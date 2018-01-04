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
    This unit contains some helpful stuff for the chess notation (e. g. a double
    linked list and a hash table).
}
unit NotationUtils;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  SysUtils, ChessUtils;

const
  MaxHash = $ff; // I think it's enough...

type

  { TListNode }

  TListNode = class
  private
    FPrev: TListNode;
    FNext: TListNode;
  public
    // Properties
    property Prev: TListNode read FPrev;
    property Next: TListNode read FNext;
    // Methods
    procedure Assign(Source: TListNode);
    procedure AssignTo(Target: TListNode); virtual; abstract;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TListNodeClass = class of TListNode;

  { TDoubleLinkList }

  TDoubleLinkList = class(TChessObject)
  private
    FFirst: TListNode;
    FLast: TListNode;
    function GetNodes(Index: integer): TListNode;
  protected
    procedure DeleteNoFree(Node: TListNode);
    procedure UpdateItems(ABeg, AEnd: TListNode);
    procedure DoUpdateItems(ABeg, AEnd: TListNode); virtual;
  public
    // Properties
    property Nodes[Index: integer]: TListNode read GetNodes;
    // Nodes allows you to access the nodes as in array.
    // It's slow; I don't recommend to use it.
    property First: TListNode read FFirst;
    property Last: TListNode read FLast;
    // Insertion operations
    procedure InsertBefore(BefNode, Node: TListNode);
    procedure InsertAfter(AftNode, Node: TListNode);
    procedure InsertBeforeList(BefNode: TListNode; List: TDoubleLinkList);
    procedure InsertAfterList(AftNode: TListNode; List: TDoubleLinkList);
    function Add(Node: TListNode): TListNode;
    // Copying operations
    procedure CopyBeforeList(BefNode: TListNode; List: TDoubleLinkList);
    procedure CopyAfterList(AftNode: TListNode; List: TDoubleLinkList);
    // Node removing operations
    procedure Clear;
    procedure Delete(Node: TListNode);
    procedure Truncate(NewLast: TListNode);
    // Assignment operations
    procedure Assign(Source: TDoubleLinkList);
    procedure AssignTo(Target: TDoubleLinkList); virtual;
    // Other operations
    procedure Cut(ABeg, AEnd: TListNode; List: TDoubleLinkList);
    function Cut(ABeg, AEnd: TListNode): TDoubleLinkList;
    // In Cut methods, ABeg MUST be earlier than AEnd. Otherwise, the method
    // will not work properly. Be careful with it!
    procedure Swap(A, B: TListNode);
    // Other methods
    function Empty: boolean;
    function NextNode(Node: TListNode): TListNode;
    function PrevNode(Node: TListNode): TListNode;
    procedure Update; virtual;
    function CheckList: boolean;
    // CheckList checks for validness, it's debug only.
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TDoubleLinkListClass = class of TDoubleLinkList;

  { THashTable }

  generic THashTable<TItem> = class
  public
    type
    PItem = ^TItem;
    PHashList = ^RHashList;

    RHashList = record
      Data: TItem;
      Prev, Next: PHashList;
      Node: integer;
    end;
  private
    FHash: array [0 .. MaxHash] of PHashList;
    FSize: integer;
  public
    // Properties
    property Size: integer read FSize;
    // Methods
    function Add(const Data: TItem): PHashList;
    procedure Clear;
    function Find(const Data: TItem): PHashList;
    procedure Remove(List: PHashList);
    procedure Assign(Source: THashTable);
    procedure AssignTo(Target: THashTable);
    constructor Create;
    destructor Destroy; override;
  end;

procedure IncNode(var Node: TListNode);
procedure DecNode(var Node: TListNode);
function CopyNode(Source: TListNode): TListNode;

implementation

procedure IncNode(var Node: TListNode);
// Changes Node to the next one.
begin
  if Node = nil then
    Node := nil
  else
    Node := Node.Next;
end;

procedure DecNode(var Node: TListNode);
// Changes Node to the previous one.
begin
  if Node = nil then
    Node := nil
  else
    Node := Node.Prev;
end;

function CopyNode(Source: TListNode): TListNode;
  // Makes a copy of TListNode.
begin
  Result := TListNodeClass(Source.ClassType).Create;
  Result.Assign(Source);
end;

{ TListNode }

procedure TListNode.Assign(Source: TListNode);
// Copies Source to Self.
begin
  Source.AssignTo(Self);
end;

constructor TListNode.Create;
begin
  FPrev := nil;
  FNext := nil;
end;

destructor TListNode.Destroy;
begin
  inherited Destroy;
end;

{ TDoubleLinkList }

function TDoubleLinkList.GetNodes(Index: integer): TListNode;
var
  I: integer;
begin
  Result := nil;
  if Index < 0 then
    Exit;
  // we just go further Index times.
  Result := FFirst;
  for I := 1 to Index do
  begin
    IncNode(Result);
    if Result = nil then
      Exit;
  end;
end;

procedure TDoubleLinkList.DeleteNoFree(Node: TListNode);
// Deletes Node from the list without its destruction.
begin
  if Node = nil then
    Exit;
  if Node.FPrev <> nil then
    Node.FPrev.FNext := Node.FNext;
  if Node.FNext <> nil then
    Node.FNext.FPrev := Node.FPrev;
  if Node = FFirst then
    FFirst := Node.FNext;
  if Node = FLast then
    FLast := Node.FPrev;
  DoChange;
end;

procedure TDoubleLinkList.UpdateItems(ABeg, AEnd: TListNode);
// Called when the items from ABeg to AEnd are put into the list or when they
// are updated.
begin
  if not Updating then
    DoUpdateItems(ABeg, AEnd);
end;

{$HINTS OFF}
procedure TDoubleLinkList.DoUpdateItems(ABeg, AEnd: TListNode);
// Called by UpdateItems, can be overridden.
begin
end;

{$HINTS ON}

procedure TDoubleLinkList.InsertBefore(BefNode, Node: TListNode);
// Inserts Node before BefNode.
begin
  if Node = nil then
    Exit;
  // if empty, it'll be the whole list.
  if Empty then
  begin
    Node.FNext := nil;
    Node.FPrev := nil;
    FFirst := Node;
    FLast := Node;
    // updating
    UpdateItems(Node, Node);
    DoChange;
    Exit;
  end;
  // if insert before nil, it means that we insert after the tail.
  if BefNode = nil then
  begin
    InsertAfter(FLast, Node);
    Exit;
  end;
  // otherwise, simple insertion.
  if BefNode.FPrev <> nil then
    BefNode.FPrev.FNext := Node;
  Node.FPrev := BefNode.FPrev;
  Node.FNext := BefNode;
  BefNode.FPrev := Node;
  if BefNode = FFirst then
    FFirst := Node;
  // updating
  UpdateItems(Node, Node);
  DoChange;
end;

procedure TDoubleLinkList.InsertAfter(AftNode, Node: TListNode);
// Inserts Node after AftNode.
begin
  if Node = nil then
    Exit;
  // if empty, it'll be the whole list.
  if Empty then
  begin
    Node.FNext := nil;
    Node.FPrev := nil;
    FFirst := Node;
    FLast := Node;
    // updating
    UpdateItems(Node, Node);
    DoChange;
    Exit;
  end;
  // if insert after nil, it means that we insert before the head.
  if AftNode = nil then
  begin
    InsertBefore(FFirst, Node);
    Exit;
  end;
  // otherwise, simple insertion.
  if AftNode.FNext <> nil then
    AftNode.FNext.FPrev := Node;
  Node.FPrev := AftNode;
  Node.FNext := AftNode.FNext;
  AftNode.FNext := Node;
  if AftNode = FLast then
    FLast := Node;
  // updating
  UpdateItems(Node, Node);
  DoChange;
end;

procedure TDoubleLinkList.InsertBeforeList(BefNode: TListNode; List: TDoubleLinkList);
// Inserts List before BefNode.
begin
  if List.Empty then
    Exit;
  if List = Self then
    Exit;
  // if empty, it'll be the whole list.
  if Empty then
  begin
    FFirst := List.FFirst;
    FLast := List.FLast;
    // updating
    UpdateItems(List.FFirst, List.FLast);
    List.FFirst := nil;
    List.FLast := nil;
    List.DoChange;
    DoChange;
    Exit;
  end;
  // if insert before nil, it means that we insert after the tail.
  if BefNode = nil then
  begin
    InsertAfterList(FLast, List);
    Exit;
  end;
  // otherwise, simple insertion.
  if BefNode.FPrev <> nil then
    BefNode.FPrev.FNext := List.FFirst;
  List.FFirst.FPrev := BefNode.FPrev;
  List.FLast.FNext := BefNode;
  BefNode.FPrev := List.FLast;
  if BefNode = FFirst then
    FFirst := List.FFirst;
  // updating
  UpdateItems(List.FFirst, List.FLast);
  List.FFirst := nil;
  List.FLast := nil;
  List.DoChange;
  DoChange;
end;

procedure TDoubleLinkList.InsertAfterList(AftNode: TListNode; List: TDoubleLinkList);
begin
  if List.Empty then
    Exit;
  if List = Self then
    Exit;
  // if empty, it'll be the whole list.
  if Empty then
  begin
    FFirst := List.FFirst;
    FLast := List.FLast;
    // updating
    UpdateItems(List.FFirst, List.FLast);
    List.FFirst := nil;
    List.FLast := nil;
    List.DoChange;
    DoChange;
    Exit;
  end;
  // if insert after nil, it means that we insert before the head.
  if AftNode = nil then
  begin
    InsertBeforeList(FFirst, List);
    Exit;
  end;
  // otherwise, simple insertion.
  if AftNode.FNext <> nil then
    AftNode.FNext.FPrev := List.FLast;
  List.FFirst.FPrev := AftNode;
  List.FLast.FNext := AftNode.FNext;
  AftNode.FNext := List.FFirst;
  if AftNode = FLast then
    FLast := List.FLast;
  // updating
  UpdateItems(List.FFirst, List.FLast);
  List.FFirst := nil;
  List.FLast := nil;
  List.DoChange;
  DoChange;
end;

function TDoubleLinkList.Add(Node: TListNode): TListNode;
  // Inserts the element to the tail.
begin
  InsertBefore(nil, Node);
  Result := Node;
end;

procedure TDoubleLinkList.CopyBeforeList(BefNode: TListNode; List: TDoubleLinkList);
// Copies the List's elements and inserts them before BefNode.
var
  NewList: TDoubleLinkList;
begin
  NewList := TDoubleLinkListClass(ClassType).Create;
  NewList.Assign(List);
  InsertBeforeList(BefNode, NewList);
  FreeAndNil(NewList);
end;

procedure TDoubleLinkList.CopyAfterList(AftNode: TListNode; List: TDoubleLinkList);
// Copies the List's elements and inserts them after AftNode.
var
  NewList: TDoubleLinkList;
begin
  NewList := TDoubleLinkListClass(ClassType).Create;
  NewList.Assign(List);
  InsertAfterList(AftNode, NewList);
  FreeAndNil(NewList);
end;

procedure TDoubleLinkList.Clear;
// Clears the list.
begin
  Truncate(nil);
end;

procedure TDoubleLinkList.Delete(Node: TListNode);
// Deletes Node from the list.
begin
  if Node = nil then
    Exit;
  DeleteNoFree(Node);
  FreeAndNil(Node);
end;

procedure TDoubleLinkList.Truncate(NewLast: TListNode);
// Deletes all the nodes after NewLast from the list.
begin
  BeginUpdate;
  while (FLast <> NewLast) and (FLast <> nil) do
    Delete(FLast);
  EndUpdate;
  DoChange;
end;

procedure TDoubleLinkList.Assign(Source: TDoubleLinkList);
// Copies Source to Self.
begin
  Source.AssignTo(Self);
end;

procedure TDoubleLinkList.AssignTo(Target: TDoubleLinkList);
// Copies Self to Target.
var
  CurNode: TListNode;
begin
  if Self = Target then
    Exit;
  // if empty, just clear and exit.
  if Empty then
  begin
    Target.Clear;
    Exit;
  end;
  // otherwise, iterate through the nodes, copy and insert them.
  Target.BeginUpdate;
  Target.Clear;
  CurNode := FFirst;
  while CurNode <> nil do
  begin
    Target.InsertBefore(nil, CopyNode(CurNode));
    IncNode(CurNode);
  end;
  // updating
  Target.EndUpdate;
  Target.UpdateItems(Target.FFirst, Target.FLast);
  Target.DoChange;
end;

procedure TDoubleLinkList.Cut(ABeg, AEnd: TListNode; List: TDoubleLinkList);
// Cuts items from ABeg to AEnd into List. ABeg MUST be earlier than AEnd.
// Otherwise, the result is undefined.
begin
  if List = Self then
    Exit;
  if (ABeg = nil) or (AEnd = nil) then
    Exit;
  List.BeginUpdate;
  // clear
  List.Clear;
  // cut
  List.FFirst := ABeg;
  List.FLast := AEnd;
  if ABeg.FPrev <> nil then
    ABeg.FPrev.FNext := AEnd.FNext;
  if AEnd.FNext <> nil then
    AEnd.FNext.FPrev := ABeg.FPrev;
  if ABeg = FFirst then
    FFirst := AEnd.FNext;
  if AEnd = FLast then
    FLast := ABeg.FPrev;
  ABeg.FPrev := nil;
  AEnd.FNext := nil;
  // update
  List.EndUpdate;
  List.UpdateItems(ABeg, AEnd);
  List.DoChange;
  DoChange;
end;

function TDoubleLinkList.Cut(ABeg, AEnd: TListNode): TDoubleLinkList;
  // Cuts items from ABeg to AEnd into a new list. ABeg MUST be earlier than AEnd.
  // Otherwise, the result is undefined.
begin
  Result := TDoubleLinkListClass(ClassType).Create;
  Cut(ABeg, AEnd, Result);
end;

procedure TDoubleLinkList.Swap(A, B: TListNode);
// Swaps A and B.
var
  pA, pB: TListNode;
begin
  if (A = nil) or (B = nil) then
    Exit;
  if A = B then
    Exit;
  BeginUpdate;
  // tricky cases when A and B are neighbours
  // case when A comes right before B.
  if A.FNext = B then
  begin
    DeleteNoFree(B);
    InsertBefore(A, B);
    // updating
    EndUpdate;
    DoChange;
    Exit;
  end;
  // case when A comes right after B.
  if A.FPrev = B then
  begin
    DeleteNoFree(B);
    InsertAfter(A, B);
    // updating
    EndUpdate;
    DoChange;
    Exit;
  end;
  // other cases are easier
  pA := A.FPrev;
  pB := B.FPrev;
  DeleteNoFree(A);
  DeleteNoFree(B);
  InsertAfter(pA, B);
  InsertAfter(pB, A);
  // update
  EndUpdate;
  DoChange;
end;

function TDoubleLinkList.Empty: boolean;
  // Returns True if the list is empty.
begin
  Result := FFirst = nil;
end;

function TDoubleLinkList.NextNode(Node: TListNode): TListNode;
  // Returns the node next to Node.
begin
  if Node = nil then
    Result := FFirst
  else
    Result := Node.Next;
end;

function TDoubleLinkList.PrevNode(Node: TListNode): TListNode;
  // Return the node previous to Node.
begin
  if Node = nil then
    Result := FLast
  else
    Result := Node.Prev;
end;

procedure TDoubleLinkList.Update;
// Updates the list.
begin
  if not Empty then
    UpdateItems(FFirst, FLast);
end;

function TDoubleLinkList.CheckList: boolean;
  // Checks the list for correctness. Returns True if the list is correct. The
  // function is made for debugging.
var
  CurNode: TListNode;
begin
  try
    Result := False;
    // checking FFirst and FLast.
    if Empty then
    begin
      if (FFirst <> nil) or (FLast <> nil) then
        Exit;
      Result := True;
      Exit;
    end
    else
    begin
      if (FFirst = nil) or (FLast = nil) then
        Exit;
    end;
    // there must be Nil before First and after Last.
    if FFirst.FPrev <> nil then
      Exit;
    if FLast.FNext <> nil then
      Exit;
    // checking that for every node Node.Next.Prev = Node and Node.Prev.Next = Node.
    CurNode := FFirst;
    while CurNode <> nil do
    begin
      if (CurNode <> FLast) and (CurNode.FNext.FPrev <> CurNode) then
        Exit;
      if (CurNode <> FFirst) and (CurNode.FPrev.FNext <> CurNode) then
        Exit;
      IncNode(CurNode);
    end;
  except
    // if exception - the list is invalid.
    Exit;
  end;
  Result := True;
end;

constructor TDoubleLinkList.Create;
begin
  inherited;
  FFirst := nil;
  FLast := nil;
end;

destructor TDoubleLinkList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

{ THashTable }

function THashTable.Add(const Data: TItem): PHashList;
  // Adds an item to the hash table and returns the node that contains the item.
var
  H: integer;
  P: PHashList;
begin
  H := Data.GetHash and MaxHash;
  New(P);
  P^.Data := Data;
  P^.Next := FHash[H];
  P^.Prev := nil;
  P^.Node := H;
  if P^.Next <> nil then
    P^.Next^.Prev := P;
  FHash[H] := P;
  Result := P;
  Inc(FSize);
end;

procedure THashTable.Clear;
// Clears the hash table.
var
  I: integer;
  R, P: PHashList;
begin
  for I := 0 to MaxHash do
  begin
    P := FHash[I];
    while P <> nil do
    begin
      R := P;
      P := P^.Next;
      Dispose(R);
    end;
    FHash[I] := nil;
  end;
  FSize := 0;
end;

function THashTable.Find(const Data: TItem): PHashList;
  // Finds an item in the hash table. If it was found, returns the node that
  // contains the item. If it wasn't found, returns Nil.
var
  H: integer;
  P: PHashList;
begin
  H := Data.GetHash and MaxHash;
  P := FHash[H];
  while P <> nil do
  begin
    if Data = P^.Data then
      Break;
    P := P^.Next;
  end;
  Result := P;
end;

procedure THashTable.Assign(Source: THashTable);
// Copies Source to Self.
begin
  Source.AssignTo(Self);
end;

procedure THashTable.AssignTo(Target: THashTable);
// Copies Self to Target.
var
  I: integer;
  NewP, P: PHashList;
begin
  Target.Clear;
  Target.FSize := FSize;
  for I := 0 to MaxHash do
  begin
    P := FHash[I];
    while P <> nil do
    begin
      New(NewP);
      P^.Data := NewP^.Data;
      NewP^.Next := Target.FHash[I];
      NewP^.Prev := nil;
      NewP^.Node := I;
      if P^.Next <> nil then
        P^.Next^.Prev := P;
      Target.FHash[I] := NewP;
      P := P^.Next;
    end;
  end;
end;

procedure THashTable.Remove(List: PHashList);
// Removes a node from the hash.
var
  H: integer;
begin
  H := List^.Node;
  if List^.Prev = nil then
    FHash[H] := List^.Next
  else
    List^.Prev^.Next := List^.Next;
  if List^.Next <> nil then
    List^.Next^.Prev := List^.Prev;
  Dispose(List);
  Dec(FSize);
end;

constructor THashTable.Create;
var
  I: integer;
begin
  for I := 0 to MaxHash do
    FHash[I] := nil;
  FSize := 0;
end;

destructor THashTable.Destroy;
begin
  Clear;
  inherited;
end;

end.
