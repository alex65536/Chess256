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
    This unit implements the move variant list. Moves can be made by clicking on
    an appropriate move variant.
}

{
  TODO : Decide what to do with this unit. Earlier, it was added with testing
  purposes. Now it's unknown if it's necessary now.
}
unit MoveVariantForms;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ApplicationForms, ChessBoards, NotationForms, MoveConverters, ChessGUIUtils;

type

  { TMoveVariantForm }

  TMoveVariantForm = class(TApplicationForm)
    ListBox: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBoxDblClick(Sender: TObject);
    procedure ListBoxKeyPress(Sender: TObject; var Key: char);
    procedure VisualBoardChanger(Sender: TObject);
  private
    FMoveConverter: TNotationMoveConverter;
    FVisualBoard: TVisualChessBoard;
    procedure SetVisualBoard(AValue: TVisualChessBoard);
  public
    property VisualBoard: TVisualChessBoard read FVisualBoard write SetVisualBoard;
    procedure ShowMoves;
  end;

var
  MoveVariantForm: TMoveVariantForm;

implementation

{$R *.lfm}

{ TMoveVariantForm }

procedure TMoveVariantForm.FormCreate(Sender: TObject);
begin
  FMoveConverter := TNotationMoveConverter.Create;
  ListBox.Font.Name := DefaultChessFont;
  ListBox.Font.Size := DefaultChessFontSize;
end;

procedure TMoveVariantForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FMoveConverter);
end;

procedure TMoveVariantForm.ListBoxDblClick(Sender: TObject);
var
  MoveIndex: integer;
begin
  if ListBox.ItemIndex = -1 then
    Exit;
  with ListBox do
    MoveIndex := PtrInt(Items.Objects[ItemIndex]);
  with NotationForm.ChessNotation do
    AddMove(VisualBoard.ChessBoard.Moves[MoveIndex]);
end;

procedure TMoveVariantForm.ListBoxKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
    ListBox.OnDblClick(Self);
end;

procedure TMoveVariantForm.VisualBoardChanger(Sender: TObject);
begin
  ShowMoves;
end;

procedure TMoveVariantForm.SetVisualBoard(AValue: TVisualChessBoard);
begin
  if FVisualBoard = AValue then
    Exit;
  if FVisualBoard <> nil then
    FVisualBoard.RemoveHandlerOnChange(@VisualBoardChanger);
  FVisualBoard := AValue;
  FVisualBoard.ChessBoard.AutoGenerateMoves := True;
  if FVisualBoard <> nil then
    FVisualBoard.AddHandlerOnChange(@VisualBoardChanger);
  ShowMoves;
end;

procedure TMoveVariantForm.ShowMoves;
// Shows the move variants on the list box.
var
  I: integer;
begin
  // clear
  ListBox.Clear;
  // check
  if not NotationForm.ChessNotation.CanAddMove then
    Exit;
  // add moves
  with VisualBoard.ChessBoard do
  begin
    FMoveConverter.RawBoard := RawBoard;
    for I := 0 to MoveCount - 1 do
      with Moves[I] do
        ListBox.Items.AddObject(FMoveConverter.GetMoveString(Moves[I]),
          TObject(PtrInt(I)));
  end;
end;

end.
