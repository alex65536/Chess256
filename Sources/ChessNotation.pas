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
    This unit implements the chess notation class.
}

{
  TODO : Add the following:
   * Variation compression.
   * Make a node main or convert a node to a variation.
   * Make Assign/AssignTo (?)
}
unit ChessNotation;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Classes, SysUtils, ChessUtils, NotationTags, NotationLists, ChessRules,
  NotationMessaging, MoveChains;

resourcestring
  SIllegalMove = 'Illegal move.';
  SCannotInsertChain = 'Cannot insert the move chain.';

type
  TNotationAction = (naNone, naClear, naClearCustom, naAddMove, naAddMoveChain, naErase,
    naEditComment, naEditNAG, naInsertComment, naInsertNAG, naMoveUp,
    naMoveDown, naPaste, naTruncate, naUndo, naRedo);

  TNotationActionAcceptEvent = procedure(Sender: TObject; AAction: TNotationAction;
    var Accept: boolean) of object;
  TNotationActionEvent = procedure(Sender: TObject; AAction: TNotationAction) of object;

  EChessNotation = class(Exception);

  { TChessNotation }

  TChessNotation = class(TChessObject)
  private
    FOnActionAccept: TNotationActionAcceptEvent;
    FOnBeginAction: TNotationActionEvent;
    FOnBeginActionNotify: TNotifyEvent;
    FOnEndAction: TNotationActionEvent;
    FOnBoardUpdate: TNotifyEvent;
    FOnChangeGameResult: TNotifyEvent;
    FOnChangeTail: TNotifyEvent;
    FOnEndActionNotify: TNotifyEvent;
    FOnSendMessage: TNotationMessageReceiver;
    FSendMessages: boolean;
    FTags: TPGNTags;
    FList: TNotationList;
    FBoard: TChessBoard;
    FIterator: TNotationIterator;
    FChanging: integer;
    // Variables to check if the game result was changed
    FGameResUpdating: integer;
    FGameResPerform: boolean;
    // Getters / Setters
    function GetGameResult: RGameResult;
    function GetPGNString: string;
    procedure SetBoard(AValue: TChessBoard);
    procedure SetGameResult(AValue: RGameResult);
    procedure SetPGNString(const AValue: string);
    // Event handlers
    procedure Changer(Sender: TObject);
    procedure IteratorChanger(Sender: TObject);
    procedure GameResultChanger(Sender: TObject);
  protected
    FObjTag: TNotationObjectTag;
    // Methods to check if the game result was changed
    procedure GameResChanging;
    procedure GameResChanged;
    procedure CallGameResEvent;
    // Methods to be called before and after doing each operation
    procedure Changing;
    procedure Changed;
    function IsChanging: boolean;
    // Other methods
    procedure DoChangeTail; virtual;
    procedure DoEndAction(AAction: TNotationAction); virtual;
    procedure DoBeginAction(AAction: TNotationAction); virtual;
    function DoActionAccept(AAction: TNotationAction): boolean; virtual;
    procedure DoUpdate;
    procedure DoSendMessage(Message: TNotationMessage);
    procedure UpdateTags;
    procedure ClearUsingTags;
    procedure UpdateBoard;
    procedure ClearNotation(const ABaseBoard: RRawBoard);
    // helpful method for Clear & ClearCustom
    // These two ones are made for AddMove / AddMoveChain
    function CanAddMoveNodes: boolean;
    procedure AddMoveNodes(AList: TNotationList);
    // These two ones are made for MoveUp / MoveDown...
    // It1 should be earlier than It2 !!!
    function CanSwapNeighbour(It1, It2: TNotationNode): boolean;
    procedure SwapNeighbour(It1, It2: TNotationNode);
  public
    // Properties
    property ObjTag: TNotationObjectTag read FObjTag write FObjTag;
    property Board: TChessBoard read FBoard write SetBoard;
    property GameResult: RGameResult read GetGameResult write SetGameResult;
    property PGNString: string read GetPGNString write SetPGNString;
    property Tags: TPGNTags read FTags;
    property List: TNotationList read FList;
    property Iterator: TNotationIterator read FIterator;
    property SendMessages: boolean read FSendMessages write FSendMessages;
    // Events
    property OnChangeTail: TNotifyEvent read FOnChangeTail write FOnChangeTail;
    property OnChangeGameResult: TNotifyEvent
      read FOnChangeGameResult write FOnChangeGameResult;
    property OnBoardUpdate: TNotifyEvent read FOnBoardUpdate write FOnBoardUpdate;
    // OnBeginAction indicates action beginning
    property OnBeginAction: TNotationActionEvent
      read FOnBeginAction write FOnBeginAction;
    property OnBeginActionNotify: TNotifyEvent
      read FOnBeginActionNotify write FOnBeginActionNotify;
    // OnEndAction indicates action ending
    property OnEndAction: TNotationActionEvent read FOnEndAction write FOnEndAction;
    property OnEndActionNotify: TNotifyEvent
      read FOnEndActionNotify write FOnEndActionNotify;
    // The rest of the events
    property OnActionAccept: TNotationActionAcceptEvent
      read FOnActionAccept write FOnActionAccept; // called by each CanDo() & Do().
    property OnSendMessage: TNotationMessageReceiver
      read FOnSendMessage write FOnSendMessage; // sends a message (maybe for redrawing)
    // Iterator changing methods
    procedure GoToStart;
    procedure GoToLastMove;
    procedure GoToEnd;
    // Other methods
    function LastMoveNode: TMoveNode;
    function CurBoard: RRawBoard;
    function GetMoveChain: TMoveChain;
    function GetBegIter: TNotationIterator;
    function GetEndIter: TNotationIterator;
    // Actions
    function CanClear: boolean;
    procedure Clear;
    function CanClearCustom: boolean;
    procedure ClearCustom(const ABaseBoard: RRawBoard);
    function CanAddMove: boolean;
    procedure AddMove(const Move: RChessMove);
    function CanAddMoveChain: boolean;
    procedure AddMoveChain(Chain: TMoveChain);
    function CanErase: boolean;
    procedure Erase(GoToMove: boolean);
    function CanTruncate: boolean;
    procedure Truncate(GoToMove: boolean);
    function CanEditComment: boolean;
    procedure EditComment(const Comment: string);
    function CanEditNAG: boolean;
    procedure EditNAG(NAG: byte);
    function CanInsertComment: boolean;
    procedure InsertComment(const Comment: string);
    function CanInsertNAG: boolean;
    procedure InsertNAG(NAG: byte);
    function CanMoveUp: boolean;
    procedure MoveUp;
    function CanMoveDown: boolean;
    procedure MoveDown;
    function CanPaste: boolean;
    procedure Paste(APGNString: string);
    // Constructor & destructor
    constructor Create(ABoard: TChessBoard);
    destructor Destroy; override;
  end;

implementation

{ TChessNotation }

function TChessNotation.GetGameResult: RGameResult;
begin
  Result := FList.GameResult;
end;

function TChessNotation.GetPGNString: string;
begin
  BeginUpdate;
  UpdateTags;
  EndUpdate;
  Result := Tags.TagString + LineEnding + List.PGNString;
end;

procedure TChessNotation.SetBoard(AValue: TChessBoard);
begin
  if FBoard = AValue then
    Exit;
  FBoard := AValue;
  UpdateBoard;
end;

procedure TChessNotation.SetGameResult(AValue: RGameResult);
begin
  FList.GameResult := AValue;
end;

procedure TChessNotation.SetPGNString(const AValue: string);
begin
  Paste(AValue);
end;

procedure TChessNotation.Changer(Sender: TObject);
begin
  if Updating or IsChanging then
    Exit;
  DoChange;
  DoUpdate;
end;

procedure TChessNotation.IteratorChanger(Sender: TObject);
begin
  UpdateBoard;
  DoSendMessage(TIteratorChangeMessage.Create);
  DoChange;
end;

procedure TChessNotation.GameResultChanger(Sender: TObject);
begin
  DoSendMessage(TChangeGameEndMessage.Create(Sender as TNotationList));
  if Sender <> FList then
    Exit;
  FGameResPerform := True;
  CallGameResEvent;
end;

procedure TChessNotation.GameResChanging;
// Begins game result changing.
begin
  Inc(FGameResUpdating);
end;

procedure TChessNotation.GameResChanged;
// Finishes game result changing.
begin
  Dec(FGameResUpdating);
  if FGameResUpdating < 0 then
    FGameResUpdating := 0;
  CallGameResEvent;
end;

procedure TChessNotation.CallGameResEvent;
// Calls OnChangeGameResult if not changing.
begin
  if FGameResUpdating <> 0 then
    Exit;
  if not FGameResPerform then
    Exit;
  if Assigned(FOnChangeGameResult) then
    FOnChangeGameResult(Self);
  FGameResPerform := False;
end;

procedure TChessNotation.Changing;
// Indicates the operation beginning.
begin
  Inc(FChanging);
  GameResChanging;
end;

procedure TChessNotation.Changed;
// Indicates the operation ending.
begin
  Dec(FChanging);
  GameResChanged;
end;

function TChessNotation.IsChanging: boolean;
  // Returns True if the component is changing.
begin
  Result := FChanging <> 0;
end;

procedure TChessNotation.DoChangeTail;
// Indicates that the tail has changed.
begin
  if IsChanging then
    Exit;
  if Assigned(FOnChangeTail) then
    FOnChangeTail(Self);
end;

procedure TChessNotation.DoBeginAction(AAction: TNotationAction);
// Indicates that an action has started.
begin
  if IsChanging then
    Exit;
  if Assigned(FOnBeginAction) then
    FOnBeginAction(Self, AAction);
  if Assigned(FOnBeginActionNotify) then
    FOnBeginActionNotify(Self);
end;

procedure TChessNotation.DoEndAction(AAction: TNotationAction);
// Indicates that an action has ended.
begin
  if IsChanging then
    Exit;
  if Assigned(FOnEndAction) then
    FOnEndAction(Self, AAction);
  if Assigned(FOnEndActionNotify) then
    FOnEndActionNotify(Self);
end;

function TChessNotation.DoActionAccept(AAction: TNotationAction): boolean;
  // Runs an internal action validator.
begin
  Result := True;
  if Assigned(FOnActionAccept) then
    FOnActionAccept(Self, AAction, Result);
end;

procedure TChessNotation.DoUpdate;
// Indicates that the notation has been fully updated.
var
  It: TNotationIterator;
begin
  if Updating then
    Exit;
  BeginUpdate;
  It := GetEndIter;
  FIterator.Assign(It);
  FreeAndNil(It);
  EndUpdate;
  DoSendMessage(TUpdateMessage.Create);
  DoSendMessage(TIteratorChangeMessage.Create);
end;

procedure TChessNotation.DoSendMessage(Message: TNotationMessage);
// Sends a message.
begin
  if Updating or (not FSendMessages) then
    SendNotationMessage(Self, Message, nil)
  else
    SendNotationMessage(Self, Message, FOnSendMessage);
end;

procedure TChessNotation.UpdateTags;
// Updates the tags.
begin
  BeginUpdate;
  if List.BaseBoard = GetInitialPosition then
  begin
    Tags.Tags['SetUp'] := '0';
    Tags.RemoveTag('FEN');
  end
  else
  begin
    Tags.Tags['SetUp'] := '1';
    Tags.Tags['FEN'] := List.BaseBoardFEN;
  end;
  Tags.Tags['Result'] := GameResultMeanings[GameResult.Winner];
  EndUpdate;
  DoChange;
end;

procedure TChessNotation.ClearUsingTags;
// Clears the list using position in tags.
var
  ABoard: TChessBoard;
begin
  ABoard := TChessBoard.Create(False);
  try
    // put the position to our board
    if Tags['SetUp'] = '' then
    begin
      if Tags['FEN'] = '' then
        Tags['SetUp'] := '0'
      else
        Tags['SetUp'] := '1';
    end;
    if Tags['SetUp'] = '0' then
      ABoard.InitialPosition
    else
      ABoard.FENString := Tags['FEN'];
    // validate the position
    if ABoard.ValidatePosition <> vrOK then
      raise Exception.Create('-- validation fail --');
  except
    // bad FEN
    List.Clear(GetInitialPosition);
    FreeAndNil(ABoard);
    raise EPGNReadWrite.Create(SIllegalFEN);
    Exit;
  end;
  // if success, then clear with our board
  List.Clear(ABoard.RawBoard);
  FreeAndNil(ABoard);
end;

procedure TChessNotation.UpdateBoard;
// Updates the board.
begin
  if not Assigned(FBoard) then
    Exit;
  FBoard.RawBoard := CurBoard;
  if Assigned(FOnBoardUpdate) then
    FOnBoardUpdate(Self);
end;

procedure TChessNotation.ClearNotation(const ABaseBoard: RRawBoard);
// Clears the notation with given board.
var
  TailChanges: boolean;
begin
  TailChanges := (ABaseBoard <> FList.BaseBoard) or (FList.LastMoveNode <> nil);
  FList.GameResult := MakeGameResult(geNone, gwNone); // first, we null it ...
  Changing;
  FList.Clear(ABaseBoard);
  FList.UpdateGameResult(True);
  DoSendMessage(TUpdateMessage.Create);
  FIterator.SetValues(List, nil);
  Changed;
  DoChange;
  if TailChanges then
    DoChangeTail;
end;

function TChessNotation.CanAddMoveNodes: boolean;
  // Returns True if we can add moves.
var
  AftNode: TMoveNode;
begin
  with FIterator.List do
    AftNode := LastMoveNode(NextNode(FIterator.Node), mdForward);
  if AftNode = nil then
    Result := not FIterator.List.GameFinished
  else
    Result := True;
end;

procedure TChessNotation.AddMoveNodes(AList: TNotationList);
// Pushes AList to the notation. This function HAS NO VALIDATION!
var
  AftNode: TNotationNode;
  VarNode: TVariationNode;
  FromNode: TNotationNode;
  TailChanges: boolean;
begin
  if AList.Empty then
    Exit;
  TailChanges := False;
  Changing;
  with FIterator.List do
    AftNode := LastMoveNode(NextNode(FIterator.Node), mdForward);
  if AftNode = nil then
  begin
    // just push to the end
    TailChanges := True;
    FromNode := AList.First; // we save from what we add
    FIterator.List.InsertBeforeList(nil, AList);
    FIterator.List.UpdateGameResult(True);
    DoSendMessage(TInsertTailMessage.Create(FromNode));
    // update the iterator
    FIterator.SetValues(FIterator.List, FIterator.List.Last);
  end
  else
  begin
    // we must make a new variation
    repeat // we want to push our variation right before the next move
      AftNode := AftNode.Next;
    until (AftNode = nil) or (AftNode is TMoveNode);
    // now, create a new variation with this move
    VarNode := TVariationNode.Create(nil);
    VarNode.List.Clear(AList.BaseBoard);
    VarNode.List.InsertBeforeList(nil, AList);
    FIterator.List.InsertBefore(AftNode, VarNode);
    VarNode.List.UpdateGameResult(True); // recalc the game end
    DoSendMessage(TInsertMessage.Create(VarNode));
    // update the iterator
    FIterator.SetValues(VarNode.List, VarNode.List.Last);
  end;
  Changed;
  DoChange;
  if TailChanges then
    DoChangeTail;
end;

function TChessNotation.CanSwapNeighbour(It1, It2: TNotationNode): boolean;
  // Returns True if we can swap It1 and It2 that are neighbours.
begin
  if (It1 = nil) or (It2 = nil) then
    Exit(False);
  if (It1 is TShortCommentNode) or (It1 is TLongCommentNode) or
    (It2 is TShortCommentNode) or (It2 is TLongCommentNode) then
    Exit(True);
  if (It1 is TVariationNode) and (It2 is TVariationNode) then
    Exit(True);
  Result := False;
end;

procedure TChessNotation.SwapNeighbour(It1, It2: TNotationNode);
// Swaps It1 and It2 that are neighbours.
begin
  Changing;
  DoSendMessage(TMovingUpDownMessage.Create(It1, It2));
  FIterator.List.Swap(It1, It2);
  DoSendMessage(TMovedUpDownMessage.Create);
  Iterator.DoChange;
  // just the order of pointers has changed, so we don't have to change the iterator.
  Changed;
  DoChange;
end;

procedure TChessNotation.GoToStart;
// Goes to the beginning of the notation.
begin
  FIterator.SetValues(FList, nil);
end;

procedure TChessNotation.GoToLastMove;
// Goes to the last move of the notation.
begin
  FIterator.SetValues(FList, FList.LastMoveNode);
end;

procedure TChessNotation.GoToEnd;
// Goes to the end of the notation.
begin
  FIterator.SetValues(FList, FList.Last);
end;

function TChessNotation.LastMoveNode: TMoveNode;
  // Returns the last move node.
begin
  Result := FIterator.List.LastMoveNode(FIterator.Node);
end;

function TChessNotation.CurBoard: RRawBoard;
  // Returns the current board.
var
  LastMove: TMoveNode;
begin
  LastMove := LastMoveNode;
  if LastMove = nil then
    Result := FIterator.List.BaseBoard
  else
    Result := LastMove.NewBoard;
end;

function TChessNotation.GetMoveChain: TMoveChain;
  // Returns the current move chain.
begin
  Result := FIterator.List.GetMoveChain(FIterator.Node);
end;

function TChessNotation.GetBegIter: TNotationIterator;
  // Returns the iterator to the beginning.
begin
  Result := FList.GetBegIter;
end;

function TChessNotation.GetEndIter: TNotationIterator;
  // Returns the iterator to the ending.
begin
  Result := FList.GetEndIter;
end;

function TChessNotation.CanClear: boolean;
  // Returns True if we can clear the notation.
begin
  Result := DoActionAccept(naClear);
end;

procedure TChessNotation.Clear;
// Clears the notation.
begin
  if not CanClear then
    Exit;
  DoBeginAction(naClear);
  ClearNotation(FList.BaseBoard);
  DoEndAction(naClear);
end;

function TChessNotation.CanClearCustom: boolean;
  // Returns True if we can clear using a custom board.
begin
  Result := DoActionAccept(naClearCustom);
end;

procedure TChessNotation.ClearCustom(const ABaseBoard: RRawBoard);
// Clears the notation using a custom board.
begin
  if not CanClearCustom then
    Exit;
  DoBeginAction(naClearCustom);
  ClearNotation(ABaseBoard);
  DoEndAction(naClearCustom);
end;

function TChessNotation.CanAddMove: boolean;
  // Returns True if we can add a move.
begin
  Result := CanAddMoveNodes and DoActionAccept(naAddMove);
end;

procedure TChessNotation.AddMove(const Move: RChessMove);
// Adds a single move to the notation.
var
  ABoard: TChessBoard;
  AList: TNotationList;
  LastBoard: RRawBoard;
begin
  if not CanAddMove then
    Exit;
  LastBoard := CurBoard;
  // first, check move.
  ABoard := TChessBoard.Create(True);
  ABoard.RawBoard := LastBoard;
  try
    ABoard.MakeMove(Move);
  except
    FreeAndNil(ABoard);
    raise EChessNotation.Create(SIllegalMove);
  end;
  FreeAndNil(ABoard);
  // start adding
  DoBeginAction(naAddMove);
  // create the node and the list.
  AList := TNotationList.Create;
  AList.Clear(LastBoard);
  AList.Add(TMoveNode.Create(nil, LastBoard, Move));
  // finally, find the position and insert there.
  AddMoveNodes(AList);
  FreeAndNil(AList);
  DoEndAction(naAddMove);
end;

function TChessNotation.CanAddMoveChain: boolean;
  // Returns True if we can add a move chain.
begin
  Result := CanAddMoveNodes and DoActionAccept(naAddMoveChain);
end;

procedure TChessNotation.AddMoveChain(Chain: TMoveChain);
// Adds a move chain to the notation.
var
  LastBoard: RRawBoard;
  I: integer;
  AList: TNotationList;
begin
  if not CanAddMoveChain then
    Exit;
  // first, validate the chain.
  LastBoard := CurBoard;
  if Chain.Boards[-1] <> LastBoard then
    raise EChessNotation.Create(SCannotInsertChain);
  if Chain.Count = 0 then
    Exit;
  // start adding
  DoBeginAction(naAddMoveChain);
  // create the list and add all the moves.
  AList := TNotationList.Create;
  AList.Clear(LastBoard);
  for I := 0 to Chain.Count - 1 do
    AList.Add(TMoveNode.Create(nil, Chain.Boards[I - 1], Chain.Moves[I]));
  // finally, find the position and insert there.
  AddMoveNodes(AList);
  FreeAndNil(AList);
  DoEndAction(naAddMoveChain);
end;

function TChessNotation.CanErase: boolean;
  // Returns True if we can erase current node.
begin
  if FIterator.Node = nil then
    Exit(False);
  if FIterator.Node is TMoveNode then
    Result := FIterator.List.LastMoveNode = FIterator.Node
  else
    Result := True;
  if Result then
    Result := DoActionAccept(naErase);
end;

procedure TChessNotation.Erase(GoToMove: boolean);
// Erases current node.
var
  NewList: TNotationList;
  VarNode, NewNode: TNotationNode;
  TailChanges: boolean;
begin
  if not CanErase then
    Exit;
  DoBeginAction(naErase);
  TailChanges := False;
  Changing;
  if FIterator.Node is TMoveNode then
  begin
    // removing moves is very specific
    if (FIterator.List.Parent <> nil) and
      (FIterator.List.LastMoveNode(FIterator.Node.Prev) = nil) then
    begin
      // it's a variation and there's only one move here
      VarNode := FIterator.List.Parent;
      NewList := VarNode.Parent;
      NewNode := VarNode.Prev;
      DoSendMessage(TDeletingMessage.Create(VarNode));
      NewList.Delete(VarNode);
      DoSendMessage(TDeletedMessage.Create);
      // update the iterator
      if GoToMove then
        FIterator.SetValues(NewList,
          NewList.LastMoveNode(NewNode))
      else
        FIterator.SetValues(NewList, NewNode);
    end
    else
    begin
      // just delete the tail
      TailChanges := True;
      DoSendMessage(TDeletingTailMessage.Create(FIterator.Node));
      FIterator.List.Truncate(FIterator.Node.Prev);
      FIterator.List.UpdateGameResult(True);
      DoSendMessage(TDeletedTailMessage.Create);
      // update the iterator
      if GoToMove then
        FIterator.SetValues(FIterator.List,
          FIterator.List.LastMoveNode)
      else
        FIterator.SetValues(FIterator.List,
          FIterator.List.Last);
    end;
  end
  else
  begin
    // removing comments, NAGs & variations is quite easier
    NewNode := FIterator.Node.Prev;
    DoSendMessage(TDeletingMessage.Create(FIterator.Node));
    FIterator.List.Delete(FIterator.Node);
    DoSendMessage(TDeletedMessage.Create);
    // update the iterator
    if GoToMove then
      FIterator.SetValues(FIterator.List,
        FIterator.List.LastMoveNode(NewNode))
    else
      FIterator.SetValues(FIterator.List, NewNode);
  end;
  Changed;
  DoChange;
  if TailChanges then
    DoChangeTail;
  DoEndAction(naErase);
end;

function TChessNotation.CanTruncate: boolean;
  // Returns True if we can truncate the notation.
begin
  Result := FIterator.List.Last <> FIterator.Node;
  if Result then
    Result := DoActionAccept(naTruncate);
end;

procedure TChessNotation.Truncate(GoToMove: boolean);
// Truncates the notation.
var
  TailChanges: boolean;
  WasLastMove: TMoveNode;
  VarNode, NewNode: TNotationNode;
  NewList: TNotationList;
begin
  if not CanTruncate then
    Exit;
  DoBeginAction(naTruncate);
  TailChanges := False;
  Changing;
  if (FIterator.List.Parent <> nil) and
    (FIterator.List.LastMoveNode(FIterator.Node) = nil) then
  begin
    // it's a variation and it'll be empty, let's delete it!
    VarNode := FIterator.List.Parent;
    NewList := VarNode.Parent;
    NewNode := VarNode.Prev;
    DoSendMessage(TDeletingMessage.Create(VarNode));
    NewList.Delete(VarNode);
    DoSendMessage(TDeletedMessage.Create);
    // update the iterator
    if GoToMove then
      FIterator.SetValues(NewList,
        NewList.LastMoveNode(NewNode))
    else
      FIterator.SetValues(NewList, NewNode);
  end
  else
  begin
    // just truncate the list
    WasLastMove := FIterator.List.LastMoveNode;
    with FIterator do
      DoSendMessage(TDeletingTailMessage.Create(List.NextNode(Node)));
    FIterator.List.Truncate(FIterator.Node);
    FIterator.List.UpdateGameResult(True);
    DoSendMessage(TDeletedTailMessage.Create);
    // update the iterator
    if GoToMove then
      FIterator.SetValues(FIterator.List,
        FIterator.List.LastMoveNode)
    else
      FIterator.SetValues(FIterator.List, FIterator.List.Last);
    // update TailChanges
    TailChanges := (FIterator.List = FList) and (WasLastMove <>
      FIterator.List.LastMoveNode);
  end;
  Changed;
  DoChange;
  if TailChanges then
    DoChangeTail;
  DoEndAction(naTruncate);
end;

function TChessNotation.CanEditComment: boolean;
  // Returns True if we can change current comment.
begin
  if FIterator.Node = nil then
    Exit(False);
  Result := (FIterator.Node is TTextCommentNode) and DoActionAccept(naEditComment);
end;

procedure TChessNotation.EditComment(const Comment: string);
// Changes current comment.
begin
  if not CanEditComment then
    Exit;
  DoBeginAction(naEditComment);
  Changing;
  (FIterator.Node as TTextCommentNode).Comment := Comment;
  DoSendMessage(TEditMessage.Create(FIterator.Node));
  Changed;
  DoChange;
  DoEndAction(naEditComment);
end;

function TChessNotation.CanEditNAG: boolean;
  // Returns True if we can change current NAG.
begin
  if FIterator.Node = nil then
    Exit(False);
  Result := (FIterator.Node is TNAGNode) and DoActionAccept(naEditNAG);
end;

procedure TChessNotation.EditNAG(NAG: byte);
// Changes current NAG.
begin
  if not CanEditNAG then
    Exit;
  DoBeginAction(naEditNAG);
  Changing;
  (FIterator.Node as TNAGNode).NAG := NAG;
  DoSendMessage(TEditMessage.Create(FIterator.Node));
  Changed;
  DoChange;
  DoEndAction(naEditNAG);
end;

function TChessNotation.CanInsertComment: boolean;
  // Returns True if we can insert a comment.
begin
  Result := DoActionAccept(naInsertComment);
end;

procedure TChessNotation.InsertComment(const Comment: string);
// Inserts a comment here.
var
  ANode: TTextCommentNode;
begin
  if not CanInsertComment then
    Exit;
  DoBeginAction(naInsertComment);
  ANode := TTextCommentNode.Create(nil, Comment);
  Changing;
  FIterator.List.InsertAfter(FIterator.Node, ANode);
  DoSendMessage(TInsertMessage.Create(ANode));
  FIterator.Next;
  Changed;
  DoChange;
  DoEndAction(naInsertComment);
end;

function TChessNotation.CanInsertNAG: boolean;
  // Returns True if we can insert a NAG.
begin
  Result := DoActionAccept(naInsertNAG);
end;

procedure TChessNotation.InsertNAG(NAG: byte);
// Inserts a NAG here.
var
  ANode: TNAGNode;
begin
  if not CanInsertNAG then
    Exit;
  DoBeginAction(naInsertNAG);
  ANode := TNAGNode.Create(nil, NAG);
  Changing;
  FIterator.List.InsertAfter(FIterator.Node, ANode);
  DoSendMessage(TInsertMessage.Create(ANode));
  FIterator.Next;
  Changed;
  DoChange;
  DoEndAction(naInsertNAG);
end;

function TChessNotation.CanMoveUp: boolean;
  // Returns True if we can move current node up.
begin
  if FIterator.Node = nil then
    Exit(False);
  Result := CanSwapNeighbour(FIterator.Node.Prev, FIterator.Node) and
    DoActionAccept(naMoveUp);
end;

procedure TChessNotation.MoveUp;
// Moves current node up.
begin
  if not CanMoveUp then
    Exit;
  DoBeginAction(naMoveUp);
  SwapNeighbour(FIterator.Node.Prev, FIterator.Node);
  DoEndAction(naMoveUp);
end;

function TChessNotation.CanMoveDown: boolean;
  // Returns True if we can move current node down.
begin
  if FIterator.Node = nil then
    Exit(False);
  Result := CanSwapNeighbour(FIterator.Node, FIterator.Node.Next) and
    DoActionAccept(naMoveDown);
end;

procedure TChessNotation.MoveDown;
// Moves current node down.
begin
  if not CanMoveDown then
    Exit;
  DoBeginAction(naMoveDown);
  SwapNeighbour(FIterator.Node, FIterator.Node.Next);
  DoEndAction(naMoveDown);
end;

function TChessNotation.CanPaste: boolean;
  // Returns True if we can paste PGN.
begin
  Result := DoActionAccept(naPaste);
end;

procedure TChessNotation.Paste(APGNString: string);
// Pastes PGN.
var
  P: integer;
begin
  if not CanPaste then
    Exit;
  DoBeginAction(naPaste);
  FList.GameResult := MakeGameResult(geNone, gwNone); // clear game result
  Changing;
  try
    // parse tags
    Tags.Clear;
    P := 1;
    Tags.AddTagsFromStr(APGNString, P);
    Delete(APGNString, 1, P - 1);
    // use tags
    ClearUsingTags;
    // assign the PGN string
    FList.PGNString := APGNString;
  finally
    // now, everything's changed... :)
    DoUpdate;
    Changed;
    DoChange;
    DoChangeTail;
    DoEndAction(naPaste);
  end;
end;

constructor TChessNotation.Create(ABoard: TChessBoard);
begin
  inherited Create;
  FObjTag := nil;
  FChanging := 0;
  FBoard := ABoard;
  FList := TNotationList.Create;
  FList.OnChange := @Changer;
  FList.OnChangeGameResult := @GameResultChanger;
  FTags := TPGNTags.Create;
  FTags.OnChange := @Changer;
  FIterator := GetEndIter;
  FSendMessages := True;
  FIterator.OnChange := @IteratorChanger;
  FGameResUpdating := 0;
  FGameResPerform := False;
end;

destructor TChessNotation.Destroy;
begin
  FreeAndNil(FList);
  FreeAndNil(FTags);
  FreeAndNil(FIterator);
  FreeAndNil(FObjTag);
  inherited Destroy;
end;

end.
