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
    This unit contains some utilities for Chess 256.
}
unit ChessUtils;

{$I CompilerDirectives.inc}

interface

uses
  Classes;

type

  { TChessObject }

  TChessObject = class
  private
    FDestroying: boolean;
    FOnChange: TNotifyEvent;
    FUpdating: integer;
    procedure SetOnChange(AValue: TNotifyEvent);
  protected
    function Updating: boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
  public
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
    constructor Create;
    procedure BeforeDestruction; override;
    procedure DoChange; virtual;
  end;

implementation

{ TChessObject }

procedure TChessObject.SetOnChange(AValue: TNotifyEvent);
begin
  if FOnChange = AValue then
    Exit;
  FOnChange := AValue;
end;

function TChessObject.Updating: boolean;
  // Returns True if DoChange is locked.
begin
  Result := (FUpdating <> 0) or FDestroying;
end;

procedure TChessObject.BeginUpdate;
// Locks DoChange.
begin
  Inc(FUpdating);
end;

procedure TChessObject.EndUpdate;
// Unlocks DoChange.
begin
  Dec(FUpdating);
  if FUpdating < 0 then
    FUpdating := 0;
end;

procedure TChessObject.DoChange;
// OnChange event caller.
begin
  if Updating then
    Exit;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TChessObject.Create;
begin
  FUpdating := 0;
  FDestroying := False;
end;

procedure TChessObject.BeforeDestruction;
begin
  inherited BeforeDestruction;
  FDestroying := True;
end;

end.
