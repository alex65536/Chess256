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
    This unit implements the chess clock system.
}

// TODO : Make a better timer!!! (maybe without using standard TTimer)
unit ChessTime;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, ChessRules, FGL, ExtCtrls, ChessUtils;

type

  { TTimer }

  TTimer = class(ExtCtrls.TTimer) // a better timer will be implemented later!
    constructor Create; overload;
  end;

  { TClockValue }

  TClockValue = record
  private
    Value: int64;
  public
    class operator=(const A, B: TClockValue): Boolean;
  end;

  { RTimeControl }

  RTimeControl = record
    StartTime, AddTime: TClockValue;
    MoveCount: integer;
    class operator=(A, B: RTimeControl): Boolean;
  end;
  // StartTime = Infinity -> no time control
  // MoveCount = -1 -> for the rest of the game

  { RClockData }

  RClockData = record
    Time: TClockValue;
    MoveLeft, ItemIndex: integer;
    class operator=(A, B: RClockData): Boolean;
  end;

  { RChessClock }

  RChessClock = record
    Times: array [TPieceColor] of RClockData;
    Active: TPieceColor;
    class operator=(A, B: RChessClock): Boolean;
  end;

const
  // TClockValue consts
  InfVal: TClockValue = (Value: 9223372036854775807);
  ZeroVal: TClockValue = (Value: 0);

resourcestring
  STimeControlStringRead = 'Invalid TimeControl string.';
  SInfiniteTime = '∞';
  SOutOfTime = '-';
  STimeFormat = '%s:%s:%s';
  SExtTimeFormat = '%dd %s:%s:%s';
  SActiveWhite = '[%s] (%s)';
  SActiveBlack = '(%s) [%s]';

type
  ETimeControlStringRead = class(Exception);

  TTimeForfeitEvent = procedure(Sender: TObject; Side: TPieceColor) of object;

  TTimeControlList = specialize TFPGList<RTimeControl>;

  { TTimeControl }

  TTimeControl = class(TChessObject)
  private
    FList: TTimeControlList;
    // Getters / Setters
    function GetCount: integer;
    function GetItems(I: integer): RTimeControl;
    function GetTimeControlString: string;
    procedure SetItems(I: integer; AValue: RTimeControl);
    procedure SetTimeControlString(AValue: string);
  public
    // Properties
    property List: TTimeControlList read FList;
    property Items[I: integer]: RTimeControl read GetItems write SetItems; default;
    property Count: integer read GetCount;
    property TimeControlString: string read GetTimeControlString
      write SetTimeControlString;
    // Methods
    procedure ChangeMove(var Data: RClockData);
    function GetInitialTime: RClockData;
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
  end;

  { TTimeControlPair }

  TTimeControlPair = class(TChessObject)
  private
    FTimeControls: array [TPieceColor] of TTimeControl;
    // Getters / Setters
    function GetTimeControls(C: TPieceColor): TTimeControl;
    function GetTimeControlString: string;
    procedure SetTimeControlString(AValue: string);
    // Event handlers
    procedure Changer(Sender: TObject);
  public
    // Properties
    property WhiteTimeControl: TTimeControl index pcWhite read GetTimeControls;
    property BlackTimeControl: TTimeControl index pcBlack read GetTimeControls;
    property TimeControls[C: TPieceColor]: TTimeControl read GetTimeControls;
    property TimeControlString: string read GetTimeControlString
      write SetTimeControlString;
    // Methods
    procedure ChangeMove(var Data: RChessClock);
    function GetInitialTime(Color: TPieceColor): RChessClock;
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
  end;

  { TChessTimer }

  TChessTimer = class
  private
    FInitialColor: TPieceColor;
    FOnChange: TNotifyEvent;
    FOnTimeForfeit: TTimeForfeitEvent;
    FOnUpdate: TNotifyEvent;
    FPaused: boolean;
    FTimeControl: TTimeControlPair;
    FTimeForfeit: boolean;
    FTimers: array [TPieceColor] of TTimer;
    FClock: RChessClock;
    // Getters / Setters
    procedure SetClock(AValue: RChessClock);
    procedure SetPaused(AValue: boolean);
    // Event handlers
    procedure Changer(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  protected
    function IsTimeForfeit: boolean;
    function CanResume: boolean;
    procedure DoChange;
    procedure DoTimeForfeit(Color: TPieceColor);
    procedure Pause;
    procedure Resume;
  public
    // Properties
    property TimeControl: TTimeControlPair read FTimeControl;
    property Paused: boolean read FPaused write SetPaused;
    property Clock: RChessClock read FClock write SetClock;
    property TimeForfeit: boolean read IsTimeForfeit;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
    property OnTimeForfeit: TTimeForfeitEvent read FOnTimeForfeit write FOnTimeForfeit;
    property InitialColor: TPieceColor read FInitialColor write FInitialColor;
    // Methods
    procedure FlipClock;
    procedure Restart;
    constructor Create;
    destructor Destroy; override;
  end;

function MakeTimeControl(AStartTime, AAddTime: TClockValue;
  AMoveCount: integer): RTimeControl;

function ClockValueToString(Val: TClockValue): string;

function TimeControlToString(const Control: RTimeControl): string;
function StringToTimeControl(const Str: string; out Control: RTimeControl): boolean;

function GetTimeString(const Data: RClockData): string;
function GetFullTimeString(const Data: RChessClock): string;

function IsTimeForfeit(const Data: RChessClock): boolean;
function IsInfinite(const Data: RChessClock): boolean;
procedure Decrement(var Data: RClockData; Delta: TClockValue);

// "Safe" methods to work with TClockValue
function IsTimeForfeit(Val: TClockValue): boolean;
procedure IncTime(var Val: TClockValue; Delta: TClockValue);
procedure DecTime(var Val: TClockValue; Delta: TClockValue);
function SecondsToClockValue(Val: extended): TClockValue;
function ClockValueToSeconds(Val: TClockValue): extended;
function ClockValueToSecondsInt(Val: TClockValue): int64;
function MilliSecondsToClockValue(Val: int64): TClockValue;
function ClockValueToMilliSeconds(Val: TClockValue): int64;

implementation

function MakeTimeControl(AStartTime, AAddTime: TClockValue;
  AMoveCount: integer): RTimeControl;
  // Packs RTimerControl into a record.
begin
  Result.StartTime := AStartTime;
  Result.AddTime := AAddTime;
  Result.MoveCount := AMoveCount;
end;

function ClockValueToString(Val: TClockValue): string;
  // Converts TClockValue to string.

  function IntToTimeString(I: integer): string;
    // Converts Integer to string with putting leading zeros.
  begin
    Result := IntToStr(I);
    while Length(Result) < 2 do
      Result := '0' + Result;
  end;

var
  Day, Hour, Min, Sec, TimeInSecs: integer;
begin
  // if time forfeit or infinite time - then specific cases
  if Val = InfVal then
    Exit(SInfiniteTime);
  if IsTimeForfeit(Val) then
    Exit(SOutOfTime);
  // otherwise, just convert time to string
  TimeInSecs := ClockValueToSecondsInt(Val);
  // calc values
  Sec := TimeInSecs mod 60;
  Min := (TimeInSecs mod (60 * 60)) div 60;
  Hour := (TimeInSecs mod (24 * 60 * 60)) div (60 * 60);
  Day := TimeInSecs div (24 * 60 * 60);
  // convert to string
  if Day = 0 then
    Result := Format(STimeFormat, [IntToTimeString(Hour),
      IntToTimeString(Min),
      IntToTimeString(Sec)])
  else
    Result := Format(SExtTimeFormat,
      [Day, IntToTimeString(Hour),
      IntToTimeString(Min),
      IntToTimeString(Sec)]);
end;

function TimeControlToString(const Control: RTimeControl): string;
  // Converts RTimeControl to string.
var
  S: string;
begin
  with Control do
  begin
    // if infinite - "-"
    if StartTime = InfVal then
      Exit('-');
    // otherwise, the following variants are allowed:
    // 1. <move count>/<time>[+<increment time>]
    // 2. <time>[+<increment time>]
    if MoveCount < 0 then
      S := IntToStr(ClockValueToSecondsInt(StartTime))  // for the rest of the game
    else
      S := IntToStr(MoveCount) + '/' + IntToStr(
        ClockValueToSecondsInt(StartTime));
    // for n moves
    // adding increment (if nessesary)
    if AddTime <> ZeroVal then
      S := S + '+' + IntToStr(ClockValueToSecondsInt(AddTime));
  end;
  Result := S;
end;

function StringToTimeControl(const Str: string; out Control: RTimeControl): boolean;
  // Converts string into RTimeControl. Returns True if success.
const
  Separators = [#0 .. #32];
var
  S, S2: string;
  I, P: integer;
  Q: integer;
begin
  // deleting separators
  S := '';
  for I := 1 to Length(Str) do
    if not (Str[I] in Separators) then
      S := S + Str[I];
  // if "-", "?", "" - then it's infinite time.
  if (S = '-') or (S = '?') or (S = '') then
  begin
    Control := MakeTimeControl(InfVal, ZeroVal, -1);
    Exit(True);
  end;
  // time is not infinite, we need to parse it.
  Result := True;
  Control := MakeTimeControl(InfVal, ZeroVal, -1);
  P := Pos('/', S);
  if P <> 0 then
  begin
    // parse move count
    S2 := Copy(S, 1, P - 1);
    Delete(S, 1, P);
    Val(S2, Control.MoveCount, I);
    if I <> 0 then
      Result := False;
    if Control.MoveCount <= 0 then
      Control.MoveCount := -1;
  end;
  P := Pos('+', S);
  if P <> 0 then
  begin
    // parse increment
    S2 := Copy(S, 1, P - 1);
    Delete(S, 1, P);
    Val(S, Q, I);
    Control.AddTime := SecondsToClockValue(Q);
    S := S2;
    if I <> 0 then
      Result := False;
  end;
  // parse time
  Val(S, Q, I);
  Control.StartTime := SecondsToClockValue(Q);
  if I <> 0 then
    Result := False;
end;

function GetTimeString(const Data: RClockData): string;
  // Converts RClockData into string.
begin
  Result := ClockValueToString(Data.Time);
end;

function GetFullTimeString(const Data: RChessClock): string;
  // Converts RChessClock into string.
var
  S: string;
begin
  S := '';
  case Data.Active of
    pcWhite: S := SActiveWhite;
    pcBlack: S := SActiveBlack;
  end;
  Result := Format(S, [GetTimeString(Data.Times[pcWhite]),
    GetTimeString(Data.Times[pcBlack])]);
end;

function IsTimeForfeit(const Data: RChessClock): boolean;
  // Returns True if forfeit on time.
begin
  with Data do
    Result := IsTimeForfeit(Times[Active].Time);
end;

function IsInfinite(const Data: RChessClock): boolean;
  // Returns True if the time is infinite.
begin
  with Data do
    Result := Times[Active].Time = InfVal;
end;

procedure Decrement(var Data: RClockData; Delta: TClockValue);
// Decreases time by Delta.
begin
  DecTime(Data.Time, Delta);
end;

// ----------------------------------------
// "Safe" methods to work with TClockValue.
// ----------------------------------------

function IsTimeForfeit(Val: TClockValue): boolean;
  // Returns True if forfeit on time.
begin
  Result := Val.Value < 0;
end;

procedure IncTime(var Val: TClockValue; Delta: TClockValue);
// Increases time by Delta.
begin
  if (Val = InfVal) or (Delta = InfVal) then
    Val := InfVal
  else
    Inc(Val.Value, Delta.Value);
end;

procedure DecTime(var Val: TClockValue; Delta: TClockValue);
// Decreases time by Delta.
begin
  if Val <> InfVal then
    Dec(Val.Value, Delta.Value);
end;

function SecondsToClockValue(Val: extended): TClockValue;
  // Converts seconds to TClockValue.
begin
  Result.Value := Round(Val * 1000);
end;

function ClockValueToSeconds(Val: TClockValue): extended;
  // Converts TClockValue to seconds.
begin
  Result := Val.Value / 1000;
end;

function ClockValueToSecondsInt(Val: TClockValue): int64;
  // Converts TClockValue to seconds (with rounding to Integer).
begin
  Result := Round(Val.Value / 1000);
end;

function MilliSecondsToClockValue(Val: int64): TClockValue;
  // Converts milliseconds to TClockValue.
begin
  Result.Value := Val;
end;

function ClockValueToMilliSeconds(Val: TClockValue): int64;
  // Converts TClockValue to milliseconds.
begin
  Result := Val.Value;
end;

{ TTimer }

constructor TTimer.Create;
begin
  inherited Create(nil);
end;

{ TClockValue }

class operator TClockValue.=(const A, B: TClockValue): boolean;
begin
  Result := A.Value = B.Value;
end;

{ RTimeControl }

class operator RTimeControl.=(A, B: RTimeControl): boolean;
begin
  Result := (A.StartTime = B.StartTime) and (A.AddTime = B.AddTime) and
    (A.MoveCount = B.MoveCount);
end;

{ RClockData }

class operator RClockData.=(A, B: RClockData): boolean;
begin
  Result := (A.Time = B.Time) and (A.MoveLeft = B.MoveLeft) and
    (A.ItemIndex = B.ItemIndex);
end;

{ RChessClock }

class operator RChessClock.=(A, B: RChessClock): boolean;
begin
  Result := (A.Times[pcWhite] = B.Times[pcWhite]) and
    (A.Times[pcBlack] = B.Times[pcBlack]) and (A.Active = B.Active);
end;

{ TTimeControl }

function TTimeControl.GetCount: integer;
begin
  Result := FList.Count;
end;

function TTimeControl.GetItems(I: integer): RTimeControl;
begin
  Result := FList.Items[I];
end;

function TTimeControl.GetTimeControlString: string;
var
  S: string;
  I: integer;
begin
  if FList.Count = 0 then
    Exit('-');
  S := '';
  for I := 0 to FList.Count - 1 do
  begin
    if I <> 0 then
      S := S + ':';
    S := S + TimeControlToString(FList.Items[I]);
  end;
  Result := S;
end;

procedure TTimeControl.SetItems(I: integer; AValue: RTimeControl);
begin
  FList.Items[I] := AValue;
  DoChange;
end;

procedure TTimeControl.SetTimeControlString(AValue: string);

  function TimeControlStringParser(S: string): boolean;
    // Parses TimeControlString, retruns True if success.
  var
    P: integer;
    Cntrl: RTimeControl;
    Res: boolean;
  begin
    // simple time controls are separated by ":".
    // ok, let's find ":"s and parse everything between them.
    S := S + ':';
    Result := False;
    P := Pos(':', S);
    while P <> 0 do
    begin
      Res := StringToTimeControl(Copy(S, 1, P - 1), Cntrl);
      Delete(S, 1, P);
      FList.Add(Cntrl);
      if not Res then
        Exit;
      P := Pos(':', S);
    end;
    Result := True;
  end;

var
  Res: boolean;
begin
  if AValue = TimeControlString then
    Exit;
  // clear
  FList.Clear;
  // parse
  Res := TimeControlStringParser(AValue);
  DoChange;
  // if not parsed - raise an exception
  if not Res then
    raise ETimeControlStringRead.Create(STimeControlStringRead);
end;

procedure TTimeControl.ChangeMove(var Data: RClockData);
// Changes Data as the clock have been flipped.
begin
  with Data do
  begin
    // decrease moves for next time control
    if MoveLeft > 0 then
      Dec(MoveLeft);
    // add increment
    IncTime(Time, Items[ItemIndex].AddTime);
    if MoveLeft = 0 then
    begin
      // new time control
      Inc(ItemIndex);
      if ItemIndex >= Count then
        ItemIndex := Count - 1;
      IncTime(Time, Items[ItemIndex].StartTime);
      MoveLeft := Items[ItemIndex].MoveCount;
    end;
  end;
end;

function TTimeControl.GetInitialTime: RClockData;
  // Returns the initial clock for this time control.
begin
  with Result do
  begin
    Time := Items[0].StartTime;
    ItemIndex := 0;
    MoveLeft := Items[0].MoveCount;
  end;
end;

procedure TTimeControl.Clear;
// Clears the time control.
begin
  SetTimeControlString('');
end;

constructor TTimeControl.Create;
begin
  FList := TTimeControlList.Create;
  Clear;
end;

destructor TTimeControl.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

{ TTimeControlPair }

function TTimeControlPair.GetTimeControls(C: TPieceColor): TTimeControl;
begin
  Result := FTimeControls[C];
end;

function TTimeControlPair.GetTimeControlString: string;
var
  WhiteStr, BlackStr: string;
begin
  // strings for sides
  WhiteStr := FTimeControls[pcWhite].TimeControlString;
  BlackStr := FTimeControls[pcBlack].TimeControlString;
  // if different for white and black - separate by "|"
  // if equal - output just one time control
  if WhiteStr <> BlackStr then
    Result := WhiteStr + '|' + BlackStr
  else
    Result := WhiteStr;
end;

procedure TTimeControlPair.SetTimeControlString(AValue: string);
var
  P: integer;
  Res: boolean;

  procedure SetTCS(S: string; C: TPieceColor);
  // Sets a time control string for just one side.
  begin
    try
      FTimeControls[C].TimeControlString := S;
    except
      on E: ETimeControlStringRead do
        Res := False
      else
        raise;
    end;
  end;

begin
  if AValue = TimeControlString then
    Exit;
  BeginUpdate;
  Res := True;
  P := Pos('|', AValue);
  if P = 0 then
  begin
    // no "|", equal for both sides.
    SetTCS(AValue, pcWhite);
    SetTCS(AValue, pcBlack);
  end
  else
  begin
    // set separately for white and separately for black.
    SetTCS(Copy(AValue, 1, P - 1), pcWhite);
    SetTCS(Copy(AValue, P + 1, Length(AValue) - P), pcBlack);
  end;
  EndUpdate;
  DoChange;
  // if error - raise an exception
  if not Res then
    raise ETimeControlStringRead.Create(STimeControlStringRead);
end;

procedure TTimeControlPair.Changer(Sender: TObject);
begin
  DoChange;
end;

procedure TTimeControlPair.ChangeMove(var Data: RChessClock);
// Changes Data as the clock have been flipped.
begin
  with Data do
  begin
    FTimeControls[Active].ChangeMove(Times[Active]);
    Active := not Active;
  end;
end;

function TTimeControlPair.GetInitialTime(Color: TPieceColor): RChessClock;
  // Returns the initial clock for this time control.
begin
  Result.Times[pcWhite] := FTimeControls[pcWhite].GetInitialTime;
  Result.Times[pcBlack] := FTimeControls[pcBlack].GetInitialTime;
  Result.Active := Color;
end;

procedure TTimeControlPair.Clear;
// Clears the time control.
begin
  SetTimeControlString('');
end;

constructor TTimeControlPair.Create;
begin
  inherited;
  FTimeControls[pcWhite] := TTimeControl.Create;
  FTimeControls[pcWhite].OnChange := @Changer;
  FTimeControls[pcBlack] := TTimeControl.Create;
  FTimeControls[pcBlack].OnChange := @Changer;
  Clear;
end;

destructor TTimeControlPair.Destroy;
begin
  FreeAndNil(FTimeControls[pcWhite]);
  FreeAndNil(FTimeControls[pcBlack]);
  inherited Destroy;
end;

{ TChessTimer }

procedure TChessTimer.SetClock(AValue: RChessClock);
begin
  if FClock = AValue then
    Exit;
  FClock := AValue;
  DoChange;
end;

procedure TChessTimer.SetPaused(AValue: boolean);
begin
  if FPaused = AValue then
    Exit;
  FPaused := AValue;
  if AValue then
    Pause
  else
    Resume;
  DoChange;
end;

procedure TChessTimer.Changer(Sender: TObject);
begin
  Restart;
end;

procedure TChessTimer.TimerTimer(Sender: TObject);
begin
  with FClock do
    Decrement(Times[Active],
      MilliSecondsToClockValue(FTimers[Active].Interval));
  DoChange;
end;

function TChessTimer.IsTimeForfeit: boolean;
  // Returns True if the active side forfeits on time.
begin
  Result := ChessTime.IsTimeForfeit(FClock);
end;

function TChessTimer.CanResume: boolean;
  // Returns True if timer can go.
begin
  Result := not (IsTimeForfeit or IsInfinite(FClock));
end;

procedure TChessTimer.DoChange;
begin
  // update pausing/resuming
  if FPaused then
    Pause
  else
    Resume;
  // event handlers
  if Assigned(FOnChange) then
    FOnChange(Self);
  if Assigned(FOnUpdate) then
    FOnUpdate(Self);
  if IsTimeForfeit then
    DoTimeForfeit(FClock.Active);
end;

procedure TChessTimer.DoTimeForfeit(Color: TPieceColor);
// Event handler when forfeit on time.
begin
  if FTimeForfeit then
    Exit;
  FTimeForfeit := True;
  Pause;
  if Assigned(FOnTimeForfeit) then
    FOnTimeForfeit(Self, Color);
end;

procedure TChessTimer.Pause;
// Pauses the timers.
begin
  FTimers[pcWhite].Enabled := False;
  FTimers[pcBlack].Enabled := False;
end;

procedure TChessTimer.Resume;
// Resumes the timers.
begin
  if CanResume then
  begin
    FTimers[FClock.Active].Enabled := True;
    FTimers[not FClock.Active].Enabled := False;
  end
  else
    Pause;
end;

procedure TChessTimer.FlipClock;
// Flips the clock (when active side has made a move).
begin
  if IsTimeForfeit then
    Exit;
  TimeControl.ChangeMove(FClock);
  DoChange;
end;

procedure TChessTimer.Restart;
// Restarts the timer.
begin
  FTimeForfeit := False;
  FClock := TimeControl.GetInitialTime(FInitialColor);
  DoChange;
end;

constructor TChessTimer.Create;
var
  C: TPieceColor;
begin
  FInitialColor := pcWhite;
  FPaused := True;
  FTimeForfeit := False;
  FTimeControl := TTimeControlPair.Create;
  FTimeControl.OnChange := @Changer;
  for C := Low(TPieceColor) to High(TPieceColor) do
  begin
    FTimers[C] := TTimer.Create;
    with FTimers[C] do
    begin
      Interval := 15; // timer accuracy is not high enough now !!!
      // TODO: Improve timer accuracy !!!
      Enabled := False;
      OnTimer := @TimerTimer;
    end;
  end;
  Restart;
end;

destructor TChessTimer.Destroy;
var
  C: TPieceColor;
begin
  for C := Low(TPieceColor) to High(TPieceColor) do
    FreeAndNil(FTimers[C]);
  FreeAndNil(FTimeControl);
  inherited Destroy;
end;

end.
