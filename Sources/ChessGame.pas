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
    This unit contains a core class implementing a chess game.
}

// TODO : Implement pondering !!!
// TODO : Make adding/removing the event handlers.
unit ChessGame;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Classes, SysUtils, ChessNotation, ChessTime, ChessEngines, ChessRules,
  NotationLists, MoveChains, ChessUtils, ChessStrings, PersistentNotation;

resourcestring
  SEngineNotResponding = 'Engine "%s" that plays for %s is not responding.';
  SEngineWrongMove = 'Engine "%s" that plays for %s returned an incorrect move.';
  SStartGameRequirements =
    'To start a game, you must set ChessNotation and ChessTimer props.';
  SCannotChange = 'Cannot change %s while the game is active.';

type
  EChessGame = class(Exception);

  { TChessPlayer }

  TChessPlayer = class
  private
    FEngine: TAbstractChessEngine;
    FName: string;
    FOnEngineStop: TAnalysisStopEvent;
    procedure EngineStopper(Sender: TObject; const AResult: RAnalysisResult);
    procedure SetEngine(AValue: TAbstractChessEngine);
    procedure DestroyEngine;
  public
    property OnEngineStop: TAnalysisStopEvent read FOnEngineStop write FOnEngineStop;
    property Name: string read FName write FName;
    property Engine: TAbstractChessEngine read FEngine write SetEngine;
    // = nil if it's a player.
    destructor Destroy; override;
  end;

  { TChessGame }

  TChessGame = class(TChessObject)
  private
    FLastAction: TNotationAction;
    FEngineMoving: boolean;
    FChessNotation: TChessNotation;
    FChessTimer: TChessTimer;
    FEventLockCount: integer;
    FOnFinishGame: TNotifyEvent;
    FPlayers: array [TPieceColor] of TChessPlayer;
    FActive: boolean;
    // Setters
    procedure SetActive(AValue: boolean);
    procedure SetChessNotation(AValue: TChessNotation);
    procedure SetChessTimer(AValue: TChessTimer);
    // Event handlers
    procedure NotationActionAccept(Sender: TObject; AAction: TNotationAction;
      var Accept: boolean);
    procedure NotationBeginAction(Sender: TObject; AAction: TNotationAction);
    procedure NotationEndAction(Sender: TObject; AAction: TNotationAction);
    procedure NotationChangeTail(Sender: TObject);
    procedure NotationChangeGameResult(Sender: TObject);
    procedure TimerTimeForfeit(Sender: TObject; Side: TPieceColor);
    procedure EngineStop(Sender: TObject; const AResult: RAnalysisResult);
  protected
    // Utiltities
    procedure StopEngines(WaitForStop: boolean);
    procedure StartEngines;
    procedure UpdateClock;
    procedure RaiseEngineException(Color: TPieceColor; const AFormat: string);
    procedure CommonMakeMove(const Move: RChessMove);
    // Lock / unlock
    function EventsLocked: boolean;
    procedure LockEvents;
    procedure UnlockEvents;
  public
    // Properties
    // WARNING! Do not change WhitePlayer, BlackPlayer, ChessNotation
    // or ChessTimer when Active = True.
    property Active: boolean read FActive write SetActive;
    property ChessNotation: TChessNotation read FChessNotation write SetChessNotation;
    property ChessTimer: TChessTimer read FChessTimer write SetChessTimer;
    property WhitePlayer: TChessPlayer read FPlayers[pcWhite];
    property BlackPlayer: TChessPlayer read FPlayers[pcBlack];
    property OnFinishGame: TNotifyEvent read FOnFinishGame write FOnFinishGame;
    // Functions
    function CurSide: TPieceColor;
    function EngineThinks: boolean;
    // Actions
    procedure StartGame;
    procedure FinishGame(const Res: RGameResult);
    function CanResign: boolean;
    procedure Resign;
    function CanDrawByAgreement: boolean;
    procedure DrawByAgreement;
    function CanMakeMove: boolean;
    procedure MakeMove(const AMove: RChessMove);
    // Constructors / Destruction
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TChessPlayer }

procedure TChessPlayer.EngineStopper(Sender: TObject; const AResult: RAnalysisResult);
begin
  if Assigned(FOnEngineStop) then
    FOnEngineStop(Self, AResult);
end;

procedure TChessPlayer.SetEngine(AValue: TAbstractChessEngine);
begin
  if FEngine = AValue then
    Exit;
  DestroyEngine;
  FEngine := AValue;
  if Assigned(FEngine) then
    FEngine.OnStop := @EngineStopper;
end;

procedure TChessPlayer.DestroyEngine;
// Destroys the engine.
begin
  if FEngine <> nil then
    FEngine.Uninitialize;
  FreeAndNil(FEngine);
end;

destructor TChessPlayer.Destroy;
begin
  DestroyEngine;
  inherited Destroy;
end;

{ TChessGame }

procedure TChessGame.SetActive(AValue: boolean);
begin
  if FActive = AValue then
    Exit;
  if AValue then
    StartGame
  else
    FinishGame(MakeGameResult(geNone, gwNone));
end;

procedure TChessGame.SetChessNotation(AValue: TChessNotation);
begin
  // check
  if FChessNotation = AValue then
    Exit;
  if FActive then
    raise EChessGame.CreateFmt(SCannotChange, ['ChessNotation']);
  // apply new notation
  FChessNotation := AValue;
  if not Assigned(FChessNotation) then
    Exit;
  FChessNotation.OnBeginAction := @NotationBeginAction;
  FChessNotation.OnEndAction := @NotationEndAction;
  FChessNotation.OnActionAccept := @NotationActionAccept;
  FChessNotation.OnChangeGameResult := @NotationChangeGameResult;
  FChessNotation.OnChangeTail := @NotationChangeTail;
end;

procedure TChessGame.SetChessTimer(AValue: TChessTimer);
begin
  // check
  if FChessTimer = AValue then
    Exit;
  if FActive then
    raise EChessGame.CreateFmt(SCannotChange, ['ChessTimer']);
  // apply new timer
  FChessTimer := AValue;
  if not Assigned(FChessTimer) then
    Exit;
  FChessTimer.OnTimeForfeit := @TimerTimeForfeit;
end;

procedure TChessGame.NotationActionAccept(Sender: TObject;
  AAction: TNotationAction; var Accept: boolean);
begin
  Accept := True;
  if not FActive then
    Exit;
  case AAction of
    naClearCustom: Accept := False;
    naAddMove: Accept := CanMakeMove;
    naAddMoveChain: Accept := False;
    naPaste: Accept := False;
  end;
end;

procedure TChessGame.NotationBeginAction(Sender: TObject; AAction: TNotationAction);
begin
  FLastAction := AAction;
end;

procedure TChessGame.NotationEndAction(Sender: TObject; AAction: TNotationAction);
begin
  if not FActive then
    Exit;
  if AAction = naAddMove then
  begin
    // changing time for naAddMove
    FChessTimer.FlipClock;
    FChessNotation.List.LastMoveNode.ClockMark := FChessTimer.Clock;
    try
      StopEngines(True);
    finally
      StartEngines;
      DoChange;
    end;
  end;
end;

procedure TChessGame.NotationChangeTail(Sender: TObject);
begin
  if not FActive then
    Exit;
  if FLastAction = naAddMove then
    Exit; // changing time for naAddMove is specific
  try
    StopEngines(True);
  finally
    UpdateClock;
    StartEngines;
    DoChange;
  end;
end;

procedure TChessGame.NotationChangeGameResult(Sender: TObject);
begin
  if not FActive then
    Exit;
  if FChessNotation.GameResult.Winner <> gwNone then
    FinishGame(FChessNotation.GameResult);
end;

procedure TChessGame.TimerTimeForfeit(Sender: TObject; Side: TPieceColor);
begin
  if not FActive then
    Exit;
  if Side = pcWhite then
    FinishGame(MakeGameResult(geTimeForfeit, gwBlack))
  else
    FinishGame(MakeGameResult(geTimeForfeit, gwWhite));
end;

procedure TChessGame.EngineStop(Sender: TObject; const AResult: RAnalysisResult);
begin
  if EventsLocked then
    Exit;
  if not FActive then
    Exit;
  try
    FEngineMoving := True;
    try
      CommonMakeMove(AResult.BestMove);
    except
      RaiseEngineException(CurSide, SEngineWrongMove);
    end;
  finally
    FEngineMoving := False;
    DoChange;
  end;
end;

procedure TChessGame.StopEngines(WaitForStop: boolean);
// Stops all the engines.
var
  C: TPieceColor;
begin
  for C := Low(TPieceColor) to High(TPieceColor) do
    if (FPlayers[C].Engine <> nil) and (FPlayers[C].Engine.State.Active) then
    begin
      FPlayers[C].Engine.Stop;
      if not WaitForStop then
        Continue;
      // wait for engine stop.
      LockEvents;
      try
        if not FPlayers[C].Engine.WaitForStop then
          RaiseEngineException(C, SEngineNotResponding);
      finally
        UnlockEvents;
      end;
    end;
end;

procedure TChessGame.StartEngines;
// Starts nessesary engines.
var
  AChain: TMoveChain;
  ASide: TPieceColor;
begin
  ASide := CurSide;
  if FPlayers[ASide].Engine <> nil then
  begin
    // start analysis!
    with FChessNotation.List do
      AChain := GetMoveChain(Last);
    FPlayers[ASide].Engine.MoveChain.Assign(AChain);
    FPlayers[ASide].Engine.StartTime(FChessTimer);
    FreeAndNil(AChain);
  end;
end;

procedure TChessGame.UpdateClock;
// Updates ChessTimer.
var
  AMoveNode: TMoveNode;
begin
  AMoveNode := FChessNotation.List.LastMoveNode;
  if AMoveNode = nil then
    FChessTimer.Clock := FChessNotation.List.ClockMark
  else
    FChessTimer.Clock := AMoveNode.ClockMark;
end;

procedure TChessGame.RaiseEngineException(Color: TPieceColor; const AFormat: string);
// Finishes the game and raises an engine exception. The method is called when
// an engine has a error.
begin
  if Color = pcWhite then
    FinishGame(MakeGameResult(geEngineFault, gwBlack))
  else
    FinishGame(MakeGameResult(geEngineFault, gwWhite));
  raise EChessGame.CreateFmt(AFormat, [FPlayers[Color].Name, SSideNames[Color]]);
end;

procedure TChessGame.CommonMakeMove(const Move: RChessMove);
// Makes a move (without checking).
begin
  with FChessNotation do
  begin
    Iterator.SetValues(List, List.Last); // go to the last position
    AddMove(Move);
  end;
end;

function TChessGame.EventsLocked: boolean;
  // Returns True if not locked.
begin
  Result := FEventLockCount <> 0;
end;

procedure TChessGame.LockEvents;
// Increases lock count.
begin
  Inc(FEventLockCount);
end;

procedure TChessGame.UnlockEvents;
// Decreases lock count.
begin
  Dec(FEventLockCount);
  if FEventLockCount < 0 then
    FEventLockCount := 0;
end;

function TChessGame.CurSide: TPieceColor;
  // Returns current moving side.
begin
  Result := FChessNotation.List.CurBoard.MoveSide;
end;

function TChessGame.EngineThinks: boolean;
  // Returns if the engine is thinking.
begin
  if FEngineMoving then
    Exit(False); // let's allow our engine to move
  Result := FPlayers[CurSide].Engine <> nil;
end;

procedure TChessGame.StartGame;
// Starts the game.
begin
  // check
  if FActive then
    Exit;
  if (not Assigned(FChessNotation)) or (not Assigned(FChessTimer)) then
    raise EChessGame.Create(SStartGameRequirements);
  FActive := True;
  // set timer
  FChessTimer.InitialColor := CurSide;
  FChessTimer.Restart;
  FChessTimer.Paused := False;
  // set notation
  FChessNotation.Clear;
  FChessNotation.List.ClockMark := FChessTimer.Clock;
  if FChessNotation is TPersistentChessNotation then
    (FChessNotation as TPersistentChessNotation).ClearStates;
  // check if the game has finished right in this moment.
  if not FActive then
    Exit;
  // start it!
  StartEngines;
  DoChange;
end;

procedure TChessGame.FinishGame(const Res: RGameResult);
// Finishes the game.
begin
  if not FActive then
    Exit;
  FActive := False;
  try
    if not EventsLocked then
      StopEngines(True);
  finally
    FChessNotation.GameResult := Res;
    FChessTimer.Paused := True;
    if Assigned(FOnFinishGame) then
      FOnFinishGame(Self);
    if FChessNotation is TPersistentChessNotation then
      with FChessNotation as TPersistentChessNotation do
      begin
        ClearStates;
        IgnoreSaveActionsCount := IgnoreSaveActionsCount + 1;
      end;
    DoChange;
  end;
end;

function TChessGame.CanResign: boolean;
  // Checks if we can resign.
begin
  Result := FActive and (not EngineThinks);
end;

procedure TChessGame.Resign;
// Resign for player.
begin
  if not CanResign then
    Exit;
  if CurSide = pcWhite then
    FinishGame(MakeGameResult(geResign, gwBlack))
  else
    FinishGame(MakeGameResult(geResign, gwWhite));
end;

function TChessGame.CanDrawByAgreement: boolean;
  // Checks if we can offer draw.
begin
  if not FActive then
    Exit(False);
  Result := (FPlayers[pcWhite].Engine = nil) and (FPlayers[pcBlack].Engine = nil);
end;

procedure TChessGame.DrawByAgreement;
// Make draw by agreement.
begin
  if not CanDrawByAgreement then
    Exit;
  FinishGame(MakeGameResult(geByAgreement, gwDraw));
end;

function TChessGame.CanMakeMove: boolean;
  // Checks if we can make a move.
begin
  Result := False;
  if not FActive then
    Exit;
  // if in variation - we can't make a move
  if FChessNotation.Iterator.List <> FChessNotation.List then
    Exit;
  // if not last move - we can't make a move
  with FChessNotation, FChessNotation.List do
    Result := LastMoveNode(NextNode(Iterator.Node), mdForward) = nil;
  // if the engine is thinking - we can't make a move
  Result := Result and not EngineThinks;
end;

procedure TChessGame.MakeMove(const AMove: RChessMove);
// Makes a move.
begin
  if not CanMakeMove then
    Exit;
  CommonMakeMove(AMove);
end;

constructor TChessGame.Create;
begin
  FPlayers[pcWhite] := TChessPlayer.Create;
  FPlayers[pcWhite].OnEngineStop := @EngineStop;
  FPlayers[pcBlack] := TChessPlayer.Create;
  FPlayers[pcBlack].OnEngineStop := @EngineStop;
  FEngineMoving := False;
  FEventLockCount := 0;
  FLastAction := naNone;
end;

destructor TChessGame.Destroy;
begin
  FreeAndNil(FPlayers[pcWhite]);
  FreeAndNil(FPlayers[pcBlack]);
  inherited Destroy;
end;

end.
