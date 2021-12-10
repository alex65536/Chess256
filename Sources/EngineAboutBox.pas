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
    This unit implements the About box for engines.
}
unit EngineAboutBox;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, StdCtrls, ExtCtrls, ChessEngines, ApplicationForms;

resourcestring
  SAboutEngineCaption = 'About %s...';
  SEngineAuthor = 'Author: %s';
  SEnginePath = 'Path to the engine:' + LineEnding + '"%s"';

type

  { TAboutEngine }

  TAboutEngine = class(TApplicationForm)
    Bevel1: TBevel;
    EngineAuthor: TLabel;
    EngineName: TLabel;
    MainPanel: TPanel;
    OKBtn: TButton;
    Panel: TPanel;
    procedure FormShow(Sender: TObject);
  private
    FEngine: TAbstractChessEngine;
  end;

var
  AboutEngine: TAboutEngine;

procedure ShowAboutEngine(AEngine: TAbstractChessEngine);

implementation

procedure ShowAboutEngine(AEngine: TAbstractChessEngine);
// Shows a about box about the engine.
begin
  AboutEngine := TAboutEngine.Create(nil);
  try
    AboutEngine.FEngine := AEngine;
    AboutEngine.ShowModal;
  finally
    FreeAndNil(AboutEngine);
  end;
end;

{$R *.lfm}

{ TAboutEngine }

procedure TAboutEngine.FormShow(Sender: TObject);
begin
  if Assigned(FEngine) then
  begin
    DisableAutoSizing;
    Caption := Format(SAboutEngineCaption, [FEngine.Name]);
    EngineName.Caption := FEngine.Name;
    EngineAuthor.Caption := Format(SEngineAuthor, [FEngine.Author]);
    EnableAutoSizing;
  end;
end;

end.

