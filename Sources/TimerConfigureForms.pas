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
    This unit contains a dialog to configure the chess clock.
}
unit TimerConfigureForms;

{$I CompilerDirectives.inc}

interface

uses
  Classes, Controls, ButtonPanel, ExtCtrls, TimerConfigurePairs, ApplicationForms;

type

  { TTimerConfigureForm }

  TTimerConfigureForm = class(TApplicationForm)
    ButtonPanel: TButtonPanel;
    Panel: TPanel;
    Configurer: TTimerConfigurePair;
    procedure ConfigurerResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FResizeLockCount: integer;
    // Getters / Setters
    function GetBlackCanInfinite: boolean;
    function GetTimeControlString: string;
    function GetWhiteCanInfinite: boolean;
    procedure SetBlackCanInfinite(AValue: boolean);
    procedure SetTimeControlString(AValue: string);
    procedure SetWhiteCanInfinite(AValue: boolean);
  public
    // Properties
    property TimeControlString: string read GetTimeControlString
      write SetTimeControlString;
    property WhiteCanInfinite: boolean read GetWhiteCanInfinite
      write SetWhiteCanInfinite;
    property BlackCanInfinite: boolean read GetBlackCanInfinite
      write SetBlackCanInfinite;
    // Methods
    function Execute: boolean;
  end;

var
  TimerConfigureForm: TTimerConfigureForm;

implementation

{$R *.lfm}

{ TTimerConfigureForm }

procedure TTimerConfigureForm.ConfigurerResize(Sender: TObject);
begin
  // made for form autosizing (by some reason, LCL autosizing is not
  // supported while the form showing).
  if FResizeLockCount <> 0 then
    Exit;
  Inc(FResizeLockCount);
  ClientWidth := Panel.Width;
  ClientHeight := Panel.Height;
  Dec(FResizeLockCount);
end;

procedure TTimerConfigureForm.FormCreate(Sender: TObject);
begin
  FResizeLockCount := 0;
end;

procedure TTimerConfigureForm.FormResize(Sender: TObject);
begin
  // made for form autosizing: by some reason, LCL autosizing is not
  // supported while the form showing.
  ConfigurerResize(Self);
end;

function TTimerConfigureForm.GetTimeControlString: string;
begin
  Result := Configurer.TimeControlString;
end;

function TTimerConfigureForm.GetWhiteCanInfinite: boolean;
begin
  Result := Configurer.WhiteCanInfiniteTime;
end;

function TTimerConfigureForm.GetBlackCanInfinite: boolean;
begin
  Result := Configurer.BlackCanInfiniteTime;
end;

procedure TTimerConfigureForm.SetTimeControlString(AValue: string);
begin
  Configurer.TimeControlString := AValue;
end;

procedure TTimerConfigureForm.SetWhiteCanInfinite(AValue: boolean);
begin
  Configurer.WhiteCanInfiniteTime := AValue;
end;

procedure TTimerConfigureForm.SetBlackCanInfinite(AValue: boolean);
begin
  Configurer.BlackCanInfiniteTime := AValue;
end;

function TTimerConfigureForm.Execute: boolean;
  // Executes the dialog.
begin
  Result := ShowModal = mrOk;
end;

end.
