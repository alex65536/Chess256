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
    This unit contains some utilities for Chess 256 GUI.
}
unit ChessGUIUtils;

{$I CompilerDirectives.inc}

interface

uses
  Controls, Forms;

const
  DefaultChessFontSize = 11;

function GetDefaultChessFont: string;
function GetActualHeight(Control: TControl): integer;
function GetActualWidth(Control: TControl): integer;

property DefaultChessFont: String read GetDefaultChessFont;

implementation

const
  // Fonts that support UTF-8 & chess characters well.
  // TODO : Extend this list for other OSes.
  {$IFDEF WINDOWS}
  PreferredFonts: array [0 .. 0] of string = ('Arial Unicode MS');
  {$ELSE}
  PreferredFonts: array [0 .. 0] of string = ('<no fonts>');
  {$ENDIF}

var
  FDefaultChessFont: string;

procedure InitDefaultChessFont;
// Finds a suitable font to be default chess font.
var
  I, J: integer;
begin
  FDefaultChessFont := 'default';
  for I := Low(PreferredFonts) to High(PreferredFonts) do
    for J := 0 to Screen.Fonts.Count - 1 do
      if Screen.Fonts[J] = PreferredFonts[I] then
      begin
        FDefaultChessFont := Screen.Fonts[J];
        Exit;
      end;
end;

function GetDefaultChessFont: string;
  // Returns default chess font name.
begin
  Result := FDefaultChessFont;
end;

function GetActualHeight(Control: TControl): integer;
  // Returns the height of the control (with BorderSpacing).
begin
  with Control.BorderSpacing do
    Result := Control.Height + 2 * Around + Top + Bottom;
end;

function GetActualWidth(Control: TControl): integer;
  // Returns the width of the control (with BorderSpacing).
begin
  with Control.BorderSpacing do
    Result := Control.Width + 2 * Around + Left + Right;
end;

initialization
  InitDefaultChessFont;

end.
