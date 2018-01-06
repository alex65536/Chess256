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
    This unit contains a dialog for starting the game.
}
unit GameStartDialogs;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, ButtonPanel, Buttons,
  ApplicationForms, PlayerSelectors, ChessGame, ChessRules, TimerConfigureForms,
  PositionEditors;

const
  DefaultTimeControl = '300';

resourcestring
  SPGNSiteName = 'Local computer';

type

  { TNewGameDialog }

  TNewGameDialog = class(TApplicationForm)
    AnalysisCheck: TCheckBox;
    EngineGroup: TGroupBox;
    EngineLabel: TLabel;
    EngineOptions: TButton;
    EnginePath: TEdit;
    FileNameEdit: TFileNameEdit;
    GameName: TEdit;
    HumanGroup: TGroupBox;
    HumanLabel: TLabel;
    HumanName: TEdit;
    PlayerSelect: TRadioGroup;
    SelectBtn: TBitBtn;
    WhiteGroup: TGroupBox;
    TimeControlGroup: TGroupBox;
    InitialRadio: TRadioButton;
    RadioPanel: TPanel;
    PositionGroup: TGroupBox;
    LGameName: TLabel;
    EventNamePanel: TPanel;
    SpecificRadio: TRadioButton;
    SpecifyBtn: TButton;
    TimeControlBtn: TButton;
    ButtonPanel: TButtonPanel;
    BlackGroup: TGroupBox;
    WhiteSelect: TPlayerSelector;
    PositionTimePanel: TPanel;
    PlayerPanel: TPanel;
    BlackSelect: TPlayerSelector;
    procedure FormShow(Sender: TObject);
    procedure SomethingChanged(Sender: TObject);
    procedure SpecifyBtnClick(Sender: TObject);
    procedure TimeControlBtnClick(Sender: TObject);
  private
    FTimeControlString: string;
    FRawBoard: RRawBoard;
  protected
    procedure UpdateEnabled;
  public
    property TimeControlString: string read FTimeControlString write FTimeControlString;
    property RawBoard: RRawBoard read FRawBoard write FRawBoard;
    procedure ApplyToGame(AGame: TChessGame);
    function Execute: boolean;
    constructor Create(TheOwner: TComponent); override;
  end;

var
  NewGameDialog: TNewGameDialog;

implementation

{$R *.lfm}

{ TNewGameDialog }

procedure TNewGameDialog.FormShow(Sender: TObject);
begin
  WhiteSelect.RecreateEngine;
  BlackSelect.RecreateEngine;
  UpdateEnabled;
end;

procedure TNewGameDialog.SomethingChanged(Sender: TObject);
begin
  UpdateEnabled;
end;

procedure TNewGameDialog.SpecifyBtnClick(Sender: TObject);
begin
  PositionEditor.RawBoard := FRawBoard;
  if PositionEditor.Execute then
    FRawBoard := PositionEditor.RawBoard;
end;

procedure TNewGameDialog.TimeControlBtnClick(Sender: TObject);
begin
  TimerConfigureForm.WhiteCanInfinite := False;
  TimerConfigureForm.BlackCanInfinite := False;
  TimerConfigureForm.TimeControlString := FTimeControlString;
  if TimerConfigureForm.Execute then
    FTimeControlString := TimerConfigureForm.TimeControlString;
end;

procedure TNewGameDialog.UpdateEnabled;
begin
  TimeControlGroup.Enabled := not AnalysisCheck.Checked;
  PlayerPanel.Enabled := not AnalysisCheck.Checked;
  SpecifyBtn.Enabled := SpecificRadio.Checked;
end;

procedure TNewGameDialog.ApplyToGame(AGame: TChessGame);
// Applies the dialog info to the game.
begin
  // clear board
  if InitialRadio.Checked then
    AGame.ChessNotation.ClearCustom(GetInitialPosition)
  else
    AGame.ChessNotation.ClearCustom(FRawBoard);
  // update players & time control
  if AnalysisCheck.Checked then
  begin
    // analysis mode
    AGame.ChessTimer.TimeControl.TimeControlString := '-';
    AGame.WhitePlayer.Name := '?';
    AGame.WhitePlayer.Engine := nil;
    AGame.BlackPlayer.Name := '?';
    AGame.BlackPlayer.Engine := nil;
  end
  else
  begin
    AGame.ChessTimer.TimeControl.TimeControlString := FTimeControlString;
    WhiteSelect.SetToPlayer(AGame.WhitePlayer);
    BlackSelect.SetToPlayer(AGame.BlackPlayer);
    AGame.StartGame;
  end;
  // update tags
  with AGame.ChessNotation.Tags do
  begin
    Clear;
    Tags['Event'] := GameName.Text;
    Tags['Site'] := SPGNSiteName;
    Tags['Date'] := FormatDateTime('yyyy.mm.dd', Now);
    Tags['White'] := AGame.WhitePlayer.Name;
    Tags['Black'] := AGame.BlackPlayer.Name;
    Tags['TimeControl'] := AGame.ChessTimer.TimeControl.TimeControlString;
  end;
end;

function TNewGameDialog.Execute: boolean;
  // Executes the dialog.
begin
  Result := ShowModal = mrOk;
end;

constructor TNewGameDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FRawBoard := GetInitialPosition;
  FTimeControlString := DefaultTimeControl;
end;

end.
