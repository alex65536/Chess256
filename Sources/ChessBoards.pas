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
    This unit contains TVisualChessBoard - a visual component for drawing a
    chessboard.
}
unit ChessBoards;

{$I CompilerDirectives.inc}

interface

uses
  Classes, Forms, Controls, ExtCtrls, Graphics, ChessRules, Types, SysUtils,
  Math, LazMethodList;

const
  //Texture IDs
  tidCells: array [TPieceColor] of integer = (0, 1);
  tidPieces: array [TPieceColor, TPieceKind] of integer =
    ((-1, 2, 4, 6, 8, 10, 12),
    (-1, 3, 5, 7, 9, 11, 13));
  tidSelection = 14;
  tidCheck = 15;
  tidEraser = 16;
  tidCursor = 17;
  tidBoardLeftTop = 18;
  tidBoardRightTop = 19;
  tidBoardLeftBottom = 20;
  tidBoardRightBottom = 21;
  tidBoardLeft = 22;
  tidBoardRight = 23;
  tidBoardTop = 24;
  tidBoardBottom = 25;
  tidColorIndicator: array [False .. True, TPieceColor] of integer =
    ((26, 27),
    (28, 29));
  tidInverted: array [False .. True] of integer = (30, 31);

  // Texture ID specific constants
  tidLowCell = 0;
  tidHighCell = 1;
  tidLowPiece = 2;
  tidHighPiece = 13;
  tidLowIndicator = 26;
  tidHighIndicator = 29;
  tidLowInverted = 30;
  tidHighInverted = 31;

const
  BoardCellHeight = 10;

const
  // Text alignments
  talLeft = -1;
  talRight = 1;
  talTop = -1;
  talBottom = 1;
  talCenter = 0;

const
  MaxLayer = 4; // Max layers count

type
  // Types for saving the board values (made just for drawing optimization).

  { RBoardTextures }

  RBoardTextures = record
    Layers: array [0 .. MaxLayer - 1] of integer;
    class operator=(const A, B: RBoardTextures): Boolean;
    class operator<>(const A, B: RBoardTextures): Boolean;
  end;

  RBoardState = record
    Textures: array [0 .. 7, 0 .. 7] of RBoardTextures;
    Inverted: boolean;
    MoveSide: TPieceColor;
    CellHeight: integer;
  end;

type
  TBoardRowKind = (rkColumn, rkRow);
  TChessBoardDragDropMode = (ddNone, ddDrag, ddDragQuery);
  TMoveQueryEvent = procedure(Sender: TObject;
    SrcX, SrcY, DstX, DstY: integer) of object;
  TClickCellEvent = procedure(Sender: TObject; X, Y: integer;
    Button: TMouseButton) of object;

  { TTextureContainer }

  TTextureContainer = class
  private
    FCellHeight: integer;
    FMethodList: TMethodList;
  protected
    procedure DoChange; virtual;
  public
    property CellHeight: integer read FCellHeight write FCellHeight;
    // Abstract methods
    function GetItemHeight: integer; virtual; abstract; // Must return item height.
    function GetBorderWidth: integer; virtual; abstract; // Must return border width.
    procedure DrawTexture(Canvas: TCanvas; X, Y, ID: integer); virtual;
      abstract; // Draws a texture.
    procedure StretchDrawTexture(Canvas: TCanvas; Rect: TRect; ID: integer);
      virtual; abstract; // Stretch draws a texture.
    procedure RawOutCoordinate(Canvas: TCanvas; X, Y, Coord: integer;
      Row: TBoardRowKind); virtual; abstract;
    // Raw coordinate output (used by OutCoordinate).
    // Other methods
    constructor Create; virtual;
    destructor Destroy; override;
    procedure AddHandlerOnChange(AHandler: TNotifyEvent);
    procedure RemoveHandlerOnChange(AHandler: TNotifyEvent);
    procedure MakeBitmap(Bitmap: TBitmap; GlyphSize: integer;
      CellID, PieceID: integer);
    procedure OutCoordinate(Canvas: TCanvas; X, Y, Coord: integer;
      Row: TBoardRowKind; AlignX, AlignY: integer);
  end;

  { TVisualChessBoard }

  TVisualChessBoard = class(TFrame)
    PaintBox: TPaintBox;
    procedure FrameResize(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure PaintBoxMouseLeave(Sender: TObject);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure PaintBoxPaint(Sender: TObject);
  private
    FMethodList: TMethodList;
    FDrawImage: TBitmap;
    FCellHeight: integer;
    FInverted: boolean;
    FChessBoard: TChessBoard;
    FTextureContainer: TTextureContainer;
    FDragDropMode: TChessBoardDragDropMode;
    FDragStarted: boolean;
    FCursorID: integer;
    FDrawSelection: boolean;
    FOnClickCell: TClickCellEvent;
    FOnMoveQuery: TMoveQueryEvent;
    FDragX, FDragY: integer; // Drag start coordinates
    FUpdating: integer;
    FState: RBoardState; // State of last redrawing
    // Event handlers
    procedure ChessBoardChange(Sender: TObject);
    procedure TextureContainerChange(Sender: TObject);
    // Setters
    procedure SetCursorID(AValue: integer);
    procedure SetDrawSelection(AValue: boolean);
    procedure SetInverted(AValue: boolean);
    procedure SetTextureContainer(AValue: TTextureContainer);
    procedure SetDragDropMode(AValue: TChessBoardDragDropMode);
    // Dragging methods
    procedure BoardCellClicked(SrcX, SrcY: integer; Button: TMouseButton);
    function DragStart(SrcX, SrcY: integer): boolean;
    procedure DragDecline;
    procedure DragEnd(DstX, DstY: integer);
    // Some calculation methods
    function ClientToBoard(Pos: TPoint): TPoint;
    function GetBoardPosition: TPoint;
    function GetBoardRect: TRect;
    function GetBoardRectNoBorder: TRect;
    function GetInvertButtonRect: TRect;
    function MouseOutOfBoard: boolean;
    procedure MousePointToCoords(const P: TPoint; out X, Y: integer);
    procedure AdjustCellHeight;
    // Refreshing
    procedure RefreshBitmap;
  protected
    // Drawing stuff
    property DrawImage: TBitmap read FDrawImage; // Our buffer image.
    procedure UpdateBitmap; virtual; // Draw on DrawImage.Canvas!
    procedure DrawMoving; virtual;   // Draw on PaintBox.Canvas!
    // Do... methods.
    procedure DoClickCell(X, Y: integer; Button: TMouseButton);
    procedure DoMoveQuery(SrcX, SrcY, DstX, DstY: integer);
  public
    // Properties
    property CellHeight: integer read FCellHeight write FCellHeight;
    property Inverted: boolean read FInverted write SetInverted;
    property ChessBoard: TChessBoard read FChessBoard;
    property TextureContainer: TTextureContainer
      read FTextureContainer write SetTextureContainer;
    property DragDropMode: TChessBoardDragDropMode
      read FDragDropMode write SetDragDropMode;
    property DragStarted: boolean read FDragStarted;
    property CursorID: integer read FCursorID write SetCursorID;
    property DrawSelection: boolean read FDrawSelection write SetDrawSelection;
    // Events
    property OnClickCell: TClickCellEvent read FOnClickCell write FOnClickCell;
    property OnMoveQuery: TMoveQueryEvent read FOnMoveQuery write FOnMoveQuery;
    // Methods
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure DoChange;
    procedure InvertBoard;
    procedure FullRefresh;
    function GetCellHeightOnResizing(NewWidth, NewHeight: integer): integer;
    procedure AddHandlerOnChange(AHandler: TNotifyEvent);
    procedure RemoveHandlerOnChange(AHandler: TNotifyEvent);
  end;

function GetCellColor(X, Y: integer): TPieceColor;

implementation

function GetCellColor(X, Y: integer): TPieceColor;
  // Returns the color of the cell (required for drawing this cell).
begin
  if Odd(X + Y) then
    Result := pcBlack
  else
    Result := pcWhite;
end;

{$R *.lfm}

{ TTextureContainer }

procedure TTextureContainer.DoChange;
begin
  FMethodList.CallNotifyEvents(Self);
end;

constructor TTextureContainer.Create;
begin
  FCellHeight := 0;
  FMethodList := TMethodList.Create;
end;

destructor TTextureContainer.Destroy;
begin
  FreeAndNil(FMethodList);
  inherited Destroy;
end;

procedure TTextureContainer.AddHandlerOnChange(AHandler: TNotifyEvent);
// Adds OnChange handler.
begin
  FMethodList.Add(TMethod(AHandler));
end;

procedure TTextureContainer.RemoveHandlerOnChange(AHandler: TNotifyEvent);
// Removes OnChange handler.
begin
  FMethodList.Remove(TMethod(AHandler));
end;

procedure TTextureContainer.MakeBitmap(Bitmap: TBitmap; GlyphSize: integer;
  CellID, PieceID: integer);
// Makes a bitmap from two cells.
var
  DrawRect: TRect;
begin
  with Bitmap do
  begin
    DrawRect := Rect(0, 0, GlyphSize, GlyphSize);
    SetSize(GlyphSize, GlyphSize);
    StretchDrawTexture(Canvas, DrawRect, CellID);
    StretchDrawTexture(Canvas, DrawRect, PieceID);
  end;
end;

procedure TTextureContainer.OutCoordinate(Canvas: TCanvas; X, Y, Coord: integer;
  Row: TBoardRowKind; AlignX, AlignY: integer);
// Draws a coordinate with alignment.
var
  Delta: integer;
begin
  Delta := GetItemHeight - GetBorderWidth;
  Inc(X, (GetItemHeight + AlignX * Delta) div 2);
  Inc(Y, (GetItemHeight + AlignY * Delta) div 2);
  RawOutCoordinate(Canvas, X, Y, Coord, Row);
end;

{ RBoardTextures }

class operator RBoardTextures.=(const A, B: RBoardTextures): boolean;
var
  I: integer;
begin
  for I := 0 to MaxLayer - 1 do
    if A.Layers[I] <> B.Layers[I] then
      Exit(False);
  Exit(True);
end;

class operator RBoardTextures.<>(const A, B: RBoardTextures): boolean;
begin
  Result := not (A = B);
end;

{ TVisualChessBoard }

procedure TVisualChessBoard.FrameResize(Sender: TObject);
begin
  CellHeight := GetCellHeightOnResizing(ClientWidth, ClientHeight);
  RefreshBitmap;
end;

{$HINTS OFF}
procedure TVisualChessBoard.PaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  AX, AY: integer;
begin
  if not Assigned(FTextureContainer) then
    Exit;
  if PtInRect(GetInvertButtonRect, ScreenToClient(Mouse.CursorPos)) then
  begin
    // invert board
    if Button = mbLeft then
      InvertBoard;
  end
  else if not MouseOutOfBoard then
  begin
    // we clicked on a cell
    MousePointToCoords(GetBoardPosition, AX, AY);
    BoardCellClicked(AX, AY, Button);
  end;
end;

{$HINTS ON}

{$HINTS OFF}
procedure TVisualChessBoard.PaintBoxMouseLeave(Sender: TObject);
begin
  if not Assigned(FTextureContainer) then
    Exit;
  if FCursorID >= 0 then
    Refresh;
end;

{$HINTS ON}

{$HINTS OFF}
procedure TVisualChessBoard.PaintBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: integer);
begin
  if not Assigned(FTextureContainer) then
    Exit;
  if FCursorID >= 0 then
  begin
    if MouseOutOfBoard then
      PaintBox.Cursor := crDefault
    else
      PaintBox.Cursor := crNone;
  end;
  if FDragStarted or (FCursorID >= 0) then
    Refresh;
end;

{$HINTS ON}

{$HINTS OFF}
procedure TVisualChessBoard.PaintBoxMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  AX, AY: integer;
begin
  if not Assigned(FTextureContainer) then
    Exit;
  if Button = mbLeft then
  begin
    // try to end dragging
    if MouseOutOfBoard then
      DragDecline
    else
    begin
      MousePointToCoords(GetBoardPosition, AX, AY);
      DragEnd(AX, AY);
    end;
  end;
end;

{$HINTS ON}

procedure TVisualChessBoard.PaintBoxPaint(Sender: TObject);
begin
  PaintBox.Canvas.Clear;
  PaintBox.Canvas.Draw(GetBoardRect.Left, GetBoardRect.Top, FDrawImage);
  AdjustCellHeight;
  DrawMoving;
end;

procedure TVisualChessBoard.ChessBoardChange(Sender: TObject);
begin
  DragDecline;
  DoChange;
end;

procedure TVisualChessBoard.TextureContainerChange(Sender: TObject);
begin
  FullRefresh;
end;

procedure TVisualChessBoard.SetCursorID(AValue: integer);
begin
  if FCursorID = AValue then
    Exit;
  FCursorID := AValue;
  if FCursorID < 0 then
    PaintBox.Cursor := crDefault
  else
    PaintBox.Cursor := crNone;
  Refresh;
end;

procedure TVisualChessBoard.SetDrawSelection(AValue: boolean);
begin
  if FDrawSelection = AValue then
    Exit;
  FDrawSelection := AValue;
  RefreshBitmap;
end;

procedure TVisualChessBoard.SetInverted(AValue: boolean);
begin
  if FInverted = AValue then
    Exit;
  FInverted := AValue;
  RefreshBitmap;
end;

procedure TVisualChessBoard.SetTextureContainer(AValue: TTextureContainer);
begin
  if FTextureContainer = AValue then
    Exit;
  if FTextureContainer <> nil then
    FTextureContainer.RemoveHandlerOnChange(@TextureContainerChange);
  FTextureContainer := AValue;
  if FTextureContainer <> nil then
    FTextureContainer.AddHandlerOnChange(@TextureContainerChange);
  FullRefresh;
end;

procedure TVisualChessBoard.SetDragDropMode(AValue: TChessBoardDragDropMode);
begin
  if FDragDropMode = AValue then
    Exit;
  if FDragStarted then
    DragDecline;
  FDragDropMode := AValue;
end;

procedure TVisualChessBoard.BoardCellClicked(SrcX, SrcY: integer; Button: TMouseButton);
// The function that handles clicks to a cell (SrcX, SrcY) with button Button.
begin
  if Button = mbLeft then
    DragStart(SrcX, SrcY);
  if FDragDropMode = ddNone then
    DoClickCell(SrcX, SrcY, Button);
end;

function TVisualChessBoard.DragStart(SrcX, SrcY: integer): boolean;
  // The function starts dragging a piece.
begin
  Result := False;
  // useful checks
  if (SrcX < 0) or (SrcX > 7) or (SrcY < 0) or (SrcY > 7) then
    Exit;
  if FChessBoard.RawBoard.Field[SrcX, SrcY].Kind = pkNone then
    Exit;
  if FUpdating <> 0 then
    Exit;
  if DragDropMode = ddNone then
    Exit;
  // now, start dragging
  BeginUpdate;
  if FDragStarted then
    DragDecline;
  FDragStarted := True;
  FDragX := SrcX;
  FDragY := SrcY;
  EndUpdate;
  Result := True;
end;

procedure TVisualChessBoard.DragDecline;
// Ends dragging and returns a dragged piece back.
begin
  if not FDragStarted then
    Exit;
  FDragStarted := False;
  RefreshBitmap;
end;

procedure TVisualChessBoard.DragEnd(DstX, DstY: integer);
// Ends dragging with checking what to do with it.
begin
  if not FDragStarted then
    Exit;
  // dragging
  BeginUpdate;
  FDragStarted := False;
  DoMoveQuery(FDragX, FDragY, DstX, DstY);
  EndUpdate;
end;

function TVisualChessBoard.ClientToBoard(Pos: TPoint): TPoint;
  // Converting client coords to on-board coords.
var
  Rect: TRect;
begin
  Rect := GetBoardRect;
  Result := Point(Pos.x - Rect.Left, Pos.y - Rect.Top);
end;

function TVisualChessBoard.GetBoardPosition: TPoint;
  // Returns current mouse cursor position on the board.
begin
  Result := ClientToBoard(ScreenToClient(Mouse.CursorPos));
end;

function TVisualChessBoard.GetBoardRect: TRect;
  // Returns the board rectangle.
var
  ImgHeight, LeftPos, TopPos: integer;
begin
  ImgHeight := BoardCellHeight * CellHeight;
  LeftPos := (Width - ImgHeight) div 2;
  TopPos := (Height - ImgHeight) div 2;
  Result := Rect(LeftPos, TopPos, LeftPos + ImgHeight, TopPos + ImgHeight);
end;

function TVisualChessBoard.GetBoardRectNoBorder: TRect;
  // Returns the board rectangle (without boarder).
var
  R: TRect;
begin
  R := GetBoardRect;
  Result := Rect(R.Left + CellHeight, R.Top + CellHeight, R.Right -
    CellHeight, R.Bottom - CellHeight);
end;

function TVisualChessBoard.GetInvertButtonRect: TRect;
  // Returns the rectangle of "invert board" button.
var
  R: TRect;
  BrdWidth: integer;
begin
  AdjustCellHeight;
  R := GetBoardRect;
  BrdWidth := CellHeight;
  if Assigned(FTextureContainer) then
  begin
    with FTextureContainer do
      BrdWidth := Self.CellHeight * GetBorderWidth div GetItemHeight;
  end;
  Result := Rect(R.Left + CellHeight - BrdWidth, R.Bottom -
    CellHeight, R.Left + CellHeight, R.Bottom -
    CellHeight + BrdWidth);
end;

function TVisualChessBoard.MouseOutOfBoard: boolean;
  // Checks if the mouse out of board.
begin
  if not Assigned(FTextureContainer) then
    Exit(True);
  Result := not PtInRect(GetBoardRectNoBorder, ScreenToClient(Mouse.CursorPos));
end;

procedure TVisualChessBoard.MousePointToCoords(const P: TPoint; out X, Y: integer);
// Converts mouse point to coordinates.
begin
  X := P.x div CellHeight - 1;
  Y := P.y div CellHeight - 1;
  if FInverted then
  begin
    X := 7 - X;
    Y := 7 - Y;
  end;
end;

procedure TVisualChessBoard.AdjustCellHeight;
// Changes the cell height.
begin
  if Assigned(FTextureContainer) then
    FTextureContainer.CellHeight := Self.CellHeight;
end;

procedure TVisualChessBoard.RefreshBitmap;
// Updates the bitmap and redraws the board.
begin
  if FUpdating <> 0 then
    Exit;
  AdjustCellHeight;
  UpdateBitmap;
  Refresh;
end;

// Here are UpdateBitmap & DrawMoving methods.
{$I BoardPainting.inc}

procedure TVisualChessBoard.DoClickCell(X, Y: integer; Button: TMouseButton);
// Handler when we clicked on cell.
begin
  if (X < 0) or (X > 7) or (Y < 0) or (Y > 7) then
    Exit;
  if Assigned(FOnClickCell) then
    FOnClickCell(Self, X, Y, Button);
end;

procedure TVisualChessBoard.DoMoveQuery(SrcX, SrcY, DstX, DstY: integer);
// Handler when we try to drag a piece.
begin
  if (DstX = SrcX) and (DstY = SrcY) then
    Exit;
  if (SrcX < 0) or (SrcX > 7) or (DstX < 0) or (DstX > 7) or (SrcY < 0) or
    (SrcY > 7) or (DstY < 0) or (DstY > 7) then
    Exit;
  BeginUpdate;
  if FDragDropMode = ddDrag then
  begin
    // default drag
    with FChessBoard do
    begin
      Field[DstX, DstY] := Field[SrcX, SrcY];
      Field[SrcX, SrcY] := MakeBoardCell(pkNone, pcWhite);
    end;
  end
  else if Assigned(FOnMoveQuery) then
    FOnMoveQuery(Self, SrcX, SrcY, DstX, DstY);
  EndUpdate;
end;

constructor TVisualChessBoard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMethodList := TMethodList.Create;
  FCursorID := -1;
  FChessBoard := TChessBoard.Create;
  FChessBoard.OnChange := @ChessBoardChange;
  FDragDropMode := ddNone;
  FTextureContainer := nil;
  FDragStarted := False;
  FDrawImage := TBitmap.Create;
  FUpdating := 0;
  FDrawSelection := True;
  FInverted := False;
  FState.CellHeight := -1;
  PaintBox.Align := alClient;
  DoubleBuffered := True;
end;

destructor TVisualChessBoard.Destroy;
begin
  FreeAndNil(FMethodList);
  FreeAndNil(FChessBoard);
  FreeAndNil(FDrawImage);
  inherited Destroy;
end;

procedure TVisualChessBoard.BeginUpdate;
// Locks DoChange and refrshing.
begin
  Inc(FUpdating);
end;

procedure TVisualChessBoard.EndUpdate;
// Unlocks DoChange and refrshing.
begin
  Dec(FUpdating);
  if FUpdating < 0 then
    FUpdating := 0;
  if FUpdating = 0 then
    DoChange;
end;

procedure TVisualChessBoard.DoChange;
// Handler when smth has changed.
begin
  if FUpdating <> 0 then
    Exit;
  FMethodList.CallNotifyEvents(Self);
  RefreshBitmap;
end;

procedure TVisualChessBoard.InvertBoard;
// Inverts the board.
begin
  Inverted := not Inverted;
end;

procedure TVisualChessBoard.FullRefresh;
// Fully refreshes the board.
begin
  FState.CellHeight := -1; // to call the full refreshing
  RefreshBitmap;
  // some magic (simple Refresh gives bugs here on Ubuntu!)
  with PaintBox do
  begin
    Align := alNone;
    Width := 0;
    Align := alClient;
  end;
end;

function TVisualChessBoard.GetCellHeightOnResizing(NewWidth, NewHeight:
  integer): integer;
  // Returns the cell height if the frame will be resized.
var
  FieldSize: integer;
begin
  FieldSize := Min(NewWidth, NewHeight);
  Result := FieldSize div BoardCellHeight;
end;

procedure TVisualChessBoard.AddHandlerOnChange(AHandler: TNotifyEvent);
// Adds OnChange handler.
begin
  FMethodList.Add(TMethod(AHandler));
end;

procedure TVisualChessBoard.RemoveHandlerOnChange(AHandler: TNotifyEvent);
// Removes OnChange handler.
begin
  FMethodList.Remove(TMethod(AHandler));
end;

end.
