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
    This unit implements texture packs for TVisualChessBoard. For now, two
    texture packs are supported: 1) using bitmaps stored in the resources and
    2) using Unicode chess characters from a certain font. The second one is
    experimental and doesn't color the pieces (especially white) inside, so they
    are rendered transparent.
}
unit TextureContainers;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, ChessBoards, Graphics, Controls, Types, ChessRules, Math,
  ChessGUIUtils, Forms, ChessStrings;

type

  { TImageTextureContainer }

  TImageTextureContainer = class(TTextureContainer)
  private
    FImageList: TImageList;
    FFont: TFont;
    procedure SetFont(AValue: TFont);
  public
    property ImageList: TImageList read FImageList;
    property Font: TFont read FFont write SetFont;
    function GetItemHeight: integer; override;
    function GetBorderWidth: integer; override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawTexture(Canvas: TCanvas; X, Y, ID: integer); override;
    procedure StretchDrawTexture(Canvas: TCanvas; Rect: TRect; ID: integer); override;
    procedure RawOutCoordinate(Canvas: TCanvas; X, Y, Coord: integer;
      Row: TBoardRowKind); override;
  end;

  { TFontTextureContainer }

  TFontTextureContainer = class(TTextureContainer)
  private
    FFont: TFont;
    FCursorImage: TGraphic;
    FEraserImage: TGraphic;
    procedure SetFont(AValue: TFont);
  public
    property CursorImage: TGraphic read FCursorImage;
    property EraserImage: TGraphic read FEraserImage;
    property Font: TFont read FFont write SetFont;
    function GetItemHeight: integer; override;
    function GetBorderWidth: integer; override;
    constructor Create; override;
    destructor Destroy; override;
    procedure DrawTexture(Canvas: TCanvas; X, Y, ID: integer); override;
    procedure StretchDrawTexture(Canvas: TCanvas; Rect: TRect; ID: integer); override;
    procedure RawOutCoordinate(Canvas: TCanvas; X, Y, Coord: integer;
      Row: TBoardRowKind); override;
  end;

  { TResourceTextureContainer }

  TResourceTextureContainer = class(TImageTextureContainer)
  public
    constructor Create; override;
    function GetBorderWidth: integer; override;
  end;

procedure PaintTextToCenter(Canvas: TCanvas; X, Y: integer; const Text: string);
procedure AdjustFontSize(AFont: TFont; AHeight: integer);

implementation

procedure PaintTextToCenter(Canvas: TCanvas; X, Y: integer; const Text: string);
var
  TextX, TextY: integer;
  TextSz: TSize;
begin
  TextSz := Canvas.TextExtent(Text);
  TextX := X - TextSz.cx div 2;
  TextY := Y - TextSz.cy div 2;
  Canvas.TextOut(TextX, TextY, Text);
end;

procedure AdjustFontSize(AFont: TFont; AHeight: integer);
begin
  AFont.Height := -Round(AHeight * 0.9);
end;

{ TImageTextureContainer }

procedure TImageTextureContainer.SetFont(AValue: TFont);
begin
  if FFont = AValue then
    Exit;
  FFont.Assign(AValue);
  DoChange;
end;

function TImageTextureContainer.GetItemHeight: integer;
begin
  Result := FImageList.Height;
end;

function TImageTextureContainer.GetBorderWidth: integer;
begin
  Result := GetItemHeight;
end;

constructor TImageTextureContainer.Create;
begin
  inherited;
  FImageList := TImageList.Create(nil);
  FFont := TFont.Create;
  FFont.Name := DefaultChessFont;
  FFont.Size := DefaultChessFontSize;
end;

destructor TImageTextureContainer.Destroy;
begin
  FreeAndNil(FImageList);
  FreeAndNil(FFont);
  inherited;
end;

procedure TImageTextureContainer.DrawTexture(Canvas: TCanvas; X, Y, ID: integer);
begin
  FImageList.Draw(Canvas, X, Y, ID);
end;

procedure TImageTextureContainer.StretchDrawTexture(Canvas: TCanvas;
  Rect: TRect; ID: integer);
begin
  FImageList.StretchDraw(Canvas, ID, Rect);
end;

procedure TImageTextureContainer.RawOutCoordinate(Canvas: TCanvas;
  X, Y, Coord: integer; Row: TBoardRowKind);
var
  S: string;
begin
  if Row = rkRow then
    S := Chr(Ord('A') + Coord)
  else
    S := Chr(Ord('8') - Coord);
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(FFont);
  AdjustFontSize(Canvas.Font, GetBorderWidth);
  PaintTextToCenter(Canvas, X, Y, S);
end;

{ TFontTextureContainer }

procedure TFontTextureContainer.SetFont(AValue: TFont);
begin
  if FFont = AValue then
    Exit;
  FFont.Assign(AValue);
  DoChange;
end;

function TFontTextureContainer.GetItemHeight: integer;
begin
  Result := CellHeight;
end;

function TFontTextureContainer.GetBorderWidth: integer;
begin
  Result := Min(CellHeight, Round(0.2 * Screen.PixelsPerInch));
end;

constructor TFontTextureContainer.Create;
begin
  inherited;
  FFont := TFont.Create;
  FFont.Name := DefaultChessFont;
  FCursorImage := TPortableNetworkGraphic.Create;
  FCursorImage.LoadFromResourceName(HINSTANCE, 'Textures.Cursor');
  FEraserImage := TPortableNetworkGraphic.Create;
  FEraserImage.LoadFromResourceName(HINSTANCE, 'Textures.Eraser');
end;

destructor TFontTextureContainer.Destroy;
begin
  FreeAndNil(FCursorImage);
  FreeAndNil(FEraserImage);
  FreeAndNil(FFont);
  inherited;
end;

procedure TFontTextureContainer.DrawTexture(Canvas: TCanvas; X, Y, ID: integer);
begin
  StretchDrawTexture(Canvas, Rect(X, Y, X + GetItemHeight, Y + GetItemHeight), ID);
end;

procedure TFontTextureContainer.StretchDrawTexture(Canvas: TCanvas;
  Rect: TRect; ID: integer);
var
  K, SelK: TPieceKind;
  C, SelC: TPieceColor;

  procedure DrawPiece(DrawColor: TColor; PieceColor: TPieceColor);
  // Draws a piece.
  begin
    Canvas.Font.Color := DrawColor;
    PaintTextToCenter(Canvas,
      (Rect.Left + Rect.Right) div 2,
      (Rect.Top + Rect.Bottom) div 2,
      ChessPieceChars[PieceColor, SelK]);
  end;

  procedure AlignOn(Align: integer; out L, R: integer; LeaveSpace: boolean);
  // Converts the Align for a border to interval [L, R] where it must be.
  // Align < 0 -> left (or top)
  // Align = 0 -> the full cell
  // Align > 0 -> right (or bottom)
  const
    Bool2Int: array [False .. True] of integer = (0, 1);
  begin
    if Align <= 0 then
      L := -Bool2Int[LeaveSpace]
    else
      L := GetItemHeight - GetBorderWidth;
    if Align >= 0 then
      R := GetItemHeight + Bool2Int[LeaveSpace]
    else
      R := GetBorderWidth;
  end;

  procedure DrawBorder(XAlign, YAlign: integer);
  // Draws a border with specified alignments on X and Y.
  var
    Left, Top, Right, Bottom: integer;
  begin
    // put canvas parameters
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := clSilver;
    Canvas.Pen.Color := clBlack;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
    // calc position
    AlignOn(XAlign, Left, Right, True);
    AlignOn(YAlign, Top, Bottom, True);
    // draw it!
    Canvas.Rectangle(Left, Top, Right, Bottom);
  end;

  procedure DrawIndicator(XAlign, YAlign: integer; Color: TColor);
  // Draws a color indicator with specified alignments on X and Y.
  var
    Height, Width: integer;
    Left, Top, Right, Bottom: integer;
  begin
    // calc position
    AlignOn(XAlign, Left, Right, False);
    AlignOn(YAlign, Top, Bottom, False);
    Height := Bottom - Top;
    Width := Right - Left;
    Inc(Top, Height div 5);
    Dec(Bottom, Height div 5);
    Inc(Left, Width div 5);
    Dec(Right, Width div 5);
    // put pen & brush params ...
    Canvas.Pen.Color := clBlack;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Color;
    // draw it!
    Canvas.Ellipse(Left, Top, Right, Bottom);
  end;

  procedure DrawInverted(XAlign, YAlign: integer; Inverted: boolean);
  // Draws an "invert board" arrow with the specified X and Y alignments.
  const
    InvertedArrows: array [False .. True] of string = ('↻', '↺');
  var
    Height: integer;
    Left, Top, Right, Bottom: integer;
  begin
    // calc position
    AlignOn(XAlign, Left, Right, False);
    AlignOn(YAlign, Top, Bottom, False);
    Height := Bottom - Top;
    // put canvas params
    Canvas.Font.Assign(FFont);
    AdjustFontSize(Canvas.Font, Height);
    Canvas.Brush.Style := bsClear;
    // draw it!
    PaintTextToCenter(Canvas, (Left + Right) div 2, (Top + Bottom) div 2,
      InvertedArrows[Inverted]);
  end;

begin
  case ID of
    // cells
    tidLowCell .. tidHighCell:
    begin
      if ID = tidCells[pcWhite] then
        Canvas.Brush.Color := clWhite
      else
        Canvas.Brush.Color := clGray;
      Canvas.Pen.Style := psClear;
      Canvas.FillRect(Rect);
    end;
    // pieces
    tidLowPiece .. tidHighPiece:
    begin
      for K in TPieceKind do
        for C in TPieceColor do
          if ID = tidPieces[C, K] then
          begin
            SelK := K;
            SelC := C;
          end;
      Canvas.Brush.Style := bsClear;
      Canvas.Font.Assign(FFont);
      AdjustFontSize(Canvas.Font, Rect.Bottom - Rect.Top);
      DrawPiece(clBlack, SelC);
      // TODO : Make filling the pieces !!!
    end;
    // selections
    tidSelection, tidCheck:
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Style := psSolid;
      Canvas.Pen.Width := (Rect.Bottom - Rect.Top) div 20 * 2 + 1;
      Canvas.Pen.Color := IfThen(ID = tidSelection, clGreen, clRed);
      Canvas.Rectangle(Rect);
    end;
    // eraser & cursor
    tidEraser: Canvas.StretchDraw(Rect, FEraserImage);
    tidCursor: Canvas.StretchDraw(Rect, FCursorImage);
    // borders
    tidBoardLeftTop: DrawBorder(1, 1);
    tidBoardRightTop: DrawBorder(-1, 1);
    tidBoardLeftBottom: DrawBorder(1, -1);
    tidBoardRightBottom: DrawBorder(-1, -1);
    tidBoardLeft: DrawBorder(1, 0);
    tidBoardRight: DrawBorder(-1, 0);
    tidBoardTop: DrawBorder(0, 1);
    tidBoardBottom: DrawBorder(0, -1);
    // color indicators
    tidLowIndicator .. tidHighIndicator:
    begin
      if ID = tidColorIndicator[False, pcWhite] then
        DrawIndicator(-1, -1, clWhite);
      if ID = tidColorIndicator[False, pcBlack] then
        DrawIndicator(-1, 1, clGray);
      if ID = tidColorIndicator[True, pcWhite] then
        DrawIndicator(-1, 1, clWhite);
      if ID = tidColorIndicator[True, pcBlack] then
        DrawIndicator(-1, -1, clGray);
    end;
    // "invert board" arrows
    tidLowInverted .. tidHighInverted: DrawInverted(1, -1, ID = tidInverted[True]);
  end;
end;

procedure TFontTextureContainer.RawOutCoordinate(Canvas: TCanvas;
  X, Y, Coord: integer; Row: TBoardRowKind);
var
  S: string;
begin
  if Row = rkRow then
    S := Chr(Ord('A') + Coord)
  else
    S := Chr(Ord('8') - Coord);
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(FFont);
  AdjustFontSize(Canvas.Font, GetBorderWidth);
  PaintTextToCenter(Canvas, X, Y, S);
end;

{ TResourceTextureContainer }

constructor TResourceTextureContainer.Create;

  procedure AddFromRes(ResName: string; UpdateSizes: boolean = False);
  // Adds images to image list from resourse with name ResName.
  var
    PNG: TPortableNetworkGraphic;
  begin
    PNG := TPortableNetworkGraphic.Create;
    try
      PNG.LoadFromResourceName(HINSTANCE, ResName);
      if UpdateSizes then
      begin
        ImageList.Height := PNG.Height;
        ImageList.Width := PNG.Height;
      end;
      ImageList.Add(PNG, nil);
    finally
      FreeAndNil(PNG);
    end;
  end;

begin
  inherited Create;
  AddFromRes('Textures.Pieces', True);
  AddFromRes('Textures.Eraser');
  AddFromRes('Textures.Cursor');
  AddFromRes('Textures.Borders');
end;

function TResourceTextureContainer.GetBorderWidth: integer;
begin
  Result := GetItemHeight div 2;
end;

end.
