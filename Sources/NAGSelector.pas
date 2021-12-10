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
    This unit contains a dialog to select NAGs (Numeric Annotation Glyphs).
}
unit NAGSelector;

{$I CompilerDirectives.inc}

interface

uses
  Classes, Controls, ExtCtrls, ButtonPanel, NAGUtils, StdCtrls, ApplicationForms,
  ChessRules, ChessGUIUtils;

const
  // Sizes of the NAG grid.
  NAGColCount = 6;
  NAGRowCount = 5;

type

  { TNAGSelect }

  TNAGSelect = class(TApplicationForm)
    ButtonPanel: TButtonPanel;
    FlowPanel: TFlowPanel;
    procedure FormShow(Sender: TObject);
    procedure ToggleBoxClicker(Sender: TObject);
  private
    FChanging: integer;
    FNAG: byte;
    FButtonH, FButtonW: integer;
    FControls: array [byte] of TToggleBox;
    // Getters / Setters
    procedure SetNAG(AValue: byte);
    // Recalc methods
    procedure UpdateChecked;
    procedure CreateFlowPanel;
  public
    property NAG: byte read FNAG write SetNAG;
    procedure AfterConstruction; override;
    function Execute: boolean;
  end;

var
  NAGSelect: TNAGSelect;

implementation

{$R *.lfm}

{ TNAGSelect }

procedure TNAGSelect.FormShow(Sender: TObject);
begin
  // resize our form
  ClientWidth := FButtonW * NAGColCount + 1;
  ClientHeight := FButtonH * NAGRowCount + GetActualHeight(ButtonPanel);
end;

procedure TNAGSelect.ToggleBoxClicker(Sender: TObject);
begin
  // if clicked, we set NAG
  SetNAG((Sender as TToggleBox).Tag);
end;

procedure TNAGSelect.SetNAG(AValue: byte);
begin
  // FChanging is used to prevent loops
  if FChanging <> 0 then
    Exit;
  // convert as NAG for white
  AValue := ConvertNAG(AValue, pcWhite);
  // now, assign & update
  Inc(FChanging);
  FNAG := AValue;
  UpdateChecked;
  Dec(FChanging);
end;

procedure TNAGSelect.UpdateChecked;
// Updates Checked for all the toggle boxes.
var
  I: byte;
begin
  for I := Low(byte) to High(byte) do
    if (FControls[I] <> nil) then
      FControls[I].Checked := I = FNAG;
end;

procedure TNAGSelect.CreateFlowPanel;
// Creates the toggle boxes on the FlowPanel.
var
  TextH: integer;
  I: byte;
begin
  FButtonH := 0;
  FButtonW := 0;
  // applying font
  FlowPanel.Font.Name := DefaultChessFont;
  FlowPanel.Font.Size := DefaultChessFontSize;
  // counting text height
  TextH := FlowPanel.Canvas.TextHeight('Cheetah!!!');
  // now, go & create buttons
  for I := Low(byte) to High(byte) do
  begin
    FControls[I] := nil;
    if not CanAddNAG(I) then
      Continue;
    FControls[I] := TToggleBox.Create(Self);
    with FControls[I] do
    begin
      // set button's properties
      ClientHeight := Round(TextH * 1.8);
      ClientWidth := Round(TextH * 1.8);
      AutoSize := False;
      Tag := I;
      Caption := NAGStrings[I];
      Parent := FlowPanel;
      Align := alTop;
      ParentFont := True;
      OnChange := @ToggleBoxClicker;
      // update sizes
      FButtonH := GetActualHeight(FControls[I]);
      FButtonW := GetActualWidth(FControls[I]);
    end;
  end;
end;

procedure TNAGSelect.AfterConstruction;
begin
  inherited AfterConstruction;
  FChanging := 0;
  FNAG := 0;
  CreateFlowPanel;
end;

function TNAGSelect.Execute: boolean;
  // Executes the dialog.
begin
  Result := ShowModal = mrOk;
  if NAG = 0 then
    Result := False;
end;

end.
