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
    This unit implements a component to edit time control for one of the sides.
}
unit TimerConfigurers;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, Forms, ExtCtrls, Buttons, ActnList, ChessTime,
  TimerConfigurePanels, FGL;

type
  TTimerConfigurePanelList = specialize TFPGObjectList<TTimerConfigurePanel>;

  { TTimerConfigure }

  TTimerConfigure = class(TFrame)
    ClearAction: TAction;
    EraseAction: TAction;
    AddAction: TAction;
    ActionList: TActionList;
    AddButton: TBitBtn;
    ClearButton: TBitBtn;
    EraseButton: TBitBtn;
    Panel: TPanel;
    ControlPanel: TPanel;
    procedure AddActionExecute(Sender: TObject);
    procedure AddActionUpdate(Sender: TObject);
    procedure ClearActionExecute(Sender: TObject);
    procedure ClearActionUpdate(Sender: TObject);
    procedure EraseActionExecute(Sender: TObject);
    procedure EraseActionUpdate(Sender: TObject);
  private
    FCanInfiniteTime: boolean;
    FList: TTimerConfigurePanelList;
    // Getters / Setters
    function GetTimeControlString: string;
    procedure SetCanInfiniteTime(AValue: boolean);
    procedure SetTimeControlString(AValue: string);
    // Other methods
    function AddPanel: TTimerConfigurePanel;
  public
    // Properties
    property TimeControlString: string read GetTimeControlString
      write SetTimeControlString;
    property CanInfiniteTime: boolean read FCanInfiniteTime write SetCanInfiniteTime;
    // Actions
    function CanAdd: boolean;
    procedure Add;
    function CanErase: boolean;
    procedure Erase;
    function CanClear: boolean;
    procedure Clear;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.lfm}

{ TTimerConfigure }

procedure TTimerConfigure.ClearActionExecute(Sender: TObject);
begin
  Clear;
end;

procedure TTimerConfigure.ClearActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := CanClear;
end;

procedure TTimerConfigure.AddActionExecute(Sender: TObject);
begin
  Add;
end;

procedure TTimerConfigure.AddActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := CanAdd;
end;

procedure TTimerConfigure.EraseActionExecute(Sender: TObject);
begin
  Erase;
end;

procedure TTimerConfigure.EraseActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := CanErase;
end;

function TTimerConfigure.GetTimeControlString: string;
var
  ATimeControl: TTimeControl;
  I: integer;
begin
  ATimeControl := TTimeControl.Create;
  try
    ATimeControl.List.Clear;
    for I := 0 to FList.Count - 1 do
      ATimeControl.List.Add(FList[I].TimeControl);
    Result := ATimeControl.TimeControlString;
  finally
    FreeAndNil(ATimeControl);
  end;
end;

procedure TTimerConfigure.SetCanInfiniteTime(AValue: boolean);
var
  I: integer;
begin
  if FCanInfiniteTime = AValue then
    Exit;
  FCanInfiniteTime := AValue;
  // now, apply it for all the items
  DisableAutoSizing;
  for I := 0 to FList.Count - 1 do
    FList[I].CanInfiniteTime := FCanInfiniteTime;
  EnableAutoSizing;
end;

procedure TTimerConfigure.SetTimeControlString(AValue: string);
var
  ATimeControl: TTimeControl;
  I: integer;
  AControl: TTimerConfigurePanel;
begin
  ATimeControl := TTimeControl.Create;
  DisableAutoSizing;
  try
    ATimeControl.TimeControlString := AValue;
    FList.Clear;
    // add panels with time controls
    for I := 0 to ATimeControl.List.Count - 1 do
    begin
      AControl := AddPanel;
      AControl.TimeControl := ATimeControl.List[I];
      AControl.CanRestOfGame := (I = ATimeControl.List.Count - 1);
      FList.Add(AControl);
    end;
  finally
    EnableAutoSizing;
    FreeAndNil(ATimeControl);
  end;
end;

function TTimerConfigure.AddPanel: TTimerConfigurePanel;
  // Adds a time configurer panel.
begin
  Result := TTimerConfigurePanel.Create(nil);
  Result.Parent := ControlPanel;
  Result.CanInfiniteTime := FCanInfiniteTime;
  Result.RestOfGame := True;
end;

function TTimerConfigure.CanAdd: boolean;
  // Returns True if we can add a new time control.
begin
  Result := True;
end;

procedure TTimerConfigure.Add;
// Adds a new time control.
begin
  if not CanAdd then
    Exit;
  DisableAutoSizing;
  if FList.Count <> 0 then
    FList[FList.Count - 1].CanRestOfGame := False;
  FList.Add(AddPanel);
  EnableAutoSizing;
end;

function TTimerConfigure.CanErase: boolean;
  // Returns True if we can erase last time control.
begin
  Result := FList.Count > 1;
end;

procedure TTimerConfigure.Erase;
// Erases last time control.
begin
  if not CanErase then
    Exit;
  DisableAutoSizing;
  FList.Delete(FList.Count - 1);
  if FList.Count <> 0 then
    with FList[FList.Count - 1] do
    begin
      CanRestOfGame := True;
      RestOfGame := True;
    end;
  EnableAutoSizing;
end;

function TTimerConfigure.CanClear: boolean;
  // Returns True if we can clear the time control list.
begin
  Result := True;
end;

procedure TTimerConfigure.Clear;
// Clears the time control list.
var
  AControl: TTimerConfigurePanel;
begin
  if not CanClear then
    Exit;
  DisableAutoSizing;
  FList.Clear;
  AControl := AddPanel;
  FList.Add(AControl);
  AControl.InfiniteTime := True;
  EnableAutoSizing;
end;

constructor TTimerConfigure.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList := TTimerConfigurePanelList.Create(True);
  FCanInfiniteTime := True;
  Clear;
end;

destructor TTimerConfigure.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

end.
