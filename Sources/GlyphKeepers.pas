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
    This unit contains a data module to store the button glyphs.
}
unit GlyphKeepers;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, FileUtil, Controls;

type

  { TGlyphKeeper }

  TGlyphKeeper = class(TDataModule)
    ImageList: TImageList;
  end;

var
  GlyphKeeper: TGlyphKeeper;

implementation

{$R *.lfm}

end.

