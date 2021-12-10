{
  This file is part of Chess 256.

  Copyright © 2016, 2018, 2019 Alexander Kernozhitsky <sh200105@mail.ru>

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
    This file contains a visual component for position analysis.

  This unit is ALPHA. It may be improved in beta version (e. g. using a special
  component for showing the analysis instead of ListBox & FlowPanel on the form).
}

{
  TODO : We should deal somehow with the Analysis and decide if we should restart it.
  May be not to deal with this and make another way to do it (e. g. comparing the move chains)
}
unit AnalysisForms;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  SysUtils, Graphics, Dialogs, ExtCtrls, StdCtrls, ActnList, ChessEngines,
  NotationForms, MoveChains, ChessTime, MoveConverters, EngineScores,
  ApplicationForms, ChessRules, Math, EngineAboutBox, EngineConfigurers,
  ChessGUIUtils, EngineStrings;

resourcestring
  SAnalysisCaptionEmpty = 'Analysis';
  SAnalysisCaption = 'Analysis [%s]';
  SAnalysisWindowName = 'Analysis';
  SEnglineTerminated = 'Engine "%s" suddenly died.';

const
  MaxItemCount = 128;

type

  { TAnalysisForm }

  TAnalysisForm = class(TApplicationForm)
    EngineSelectAction: TAction;
    EngineSettingsAction: TAction;
    EngineAboutAction: TAction;
    AnalysisStopAction: TAction;
    AnalysisAction: TAction;
    ActionList: TActionList;
    FlowPanel: TFlowPanel;
    DepthLabel: TLabel;
    TimeLabel: TLabel;
    NodesLabel: TLabel;
    SpeedLabel: TLabel;
    CurMoveLabel: TLabel;
    ScoreLabel: TLabel;
    ListBox: TListBox;
    OpenDialog: TOpenDialog;
    IndicatorPanel: TPanel;
    DepthPanel: TPanel;
    TimePanel: TPanel;
    NodesPanel: TPanel;
    SpeedPanel: TPanel;
    CurMovePanel: TPanel;
    ScorePanel: TPanel;
    EngineHandle: TTimer;
    procedure AnalysisActionExecute(Sender: TObject);
    procedure AnalysisActionUpdate(Sender: TObject);
    procedure AnalysisStopActionExecute(Sender: TObject);
    procedure AnalysisStopActionUpdate(Sender: TObject);
    procedure EngineAboutActionExecute(Sender: TObject);
    procedure EngineAboutActionUpdate(Sender: TObject);
    procedure EngineSelectActionExecute(Sender: TObject);
    procedure EngineSettingsActionExecute(Sender: TObject);
    procedure EngineSettingsActionUpdate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBoxDblClick(Sender: TObject);
    procedure EngineHandleTimer(Sender: TObject);
  private
    FUpdating: integer;
    FWasAnalysis: boolean;
    FEngine: TAbstractChessEngine;
    // Event handlers
    procedure StateChange(Sender: TObject);
    procedure AnalysisEngineHandler(Sender: TObject; AMessage: TAnalysisMessage);
    procedure AnalysisStart(Sender: TObject);
    procedure AnalysisStop(Sender: TObject; const AResult: RAnalysisResult);
    procedure AnalysisTerminate(Sender: TObject);
    procedure ConfigurerUpdateOptions(Sender: TObject; var ApplyOptions: boolean);
    procedure NotatBoardUpdate(Sender: TObject);
    // Other methods
    procedure ClearList;
    procedure EngineNotResponding;
    procedure UpdateAll;
    procedure RecalcListBoxWidth;
  public
    // Methods
    procedure CreateEngine(const FileName: string);
    procedure StartEngine;
    procedure StopEngine;
    procedure ReloadEngine;
    procedure DestroyEngine;
    procedure BeginUpdate;
    procedure EndUpdate;
  end;

var
  AnalysisForm: TAnalysisForm;

implementation

{$R *.lfm}

{ TAnalysisForm }

procedure TAnalysisForm.AnalysisActionExecute(Sender: TObject);
begin
  ShowWithContainer;
  StartEngine;
end;

procedure TAnalysisForm.AnalysisActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled :=
    (FEngine <> nil) and (not FEngine.State.Active) and
    (not FEngine.Terminated) and (NotationForm.ChessNotation.CanAddMove);
end;

procedure TAnalysisForm.AnalysisStopActionExecute(Sender: TObject);
begin
  StopEngine;
end;

procedure TAnalysisForm.AnalysisStopActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := (FEngine <> nil) and FEngine.State.Active;
end;

procedure TAnalysisForm.EngineAboutActionExecute(Sender: TObject);
begin
  if FEngine = nil then
    Exit;
  ShowAboutEngine(FEngine);
end;

procedure TAnalysisForm.EngineAboutActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := FEngine <> nil;
end;

procedure TAnalysisForm.EngineSelectActionExecute(Sender: TObject);
var
  WasAnalysis: boolean;
begin
  // remember last engine state
  if FEngine = nil then
    WasAnalysis := False
  else
    WasAnalysis := FEngine.State.Active;
  // execute the open dialog
  if not OpenDialog.Execute then
    Exit;
  // create new engine
  CreateEngine(OpenDialog.FileName);
  // restore the state
  if WasAnalysis and (FEngine <> nil) then
    StartEngine;
end;

procedure TAnalysisForm.EngineSettingsActionExecute(Sender: TObject);
begin
  if FEngine = nil then
    Exit;
  // save the state
  FWasAnalysis := False;
  // execute the dialog
  if not ExecuteConfigurer(FEngine, @ConfigurerUpdateOptions) then
    Exit;
  // wait the engine to apply the settings
  if FEngine = nil then
    Exit;
  if not FEngine.WaitForEngine then
  begin
    EngineNotResponding;
    Exit;
  end;
  // restore the state
  if FWasAnalysis then
    StartEngine;
end;

procedure TAnalysisForm.EngineSettingsActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := CanExecuteConfigurer(FEngine);
end;

procedure TAnalysisForm.FormCreate(Sender: TObject);
begin
  NotationForm.ChessNotation.OnBoardUpdate := @NotatBoardUpdate;
  IndicatorPanel.Font.Name := DefaultChessFont;
  IndicatorPanel.Font.Size := DefaultChessFontSize;
  ScoreLabel.Font.Style := [fsBold];
  ListBox.Font.Name := DefaultChessFont;
  ListBox.Font.Size := DefaultChessFontSize;
  OpenDialog.Filter := Format(SEngineFilter, [EngineFilter]);
  OpenDialog.DefaultExt := EngineDefExt;
  CreateEngine(EngineName);
end;

procedure TAnalysisForm.FormDestroy(Sender: TObject);
begin
  ClearList;
  DestroyEngine;
end;

procedure TAnalysisForm.FormHide(Sender: TObject);
begin
  StopEngine;
end;

procedure TAnalysisForm.FormShow(Sender: TObject);
begin
  UpdateAll;
end;

procedure TAnalysisForm.ListBoxDblClick(Sender: TObject);
begin
  with ListBox do
  begin
    if ItemIndex < 0 then
      Exit;
    if Items.Objects[ItemIndex] = nil then
      Exit;
    if Items.Objects[ItemIndex] is TMoveChain then
      with NotationForm.ChessNotation do
        AddMoveChain(Items.Objects[ItemIndex] as TMoveChain);
  end;
end;

procedure TAnalysisForm.EngineHandleTimer(Sender: TObject);
begin
  if FEngine = nil then
    Exit;
  UpdateAll;
  // patch for GTK+ widgetset under Windows; GTK+ controls lock
  // TAsyncProcess.OnReadData event by some reason. So, we read from the pipe
  // in the timer.
  BeginUpdate;
  FEngine.ProcessMessages;
  EndUpdate;
end;

procedure TAnalysisForm.StateChange(Sender: TObject);
begin
  if FEngine = nil then
    Exit;
  UpdateAll;
end;

procedure TAnalysisForm.AnalysisEngineHandler(Sender: TObject;
  AMessage: TAnalysisMessage);
var
  AString: string;
  AObject: TObject;

  procedure ProcessEngineString(AMessage: TEngineString);
  // Processes TEngineString message.
  begin
    AString := '::' + AMessage.Value;
    AObject := nil;
  end;

  procedure ProcessAnalysisLine(AMessage: TAnalysisLine);
  // Processes TAnalysisLine message.
  var
    ScoreStr, ChainStr, TimeStr: string;
    Converter: TNotationMoveConverter;
  begin
    // convert move chain
    Converter := TNotationMoveConverter.Create;
    ChainStr := AMessage.MoveChain.ConvertToString(Converter, ' ');
    FreeAndNil(Converter);
    // convert score
    ScoreStr := PositionScoreToString(AMessage.Score);
    // convert time
    TimeStr := ClockValueToString(AMessage.Time);
    // assign values
    AString := Format('d = %d: [%s] %s (%s)', [FEngine.State.Depth,
      ScoreStr, ChainStr, TimeStr]);
    AObject := TMoveChain.Create;
    (AObject as TMoveChain).Assign(AMessage.MoveChain);
  end;

begin
  if FEngine = nil then
    Exit;
  // init
  AString := '';
  AObject := nil;
  // process messages
  if AMessage is TEngineString then
    ProcessEngineString(AMessage as TEngineString);
  if AMessage is TAnalysisLine then
    ProcessAnalysisLine(AMessage as TAnalysisLine);
  if AString <> '' then
  begin
    ListBox.Items.InsertObject(0, AString, AObject);
    // we cannot keep to many items in the list box (due to lags)...
    if ListBox.Items.Count = MaxItemCount then
    begin
      ListBox.Items.Objects[ListBox.Items.Count - 1].Free;
      ListBox.Items.Delete(ListBox.Items.Count - 1);
    end;
  end;
  ListBox.TopIndex := 0;
  RecalcListBoxWidth;
end;

procedure TAnalysisForm.AnalysisStart(Sender: TObject);
begin
  UpdateAll;
end;

{$HINTS OFF}
procedure TAnalysisForm.AnalysisStop(Sender: TObject; const AResult: RAnalysisResult);
begin
  UpdateAll;
end;

{$HINTS ON}

procedure TAnalysisForm.AnalysisTerminate(Sender: TObject);
begin
  MessageDlg(SAnalysisWindowName, Format(SEnglineTerminated, [FEngine.Name]),
    mtError, [mbOK], 0);
end;

procedure TAnalysisForm.ConfigurerUpdateOptions(Sender: TObject;
  var ApplyOptions: boolean);
begin
  // before updating the options, we should stop the analysis
  FWasAnalysis := FEngine.State.Active;
  if FWasAnalysis then
    StopEngine;
  ApplyOptions := FEngine <> nil;
end;

procedure TAnalysisForm.NotatBoardUpdate(Sender: TObject);
begin
  UpdateAll;
  ClearList;
  ReloadEngine;
end;

procedure TAnalysisForm.ClearList;
// Clears the ListBox.
var
  I: integer;
begin
  for I := 0 to ListBox.Count - 1 do
  begin
    ListBox.Items.Objects[I].Free;
    ListBox.Items.Objects[I] := nil;
  end;
  ListBox.Clear;
  RecalcListBoxWidth;
end;

procedure TAnalysisForm.EngineNotResponding;
// Indicates that the engine is not responding.
begin
  DestroyEngine;
  MessageDlg(SEngineNotResponding, mtError, [mbOK], 0);
end;

procedure TAnalysisForm.UpdateAll;
// Updates all when something has changed.

  procedure UpdateMove;
  // Updates the move panel.
  var
    Board: TChessBoard;
    Converter: TNotationMoveConverter;
    S: string;
  begin
    Board := TChessBoard.Create(True);
    with FEngine.MoveChain do
      Board.RawBoard := Boards[Count - 1];
    // extracting move string
    Converter := TNotationMoveConverter.Create(Board.RawBoard);
    try
      if FEngine.State.CurMove.Kind = mkImpossible then
        S := ''
      else
        S := Converter.GetMoveString(FEngine.State.CurMove);
    except
      S := '';
    end;
    if S <> '' then
      S := S + ' ';
    // updating caption
    if FEngine.State.MoveNumber = 0 then
      CurMoveLabel.Caption := S
    else
      CurMoveLabel.Caption :=
        Format('%s(%d/%d)', [S, FEngine.State.MoveNumber, Board.MoveCount]);
    // deleting temp objects
    FreeAndNil(Converter);
    FreeAndNil(Board);
  end;

  procedure UpdateCaption;
  // Updates the form caption.
  var
    S: string;
  begin
    if FEngine = nil then
      S := ''
    else
      S := FEngine.Name;
    if S = '' then
      Caption := SAnalysisCaptionEmpty
    else
      Caption := Format(SAnalysisCaption, [S]);
  end;

  procedure UpdateStatePanel;
  // Updates the panels' visiblity.
  begin
    if FEngine = nil then
      IndicatorPanel.Visible := False
    else
      IndicatorPanel.Visible := FEngine.State.Active;
  end;

begin
  if FUpdating <> 0 then
    Exit;
  UpdateCaption;
  UpdateStatePanel;
  if FEngine = nil then
    Exit;
  // update depth panel
  if FEngine.State.Depth = 0 then
    DepthLabel.Caption := ''
  else
    DepthLabel.Caption := Format('d = %d', [FEngine.State.Depth]);
  // update time panel
  TimeLabel.Caption := ClockValueToString(FEngine.State.Time);
  // update nodes count panel
  if FEngine.State.Nodes = 0 then
    NodesLabel.Caption := ''
  else
    NodesLabel.Caption := Format('%d kN', [Round(FEngine.State.Nodes / 1000)]);
  // update speed panel
  if FEngine.State.NPS = 0 then
    SpeedLabel.Caption := ''
  else
    SpeedLabel.Caption := Format('%d kN/s', [Round(FEngine.State.NPS / 1000)]);
  // update score panel
  if FEngine.State.Score = DefaultPositionScore then
    ScoreLabel.Caption := ''
  else
  begin
    if FEngine.State.Score.Mate = DefaultMate then
      ScoreLabel.Font.Color := clDefault
    else
      ScoreLabel.Font.Color := clRed;
    ScoreLabel.Caption := PositionScoreToString(FEngine.State.Score);
  end;
  // update move panel
  UpdateMove;
  // repaint everything
  Refresh;
end;

procedure TAnalysisForm.RecalcListBoxWidth;
// Updates the list box width.
var
  I, MaxWidth: integer;
begin
  if FUpdating <> 0 then
    Exit;
  MaxWidth := 0;
  with ListBox.Items do
  begin
    ListBox.Canvas.Font.Assign(ListBox.Font);
    for I := 0 to Count - 1 do
      MaxWidth := Max(MaxWidth, ListBox.Canvas.TextWidth(Strings[I]));
    ListBox.ScrollWidth := MaxWidth + 2;
  end;
end;

procedure TAnalysisForm.CreateEngine(const FileName: string);
// Creates the engine from file.
begin
  // destroy old engine
  if FEngine <> nil then
    DestroyEngine;
  // then, create a new one
  try
    FEngine := TUCIChessEngine.Create(FileName);
    FEngine.OnAnalysisMessage := @AnalysisEngineHandler;
    FEngine.State.OnChange := @StateChange;
    FEngine.OnStart := @AnalysisStart;
    FEngine.OnStop := @AnalysisStop;
    FEngine.OnTerminate := @AnalysisTerminate;
    FEngine.Initialize;
  except
    on E: Exception do
    begin
      FreeAndNil(FEngine);
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
  UpdateAll;
end;

procedure TAnalysisForm.StartEngine;
// starts the analysis
var
  MoveChain: TMoveChain;
begin
  // check for possiblity
  if FEngine = nil then
    Exit;
  if FEngine.State.Active then
    Exit;
  if not NotationForm.ChessNotation.CanAddMove then
    Exit;
  if FEngine.Terminated then
    Exit;
  // clear list
  ClearList;
  // set current move chain to engine
  MoveChain := NotationForm.ChessNotation.GetMoveChain;
  FEngine.MoveChain.Assign(MoveChain);
  FreeAndNil(MoveChain);
  // let's go!
  FEngine.StartInfinite;
  Repaint;
end;

procedure TAnalysisForm.StopEngine;
// Stops the engine.
begin
  // check
  if FEngine = nil then
    Exit;
  if not FEngine.State.Active then
    Exit;
  // stop
  FEngine.Stop;
  // if cannot stop - say that it's not responding
  if not FEngine.WaitForStop then
    EngineNotResponding;
end;

procedure TAnalysisForm.ReloadEngine;
// Stops the engine and re-starts it (if it's active'.
begin
  // check
  if FEngine = nil then
    Exit;
  if not FEngine.State.Active then
    Exit;
  // stop engine
  FEngine.Stop;
  // if cannot stop - say that it's not responding
  // otherwise, restart
  if not FEngine.WaitForStop then
    EngineNotResponding
  else
    StartEngine;
end;

procedure TAnalysisForm.DestroyEngine;
// Destroys the current engine.
begin
  if FEngine = nil then
    Exit;
  try
    FEngine.Uninitialize;
  finally
    FreeAndNil(FEngine);
  end;
  UpdateAll;
end;

procedure TAnalysisForm.BeginUpdate;
begin
  ListBox.Items.BeginUpdate;
  Inc(FUpdating);
end;

procedure TAnalysisForm.EndUpdate;
begin
  ListBox.Items.EndUpdate;
  Dec(FUpdating);
  if FUpdating < 0 then
    FUpdating := 0;
  UpdateAll;
  RecalcListBoxWidth;
end;

end.
