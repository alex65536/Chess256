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
    This file contains TApplicationForm - a base class for all the forms in the
    program.
}
unit ApplicationForms;

{$I CompilerDirectives.inc}

interface

uses
  Forms, StdCtrls, Classes;

type
  TApplicationForm = class;

  { TFormContainer }

  TFormContainer = class(TFrame)
  private
    FForm: TApplicationForm;
    // Getters / Setters
    procedure SetForm(AValue: TApplicationForm);
    procedure SetShown(AValue: boolean);
  protected
    // Virtual methods
    procedure BindForm(AForm: TApplicationForm); virtual;
    procedure UnbindForm; virtual;
    function GetShown: boolean; virtual; abstract;
    procedure ShowForm; virtual; abstract;
    procedure HideForm; virtual; abstract;
  public
    // Properties
    property Shown: boolean read GetShown write SetShown;
    property Form: TApplicationForm read FForm write SetForm;
  end;

  { TApplicationForm }

  TApplicationForm = class(TForm)
  private
    FContainer: TFormContainer;
    FOnCaptionChange: TNotifyEvent;
  protected
    procedure TextChanged; override;
  public
    property Container: TFormContainer read FContainer;
    property OnCaptionChange: TNotifyEvent read FOnCaptionChange write FOnCaptionChange;
    procedure ShowWithContainer;
    constructor Create(TheOwner: TComponent); override;
  end;

implementation

{ TFormContainer }

procedure TFormContainer.SetForm(AValue: TApplicationForm);
begin
  if FForm = AValue then
    Exit;
  UnbindForm;
  BindForm(AValue);
end;

procedure TFormContainer.SetShown(AValue: boolean);
begin
  if AValue = GetShown then
    Exit;
  if AValue then
    ShowForm
  else
    HideForm;
end;

procedure TFormContainer.BindForm(AForm: TApplicationForm);
// Binds the forms to the container.
begin
  if AForm = nil then
    Exit;
  FForm := AForm;
  FForm.FContainer := Self;
end;

procedure TFormContainer.UnbindForm;
// Unbinds the forms to the container.
begin
  if FForm = nil then
    Exit;
  FForm.FContainer := nil;
  FForm := nil;
end;

{ TApplicationForm }

procedure TApplicationForm.TextChanged;
begin
  inherited TextChanged;
  if Assigned(FOnCaptionChange) then
    FOnCaptionChange(Self);
end;

procedure TApplicationForm.ShowWithContainer;
// Shows the form with the container.
begin
  if Assigned(FContainer) then
    FContainer.Shown := True
  else
    Visible := True;
end;

constructor TApplicationForm.Create(TheOwner: TComponent);
begin
  FContainer := nil;
  inherited Create(TheOwner);
end;

end.
