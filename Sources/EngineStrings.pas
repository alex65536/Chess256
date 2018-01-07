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
    This file contains string messages used by the engine subsystems. Also the
    default paths for chess engines are stored.
}
unit EngineStrings;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils;

resourcestring
  SEngineNotResponding = 'The chess engine is not responding and will be terminated.';
  SEngineFilter = 'UCI chess engines|%s';

const
  {$IFDEF WINDOWS}
    {$IFDEF CPUI386}
      EngineName1 = 'stockfish-i386.exe';
      EngineName2 = 'stockfish-i386.exe';
    {$ELSE}
      EngineName1 = 'stockfish-x86_64.exe';
      EngineName2 = 'stockfish-x86_64.exe';
    {$ENDIF}
    EngineFilter = '*.exe';
    EngineDefExt = '.exe';
    {$DEFINE HAS_ENGINE_NAME}
  {$ENDIF}
  {$IFDEF LINUX}
    {$IFDEF CPUI386}
      EngineName1 = 'stockfish-i386';
    {$ELSE}
      EngineName1 = 'stockfish-x86_64';
    {$ENDIF}
    EngineName2 = '/usr/games/stockfish';
    EngineFilter = '*';
    EngineDefExt = '';
    {$DEFINE HAS_ENGINE_NAME}
  {$ENDIF}
  {$IFNDEF HAS_ENGINE_NAME}
    {$ERROR Please add nessesary constants for this platform.}
  {$ENDIF}

function EngineName: string;

implementation

function EngineName: string;
begin
  if FileExists(EngineName1) then
    Result := EngineName1
  else
    Result := EngineName2;
end;

end.

