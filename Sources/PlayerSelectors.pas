{
  This file is part of Chess 256.

  Copyright © 2016, 2018 Kernozhitsky Alexander <sh200105@mail.ru>

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
    This file implements a components that allows to choose a player (human or
    engine) and specify the executable path for engine.
}
unit PlayerSelectors;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Classes, SysUtils, Forms, EditBtn, StdCtrls, ExtCtrls, ChessGame, ChessEngines,
  Dialogs, Buttons, EngineConfigurers, EngineStrings;

resourcestring
  SPlayer = 'Player';

type

  { TFileNameEdit }

  TFileNameEdit = class(EditBtn.TFileNameEdit)
  private
    function GetButton: TSpeedButton;
  public
    property Button: TSpeedButton read GetButton;
  end;

  { TPlayerSelector }

  TPlayerSelector = class(TFrame)
    FileNameEdit: TFileNameEdit;
    OpenDialog: TOpenDialog;
    SelectBtn: TBitBtn;
    EnginePath: TEdit;
    EngineOptions: TButton;
    EngineGroup: TGroupBox;
    EngineLabel: TLabel;
    HumanName: TEdit;
    HumanGroup: TGroupBox;
    HumanLabel: TLabel;
    PlayerSelect: TRadioGroup;
    procedure EngineOptionsClick(Sender: TObject);
    procedure PlayerSelectClick(Sender: TObject);
    procedure SelectBtnClick(Sender: TObject);
  private
    FEventsLockCount: integer;
    FEngine: TAbstractChessEngine;
    FChanged: boolean;
  protected
    procedure UpdateAll;
    procedure DestroyEngine;
    procedure ChangeEngineName(const AFileName: string);
    procedure SetEnabled(Value: boolean); override;
  public
    procedure SetToPlayer(APlayer: TChessPlayer);
    procedure RecreateEngine;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.lfm}

{ TFileNameEdit }

function TFileNameEdit.GetButton: TSpeedButton;
begin
  Result := inherited Button;
end;

{ TPlayerSelector }

procedure TPlayerSelector.EngineOptionsClick(Sender: TObject);
begin
  if PlayerSelect.ItemIndex <> 1 then
    Exit;
  ExecuteConfigurer(FEngine, nil);
end;

procedure TPlayerSelector.PlayerSelectClick(Sender: TObject);
begin
  if FEventsLockCount <> 0 then
    Exit;
  try
    if PlayerSelect.ItemIndex = 1 then
    begin
      if not Assigned(FEngine) then
      begin
        FChanged := False;
        SelectBtn.Click;
        if not FChanged then
          PlayerSelect.ItemIndex := 0;
      end;
    end;
  finally
    UpdateAll;
  end;
end;

procedure TPlayerSelector.SelectBtnClick(Sender: TObject);
begin
  OpenDialog.FileName := EnginePath.Text;
  if OpenDialog.Execute then
    ChangeEngineName(OpenDialog.FileName);
end;

procedure TPlayerSelector.UpdateAll;
// Updates properties of the frame.
begin
  SelectBtn.Width := SelectBtn.Height;
  if FEventsLockCount <> 0 then
    Exit;
  Inc(FEventsLockCount);
  if PlayerSelect.ItemIndex = 0 then
  begin
    HumanGroup.Enabled := Self.Enabled;
    EngineGroup.Enabled := False;
  end
  else
  begin
    HumanGroup.Enabled := False;
    EngineGroup.Enabled := Self.Enabled;
  end;
  // a trick (to fix the LCL's bugs) to make the controls draw correctly
  HumanLabel.Enabled := HumanGroup.Enabled;
  HumanName.Enabled := HumanGroup.Enabled;
  EngineLabel.Enabled := EngineGroup.Enabled;
  EnginePath.Enabled := EngineGroup.Enabled;
  SelectBtn.Enabled := EngineGroup.Enabled;
  EngineOptions.Enabled := EngineGroup.Enabled;
  // now, update the path ...
  if Assigned(FEngine) then
    EnginePath.Text := FEngine.FileName
  else
    EnginePath.Text := '';
  Dec(FEventsLockCount);
end;

procedure TPlayerSelector.DestroyEngine;
// Destroys the engine.
begin
  if Assigned(FEngine) then
    FEngine.Uninitialize;
  FreeAndNil(FEngine);
end;

procedure TPlayerSelector.ChangeEngineName(const AFileName: string);
// Changes the engine's location to AFileName.
var
  EngineCreated: boolean;
  AEngine: TAbstractChessEngine;
begin
  if FEventsLockCount <> 0 then
    Exit;
  if PlayerSelect.ItemIndex <> 1 then
    Exit;
  FChanged := True;
  Inc(FEventsLockCount);
  EngineCreated := False;
  try
    AEngine := TUCIChessEngine.Create(AFileName);
    EngineCreated := True;
    AEngine.Initialize;
  except
    on E: Exception do
    begin
      if EngineCreated then
        FreeAndNil(AEngine);
      if not Assigned(FEngine) then
        PlayerSelect.ItemIndex := 0;
      Dec(FEventsLockCount);
      UpdateAll;
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  DestroyEngine;
  FEngine := AEngine;
  Dec(FEventsLockCount);
  UpdateAll;
end;

procedure TPlayerSelector.SetEnabled(Value: boolean);
begin
  if Value = GetEnabled then
    Exit;
  inherited SetEnabled(Value);
  UpdateAll;
end;

procedure TPlayerSelector.SetToPlayer(APlayer: TChessPlayer);
// Assigns the panel's parameters to APlayer.
begin
  if PlayerSelect.ItemIndex = 0 then
  begin
    APlayer.Engine := nil;
    APlayer.Name := HumanName.Caption;
  end
  else
  begin
    APlayer.Engine := FEngine;
    APlayer.Name := FEngine.Name;
    FEngine := nil;
  end;
end;

procedure TPlayerSelector.RecreateEngine;
// Re-creates the engine from file.
var
  EngineCreated: boolean;
begin
  if FEngine <> nil then
    Exit;
  if EnginePath.Text = '' then
    Exit;
  EngineCreated := False;
  try
    FEngine := TUCIChessEngine.Create(EnginePath.Text);
    EngineCreated := True;
    FEngine.Initialize;
  except
    on E: Exception do
    begin
      if EngineCreated then
        FreeAndNil(FEngine);
      FEngine := nil;
      EnginePath.Text := '';
      PlayerSelect.ItemIndex := 0;
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
end;

constructor TPlayerSelector.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  SelectBtn.Glyph.Assign(FileNameEdit.Button.Glyph);
  OpenDialog.Filter := Format(SEngineFilter, [EngineFilter]);
  OpenDialog.DefaultExt := EngineDefExt;
  FEngine := nil;
  EnginePath.Text := EngineName;
end;

destructor TPlayerSelector.Destroy;
begin
  DestroyEngine;
  inherited Destroy;
end;

end.
