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
    This unit implements a frame that shows a material imbalance between the two
    sides.
}
unit ImbalanceFrame;

{$I CompilerDirectives.inc}

interface

uses
  Forms, Controls, ExtCtrls, ChessRules, ChessBoards, Classes;

type

  { TImbalance }

  TImbalance = class(TFrame)
    PaintBox: TPaintBox;
    procedure PaintBoxPaint(Sender: TObject);
    procedure BoardChange(Sender: TObject);
    procedure TextureContainerChange(Sender: TObject);
  private
    FBoard: TVisualChessBoard;
    FTextureContainer: TTextureContainer;
    // Getters / Setters
    procedure SetBoard(AValue: TVisualChessBoard);
    procedure SetTextureContainer(AValue: TTextureContainer);
  public
    // Properties
    property Board: TVisualChessBoard read FBoard write SetBoard;
    property TextureContainer: TTextureContainer
      read FTextureContainer write SetTextureContainer;
    // Methods
    procedure AfterConstruction; override;
  end;

implementation

{$R *.lfm}

{ TImbalance }

procedure TImbalance.PaintBoxPaint(Sender: TObject);
var
  Pieces: array [TPieceColor, 0 .. 63] of TPieceKind;
  PieceCounts: array [TPieceColor] of integer;
  PieceWidths: array [TPieceColor] of integer;
  PieceHeight: integer;

  procedure CalcPieces;
  // Determines what pieces to draw.
  var
    I, J: integer;
    C: TPieceColor;
    K: TPieceKind;
    PieceCnt: array [TPieceColor, TPieceKind] of integer;
  begin
    // null all the values
    for C in TPieceColor do
      for K in TPieceKind do
        PieceCnt[C, K] := 0;
    for C in TPieceColor do
      PieceCounts[C] := 0;
    // calc PieceCnt
    with FBoard.ChessBoard.RawBoard do
    begin
      for I := 0 to 7 do
        for J := 0 to 7 do
          with Field[I, J] do
          begin
            if Kind <> pkNone then
              Inc(PieceCnt[Color, Kind]);
          end;
    end;
    // fill Pieces & PieceCounts
    for K in TPieceKind do
    begin
      if PieceCnt[pcWhite, K] > PieceCnt[pcBlack, K] then
        C := pcWhite
      else
        C := pcBlack;
      for I := 0 to Abs(PieceCnt[pcWhite, K] - PieceCnt[pcBlack, K]) - 1 do
      begin
        Pieces[C, PieceCounts[C]] := K;
        Inc(PieceCounts[C]);
      end;
    end;
  end;

  procedure CalcWidths;
  // Calculates the pieces' widths.
  var
    C: TPieceColor;
    FieldWidth: integer;
  begin
    // calculate FieldWidth (width or piece drawing area for one side)
    FieldWidth := (ClientWidth - ClientHeight) div 2;
    if FieldWidth < 0 then
      FieldWidth := 0;
    // calculate the height
    PieceHeight := ClientHeight;
    for C in TPieceColor do
    begin
      // calculate the width
      if PieceCounts[C] <= 1 then
        PieceWidths[C] := 0
      else
        PieceWidths[C] := (FieldWidth - PieceHeight) div (PieceCounts[C] - 1);
      // remember than PieceWidth must be in interval [0 .. PieceHeight]
      if PieceWidths[C] > PieceHeight then
        PieceWidths[C] := PieceHeight;
      if PieceWidths[C] < 0 then
        PieceWidths[C] := 0;
    end;
  end;

  procedure DrawPieces;
  // Draws the pieces.
  var
    C: TPieceColor;
    I: integer;
    X: integer;
  begin
    for C in TPieceColor do
      for I := 0 to PieceCounts[C] - 1 do
      begin
        // calc X position (white should be drawn on the left, and black -
        // on the right
        if C = pcWhite then
          X := PieceWidths[C] * I
        else
          X := ClientWidth - PieceWidths[C] * I - PieceHeight;
        // draw!
        FTextureContainer.StretchDrawTexture(
          PaintBox.Canvas,
          Rect(X, 0, X + PieceHeight, PieceHeight),
          tidPieces[C, Pieces[C, I]]);
      end;
  end;

begin
  if FBoard = nil then
    Exit;
  if not Assigned(FTextureContainer) then
    Exit;
  CalcPieces;
  CalcWidths;
  DrawPieces;
end;

procedure TImbalance.BoardChange(Sender: TObject);
begin
  Refresh;
end;

procedure TImbalance.TextureContainerChange(Sender: TObject);
begin
  Refresh;
end;

procedure TImbalance.SetBoard(AValue: TVisualChessBoard);
begin
  if FBoard = AValue then
    Exit;
  if FBoard <> nil then
    FBoard.RemoveHandlerOnChange(@BoardChange);
  FBoard := AValue;
  if FBoard <> nil then
    FBoard.AddHandlerOnChange(@BoardChange);
  Refresh;
end;

procedure TImbalance.SetTextureContainer(AValue: TTextureContainer);
begin
  if FTextureContainer = AValue then
    Exit;
  if FTextureContainer <> nil then
    FTextureContainer.RemoveHandlerOnChange(@TextureContainerChange);
  FTextureContainer := AValue;
  if FTextureContainer <> nil then
    FTextureContainer.AddHandlerOnChange(@TextureContainerChange);
  Refresh;
end;

procedure TImbalance.AfterConstruction;
begin
  inherited AfterConstruction;
  PaintBox.Align := alClient;
  DoubleBuffered := True;
end;

end.
