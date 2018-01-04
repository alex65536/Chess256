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
    This unit contains the biggest "brick" for configuring the chess clock -
    a pair of configurations for black and for white.
}
unit TimerConfigurePairs;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, Forms, StdCtrls, TimerConfigurers, ChessTime;

const
  SBothGroup = 'White and Black';
  SWhiteGroup = 'White';

type

  { TTimerConfigurePair }

  TTimerConfigurePair = class(TFrame)
    BlackGroup: TGroupBox;
    SameTimeCheck: TCheckBox;
    BlackConfigurer: TTimerConfigure;
    WhiteConfigurer: TTimerConfigure;
    WhiteGroup: TGroupBox;
    procedure SameTimeCheckChange(Sender: TObject);
  private
    FBlackCanInfiniteTime: boolean;
    FSameTime: boolean;
    FWhiteCanInfiniteTime: boolean;
    // Getters / Setters
    function GetTimeControlString: string;
    procedure SetWhiteCanInfiniteTime(AValue: boolean);
    procedure SetBlackCanInfiniteTime(AValue: boolean);
    procedure SetSameTime(AValue: boolean);
    procedure SetTimeControlString(AValue: string);
    // Other methods
    procedure UpdateCanInfiniteTime;
  public
    // Properties
    property WhiteCanInfiniteTime: boolean read FWhiteCanInfiniteTime
      write SetWhiteCanInfiniteTime;
    property BlackCanInfiniteTime: boolean read FBlackCanInfiniteTime
      write SetBlackCanInfiniteTime;
    property TimeControlString: string read GetTimeControlString
      write SetTimeControlString;
    property SameTime: boolean read FSameTime write SetSameTime;
    // Methods
    constructor Create(TheOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

{ TTimerConfigurePair }

procedure TTimerConfigurePair.SameTimeCheckChange(Sender: TObject);
begin
  SetSameTime(SameTimeCheck.Checked);
  DoOnResize;
end;

function TTimerConfigurePair.GetTimeControlString: string;
var
  AControl: TTimeControlPair;
begin
  AControl := TTimeControlPair.Create;
  try
    with AControl do
    begin
      if SameTime then
        BlackConfigurer.TimeControlString := WhiteConfigurer.TimeControlString;
      WhiteTimeControl.TimeControlString := WhiteConfigurer.TimeControlString;
      BlackTimeControl.TimeControlString := BlackConfigurer.TimeControlString;
      Result := TimeControlString;
    end;
  finally
    FreeAndNil(AControl);
  end;
end;

procedure TTimerConfigurePair.SetWhiteCanInfiniteTime(AValue: boolean);
begin
  if FWhiteCanInfiniteTime = AValue then
    Exit;
  FWhiteCanInfiniteTime := AValue;
  UpdateCanInfiniteTime;
end;

procedure TTimerConfigurePair.SetBlackCanInfiniteTime(AValue: boolean);
begin
  if FBlackCanInfiniteTime = AValue then
    Exit;
  FBlackCanInfiniteTime := AValue;
  UpdateCanInfiniteTime;
end;

procedure TTimerConfigurePair.SetSameTime(AValue: boolean);
begin
  if FSameTime = AValue then
    Exit;
  FSameTime := AValue;
  SameTimeCheck.Checked := FSameTime;
  // update the configurers
  DisableAutoSizing;
  if not AValue then
    BlackConfigurer.TimeControlString := WhiteConfigurer.TimeControlString;
  BlackGroup.Visible := not AValue;
  if AValue then
    WhiteGroup.Caption := SBothGroup
  else
    WhiteGroup.Caption := SWhiteGroup;
  UpdateCanInfiniteTime;
  EnableAutoSizing;
end;

procedure TTimerConfigurePair.SetTimeControlString(AValue: string);
var
  AControl: TTimeControlPair;
begin
  AControl := TTimeControlPair.Create;
  DisableAutoSizing;
  try
    with AControl do
    begin
      TimeControlString := AValue;
      SameTime := (WhiteTimeControl.TimeControlString =
        BlackTimeControl.TimeControlString);
      WhiteConfigurer.TimeControlString := WhiteTimeControl.TimeControlString;
      BlackConfigurer.TimeControlString := BlackTimeControl.TimeControlString;
    end;
  finally
    EnableAutoSizing;
    FreeAndNil(AControl);
  end;
end;

procedure TTimerConfigurePair.UpdateCanInfiniteTime;
// Updates .CanInfiniteTime to configurers.
var
  Temp: boolean;
begin
  if FSameTime then
  begin
    Temp := FWhiteCanInfiniteTime and FBlackCanInfiniteTime;
    WhiteConfigurer.CanInfiniteTime := Temp;
    BlackConfigurer.CanInfiniteTime := Temp;
  end
  else
  begin
    WhiteConfigurer.CanInfiniteTime := FWhiteCanInfiniteTime;
    BlackConfigurer.CanInfiniteTime := FBlackCanInfiniteTime;
  end;
end;

constructor TTimerConfigurePair.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FSameTime := True;
  FWhiteCanInfiniteTime := True;
  FBlackCanInfiniteTime := True;
end;

end.
