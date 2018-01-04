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
    Main Chess 256 project file. This was automatically created by Lazarus.
}
program Chess256;

{$I CompilerDirectives.inc}

uses
  SysUtils,
  Interfaces, // this includes the LCL widgetset
  ChessGUIUtils,
  Forms,
  CmdBox,
  DebugConsole,
  MainUnit,
  ChessRules,
  PromoteDialog,
  MoveConverters,
  PositionEditors,
  About,
  ApplicationForms,
  ChessTime,
  ChessClock,
  NotationUtils,
  NotationTags,
  NotationLists,
  ChessUtils,
  PGNUtils,
  NotationForms,
  VisualNotation,
  NotationMessaging,
  ChessNotation,
  TextViewImpl,
  NAGSelector,
  NAGUtils,
  CommentEditors,
  BoardHashes,
  EngineProcesses,
  ChessEngines,
  UCICommands,
  MoveChains,
  EngineScores,
  EngineAboutBox,
  ChessBoards,
  EngineConfigurers,
  UCIEngineConfigurer,
  TextureContainers,
  ChessGame,
  GameStartDialogs,
  TimerConfigurers,
  TimerConfigurePanels,
  TimerConfigurePairs,
  TimerConfigureForms,
  PlayerSelectors,
  ChessStrings,
  Utilities,
  GlyphKeepers,
  ClockForms,
  BoardForms,
  MoveVariantForms,
  EngineStrings,
  AnalysisForms,
  PseudoDockedForms,
  ImbalanceFrame,
  ScaleDPI,
  PersistentNotation,
  LicenseInfo;

{$R *.res}

begin
  Application.Title := 'Chess 256';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TGlyphKeeper, GlyphKeeper);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TNotationForm, NotationForm);
  Application.CreateForm(TAnalysisForm, AnalysisForm);
  Application.CreateForm(TBoardForm, BoardForm);
  Application.CreateForm(TClockForm, ClockForm);
  Application.CreateForm(TMoveVariantForm, MoveVariantForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TConsole, Console);
  Application.CreateForm(TPromoteDlg, PromoteDlg);
  Application.CreateForm(TPositionEditor, PositionEditor);
  Application.CreateForm(TNAGSelect, NAGSelect);
  Application.CreateForm(TCommentEditor, CommentEditor);
  Application.CreateForm(TNewGameDialog, NewGameDialog);
  Application.CreateForm(TTimerConfigureForm, TimerConfigureForm);
  Application.CreateForm(TLicenseInfoFrom, LicenseInfoFrom);
  Application.Run;
end.
