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
    This unit contains an implementation of the abstract class TEngineConfigurer
    to configure UCI engines.
}
unit UCIEngineConfigurer;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, Controls, Graphics, ButtonPanel, StdCtrls, ExtCtrls, Spin,
  ChessEngines, EngineConfigurers, UCICommands, ApplicationForms;

resourcestring
  SConfigurerCaption = '%s';

type

  { TUCIConfigurerForm }

  TUCIConfigurerForm = class(TApplicationForm)
    ButtonPanel: TButtonPanel;
    Panel: TPanel;
  private
    FLastLabel: TLabel;
    FLastControl: TControl;
    procedure PushControl(AControl: TControl);
    procedure ChangeLastLabel(ALabel: TLabel);
    procedure AnchorToLastLabel(AControl: TControl;
      AnchorToRightCorner: boolean = False);
    function AddPanelWithLabel(const AName: string): TPanel;
  public
    procedure BeginAdd;
    procedure AddCheckBox(AOption: TCheckBoxOption);
    procedure AddSpinEdit(AOption: TSpinEditOption);
    procedure AddComboBox(AOption: TComboBoxOption);
    procedure AddEdit(AOption: TEditOption);
    procedure AddButton(AOption: TButtonOption);
    constructor Create(AOwner: TComponent); override;
  end;

  { TUCIChessConfigurer }

  TUCIChessConfigurer = class(TEngineConfigurer)
  public
    function Execute: boolean; override;
  end;

var
  UCIConfigurerForm: TUCIConfigurerForm;

implementation

{$R *.lfm}

{ TUCIConfigurerForm }

procedure TUCIConfigurerForm.PushControl(AControl: TControl);
// Adds AControl to the top of the form.
begin
  if Assigned(FLastControl) then
  begin
    AControl.Top := FLastControl.Top + 1;
    (AControl as TWinControl).TabOrder :=
      (FLastControl as TWinControl).TabOrder + 1;
  end
  else
  begin
    AControl.Top := 0;
    (AControl as TWinControl).TabOrder := 0;
  end;
  AControl.Align := alTop;
  FLastControl := AControl;
end;

procedure TUCIConfigurerForm.ChangeLastLabel(ALabel: TLabel);
// Indicates that ALabel was the last added label.
begin
  ALabel.BorderSpacing.Right := 6;
  ALabel.Align := alLeft;
  FLastLabel := ALabel;
end;

procedure TUCIConfigurerForm.AnchorToLastLabel(AControl: TControl;
  AnchorToRightCorner: boolean);
// Anchors AControl to the last added label.
begin
  if FLastLabel = nil then
    Exit;
  AControl.Left := AControl.Left + 1; // to make it change
  if AnchorToRightCorner then
    AControl.Align := alClient
  else
    AControl.Align := alLeft;
  FLastLabel.Align := alLeft;
end;

function TUCIConfigurerForm.AddPanelWithLabel(const AName: string): TPanel;
  // Creates a panel with a label which caption is AName and adds it to the top of the form.
begin
  Result := TPanel.Create(Self);
  with Result do
  begin
    Caption := '';
    BevelInner := bvNone;
    BevelOuter := bvNone;
    Parent := Panel;
    AutoSize := True;
    PushControl(Result);
  end;
  FLastLabel := TLabel.Create(Self);
  with FLastLabel do
  begin
    Caption := AName;
    Layout := tlCenter;
    Parent := Result;
    AutoSize := True;
    ChangeLastLabel(FLastLabel);
  end;
end;

procedure TUCIConfigurerForm.BeginAdd;
// Starts adding controls to the form.
begin
  FLastControl := nil;
end;

procedure TUCIConfigurerForm.AddCheckBox(AOption: TCheckBoxOption);
// Adds a check box option.
var
  ACheckBox: TCheckBox;
begin
  ACheckBox := TCheckBox.Create(Self);
  with ACheckBox do
  begin
    Caption := AOption.Name;
    Checked := AOption.Checked;
    Parent := Panel;
    AutoSize := True;
    PushControl(ACheckBox);
  end;
  AOption.Tag := PtrInt(ACheckBox);
end;

procedure TUCIConfigurerForm.AddSpinEdit(AOption: TSpinEditOption);
// Adds a spin edit option.
var
  ASpinEdit: TSpinEdit;
begin
  ASpinEdit := TSpinEdit.Create(Self);
  with ASpinEdit do
  begin
    MinValue := AOption.Min;
    MaxValue := AOption.Max;
    Value := AOption.Value;
    Parent := AddPanelWithLabel(AOption.Name);
    AutoSize := True;
    AnchorToLastLabel(ASpinEdit, True);
  end;
  AOption.Tag := PtrInt(ASpinEdit);
end;

procedure TUCIConfigurerForm.AddComboBox(AOption: TComboBoxOption);
// Adds a combo box option.
var
  AComboBox: TComboBox;
begin
  AComboBox := TComboBox.Create(Self);
  with AComboBox do
  begin
    Style := csDropDownList;
    Items.Assign(AOption.Items);
    ItemIndex := AOption.ItemIndex;
    Parent := AddPanelWithLabel(AOption.Name);
    AutoSize := True;
    AnchorToLastLabel(AComboBox, True);
  end;
  AOption.Tag := PtrInt(AComboBox);
end;

procedure TUCIConfigurerForm.AddEdit(AOption: TEditOption);
// Adds a string option.
var
  AEdit: TEdit;
begin
  AEdit := TEdit.Create(Self);
  with AEdit do
  begin
    Text := AOption.Text;
    Parent := AddPanelWithLabel(AOption.Name);
    AutoSize := True;
    AnchorToLastLabel(AEdit, True);
  end;
  AOption.Tag := PtrInt(AEdit);
end;

procedure TUCIConfigurerForm.AddButton(AOption: TButtonOption);
// Adds a button option.
var
  AButton: TToggleBox;
begin
  AButton := TToggleBox.Create(Self);
  with AButton do
  begin
    Caption := AOption.Name;
    Checked := False;
    Parent := Panel;
    Height := Round(Canvas.TextHeight(Caption) * 1.75);
    PushControl(AButton);
  end;
  AOption.Tag := PtrInt(AButton);
end;

constructor TUCIConfigurerForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLastLabel := nil;
end;

{ TUCIChessConfigurer }

function TUCIChessConfigurer.Execute: boolean;
var
  AForm: TUCIConfigurerForm;
  AEngine: TUCIChessEngine;

  procedure PutElements;
  // Puts the elements to the form.
  var
    I: integer;
    AOption: TEngineOption;
  begin
    AForm.BeginAdd;
    for I := 0 to AEngine.OptionCount - 1 do
    begin
      AOption := AEngine.Options[I];
      if AOption is TCheckBoxOption then
        AForm.AddCheckBox(AOption as TCheckBoxOption);
      if AOption is TSpinEditOption then
        AForm.AddSpinEdit(AOption as TSpinEditOption);
      if AOption is TComboBoxOption then
        AForm.AddComboBox(AOption as TComboBoxOption);
      if AOption is TEditOption then
        AForm.AddEdit(AOption as TEditOption);
      if AOption is TButtonOption then
        AForm.AddButton(AOption as TButtonOption);
    end;
  end;

  procedure ApplyOptions;
  // Applies the options to the engine.
  var
    I: integer;
    AOption: TEngineOption;
    CanApply: boolean;
    ApplyOptions: boolean;
  begin
    // calling OnUpdateOptions
    ApplyOptions := True;
    if Assigned(OnUpdateOptions) then
      OnUpdateOptions(Self, ApplyOptions);
    if not ApplyOptions then
      Exit;
    // apply all the options
    for I := 0 to AEngine.OptionCount - 1 do
    begin
      AOption := AEngine.Options[I];
      CanApply := True;
      // apply checkbox
      if AOption is TCheckBoxOption then
        with TCheckBox(AOption.Tag) do
        begin
          if (AOption as TCheckBoxOption).Checked = Checked then
            CanApply := False
          else
            (AOption as TCheckBoxOption).Checked := Checked;
        end;
      // apply spinedit
      if AOption is TSpinEditOption then
        with TSpinEdit(AOption.Tag) do
        begin
          if (AOption as TSpinEditOption).Value = Value then
            CanApply := False
          else
            (AOption as TSpinEditOption).Value := Value;
        end;
      // apply combobox
      if AOption is TComboBoxOption then
        with TComboBox(AOption.Tag) do
        begin
          if ItemIndex < 0 then
            ItemIndex := (AOption as TComboBoxOption).ItemIndex;
          if (AOption as TComboBoxOption).ItemIndex = ItemIndex then
            CanApply := False
          else
            (AOption as TComboBoxOption).ItemIndex := ItemIndex;
        end;
      // apply edit
      if AOption is TEditOption then
        with TEdit(AOption.Tag) do
        begin
          if Text = '' then
            Text := EmptyStr;
          if (AOption as TEditOption).Text = Text then
            CanApply := False
          else
            (AOption as TEditOption).Text := Text;
        end;
      // apply button
      if AOption is TButtonOption then
        CanApply := TToggleBox(AOption.Tag).Checked;
      // if option changed - apply it.
      if CanApply then
        AEngine.ApplyOption(AOption);
    end;
  end;

begin
  Result := False;
  AForm := TUCIConfigurerForm.Create(nil);
  try
    AForm.Caption := Format(SConfigurerCaption, [Engine.Name]);
    AEngine := Engine as TUCIChessEngine;
    PutElements;
    if AForm.ShowModal = mrOk then
    begin
      Result := True;
      ApplyOptions;
    end;
  finally
    FreeAndNil(AForm);
  end;
end;

initialization
  RegisterConfigurer(TUCIChessEngine, TUCIChessConfigurer);

end.
