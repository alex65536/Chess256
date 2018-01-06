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
    This file contains the real implementation for the abstract TTextViewer.

  Creation date: 07.06.2016.

  This unit is tested for Lazarus 1.6 - 1.8, FPC 3.0.0 - 3.0.4.
  THIS UNIT IS BETA, IT CAN BE OPTIMIZED!!!

  Known issues:
    * Low speed because of full refreshing (?)
    * Redrawing must be optimized.
    * Diacritic symbols may result in incorrect cursor drawing.
  To be made:
    < nothing at this moment of time >
}
unit TextViewImpl;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Forms, ExtCtrls, StdCtrls, TextViewBase, Graphics, FGL, LCLIntf, Types, Math,
  SysUtils, LazUTF8, Classes, Controls, Utilities;

const
  CursorWidth = 2;

  WHEEL_DELTA = 120; // This was in Windows unit ...

type
  TFormatText = class;
  TTextPiece = class;
  TAddPieceProc = procedure(Piece: TTextPiece) of object;
  TTextPieceList = specialize TFPGObjectList<TTextPiece>;

  TCharInfo = record
    Style: TCharStyle;
    Size: TSize;
  end;

  { TTextViewImplFrame }

  TTextViewImplFrame = class(TFrame)
    PaintBox: TPaintBox;
    Panel: TPanel;
    ScrollBar: TScrollBar;
    Timer: TTimer;
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxResize(Sender: TObject);
    procedure PanelMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
    procedure ScrollBarChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    FDrawCursor: boolean;
    FText: TFormatText;
    FList: TTextPieceList;
    FTempBuffer: TBitmap; // a buffer to output the image
    FScrollBarRepaintOnChange: boolean; // if True, we'll call repaint on ScrollBox.OnChange
    // Methods
    procedure AddPiece(APiece: TTextPiece);
    procedure SetDrawCursor(AValue: boolean);
    procedure UpdateTempBuffer;
    procedure CalcScrollBar;
  public
    // Properties
    property DrawCursor: boolean read FDrawCursor write SetDrawCursor;
    property Text: TFormatText read FText;
    // Painting methods
    procedure PaintCursor;
    procedure UpdateAndDraw;
    procedure ScrollToCursor;
    procedure UpdateText;
    // Other methods
    function CharAtPos(X, Y: integer): integer;
    procedure AfterConstruction; override;
    destructor Destroy; override;
  end;

  { TTextViewerImpl }

  TTextViewerImpl = class(TAbstractTextViewer)
  private
    FControl: TTextViewImplFrame;
    procedure PutCursorPos(AValue: integer);
  protected
    function GetControl: TControl; override;
    function GetText: string; override;
    function GetCursorPos: integer; override;
    procedure SetCursorPos(const AValue: integer); override;
    function GetCharStyle(I: integer): TCharStyle; override;
    procedure DoUpdate; override;
    // Internals
    procedure InternalInsertText(const S: string; const AStyle: TCharStyle;
      Beg: integer); override;
    procedure InternalInsertText(AChunk: TAbstractTextChunk;
      Pos, Beg, Len: integer); override;
    procedure InternalAddText(const S: string; const AStyle: TCharStyle); override;
    procedure InternalAddText(AChunk: TAbstractTextChunk; Beg, Len: integer); override;
    procedure InternalDeleteText(Beg, Len: integer); override;
    procedure InternalSetText(const S: string; const AStyle: TCharStyle); override;
    procedure InternalClear; override;
    function InternalCharAtPos(X, Y: integer): integer; override;
    function InternalCopy(Beg, Len: integer): TAbstractTextChunk; override;
  published
    constructor Create(AOwner: TComponent); override;
  end;

  { TFormatTextChunk }

  TFormatTextChunk = class(TAbstractTextChunk)
  private
    FText: string;
    FList: array of TCharInfo;
  public
    constructor Create;
    constructor Create(const AText: string; const AStyle: TCharStyle);
  end;

  { TFormatText }

  TFormatText = class
  private
    FCanvas: TCanvas;
    FCursorPos: integer;
    FUpdating: integer;
    FList: array of TCharInfo;
    FText: string;
    FCapacity: integer;
    // Getters / Setters
    function GetCharSize(I: integer): TSize;
    function GetCharStyle(I: integer): TCharStyle;
    function GetSize: integer;
    procedure SetCanvas(AValue: TCanvas);
    procedure SetCharSize(I: integer; AValue: TSize);
    procedure SetCharStyle(I: integer; AValue: TCharStyle);
    procedure SetCursorPos(AValue: integer);
    procedure SetText(const AValue: string);
  protected
    function BuildStyleTable(Beg, Len: integer): TVectorPairIntInt;
    procedure ResizeList(AValue: integer);
    procedure CutFromSeparators(var Beg, Len: integer; MinSize: integer);
  public
    // !!! Everything is 1-indexed here !!!
    // Properties
    property Canvas: TCanvas read FCanvas write SetCanvas;
    property Text: string read FText write SetText;
    property Size: integer read GetSize;
    property CharStyle[I: integer]: TCharStyle read GetCharStyle write SetCharStyle;
    property CharSize[I: integer]: TSize read GetCharSize write SetCharSize;
    property CursorPos: integer read FCursorPos write SetCursorPos;
    // Inserting / Deleting
    procedure InsertText(const S: string; const AStyle: TCharStyle;
      Beg: integer); overload;
    procedure InsertText(AChunk: TFormatTextChunk; Pos, Beg, Len: integer); overload;
    procedure AddText(const S: string; const AStyle: TCharStyle); overload;
    procedure AddText(AChunk: TFormatTextChunk; Beg, Len: integer); overload;
    procedure DeleteText(Beg, Len: integer);
    procedure Clear;
    procedure PutText(const S: string; const AStyle: TCharStyle);
    function CopyText(Beg, Len: integer): TFormatTextChunk;
    // Constructors / Destructors
    constructor Create(ACanvas: TCanvas);
    destructor Destroy; override;
    // Drawing features
    function GetSize(Beg, Len: integer; SkipSeparators: boolean): TSize;
    procedure DrawPiece(Beg, Len: integer; AX, AY: integer);
    procedure DrawCursor(Beg, Len: integer; AX, AY: integer);
    function CanDrawCursor(Beg, Len: integer): boolean;
    procedure CalcWidths(Beg, Len: integer);
    procedure DivideIntoPieces(Beg, Len: integer; AWidth: integer;
      AddPiece: TAddPieceProc);
    procedure DivideText(AWidth: integer; AddPiece: TAddPieceProc);
    function CharAtPos(Beg, Len: integer; X: integer): integer;
  end;

  { TTextPiece }

  TTextPiece = class
  private
    FParent: TFormatText;
    FStart, FLength: integer;
    FSize: TSize;
  public
    // Properties
    property Parent: TFormatText read FParent;
    property Start: integer read FStart;
    property Length: integer read FLength;
    property Size: TSize read FSize;
    // Methods
    constructor Create(AParent: TFormatText; AStart, ALength: integer; ASize: TSize);
    destructor Destroy; override;
    procedure DrawPiece(AX, AY: integer);
    procedure DrawCursor(AX, AY: integer);
    function CanDrawCursor: boolean;
    function CharAtPos(X: integer): integer;
  end;

operator := (Style: TCharStyle): TCharInfo;

implementation

const
  Separators = [#0, #9, #10, #13, ' '];

{$R *.lfm}

operator := (Style: TCharStyle): TCharInfo;
begin
  Result.Style := Style;
  Result.Size.cx := 0;
  Result.Size.cy := 0;
end;

{ TTextViewImplFrame }

procedure TTextViewImplFrame.PaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  MouseDown(Button, Shift, X, Y);
end;

procedure TTextViewImplFrame.PaintBoxPaint(Sender: TObject);
begin
  PaintBox.Canvas.Draw(0, 0, FTempBuffer);
end;

procedure TTextViewImplFrame.PaintBoxResize(Sender: TObject);
begin
  UpdateText;
end;

{$HINTS OFF}
procedure TTextViewImplFrame.PanelMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: integer; MousePos: TPoint; var Handled: boolean);
var
  Pos: integer;
begin
  Pos := ScrollBar.Position - WheelDelta div WHEEL_DELTA;
  if Pos < 0 then
    Pos := 0;
  if Pos > ScrollBar.Max then
    Pos := ScrollBar.Max;
  ScrollBar.Position := Pos;
  Handled := True;
end;

{$HINTS ON}

procedure TTextViewImplFrame.ScrollBarChange(Sender: TObject);
begin
  if FScrollBarRepaintOnChange then
    UpdateAndDraw;
end;

procedure TTextViewImplFrame.TimerTimer(Sender: TObject);
begin
  // This code enables cursor blinking.
  DrawCursor := not DrawCursor;
end;

procedure TTextViewImplFrame.AddPiece(APiece: TTextPiece);
// Event handler to add a piece.
begin
  FList.Add(APiece);
end;

procedure TTextViewImplFrame.SetDrawCursor(AValue: boolean);
begin
  if FDrawCursor = AValue then
    Exit;
  FDrawCursor := AValue;
  PaintCursor;
  PaintBox.Refresh;
end;

procedure TTextViewImplFrame.UpdateTempBuffer;
// Draws the text into FTempBuffer.
var
  I, Y: integer;
begin
  FTempBuffer.SetSize(PaintBox.Width, PaintBox.Height);
  with FTempBuffer do
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(Rect(0, 0, Width, Height));
  end;
  Y := 0;
  for I := ScrollBar.Position to FList.Count - 1 do
  begin
    FList[I].DrawPiece(0, Y);
    Y += FList[I].Size.cy;
    if Y > FTempBuffer.Height then
      Break;
  end;
end;

procedure TTextViewImplFrame.CalcScrollBar;
// Finds the scroll bar size using binary search.

  function Ends(Position: integer): boolean; inline;
    // Checks if this scroll bar size possible.
  var
    Y: integer;
    I: integer;
  begin
    Y := 0;
    Result := False;
    for I := Position to FList.Count - 1 do
    begin
      Inc(Y, FList[I].Size.cy);
      if Y > PaintBox.Height then
        Exit;
    end;
    Result := True;
  end;

var
  L, M, R: integer;
begin
  L := 0;
  R := FList.Count - 1;
  while L < R do
  begin
    M := (L + R) div 2;
    if Ends(M) then
      R := M
    else
      L := M + 1;
  end;
  ScrollBar.Max := L;
end;

procedure TTextViewImplFrame.PaintCursor;
// Draws (or undraws) the cursor. Drawing and undrawing happens because of Pen.Mode = pmXor.
var
  I, Y: integer;
begin
  Y := 0;
  for I := ScrollBar.Position to FList.Count - 1 do
  begin
    FList[I].DrawCursor(0, Y);
    Y += FList[I].Size.cy;
    if Y > FTempBuffer.Height then
      Break;
  end;
end;

procedure TTextViewImplFrame.UpdateAndDraw;
// Full refresh. Updates and redraws EVERYTHING.
begin
  UpdateTempBuffer;
  if FDrawCursor then
    PaintCursor;
  PaintBox.Refresh;
end;

procedure TTextViewImplFrame.ScrollToCursor;
// Scrolls to current cursor position.
var
  Pos: integer;

  function GetPos: integer; inline;
    // Returns the current cursor position (-1 if not found)
  var
    I: integer;
  begin
    for I := 0 to FList.Count - 1 do
      if FList[I].CanDrawCursor then
        Exit(I);
    Result := -1;
  end;

  function RelativePosition(Position: integer): integer; inline;
    // Imagine that ScrollBar.Position = Position. Then, function returns:
    //   -1 if cursor will be higher.
    //    0 if cursor will be seen.
    //    1 if cursor will be lower.
  var
    Y, I: integer;
  begin
    if Pos < Position then
      Exit(-1);
    if Pos = Position then
      Exit(0);
    Y := 0;
    for I := Position to FList.Count - 1 do
    begin
      Inc(Y, FList[I].Size.cy);
      if Y > PaintBox.Height then
        Exit(1);
      if I = Pos then
        Exit(0);
    end;
    Exit(1);
  end;

var
  L, M, R, OurPos: integer;
begin
  Pos := GetPos;
  if Pos < 0 then
    Exit; // no cursor - no scrolling :)
  OurPos := ScrollBar.Position;
  case RelativePosition(OurPos) of
    -1:
    begin
      // our cursor is higher, just make it last shown line (first available position)
      L := 0;
      R := ScrollBar.Max;
      while L < R do
      begin
        M := (L + R) div 2;
        if RelativePosition(M) <= 0 then
          R := M
        else
          L := M + 1;
      end;
      ScrollBar.Position := L;
    end;
    0: {do nothing}; // our cursor is seen, don't change anything.
    1:
    begin
      // our cursor is lower, just make it first shown line.
      ScrollBar.Position := Min(Pos, ScrollBar.Max);
    end;
  end;
end;

procedure TTextViewImplFrame.UpdateText;
// Full refresh with recalculating lines (if the text was changed).
begin
  FScrollBarRepaintOnChange := False;
  // divide text
  FList.Clear;
  FText.DivideText(PaintBox.Width - CursorWidth - 1, @AddPiece);
  // recalc scroll bar
  CalcScrollBar;
  ScrollToCursor;
  // redraw
  UpdateAndDraw;
  FScrollBarRepaintOnChange := True;
end;

function TTextViewImplFrame.CharAtPos(X, Y: integer): integer;
  // Returns what character there is on position (X; Y).
var
  QY: integer;
  I: integer;
begin
  QY := 0;
  for I := ScrollBar.Position to FList.Count - 1 do
    if QY + FList[I].Size.cy > Y then
      Exit(FList[I].CharAtPos(X))
    else
      QY += FList[I].Size.cy;
  Result := FText.Size;
end;

procedure TTextViewImplFrame.AfterConstruction;
// Initialize everything.
begin
  inherited AfterConstruction;
  FDrawCursor := True;
  FTempBuffer := TBitmap.Create;
  FText := TFormatText.Create(FTempBuffer.Canvas);
  FList := TTextPieceList.Create(True);
  DoubleBuffered := True;
  Panel.DoubleBuffered := True;
  with FTempBuffer.Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := PaintBox.Color;
    Pen.Width := CursorWidth;
    Pen.Mode := pmNot;
  end;
end;

destructor TTextViewImplFrame.Destroy;
begin
  FreeAndNil(FText);
  FreeAndNil(FList);
  FreeAndNil(FTempBuffer);
  inherited Destroy;
end;

{ TTextViewerImpl }

procedure TTextViewerImpl.PutCursorPos(AValue: integer);
// Just updates the cursor position in FControl.Text.
begin
  if AValue < 0 then
    FControl.Text.CursorPos := 0;
  if AValue > Length(Text) then
    FControl.Text.CursorPos := Length(Text);
  FControl.Text.CursorPos := AValue;
end;

function TTextViewerImpl.GetControl: TControl;
begin
  Result := FControl;
end;

function TTextViewerImpl.GetText: string;
begin
  Result := FControl.Text.Text;
end;

function TTextViewerImpl.GetCursorPos: integer;
begin
  Result := FControl.Text.CursorPos;
end;

procedure TTextViewerImpl.SetCursorPos(const AValue: integer);
// Changes the cursor position and redraws the control.
begin
  if IsUpdating then
  begin
    FControl.Text.CursorPos := AValue;
    Exit;
  end;
  FControl.DrawCursor := False;
  PutCursorPos(AValue);
  FControl.DrawCursor := True;
  FControl.ScrollToCursor;
  FControl.Refresh;
end;

function TTextViewerImpl.GetCharStyle(I: integer): TCharStyle;
begin
  Result := FControl.Text.CharStyle[I];
end;

procedure TTextViewerImpl.DoUpdate;
// Updates the text.
begin
  PutCursorPos(CursorPos);
  FControl.UpdateText;
  FControl.DrawCursor := True;
end;

procedure TTextViewerImpl.InternalInsertText(const S: string;
  const AStyle: TCharStyle; Beg: integer);
begin
  FControl.Text.InsertText(S, AStyle, Beg);
end;

procedure TTextViewerImpl.InternalInsertText(AChunk: TAbstractTextChunk;
  Pos, Beg, Len: integer);
begin
  FControl.Text.InsertText(AChunk as TFormatTextChunk, Pos, Beg, Len);
end;

procedure TTextViewerImpl.InternalAddText(const S: string; const AStyle: TCharStyle);
begin
  FControl.Text.AddText(S, AStyle);
end;

procedure TTextViewerImpl.InternalAddText(AChunk: TAbstractTextChunk;
  Beg, Len: integer);
begin
  FControl.Text.AddText(AChunk as TFormatTextChunk, Beg, Len);
end;

procedure TTextViewerImpl.InternalDeleteText(Beg, Len: integer);
begin
  FControl.Text.DeleteText(Beg, Len);
end;

procedure TTextViewerImpl.InternalSetText(const S: string; const AStyle: TCharStyle);
begin
  FControl.Text.PutText(S, AStyle);
end;

procedure TTextViewerImpl.InternalClear;
begin
  FControl.Text.Clear;
end;

function TTextViewerImpl.InternalCharAtPos(X, Y: integer): integer;
begin
  Result := FControl.CharAtPos(X, Y);
end;

function TTextViewerImpl.InternalCopy(Beg, Len: integer): TAbstractTextChunk;
begin
  Result := FControl.Text.CopyText(Beg, Len);
end;

constructor TTextViewerImpl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FControl := TTextViewImplFrame.Create(Self);
end;

{ TFormatTextChunk }

constructor TFormatTextChunk.Create;
begin
  FText := '';
end;

constructor TFormatTextChunk.Create(const AText: string; const AStyle: TCharStyle);
var
  I: integer;
begin
  FText := AText;
  SetLength(FList, Length(AText));
  for I := 0 to Length(AText) - 1 do
    FList[I] := AStyle;
end;

{ TTextPiece }

constructor TTextPiece.Create(AParent: TFormatText; AStart, ALength: integer;
  ASize: TSize);
begin
  FParent := AParent;
  FStart := AStart;
  FLength := ALength;
  FSize := ASize;
end;

destructor TTextPiece.Destroy;
begin
  inherited Destroy;
end;

procedure TTextPiece.DrawPiece(AX, AY: integer);
begin
  FParent.DrawPiece(FStart, FLength, AX, AY);
end;

procedure TTextPiece.DrawCursor(AX, AY: integer);
begin
  Parent.DrawCursor(FStart, FLength, AX, AY);
end;

function TTextPiece.CanDrawCursor: boolean;
begin
  Result := Parent.CanDrawCursor(FStart, FLength);
end;

function TTextPiece.CharAtPos(X: integer): integer;
begin
  Result := Parent.CharAtPos(FStart, FLength, X);
end;

{ TFormatText }

function TFormatText.GetCharSize(I: integer): TSize;
begin
  Result := FList[I - 1].Size;
end;

function TFormatText.GetCharStyle(I: integer): TCharStyle;
begin
  Result := FList[I - 1].Style;
end;

function TFormatText.GetSize: integer;
begin
  Result := Length(FText);
end;

procedure TFormatText.SetCanvas(AValue: TCanvas);
begin
  if FCanvas = AValue then
    Exit;
  FCanvas := AValue;
  CalcWidths(1, Size);
end;

procedure TFormatText.SetCharSize(I: integer; AValue: TSize);
begin
  FList[I - 1].Size := AValue;
end;

procedure TFormatText.SetCharStyle(I: integer; AValue: TCharStyle);
begin
  FList[I - 1].Style := AValue;
end;

procedure TFormatText.SetCursorPos(AValue: integer);
begin
  if FCursorPos = AValue then
    Exit;
  FCursorPos := AValue;
end;

procedure TFormatText.SetText(const AValue: string);
begin
  if FText = AValue then
    Exit;
  PutText(AValue, DefaultCharStyle);
end;

function TFormatText.BuildStyleTable(Beg, Len: integer): TVectorPairIntInt;
  // Build the table of styles. Each of TPairIntInt contains a segment (Beg, Len)
  // of chars that have the same style.
var
  I, P, SegEnd: longint;
begin
  SegEnd := Beg + Len - 1;
  Result := TVectorPairIntInt.Create;
  I := Beg;
  while I <= SegEnd do
  begin
    P := I;
    while (I <= SegEnd) and (CharStyle[P] = CharStyle[I]) do
      Inc(I);
    Result.Add(TPairIntInt.MakePair(P, I - P));
  end;
end;

procedure TFormatText.ResizeList(AValue: integer);
// Resizes the list.
begin
  if AValue >= FCapacity then
  begin
    FCapacity := AValue * 2;
    SetLength(FList, FCapacity);
  end;
end;

procedure TFormatText.CutFromSeparators(var Beg, Len: integer; MinSize: integer);
// Decreases the length that last char is not a separator (but Len >= MinSize).
begin
  while (Len > MinSize) and (FText[Beg + Len - 1] in Separators) do
    Dec(Len);
end;

procedure TFormatText.InsertText(const S: string; const AStyle: TCharStyle;
  Beg: integer);
// Inserts a text to position Beg.
var
  AChunk: TFormatTextChunk;
begin
  if Length(S) = 0 then
    Exit; // we've got nothing to insert ...
  AChunk := TFormatTextChunk.Create(S, AStyle);
  InsertText(AChunk, Beg, 1, Length(S));
  CalcWidths(Beg, Length(S));
  FreeAndNil(AChunk);
end;

procedure TFormatText.InsertText(AChunk: TFormatTextChunk; Pos, Beg, Len: integer);
// Inserts a text chunk to position Beg.
var
  A: array of TCharInfo;
  I: integer;
begin
  if Len = 0 then
    Exit; // we've got nothing to insert ...
  Dec(Pos); // make it 0-indexed ...
  A := Copy(FList, Pos, Size - Pos);
  ResizeList(Size + Len);
  for I := 0 to Len - 1 do
    FList[Pos + I] := AChunk.FList[I + Beg - 1];
  for I := Pos to Size - 1 do
    FList[I + Len] := A[I - Pos];
  Insert(Copy(AChunk.FText, Beg, Len), FText, Pos + 1);
end;

procedure TFormatText.AddText(const S: string; const AStyle: TCharStyle);
// Adds a text to the end.
var
  AChunk: TFormatTextChunk;
begin
  if Length(S) = 0 then
    Exit; // we've got nothing to add ...
  AChunk := TFormatTextChunk.Create(S, AStyle);
  AddText(AChunk, 1, Length(S));
  CalcWidths(Size - Length(S) + 1, Length(S));
  FreeAndNil(AChunk);
end;

procedure TFormatText.AddText(AChunk: TFormatTextChunk; Beg, Len: integer);
// Adds a text chunk to the end.
var
  I: integer;
begin
  if Len = 0 then
    Exit; // we've got nothing to add ...
  ResizeList(Size + Len);
  for I := 0 to Len - 1 do
    FList[Size + I] := AChunk.FList[I + Beg - 1];
  FText += Copy(AChunk.FText, Beg, Len);
end;

procedure TFormatText.DeleteText(Beg, Len: integer);
// Deletes the text in (Beg, Len) segment.
var
  A: array of TCharInfo;
  I: integer;
begin
  if Len = 0 then
    Exit; // we've got nothing to delete ...
  Dec(Beg); // make it 0-indexed ...
  A := Copy(FList, Beg + Len, Size - Beg - Len);
  ResizeList(Size - Len);
  for I := Beg + Len to Size - 1 do
    FList[I - Len] := A[I - Beg - Len];
  Delete(FText, Beg + 1, Len);
end;

procedure TFormatText.Clear;
// Clears the text.
begin
  ResizeList(0);
  FText := '';
  CalcWidths(1, Size);
end;

procedure TFormatText.PutText(const S: string; const AStyle: TCharStyle);
// Replaces the text with a given string.
var
  I, Len: integer;
begin
  Len := Length(S);
  ResizeList(Len);
  for I := 0 to Len - 1 do
    FList[I] := AStyle;
  FText := S;
  CalcWidths(1, Size);
end;

function TFormatText.CopyText(Beg, Len: integer): TFormatTextChunk;
  // Copies the text into chunk.
var
  I: integer;
begin
  Result := TFormatTextChunk.Create;
  Result.FText := Copy(FText, Beg, Len);
  SetLength(Result.FList, Len);
  for I := 0 to Len - 1 do
    Result.FList[I] := FList[Beg + I - 1];
end;

constructor TFormatText.Create(ACanvas: TCanvas);
begin
  FCapacity := 0;
  FCanvas := ACanvas;
  FCursorPos := -1;
  FUpdating := 0;
  Clear;
end;

destructor TFormatText.Destroy;
begin
  inherited Destroy;
end;

function TFormatText.GetSize(Beg, Len: integer; SkipSeparators: boolean): TSize;
  // Returns the size of the segment.
var
  I: integer;
begin
  if SkipSeparators then
    CutFromSeparators(Beg, Len, 1);
  Result.cx := 0;
  Result.cy := 0;
  for I := Beg to Beg + Len - 1 do
  begin
    Result.cy := Max(Result.cy, CharSize[I].cy);
    Inc(Result.cx, CharSize[I].cx);
  end;
end;

procedure TFormatText.DrawPiece(Beg, Len: integer; AX, AY: integer);
// Draws the piece onto the canvas.
var
  V: TVectorPairIntInt;
  I, H: integer;
  Sz: TSize;
  WasBrush: TBrushStyle;
begin
  CutFromSeparators(Beg, Len, 0);
  if Len = 0 then
    Exit;
  // Drawing initialization ...
  AX += CharStyle[Beg].Indent;
  V := BuildStyleTable(Beg, Len);
  WasBrush := FCanvas.Brush.Style;
  FCanvas.Brush.Style := bsClear;
  // Calc the sizes...
  H := GetSize(Beg, Len, False).cy;
  AY += H;
  // Now, draw the text.
  for I := 0 to V.Count - 1 do
  begin
    PutStyle(FCanvas, CharStyle[V[I].First]);
    Sz := GetSize(V[I].First, V[I].Second, False);
    TextOut(FCanvas.Handle, AX, AY - Sz.cy,
      PChar(FText) + V[I].First - 1, V[I].Second);
    Inc(AX, Sz.cx);
  end;
  FCanvas.Brush.Style := WasBrush;
  FreeAndNil(V);
end;

procedure TFormatText.DrawCursor(Beg, Len: integer; AX, AY: integer);
// Draws the cursor onto the canvas.
var
  I, H, CurPos: integer;
begin
  if not CanDrawCursor(Beg, Len) then
    Exit;
  // calc where to draw the cursor ...
  CurPos := FCursorPos;
  while (CurPos >= Beg) and (FText[CurPos] in Separators) do
    Dec(CurPos);
  // calc the sizes ...
  AX += CharStyle[Beg].Indent;
  H := GetSize(Beg, Len, True).cy;
  AY += H;
  // now, draw the cursor!
  for I := Beg to Beg + Len - 1 do
  begin
    if CurPos + 1 = I then
      FCanvas.Line(AX + 1, AY - H, AX + 1, AY);
    AX += CharSize[I].cx;
  end;
end;

function TFormatText.CanDrawCursor(Beg, Len: integer): boolean;
  // Returns True if we have the cursor in segment (Beg, Len).
begin
  if Len = 0 then
    Result := False
  else
    Result := (Beg <= FCursorPos + 1) and (FCursorPos + 1 <= Beg + Len - 1);
end;

procedure TFormatText.CalcWidths(Beg, Len: integer);
// Calculates the char sizes.

  procedure AddTextPiece(Text: PChar; Beg, Len: integer);
  // Calculates the char sizes for (Beg, Len) segment from the style table.
  var
    TempLen: integer;
    ASize: TSize;
  begin
    while Len <> 0 do
    begin
      TempLen := UTF8CharacterLength(Text);
      ASize.cx := 0;
      ASize.cy := 0;
      GetTextExtentPoint(FCanvas.Handle, Text, TempLen, ASize);
      CharSize[Beg] := ASize;
      Inc(Text, TempLen);
      Inc(Beg, TempLen);
      Dec(Len, TempLen);
    end;
  end;

var
  V: TVectorPairIntInt;
  I: integer;
begin
  // null the sizes ...
  for I := Beg to Beg + Len - 1 do
    with CharSize[I] do
    begin
      cx := 0;
      cy := 0;
    end;
  // bulid our table and recalc ...
  V := BuildStyleTable(Beg, Len);
  for I := 0 to V.Count - 1 do
  begin
    PutStyle(FCanvas, CharStyle[V[I].First]);
    AddTextPiece(PChar(Text) + V[I].First - 1, V[I].First, V[I].Second);
  end;
  FreeAndNil(V);
end;

procedure TFormatText.DivideIntoPieces(Beg, Len: integer; AWidth: integer;
  AddPiece: TAddPieceProc);
// Divides a single line into lines (with word wrap). The result is passed
// to AddPiece procedure consecutively.
var
  S: PChar;
  ACharSize: TSize;
  NewWidth: integer;
  Chars: integer;
  SavedChars: integer;
  Temp: PChar;
  ASize: TSize;
begin
  if Len = 0 then
    Exit;
  S := PChar(FText) + Beg - 1;
  while Len > 0 do
  begin
    // initialize variables
    ASize.cx := 0;
    ASize.cy := 0;
    NewWidth := AWidth - CharStyle[Beg].Indent - ASize.cx;
    Chars := 0;
    ASize.cx := 0;
    ASize.cy := 0;
    // find the number of characters that fit to width
    while Chars < Len do
    begin
      ACharSize := CharSize[Chars + Beg];
      if ASize.cx + ACharSize.cx > NewWidth then
        Break;
      Inc(Chars);
      Inc(ASize.cx, ACharSize.cx);
      ASize.cy := Max(ASize.cy, ACharSize.cy);
    end;
    if (Chars <> 0) and (Chars <> Len) then
    begin
      // try to remove the last word (probably not full)
      SavedChars := Chars;
      Temp := S + Chars;
      while (Chars > 0) and not (Temp^ in Separators) do
      begin
        Dec(Chars);
        Dec(Temp);
      end;
      // if it's the only word - don't remove it
      if Chars = 0 then
        Chars := SavedChars;
      // remove the separators
      Temp := S + Chars;
      while (Chars < Len) and (Temp^ in Separators) do
      begin
        Inc(Chars);
        Inc(Temp);
      end;
    end;
    if (Chars = 0) and (Len <> 0) then
      Chars := 1;
    // push this string and go further
    if Assigned(AddPiece) then
      AddPiece(TTextPiece.Create(Self, Beg, Chars, GetSize(Beg, Chars, True)));
    Inc(S, Chars);
    Inc(Beg, Chars);
    Dec(Len, Chars);
  end;
end;

procedure TFormatText.DivideText(AWidth: integer; AddPiece: TAddPieceProc);
// Divides the full text into lines (with word wrap). The result is passed
// to AddPiece procedure consecutively.
var
  I, Len: integer;
  CurBeg: integer;

  function IsLineEnding(P: integer): boolean; inline;
    // Returns true if LineEnding starts in position P.
  var
    I: integer;
  begin
    if P + Length(LineEnding) - 1 > Length(FText) then
      Exit(False);
    for I := 1 to Length(LineEnding) do
      if FText[P + I - 1] <> string(LineEnding)[I] then
        Exit(False);
    Exit(True);
  end;

begin
  Len := Length(FText);
  if Len = 0 then
  begin
    // add one empty line
    AddPiece(TTextPiece.Create(Self, 1, 0, Types.Size(0, 0)));
    Exit;
  end;
  // iterate through the lines and call DivideIntoPieces for all of them.
  I := 1;
  while I <= Len do
  begin
    CurBeg := I;
    while (I <= Len) and (not IsLineEnding(I)) do
      Inc(I);
    if IsLineEnding(I) then
      I += Length(LineEnding);
    DivideIntoPieces(CurBeg, I - CurBeg, AWidth, AddPiece);
  end;
end;

function TFormatText.CharAtPos(Beg, Len: integer; X: integer): integer;
  // Returns position of the character with coordinate X - <X-coord or Beg>.
  // If the position is more than (Beg + Len - 1), that it returns (Beg + Len - 1).
var
  QX, I: integer;
begin
  QX := CharStyle[Beg].Indent;
  for I := Beg to Beg + Len - 1 do
    if QX + CharSize[I].cx > X then
      Exit(I)
    else
      QX += CharSize[I].cx;
  Result := Beg + Len - 1;
end;

initialization
  // we must register our TTextViewerImpl.
  TTextViewer := TTextViewerImpl;

end.
