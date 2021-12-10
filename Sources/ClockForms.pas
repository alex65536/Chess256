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
    This unit contains a form that displays chess clock.
}
unit ClockForms;

{$I CompilerDirectives.inc}

interface

uses
  ActnList, ApplicationForms, ChessClock, ChessTime;

type

  { TClockForm }

  TClockForm = class(TApplicationForm)
    ClockOrientationAction: TAction;
    ActionList: TActionList;
    VisualClock: TVisualChessClock;
    procedure ClockOrientationActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function GetClock: TChessTimer;
  public
    property Clock: TChessTimer read GetClock;
  end;

var
  ClockForm: TClockForm;

implementation

{$R *.lfm}

{ TClockForm }

procedure TClockForm.ClockOrientationActionExecute(Sender: TObject);
begin
  with VisualClock do
    if Orientation = coVertical then
      Orientation := coHorizontal
    else
      Orientation := coVertical;
end;

procedure TClockForm.FormCreate(Sender: TObject);
begin
  VisualClock.Orientation := coVertical;
end;

function TClockForm.GetClock: TChessTimer;
begin
  Result := VisualClock.Clock;
end;

end.
