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
    This unit implements "move chains" - plain chess notation without such
    advanced features as variations or comments.
}
unit MoveChains;

{$I CompilerDirectives.inc}

interface

uses
  SysUtils, FGL, ChessRules, MoveConverters, BoardHashes;

type

  { RMoveChainElement }

  RMoveChainElement = record
    Move: RChessMove;
    NewBoard: RRawBoard;
    class operator=(const A, B: RMoveChainElement): Boolean;
  end;

  TMoveChainList = specialize TFPGList<RMoveChainElement>;

  { TMoveChain }

  TMoveChain = class
  private
    FList: TMoveChainList;
    FChessBoard: TChessBoard;
    FBaseBoard: RRawBoard;
    FHash: TBoardHash;
    // Getters / Setters
    function GetBoards(I: integer): RRawBoard;
    function GetCount: integer;
    function GetMoves(I: integer): RChessMove;
    function GetValidation: boolean;
    procedure SetValidation(AValue: boolean);
  public
    // Properties
    property Moves[I: integer]: RChessMove read GetMoves;
    property Boards[I: integer]: RRawBoard read GetBoards;
    // 0 .. Count - 1 are boards after move with that number, -1 is the base board.
    property Count: integer read GetCount;
    property Validation: boolean read GetValidation write SetValidation;
    // If Valiation = False, it will be the speed improvement but TMoveChain
    // won't check moves for validness.

    // Methods for chain manipulating
    procedure Clear;
    procedure Clear(const ABaseBoard: RRawBoard);
    procedure Add(const AMove: RChessMove);
    procedure RemoveLast;
    procedure Assign(Source: TMoveChain);
    procedure AssignTo(Target: TMoveChain);
    // Functions
    function ConvertToString(AConverter: TAbstractMoveConverter;
      ASeparator: string): string;
    function IsRepetitions: boolean;
    function GetGameResult: RGameResult;
    // Constructors / Destructors
    constructor Create;
    constructor Create(const ABaseBoard: RRawBoard);
    destructor Destroy; override;
  end;

implementation

{ RMoveChainElement }

class operator RMoveChainElement.=(const A, B: RMoveChainElement): boolean;
begin
  Result := (A.Move = B.Move) and (A.NewBoard = B.NewBoard);
end;

{ TMoveChain }

function TMoveChain.GetBoards(I: integer): RRawBoard;
begin
  if I = -1 then
    Result := FBaseBoard
  else
    Result := FList[I].NewBoard;
end;

function TMoveChain.GetCount: integer;
begin
  Result := FList.Count;
end;

function TMoveChain.GetMoves(I: integer): RChessMove;
begin
  Result := FList[I].Move;
end;

function TMoveChain.GetValidation: boolean;
begin
  Result := FChessBoard.AutoGenerateMoves;
end;

procedure TMoveChain.SetValidation(AValue: boolean);
begin
  FChessBoard.AutoGenerateMoves := AValue;
end;

procedure TMoveChain.Clear;
// Clears the chain.
begin
  Clear(FBaseBoard);
end;

procedure TMoveChain.Clear(const ABaseBoard: RRawBoard);
// Clears the chain with custom board.
begin
  FList.Clear;
  FHash.Clear;
  FHash.Add(ABaseBoard);
  FBaseBoard := ABaseBoard;
end;

procedure TMoveChain.Add(const AMove: RChessMove);
// Adds a move to the chain.
var
  NewEl: RMoveChainElement;
begin
  FChessBoard.RawBoard := Boards[Count - 1];
  FChessBoard.MakeMove(AMove);
  NewEl.Move := AMove;
  NewEl.NewBoard := FChessBoard.RawBoard;
  FList.Add(NewEl);
  FHash.Add(NewEl.NewBoard);
end;

procedure TMoveChain.RemoveLast;
// Removes a move from the chain.
begin
  if Count = 0 then
    Exit;
  FList.Delete(Count - 1);
  FHash.RemoveLast;
end;

procedure TMoveChain.Assign(Source: TMoveChain);
// Copies Source to Self.
begin
  Source.AssignTo(Self);
end;

procedure TMoveChain.AssignTo(Target: TMoveChain);
// Copies Self to Target.
var
  I: integer;
  WasValidation: boolean;
begin
  // prepare
  WasValidation := Target.Validation;
  Target.Validation := False;
  // assign
  Target.Clear(Boards[-1]);
  for I := 0 to Count - 1 do
    Target.Add(Moves[I]);
  // finalize
  Target.Validation := WasValidation;
end;

function TMoveChain.ConvertToString(AConverter: TAbstractMoveConverter;
  ASeparator: string): string;
  // Converts the move chain to string. Moves are converted to string with the
  // specified converter.
var
  I: integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
  begin
    AConverter.RawBoard := Boards[I - 1];
    if I <> 0 then
      Result += ASeparator;
    Result += AConverter.GetMoveSeparator(I = 0);
    Result += AConverter.GetMoveString(Moves[I]);
  end;
end;

function TMoveChain.IsRepetitions: boolean;
  // Returns True if no draw by repetitions.
begin
  Result := FHash.IsRepetitions;
end;

function TMoveChain.GetGameResult: RGameResult;
  // Returns the game result.
begin
  if IsRepetitions then
    Result := MakeGameResult(geRepetitions, gwDraw)
  else
  begin
    FChessBoard.RawBoard := Boards[Count - 1];
    Result := FChessBoard.GetGameResult;
  end;
end;

constructor TMoveChain.Create;
begin
  Create(GetInitialPosition);
end;

constructor TMoveChain.Create(const ABaseBoard: RRawBoard);
begin
  FChessBoard := TChessBoard.Create;
  FList := TMoveChainList.Create;
  FHash := TBoardHash.Create;
  Clear(ABaseBoard);
end;

destructor TMoveChain.Destroy;
begin
  FreeAndNil(FChessBoard);
  FreeAndNil(FList);
  FreeAndNil(FHash);
  inherited Destroy;
end;

end.
