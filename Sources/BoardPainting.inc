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
    The two most lengthy methods of TVisualChessBoard are moved here.
    They contains the board drawing routines.
}

procedure TVisualChessBoard.UpdateBitmap;
// Redraws with optimization.

  function GetState: RBoardState;
    // Returns current board state.

    procedure PutIt(X, Y, Layer, ID: integer);
    // Puts the cell into result (with checking if inverted).
    begin
      if FInverted then
      begin
        X := 7 - X;
        Y := 7 - Y;
      end;
      Result.Textures[X, Y].Layers[Layer] := ID;
    end;

  var
    I, J, K: integer;
  begin
    Result.CellHeight := CellHeight;
    Result.Inverted := FInverted;
    Result.MoveSide := FChessBoard.MoveSide;
    for I := 0 to 7 do
      for J := 0 to 7 do
        for K := 0 to MaxLayer - 1 do
          Result.Textures[I, J].Layers[K] := -1;
    with FChessBoard do
    begin
      for I := 0 to 7 do
        for J := 0 to 7 do
          PutIt(I, J, 0, tidCells[GetCellColor(I, J)]);
      for I := 0 to 7 do
        for J := 0 to 7 do
        begin
          if Field[I, J].Kind = pkNone then
            Continue;
          if FDragStarted and (I = FDragX) and (J = FDragY) then
            Continue;
          PutIt(I, J, 1, tidPieces[Field[I, J].Color, Field[I, J].Kind]);
        end;
      if FDrawSelection and (GetCheckKind <> ckNone) then
      begin
        GetKingXY(I, J);
        PutIt(I, J, 2, tidCheck);
      end;
      if FDragStarted and FDrawSelection then
        PutIt(FDragX, FDragY, 3, tidSelection);
    end;
  end;

var
  TempBuffer: TBitmap;
  ItemHeight: integer;
  NewState: RBoardState;

  procedure ClearTempBuffer;
  // Clears the temp buffer.
  begin
    with TempBuffer do
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := Self.Color;
      Canvas.FillRect(Rect(0, 0, Width, Height));
    end;
  end;

  procedure PushTempBuffer(X, Y: integer);
  // Draws the temp buffer's contents.
  begin
    FDrawImage.Canvas.StretchDraw(
      Rect((X + 1) * CellHeight, (Y + 1) * CellHeight, (X + 2) *
      CellHeight, (Y + 2) * CellHeight),
      TempBuffer);
  end;

  procedure OutTextures(X, Y: integer; ID: RBoardTextures;
    PushBuffer: boolean = True);
  // Draws the textures on the temp buffer.
  var
    I: integer;
  begin
    ClearTempBuffer;
    with FTextureContainer do
      for I := 0 to MaxLayer - 1 do
        if ID.Layers[I] >= 0 then
          DrawTexture(TempBuffer.Canvas, 0, 0, ID.Layers[I]);
    if PushBuffer then
      PushTempBuffer(X, Y);
  end;

  procedure OutCoordinates(Row: TBoardRowKind; X, Y, AlignX, AlignY: integer);
  // Draws the coordinates on the temp buffer.
  var
    Coord: integer;
  begin
    if Row = rkRow then
      Coord := X
    else
      Coord := Y;
    if FInverted then
      Coord := 7 - Coord;
    with FTextureContainer do
      OutCoordinate(TempBuffer.Canvas, 0, 0, Coord, Row, AlignX, AlignY);
  end;

  procedure OutTexturesCoordinates(Row: TBoardRowKind; X, Y: integer;
    ID: RBoardTextures; AlignX, AlignY: integer);
  // Draws textures & coordinates on the temp buffer.
  begin
    OutTextures(X, Y, ID, False);
    OutCoordinates(Row, X, Y, AlignX, AlignY);
    PushTempBuffer(X, Y);
  end;

  procedure OutMoveSide;
  // Draws "who moves" indicator.
  var
    T: RBoardTextures;
    I: integer;
  begin
    for I := 0 to MaxLayer - 1 do
      T.Layers[I] := -1;
    // right top corner
    T.Layers[0] := tidBoardRightTop;
    if (FChessBoard.MoveSide = pcBlack) xor FInverted then
      T.Layers[1] := tidColorIndicator[FInverted, FChessBoard.MoveSide];
    OutTextures(8, -1, T);
    T.Layers[1] := -1;
    // right bottom corner
    T.Layers[0] := tidBoardRightBottom;
    if (FChessBoard.MoveSide = pcWhite) xor FInverted then
      T.Layers[1] := tidColorIndicator[FInverted, FChessBoard.MoveSide];
    OutTextures(8, 8, T);
    T.Layers[1] := -1;
  end;

  procedure OutBorders;
  // Draws the borders.
  var
    T: RBoardTextures;
    I: integer;
  begin
    for I := 0 to MaxLayer - 1 do
      T.Layers[I] := -1;
    // left top corner
    T.Layers[0] := tidBoardLeftTop;
    OutTextures(-1, -1, T);
    // left bottom corner
    T.Layers[0] := tidBoardLeftBottom;
    T.Layers[1] := tidInverted[FInverted];
    OutTextures(-1, 8, T);
    T.Layers[1] := -1;
    // right top corner & Right bottom corner are drawn by OutMoveSide
    OutMoveSide;
    // drawing left & right borders
    for I := 0 to 7 do
    begin
      // left borders
      T.Layers[0] := tidBoardLeft;
      OutTexturesCoordinates(rkColumn, -1, I, T, talRight, talCenter);
      // right borders
      T.Layers[0] := tidBoardRight;
      OutTexturesCoordinates(rkColumn, 8, I, T, talLeft, talCenter);
    end;
    // drawing top & bottom borders
    for I := 0 to 7 do
    begin
      // top borders
      T.Layers[0] := tidBoardTop;
      OutTexturesCoordinates(rkRow, I, -1, T, talCenter, talBottom);
      // bottom borders
      T.Layers[0] := tidBoardBottom;
      OutTexturesCoordinates(rkRow, I, 8, T, talCenter, talTop);
    end;
  end;

  procedure OutCells(FullyRefresh: boolean);
  // Draws the board cells.
  var
    I, J: integer;
  begin
    for I := 0 to 7 do
      for J := 0 to 7 do
        if FullyRefresh or (NewState.Textures[I, J] <> FState.Textures[I, J])
        then
          OutTextures(I, J, NewState.Textures[I, J]);
  end;

var
  NewH, NewW: integer;
  FullyRefresh: boolean;
begin
  if not Assigned(FTextureContainer) then
    Exit;
  ItemHeight := FTextureContainer.GetItemHeight;
  FullyRefresh := False;
  // resize the buffer
  TempBuffer := TBitmap.Create;
  TempBuffer.SetSize(ItemHeight, ItemHeight);
  // get current state
  NewState := GetState;
  // if size changed - redraw all
  if (FState.CellHeight <> NewState.CellHeight) then
  begin
    NewH := CellHeight * BoardCellHeight;
    NewW := CellHeight * BoardCellHeight;
    FullyRefresh := True;
    FDrawImage.SetSize(NewW, NewH);
  end;
  // redraw borders
  if FullyRefresh or (FState.Inverted <> NewState.Inverted) then
    OutBorders
  else if (FState.MoveSide <> NewState.MoveSide) then
    OutMoveSide;
  // redraw cells
  OutCells(FullyRefresh);
  // set new state
  FState := NewState;
  FreeAndNil(TempBuffer);
end;

procedure TVisualChessBoard.DrawMoving;
// Draws cursors & moving pieces.

  procedure DrawIt(ID: integer; DrawOutOfBoard: boolean);
  var
    Point: TPoint;
  begin
    if MouseOutOfBoard and (not DrawOutOfBoard) then
      Exit;
    Point := ScreenToClient(Mouse.CursorPos);
    Dec(Point.x, CellHeight div 2);
    Dec(Point.y, CellHeight div 2);
    FTextureContainer.StretchDrawTexture(PaintBox.Canvas,
      Rect(Point.x, Point.y, Point.x + CellHeight, Point.y + CellHeight), ID);
  end;

begin
  if not Assigned(FTextureContainer) then
    Exit;
  with FChessBoard do
  begin
    // draw moving pieces
    if FDragStarted then
    begin
      with Field[FDragX, FDragY] do
        DrawIt(tidPieces[Color, Kind], True);
    end;
    // draw cursors
    if (not FDragStarted) and (FCursorID <> -1) then
      DrawIt(FCursorID, False);
  end;
end;

