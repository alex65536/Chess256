{
  This file is part of Chess 256.

  Copyright © 2016, 2018 Kernozhitsky Alexander <sh200105@mail.ru>

  Chess 256 is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Chess 256 is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Chess 256.  If not, see <http://www.gnu.org/licenses/>.

  Abstract:
    This file contains things necessary for hashing the boards and detecting the
    draw by repetitions.
}
unit BoardHashes;

{$I CompilerDirectives.inc}

interface

uses
  SysUtils, ChessRules, NotationUtils, FGL;

type

  { RRepBoard }

  RRepBoard = record
    Board: RRawBoard;
    RepCount: integer;
    class operator=(const A, B: RRepBoard): Boolean;
    function GetHash: integer;
  end;

  TRepBoardTable = specialize THashTable<RRepBoard>;
  TListOfHashList = specialize TFPGList<TRepBoardTable.PHashList>;

  { TBoardHash }

  TBoardHash = class
  private
    FSize: integer;
    FTable: TRepBoardTable;
    FList: TListOfHashList;
    FRepetitions: integer;
    procedure Remove(List: TRepBoardTable.PHashList);
  public
    // Properties
    property Repetitions: integer read FRepetitions;
    property Size: integer read FSize;
    // Methods
    procedure Add(const Value: RRawBoard);
    procedure Clear;
    procedure RemoveLast;
    function IsRepetitions: boolean;
    constructor Create;
    destructor Destroy; override;
  end;

operator := (const A: RRawBoard): RRepBoard;

implementation

operator := (const A: RRawBoard): RRepBoard;
begin
  Result.Board := A;
  Result.RepCount := 1;
end;

// Zobrist hashing precalculated values.
var
  ZobristBoard: array [TPieceKind, TPieceColor, 0 .. 7, 0 .. 7] of integer;
  ZobristCastling: array [TPieceColor, TCastlingSide] of integer;
  ZobristMoveSide: array [TPieceColor] of integer;
  ZobristEnPassant: array [0 .. 7] of integer;

{ RRepBoard }

class operator RRepBoard.=(const A, B: RRepBoard): Boolean;
var
  I, J: longint;
  C: TPieceColor;
  S: TCastlingSide;
begin
  Result := False;
  // check board
  for I := 0 to 7 do
    for J := 0 to 7 do
      if A.Board.Field[I, J] <> B.Board.Field[I, J] then
        Exit;
  // check castling
  for C := Low(TPieceColor) to High(TPieceColor) do
    for S := Low(TCastlingSide) to High(TCastlingSide) do
      if A.Board.AllowCastling[C, S] <> B.Board.AllowCastling[C, S] then
        Exit;
  // check enpassant
  if A.Board.EnPassantLine <> B.Board.EnPassantLine then
    Exit;
  // check move side
  if A.Board.MoveSide <> B.Board.MoveSide then
    Exit;
  Result := True;
end;

function RRepBoard.GetHash: integer;
  // Calculates Zobrist hash of the position.
var
  I, J: longint;
  C: TPieceColor;
  S: TCastlingSide;
begin
  Result := 0;
  with Board do
  begin
    // hash for board
    for I := 0 to 7 do
      for J := 0 to 7 do
        with Field[I, J] do
          Result := Result xor ZobristBoard[Kind, Color, I, J];
    // hash for castling
    for C := Low(TPieceColor) to High(TPieceColor) do
      for S := Low(TCastlingSide) to High(TCastlingSide) do
        if AllowCastling[C, S] then
          Result := Result xor ZobristCastling[C, S];
    // hash for enpassant
    if EnPassantLine >= 0 then
      Result := Result xor ZobristEnPassant[EnPassantLine];
    // hash for move side
    Result := Result xor ZobristMoveSide[MoveSide];
  end;
end;

{ TBoardHash }

procedure TBoardHash.Remove(List: TRepBoardTable.PHashList);
// Removes a node from the hash.
begin
  if List^.Data.RepCount = 1
  // just remove the node
  then
    FTable.Remove(List)
  // else decrease the number of repetitions
  else
  begin
    if List^.Data.RepCount = 3 then
      Dec(FRepetitions);
    Dec(List^.Data.RepCount);
  end;
  Dec(FSize);
end;

procedure TBoardHash.Add(const Value: RRawBoard);
// Adds the board into the hash.
var
  L: TRepBoardTable.PHashList;
begin
  L := FTable.Find(Value);
  if L = nil
  // if new - just add it
  then
    L := FTable.Add(Value)
  // else inc repetitions count
  else
  begin
    Inc(L^.Data.RepCount);
    if L^.Data.RepCount = 3 then
      Inc(FRepetitions);
  end;
  // add to list
  FList.Add(L);
  Inc(FSize);
end;

procedure TBoardHash.Clear;
// Clears the hash.
begin
  while FList.Count <> 0 do
    RemoveLast;
end;

procedure TBoardHash.RemoveLast;
// Removes the last board.
begin
  if FList.Count = 0 then
    Exit;
  Remove(FList[FList.Count - 1]);
  FList.Delete(FList.Count - 1);
end;

function TBoardHash.IsRepetitions: boolean;
  // Checks if there are repetitions.
begin
  Result := FRepetitions <> 0;
end;

constructor TBoardHash.Create;
begin
  FTable := TRepBoardTable.Create;
  FList := TListOfHashList.Create;
  FRepetitions := 0;
  FSize := 0;
end;

destructor TBoardHash.Destroy;
begin
  FreeAndNil(FTable);
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure InitZobrist;
// Initializes Zobrist hashing values.

  function RandInt: integer; inline;
    // Returns a random integer.
  begin
    Result := integer(Random(1 shl 32));
  end;

var
  I, J: integer;
  C: TPieceColor;
  K: TPieceKind;
  S: TCastlingSide;
begin
  Randomize;
  // values for board
  for K := Low(TPieceKind) to High(TPieceKind) do
    for C := Low(TPieceColor) to High(TPieceColor) do
      for I := 0 to 7 do
        for J := 0 to 7 do
          if K = pkNone then
            ZobristBoard[K, C, I, J] := 0
          else
            ZobristBoard[K, C, I, J] := RandInt;
  // values for castling
  for C := Low(TPieceColor) to High(TPieceColor) do
    for S := Low(TCastlingSide) to High(TCastlingSide) do
      ZobristCastling[C, S] := RandInt;
  // values for enpassant
  for I := 0 to 7 do
    ZobristEnPassant[I] := RandInt;
  // values for move side
  for C := Low(TPieceColor) to High(TPieceColor) do
    ZobristMoveSide[C] := RandInt;
end;

initialization
  InitZobrist;

end.
