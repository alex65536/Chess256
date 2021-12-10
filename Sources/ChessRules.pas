{
  This file is part of Chess 256.

  Copyright © 2016, 2018 Alexander Kernozhitsky <sh200105@mail.ru>

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
    This file is the heart of Chess 256 - it implements the chess rules and a
    non-visual board class.
}
unit ChessRules;

{$I CompilerDirectives.inc}
{$packenum 1}

interface

uses
  SysUtils, ChessUtils;

resourcestring
  SOutOfRangeMsg = 'Out of range in %s.%s';
  SKingCapture = 'Illegal position: king capture is possible.';
  SIllegalFEN = 'Illegal FEN string.';
  SInvalidPosition = 'Position is invalid.';
  SIllegalMove = 'Illegal move.';

type
  EChessRules = class(Exception);

  TPieceKind = (pkNone, pkPawn, pkKnight, pkBishop, pkRook, pkQueen, pkKing);
  TPieceColor = (pcWhite, pcBlack);
  TCastlingSide = (csKingSide, csQueenSide);
  TMoveKind = (mkMove, mkPromote, mkCastling, mkEnPassant, mkImpossible);
  TCheckKind = (ckNone, ckCheck, ckDoubleCheck, ckCheckMate);
  TGameEndKind = (geNone, geCheckMate, geResign, geStaleMate, ge50Moves,
    geByAgreement, geRepetitions, geInsufficientMaterial, geTimeForfeit,
    geEngineFault, geOther);
  TGameWinner = (gwNone, gwWhite, gwBlack, gwDraw);
  TValidationResult = (vrOK, vrNoKing, vrIllegalPawnPosition,
    vrOpponentKingAttacked, vrTooManyKings, vrTooManyPieces);

  RBoardCell = packed record
    Kind: TPieceKind;
    Color: TPieceColor;
  end;

  RRawBoard = packed record
    Field: array [0 .. 7, 0 .. 7] of RBoardCell;
    AllowCastling: array [TPieceColor, TCastlingSide] of boolean;
    MoveSide: TPieceColor;
    EnPassantLine: shortint;
    MoveCounter: smallint;
    MoveNumber: integer;
  end;

  RChessMove = packed record
    SrcX, SrcY: shortint;
    DstX, DstY: shortint;
    PromoteTo: TPieceKind;
    IsCapture: boolean;
    Kind: TMoveKind;
    Check: TCheckKind;
  end;

  RGameResult = packed record
    Kind: TGameEndKind;
    Winner: TGameWinner;
  end;

  TMoveFilter = function(const Move: RChessMove): boolean of object;

  { TChessBoard }

  TChessBoard = class(TChessObject)
  private
    FAutoGenerateMoves: boolean;
    FMoveCount: integer;
    FMoves: array of RChessMove;
    FRawBoard: RRawBoard;
    // Temp vars
    FTmpSrcX, FTmpSrcY: integer;
    FTmpDstX, FTmpDstY: integer;
    // Getters / Setters
    function GetFENString: string;
    function GetMoves(I: integer): RChessMove;
    function GetAllowCastling(C: TPieceColor; S: TCastlingSide): boolean;
    function GetField(I, J: integer): RBoardCell;
    function GetEnPassantLine: integer;
    function GetMoveCounter: integer;
    function GetMoveNumber: integer;
    function GetMoveSide: TPieceColor;
    procedure SetFENString(const FENString: string);
    procedure SetAllowCastling(C: TPieceColor; S: TCastlingSide; AValue: boolean);
    procedure SetAutoGenerateMoves(AValue: boolean);
    procedure SetField(I, J: integer; AValue: RBoardCell);
    procedure SetEnPassantLine(AValue: integer);
    procedure SetMoveCounter(AValue: integer);
    procedure SetMoveNumber(AValue: integer);
    procedure SetMoveSide(AValue: TPieceColor);
    procedure SetRawBoard(AValue: RRawBoard);
    // Move filters
    function SrcMoveFilter(const Move: RChessMove): boolean;
    function SrcDstMoveFilter(const Move: RChessMove): boolean;
    // Helpful methods
    procedure AddMoveToList(const Move: RChessMove);
    procedure PutCheckMove(var Move: RChessMove);
  public
    // Properties
    property RawBoard: RRawBoard read FRawBoard write SetRawBoard;
    property FENString: string read GetFENString write SetFENString;
    property Moves[I: integer]: RChessMove read GetMoves;
    property MoveCount: integer read FMoveCount;
    property Field[I, J: integer]: RBoardCell read GetField write SetField;
    property AllowCastling[C: TPieceColor;
      S: TCastlingSide]: boolean read GetAllowCastling write SetAllowCastling;
    property MoveSide: TPieceColor read GetMoveSide write SetMoveSide;
    property EnPassantLine: integer read GetEnPassantLine write SetEnPassantLine;
    property MoveCounter: integer read GetMoveCounter write SetMoveCounter;
    property MoveNumber: integer read GetMoveNumber write SetMoveNumber;
    property AutoGenerateMoves: boolean read FAutoGenerateMoves
      write SetAutoGenerateMoves; //Be careful, there will be no vaidation.
    // Board methods
    procedure ClearBoard;
    procedure InitialPosition;
    procedure FlipVertically;
    procedure FlipHorizontally;
    // Move list methods
    procedure ClearList;
    procedure GenerateMoves(Validate: boolean = True; PutCheck: boolean = True;
      MaxCount: integer = 512);
    procedure PutChecks;
    // Filters
    procedure FilterBy(Filter: TMoveFilter); overload;
    procedure FilterBy(SrcX, SrcY: integer); overload;
    procedure FilterBy(SrcX, SrcY, DstX, DstY: integer); overload;
    function GetMove(SrcX, SrcY, DstX, DstY: integer): RChessMove;
    // Other methods
    function GetGameResult: RGameResult;
    function ValidatePosition: TValidationResult;
    procedure MakeMove(const Move: RChessMove);
    function GetCheckKind: TCheckKind;
    procedure GetKingXY(out X, Y: integer);
    procedure DoChange; override;
    constructor Create(AAutoGen: boolean = True);
    destructor Destroy; override;
  end;

function MakeBoardCell(Kind: TPieceKind; Color: TPieceColor): RBoardCell;
function MakeChessMove(SrcX, SrcY, DstX, DstY: integer; PromoteTo: TPieceKind;
  IsCapture: boolean; Kind: TMoveKind; Check: TCheckKind): RChessMove;
function MakeGameResult(Kind: TGameEndKind; Winner: TGameWinner): RGameResult;

function GetInitialPosition: RRawBoard;
function GetClearBoard: RRawBoard;

operator not(A: TPieceColor): TPieceColor;

operator=(const A, B: RRawBoard): Boolean;
operator<>(const A, B: RRawBoard): Boolean;
operator=(const A, B: RBoardCell): Boolean;
operator<>(const A, B: RBoardCell): Boolean;
operator=(const A, B: RChessMove): Boolean;
operator<>(const A, B: RChessMove): Boolean;
operator=(const A, B: RGameResult): Boolean;
operator<>(const A, B: RGameResult): Boolean;

implementation

function MakeBoardCell(Kind: TPieceKind; Color: TPieceColor): RBoardCell;
  // Packs a board cell into a record.
begin
  Result.Kind := Kind;
  Result.Color := Color;
end;

function MakeChessMove(SrcX, SrcY, DstX, DstY: integer; PromoteTo: TPieceKind;
  IsCapture: boolean; Kind: TMoveKind; Check: TCheckKind): RChessMove;
  // Packs a chess move into a record.
begin
  Result.SrcX := SrcX;
  Result.SrcY := SrcY;
  Result.DstX := DstX;
  Result.DstY := DstY;
  Result.PromoteTo := PromoteTo;
  Result.IsCapture := IsCapture;
  Result.Kind := Kind;
  Result.Check := Check;
end;

function MakeGameResult(Kind: TGameEndKind; Winner: TGameWinner): RGameResult;
  // Packs a game result into a record.
begin
  Result.Kind := Kind;
  Result.Winner := Winner;
end;

function GetInitialPosition: RRawBoard;
  // Returns an initial position.
var
  I, J: integer;
  C: TPieceColor;
  S: TCastlingSide;
begin
  Result := GetClearBoard;
  with Result do
  begin
    for C := Low(TPieceColor) to High(TPieceColor) do
      for S := Low(TCastlingSide) to High(TCastlingSide) do
        AllowCastling[C, S] := True;
    Field[0, 0].Kind := pkRook;
    Field[1, 0].Kind := pkKnight;
    Field[2, 0].Kind := pkBishop;
    Field[3, 0].Kind := pkQueen;
    Field[4, 0].Kind := pkKing;
    Field[5, 0].Kind := pkBishop;
    Field[6, 0].Kind := pkKnight;
    Field[7, 0].Kind := pkRook;
    for I := 0 to 7 do
    begin
      for J := 0 to 1 do
        Field[I, J].Color := pcBlack;
      for J := 6 to 7 do
        Field[I, J].Color := pcWhite;
      Field[I, 1].Kind := pkPawn;
      Field[I, 6].Kind := pkPawn;
      Field[I, 7].Kind := Field[I, 0].Kind;
    end;
  end;
end;

function GetClearBoard: RRawBoard;
  // Returns a clear board.
var
  I, J: integer;
  C: TPieceColor;
  S: TCastlingSide;
begin
  with Result do
  begin
    for I := 0 to 7 do
      for J := 0 to 7 do
      begin
        Field[I, J].Color := pcWhite;
        Field[I, J].Kind := pkNone;
      end;
    for C := Low(TPieceColor) to High(TPieceColor) do
      for S := Low(TCastlingSide) to High(TCastlingSide) do
        AllowCastling[C, S] := False;
    EnPassantLine := -1;
    MoveCounter := 0;
    MoveNumber := 1;
    MoveSide := pcWhite;
  end;
end;

operator not(A: TPieceColor): TPieceColor;
  // Inverts the color.
begin
  if A = pcWhite then
    Result := pcBlack
  else
    Result := pcWhite;
end;

operator=(const A, B: RRawBoard): boolean;
var
  I, J: longint;
  C: TPieceColor;
  S: TCastlingSide;
begin
  Result := False;
  for I := 0 to 7 do
    for J := 0 to 7 do
      if A.Field[I, J] <> B.Field[I, J] then
        Exit;
  for C := Low(TPieceColor) to High(TPieceColor) do
    for S := Low(TCastlingSide) to High(TCastlingSide) do
      if A.AllowCastling[C, S] <> B.AllowCastling[C, S] then
        Exit;
  if A.EnPassantLine <> B.EnPassantLine then
    Exit;
  if A.MoveCounter <> B.MoveCounter then
    Exit;
  if A.MoveNumber <> B.MoveNumber then
    Exit;
  if A.MoveSide <> B.MoveSide then
    Exit;
  Result := True;
end;

operator<>(const A, B: RRawBoard): boolean;
begin
  Result := not (A = B);
end;

operator=(const A, B: RBoardCell): boolean;
begin
  if A.Kind = pkNone then
    Result := (A.Kind = B.Kind)
  else
    Result := (A.Kind = B.Kind) and (A.Color = B.Color);
end;

operator<>(const A, B: RBoardCell): boolean;
begin
  Result := not (A = B);
end;

operator=(const A, B: RChessMove): boolean;
begin
  Result := (A.DstX = B.DstX) and (A.DstY = B.DstY) and
    (A.SrcX = B.SrcX) and (A.SrcY = B.SrcY) and
    (A.PromoteTo = B.PromoteTo);
end;

operator<>(const A, B: RChessMove): boolean;
begin
  Result := not (A = B);
end;

operator=(const A, B: RGameResult): boolean;
begin
  Result := (A.Kind = B.Kind) and (A.Winner = B.Winner);
end;

operator<>(const A, B: RGameResult): boolean;
begin
  Result := (A.Kind <> B.Kind) or (A.Winner <> B.Winner);
end;

// Chess rules implementation.
// Required for TChessBoard.

type
  TAddMoveEvent = procedure(const Move: RChessMove) of object;

function AttackCount(Board: RRawBoard; X, Y: integer; AttackerColor: TPieceColor;
  MaxCount: integer = 256): integer;
  // Returns the number of attacks to this cell (without enpassant).
var
  Res: integer;
  PawnDY, KingDY: integer;

  procedure GetOnLine(DeltaX, DeltaY: integer; Count: integer;
    Piece1, Piece2: TPieceKind);
  // Updates attack count on line. It goes through the following cells:
  // (X + DeltaX, Y + DeltaY), (X + 2*DeltaX, Y + 2*DeltaY),
  // (X + 3*DeltaX, Y + 3*DeltaY) ... (X + Count * DeltaX, Y + Count * DeltaY)
  // Increments Res when meets Piece1 or Piece2.
  var
    I, NewX, NewY: integer;
  begin
    NewX := X;
    NewY := Y;
    for I := 1 to Count do
    begin
      Inc(NewX, DeltaX);
      Inc(NewY, DeltaY);
      if (NewX < 0) or (NewX > 7) or (NewY < 0) or (NewY > 7) then
        Exit;
      with Board.Field[NewX, NewY] do
      begin
        if (Kind in [Piece1, Piece2]) and (Color = AttackerColor) then
          Inc(Res);
        if Kind <> pkNone then
          Exit;
      end;
    end;
  end;

begin
  Res := 0;
  if AttackerColor = pcWhite then
    PawnDY := 1
  else
    PawnDY := -1;
  KingDY := -1 * PawnDY;
  // pawn, king
  GetOnLine(-1, PawnDY, 1, pkPawn, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, PawnDY, 1, pkPawn, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-1, KingDY, 1, pkKing, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, KingDY, 1, pkKing, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(0, 1, 1, pkKing, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(0, -1, 1, pkKing, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-1, 0, 1, pkKing, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, 0, 1, pkKing, pkKing);
  if Res >= MaxCount then
    Exit(Res);
  // knight
  GetOnLine(2, 1, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(2, -1, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-2, 1, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-2, -1, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, 2, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, -2, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-1, 2, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-1, -2, 1, pkKnight, pkKnight);
  if Res >= MaxCount then
    Exit(Res);
  // bishop, rook & queen
  GetOnLine(0, 1, 8, pkRook, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(0, -1, 8, pkRook, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, 0, 8, pkRook, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-1, 0, 8, pkRook, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, 1, 8, pkBishop, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(1, -1, 8, pkBishop, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-1, 1, 8, pkBishop, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  GetOnLine(-1, -1, 8, pkBishop, pkQueen);
  if Res >= MaxCount then
    Exit(Res);
  // that's all!
  Result := Res;
end;

procedure MakeMove(var Board: RRawBoard; const Move: RChessMove);
// Makes a move
begin
  with Move, Board do
  begin
    // updating Board.Field
    Field[SrcX, SrcY].Kind := pkNone;
    Field[DstX, DstY].Kind := PromoteTo;
    Field[DstX, DstY].Color := MoveSide;
    if Kind = mkEnPassant then
      Field[DstX, SrcY].Kind := pkNone;
    if Kind = mkCastling then
    begin
      if DstX = 2 then
      begin
        Field[3, DstY].Kind := pkRook;
        Field[3, DstY].Color := MoveSide;
        Field[0, DstY].Kind := pkNone;
      end
      else
      begin
        Field[5, DstY].Kind := pkRook;
        Field[5, DstY].Color := MoveSide;
        Field[7, DstY].Kind := pkNone;
      end;
    end;
    // updating Board.EnPassantLine
    if (PromoteTo = pkPawn) and (Abs(DstY - SrcY) = 2) then
      EnPassantLine := DstX
    else
      EnPassantLine := -1;
    // updating Board.MoveSide
    MoveSide := not MoveSide;
    // updating Board.AllowCastling
    if SrcY = 0 then
    begin
      if SrcX in [0, 4] then
        AllowCastling[pcBlack, csQueenSide] := False;
      if SrcX in [4, 7] then
        AllowCastling[pcBlack, csKingSide] := False;
    end;
    if SrcY = 7 then
    begin
      if SrcX in [0, 4] then
        AllowCastling[pcWhite, csQueenSide] := False;
      if SrcX in [4, 7] then
        AllowCastling[pcWhite, csKingSide] := False;
    end;
    if DstY = 0 then
    begin
      if DstX in [0, 4] then
        AllowCastling[pcBlack, csQueenSide] := False;
      if DstX in [4, 7] then
        AllowCastling[pcBlack, csKingSide] := False;
    end;
    if DstY = 7 then
    begin
      if DstX in [0, 4] then
        AllowCastling[pcWhite, csQueenSide] := False;
      if DstX in [4, 7] then
        AllowCastling[pcWhite, csKingSide] := False;
    end;
    // updating Board.MoveCounter
    if IsCapture or (Kind = mkPromote) or (PromoteTo = pkPawn) then
      MoveCounter := 0
    else
      Inc(MoveCounter);
    // updating Board.MoveNumber
    if MoveSide = pcWhite then
      Inc(MoveNumber);
  end;
end;

procedure GetKingXY(Board: RRawBoard; out X, Y: integer);
// Returns king coordinates.
var
  I, J: integer;
begin
  X := -1;
  Y := -1;
  with Board do
    for I := 0 to 7 do
      for J := 0 to 7 do
        with Field[I, J] do
          if (Kind = pkKing) and (Color = MoveSide) then
          begin
            X := I;
            Y := J;
          end;
end;

function GenerateMoves(Board: RRawBoard; AddMove: TAddMoveEvent;
  Validate: boolean = True; MaxCount: integer = 512): integer;
  // Move generator.
var
  KingX, KingY: integer;
  CastlingLine, PawnDouble, PawnEnPassant, PawnPromote, PawnDelta: integer;
  Move: RChessMove;
  GeneratedCount: integer;

  procedure AddList;
  // Adds a move to the list.
  var
    IsValid: boolean;
    NewKingX, NewKingY: integer;
    NewBoard: RRawBoard;
  begin
    if GeneratedCount >= MaxCount then
      Exit;
    // validating move
    if Validate then
    begin
      NewBoard := Board;
      MakeMove(NewBoard, Move);
      with Move do
        if PromoteTo = pkKing then
        begin
          NewKingX := DstX;
          NewKingY := DstY;
        end
        else
        begin
          NewKingX := KingX;
          NewKingY := KingY;
        end;
      IsValid := AttackCount(NewBoard, NewKingX, NewKingY,
        NewBoard.MoveSide, 1) = 0;
    end
    else
      IsValid := True;
    // adding move
    if IsValid then
    begin
      if Assigned(AddMove) then
        AddMove(Move);
      Inc(GeneratedCount);
    end;
  end;

  procedure AddOnLine(X, Y, DeltaX, DeltaY, Count: integer; Piece: TPieceKind);
  // Tries to update on line. It goes through the following cells:
  // (X + DeltaX, Y + DeltaY), (X + 2*DeltaX, Y + 2*DeltaY),
  // (X + 3*DeltaX, Y + 3*DeltaY) ... (X + Count * DeltaX, Y + Count * DeltaY)
  var
    I: integer;
  begin
    with Move do
    begin
      SrcX := X;
      SrcY := Y;
      IsCapture := False;
      Kind := mkMove;
      PromoteTo := Piece;
    end;
    for I := 1 to Count do
    begin
      Inc(X, DeltaX);
      Inc(Y, DeltaY);
      if (X < 0) or (X > 7) or (Y < 0) or (Y > 7) then
        Exit;
      Move.DstX := X;
      Move.DstY := Y;
      with Board.Field[X, Y] do
      begin
        if (Kind <> pkNone) and (Color <> Board.MoveSide) then
        begin
          Move.IsCapture := True;
          AddList;
        end;
        if Kind = pkNone then
          AddList
        else
          Exit;
      end;
    end;
  end;

  procedure InitAll;
  // Initializes the generator.
  begin
    GetKingXY(Board, KingX, KingY);
    if Board.MoveSide = pcBlack then
    begin
      CastlingLine := 0;
      PawnDelta := 1;
      PawnDouble := 1;
      PawnEnPassant := 4;
      PawnPromote := 7;
    end
    else
    begin
      CastlingLine := 7;
      PawnDelta := -1;
      PawnDouble := 6;
      PawnEnPassant := 3;
      PawnPromote := 0;
    end;
  end;

  procedure AddPawn(X, Y: integer);
  // Adds a pawn.

    procedure AddCanPromote(DX, DY: integer; Capture: boolean);
    // Adds a move (X, Y) -> (DX, DY) with trying to promote.
    begin
      with Move do
      begin
        DstX := DX;
        DstY := DY;
        IsCapture := Capture;
        if DY = PawnPromote then
        begin
          Kind := mkPromote;
          PromoteTo := pkKnight;
          AddList;
          PromoteTo := pkBishop;
          AddList;
          PromoteTo := pkRook;
          AddList;
          PromoteTo := pkQueen;
          AddList;
        end
        else
        begin
          Kind := mkMove;
          PromoteTo := pkPawn;
          AddList;
        end;
      end;
    end;

  begin
    Move.SrcX := X;
    Move.SrcY := Y;
    with Board do
    begin
      // move forward
      if Field[X, Y + PawnDelta].Kind = pkNone then
      begin
        AddCanPromote(X, Y + PawnDelta, False);
        if (Y = PawnDouble) and
          (Field[X, Y + 2 * PawnDelta].Kind = pkNone) then
          AddCanPromote(X, Y + 2 * PawnDelta, False);
      end;
      // capture left
      if X > 0 then
      begin
        // simple capture
        if (Field[X - 1, Y + PawnDelta].Kind <> pkNone) and
          (Field[X - 1, Y + PawnDelta].Color <> MoveSide) then
          AddCanPromote(X - 1, Y + PawnDelta, True);
        // en passant
        if (EnPassantLine = X - 1) and (Y = PawnEnPassant) and
          (Field[X - 1, Y].Kind = pkPawn) and
          (Field[X - 1, Y].Color <> MoveSide) then
        begin
          with Move do
          begin
            DstX := X - 1;
            DstY := Y + PawnDelta;
            IsCapture := True;
            Kind := mkEnPassant;
            PromoteTo := pkPawn;
          end;
          AddList;
        end;
      end;
      // capture right
      if X < 7 then
      begin
        // simple capture
        if (Field[X + 1, Y + PawnDelta].Kind <> pkNone) and
          (Field[X + 1, Y + PawnDelta].Color <> MoveSide) then
          AddCanPromote(X + 1, Y + PawnDelta, True);
        // en passant
        if (EnPassantLine = X + 1) and (Y = PawnEnPassant) and
          (Field[X + 1, Y].Kind = pkPawn) and
          (Field[X + 1, Y].Color <> MoveSide) then
        begin
          with Move do
          begin
            DstX := X + 1;
            DstY := Y + PawnDelta;
            IsCapture := True;
            Kind := mkEnPassant;
            PromoteTo := pkPawn;
          end;
          AddList;
        end;
      end;
    end;
  end;

  procedure AddCastlings;
  // Adds castlings.
  begin
    with Board do
    begin
      // queenside
      if AllowCastling[MoveSide, csQueenSide] then
      begin
        if (Field[0, CastlingLine].Kind = pkRook) and
          (Field[0, CastlingLine].Color = MoveSide) and
          (Field[1, CastlingLine].Kind = pkNone) and
          (Field[2, CastlingLine].Kind = pkNone) and
          (Field[3, CastlingLine].Kind = pkNone) and
          (Field[4, CastlingLine].Kind = pkKing) and
          (Field[4, CastlingLine].Color = MoveSide) and
          (AttackCount(Board, 2, CastlingLine, not MoveSide, 1) = 0) and
          (AttackCount(Board, 3, CastlingLine, not MoveSide, 1) = 0) and
          (AttackCount(Board, 4, CastlingLine, not MoveSide, 1) = 0)
        then
        begin
          Move :=
            MakeChessMove(4, CastlingLine, 2, CastlingLine, pkKing,
            False, mkCastling, ckNone);
          AddList;
        end;
      end;
      // kingside
      if AllowCastling[MoveSide, csKingSide] then
      begin
        if (Field[4, CastlingLine].Kind = pkKing) and
          (Field[4, CastlingLine].Color = MoveSide) and
          (Field[5, CastlingLine].Kind = pkNone) and
          (Field[6, CastlingLine].Kind = pkNone) and
          (Field[7, CastlingLine].Kind = pkRook) and
          (Field[7, CastlingLine].Color = MoveSide) and
          (AttackCount(Board, 4, CastlingLine, not MoveSide, 1) = 0) and
          (AttackCount(Board, 5, CastlingLine, not MoveSide, 1) = 0) and
          (AttackCount(Board, 6, CastlingLine, not MoveSide, 1) = 0)
        then
        begin
          Move :=
            MakeChessMove(4, CastlingLine, 6, CastlingLine, pkKing,
            False, mkCastling, ckNone);
          AddList;
        end;
      end;
    end;
  end;

var
  I, J: integer;
begin
  GeneratedCount := 0;
  Move.Check := ckNone;
  InitAll;
  AddCastlings;
  for I := 0 to 7 do
    for J := 0 to 7 do
      with Board.Field[I, J] do
      begin
        if Color <> Board.MoveSide then
          Continue;
        case Kind of
          pkPawn: AddPawn(I, J);
          pkKnight:
          begin
            // adding knight
            AddOnLine(I, J, 2, 1, 1, pkKnight);
            AddOnLine(I, J, 2, -1, 1, pkKnight);
            AddOnLine(I, J, -2, 1, 1, pkKnight);
            AddOnLine(I, J, -2, -1, 1, pkKnight);
            AddOnLine(I, J, 1, 2, 1, pkKnight);
            AddOnLine(I, J, 1, -2, 1, pkKnight);
            AddOnLine(I, J, -1, 2, 1, pkKnight);
            AddOnLine(I, J, -1, -2, 1, pkKnight);
          end;
          pkBishop:
          begin
            // adding bishop
            AddOnLine(I, J, 1, 1, 8, pkBishop);
            AddOnLine(I, J, 1, -1, 8, pkBishop);
            AddOnLine(I, J, -1, 1, 8, pkBishop);
            AddOnLine(I, J, -1, -1, 8, pkBishop);
          end;
          pkRook:
          begin
            // adding rook
            AddOnLine(I, J, 0, 1, 8, pkRook);
            AddOnLine(I, J, 0, -1, 8, pkRook);
            AddOnLine(I, J, 1, 0, 8, pkRook);
            AddOnLine(I, J, -1, 0, 8, pkRook);
          end;
          pkQueen:
          begin
            // adding queen
            AddOnLine(I, J, 0, 1, 8, pkQueen);
            AddOnLine(I, J, 0, -1, 8, pkQueen);
            AddOnLine(I, J, 1, 0, 8, pkQueen);
            AddOnLine(I, J, -1, 0, 8, pkQueen);
            AddOnLine(I, J, 1, 1, 8, pkQueen);
            AddOnLine(I, J, 1, -1, 8, pkQueen);
            AddOnLine(I, J, -1, 1, 8, pkQueen);
            AddOnLine(I, J, -1, -1, 8, pkQueen);
          end;
          pkKing:
          begin
            // adding king
            AddOnLine(I, J, 0, 1, 1, pkKing);
            AddOnLine(I, J, 0, -1, 1, pkKing);
            AddOnLine(I, J, 1, 0, 1, pkKing);
            AddOnLine(I, J, -1, 0, 1, pkKing);
            AddOnLine(I, J, 1, 1, 1, pkKing);
            AddOnLine(I, J, 1, -1, 1, pkKing);
            AddOnLine(I, J, -1, 1, 1, pkKing);
            AddOnLine(I, J, -1, -1, 1, pkKing);
          end;
        end;
        // stop generator (if nessesary)
        if GeneratedCount >= MaxCount then
          Exit(GeneratedCount);
      end;
  Result := GeneratedCount;
end;

function GetCheckKind(Board: RRawBoard): TCheckKind;
  // Returns the check kind.
var
  AttackCnt, GeneratedCnt: integer;
  X, Y: integer;
begin
  GetKingXY(Board, X, Y);
  AttackCnt := ChessRules.AttackCount(Board, X, Y, not Board.MoveSide, 2);
  if AttackCnt = 0 then
    Result := ckNone
  else
  begin
    GeneratedCnt := GenerateMoves(Board, nil, True, 2);
    if GeneratedCnt = 0 then
      Result := ckCheckMate
    else if AttackCnt = 1 then
      Result := ckCheck
    else
      Result := ckDoubleCheck;
  end;
end;

{ TChessBoard }

function TChessBoard.GetFENString: string;
  // Returns FEN string.
const
  Pieces: array [TPieceColor, TPieceKind] of string =
    ((' ', 'P', 'N', 'B', 'R', 'Q', 'K'),
    (' ', 'p', 'n', 'b', 'r', 'q', 'k'));
  Castling: array [TPieceColor, TCastlingSide] of string =
    (('K', 'Q'),
    ('k', 'q'));
var
  I, J, EmptyCount: integer;
  S: TCastlingSide;
  C: TPieceColor;
  Temp: string;
begin
  with FRawBoard do
  begin
    Result := '';
    // field
    for J := 0 to 7 do
    begin
      EmptyCount := 0;
      for I := 0 to 7 do
        with Field[I, J] do
        begin
          if Kind = pkNone then
            Inc(EmptyCount)
          else
          begin
            if EmptyCount > 0 then
              Result := Result + IntToStr(EmptyCount);
            Result := Result + Pieces[Color, Kind];
            EmptyCount := 0;
          end;
        end;
      if EmptyCount > 0 then
        Result := Result + IntToStr(EmptyCount);
      if J < 7 then
        Result := Result + '/';
    end;
    // move side
    if MoveSide = pcWhite then
      Result := Result + ' w '
    else
      Result := Result + ' b ';
    // castling booleans
    Temp := '';
    for C := Low(TPieceColor) to High(TPieceColor) do
      for S := Low(TCastlingSide) to High(TCastlingSide) do
        if (AllowCastling[C, S]) then
          Temp := Temp + Castling[C, S];
    if Temp = '' then
      Result := Result + '-'
    else
      Result := Result + Temp;
    // enpassant line
    if EnPassantLine < 0 then
      Result := Result + ' - '
    else
    begin
      Result := Result + ' ' + Chr(Ord('a') + EnPassantLine);
      if MoveSide = pcWhite then
        Result := Result + '6 '
      else
        Result := Result + '3 ';
    end;
    // move counter & move number
    Result := Result + IntToStr(MoveCounter) + ' ' + IntToStr(MoveNumber);
  end;
end;

function TChessBoard.GetMoves(I: integer): RChessMove;
begin
  if I >= MoveCount then
    raise EChessRules.CreateFmt(SOutOfRangeMsg, ['TChessBoard', 'GetMoves'])
  else
    Result := FMoves[I];
end;

function TChessBoard.GetAllowCastling(C: TPieceColor; S: TCastlingSide): boolean;
begin
  Result := FRawBoard.AllowCastling[C, S];
end;

function TChessBoard.GetField(I, J: integer): RBoardCell;
begin
  if (I < 0) or (J < 0) or (I > 7) or (J > 7) then
    raise EChessRules.CreateFmt(SOutOfRangeMsg, ['TChessBoard', 'GetBoard'])
  else
    Result := FRawBoard.Field[I, J];
end;

function TChessBoard.GetEnPassantLine: integer;
begin
  Result := FRawBoard.EnPassantLine;
end;

function TChessBoard.GetMoveCounter: integer;
begin
  Result := FRawBoard.MoveCounter;
end;

function TChessBoard.GetMoveNumber: integer;
begin
  Result := FRawBoard.MoveNumber;
end;

function TChessBoard.GetMoveSide: TPieceColor;
begin
  Result := FRawBoard.MoveSide;
end;

procedure TChessBoard.SetFENString(const FENString: string);
// Puts FEN string.

  function FENParser(FENString: string): boolean;
    // The core of the parser. Returns True if parsed successfully.
  const
    WhitePieceSet = ['P', 'N', 'B', 'R', 'Q', 'K'];
    BlackPieceSet = ['p', 'n', 'b', 'r', 'q', 'k'];
    PieceSet = WhitePieceSet + BlackPieceSet;
  var
    I, J: integer;
  begin
    Result := False;
    ClearBoard;
    with FRawBoard do
    begin
      // field
      I := 0;
      J := 0;
      while True do
      begin
        if FENString = '' then
          Exit;
        if (FENString[1] in PieceSet) and ((I >= 8) or (J >= 8)) then
          Exit;
        case FENString[1] of
          '/':
          begin
            if I <> 8 then
              Exit;
            if J > 8 then
              Exit;
            Inc(J);
            I := 0;
          end;
          ' ':
          begin
            if J <> 7 then
              Exit;
            Break;
          end;
          '1' .. '8':
          begin
            Inc(I, Ord(FENString[1]) - Ord('0'));
            if I > 8 then
              Exit;
          end;
          'p', 'P': Field[I, J].Kind := pkPawn;
          'n', 'N': Field[I, J].Kind := pkKnight;
          'b', 'B': Field[I, J].Kind := pkBishop;
          'r', 'R': Field[I, J].Kind := pkRook;
          'q', 'Q': Field[I, J].Kind := pkQueen;
          'k', 'K': Field[I, J].Kind := pkKing;
          else
            Exit;
        end;
        if FENString[1] in WhitePieceSet then
        begin
          Field[I, J].Color := pcWhite;
          Inc(I);
        end;
        if FENString[1] in BlackPieceSet then
        begin
          Field[I, J].Color := pcBlack;
          Inc(I);
        end;
        Delete(FENString, 1, 1);
      end;
      if FENString = '' then
        Exit;
      // move side
      Delete(FENString, 1, 1);
      if FENString = '' then
        Exit;
      case FENString[1] of
        'w': MoveSide := pcWhite;
        'b': MoveSide := pcBlack;
        else
          Exit;
      end;
      Delete(FENString, 1, 2);
      if FENString = '' then
        Exit;
      // castling booleans
      if FENString[1] = '-' then
        Delete(FENString, 1, 1)
      else
      begin
        while True do
        begin
          if FENString = '' then
            Exit;
          case FENString[1] of
            'K': AllowCastling[pcWhite, csKingSide] := True;
            'Q': AllowCastling[pcWhite, csQueenSide] := True;
            'k': AllowCastling[pcBlack, csKingSide] := True;
            'q': AllowCastling[pcBlack, csQueenSide] := True;
            ' ': Break;
            else
              Exit;
          end;
          Delete(FENString, 1, 1);
        end;
      end;
      // enpassant line
      Delete(FENString, 1, 1);
      if FENString = '' then
        Exit;
      if FENString[1] = '-' then
        Delete(FENString, 1, 2)
      else
      begin
        if FENString[1] in ['a' .. 'h'] then
          EnPassantLine := Ord(FENString[1]) - Ord('a')
        else
          Exit;
        Delete(FENString, 1, 3);
      end;
      // move counter
      Result := True;
      MoveCounter := 0;
      MoveNumber := 1;
      if FENString = '' then
        Exit;
      I := Pos(' ', FENString);
      if I = 0 then
        I := Length(FENString) + 1;
      Val(Copy(FENString, 1, I - 1), MoveCounter, J);
      if J <> 0 then
      begin
        MoveCounter := 0;
        Exit;
      end;
      // move number
      if I > Length(FENString) then
        Dec(I);
      Delete(FENString, 1, I);
      I := Pos(' ', FENString);
      if I = 0 then
        I := Length(FENString) + 1;
      Val(Copy(FENString, 1, I - 1), MoveNumber, J);
      if J <> 0 then
        MoveNumber := 1;
    end;
  end;

var
  Res: boolean;
  PreBoard: RRawBoard;
begin
  // try to parse
  BeginUpdate;
  PreBoard := FRawBoard;
  Res := FENParser(FENString);
  if not Res then
    FRawBoard := PreBoard;
  EndUpdate;
  DoChange;
  // if error - raise an exception.
  if not Res then
    raise EChessRules.Create(SIllegalFEN);
end;

procedure TChessBoard.SetAllowCastling(C: TPieceColor; S: TCastlingSide;
  AValue: boolean);
begin
  if FRawBoard.AllowCastling[C, S] = AValue then
    Exit;
  FRawBoard.AllowCastling[C, S] := AValue;
  DoChange;
end;

procedure TChessBoard.SetAutoGenerateMoves(AValue: boolean);
begin
  if FAutoGenerateMoves = AValue then
    Exit;
  FAutoGenerateMoves := AValue;
  if FAutoGenerateMoves then
  begin
    ClearList;
    GenerateMoves;
  end;
end;

procedure TChessBoard.SetField(I, J: integer; AValue: RBoardCell);
begin
  if (I < 0) or (J < 0) or (I > 7) or (J > 7) then
    raise EChessRules.CreateFmt(SOutOfRangeMsg, ['TChessBoard', 'SetField'])
  else if FRawBoard.Field[I, J] <> AValue then
  begin
    FRawBoard.Field[I, J] := AValue;
    DoChange;
  end;
end;

procedure TChessBoard.SetEnPassantLine(AValue: integer);
begin
  if FRawBoard.EnPassantLine = AValue then
    Exit;
  FRawBoard.EnPassantLine := AValue;
  DoChange;
end;

procedure TChessBoard.SetMoveCounter(AValue: integer);
begin
  if FRawBoard.MoveCounter = AValue then
    Exit;
  FRawBoard.MoveCounter := AValue;
  DoChange;
end;

procedure TChessBoard.SetMoveNumber(AValue: integer);
begin
  if FRawBoard.MoveNumber = AValue then
    Exit;
  FRawBoard.MoveNumber := AValue;
  DoChange;
end;

procedure TChessBoard.SetMoveSide(AValue: TPieceColor);
begin
  if FRawBoard.MoveSide = AValue then
    Exit;
  FRawBoard.MoveSide := AValue;
  DoChange;
end;

procedure TChessBoard.SetRawBoard(AValue: RRawBoard);
begin
  FRawBoard := AValue;
  DoChange;
end;

function TChessBoard.SrcMoveFilter(const Move: RChessMove): boolean;
  // Filter by Src.
begin
  Result := (Move.SrcX = FTmpSrcX) and (Move.SrcY = FTmpSrcY);
end;

function TChessBoard.SrcDstMoveFilter(const Move: RChessMove): boolean;
  // Filter by Src and Dst.
begin
  Result := (Move.SrcX = FTmpSrcX) and (Move.SrcY = FTmpSrcY) and
    (Move.DstX = FTmpDstX) and (Move.DstY = FTmpDstY);
end;

procedure TChessBoard.AddMoveToList(const Move: RChessMove);
// Adds a move to the list.
begin
  FMoves[FMoveCount] := Move;
  Inc(FMoveCount);
end;

procedure TChessBoard.PutCheckMove(var Move: RChessMove);
// Puts a check to the move.
var
  NewBoard: RRawBoard;
begin
  NewBoard := FRawBoard;
  ChessRules.MakeMove(NewBoard, Move);
  Move.Check := ChessRules.GetCheckKind(NewBoard);
end;

procedure TChessBoard.ClearBoard;
// Clears the board.
begin
  FRawBoard := GetClearBoard;
  DoChange;
end;

procedure TChessBoard.InitialPosition;
// Puts the initial position onto the board.
begin
  FRawBoard := GetInitialPosition;
  DoChange;
end;

procedure TChessBoard.FlipHorizontally;
// Flips the board horizontally.
var
  TempBoard: RRawBoard;
  I, J: integer;
  C: TPieceColor;
  S: TCastlingSide;
begin
  BeginUpdate;
  TempBoard := FRawBoard;
  with FRawBoard do
  begin
    for I := 0 to 7 do
      for J := 0 to 7 do
        Field[I, J] := TempBoard.Field[7 - I, J];
    if EnPassantLine >= 0 then
      EnPassantLine := 7 - EnPassantLine;
    for C := Low(TPieceColor) to High(TPieceColor) do
      for S := Low(TCastlingSide) to High(TCastlingSide) do
        AllowCastling[C, S] := False;
  end;
  EndUpdate;
  DoChange;
end;

procedure TChessBoard.FlipVertically;
// Flips the board vertically.
var
  TempBoard: RRawBoard;
  I, J: integer;
  S: TCastlingSide;
  C: TPieceColor;
begin
  BeginUpdate;
  TempBoard := FRawBoard;
  with FRawBoard do
  begin
    for I := 0 to 7 do
      for J := 0 to 7 do
      begin
        Field[I, J].Kind := TempBoard.Field[I, 7 - J].Kind;
        Field[I, J].Color := not TempBoard.Field[I, 7 - J].Color;
      end;
    for C := Low(TPieceColor) to High(TPieceColor) do
      for S := Low(TCastlingSide) to High(TCastlingSide) do
        AllowCastling[C, S] := TempBoard.AllowCastling[not C, S];
    MoveSide := not MoveSide;
  end;
  EndUpdate;
  DoChange;
end;

procedure TChessBoard.ClearList;
// Clears the move list.
begin
  FMoveCount := 0;
end;

procedure TChessBoard.GenerateMoves(Validate: boolean; PutCheck: boolean;
  MaxCount: integer);
// Generates the moves.
begin
  ClearList;
  ChessRules.GenerateMoves(FRawBoard, @AddMoveToList, Validate, MaxCount);
  if PutCheck then
    PutChecks;
end;

procedure TChessBoard.PutChecks;
// Puts the checks onto moves.
var
  I: integer;
begin
  for I := 0 to FMoveCount - 1 do
    PutCheckMove(FMoves[I]);
end;

procedure TChessBoard.FilterBy(Filter: TMoveFilter);
// Filter moves by a custom filter.
var
  OldMoveCount: integer;
  I: integer;

  procedure Swap(var A, B: RChessMove);
  // Swaps moves.
  var
    T: RChessMove;
  begin
    T := A;
    A := B;
    B := T;
  end;

begin
  OldMoveCount := FMoveCount;
  FMoveCount := 0;
  for I := 0 to OldMoveCount - 1 do
    if Filter(FMoves[I]) then
    begin
      Swap(FMoves[I], FMoves[FMoveCount]);
      Inc(FMoveCount);
    end;
end;

procedure TChessBoard.FilterBy(SrcX, SrcY: integer);
// Filter moves by Src.
begin
  FTmpSrcX := SrcX;
  FTmpSrcY := SrcY;
  FilterBy(@SrcMoveFilter);
end;

procedure TChessBoard.FilterBy(SrcX, SrcY, DstX, DstY: integer);
// Filter moves by Dst and Src.
begin
  FTmpSrcX := SrcX;
  FTmpSrcY := SrcY;
  FTmpDstX := DstX;
  FTmpDstY := DstY;
  FilterBy(@SrcDstMoveFilter);
end;

function TChessBoard.GetMove(SrcX, SrcY, DstX, DstY: integer): RChessMove;
  // Returns a move with specified Dst and Src. If move isn't found, returns
  // a move with Kind = mkImpossible.
var
  I: integer;
begin
  FTmpSrcX := SrcX;
  FTmpSrcY := SrcY;
  FTmpDstX := DstX;
  FTmpDstY := DstY;
  for I := 0 to FMoveCount - 1 do
    if SrcDstMoveFilter(FMoves[I]) then
      Exit(FMoves[I]);
  Result := MakeChessMove(-1, -1, -1, -1, pkNone, False, mkImpossible, ckNone);
end;

function TChessBoard.GetGameResult: RGameResult;
  // Returns the game result.
const
  MaxMoves = 50;
var
  KingX, KingY: integer;
  GeneratedCount: integer;

  function IsInsufficientMaterial: boolean;
    // Check for draw by insufficient material.
    // Draw happens when:
    //   1. King + Knight vs King
    //   2. King + Bishop vs King
    //   3. King + Bishops vs King + Bishops (bishops stay on cells of the same color)
  var
    I, J: integer;
    Knights, BishopsWhite, BishopsBlack: integer;
  begin
    Result := False;
    Knights := 0;
    BishopsWhite := 0;
    BishopsBlack := 0;
    for I := 0 to 7 do
      for J := 0 to 7 do
        with FRawBoard.Field[I, J] do
        begin
          if Kind in [pkPawn, pkRook, pkQueen] then
            Exit;
          if Kind = pkKnight then
          begin
            // knights (no more than one)
            Inc(Knights);
            if Knights > 1 then
              Exit;
          end;
          if Kind = pkBishop then
          begin
            // bishops (at same color of cells)
            if (I + J) and 1 = 0 then
              Inc(BishopsWhite)
            else
              Inc(BishopsBlack);
            if (BishopsWhite > 0) and (BishopsBlack > 0) then
              Exit;
          end;
        end;
    // knights and bishops are not allowed!
    if (Knights = 1) and (BishopsWhite + BishopsBlack > 0) then
      Exit;
    Result := True;
  end;

begin
  // we cannot check invalid position
  if ValidatePosition <> vrOK then
    raise EChessRules.Create(SInvalidPosition);
  GetKingXY(KingX, KingY);
  GeneratedCount := ChessRules.GenerateMoves(FRawBoard, nil, True, 1);
  if GeneratedCount = 0 then
  begin
    // we have no moves, checkmate or stalemate.
    if AttackCount(FRawBoard, KingX, KingY, not FRawBoard.MoveSide, 1) >
      0 then
      Result.Kind := geCheckMate
    else
      Result.Kind := geStaleMate;
  end
  else
  begin
    // check for draw by 50 moves
    if FRawBoard.MoveCounter >= MaxMoves * 2 then
      Result.Kind := ge50Moves
    else
      Result.Kind := geNone;
  end;
  // check for insufficient material
  if IsInsufficientMaterial then
    Result.Kind := geInsufficientMaterial;
  // put winner
  case Result.Kind of
    geCheckMate: if FRawBoard.MoveSide = pcWhite then
        Result.Winner := gwBlack
      else
        Result.Winner := gwWhite;
    geStaleMate, ge50Moves, geInsufficientMaterial: Result.Winner := gwDraw;
    geNone: Result.Winner := gwNone;
  end;
end;

function TChessBoard.ValidatePosition: TValidationResult;
  // Position validator.
var
  WhiteKingCount, BlackKingCount: integer;
  WhitePieceCount, BlackPieceCount: integer;
  I, J: integer;
  EnPassantPawn, EnPassantPrev: integer;
  C: TPieceColor;
begin
  with FRawBoard do
  begin
    // first, check for correctness
    // vrTooManyPieces, vrNoKing, vrTooManyKings
    WhiteKingCount := 0;
    BlackKingCount := 0;
    WhitePieceCount := 0;
    BlackPieceCount := 0;
    for I := 0 to 7 do
      for J := 0 to 7 do
      begin
        if Field[I, J].Kind = pkKing then
        begin
          if Field[I, J].Color = pcWhite then
            Inc(WhiteKingCount)
          else
            Inc(BlackKingCount);
        end;
        if Field[I, J].Kind <> pkNone then
        begin
          if Field[I, J].Color = pcWhite then
            Inc(WhitePieceCount)
          else
            Inc(BlackPieceCount);
        end;
      end;
    if (WhiteKingCount <> 1) or (BlackKingCount <> 1) then
    begin
      if (WhiteKingCount = 0) or (BlackKingCount = 0) then
        Exit(vrNoKing)
      else
        Exit(vrTooManyKings);
    end;
    if (WhitePieceCount > 16) or (BlackPieceCount > 16) then
      Exit(vrTooManyPieces);
    // vrIllegalPawnPosition
    for I := 0 to 7 do
      if (Field[I, 0].Kind = pkPawn) or (Field[I, 7].Kind = pkPawn) then
        Exit(vrIllegalPawnPosition);
    // vrOpponentKingAttacked
    MoveSide := not MoveSide;
    GetKingXY(I, J);
    MoveSide := not MoveSide;
    if AttackCount(FRawBoard, I, J, MoveSide, 1) > 0 then
      Exit(vrOpponentKingAttacked);
    Result := vrOK;
    // update incorrectly set field
    // correct castling booleans
    for C := Low(TPieceColor) to High(TPieceColor) do
    begin
      if C = pcWhite then
        J := 7
      else
        J := 0;
      if AllowCastling[C, csQueenSide] then
      begin
        if (Field[0, J].Color <> C) or (Field[4, J].Color <> C) or
          (Field[0, J].Kind <> pkRook) or (Field[4, J].Kind <> pkKing)
        then
          AllowCastling[C, csQueenSide] := False;
      end;
      if AllowCastling[C, csKingSide] then
      begin
        if (Field[7, J].Color <> C) or (Field[4, J].Color <> C) or
          (Field[7, J].Kind <> pkRook) or (Field[4, J].Kind <> pkKing)
        then
          AllowCastling[C, csKingSide] := False;
      end;
    end;
    // correct enpassant line
    if MoveSide = pcWhite then
    begin
      EnPassantPawn := 3;
      EnPassantPrev := 2;
    end
    else
    begin
      EnPassantPawn := 4;
      EnPassantPrev := 5;
    end;
    // on (EnPassantLine, EnPassantPawn) there must be an enemy pawn
    if EnPassantLine >= 0 then
      if Field[EnPassantLine, EnPassantPawn] <> MakeBoardCell(pkPawn, not MoveSide)
      then
        EnPassantLine := -1;
    // on (EnPassantLine, EnPassantPrev) there must be an empty cell
    if EnPassantLine >= 0 then
      if Field[EnPassantLine, EnPassantPrev].Kind <> pkNone then
        EnPassantLine := -1;
  end;
end;

procedure TChessBoard.MakeMove(const Move: RChessMove);
// Makes a move.
var
  I: integer;
begin
  if not FAutoGenerateMoves then
  begin
    // just make a move and that's all.
    ChessRules.MakeMove(FRawBoard, Move);
    DoChange;
    Exit;
  end;
  // check if this move exists
  for I := 0 to FMoveCount - 1 do
    if FMoves[I] = Move then
    begin
      ChessRules.MakeMove(FRawBoard, FMoves[I]);
      DoChange;
      Exit;
    end;
  // if not exists, raise an exception
  raise EChessRules.Create(SIllegalMove);
end;

procedure TChessBoard.DoChange;
// Called when somethings has changed.
begin
  if Updating then
    Exit;
  ClearList;
  if FAutoGenerateMoves then
    GenerateMoves;
  inherited;
end;

function TChessBoard.GetCheckKind: TCheckKind;
  // Returns check kind.
begin
  Result := ChessRules.GetCheckKind(FRawBoard);
end;

procedure TChessBoard.GetKingXY(out X, Y: integer);
// Returns king coordinates.
begin
  ChessRules.GetKingXY(FRawBoard, X, Y);
end;

constructor TChessBoard.Create(AAutoGen: boolean);
begin
  inherited Create;
  FAutoGenerateMoves := AAutoGen;
  FMoveCount := 0;
  SetLength(FMoves, 512);
  InitialPosition;
end;

destructor TChessBoard.Destroy;
begin
  inherited Destroy;
end;

end.
