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
      EngineName = 'stockfish8.exe';
    {$ELSE}
      EngineName = 'stockfish8_x64.exe';
    {$ENDIF}
    EngineFilter = '*.exe';
    EngineDefExt = '.exe';
    {$DEFINE HAS_ENGINE_NAME}
  {$ENDIF}
  {$IFDEF LINUX}
    {$IFDEF CPUI386}
      EngineName = 'stockfish8';
    {$ELSE}
      EngineName = 'stockfish8_x64';
    {$ENDIF}
     EngineFilter = '*';
     EngineDefExt = '';
     {$DEFINE HAS_ENGINE_NAME}
  {$ENDIF}
  {$IFNDEF HAS_ENGINE_NAME}
    {$ERROR Please add nessesary constants for this platform.}
  {$ENDIF}

implementation

end.

