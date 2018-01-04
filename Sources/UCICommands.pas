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
    This unit is the core of the UCI protocol implementation. It contains classes
    to process UCI engine messages and to send UCI engine commands.
}

// TODO : Support more UCI commands!
unit UCICommands;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Classes, SysUtils, FGL, AvgLvlTree, EngineProcesses, MoveChains, ChessRules,
  MoveConverters, EngineScores, ChessTime;

const
  EmptyStr = '<empty>';

type
  // Commands

  { TUCIInitCommand }

  TUCIInitCommand = class(TEngineCommand)  // "uci" command
  public
    function GetCommandString: string; override;
  end;

  { TDebugCheckCommand }

  TDebugCheckCommand = class(TEngineCommand) // "debug" command
  private
    FDebugging: boolean;
    procedure SetDebugging(AValue: boolean);
  public
    property Debugging: boolean read FDebugging write SetDebugging;
    function GetCommandString: string; override;
    constructor Create(ADebugging: boolean);
  end;

  { TReadyCheckCommand }

  TReadyCheckCommand = class(TEngineCommand) // "isready" command
  public
    function GetCommandString: string; override;
  end;

  { TSetOptionCommand }

  TSetOptionCommand = class(TEngineCommand) // "setoption" command
  private
    FName: string;
    FValue: string;
    procedure SetName(AValue: string);
    procedure SetValue(AValue: string);
  public
    property Name: string read FName write SetName;
    property Value: string read FValue write SetValue;
    constructor Create(const AName, AValue: string);
    function GetCommandString: string; override;
  end;

  //TRegisterCommand = class(TEngineCommand) // "register" command
  // TODO : implement "register" command !!!

  { TNewGameCommand }

  TNewGameCommand = class(TEngineCommand)
  public
    function GetCommandString: string; override;
  end;

  { TSetPositionCommand }

  TSetPositionCommand = class(TEngineCommand) // "position" command
  private
    FChain: TMoveChain;
    procedure SetChain(AValue: TMoveChain);
  public
    property Chain: TMoveChain read FChain write SetChain;
    constructor Create(AChain: TMoveChain; OwnsChain: boolean);
    destructor Destroy; override;
    function GetCommandString: string; override;
  end;

  // TODO : add more "go" command subtypes.

  { TAnalysisCommand }

  TAnalysisCommand = class(TEngineCommand)
    // "go" command (inherit from this class to add subcommands
  public
    function GetCommandString: string; override;
  end;

  { TInfiniteAnalysisCommand }

  TInfiniteAnalysisCommand = class(TAnalysisCommand) // "go infinite" command
  public
    function GetCommandString: string; override;
  end;

  { TTimeredAnalysisCommand }

  TTimeredAnalysisCommand = class(TAnalysisCommand)
    // "go wtime btime winc binc ..." command
  private
    FTimer: TChessTimer;
  public
    property Timer: TChessTimer read FTimer write FTimer;
    constructor Create(ATimer: TChessTimer);
    function GetCommandString: string; override;
  end;

  { TStopAnalysisCommand }

  TStopAnalysisCommand = class(TEngineCommand) // "stop" command
  public
    function GetCommandString: string; override;
  end;

  { TPonderHitCommand }

  TPonderHitCommand = class(TEngineCommand) // "ponderhit" command
  public
    function GetCommandString: string; override;
  end;

  { TEngineQuitCommand }

  TEngineQuitCommand = class(TEngineCommand) // "quit" command
  public
    function GetCommandString: string; override;
  end;

  // Info messages

  { TMessageInfo }

  TMessageInfo = class
  private
    FName: string;
  public
    property Name: string read FName;
    procedure ParseInfo(Params: TStringList; var Pos: integer); virtual; abstract;
    constructor Create; virtual;
    constructor Create(const AName: string);
    function DebugStr: string; virtual;
  end;

  TMessageInfoClass = class of TMessageInfo;
  TMessageInfoList = specialize TFPGObjectList<TMessageInfo>;

  { TIntegerMessageInfo }

  TIntegerMessageInfo = class(TMessageInfo)
    // "depth", "seldepth", "time", "nodes", "multipv", "currmovenumber",
    // "hashfull", "nps", "tbhits", "sbhits", "cpuload" infos.
  private
    FValue: int64;
  public
    property Value: int64 read FValue;
    procedure ParseInfo(Params: TStringList; var Pos: integer); override;
    function DebugStr: string; override;
  end;

  { TMoveChainMessageInfo }

  TMoveChainMessageInfo = class(TMessageInfo)
    // "pv", "currmove", "refutation", "currline" etc. infos.
  private
    FMoveChain: TMoveChain;
    FList: TStringList;
  public
    property MoveChain: TMoveChain read FMoveChain;
    constructor Create; override;
    destructor Destroy; override;
    procedure ParseInfo(Params: TStringList; var Pos: integer); override;
    procedure ExtractMoveChain(const ABaseBoard: RRawBoard);
    function DebugStr: string; override;
  end;

  { TScoreMessageInfo }

  TScoreMessageInfo = class(TMessageInfo)
    // "score" info.
  private
    FScore: RPositionScore;
  public
    property Kind: TScoreKind read FScore.Kind;
    property Mate: integer read FScore.Mate;
    property Score: TScoreValue read FScore.Score;
    property PositionScore: RPositionScore read FScore;
    procedure ParseInfo(Params: TStringList; var Pos: integer); override;
    function DebugStr: string; override;
    constructor Create; override;
  end;

  { TStringMessageInfo }

  TStringMessageInfo = class(TMessageInfo)
    // "string" info.
  private
    FValue: string;
  public
    property Value: string read FValue;
    procedure ParseInfo(Params: TStringList; var Pos: integer); override;
    function DebugStr: string; override;
  end;

  // Option kinds

  { TEngineOption }

  TEngineOption = class
  private
    FName: string;
    FTag: PtrInt;
  public
    property Name: string read FName;
    property Tag: PtrInt read FTag write FTag;
    procedure ParseOption(Params: TStringList; Pos: integer); virtual; abstract;
    function GetOptionCommand: TSetOptionCommand; virtual;
    procedure Assign(Source: TEngineOption);
    procedure AssignTo(Target: TEngineOption); virtual;
    function DebugStr: string; virtual;
    constructor Create; virtual;
  end;

  TEngineOptionClass = class of TEngineOption;

  { TCheckBoxOption }

  TCheckBoxOption = class(TEngineOption) // "check"
  private
    FChecked: boolean;
    procedure SetChecked(AValue: boolean);
  public
    property Checked: boolean read FChecked write SetChecked;
    procedure ParseOption(Params: TStringList; Pos: integer); override;
    function GetOptionCommand: TSetOptionCommand; override;
    procedure AssignTo(Target: TEngineOption); override;
    function DebugStr: string; override;
  end;

  { TSpinEditOption }

  TSpinEditOption = class(TEngineOption) // "spin"
  private
    FMax: integer;
    FMin: integer;
    FValue: integer;
    procedure SetMax(AValue: integer);
    procedure SetMin(AValue: integer);
    procedure SetValue(AValue: integer);
  public
    property Min: integer read FMin write SetMin;
    property Max: integer read FMax write SetMax;
    property Value: integer read FValue write SetValue;
    procedure ParseOption(Params: TStringList; Pos: integer); override;
    function GetOptionCommand: TSetOptionCommand; override;
    procedure AssignTo(Target: TEngineOption); override;
    function DebugStr: string; override;
  end;

  { TComboBoxOption }

  TComboBoxOption = class(TEngineOption) // "combo"
  private
    FItemIndex: integer;
    FItems: TStringList;
    procedure SetItemIndex(AValue: integer);
  public
    property Items: TStringList read FItems;
    property ItemIndex: integer read FItemIndex write SetItemIndex;
    constructor Create; override;
    destructor Destroy; override;
    procedure ParseOption(Params: TStringList; Pos: integer); override;
    function GetOptionCommand: TSetOptionCommand; override;
    procedure AssignTo(Target: TEngineOption); override;
    function DebugStr: string; override;
  end;

  { TEditOption }

  TEditOption = class(TEngineOption) // "string"
  private
    FText: string;
    procedure SetText(AValue: string);
  public
    property Text: string read FText write SetText;
    constructor Create; override;
    procedure ParseOption(Params: TStringList; Pos: integer); override;
    function GetOptionCommand: TSetOptionCommand; override;
    procedure AssignTo(Target: TEngineOption); override;
    function DebugStr: string; override;
  end;

  { TButtonOption }

  TButtonOption = class(TEngineOption) // "button"
  public
    procedure ParseOption(Params: TStringList; Pos: integer); override;
    function GetOptionCommand: TSetOptionCommand; override;
    procedure AssignTo(Target: TEngineOption); override;
  end;

  // Messages

  TEngineIDKind = (idName, idAuthor, idUnknown);

  { TEngineIDMessage }

  TEngineIDMessage = class(TEngineMessage) // "id" message
  private
    FKind: TEngineIDKind;
    FValue: string;
  public
    property Kind: TEngineIDKind read FKind;
    property Value: string read FValue;
    procedure ParseParameters(Params: TStringList); override;
    constructor Create; override;
    function DebugStr: string; override;
  end;

  { TUCIInitedMessage }

  TUCIInitedMessage = class(TEngineMessage) // "uciok" message
  public
    procedure ParseParameters(Params: TStringList); override;
  end;

  { TUCIReadyMessage }

  TUCIReadyMessage = class(TEngineMessage) // "readyok" message
  public
    procedure ParseParameters(Params: TStringList); override;
  end;

  { TBestMoveMessage }

  TBestMoveMessage = class(TEngineMessage) // "bestmove" message
  private
    FBestMove: RChessMove;
    FBestMoveStr: string;
    FPonderMove: RChessMove;
    FPonderMoveStr: string;
  public
    property BestMove: RChessMove read FBestMove;
    property PonderMove: RChessMove read FPonderMove;
    procedure ParseParameters(Params: TStringList); override;
    procedure ExtractMoves(const ABaseBoard: RRawBoard);
    constructor Create; override;
    function DebugStr: string; override;
  end;

  //TCopyProtectionMessage = class(TEngineMessage) "copyprotection" message
  // TODO : Implement "copyprotecion" message !!!

  //TRegistrationMessage = class(TEngineMessage) "registration" message
  // TODO : Implement "registration" message !!!

  { TInfoMessage }

  TInfoMessage = class(TEngineMessage) // "info" message
  private
    FList: TMessageInfoList;
  public
    property List: TMessageInfoList read FList;
    procedure ParseParameters(Params: TStringList); override;
    constructor Create; override;
    destructor Destroy; override;
    function DebugStr: string; override;
  end;

  { TOptionMessage }

  TOptionMessage = class(TEngineMessage) // "option" message
  private
    FOption: TEngineOption;
  public
    property Option: TEngineOption read FOption;
    procedure ParseParameters(Params: TStringList); override;
    constructor Create; override;
    destructor Destroy; override;
    function DebugStr: string; override;
  end;

  // Engine process

  { TUCIEngineProcess }

  TUCIEngineProcess = class(TEngineProcess)
    procedure RegisterMessages; override;
  end;

function GetStringUntil(Params: TStringList; var Pos: integer;
  StopAt: string = ' '): string;
function CheckWord(Params: TStringList; var Pos: integer; AWord: string): boolean;
function IsUCIMove(S: string): boolean;

implementation

var
  Infos: TStringToPointerTree;

procedure RegisterInfo(const AInfo: string; AClass: TMessageInfoClass);
// Registers an info message.
begin
  Infos[AInfo] := AClass;
end;

function InfoRegistered(const AInfo: string): boolean;
  // Returns True if such Info message was registered.
begin
  Result := Infos.Contains(AInfo);
end;

function GetStringUntil(Params: TStringList; var Pos: integer; StopAt: string): string;
  // The function iterates over params from position Pos and adds them into the
  // result string. The function stops when meets StopAt string.
begin
  Result := '';
  while (Pos < Params.Count) and (LowerCase(Params[Pos]) <> LowerCase(StopAt)) do
  begin
    if Result <> '' then
      Result += ' ';
    Result += Params[Pos];
    Inc(Pos);
  end;
end;

function CheckWord(Params: TStringList; var Pos: integer; AWord: string): boolean;
  // Returns True if AWord is on position Pos in Params list.
begin
  Result := False;
  if Pos >= Params.Count then
    Exit;
  if LowerCase(Params[Pos]) <> LowerCase(AWord) then
    Exit;
  Inc(Pos);
  Result := True;
end;

function IsUCIMove(S: string): boolean;
  // Returns True if the string is an UCI move.
begin
  S := LowerCase(S);
  Result := False;
  if not (S[1] in ['a' .. 'h']) then
    Exit;
  if not (S[2] in ['1' .. '8']) then
    Exit;
  if not (S[3] in ['a' .. 'h']) then
    Exit;
  if not (S[4] in ['1' .. '8']) then
    Exit;
  if Length(S) = 4 then
    Result := True
  else
  if Length(S) = 5 then
    Result := S[5] in ['n', 'b', 'r', 'q'];
end;

{ TUCIInitCommand }

function TUCIInitCommand.GetCommandString: string;
begin
  Result := 'uci';
end;

{ TDebugCheckCommand }

procedure TDebugCheckCommand.SetDebugging(AValue: boolean);
begin
  if FDebugging = AValue then
    Exit;
  FDebugging := AValue;
end;

function TDebugCheckCommand.GetCommandString: string;
begin
  Result := 'debug ' + BoolToStr(FDebugging, 'on', 'off');
end;

constructor TDebugCheckCommand.Create(ADebugging: boolean);
begin
  FDebugging := ADebugging;
end;

{ TReadyCheckCommand }

function TReadyCheckCommand.GetCommandString: string;
begin
  Result := 'isready';
end;

{ TSetOptionCommand }

procedure TSetOptionCommand.SetName(AValue: string);
begin
  if FName = AValue then
    Exit;
  FName := AValue;
end;

procedure TSetOptionCommand.SetValue(AValue: string);
begin
  if FValue = AValue then
    Exit;
  FValue := AValue;
end;

constructor TSetOptionCommand.Create(const AName, AValue: string);
begin
  FName := AName;
  FValue := AValue;
end;

function TSetOptionCommand.GetCommandString: string;
begin
  Result := 'setoption name ' + FName;
  if FValue <> '' then
    Result += ' value ' + FValue;
end;

{ TNewGameCommand }

function TNewGameCommand.GetCommandString: string;
begin
  Result := 'ucinewgame';
end;

{ TSetPositionCommand }

procedure TSetPositionCommand.SetChain(AValue: TMoveChain);
begin
  FChain.Assign(AValue);
end;

constructor TSetPositionCommand.Create(AChain: TMoveChain; OwnsChain: boolean);
begin
  if OwnsChain then
    FChain := AChain
  else
  begin
    FChain := TMoveChain.Create;
    FChain.Assign(AChain);
  end;
end;

destructor TSetPositionCommand.Destroy;
begin
  FreeAndNil(FChain);
  inherited Destroy;
end;

function TSetPositionCommand.GetCommandString: string;
var
  Converter: TUCIMoveConverter;
  ChessBoard: TChessBoard;
begin
  Result := 'position';
  ChessBoard := TChessBoard.Create;
  ChessBoard.RawBoard := FChain.Boards[-1];
  if ChessBoard.RawBoard = GetInitialPosition then
    Result += ' startpos'
  else
    Result += ' fen ' + ChessBoard.FENString;
  FreeAndNil(ChessBoard);
  Result += ' moves';
  if FChain.Count <> 0 then
  begin
    Converter := TUCIMoveConverter.Create;
    Result += ' ' + FChain.ConvertToString(Converter, ' ');
    FreeAndNil(Converter);
  end;
end;

{ TAnalysisCommand }

function TAnalysisCommand.GetCommandString: string;
begin
  Result := 'go';
end;

{ TInfiniteAnalysisCommand }

function TInfiniteAnalysisCommand.GetCommandString: string;
begin
  Result := inherited GetCommandString + ' infinite';
end;

{ TTimeredAnalysisCommand }

constructor TTimeredAnalysisCommand.Create(ATimer: TChessTimer);
begin
  FTimer := ATimer;
end;

function TTimeredAnalysisCommand.GetCommandString: string;
var
  WhiteInc, BlackInc: TClockValue;
  MoveLeft, MoveCount: integer;
begin
  Result := inherited GetCommandString;
  if not Assigned(FTimer) then
  begin
    Result += ' infinite';
    Exit;
  end;
  with FTimer.Clock, FTimer.TimeControl do
  begin
    // wtime
    with Times[pcWhite] do
      if Time <> InfVal then
        Result += Format(' wtime %d', [ClockValueToMilliSeconds(Time)]);
    // btime
    with Times[pcBlack] do
      if Time <> InfVal then
        Result += Format(' btime %d', [ClockValueToMilliSeconds(Time)]);
    // winc, binc
    WhiteInc := WhiteTimeControl[Times[pcWhite].ItemIndex].AddTime;
    BlackInc := BlackTimeControl[Times[pcBlack].ItemIndex].AddTime;
    Result += Format(' winc %d binc %d', [ClockValueToMilliSeconds(WhiteInc),
      ClockValueToMilliSeconds(BlackInc)]);
    // movestogo
    MoveLeft := Times[Active].MoveLeft;
    MoveCount := TimeControls[Active].Items[Times[Active].ItemIndex].MoveCount;
    if (MoveLeft > 0) and (MoveCount > 0) then
      Result += Format(' movestogo %d', [MoveLeft]);
  end;
end;

{ TStopAnalysisCommand }

function TStopAnalysisCommand.GetCommandString: string;
begin
  Result := 'stop';
end;

{ TPonderHitCommand }

function TPonderHitCommand.GetCommandString: string;
begin
  Result := 'ponderhit';
end;

{ TEngineQuitCommand }

function TEngineQuitCommand.GetCommandString: string;
begin
  Result := 'quit';
end;

{ TMessageInfo }

constructor TMessageInfo.Create;
begin
  FName := '';
end;

constructor TMessageInfo.Create(const AName: string);
begin
  Create;
  FName := AName;
end;

function TMessageInfo.DebugStr: string;
  // Returns a string for debugging.
begin
  WriteStr(Result, ClassName, '[', FName, ']');
end;

{ TIntegerMessageInfo }

procedure TIntegerMessageInfo.ParseInfo(Params: TStringList; var Pos: integer);
var
  Code: integer;
begin
  if Pos >= Params.Count then
    Exit;
  Val(Params[Pos], FValue, Code);
  if Code = 0 then
    Inc(Pos);
end;

function TIntegerMessageInfo.DebugStr: string;
begin
  WriteStr(Result, ClassName, '[', FName, '] :: (Value: ', FValue, ')');
end;

{ TMoveChainMessageInfo }

constructor TMoveChainMessageInfo.Create;
begin
  inherited;
  FMoveChain := nil;
  FList := TStringList.Create;
end;

destructor TMoveChainMessageInfo.Destroy;
begin
  if FMoveChain <> nil then
    FreeAndNil(FMoveChain);
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TMoveChainMessageInfo.ParseInfo(Params: TStringList; var Pos: integer);
var
  S: string;
begin
  FList.Clear;
  while Pos < Params.Count do
  begin
    S := LowerCase(Params[Pos]);
    if IsUCIMove(S) then
      FList.Add(S)
    else
      Exit;
    Inc(Pos);
  end;
end;

procedure TMoveChainMessageInfo.ExtractMoveChain(const ABaseBoard: RRawBoard);
// Extracts the move chain with the specified board.
var
  I: integer;
  Converter: TUCIMoveConverter;
begin
  if FMoveChain <> nil then
    FreeAndNil(FMoveChain);
  FMoveChain := TMoveChain.Create(ABaseBoard);
  Converter := TUCIMoveConverter.Create;
  try
    for I := 0 to FList.Count - 1 do
    begin
      with FMoveChain do
        Converter.RawBoard := Boards[Count - 1];
      FMoveChain.Add(Converter.ParseMove(FList[I]));
    end;
  except
    // mute the exceptions.
  end;
  FreeAndNil(Converter);
end;

function TMoveChainMessageInfo.DebugStr: string;
var
  I: integer;
  Converter: TUCIMoveConverter;
begin
  Result := inherited DebugStr;
  Result += ' :: (List : "';
  for I := 0 to FList.Count - 1 do
  begin
    if I <> 0 then
      Result += ' ';
    Result += FList[I];
  end;
  Converter := TUCIMoveConverter.Create;
  Result += '", Chain: "';
  if FMoveChain = nil then
    Result += 'nil'
  else
    Result += FMoveChain.ConvertToString(Converter, ' ');
  FreeAndNil(Converter);
  Result += '")';
end;

{ TScoreMessageInfo }

constructor TScoreMessageInfo.Create;
begin
  inherited Create;
  FScore := DefaultPositionScore;
end;

procedure TScoreMessageInfo.ParseInfo(Params: TStringList; var Pos: integer);

  function NextInt(DefaultValue: integer): integer;
    // If Params[Pos] is integer, it returns this integer and increments Pos.
    // Otherwise, returns DefaultValue.
  var
    Code: integer;
  begin
    if Pos >= Params.Count then
      Exit(DefaultValue);
    Val(Params[Pos], Result, Code);
    if Code = 0 then
      Inc(Pos)
    else
      Result := DefaultValue;
  end;

var
  AKind: string;
begin
  FScore := DefaultPositionScore;
  while Pos < Params.Count do
  begin
    AKind := LowerCase(Params[Pos]);
    Inc(Pos);
    if AKind = 'cp' then
      FScore.Score := NextInt(FScore.Score)
    else
    if AKind = 'mate' then
      FScore.Mate := NextInt(FScore.Mate)
    else
    if AKind = 'lowerbound' then
      FScore.Kind := skLowerBound
    else
    if AKind = 'upperbound' then
      FScore.Kind := skUpperBound
    else
    begin
      Dec(Pos);
      Exit;
    end;
  end;
end;

function TScoreMessageInfo.DebugStr: string;
begin
  WriteStr(Result, ClassName, '[', FName, '] :: (Kind: ', Kind, ', Mate: ',
    Mate, ', Score: ', Score, ')');
end;

{ TStringMessageInfo }

procedure TStringMessageInfo.ParseInfo(Params: TStringList; var Pos: integer);
begin
  FValue := GetStringUntil(Params, Pos);
end;

function TStringMessageInfo.DebugStr: string;
begin
  WriteStr(Result, ClassName, '[', FName, '] :: (Value: "', FValue, '")');
end;

{ TEngineOption }

function TEngineOption.GetOptionCommand: TSetOptionCommand;
  // Returns a SetOptionCommand to set this option.
begin
  Result := TSetOptionCommand.Create(FName, '');
end;

procedure TEngineOption.Assign(Source: TEngineOption);
// Copies Source to Self.
begin
  Source.AssignTo(Self);
end;

procedure TEngineOption.AssignTo(Target: TEngineOption);
// Copies Self to Target.
begin
  Target.FName := Self.FName;
  Target.Tag := Self.Tag;
end;

function TEngineOption.DebugStr: string;
begin
  WriteStr(Result, ClassName, '[', FName, ']');
end;

constructor TEngineOption.Create;
begin
end;

{ TCheckBoxOption }

procedure TCheckBoxOption.SetChecked(AValue: boolean);
begin
  if FChecked = AValue then
    Exit;
  FChecked := AValue;
end;

procedure TCheckBoxOption.ParseOption(Params: TStringList; Pos: integer);
// Example: "option name Nullmove type check default true"
begin
  if not CheckWord(Params, Pos, 'default') then
    Exit;
  FChecked := False;
  if CheckWord(Params, Pos, 'true') then
    FChecked := True;
end;

function TCheckBoxOption.GetOptionCommand: TSetOptionCommand;
begin
  Result := inherited GetOptionCommand;
  Result.Value := BoolToStr(FChecked, 'true', 'false');
end;

procedure TCheckBoxOption.AssignTo(Target: TEngineOption);
begin
  inherited AssignTo(Target);
  (Target as TCheckBoxOption).Checked := Checked;
end;

function TCheckBoxOption.DebugStr: string;
begin
  WriteStr(Result, inherited DebugStr, ' :: (Checked: ', FChecked, ')');
end;

{ TSpinEditOption }

procedure TSpinEditOption.SetMax(AValue: integer);
begin
  if FMax = AValue then
    Exit;
  FMax := AValue;
end;

procedure TSpinEditOption.SetMin(AValue: integer);
begin
  if FMin = AValue then
    Exit;
  FMin := AValue;
end;

procedure TSpinEditOption.SetValue(AValue: integer);
begin
  if FValue = AValue then
    Exit;
  FValue := AValue;
end;

procedure TSpinEditOption.ParseOption(Params: TStringList; Pos: integer);
// Example: "option name Selectivity type spin default 2 min 0 max 4"
begin
  FMin := -1;
  FMax := -1;
  FValue := -1;
  try
    // parsing FValue
    if not CheckWord(Params, Pos, 'default') then
      Exit;
    FValue := StrToInt(Params[Pos]);
    Inc(Pos);
    // parsing FMin
    if not CheckWord(Params, Pos, 'min') then
      Exit;
    FMin := StrToInt(Params[Pos]);
    Inc(Pos);
    // parsing FMax
    if not CheckWord(Params, Pos, 'max') then
      Exit;
    FMax := StrToInt(Params[Pos]);
    Inc(Pos);
  except
    // mute the exceptions, we don't need them.
  end;
end;

function TSpinEditOption.GetOptionCommand: TSetOptionCommand;
begin
  Result := inherited GetOptionCommand;
  Result.Value := IntToStr(FValue);
end;

procedure TSpinEditOption.AssignTo(Target: TEngineOption);
begin
  inherited AssignTo(Target);
  (Target as TSpinEditOption).Value := Value;
  (Target as TSpinEditOption).Min := Min;
  (Target as TSpinEditOption).Max := Max;
end;

function TSpinEditOption.DebugStr: string;
begin
  WriteStr(Result, inherited DebugStr, ' :: (Min: ', FMin, ', Max: ',
    FMax, ', Value: ', FValue, ')');
end;

{ TComboBoxOption }

procedure TComboBoxOption.SetItemIndex(AValue: integer);
begin
  if FItemIndex = AValue then
    Exit;
  FItemIndex := AValue;
end;

constructor TComboBoxOption.Create;
begin
  FItems := TStringList.Create;
end;

destructor TComboBoxOption.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TComboBoxOption.ParseOption(Params: TStringList; Pos: integer);
// Example: "option name Style type combo default Normal var Solid var Normal var Risky"
var
  DefVal: string;

  procedure ParseIt;
  // Parses the list.
  begin
    DefVal := '';
    FItems.Clear;
    // parsing default value
    if not CheckWord(Params, Pos, 'default') then
      Exit;
    DefVal := GetStringUntil(Params, Pos, 'var');
    // skip the "var"
    if Pos >= Params.Count then
      Exit;
    Inc(Pos);
    // parsing vars
    while True do
    begin
      FItems.Add(GetStringUntil(Params, Pos, 'var'));
      // skip the "var"
      if Pos >= Params.Count then
        Exit;
      Inc(Pos);
    end;
  end;

begin
  DefVal := '';
  // parse the list
  ParseIt;
  // calc the item index
  FItemIndex := FItems.IndexOf(DefVal);
end;

function TComboBoxOption.GetOptionCommand: TSetOptionCommand;
begin
  Result := inherited GetOptionCommand;
  if FItemIndex >= 0 then
    Result.Value := FItems[FItemIndex];
end;

procedure TComboBoxOption.AssignTo(Target: TEngineOption);
begin
  inherited AssignTo(Target);
  (Target as TComboBoxOption).Items.Assign(Items);
  (Target as TComboBoxOption).ItemIndex := ItemIndex;
end;

function TComboBoxOption.DebugStr: string;
var
  I: integer;
begin
  Result := inherited DebugStr + ' :: (List: [';
  for I := 0 to FItems.Count - 1 do
  begin
    if I <> 0 then
      Result += ', ';
    Result += '"' + FItems[I] + '"';
  end;
  Result += '], Index: ' + IntToStr(FItemIndex) + ')';
end;

{ TEditOption }

procedure TEditOption.SetText(AValue: string);
begin
  if AValue = '' then
    AValue := EmptyStr;
  if FText = AValue then
    Exit;
  FText := AValue;
end;

constructor TEditOption.Create;
begin
  inherited Create;
  FText := EmptyStr;
end;

procedure TEditOption.ParseOption(Params: TStringList; Pos: integer);
// Example: "option name NalimovPath type string default c:\"
begin
  if not CheckWord(Params, Pos, 'default') then
    Exit;
  Text := GetStringUntil(Params, Pos);
end;

function TEditOption.GetOptionCommand: TSetOptionCommand;
begin
  Result := inherited GetOptionCommand;
  Result.Value := Text;
end;

procedure TEditOption.AssignTo(Target: TEngineOption);
begin
  inherited AssignTo(Target);
  (Target as TEditOption).Text := Text;
end;

function TEditOption.DebugStr: string;
begin
  WriteStr(Result, inherited DebugStr, ' :: (Text = "', Text, '")');
end;

{ TButtonOption }

{$HINTS OFF}
procedure TButtonOption.ParseOption(Params: TStringList; Pos: integer);
// Example: "option name Clear Hash type button"
begin
  // do nothing
end;

{$HINTS ON}

function TButtonOption.GetOptionCommand: TSetOptionCommand;
begin
  Result := inherited GetOptionCommand;
end;

procedure TButtonOption.AssignTo(Target: TEngineOption);
begin
  inherited AssignTo(Target);
end;

{ TEngineIDMessage }

procedure TEngineIDMessage.ParseParameters(Params: TStringList);
var
  S: string;
  Q: integer;
begin
  FKind := idUnknown;
  Q := 1;
  // parsing kind
  if Q >= Params.Count then
    Exit;
  S := LowerCase(Params[Q]);
  if S = 'name' then
    FKind := idName
  else
  if S = 'author' then
    FKind := idAuthor
  else
    FKind := idUnknown;
  Inc(Q);
  // parsing name
  FValue := GetStringUntil(Params, Q);
end;

constructor TEngineIDMessage.Create;
begin
  inherited Create;
  FKind := idUnknown;
end;

function TEngineIDMessage.DebugStr: string;
begin
  WriteStr(Result, ClassName, ' :: (Name: "', FValue, '", Kind: "', FKind, '")');
end;

{ TUCIInitedMessage }

{$HINTS OFF}
procedure TUCIInitedMessage.ParseParameters(Params: TStringList);
begin
end;

{$HINTS ON}

{ TUCIReadyMessage }

{$HINTS OFF}
procedure TUCIReadyMessage.ParseParameters(Params: TStringList);
begin
end;

{$HINTS ON}

{ TBestMoveMessage }

procedure TBestMoveMessage.ParseParameters(Params: TStringList);
var
  S: string;
  Q: integer;
begin
  FBestMoveStr := '';
  FPonderMoveStr := '';
  Q := 1;
  // parsing bestMove
  if Q >= Params.Count then
    Exit;
  S := LowerCase(Params[Q]);
  if not IsUCIMove(S) then
    Exit;
  FBestMoveStr := S;
  Inc(Q);
  // parsing "ponder"
  if not CheckWord(Params, Q, 'ponder') then
    Exit;
  // parsing ponderMove
  if Q >= Params.Count then
    Exit;
  S := LowerCase(Params[Q]);
  if not IsUCIMove(S) then
    Exit;
  FPonderMoveStr := S;
end;

procedure TBestMoveMessage.ExtractMoves(const ABaseBoard: RRawBoard);
// Converts move strings to moves (in position ABaseBoard).
var
  ChessBoard: TChessBoard;
  Converter: TUCIMoveConverter;
begin
  FBestMove.Kind := mkImpossible;
  FPonderMove.Kind := mkImpossible;
  Converter := TUCIMoveConverter.Create;
  ChessBoard := TChessBoard.Create;
  try
    // parsing BestMove
    ChessBoard.RawBoard := ABaseBoard;
    Converter.RawBoard := ChessBoard.RawBoard;
    FBestMove := Converter.ParseMove(FBestMoveStr);
    // parsing PonderMove
    ChessBoard.MakeMove(FBestMove);
    Converter.RawBoard := ChessBoard.RawBoard;
    FPonderMove := Converter.ParseMove(FPonderMoveStr);
  except
    // mute the exceptions
  end;
  FreeAndNil(Converter);
  FreeAndNil(ChessBoard);
end;

constructor TBestMoveMessage.Create;
begin
  inherited Create;
  FBestMove.Kind := mkImpossible;
  FPonderMove.Kind := mkImpossible;
end;

function TBestMoveMessage.DebugStr: string;
var
  Converter: TUCIMoveConverter;
begin
  // it's a hack with TUCIMoveConverter, I do not assign the board.
  // don't do it! (it's just for debugging)
  Converter := TUCIMoveConverter.Create;
  WriteStr(Result,
    ClassName, ' :: (BestMove: "', FBestMoveStr, '", PonderMove: "',
    FPonderMoveStr, '")', LineEnding, '(BestMove.Kind: "', FBestMove.Kind,
    '" PonderMove.Kind: "', FPonderMove.Kind, '")', LineEnding,
    '(BestMove: ', Converter.GetMoveString(FBestMove), ', PonderMove: ',
    Converter.GetMoveString(FPonderMove), ')');
  FreeAndNil(Converter);
end;

{ TInfoMessage }

procedure TInfoMessage.ParseParameters(Params: TStringList);
var
  Opt: TMessageInfo;
  Q: integer;
begin
  FList.Clear;
  Q := 1;
  while Q < Params.Count do
  begin
    Inc(Q);
    if InfoRegistered(Params[Q - 1]) then
    begin
      Opt := TMessageInfoClass(Infos[Params[Q - 1]]).Create(Params[Q - 1]);
      Opt.ParseInfo(Params, Q);
      FList.Add(Opt);
    end;
  end;
end;

constructor TInfoMessage.Create;
begin
  inherited Create;
  FList := TMessageInfoList.Create(True);
end;

destructor TInfoMessage.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

function TInfoMessage.DebugStr: string;
var
  I: integer;
begin
  Result := inherited DebugStr + LineEnding;
  for I := 0 to FList.Count - 1 do
    Result += FList[I].DebugStr + LineEnding;
end;

{ TOptionMessage }

procedure TOptionMessage.ParseParameters(Params: TStringList);

  function GetParam(var I: integer): string; inline;
    // Extracts the ith parameter and goes further.
  begin
    if I >= Params.Count then
      Result := ''
    else
    begin
      Result := LowerCase(Params[I]);
      Inc(I);
    end;
  end;

var
  AName: string;
  AType: string;
  Q: integer;
  AClass: TEngineOptionClass;
begin
  if FOption <> nil then
    FreeAndNil(FOption);
  Q := 1;
  // first, parse "option name <name> type <type>"

  // parsing name (till "type" word).
  if GetParam(Q) <> 'name' then
    Exit;
  AName := GetStringUntil(Params, Q, 'type');
  // parsing type.
  if GetParam(Q) <> 'type' then
    Exit;
  AType := GetParam(Q);
  // deciding what type it was.
  if AType = 'check' then
    AClass := TCheckBoxOption
  else
  if AType = 'spin' then
    AClass := TSpinEditOption
  else
  if AType = 'combo' then
    AClass := TComboBoxOption
  else
  if AType = 'string' then
    AClass := TEditOption
  else
  if AType = 'button' then
    AClass := TButtonOption
  else
    AClass := nil;
  if AClass = nil then
    Exit;

  // then, the option class must parse the rest of the params itself.
  FOption := AClass.Create;
  FOption.FName := AName;
  FOption.ParseOption(Params, Q);
end;

constructor TOptionMessage.Create;
begin
  inherited Create;
  FOption := nil;
end;

destructor TOptionMessage.Destroy;
begin
  if FOption <> nil then
    FreeAndNil(FOption);
  inherited Destroy;
end;

function TOptionMessage.DebugStr: string;
begin
  Result := ClassName + ' = ';
  if FOption = nil then
    Result += 'nil'
  else
    Result += FOption.DebugStr;
end;

{ TUCIEngineProcess }

procedure TUCIEngineProcess.RegisterMessages;
begin
  inherited;
  // register messages
  RegisterEngineMessage('id', TEngineIDMessage);
  RegisterEngineMessage('uciok', TUCIInitedMessage);
  RegisterEngineMessage('readyok', TUCIReadyMessage);
  RegisterEngineMessage('bestmove', TBestMoveMessage);
  //RegisterEngineMessage('copyprotection', TCopyProtectionMessage);
  //RegisterEngineMessage('registration', TRegistrationMessage);
  RegisterEngineMessage('info', TInfoMessage);
  RegisterEngineMessage('option', TOptionMessage);
end;

initialization
  Infos := TStringToPointerTree.Create(False);
  Infos.FreeValues := False;
  // register infos
  RegisterInfo('depth', TIntegerMessageInfo);
  RegisterInfo('seldepth', TIntegerMessageInfo);
  RegisterInfo('time', TIntegerMessageInfo);
  RegisterInfo('nodes', TIntegerMessageInfo);
  RegisterInfo('pv', TMoveChainMessageInfo);
  RegisterInfo('multipv', TIntegerMessageInfo);
  RegisterInfo('score', TScoreMessageInfo);
  RegisterInfo('currmove', TMoveChainMessageInfo);
  RegisterInfo('currmovenumber', TIntegerMessageInfo);
  RegisterInfo('hashfull', TIntegerMessageInfo);
  RegisterInfo('nps', TIntegerMessageInfo);
  RegisterInfo('tbhits', TIntegerMessageInfo);
  RegisterInfo('sbhits', TIntegerMessageInfo);
  RegisterInfo('cpuload', TIntegerMessageInfo);
  RegisterInfo('string', TStringMessageInfo);
  RegisterInfo('refutation', TMoveChainMessageInfo);
  RegisterInfo('currline', TMoveChainMessageInfo);

finalization
  FreeAndNil(Infos);

end.
