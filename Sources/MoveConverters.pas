{
  This file is part of Chess 256.

  Copyright © 2016, 2018, 2020 Alexander Kernozhitsky <sh200105@mail.ru>

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
    This unit contains classes to convert chess moves from the string format to
    the one used in Chess 256 and vice versa.
}
unit MoveConverters;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  SysUtils, ChessRules;

resourcestring
  SConversionIllegalMove = 'Conversion error: illegal move.';
  SParserIllegalMove = 'Parsing error: illegal move.';
  SParserAmbiguity = 'Parsing error: ambiguity while parsing.';
  SParserNoParser = 'Parsing error: %s doesn''t support move parsing.';

type
  EMoveConversion = class(Exception);
  EMoveParser = class(Exception);

  { TAbstractMoveConverter }

  TAbstractMoveConverter = class
  protected
    // Abstract getters / setters
    function GetRawBoard: RRawBoard; virtual; abstract;
    procedure SetRawBoard(const AValue: RRawBoard); virtual; abstract;
  public
    property RawBoard: RRawBoard read GetRawBoard write SetRawBoard;
    constructor Create; overload;
    // Abstract methods
    constructor Create(ARawBoard: RRawBoard); virtual; overload;
    function GetMoveString(const AMove: RChessMove): string; virtual; abstract;
    function GetMoveSeparator(InBeginning: boolean): string; virtual; abstract;
    function ParseMove(const MoveString: string): RChessMove; virtual;
  end;

  { TBoardMoveConverter }

  TBoardMoveConverter = class(TAbstractMoveConverter)
  private
    FChessBoard: TChessBoard;
  protected
    property ChessBoard: TChessBoard read FChessBoard;
    function GetRawBoard: RRawBoard; override;
    procedure SetRawBoard(const AValue: RRawBoard); override;
  public
    constructor Create(ARawBoard: RRawBoard); override;
    destructor Destroy; override;
  end;

type
  TStandardMoveConversionElement = string

    [32];

  RStandardMoveConversion = packed record
    PieceName: array [TPieceKind] of TStandardMoveConversionElement;
    CheckName: array [TCheckKind] of TStandardMoveConversionElement;
    Castling: array [TCastlingSide] of TStandardMoveConversionElement;
    CaptureMark: TStandardMoveConversionElement;
    MoveMark: TStandardMoveConversionElement;
    PromoteMark: TStandardMoveConversionElement;
    BeforeAdditionalCoordinate: TStandardMoveConversionElement;
    Tag: integer;
  end;

const
  DefaultMoveConversion: RStandardMoveConversion =
    (
    PieceName: ('?', '', 'N', 'B', 'R', 'Q', 'K');
    CheckName: ('', '+', '++', '#');
    Castling: ('O-O', 'O-O-O');
    CaptureMark: 'x';
    MoveMark: '';
    PromoteMark: '=';
    BeforeAdditionalCoordinate: '';
    Tag: 0
    );

  NotationMoveConversion: RStandardMoveConversion =
    (
    PieceName: ('?', '', '♘', '♗', '♖', '♕', '♔');
    CheckName: ('', '+', '++', '#');
    Castling: ('O-O', 'O-O-O');
    CaptureMark: 'x';
    MoveMark: '';
    PromoteMark: '';
    BeforeAdditionalCoordinate: '';
    Tag: 0
    );

type

  { TStandardMoveConverter }

  TStandardMoveConverter = class(TBoardMoveConverter)
  private
    FMoveConversion: RStandardMoveConversion;
  public
    property MoveConversion: RStandardMoveConversion
      read FMoveConversion write FMoveConversion;
    constructor Create(ARawBoard: RRawBoard); override;
    function GetMoveString(const AMove: RChessMove): string; override;
    function GetMoveSeparator(InBeginning: boolean): string; override;
  end;

  { TPGNMoveConverter }

  TPGNMoveConverter = class(TStandardMoveConverter)
  public
    function ParseMove(const MoveString: string): RChessMove; override;
  end;

  { TNotationMoveConverter }

  TNotationMoveConverter = class(TStandardMoveConverter)
  public
    procedure AfterConstruction; override;
  end;

  { TUCIMoveConverter }

  TUCIMoveConverter = class(TBoardMoveConverter)
  public
    function GetMoveString(const AMove: RChessMove): string; override;
    function GetMoveSeparator(InBeginning: boolean): string; override;
    function ParseMove(const MoveString: string): RChessMove; override;
  end;

function CellToString(X, Y: integer): string;

implementation

function CellToString(X, Y: integer): string;
  // Converts the coordinates on the board to string.
begin
  Result := Chr(X + Ord('a')) + Chr(7 - Y + Ord('1'));
end;

{ TAbstractMoveConverter }

constructor TAbstractMoveConverter.Create;
begin
  Create(GetInitialPosition);
end;

constructor TAbstractMoveConverter.Create(ARawBoard: RRawBoard);
begin
  SetRawBoard(ARawBoard);
end;

{$HINTS OFF}
function TAbstractMoveConverter.ParseMove(const MoveString: string): RChessMove;
begin
  Result.Kind := mkImpossible;
  raise EMoveParser.CreateFmt(SParserNoParser, [ClassName]);
end;

{$HINTS ON}

{ TBoardMoveConverter }

function TBoardMoveConverter.GetRawBoard: RRawBoard;
begin
  Result := FChessBoard.RawBoard;
end;

procedure TBoardMoveConverter.SetRawBoard(const AValue: RRawBoard);
begin
  FChessBoard.RawBoard := AValue;
end;

constructor TBoardMoveConverter.Create(ARawBoard: RRawBoard);
begin
  FChessBoard := TChessBoard.Create;
  inherited Create(ARawBoard);
end;

destructor TBoardMoveConverter.Destroy;
begin
  FreeAndNil(FChessBoard);
  inherited Destroy;
end;

{ TStandardMoveConverter }

constructor TStandardMoveConverter.Create(ARawBoard: RRawBoard);
begin
  FMoveConversion := DefaultMoveConversion;
  inherited Create(ARawBoard);
end;

function TStandardMoveConverter.GetMoveString(const AMove: RChessMove): string;
var
  NewMove: RChessMove;
  I: integer;
  SimillarX, SimillarY, SimillarAll: boolean;

  function FindNewMove: boolean;
    // Returns True if such move exists.
  var
    I: integer;
  begin
    Result := True;
    with ChessBoard do
    begin
      for I := 0 to MoveCount - 1 do
        if Moves[I] = AMove then
        begin
          NewMove := Moves[I];
          Exit;
        end;
    end;
    Result := False;
  end;

begin
  // check if exists
  if not FindNewMove then
    raise EMoveConversion.Create(SConversionIllegalMove);
  // start converting
  Result := '';
  with NewMove, FMoveConversion do
  begin
    // castling
    if Kind = mkCastling then
    begin
      // castling is simple enough
      if DstX = 2 then
        Result := Castling[csQueenSide]
      else
        Result := Castling[csKingSide];
      Result := Result + CheckName[Check];
      Exit;
    end;
    // pawn moves
    if (Kind = mkPromote) or (PromoteTo = pkPawn) then
    begin
      Result := PieceName[pkPawn];
      // different notation for simple moves and captures
      if not IsCapture then
        Result := Result + MoveMark + CellToString(DstX, DstY)
      else
        Result := Result + BeforeAdditionalCoordinate +
          Chr(Ord('a') + SrcX) + CaptureMark + CellToString(DstX, DstY);
      // promotion
      if Kind = mkPromote then
        Result := Result + PromoteMark + PieceName[PromoteTo];
      Result := Result + CheckName[Check];
      Exit;
    end;
    // other moves
    SimillarX := False;
    SimillarY := False;
    SimillarAll := False;
    // calculation SimillarX and SimillarY.
    // SimillarX = True if there exists a move with the same piece, dst & srcX.
    // SimillarY = True if there exists a move with the same piece, dst & srcY.
    with ChessBoard do
    begin
      for I := 0 to MoveCount - 1 do
        with Moves[I] do
        begin
          // pieces must not differ
          if (Kind = mkPromote) or (PromoteTo <> NewMove.PromoteTo) then
            Continue;
          // dst cells must mot differ
          if (DstX <> NewMove.DstX) or (DstY <> NewMove.DstY) then
            Continue;
          // we don't count this move!
          if (SrcX = NewMove.SrcX) and (SrcY = NewMove.SrcY) then
            Continue;
          // updating
          SimillarAll := True;
          if SrcX = NewMove.SrcX then
            SimillarX := True;
          if SrcY = NewMove.SrcY then
            SimillarY := True;
        end;
    end;
    Result := PieceName[PromoteTo];
    if SimillarAll then
    begin
      // adding additional coordinates
      // for example, if both moves Ra1e1 & Rf1e1 are possible.
      // then, one of them will be Rae1 and the other one will be Rfe1.
      if (not SimillarX) and (not SimillarY) then
        SimillarY := True;
      if SimillarX or SimillarY then
        Result := Result + BeforeAdditionalCoordinate;
      if SimillarY then
        Result := Result + Chr(Ord('a') + SrcX);
      if SimillarX then
        Result := Result + Chr(7 - SrcY + Ord('1'));
    end;
    if IsCapture then
      Result := Result + CaptureMark
    else
      Result := Result + MoveMark;
    Result := Result + CellToString(DstX, DstY) + CheckName[Check];
  end;
end;

function TStandardMoveConverter.GetMoveSeparator(InBeginning: boolean): string;
begin
  if InBeginning then
  begin
    // if in beginning, then move is "1. e4" for white & "1... e5" for black
    if RawBoard.MoveSide = pcWhite then
      Result := Format('%d. ', [RawBoard.MoveNumber])
    else
      Result := Format('%d... ', [RawBoard.MoveNumber]);
  end
  else
  begin
    // if not in beginning, then move is "2. Nf3" for white and just "Nc6" for black.
    if RawBoard.MoveSide = pcWhite then
      Result := Format('%d. ', [RawBoard.MoveNumber])
    else
      Result := '';
  end;
end;

{ TPGNMoveConverter }

function TPGNMoveConverter.ParseMove(const MoveString: string): RChessMove;
type
  TMoveParseResult = (prOK, prNoSuchMove, prAmbiguous);

const
  NumCoords = ['1' .. '8'];
  LetCoords = ['a' .. 'h'];
  AfterSymbols = ['x', '+', '#', '!', '?'];
  InsideSymbols = [':', 'x', '-'];

var
  DstX, DstY, SrcX, SrcY: integer;
  ActivePiece: TPieceKind;
  PromoteTo: TPieceKind;
  IsCastling: boolean;
  CastlingSide: TCastlingSide;
  IsShortPawnCapture: boolean;
  IsCorrect: boolean;

  procedure CleanVars;
  // Clears the variables.
  begin
    DstX := -1;
    DstY := -1;
    SrcX := -1;
    SrcY := -1;
    ActivePiece := pkNone;
    PromoteTo := pkNone;
    IsCastling := False;
    IsShortPawnCapture := False;
    IsCorrect := False;
  end;

  procedure MoveParser(S: string);
  // Parses the moves and puts the parsing result into local variables.
  var
    DelFirst: boolean;
    CrdX, CrdY: char;
    I: integer;
  begin
    CleanVars;
    // castling moves
    if (UpCase(S) = 'O-O') or (S = '0-0') then
    begin
      // kingside
      IsCastling := True;
      IsCorrect := True;
      CastlingSide := csKingSide;
      Exit;
    end;
    if (UpCase(S) = 'O-O-O') or (S = '0-0-0') then
    begin
      // queenside
      IsCastling := True;
      IsCorrect := True;
      CastlingSide := csQueenSide;
      Exit;
    end;
    // search for promotions at the end of the string
    if S = '' then
      Exit;
    // skip symbols that may come after promotions
    while (S <> '') and (S[Length(S)] in AfterSymbols) do
      Delete(S, Length(S), 1);
    if S = '' then
      Exit;
    DelFirst := True;
    case S[Length(S)] of
      'P', 'p': PromoteTo := pkPawn;
      'N', 'n': PromoteTo := pkKnight;
      'B', 'b': PromoteTo := pkBishop;
      'R', 'r': PromoteTo := pkRook;
      'Q', 'q': PromoteTo := pkQueen;
      'K', 'k': PromoteTo := pkKing
      else
        DelFirst := False;
    end;
    // delete the promotion
    if DelFirst then
      Delete(S, Length(S), 1);
    // skip "=" that may come before promotion
    if (S <> '') and (S[Length(S)] = '=') then
      Delete(S, Length(S), 1);
    // check for short pawn captures (like ed, ab, fg, ...)
    if (Length(S) = 2) and (S[1] in LetCoords) and (S[2] in LetCoords) then
    begin
      IsShortPawnCapture := True;
      SrcX := Ord(S[1]) - Ord('a');
      DstX := Ord(S[2]) - Ord('a');
      ActivePiece := pkPawn;
      IsCorrect := True;
      Exit;
    end;
    // dst coodinates
    if Length(S) < 2 then
      Exit;
    CrdX := S[Length(S) - 1];
    CrdY := S[Length(S)];
    if not (CrdX in LetCoords) or not (CrdY in NumCoords) then
      Exit;
    DstX := Ord(CrdX) - Ord('a');
    DstY := 7 - Ord(CrdY) + Ord('1');
    Delete(S, Length(S) - 1, 2);
    // piece letter
    if S = '' then
      S := 'P';
    DelFirst := True;
    case S[1] of
      'P', 'p': ActivePiece := pkPawn;
      'N', 'n': ActivePiece := pkKnight;
      'B': ActivePiece := pkBishop;
      // small "b" is not allowed (or how to parse "bxa3"?)
      'R', 'r': ActivePiece := pkRook;
      'Q', 'q': ActivePiece := pkQueen;
      'K', 'k': ActivePiece := pkKing
      else
        DelFirst := False;
    end;
    if DelFirst then
      Delete(S, 1, 1);
    // src coordinates
    for I := 1 to Length(S) do
    begin
      if S[I] in LetCoords then
      begin
        if SrcX >= 0 then
          Exit;
        SrcX := Ord(S[I]) - Ord('a');
        Continue;
      end;
      if S[I] in NumCoords then
      begin
        if SrcY >= 0 then
          Exit;
        SrcY := 7 - Ord(S[I]) + Ord('1');
        Continue;
      end;
      if not (S[I] in InsideSymbols) then
        Exit;
    end;
    // now make ActivePiece := pkPawn if there was no first letter and
    // the move is not like "g1f3".
    if (ActivePiece = pkNone) and not ((SrcX >= 0) and (SrcY >= 0)) then
      ActivePiece := pkPawn;
    IsCorrect := True;
  end;

  function ExtractChessMove(out Move: RChessMove): TMoveParseResult;
    // Extracts a chess move from the local variables.
  var
    FitCount: integer = 0;
    I: integer;

    function MoveFits(const Move: RChessMove): boolean;
      // Returns True if Move fits the parsed move.
    var
      NActivePiece: TPieceKind;
      NDstX, NDstY, NSrcX, NSrcY: integer;
    begin
      Result := False;
      if not IsCorrect then
        Exit;
      if IsCastling then
      begin
        // parsed move was castling
        if Move.Kind <> mkCastling then
          Exit;
        if (CastlingSide = csKingSide) and (Move.DstX <> 6) then
          Exit;
        if (CastlingSide = csQueenSide) and (Move.DstX <> 2) then
          Exit;
        Result := True;
        Exit;
      end;
      // make local copy of vars (we'll change them)
      NActivePiece := ActivePiece;
      NSrcX := SrcX;
      NSrcY := SrcY;
      NDstX := DstX;
      NDstY := DstY;
      if PromoteTo <> pkNone then
      begin
        // parsed move was promotion
        if Move.Kind <> mkPromote then
          Exit;
        if not (NActivePiece in [pkNone, pkPawn]) then
          Exit;
        NActivePiece := PromoteTo;
      end
      else if Move.Kind = mkPromote then
        Exit;
      // checking short form of pawn capture
      if IsShortPawnCapture then
      begin
        if (NActivePiece <> Move.PromoteTo) or (NSrcX <> Move.SrcX) or
          (NDstX <> Move.DstX) then
          Exit;
        Result := True;
        Exit;
      end;
      // checking piece, src & dst.
      if NActivePiece = pkNone then
        NActivePiece := Move.PromoteTo;
      if NSrcX < 0 then
        NSrcX := Move.SrcX;
      if NSrcY < 0 then
        NSrcY := Move.SrcY;
      if (NActivePiece <> Move.PromoteTo) or (NSrcX <> Move.SrcX) or
        (NSrcY <> Move.SrcY) or (NDstX <> Move.DstX) or (NDstY <> Move.DstY) then
        Exit;
      Result := True;
    end;

  begin
    Move.Kind := mkImpossible;
    // check every move if it fits.
    with ChessBoard do
      for I := 0 to MoveCount - 1 do
        if MoveFits(Moves[I]) then
        begin
          Move := Moves[I];
          Inc(FitCount);
        end;
    // only 1 move must fit
    if FitCount = 1 then
      Result := prOk
    else if FitCount = 0 then
      Result := prNoSuchMove
    else
      Result := prAmbiguous;
  end;

var
  Res: TMoveParseResult;
begin
  MoveParser(MoveString);
  Res := ExtractChessMove(Result);
  if Res = prOK then
    Exit;
  if Res = prAmbiguous then
    raise EMoveParser.Create(SParserAmbiguity)
  else
    raise EMoveParser.Create(SParserIllegalMove);
end;

{ TNotationMoveConverter }

procedure TNotationMoveConverter.AfterConstruction;
begin
  inherited AfterConstruction;
  FMoveConversion := NotationMoveConversion;
end;

{ TUCIMoveConverter }

function TUCIMoveConverter.GetMoveString(const AMove: RChessMove): string;
const
  PieceNames: array [TPieceKind] of string = ('', '', 'n', 'b', 'r', 'q', 'k');
begin
  // uci moves are "e2e4", "e1g1" etc, promotes are "e7e8q".
  // it's simple, isn't it?
  Result := CellToString(AMove.SrcX, AMove.SrcY) +
    CellToString(AMove.DstX, AMove.DstY);
  if AMove.Kind = mkPromote then
    Result := Result + PieceNames[AMove.PromoteTo];
end;

{$HINTS OFF}
function TUCIMoveConverter.GetMoveSeparator(InBeginning: boolean): string;
begin
  Result := '';
end;

{$HINTS ON}

function TUCIMoveConverter.ParseMove(const MoveString: string): RChessMove;

  function MoveParser(S: string; out AMove: RChessMove): boolean;
    // UCI move parser. Converts string into move. Returns True if success.
  var
    SX, SY, DX, DY: integer;
  begin
    AMove.Kind := mkImpossible;
    S := LowerCase(S);
    Result := False;
    // validation
    if (Length(S) <> 4) and (Length(S) <> 5) then
      Exit;
    if not (S[1] in ['a' .. 'h']) then
      Exit;
    if not (S[2] in ['1' .. '8']) then
      Exit;
    if not (S[3] in ['a' .. 'h']) then
      Exit;
    if not (S[4] in ['1' .. '8']) then
      Exit;
    // parsing coordinates
    SX := Ord(S[1]) - Ord('a');
    SY := 7 - Ord(S[2]) + Ord('1');
    DX := Ord(S[3]) - Ord('a');
    DY := 7 - Ord(S[4]) + Ord('1');
    AMove := ChessBoard.GetMove(SX, SY, DX, DY);
    if AMove.Kind = mkImpossible then
      Exit;
    // now, parsing promotions
    if (Length(S) = 5) xor (AMove.Kind = mkPromote) then
      Exit;
    if Length(S) = 5 then
    begin
      case S[5] of
        'n': AMove.PromoteTo := pkKnight;
        'b': AMove.PromoteTo := pkBishop;
        'r': AMove.PromoteTo := pkRook;
        'q': AMove.PromoteTo := pkQueen
        else
          Exit;
      end;
    end;
    Result := True;
  end;

begin
  if not MoveParser(MoveString, Result) then
    raise EMoveParser.Create(SParserIllegalMove);
end;

end.
