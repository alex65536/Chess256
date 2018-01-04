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
    This unit implements a debug console.
}
unit DebugConsole;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Classes, SysUtils, Forms, Graphics, Menus, uCmdBox, ApplicationForms, AvgLvlTree,
  About, Clipbrd, Process;

resourcestring
  SAlreadyReading = 'I am already reading some data!';
  SConsoleBegin = 'Chess 256 Debug Console' + LineEnding + 'Version %s' +
    LineEnding + 'Type "help" to get the list of commands.' +
    LineEnding + '----------------------------------------';
  SPrompt = 'Chess256>';
  SNoDesc = '<no description>';
  SInvalidCommand = 'Invalid command. Type "help" to get the list of commands.';
  SCommandDoesntExist = 'The command "%s" doesn''t exist.';
  SCommandHelp = 'Help on command "%s":' + LineEnding;
  SHelpHeader = 'To get more information on a command, ' +
    'type help <command name>.' + LineEnding + 'Commands list:';

  // Help description
  SHelpShortDesc = 'Shows this help.';
  SHelpDesc = '  The "help" command shows the list of commands.';
  // Exit description
  SExitShortDesc = 'Exits from the program.';
  SExitDesc = '  This command exits from the program.';
  // Clear description
  SClrShortDesc = 'Clears the console.';
  SClrDesc = '  This command clears the console.';

type
  EConsoleError = class(Exception);

  { TConsoleCommand }

  TConsoleCommand = class
  private
    FParams: TStringList;
    function GetCount: integer;
    function GetParams(I: integer): string;
  protected
    property Params[I: integer]: string read GetParams;
    property Count: integer read GetCount;
  public
    constructor Create(const AParams: TStringList);
    destructor Destroy; override;
    // Abstract methods, must be overridden
    function ShortDescription: string; virtual;
    function Description: string; virtual;
    procedure ProcessCommand; virtual; abstract;
  end;

  TConsoleCommandClass = class of TConsoleCommand;

  { THelpCommand }

  THelpCommand = class(TConsoleCommand)
  public
    function ShortDescription: string; override;
    function Description: string; override;
    procedure ProcessCommand; override;
  end;

  { TQuitCommand }

  TQuitCommand = class(TConsoleCommand)
    function ShortDescription: string; override;
    function Description: string; override;
    procedure ProcessCommand; override;
  end;

  { TClearCommand }

  TClearCommand = class(TConsoleCommand)
    function ShortDescription: string; override;
    function Description: string; override;
    procedure ProcessCommand; override;
  end;

  { TConsole }

  TConsole = class(TApplicationForm)
    CmdBox: TCmdBox;
    itemCopyToClipboard: TMenuItem;
    ConsolePopup: TPopupMenu;
    procedure CmdBoxInput(ACmdBox: TCmdBox; Input: string);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure itemCopyToClipboardClick(Sender: TObject);
  private
    FRead: boolean;
    FReadStr: string;
    procedure CmdBoxReadLn(ACmdBox: TCmdBox; Input: string);
  end;

var
  Console: TConsole;

procedure ShowDebugConsole;
procedure ConsoleWrite(const S: string);
procedure ConsoleWrite(const S: string; const Args: array of const);
procedure ConsoleWriteLn;
procedure ConsoleWriteLn(const S: string);
procedure ConsoleWriteLn(const S: string; const Args: array of const);
function ConsoleReadLn: string;
procedure RegisterCommand(const Command: string; AClass: TConsoleCommandClass);

implementation

var
  Commands: TStringToPointerTree;
  Reading: boolean = False;

procedure ShowDebugConsole;
// Shows the console.
begin
  if not Assigned(Console) then
    Exit;
  Console.Show;
end;

procedure ConsoleWrite(const S: string);
// Writes to the console.
begin
  if not Assigned(Console) then
    Exit;
  Console.CmdBox.Write(AdjustLineBreaks(S, tlbsCRLF));
end;

procedure ConsoleWrite(const S: string; const Args: array of const);
// Formatted output to the console.
begin
  ConsoleWrite(Format(S, Args));
end;

procedure ConsoleWriteLn;
// Makes a new line.
begin
  if not Assigned(Console) then
    Exit;
  Console.CmdBox.Writeln('');
end;

procedure ConsoleWriteLn(const S: string);
// Writes to the console and makes a new line.
begin
  if not Assigned(Console) then
    Exit;
  Console.CmdBox.Writeln(AdjustLineBreaks(S, tlbsCRLF));
end;

procedure ConsoleWriteLn(const S: string; const Args: array of const);
// Formatted output to the console with making a new line.
begin
  ConsoleWriteLn(Format(S, Args));
end;

function ConsoleReadLn: string;
  // Reads a string from the console.
  // Be careful with this, it uses Application.ProcessMessages!
begin
  if not Assigned(Console) then
    Exit;
  if Reading then
    raise EConsoleError.Create(SAlreadyReading); // cannot read two strings in one time!
  // reading
  // Console.CmdBoxReadLn method will put to Console.FRead True if read
  // and to Console.FReadStr the read string.
  Reading := True;
  // prepare console
  Console.FRead := False;
  Console.CmdBox.OnInput := @Console.CmdBoxReadLn;
  Console.CmdBox.StartRead(clSilver, clBlack, '', clSilver, clBlack);
  // read
  while not Console.FRead do
  begin
    // wait while not read
    Application.ProcessMessages;
    if Application.Terminated then
      Exit('');
  end;
  // finish reading
  Result := Console.FReadStr;
  Reading := False;
  Console.CmdBox.OnInput := @Console.CmdBoxInput;
end;

procedure RegisterCommand(const Command: string; AClass: TConsoleCommandClass);
// Registers a custom command (must be in "initialization" section)
begin
  Commands.Values[Command] := AClass;
end;

{$R *.lfm}

{ TConsoleCommand }

function TConsoleCommand.GetCount: integer;
begin
  Result := FParams.Count - 1;
end;

function TConsoleCommand.GetParams(I: integer): string;
begin
  Result := FParams[I];
end;

constructor TConsoleCommand.Create(const AParams: TStringList);
begin
  FParams := TStringList.Create;
  FParams.Assign(AParams);
  if FParams.Count = 0 then
    FParams.Add('');
end;

destructor TConsoleCommand.Destroy;
begin
  FreeAndNil(FParams);
  inherited Destroy;
end;

function TConsoleCommand.ShortDescription: string;
begin
  Result := SNoDesc;
end;

function TConsoleCommand.Description: string;
begin
  Result := SNoDesc;
end;

{ TClearCommand }

function TClearCommand.ShortDescription: string;
begin
  Result := SClrShortDesc;
end;

function TClearCommand.Description: string;
begin
  Result := SClrDesc;
end;

procedure TClearCommand.ProcessCommand;
begin
  Console.CmdBox.Clear;
end;

{ TQuitCommand }

function TQuitCommand.ShortDescription: string;
begin
  Result := SExitShortDesc;
end;

function TQuitCommand.Description: string;
begin
  Result := SExitDesc;
end;

procedure TQuitCommand.ProcessCommand;
begin
  Application.Terminate;
end;

{ THelpCommand }

function THelpCommand.ShortDescription: string;
begin
  Result := SHelpShortDesc;
end;

function THelpCommand.Description: string;
begin
  Result := SHelpDesc;
end;

procedure THelpCommand.ProcessCommand;

  procedure ShowAllHelp;
  var
    It: PStringToPointerTreeItem;
    StrList: TStringList;
    Cmd: TConsoleCommand;
  begin
    ConsoleWriteLn(SHelpHeader);
    StrList := TStringList.Create;
    for It in Commands do
      with It^ do
      begin
        StrList.Text := Name;
        Cmd := TConsoleCommandClass(Value).Create(StrList);
        ConsoleWriteLn(Format('  %10-s: %s', [Name, Cmd.ShortDescription]));
        FreeAndNil(Cmd);
      end;
    FreeAndNil(StrList);
  end;

  procedure ShowHelpOn(const Command: string);
  var
    StrList: TStringList;
    Cmd: TConsoleCommand;
  begin
    if not Commands.Contains(Command) then
      ConsoleWriteLn(Format(SCommandDoesntExist, [Command]))
    else
    begin
      StrList := TStringList.Create;
      StrList.Text := Command;
      Cmd := TConsoleCommandClass(Commands[Command]).Create(StrList);
      ConsoleWriteLn(Format(SCommandHelp, [Command]) + Cmd.Description);
      FreeAndNil(Cmd);
      FreeAndNil(StrList);
    end;
  end;

begin
  if Count = 0 then
    ShowAllHelp
  else
    ShowHelpOn(Params[1]);
end;

{ TConsole }

{$HINTS OFF}
procedure TConsole.CmdBoxInput(ACmdBox: TCmdBox; Input: string);
var
  StrList: TStringList;
  Cmd: TConsoleCommand;
begin
  StrList := TStringList.Create;
  CommandToList(Input, StrList);
  // check the command
  if (StrList.Count = 0) or not (Commands.Contains(StrList[0])) then
    ConsoleWriteLn(SInvalidCommand)
  else
  begin
    // execute the command
    Cmd := TConsoleCommandClass(Commands[StrList[0]]).Create(StrList);
    Cmd.ProcessCommand;
    FreeAndNil(Cmd);
  end;
  FreeAndNil(StrList);
  // re-launch reading
  CmdBox.StartRead(clSilver, clBlack, SPrompt, clSilver, clBlack);
end;

{$HINTS ON}

procedure TConsole.FormCreate(Sender: TObject);
begin
  CmdBox.Font.Size := 10;
  CmdBox.StartRead(clSilver, clBlack, SPrompt, clSilver, clBlack);
  ConsoleWriteLn(Format(SConsoleBegin, [AboutBox.GetAppVersion]));
end;

procedure TConsole.FormDestroy(Sender: TObject);
begin
  Console := nil;
end;

procedure TConsole.FormHide(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TConsole.itemCopyToClipboardClick(Sender: TObject);
begin
  Clipboard.AsText := CmdBox.Text; // to make it work, I modified TCmdBox a little ...
end;

{$HINTS OFF}
procedure TConsole.CmdBoxReadLn(ACmdBox: TCmdBox; Input: string);
begin
  FRead := True;
  FReadStr := Input;
end;

{$HINTS ON}

initialization
  Commands := TStringToPointerTree.Create(False);
  Commands.FreeValues := False;
  RegisterCommand('help', THelpCommand);
  RegisterCommand('exit', TQuitCommand);
  RegisterCommand('quit', TQuitCommand);
  RegisterCommand('clr', TClearCommand);

finalization
  FreeAndNil(Commands);

end.
