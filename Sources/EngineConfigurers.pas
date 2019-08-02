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
    This unit implements an abstract class for configuring a chess engine.
}
unit EngineConfigurers;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, ChessEngines, AvgLvlTree;

type
  TUpdateOptionsEvent = procedure(Sender: TObject; var ApplyOptions: boolean) of object;

  { TEngineConfigurer }

  TEngineConfigurer = class
  private
    FEngine: TAbstractChessEngine;
    FOnUpdateOptions: TUpdateOptionsEvent;
  public
    property OnUpdateOptions: TUpdateOptionsEvent
      read FOnUpdateOptions write FOnUpdateOptions;
    property Engine: TAbstractChessEngine read FEngine write FEngine;
    // Abstract methods
    function Execute: boolean; virtual; abstract;
  end;

  TEngineConfigurerClass = class of TEngineConfigurer;

function CanExecuteConfigurer(AEngine: TAbstractChessEngine): boolean;
function ExecuteConfigurer(AEngine: TAbstractChessEngine;
  OnUpdateOptions: TUpdateOptionsEvent): boolean;
procedure RegisterConfigurer(EngClass: TChessEngineClass;
  ConfClass: TEngineConfigurerClass);
function GetConfigurer(EngClass: TChessEngineClass): TEngineConfigurerClass;

implementation

var
  ConfMap: TPointerToPointerTree;

function CanExecuteConfigurer(AEngine: TAbstractChessEngine): boolean;
  // Returns True if we can launch a configurer for AEngine.
var
  ConfClass: TEngineConfigurerClass;
begin
  Result := False;
  if (AEngine = nil) or AEngine.Terminated then
    Exit;
  ConfClass := GetConfigurer(TChessEngineClass(AEngine.ClassType));
  if ConfClass = nil then
    Exit;
  Result := True;
end;

function ExecuteConfigurer(AEngine: TAbstractChessEngine;
  OnUpdateOptions: TUpdateOptionsEvent): boolean;
  // Executes a configurer for AEngine; returns True if success.
var
  Configurer: TEngineConfigurer;
begin
  Result := False;
  // check
  if not CanExecuteConfigurer(AEngine) then
    Exit;
  // execute
  Configurer := GetConfigurer(TChessEngineClass(AEngine.ClassType)).Create;
  Configurer.Engine := AEngine;
  Configurer.OnUpdateOptions := OnUpdateOptions;
  try
    Result := Configurer.Execute;
  finally
    FreeAndNil(Configurer);
  end;
end;

procedure RegisterConfigurer(EngClass: TChessEngineClass;
  ConfClass: TEngineConfigurerClass);
// Bind a configurer class to an engine class.
begin
  ConfMap[EngClass] := ConfClass;
end;

function GetConfigurer(EngClass: TChessEngineClass): TEngineConfigurerClass;
  // Returns a configurer class that was binded to a given engine class.
  // If no configurer class was binded, returns Nil.
begin
  if ConfMap.Contains(EngClass) then
    Result := TEngineConfigurerClass(ConfMap[EngClass])
  else
    Result := nil;
end;

initialization
  ConfMap := TPointerToPointerTree.Create;

finalization
  FreeAndNil(ConfMap);

end.
