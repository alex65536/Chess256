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
    This unit contains some utilities to work with NAGs (Numeric Annotation
    Glyphs). Also, the characters for some NAGs are defined (see NAGValues.inc
    for them).
}
unit NAGUtils;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  ChessRules;

{$I NAGValues.inc}

function ConvertNAG(NAG: byte; Color: TPieceColor): byte;
function CanAddNAG(NAG: byte): boolean;

implementation

function ConvertNAG(NAG: byte; Color: TPieceColor): byte;
  // Make the NAG for color Color.
begin
  if NAGStrings[NAG] = '' then
    Exit(NAG);
  if (NAG <> 0) and (Color = pcWhite) and (NAGStrings[NAG] = NAGStrings[NAG - 1]) then
    Dec(NAG);
  if (NAG <> 255) and (Color = pcBlack) and (NAGStrings[NAG] = NAGStrings[NAG + 1])
  then
    Inc(NAG);
  Result := NAG;
end;

function CanAddNAG(NAG: byte): boolean;
  // Returns True if this NAG can be added to NAG selector.
begin
  Result := (NAGStrings[NAG] <> '') and (ConvertNAG(NAG, pcWhite) = NAG);
end;

end.
