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
    This unit was used to scale the controls for HiDPI support. In the times of
    1.6.x there was no such thing in LCL. In 1.8, HiDPI support was introduced,
    so this unit will be removed from the code base of Chess 256 very soon,
    because now it is not necessary.
}

// TODO : Replace ScaleDPI unit with a LCL solution to support HiDPI.
unit ScaleDPI deprecated 'LCL now supprts HiDPI, so don''t use this unit';

{$I CompilerDirectives.inc}

interface

uses
  Forms, Controls, Graphics;

const
  WasDPI = 96;

procedure HighDPI(FromDPI: integer);
procedure DoScaleDPI(Control: TControl; FromDPI: integer);
procedure DoScaleDPI(Control: TControl);

implementation

// most of the code was taken from the Lazarus Wiki
// http://wiki.freepascal.org/High_DPI

procedure HighDPI(FromDPI: integer);
var
  I: integer;
begin
  if Screen.PixelsPerInch = FromDPI then
    Exit;
  for I := 0 to Screen.FormCount - 1 do
    DoScaleDPI(Screen.Forms[I], FromDPI);
end;

procedure DoScaleDPI(Control: TControl; FromDPI: integer);
var
  i: integer;
  WinControl: TWinControl;
begin
  if Screen.PixelsPerInch = FromDPI then
    Exit;

  with Control do
  begin
    Left := ScaleX(Left, FromDPI);
    Top := ScaleY(Top, FromDPI);
    Width := ScaleX(Width, FromDPI);
    Height := ScaleY(Height, FromDPI);
  end;

  if Control is TWinControl then
  begin
    WinControl := TWinControl(Control);
    if WinControl.ControlCount = 0 then
      Exit;

    with WinControl.BorderSpacing do
    begin
      Left := ScaleX(Around + Left, FromDPI);
      Right := ScaleX(Around + Right, FromDPI);
      Top := ScaleY(Around + Top, FromDPI);
      Bottom := ScaleY(Around + Bottom, FromDPI);
      Around := 0;
    end;

    with WinControl.ChildSizing do
    begin
      HorizontalSpacing := ScaleX(HorizontalSpacing, FromDPI);
      LeftRightSpacing := ScaleX(LeftRightSpacing, FromDPI);
      TopBottomSpacing := ScaleY(TopBottomSpacing, FromDPI);
      VerticalSpacing := ScaleY(VerticalSpacing, FromDPI);
    end;

    for i := 0 to WinControl.ControlCount - 1 do
      DoScaleDPI(WinControl.Controls[i], FromDPI);
  end;
end;

procedure DoScaleDPI(Control: TControl);
begin
  DoScaleDPI(Control, WasDPI);
end;

end.
