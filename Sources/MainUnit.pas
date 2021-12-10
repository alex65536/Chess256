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
    This file contains the main form of Chess 256.
}
unit MainUnit;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Forms, Controls, ExtCtrls, ChessBoards, PromoteDialog, PositionEditors, About,
  ApplicationForms, Dialogs, SysUtils, NotationForms, DebugConsole, ClockForms,
  ChessRules, AnalysisForms, TextureContainers, ChessGame, GameStartDialogs,
  ChessStrings, ActnList, Menus, ComCtrls, BoardForms, MoveVariantForms,
  PseudoDockedForms, Classes;

resourcestring
  SResignConfirmation = 'Do you really want to resign?';

type

  { TMainForm }

  TMainForm = class(TApplicationForm)
    AboutAction: TAction;
    ExitAction: TAction;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem28: TMenuItem;
    MenuItem29: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem30: TMenuItem;
    MenuItem31: TMenuItem;
    MenuItem32: TMenuItem;
    MenuItem33: TMenuItem;
    MenuItem34: TMenuItem;
    MenuItem35: TMenuItem;
    MenuItem36: TMenuItem;
    MenuItem37: TMenuItem;
    MenuItem38: TMenuItem;
    MenuItem39: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem40: TMenuItem;
    MenuItem41: TMenuItem;
    MenuItem42: TMenuItem;
    MenuItem43: TMenuItem;
    MenuItem44: TMenuItem;
    MenuItem45: TMenuItem;
    MenuItem46: TMenuItem;
    MenuItem47: TMenuItem;
    MenuItem48: TMenuItem;
    Panel4: TPanel;
    Splitter3: TSplitter;
    ToolButton28: TToolButton;
    ToolButton29: TToolButton;
    ToolButton30: TToolButton;
    WindowMenu: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    ChangeLookAction: TAction;
    FontSelectAction: TAction;
    NewGameAction: TAction;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel5: TPanel;
    GlobalPanel: TPanel;
    ResignAction: TAction;
    OfferDrawAction: TAction;
    ActionList: TActionList;
    FontDialog: TFontDialog;
    EngineHandleTimer: TTimer;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter4: TSplitter;
    ToolBar: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    ToolButton16: TToolButton;
    ToolButton17: TToolButton;
    ToolButton18: TToolButton;
    ToolButton19: TToolButton;
    ToolButton2: TToolButton;
    ToolButton20: TToolButton;
    ToolButton21: TToolButton;
    ToolButton22: TToolButton;
    ToolButton23: TToolButton;
    ToolButton24: TToolButton;
    ToolButton25: TToolButton;
    ToolButton26: TToolButton;
    ToolButton27: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    procedure AboutActionExecute(Sender: TObject);
    procedure ChangeLookActionExecute(Sender: TObject);
    procedure ExitActionExecute(Sender: TObject);
    procedure FontSelectActionExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure NewGameActionExecute(Sender: TObject);
    procedure OfferDrawActionExecute(Sender: TObject);
    procedure OfferDrawActionUpdate(Sender: TObject);
    procedure ResignActionExecute(Sender: TObject);
    procedure ResignActionUpdate(Sender: TObject);
    procedure EngineHandleTimerTimer(Sender: TObject);
    procedure GameFinished(Sender: TObject);
    procedure GameChanger(Sender: TObject);
    procedure WindowShowHideMenuItemClick(Sender: TObject);
    procedure ChildFormCaptionChanged(Sender: TObject);
    procedure ChildFormShow(Sender: TObject);
    procedure ChildFormHide(Sender: TObject);
  private
    Texture: TTextureContainer;
    FGame: TChessGame;
  protected
    procedure AddWindow(AForm: TApplicationForm; APanel: TCustomPanel;
      ASplitter: TSplitter; CanHide: boolean);
  public
    procedure CreateNewGame;
  end;

var
  MainForm: TMainForm;

implementation

{$IfDef MainMenuImages}
uses
  GlyphKeepers;

{$EndIf}

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FGame);
  FreeAndNil(Texture);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  //Constraints.MinHeight := Height - ClientHeight + ToolBar.Height;
  // (works bad under GTK+)
end;

procedure TMainForm.AboutActionExecute(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

procedure TMainForm.ChangeLookActionExecute(Sender: TObject);
var
  WasTexture: TTextureContainer;
begin
  WasTexture := Texture;

  if WasTexture is TFontTextureContainer then
  begin
    Texture := TResourceTextureContainer.Create;
    (Texture as TResourceTextureContainer).Font :=
      (WasTexture as TFontTextureContainer).Font;
  end
  else
  begin
    Texture := TFontTextureContainer.Create;
    (Texture as TFontTextureContainer).Font :=
      (WasTexture as TResourceTextureContainer).Font;
  end;

  PositionEditor.TextureContainer := Texture;
  BoardForm.TextureContainer := Texture;
  PromoteDlg.TextureContainer := Texture;

  FreeAndNil(WasTexture);
end;

procedure TMainForm.ExitActionExecute(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.FontSelectActionExecute(Sender: TObject);
begin
  if Texture is TFontTextureContainer then
    FontDialog.Font.Assign((Texture as TFontTextureContainer).Font)
  else
    FontDialog.Font.Assign((Texture as TResourceTextureContainer).Font);
  if not FontDialog.Execute then
    Exit;
  if Texture is TFontTextureContainer then
    (Texture as TFontTextureContainer).Font := FontDialog.Font
  else
    (Texture as TResourceTextureContainer).Font := FontDialog.Font;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  {$IFDEF MainMenuImages}
  MainMenu.Images := GlyphKeeper.ImageList;
  {$ENDIF}

  FGame := nil;

  Texture := TResourceTextureContainer.Create;

  PositionEditor.TextureContainer := Texture;
  BoardForm.TextureContainer := Texture;
  PromoteDlg.TextureContainer := Texture;

  GlobalPanel.DoubleBuffered := True;

  MoveVariantForm.VisualBoard := BoardForm.VisualBoard;
  NotationForm.ChessBoard := BoardForm.Board;

  AddWindow(BoardForm, Panel3, nil, False);
  AddWindow(NotationForm, Panel1, Splitter1, False);
  AddWindow(ClockForm, Panel5, Splitter4, False);
  AddWindow(MoveVariantForm, Panel2, Splitter2, True);
  AddWindow(AnalysisForm, Panel4, Splitter3, True);
  MoveVariantForm.Container.Shown := False;
  ClockForm.Container.Shown := False;

  ShowDebugConsole;

  CreateNewGame;
end;

procedure TMainForm.NewGameActionExecute(Sender: TObject);
begin
  if not NewGameDialog.Execute then
    Exit;
  CreateNewGame;
end;

procedure TMainForm.OfferDrawActionExecute(Sender: TObject);
begin
  if not Assigned(FGame) then
    Exit;
  if not FGame.CanDrawByAgreement then
    Exit;
  if MessageDlg(GetDrawOffer(FGame.CurSide), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    FGame.DrawByAgreement;
end;

procedure TMainForm.OfferDrawActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := (FGame <> nil) and FGame.CanDrawByAgreement;
end;

procedure TMainForm.ResignActionExecute(Sender: TObject);
begin
  if not Assigned(FGame) then
    Exit;
  if not FGame.CanResign then
    Exit;
  if MessageDlg(SResignConfirmation, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  FGame.Resign;
end;

procedure TMainForm.ResignActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := (FGame <> nil) and FGame.CanResign;
end;

procedure TMainForm.EngineHandleTimerTimer(Sender: TObject);
begin
  // patch for GTK+ widgetset under Windows; GTK+ controls lock
  // TAsyncProcess.OnReadData event by some reason. So, we read from the pipe
  // in the timer.
  if not Assigned(FGame) then
    Exit;
  if not FGame.Active then
    Exit;
  if FGame.WhitePlayer.Engine <> nil then
    FGame.WhitePlayer.Engine.ProcessMessages;
  if FGame.BlackPlayer.Engine <> nil then
    FGame.BlackPlayer.Engine.ProcessMessages;
end;

procedure TMainForm.GameFinished(Sender: TObject);
var
  S, S2: string;
begin
  with NotationForm.ChessNotation do
  begin
    S2 := GameResultToString(GameResult);
    if S2 <> '' then
    begin
      GoToEnd;
      InsertComment(S2);
    end;
    S := GameWinnerToString(GameResult.Winner);
    if S <> '' then
      MessageDlg(S, mtInformation, [mbOK], 0);
  end;
end;

procedure TMainForm.GameChanger(Sender: TObject);
begin
  MoveVariantForm.ShowMoves;
end;

procedure TMainForm.WindowShowHideMenuItemClick(Sender: TObject);
begin
  with Sender as TMenuItem do
    TPseudoDockContainer(Tag).Shown := Checked;
end;

procedure TMainForm.ChildFormCaptionChanged(Sender: TObject);
begin
  with Sender as TPseudoDockContainer do
    TMenuItem(Tag).Caption := Form.Caption;
end;

procedure TMainForm.ChildFormShow(Sender: TObject);
begin
  with Sender as TPseudoDockContainer do
    TMenuItem(Tag).Checked := Shown;
end;

procedure TMainForm.ChildFormHide(Sender: TObject);
begin
  with Sender as TPseudoDockContainer do
    TMenuItem(Tag).Checked := Shown;
end;

procedure TMainForm.AddWindow(AForm: TApplicationForm; APanel: TCustomPanel;
  ASplitter: TSplitter; CanHide: boolean);
var
  AItem: TMenuItem;
  AContainer: TPseudoDockContainer;
begin
  APanel.ParentColor := True;
  AContainer := DockFormToPanel(AForm, GlobalPanel, APanel, ASplitter, CanHide);
  AItem := TMenuItem.Create(Self);
  AContainer.Tag := PtrInt(AItem);
  AContainer.OnCaptionChange := @ChildFormCaptionChanged;
  AContainer.OnShowForm := @ChildFormShow;
  AContainer.OnHideForm := @ChildFormHide;
  AItem.Tag := PtrInt(AContainer);
  AItem.OnClick := @WindowShowHideMenuItemClick;
  AItem.Caption := AForm.Caption;
  AItem.Checked := AContainer.Shown;
  AItem.Enabled := CanHide;
  AItem.AutoCheck := True;
  WindowMenu.Add(AItem);
end;

procedure TMainForm.CreateNewGame;
begin
  FreeAndNil(FGame);
  FGame := TChessGame.Create;
  FGame.ChessNotation := NotationForm.ChessNotation;
  FGame.ChessTimer := ClockForm.Clock;
  FGame.OnChange := @GameChanger;
  FGame.OnFinishGame := @GameFinished;
  NewGameDialog.ApplyToGame(FGame);
  MoveVariantForm.ShowMoves;
  ClockForm.Container.Shown := FGame.Active;
  NotationForm.ChessNotation.ClearStates;
end;

end.
