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
    This file contains classes that implement chess engines. Currently, only UCI
    based engines are supported.
}

// TODO : Improve this unit and make all the chess engine features here.
// TODO : Maybe add WinBoard/XBoard engine support?

unit ChessEngines;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, FGL, ChessUtils, ChessRules, MoveChains, ChessTime,
  EngineProcesses, UCICommands, EngineScores;

resourcestring
  SUCICannotInit = 'Executable "%s" cannot be inited as UCI chess engine. ' +
    'Probably it''s not a UCI chess engine.';

const
  MaxWaitTime = 1000;
  EngineInitTime = 1000;
  EngineQuitTime = 1000;

type
  EChessEngine = class(Exception);

  RAnalysisResult = record
    BestMove: RChessMove;
    PonderMove: RChessMove;
  end;

  { TAnalysisState }

  TAnalysisState = class(TChessObject)
  private
    FCurMove: RChessMove;
    FMoveNumber: integer;
    FScore: RPositionScore;
    FStartTime: int64;
    FActive: boolean;
    FDepth: integer;
    FNodes: int64;
    FNPS: int64;
    // Getters / Setters
    function GetTime: TClockValue;
    procedure SetActive(AValue: boolean);
    procedure SetCurMove(AValue: RChessMove);
    procedure SetDepth(AValue: integer);
    procedure SetMoveNumber(AValue: integer);
    procedure SetNodes(AValue: int64);
    procedure SetNPS(AValue: int64);
    procedure SetScore(AValue: RPositionScore);
    // Other methods
    procedure Clear;
  public
    // Properties
    property Active: boolean read FActive write SetActive;
    property Depth: integer read FDepth write SetDepth;
    property Time: TClockValue read GetTime;
    property Nodes: int64 read FNodes write SetNodes;
    property NPS: int64 read FNPS write SetNPS;
    property Score: RPositionScore read FScore write SetScore;
    property MoveNumber: integer read FMoveNumber write SetMoveNumber;
    property CurMove: RChessMove read FCurMove write SetCurMove;
    // Methods
    procedure Changing;
    procedure Changed;
    constructor Create;
  end;

  TAnalysisMessage = class(TObject);

  { TEngineString }

  TEngineString = class(TAnalysisMessage)
  private
    FValue: string;
  public
    property Value: string read FValue;
    constructor Create(AValue: string);
  end;

  { TAnalysisLine }

  TAnalysisLine = class(TAnalysisMessage)
  protected
    FMoveChain: TMoveChain;
    FScore: RPositionScore;
    FTime: TClockValue;
  public
    property MoveChain: TMoveChain read FMoveChain;
    property Score: RPositionScore read FScore;
    property Time: TClockValue read FTime;
    constructor Create;
    destructor Destroy; override;
  end;

  TAnalysisMessageEvent = procedure(Sender: TObject;
    AMessage: TAnalysisMessage) of object;
  TAnalysisStopEvent = procedure(Sender: TObject;
    const AResult: RAnalysisResult) of object;

  { TAbstractChessEngine }

  TAbstractChessEngine = class
  private
    FStopping: boolean;
    FMoveChain: TMoveChain;
    FState: TAnalysisState;
    FOnAnalysisMessage: TAnalysisMessageEvent;
    FOnStart: TNotifyEvent;
    FOnStop: TAnalysisStopEvent;
    FOnTerminate: TNotifyEvent;
  protected
    // Analysis events
    procedure DoStart;
    procedure DoStop(const AResult: RAnalysisResult);
    procedure DoTerminate;
    procedure SendAnalysisMessage(AMessage: TAnalysisMessage);
    // Abstract getters (to get the engine info).
    function GetName: string; virtual; abstract;
    function GetAuthor: string; virtual; abstract;
    function GetFileName: string; virtual; abstract;
  public
    // Properties
    property Name: string read GetName;
    property Author: string read GetAuthor;
    property FileName: string read GetFileName;
    property State: TAnalysisState read FState;
    property MoveChain: TMoveChain read FMoveChain;
    // Events
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnStop: TAnalysisStopEvent read FOnStop write FOnStop;
    property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
    property OnAnalysisMessage: TAnalysisMessageEvent
      read FOnAnalysisMessage write FOnAnalysisMessage;
    // Methods
    procedure StartInfinite; virtual;
    procedure StartTime(Timer: TChessTimer); virtual;
    procedure Stop; virtual; // the engine won't stop before sending OnStop!
    function WaitForStop(Time: integer = MaxWaitTime): boolean; virtual;
    function WaitForEngine(Time: integer = MaxWaitTime): boolean; virtual;
    procedure ProcessMessages; virtual;
    // Creation / Deletion
    constructor Create;
    procedure Initialize; virtual;
    procedure Uninitialize; virtual;
    destructor Destroy; override;
  end;

  TChessEngineClass = class of TAbstractChessEngine;

  TEngineOptionList = specialize TFPGObjectList<TEngineOption>;

  { TUCIChessEngine }

  TUCIChessEngine = class(TAbstractChessEngine)
  private
    FOptions: TEngineOptionList;
    FProcess: TUCIEngineProcess;
    FName: string;
    FAuthor: string;
    FEngineReady: boolean;
    FEngineInited: boolean;
    function GetOptionCount: integer;
    function GetOptions(I: integer): TEngineOption;
  protected
    // Wait-fors
    function WaitForBoolean(Bool: PBoolean; Time: integer;
      RequiredState: boolean = True): boolean;
    function WaitForTermination(Time: integer): boolean;
    // Event handlers
    procedure MsgReceiver(Sender: TObject; AMessage: TEngineMessage);
    procedure ProcessTerminate(Sender: TObject);
    // Overridden getters
    function GetName: string; override;
    function GetAuthor: string; override;
    function GetFileName: string; override;
  public
    // Options work
    property Options[I: integer]: TEngineOption read GetOptions;
    property OptionCount: integer read GetOptionCount;
    procedure ApplyOption(I: integer); overload;
    procedure ApplyOption(AOption: TEngineOption); overload;
    procedure ApplyOption(const AValue: string); overload;
    // Overridden methods
    procedure StartInfinite; override;
    procedure StartTime(Timer: TChessTimer); override;
    procedure Stop; override;
    function WaitForStop(Time: integer = MaxWaitTime): boolean; override;
    function WaitForEngine(Time: integer = MaxWaitTime): boolean; override;
    procedure ProcessMessages; override;
    // Creation / Deletion
    constructor Create(const AExeName: string);
    procedure Initialize; override;
    procedure Uninitialize; override;
    destructor Destroy; override;
  end;

function AnalysisFailure: RAnalysisResult;

implementation

function AnalysisFailure: RAnalysisResult;
  // Returns RAnalysis result that means analysis failure.
begin
  Result.BestMove.Kind := mkImpossible;
  Result.PonderMove.Kind := mkImpossible;
end;

{ TAnalysisState }

function TAnalysisState.GetTime: TClockValue;
begin
  if FActive then
    Result := MilliSecondsToClockValue(GetTickCount64 - FStartTime)
  else
    Result := ZeroVal;
end;

procedure TAnalysisState.SetActive(AValue: boolean);
begin
  if FActive = AValue then
    Exit;
  Changing;
  FActive := AValue;
  if FActive then
  begin
    Clear;
    FStartTime := GetTickCount64;
  end;
  Changed;
end;

procedure TAnalysisState.SetCurMove(AValue: RChessMove);
begin
  if FCurMove = AValue then
    Exit;
  FCurMove := AValue;
  DoChange;
end;

procedure TAnalysisState.SetDepth(AValue: integer);
begin
  if FDepth = AValue then
    Exit;
  FDepth := AValue;
  DoChange;
end;

procedure TAnalysisState.SetMoveNumber(AValue: integer);
begin
  if FMoveNumber = AValue then
    Exit;
  FMoveNumber := AValue;
  DoChange;
end;

procedure TAnalysisState.SetNodes(AValue: int64);
begin
  if FNodes = AValue then
    Exit;
  FNodes := AValue;
  DoChange;
end;

procedure TAnalysisState.SetNPS(AValue: int64);
begin
  if FNPS = AValue then
    Exit;
  FNPS := AValue;
  DoChange;
end;

procedure TAnalysisState.SetScore(AValue: RPositionScore);
begin
  if FScore = AValue then
    Exit;
  FScore := AValue;
  DoChange;
end;

procedure TAnalysisState.Clear;
begin
  FDepth := 0;
  FNodes := 0;
  FNPS := 0;
  FMoveNumber := 0;
  FCurMove.Kind := mkImpossible;
  FScore := DefaultPositionScore;
  DoChange;
end;

procedure TAnalysisState.Changing;
// Called before changes.
begin
  BeginUpdate;
end;

procedure TAnalysisState.Changed;
// Called after changes.
begin
  EndUpdate;
  DoChange;
end;

constructor TAnalysisState.Create;
begin
  FActive := False;
  FCurMove.Kind := mkImpossible;
end;

{ TEngineString }

constructor TEngineString.Create(AValue: string);
begin
  FValue := AValue;
end;

{ TAnalysisLine }

constructor TAnalysisLine.Create;
begin
  FMoveChain := TMoveChain.Create;
  FTime := ZeroVal;
  FScore := DefaultPositionScore;
end;

destructor TAnalysisLine.Destroy;
begin
  FreeAndNil(FMoveChain);
  inherited Destroy;
end;

{ TAbstractChessEngine }

procedure TAbstractChessEngine.DoStart;
// Signals that the analysis has started.
begin
  if FState.Active then
    Exit;
  FState.Active := True;
  if Assigned(FOnStart) then
    FOnStart(Self);
end;

procedure TAbstractChessEngine.DoStop(const AResult: RAnalysisResult);
// Signals that the analysis has stopped.
begin
  if not FState.Active then
    Exit;
  FStopping := False;
  FState.Active := False;
  if Assigned(FOnStop) then
    FOnStop(Self, AResult);
end;

procedure TAbstractChessEngine.DoTerminate;
// Signals that the analysis has terminated.
begin
  DoStop(AnalysisFailure);
  if Assigned(FOnTerminate) then
    FOnTerminate(Self);
end;

procedure TAbstractChessEngine.SendAnalysisMessage(AMessage: TAnalysisMessage);
// Sends an analysis message.
begin
  if Assigned(FOnAnalysisMessage) then
    FOnAnalysisMessage(Self, AMessage);
  FreeAndNil(AMessage);
end;

procedure TAbstractChessEngine.StartInfinite;
// Starts the infinite analysis.
begin
  DoStart;
end;

{$HINTS OFF}
procedure TAbstractChessEngine.StartTime(Timer: TChessTimer);
// Starts the analysis with current timer.
begin
  DoStart;
end;

{$HINTS ON}

procedure TAbstractChessEngine.Stop;
// Stops the analysis
begin
  if not FState.Active then
    Exit;
  FStopping := True;
end;

{$HINTS OFF}
function TAbstractChessEngine.WaitForStop(Time: integer): boolean;
  // Waits while the engine will stop. Returns True if success, False otherwise.
  // Max wait time is limited with Time.
begin
  raise Exception.Create('TAbstractChessEngine.WaitForStop must be overridden!!!');
  Result := False;
end;

{$HINTS ON}

{$HINTS OFF}
function TAbstractChessEngine.WaitForEngine(Time: integer): boolean;
  // Waits while the engine will be ready to process commands. Returns True if
  // success, False otherwise. Max wait time is limited with Time.
begin
  raise Exception.Create('TAbstractChessEngine.WaitForEngine must be overridden!!!');
  Result := False;
end;

{$HINTS ON}

procedure TAbstractChessEngine.ProcessMessages;
// Processing messages that the engine has sent.
begin
end;

constructor TAbstractChessEngine.Create;
begin
  FMoveChain := TMoveChain.Create;
  FState := TAnalysisState.Create;
  FStopping := False;
end;

procedure TAbstractChessEngine.Initialize;
// Safe engine initialization (must be called after Create).
begin
end;

procedure TAbstractChessEngine.Uninitialize;
// Safe engine unitialization (must be called before Destroy).
begin
  FOnStop := nil;
  FOnStart := nil;
  if FState.Active and (not FStopping) then
    Stop;
end;

destructor TAbstractChessEngine.Destroy;
begin
  FreeAndNil(FMoveChain);
  FreeAndNil(FState);
  inherited Destroy;
end;

{ TUCIChessEngine }

function TUCIChessEngine.GetOptionCount: integer;
begin
  Result := FOptions.Count;
end;

function TUCIChessEngine.GetOptions(I: integer): TEngineOption;
begin
  Result := FOptions[I];
end;

function TUCIChessEngine.WaitForBoolean(Bool: PBoolean; Time: integer;
  RequiredState: boolean): boolean;
  // Waits while Bool^ = RequiredState. Returns True if success, False otherwise.
  // Max wait time is Time.
var
  Msec: int64;
begin
  if Bool = nil then
    Exit(False);
  Msec := GetTickCount64;
  Result := True;
  while (GetTickCount64 - Msec) < Time do
  begin
    if Bool^ = RequiredState then
      Exit;
    ProcessMessages;
    Sleep(15);
  end;
  Result := False;
end;

function TUCIChessEngine.WaitForTermination(Time: integer): boolean;
  // Waits for the engine termination. Returns True if success, False otherwise.
  // Max wait time is Time.
var
  Msec: int64;
begin
  Msec := GetTickCount64;
  Result := True;
  while (GetTickCount64 - Msec) < Time do
  begin
    if not FProcess.Process.Running then
      Exit;
    Sleep(15);
  end;
  Result := False;
end;

// Has MsgReceiver
{$I UCIMsgProcessor.inc}

procedure TUCIChessEngine.ProcessTerminate(Sender: TObject);
begin
  DoTerminate;
end;

function TUCIChessEngine.GetFileName: string;
begin
  Result := FProcess.Process.Executable;
end;

function TUCIChessEngine.GetName: string;
begin
  Result := FName;
end;

function TUCIChessEngine.GetAuthor: string;
begin
  Result := FAuthor;
end;

procedure TUCIChessEngine.ApplyOption(I: integer);
// Applies the option after changing.
begin
  ApplyOption(FOptions[I]);
end;

procedure TUCIChessEngine.ApplyOption(AOption: TEngineOption);
// Applies the option after changing.
begin
  FProcess.SendCommand(AOption.GetOptionCommand);
end;

procedure TUCIChessEngine.ApplyOption(const AValue: string);
// Applies the option after changing.
var
  I: integer;
begin
  for I := 0 to FOptions.Count - 1 do
    if AValue = FOptions[I].Name then
    begin
      ApplyOption(I);
      Exit;
    end;
end;

procedure TUCIChessEngine.StartInfinite;
begin
  if State.Active then
    Exit;
  inherited StartInfinite;
  FProcess.SendCommand(TSetPositionCommand.Create(MoveChain, False));
  FProcess.SendCommand(TInfiniteAnalysisCommand.Create);
end;

procedure TUCIChessEngine.StartTime(Timer: TChessTimer);
begin
  if State.Active then
    Exit;
  inherited StartTime(Timer);
  FProcess.SendCommand(TSetPositionCommand.Create(MoveChain, False));
  FProcess.SendCommand(TTimeredAnalysisCommand.Create(Timer));
end;

procedure TUCIChessEngine.Stop;
begin
  inherited;
  if not State.Active then
    Exit;
  FProcess.SendCommand(TStopAnalysisCommand.Create);
end;

function TUCIChessEngine.WaitForStop(Time: integer): boolean;
begin
  Result := WaitForBoolean(@FState.FActive, Time, False);
end;

function TUCIChessEngine.WaitForEngine(Time: integer): boolean;
begin
  FEngineReady := False;
  FProcess.SendCommand(TReadyCheckCommand.Create);
  Result := WaitForBoolean(@FEngineReady, Time);
end;

procedure TUCIChessEngine.ProcessMessages;
begin
  FProcess.TryRead;
end;

constructor TUCIChessEngine.Create(const AExeName: string);
begin
  inherited Create;
  FEngineInited := False;
  FName := '';
  FAuthor := '';
  FOptions := TEngineOptionList.Create(True);
  FProcess := TUCIEngineProcess.Create(AExeName);
  FProcess.MsgReceiver := @MsgReceiver;
  FProcess.OnTerminate := @ProcessTerminate;
  FProcess.TerminateOnDestroy := False;
end;

procedure TUCIChessEngine.Initialize;
begin
  FEngineInited := False;
  FProcess.TerminateOnDestroy := True;
  FProcess.SendCommand(TUCIInitCommand.Create);
  if not WaitForBoolean(@FEngineInited, EngineInitTime) then
    raise EChessEngine.CreateFmt(SUCICannotInit, [FileName]);
  FProcess.TerminateOnDestroy := False;
end;

procedure TUCIChessEngine.Uninitialize;
begin
  inherited;
  FProcess.SendCommand(TEngineQuitCommand.Create);
  if not WaitForTermination(EngineQuitTime) then
    FProcess.Process.Active := False;
end;

destructor TUCIChessEngine.Destroy;
begin
  FreeAndNil(FProcess);
  FreeAndNil(FOptions);
  inherited Destroy;
end;

end.
