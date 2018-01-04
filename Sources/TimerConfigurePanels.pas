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
    This unit contains TTimerConfigurePanel, that represents one item of
    TTimerConfigure.
}
unit TimerConfigurePanels;

{$I CompilerDirectives.inc}

interface

uses
  Classes, Forms, ExtCtrls, Spin, StdCtrls, ChessTime, Graphics, Math;

resourcestring
  SMoves = 'moves';
  SRestOfGame = 'the rest of the game';
  SSeconds = 'seconds';
  SInfiniteTime = 'Infinite time';

const
  SMovesLabelVals: array [False .. True] of string = (SMoves, SRestOfGame);
  STimeLabelVals: array [False .. True] of string = (SSeconds, SInfiniteTime);

type

  { TTimerConfigurePanel }

  TTimerConfigurePanel = class(TFrame)
    MovesPanelBtn: TButton;
    IncrementSpin: TSpinEdit;
    LFor: TLabel;
    LPlus: TLabel;
    LSecondsIncrement: TLabel;
    MovesSpin: TSpinEdit;
    MovesPanel: TPanel;
    RightSecondsPanel: TPanel;
    SecondsSpin: TSpinEdit;
    TimeLabel: TLabel;
    MovesLabel: TLabel;
    Panel: TPanel;
    SecondsPanel: TPanel;
    TimePanelBtn: TButton;
    procedure MovesLabelClick(Sender: TObject);
    procedure MovesPanelBtnClick(Sender: TObject);
    procedure MovesPanelBtnEnter(Sender: TObject);
    procedure MovesPanelBtnExit(Sender: TObject);
    procedure TimeLabelClick(Sender: TObject);
    procedure TimePanelBtnClick(Sender: TObject);
    procedure TimePanelBtnEnter(Sender: TObject);
    procedure TimePanelBtnExit(Sender: TObject);
  private
    FInfiniteTime: boolean;
    FOnUpdate: TNotifyEvent;
    FRestOfGame: boolean;
    FCanInfiniteTime: boolean;
    FCanRestOfGame: boolean;
    // Getters / Setters
    function GetTimeControl: RTimeControl;
    procedure SetCanInfiniteTime(AValue: boolean);
    procedure SetCanRestOfGame(AValue: boolean);
    procedure SetInfiniteTime(AValue: boolean);
    procedure SetRestOfGame(AValue: boolean);
    procedure SetTimeControl(AValue: RTimeControl);
    // Other methods
    procedure MovesLabelChanged;
    procedure TimeLabelChanged;
  protected
    procedure DoUpdate;
    procedure UpdateButtons;
    procedure UpdateFocus;
  public
    // Properties
    property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
    property TimeControl: RTimeControl read GetTimeControl write SetTimeControl;
    property CanRestOfGame: boolean read FCanRestOfGame write SetCanRestOfGame;
    property CanInfiniteTime: boolean read FCanInfiniteTime write SetCanInfiniteTime;
    property InfiniteTime: boolean read FInfiniteTime write SetInfiniteTime;
    property RestOfGame: boolean read FRestOfGame write SetRestOfGame;
    // Methods
    constructor Create(TheOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

{ TTimerConfigurePanel }

procedure TTimerConfigurePanel.MovesLabelClick(Sender: TObject);
begin
  if not MovesPanelBtn.Enabled then
    Exit;
  MovesPanelBtn.SetFocus;
  MovesPanelBtn.Click;
end;

procedure TTimerConfigurePanel.MovesPanelBtnClick(Sender: TObject);
begin
  SetRestOfGame(not FRestOfGame);
end;

procedure TTimerConfigurePanel.MovesPanelBtnEnter(Sender: TObject);
begin
  UpdateFocus;
end;

procedure TTimerConfigurePanel.MovesPanelBtnExit(Sender: TObject);
begin
  UpdateFocus;
end;

procedure TTimerConfigurePanel.TimeLabelClick(Sender: TObject);
begin
  if not TimePanelBtn.Enabled then
    Exit;
  TimePanelBtn.SetFocus;
  TimePanelBtn.Click;
end;

procedure TTimerConfigurePanel.TimePanelBtnClick(Sender: TObject);
begin
  SetInfiniteTime(not FInfiniteTime);
end;

procedure TTimerConfigurePanel.TimePanelBtnEnter(Sender: TObject);
begin
  UpdateFocus;
end;

procedure TTimerConfigurePanel.TimePanelBtnExit(Sender: TObject);
begin
  UpdateFocus;
end;

function TTimerConfigurePanel.GetTimeControl: RTimeControl;
begin
  if FInfiniteTime then
  begin
    Result.StartTime := InfVal;
    Result.AddTime := ZeroVal;
  end
  else
  begin
    Result.StartTime := SecondsToClockValue(SecondsSpin.Value);
    Result.AddTime := SecondsToClockValue(IncrementSpin.Value);
  end;
  Result.MoveCount := IfThen(FRestOfGame, -1, MovesSpin.Value);
end;

procedure TTimerConfigurePanel.SetCanInfiniteTime(AValue: boolean);
begin
  if FCanInfiniteTime = AValue then
    Exit;
  FCanInfiniteTime := AValue;
  SetInfiniteTime(FInfiniteTime);
  UpdateButtons;
end;

procedure TTimerConfigurePanel.SetCanRestOfGame(AValue: boolean);
begin
  if FCanRestOfGame = AValue then
    Exit;
  FCanRestOfGame := AValue;
  if not AValue then
    SetInfiniteTime(False);
  SetRestOfGame(FRestOfGame);
  UpdateButtons;
end;

procedure TTimerConfigurePanel.SetInfiniteTime(AValue: boolean);
begin
  if AValue and ((not FCanInfiniteTime) or (not FCanRestOfGame)) then
    AValue := False;
  if FInfiniteTime = AValue then
    Exit;
  if AValue then
    SetRestOfGame(True);
  FInfiniteTime := AValue;
  TimeLabelChanged;
  DoUpdate;
  UpdateButtons;
end;

procedure TTimerConfigurePanel.SetRestOfGame(AValue: boolean);
begin
  if AValue and (not FCanRestOfGame) then
    AValue := False;
  if (not AValue) and (FInfiniteTime) then
    AValue := True;
  if FRestOfGame = AValue then
    Exit;
  FRestOfGame := AValue;
  MovesLabelChanged;
  DoUpdate;
end;

procedure TTimerConfigurePanel.SetTimeControl(AValue: RTimeControl);
begin
  SetInfiniteTime(AValue.StartTime = InfVal);
  if AValue.StartTime <> InfVal then
  begin
    SecondsSpin.Value := ClockValueToSecondsInt(AValue.StartTime);
    IncrementSpin.Value := ClockValueToSecondsInt(AValue.AddTime);
  end;
  SetRestOfGame(AValue.MoveCount <= 0);
  if not FRestOfGame then
    MovesSpin.Value := AValue.MoveCount;
end;

procedure TTimerConfigurePanel.MovesLabelChanged;
// Called when MovesLabel state was changed.
begin
  DisableAutoSizing;
  with MovesLabel do
    Caption := SMovesLabelVals[FRestOfGame];
  MovesSpin.Visible := not FRestOfGame;
  EnableAutoSizing;
end;

procedure TTimerConfigurePanel.TimeLabelChanged;
// Called when TimeLabel state was changed.
begin
  DisableAutoSizing;
  with TimeLabel do
    Caption := STimeLabelVals[FInfiniteTime];
  SecondsSpin.Visible := not FInfiniteTime;
  RightSecondsPanel.Visible := not FInfiniteTime;
  EnableAutoSizing;
end;

procedure TTimerConfigurePanel.DoUpdate;
// Calls the OnUpdate event.
begin
  if Assigned(FOnUpdate) then
    FOnUpdate(Self);
end;

procedure TTimerConfigurePanel.UpdateButtons;
// Updates the hidden buttons' Enabled property.
begin
  TimePanelBtn.Enabled := FCanInfiniteTime and FCanRestOfGame;
  MovesPanelBtn.Enabled := FCanRestOfGame and (not FInfiniteTime);
  UpdateFocus;
end;

procedure TTimerConfigurePanel.UpdateFocus;
// Updates the colors of the label according to buttons' focus.
begin
  if not MovesPanelBtn.Enabled then
  begin
    MovesLabel.Font.Style := [];
    MovesLabel.Font.Color := clDefault;
  end
  else
  begin
    MovesLabel.Font.Style := [fsUnderline];
    if MovesPanelBtn.Focused then
      MovesLabel.Font.Color := clNavy
    else
      MovesLabel.Font.Color := clBlue;
  end;
  if not TimePanelBtn.Enabled then
  begin
    TimeLabel.Font.Style := [];
    TimeLabel.Font.Color := clDefault;
  end
  else
  begin
    TimeLabel.Font.Style := [fsUnderline];
    if TimePanelBtn.Focused then
      TimeLabel.Font.Color := clNavy
    else
      TimeLabel.Font.Color := clBlue;
  end;
end;

constructor TTimerConfigurePanel.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FRestOfGame := False;
  FInfiniteTime := False;
  FCanInfiniteTime := True;
  FCanRestOfGame := True;
end;

end.
