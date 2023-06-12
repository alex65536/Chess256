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
    This is a Chess PGN Database window.
    This file Coded by Jim Kinsman <relipse@gmail.com>
}
unit unitFrmPgnDatabase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Grids, Menus, Types, BoardForms;

type

  { TfrmPGNDatabase }

  TfrmPGNDatabase = class(TForm)
    mniLoadGame: TMenuItem;
    pnlDatabase: TPanel;
    gridPGNDatabase: TStringGrid;
    pmnPGNDatabase: TPopupMenu;
    procedure gridPGNDatabaseDblClick(Sender: TObject);
    procedure gridPGNDatabaseDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure gridPGNDatabaseMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure gridPGNDatabasePrepareCanvas(Sender: TObject; aCol,
      aRow: Integer; aState: TGridDrawState);
    procedure mniLoadGameClick(Sender: TObject);
  private

  public

  end;

var
  frmPGNDatabase: TfrmPGNDatabase;
  My_Grid_Highlight_BackGround_Color:Tcolor=ClGreen;
  My_Grid_Highlight_Font_Color:Tcolor=clYellow;
  My_Grid_Highlight_Font_Multiplier:Real=1.5;  // FOnt Multiplier for selected row
  LastRow : Integer;
implementation

uses
  MainUnit, GraphUtil, LCLIntf;
{$R *.lfm}

{ TfrmPGNDatabase }

procedure TfrmPGNDatabase.gridPGNDatabaseDblClick(Sender: TObject);
begin
    mniLoadGameClick(nil);
end;
procedure TfrmPGNDatabase.gridPGNDatabaseDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
begin
  If Sender is TStringGrid then
  begin
    With (sender as TStringGrid) Do
    Begin
      Canvas.Brush.Style := bsSolid;
      canvas.Font.Color:=clWhite;
      if arow=row then       // Selected Row
      begin
        FocusColor:=My_Grid_Highlight_BackGround_Color;
        Canvas.Brush.Color:=My_Grid_Highlight_BackGround_Color;
        canvas.Font.Color:=My_Grid_Highlight_Font_Color;
        canvas.Font.Size:=round(font.Size*My_Grid_Highlight_Font_Multiplier);
      end
      else
      begin
        canvas.Font.Color:=font.Color;
        Canvas.Brush.Color:=color;
        canvas.Font.Size:=font.Size;
      end;
      defaultdrawcell(Acol, Arow, arect, astate);
    end;
  end;
end;

procedure TfrmPGNDatabase.gridPGNDatabaseMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  R, C:        Integer;
  Start, Size: Integer;
  i:           Integer;
begin
  gridPGNDatabase.MouseToCell(X, Y, c, r);
  LastRow := r;
end;

procedure TfrmPGNDatabase.gridPGNDatabasePrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  P: TPoint;
  c, r: LongInt;
  obe: Boolean;
begin
  P := gridPGNDatabase.ScreenToClient(Mouse.CursorPos);
  if (aState = []) or (gdFixed in aState) then
  begin
    obe := gridPGNDatabase.AllowOutBoundEvents;
    gridPGNDatabase.AllowOutBoundEvents := false;
    gridPGNDatabase.MouseToCell(P.X, P.Y, c, r);
    gridPGNDatabase.AllowOutBoundEvents := obe;
    if (aRow = r) and (aRow >= gridPGNDatabase.FixedRows) then
    begin
      if aState = [] then
        gridPGNDatabase.Canvas.Brush.Color := rgb(232, 232, 232)
      else
        gridPGNDatabase.Canvas.Brush.Color := GetShadowColor(ColorToRGB(gridPGNDatabase.FixedColor), -20);
    end;
  end;
  gridPGNDatabase.Invalidate();
  gridPGNDatabase.Refresh();
end;

procedure TfrmPGNDatabase.mniLoadGameClick(Sender: TObject);
begin
   BoardForm.Caption := gridPGNDatabase.Rows[gridPGNDatabase.Row].Strings[1];
   if (BoardForm.Caption = '') then
   begin
     BoardForm.Caption := 'Board';
   end;
   MainForm.FGame.ChessNotation.PGNString := gridPGNDatabase.Rows[gridPGNDatabase.Row].Strings[0] + ' ' + gridPGNDatabase.Rows[gridPGNDatabase.Row].Strings[3];
   while (not MainForm.FGame.ChessNotation.Iterator.IsFirst) do
   begin
      MainForm.FGame.ChessNotation.Iterator.PrevMove();
   end;
end;

{ TfrmPGNDatabase }


end.

