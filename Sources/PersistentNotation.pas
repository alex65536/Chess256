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
    This unit contains TPersistentChessNotation - a descendant of TChessNotation
    that stores some previous states and so make possible to undo and redo the
    changes in the notation.
}
unit PersistentNotation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, NotationLists, NotationTags, ChessNotation, FGL,
  NotationMessaging, ChessRules;

const
  DefaultUndoCount = 32;

type
  EPersistentChessNotation = class(EChessNotation);

  { TNotationPersistence }

  TNotationPersistence = class
  private
    FIterationCount: integer;
    FList: TNotationList;
    FObjTag: TNotationObjectTag;
    FTags: TPGNTags;
    FTailChanged: boolean;
    // Methods
    procedure AssignIterator(AList: TNotationList; AIterator: TNotationIterator);
    function MakeIterator(AList: TNotationList): TNotationIterator;
  protected
    property List: TNotationList read FList;
    property Tags: TPGNTags read FTags;
    property ObjTag: TNotationObjectTag read FObjTag;
    property TailChanged: boolean read FTailChanged;
  public
    constructor Create;
    constructor Create(AList: TNotationList; AIterator: TNotationIterator;
      ATags: TPGNTags; AObjTag: TNotationObjectTag; ATailChanged: boolean);
    procedure Restore(AList: TNotationList; AIterator: TNotationIterator;
      ATags: TPGNTags; var AObjTag: TNotationObjectTag; var ATailChanged: boolean);
    destructor Destroy; override;
  end;

  TNotationPersistenceList = specialize TFPGObjectList<TNotationPersistence>;

  { TPersistentChessNotation }

  TPersistentChessNotation = class(TChessNotation)
  private
    FIgnoreSaveActionsCount: integer;
    FOnSaveState: TNotifyEvent;
    FPersistenceList: TNotationPersistenceList;
    FPosition: integer;
    FTailChanged: boolean;
    FUndoCount: integer;
    FStateSaveLock: integer;
    procedure SetUndoCount(AValue: integer);
  protected
    procedure TruncateList;
    procedure SaveState;
    procedure RestoreState;
    procedure DoBeginAction(AAction: TNotationAction); override;
    procedure DoEndAction(AAction: TNotationAction); override;
    procedure DoChangeTail; override;
    procedure DoSaveState; virtual;
  public
    // Actions
    property IgnoreSaveActionsCount: integer
      read FIgnoreSaveActionsCount write FIgnoreSaveActionsCount;
    property OnSaveState: TNotifyEvent read FOnSaveState write FOnSaveState;
    property UndoCount: integer read FUndoCount write SetUndoCount;
    procedure ClearStates;
    function CanUndo: boolean;
    procedure Undo;
    function CanRedo: boolean;
    procedure Redo;
    constructor Create(ABoard: TChessBoard);
    destructor Destroy; override;
  end;

implementation

{ TNotationPersistence }

procedure TNotationPersistence.AssignIterator(AList: TNotationList;
  AIterator: TNotationIterator);
// Saves AIterator form AList to store it.
var
  Iter: TNotationIterator;
begin
  FIterationCount := 0;
  Iter := AList.GetBegIter;
  try
    while not Iter.EqualTo(AIterator) do
    begin
      if Iter.IsLast then
        raise EPersistentChessNotation.Create('AIterator doesn''t fit AList.');
      Inc(FIterationCount);
      Iter.Next;
    end;
  finally
    FreeAndNil(Iter);
  end;
end;

function TNotationPersistence.MakeIterator(AList: TNotationList): TNotationIterator;
  // Restores the iterator which was saved.
var
  I: integer;
begin
  Result := AList.GetBegIter;
  for I := 0 to FIterationCount - 1 do
    Result.Next;
end;

constructor TNotationPersistence.Create;
begin
  FList := TNotationList.Create;
  FIterationCount := 0;
  FTags := TPGNTags.Create;
  FObjTag := nil;
  FTailChanged := False;
end;

constructor TNotationPersistence.Create(AList: TNotationList;
  AIterator: TNotationIterator; ATags: TPGNTags; AObjTag: TNotationObjectTag;
  ATailChanged: boolean);
begin
  Create;
  FList.Assign(AList);
  AssignIterator(AList, AIterator);
  FTags.Assign(ATags);
  AssignNotationTag(FObjTag, AObjTag);
  FTailChanged := ATailChanged;
end;

procedure TNotationPersistence.Restore(AList: TNotationList;
  AIterator: TNotationIterator; ATags: TPGNTags; var AObjTag: TNotationObjectTag;
  var ATailChanged: boolean);
// Restores the notation from the state saved in this object.
var
  Iter: TNotationIterator;
begin
  // restore list
  AList.Assign(FList);
  // restore iterator
  Iter := MakeIterator(AList);
  AIterator.Assign(Iter);
  FreeAndNil(Iter);
  // restore the others
  ATags.Assign(FTags);
  AssignNotationTag(AObjTag, FObjTag);
  ATailChanged := FTailChanged;
end;

destructor TNotationPersistence.Destroy;
begin
  FreeAndNil(FList);
  FreeAndNil(FTags);
  FreeAndNil(FObjTag);
  inherited Destroy;
end;

{ TPersistentChessNotation }

procedure TPersistentChessNotation.SetUndoCount(AValue: integer);
begin
  if FUndoCount = AValue then
    Exit;
  if AValue < 1 then
    raise EPersistentChessNotation.Create('Out of range: wrong UndoCount value');
  FUndoCount := AValue;
  TruncateList;
end;

procedure TPersistentChessNotation.TruncateList;
// Truncates the list according to UndoCount.
begin
  while FPersistenceList.Count > FUndoCount do
  begin
    FPersistenceList.Delete(0);
    Dec(FPosition);
  end;
  if FPosition < 0 then
    ClearStates;
end;

procedure TPersistentChessNotation.SaveState;
// Save the state to the states list.
begin
  // if nessesary - ignore a SaveState.
  if FIgnoreSaveActionsCount > 0 then
  begin
    Dec(FIgnoreSaveActionsCount);
    Exit;
  end;
  // now, save the state
  DoSaveState;
  Inc(FPosition);
  while FPersistenceList.Count > FPosition do
    FPersistenceList.Delete(FPosition);
  FPersistenceList.Add(TNotationPersistence.Create(List, Iterator,
    Tags, ObjTag, FTailChanged));
  TruncateList;
end;

procedure TPersistentChessNotation.RestoreState;
// Restores the state from the states list.
begin
  FPersistenceList[FPosition].Restore(List, Iterator, Tags, FObjTag, FTailChanged);
  // now, send message that we are updated.
  DoSendMessage(TRestoreMessage.Create);
  DoSendMessage(TIteratorChangeMessage.Create);
end;

procedure TPersistentChessNotation.DoBeginAction(AAction: TNotationAction);
begin
  if IsChanging then
    Exit;
  if FStateSaveLock = 0 then
    FTailChanged := False;
  Inc(FStateSaveLock);
  inherited DoBeginAction(AAction);
end;

procedure TPersistentChessNotation.DoEndAction(AAction: TNotationAction);
begin
  if IsChanging then
    Exit;
  inherited DoEndAction(AAction);
  Dec(FStateSaveLock);
  if FStateSaveLock = 0 then
    SaveState;
end;

procedure TPersistentChessNotation.DoChangeTail;
begin
  if IsChanging then
    Exit;
  if FStateSaveLock = 0 then
    FTailChanged := True;
  inherited DoChangeTail;
end;

procedure TPersistentChessNotation.DoSaveState;
// Method that is called when the state begins to save.
begin
  if Assigned(FOnSaveState) then
    FOnSaveState(Self);
end;

procedure TPersistentChessNotation.ClearStates;
// Clears the states list.
begin
  FPosition := -1;
  SaveState;
end;

function TPersistentChessNotation.CanUndo: boolean;
  // Returns True if you can undo.
begin
  Result := (FPosition > 0) and DoActionAccept(naUndo);
end;

procedure TPersistentChessNotation.Undo;
// Does the undo operation.
var
  TailChanged: boolean;
begin
  if not CanUndo then
    Exit;
  // start undo
  Inc(FStateSaveLock);
  DoBeginAction(naUndo);
  Changing;
  // do undo
  TailChanged := FTailChanged;
  Dec(FPosition);
  RestoreState;
  // finish undo
  Changed;
  DoChange;
  if TailChanged then
    DoChangeTail;
  DoEndAction(naUndo);
  Dec(FStateSaveLock);
end;

function TPersistentChessNotation.CanRedo: boolean;
  // Returns True if you can redo.
begin
  Result := (FPosition <> FPersistenceList.Count - 1) and
    DoActionAccept(naRedo);
end;

procedure TPersistentChessNotation.Redo;
// Does the redo operation.
var
  TailChanged: boolean;
begin
  if not CanRedo then
    Exit;
  // start redo
  Inc(FStateSaveLock);
  DoBeginAction(naRedo);
  Changing;
  // do redo
  Inc(FPosition);
  RestoreState;
  TailChanged := FTailChanged;
  // finish redo
  Changed;
  DoChange;
  if TailChanged then
    DoChangeTail;
  DoEndAction(naRedo);
  Dec(FStateSaveLock);
end;

constructor TPersistentChessNotation.Create(ABoard: TChessBoard);
begin
  inherited Create(ABoard);
  FPersistenceList := TNotationPersistenceList.Create(True);
  FUndoCount := DefaultUndoCount;
  FTailChanged := False;
  FStateSaveLock := 0;
  ClearStates;
end;

destructor TPersistentChessNotation.Destroy;
begin
  FreeAndNil(FPersistenceList);
  inherited Destroy;
end;

end.
