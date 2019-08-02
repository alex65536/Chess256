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
    This unit implements classes that allow to "talk" with a chess engine.
}
unit EngineProcesses;

{$I CompilerDirectives.inc}
{$B-}

interface

//{$DEFINE USELOG}
// Uncomment if you want to write to log the communication process between the
// application and the engine processes.

uses
  Classes, SysUtils, Process, AsyncProcess, AvgLvlTree;

resourcestring
  SCannotExecute = 'Failed to execute "%s".';

type
  EConsoleProcess = class(Exception);

  TReadCommandEvent = procedure(Sender: TObject; S: string) of object;

  { TConsoleProcess }

  TConsoleProcess = class
  private
    FOnReadLine: TReadCommandEvent;
    FOnTerminate: TNotifyEvent;
    FProcess: TAsyncProcess;
    FRemainder: string;
    FTerminateOnDestroy: boolean;
    FTerminated: boolean;
    // Event handlers
    procedure ProcessReadData(Sender: TObject);
    procedure ProcessTerminate(Sender: TObject);
    // Other methods
    procedure LaunchProcess;
    procedure PushStr(S: string);
  protected
    procedure DoTerminate;
    procedure DoReadLine(S: string); virtual;
  public
    // Properties
    property TerminateOnDestroy: boolean read FTerminateOnDestroy
      write FTerminateOnDestroy;
    property Process: TAsyncProcess read FProcess;
    // Events
    property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
    property OnReadLine: TReadCommandEvent read FOnReadLine write FOnReadLine;
    // Methods
    procedure WriteLine(S: string);
    procedure TryRead;
    constructor Create(const ExeName: string);
    destructor Destroy; override;
  end;

  { TEngineCommand }

  TEngineCommand = class
  public
    function GetCommandString: string; virtual; abstract;
  end;

  { TEngineMessage }

  TEngineMessage = class
  public
    procedure ParseParameters(Params: TStringList); virtual; abstract;
    constructor Create(Params: TStringList);
    constructor Create; virtual;
    function DebugStr: string; virtual; // debug function
  end;

  TEngineMessageClass = class of TEngineMessage;

  TEngineMessageReceiver = procedure(Sender: TObject;
    AMessage: TEngineMessage) of object;

  { TEngineProcess }

  TEngineProcess = class(TConsoleProcess)
  private
    FMessages: TStringToPointerTree;
    FMsgReceiver: TEngineMessageReceiver;
  protected
    // Event callers
    procedure DoReadLine(S: string); override;
    procedure DoReceiveMessage(AMessage: TEngineMessage); virtual;
    // Message work staff
    function ExtractEngineMessage(const S: string): TEngineMessage;
    procedure RegisterEngineMessage(const Name: string; AClass: TEngineMessageClass);
    procedure RegisterMessages; virtual;
  public
    // Events
    property MsgReceiver: TEngineMessageReceiver read FMsgReceiver write FMsgReceiver;
    // Methods
    procedure SendCommand(ACommand: TEngineCommand);
    constructor Create(const ExeName: string);
    destructor Destroy; override;
  end;

function MsgParamsToStrList(Params: string): TStringList;

implementation

function MsgParamsToStrList(Params: string): TStringList;
  // Converts message parameters into a string list.
const
  WhiteSpace = [' ', #9];
var
  I: integer;
  P: integer;
begin
  Params += ' ';
  Result := TStringList.Create;
  P := 1;
  // message parameters are separated with spaces
  // find the spaces and copy sequences between them
  for I := 1 to Length(Params) do
    if Params[I] in WhiteSpace then
    begin
      if P <> I then
        Result.Add(Copy(Params, P, I - P));
      P := I + 1;
    end;
end;

{$IFDEF USELOG}
var
  LogFile: TextFile;

{$ENDIF}

{ TConsoleProcess }

procedure TConsoleProcess.ProcessReadData(Sender: TObject);
var
  Cnt: integer;
  S: string;
begin
  Cnt := FProcess.NumBytesAvailable;
  if Cnt = 0 then
    Exit;
  SetLength(S, Cnt);
  FProcess.Output.Read(S[1], Cnt);
  PushStr(S);
end;

procedure TConsoleProcess.ProcessTerminate(Sender: TObject);
begin
  DoTerminate;
end;

procedure TConsoleProcess.LaunchProcess;
// Launches the process.
begin
  try
    FProcess.Active := True;
  except
    raise EConsoleProcess.CreateFmt(SCannotExecute, [FProcess.Executable]);
  end;
end;

procedure TConsoleProcess.PushStr(S: string);
// Parses FRemainder to lines.
// All the lines except are put onto DoReadLine
// The last line stays in FRemainder.
const
  LineEndChar = #10;
var
  I, P: integer;
begin
  FRemainder := AdjustLineBreaks(FRemainder + S, tlbsCR);
  P := 1;
  for I := 1 to Length(FRemainder) do
    if FRemainder[I] = LineEndChar then
    begin
      // add the line
      DoReadLine(Copy(FRemainder, P, I - P));
      P := I + 1;
    end;
  // remove all except last (incomplete) line
  Delete(FRemainder, 1, P - 1);
end;

procedure TConsoleProcess.DoTerminate;
// Called when process was terminated.
begin
  if FTerminated then
    Exit;
  FTerminated := True;
  if Assigned(FOnTerminate) then
    FOnTerminate(Self);
end;

procedure TConsoleProcess.DoReadLine(S: string);
// Called when read a line from the process.
begin
  if Assigned(FOnReadLine) then
    FOnReadLine(Self, S);
end;

procedure TConsoleProcess.WriteLine(S: string);
// Writes a line to the process.
begin
  {$IFDEF USELOG}
  WriteLn(LogFile, FProcess.Executable + ' <- Write "' + S + '"');
  Flush(LogFile);
  {$ENDIF}
  S += LineEnding;
  FProcess.Input.Write(S[1], Length(S));
end;

procedure TConsoleProcess.TryRead;
// Tries to read lines from the console.
// Can be used if TAsyncProcess.OnReadData event is not working.
begin
  if not FProcess.Active then
    DoTerminate;
  ProcessReadData(Self);
end;

constructor TConsoleProcess.Create(const ExeName: string);
begin
  FTerminated := False;
  FProcess := TAsyncProcess.Create(nil);
  FProcess.Executable := ExeName;
  FProcess.Options := [poUsePipes, poNoConsole];
  FProcess.ShowWindow := swoNone;
  FProcess.OnReadData := @ProcessReadData;
  FProcess.OnTerminate := @ProcessTerminate;
  FTerminateOnDestroy := True;
  LaunchProcess;
end;

destructor TConsoleProcess.Destroy;
begin
  {$IFDEF USELOG}
  WriteLn(LogFile, FProcess.Executable + ' <- kill(', FTerminateOnDestroy, ')');
  Flush(LogFile);
  {$ENDIF}
  if FTerminateOnDestroy then
    FProcess.Active := False;
  FreeAndNil(FProcess);
  inherited Destroy;
end;

{ TEngineMessage }

constructor TEngineMessage.Create(Params: TStringList);
begin
  Create;
  ParseParameters(Params);
end;

constructor TEngineMessage.Create;
begin
end;

function TEngineMessage.DebugStr: string;
begin
  Result := ClassName;
end;

{ TEngineProcess }

procedure TEngineProcess.DoReadLine(S: string);
var
  Msg: TEngineMessage;
begin
  {$IFDEF USELOG}
  WriteLn(LogFile, FProcess.Executable + ' -> Read "' + S + '"');
  Flush(LogFile);
  {$ENDIF}
  Msg := ExtractEngineMessage(S);
  if Msg = nil then
  begin
    // it's not a message
    inherited DoReadLine(S);
  end
  else
  begin
    // it's a message, pass it to the MsgReceiver.
    try
      DoReceiveMessage(Msg);
    finally
      FreeAndNil(Msg);
    end;
  end;
end;

procedure TEngineProcess.DoReceiveMessage(AMessage: TEngineMessage);
// Called when received a message from the process.
begin
  if Assigned(FMsgReceiver) then
    FMsgReceiver(Self, AMessage);
end;

function TEngineProcess.ExtractEngineMessage(const S: string): TEngineMessage;
  // Converts a string into an engine message.
  // Returns the message if success, otherwise, returns Nil.
var
  StrList: TStringList;
begin
  // parsing string
  StrList := MsgParamsToStrList(S);
  // finding out what message class it is
  if (StrList.Count = 0) or (not FMessages.Contains(StrList[0])) then
  begin
    // it's definitely not a message
    FreeAndNil(StrList);
    Result := nil;
    Exit;
  end;
  // found a message class, let's parse the message!
  Result := TEngineMessageClass(FMessages[StrList[0]]).Create;
  try
    Result.ParseParameters(StrList);
  except
    // if something has gone wrong while parsing, just return Nil.
    FreeAndNil(Result);
    FreeAndNil(StrList);
    Exit;
  end;
  FreeAndNil(StrList);
end;

procedure TEngineProcess.RegisterEngineMessage(const Name: string;
  AClass: TEngineMessageClass);
// Registers a message class.
begin
  FMessages.Values[Name] := AClass;
end;

procedure TEngineProcess.RegisterMessages;
// You must override RegisterMessages method and register here all
// the engine messages using RegisterEngineMessage method.
begin
end;

procedure TEngineProcess.SendCommand(ACommand: TEngineCommand);
// Sends a command to the engine.
begin
  try
    WriteLine(ACommand.GetCommandString);
  finally
    FreeAndNil(ACommand);
  end;
end;

constructor TEngineProcess.Create(const ExeName: string);
begin
  inherited Create(ExeName);
  FMessages := TStringToPointerTree.Create(False);
  FMessages.FreeValues := False;
  RegisterMessages;
end;

destructor TEngineProcess.Destroy;
begin
  FreeAndNil(FMessages);
  inherited Destroy;
end;

{$IFDEF USELOG}
initialization
  AssignFile(LogFile, 'ProcessTalk.log');
  Rewrite(LogFile);

finalization
  Close(LogFile);
{$ENDIF}

end.
