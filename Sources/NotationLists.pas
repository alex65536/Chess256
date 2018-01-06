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
    This unit is a core of the chess notation. It implements chess notation as
    a linked list. The chess notation list and node classes are defined here.
}

{
This unit is BETA. It will be improved later.
------------------------------------------------------
To improve:
  * Improve PGNParser.inc.
  * Calc temp game results. (?)
  * Then, optimize parsing asymptotics to O(N) from O(N^2) because of game results
  * Don't allow moves after the game end.
}
unit NotationLists;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Classes, SysUtils, NotationUtils, ChessRules, PGNUtils, MoveConverters,
  ChessUtils, BoardHashes, MoveChains, ChessTime;

const
  GameResultMeanings: array [TGameWinner] of string = ('*', '1-0', '0-1', '1/2-1/2');

resourcestring
  SPropertyInRoot = '%s property should be set only in root!';
  SUnknownPGNError = 'Unknown PGN error.';
  SWrongNode = 'Some nodes in TNotationList cannot be saved to PGN.';
  SBadMove = 'Bad move.';
  SWrongPGN = 'There are errors in PGN.';
  SUnclosedVariation = 'Unclosed variation.';
  SUnclosedComment = 'Unclosed comment.';
  SInvalidNAG = 'Invalid NAG label.';
  SWrongVariationPosition = 'Variation cannot stay here.';
  SDifferentGameResults = 'Two different game results detected.';
  SMoveAfterGameEnd = 'Making moves after the game end is not allowed.';

type
  TPGNReadWriteResult = (prOK, prWrongNode, prBadMove, prWrongPGN,
    prUnclosedVariation, prUnclosedComment, prInvalidNAG,
    prWrongVariationPosition, prDifferentGameResults,
    prMoveAfterGameEnd);

const
  PGNReadWriteResultToString: array [TPGNReadWriteResult] of string =
    (
    SUnknownPGNError,
    SWrongNode,
    SBadMove,
    SWrongPGN,
    SUnclosedVariation,
    SUnclosedComment,
    SInvalidNAG,
    SWrongVariationPosition,
    SDifferentGameResults,
    SMoveAfterGameEnd
    );

type

  TMoveDirection = (mdForward, mdBackward);

  EPGNReadWrite = class(Exception)
  public
    constructor Create(AResult: TPGNReadWriteResult); overload;
  end;

  ENotationList = class(Exception);

  TNotationList = class;

  { TNotationObjectTag }

  TNotationObjectTag = class
  public
    constructor Create; virtual;
    procedure Assign(Source: TNotationObjectTag);
    procedure AssignTo(Target: TNotationObjectTag); virtual; abstract;
  end;

  TNotationObjectTagClass = class of TNotationObjectTag;

  { TNotationNode }

  TNotationNode = class(TListNode)
  private
    FObjTag: TNotationObjectTag;
    FOnChange: TNotifyEvent;
    FOnChangeGameResult: TNotifyEvent;
    FParent: TNotationList;
    // Getters / Setters
    function GetNext: TNotationNode;
    function GetPrev: TNotationNode;
    procedure SetOnChange(AValue: TNotifyEvent);
    procedure SetOnChangeGameResult(AValue: TNotifyEvent);
    procedure SetParent(AValue: TNotationList);
  protected
    procedure DoChange;
    procedure Update(AParent: TNotationList); virtual;
  public
    // Properties
    property Prev: TNotationNode read GetPrev;
    property Next: TNotationNode read GetNext;
    property Parent: TNotationList read FParent write SetParent;
    property ObjTag: TNotationObjectTag read FObjTag write FObjTag;
    // Events (can be updated only in root!)
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
    property OnChangeGameResult: TNotifyEvent
      read FOnChangeGameResult write SetOnChangeGameResult;
    // Methods
    procedure AssignTo(Target: TListNode); override; // does not call DoChange!!!
    constructor Create; override; overload;
    constructor Create(AParent: TNotationList); overload;
    destructor Destroy; override;
  end;

  { TMoveNode }

  TMoveNode = class(TNotationNode)
  private
    FClockMark: RChessClock;
    FOldBoard: RRawBoard;
    FNewBoard: RRawBoard;
    FMove: RChessMove;
    procedure SetMove(AValue: RChessMove);
    procedure SetOldBoard(AValue: RRawBoard);
    procedure CalcNewBoard;
  public
    // Properties
    property ClockMark: RChessClock read FClockMark write FClockMark;
    // clock mark, required for TChessGame.
    property Move: RChessMove read FMove write SetMove;
    property OldBoard: RRawBoard read FOldBoard write SetOldBoard;
    property NewBoard: RRawBoard read FNewBoard;
    // Methods
    procedure AssignTo(Target: TListNode); override;
    procedure UpdateBoth(AOldBoard: RRawBoard; AMove: RChessMove);
    function FirstMove: boolean;
    constructor Create(AParent: TNotationList; AOldBoard: RRawBoard; AMove: RChessMove);
  end;

  TShortCommentNode = class(TNotationNode);
  TLongCommentNode = class(TNotationNode);

  { TTextCommentNode }

  TTextCommentNode = class(TLongCommentNode)
  private
    FComment: string;
    procedure SetComment(AValue: string);
  public
    property Comment: string read FComment write SetComment;
    procedure AssignTo(Target: TListNode); override;
    constructor Create(AParent: TNotationList; const AComment: string);
  end;

  { TNAGNode }

  TNAGNode = class(TShortCommentNode)
  private
    FNAG: byte;
    procedure SetNAG(AValue: byte);
  public
    property NAG: byte read FNAG write SetNAG;
    procedure AssignTo(Target: TListNode); override;
    constructor Create(AParent: TNotationList; ANAG: byte);
  end;

  { TVariationNode }

  TVariationNode = class(TNotationNode)
  private
    FList: TNotationList;
    procedure SetList(AValue: TNotationList);
  protected
    procedure Update(AParent: TNotationList); override;
  public
    property List: TNotationList read FList write SetList;
    procedure AssignTo(Target: TListNode); override;
    constructor Create; override;
    destructor Destroy; override;
  end;

  { TNotationIterator }

  TNotationIterator = class(TChessObject)
  private
    FList: TNotationList;
    FNode: TNotationNode;
  public
    // Properties
    property List: TNotationList read FList;
    property Node: TNotationNode read FNode;
    // Checks
    function IsFirst: boolean;
    function IsLast: boolean;
    function IsFirstMove: boolean;
    function IsLastMove: boolean;
    // Actions
    function Next: boolean;
    function Prev: boolean;
    function NextMove: boolean;
    function PrevMove: boolean;
    // Methods
    procedure SetValues(AList: TNotationList; ANode: TNotationNode);
    function EqualTo(AIter: TNotationIterator): boolean;
    constructor Create;
    procedure Assign(Source: TNotationIterator);
    procedure AssignTo(Target: TNotationIterator);
  end;

  { TNotationList }

  TNotationList = class(TDoubleLinkList)
  private
    FBaseBoard: RRawBoard;
    FGameResult: RGameResult;
    FClockMark: RChessClock;
    FObjTag: TNotationObjectTag;
    FParent: TNotationNode;
    FDepth: integer;
    FChessBoard: TChessBoard;
    FOnChangeGameResult: TNotifyEvent;
    // Getters / Setters
    function GetBaseBoardFEN: string;
    function GetCurBoard: RRawBoard;
    function GetCurBoardFEN: string;
    function GetFirst: TNotationNode;
    function GetLast: TNotationNode;
    function GetOnChange: TNotifyEvent;
    function GetPGNString: string;
    procedure SetGameResult(AValue: RGameResult);
    procedure SetPGNString(AValue: string);
    procedure SetOnChangeGameResult(AValue: TNotifyEvent);
    procedure InternalSetOnChange(AValue: TNotifyEvent);
    procedure SetOnChange(AValue: TNotifyEvent);
  protected
    procedure DoUpdateItems(ABeg, AEnd: TListNode); override;
    procedure DoChangeGameResult;
    // Parsers (implemented in PGNParser.inc)
    function ParseFromPGNString(const S: string; var Pos: integer): TPGNReadWriteResult;
    function SaveToPGNString(out S: string;
      SaveGameResult: boolean): TPGNReadWriteResult;
  public
    // Properties
    property PGNString: string read GetPGNString write SetPGNString;
    property Parent: TNotationNode read FParent;
    property First: TNotationNode read GetFirst;
    property Last: TNotationNode read GetLast;
    property BaseBoard: RRawBoard read FBaseBoard;
    property BaseBoardFEN: string read GetBaseBoardFEN;
    property CurBoard: RRawBoard read GetCurBoard;
    property CurBoardFEN: string read GetCurBoardFEN;
    property GameResult: RGameResult read FGameResult write SetGameResult;
    property ClockMark: RChessClock read FClockMark write FClockMark;
    // clock mark, required for TChessGame.
    property ObjTag: TNotationObjectTag read FObjTag write FObjTag;
    property Depth: integer read FDepth;
    // Events
    property OnChange: TNotifyEvent read GetOnChange write SetOnChange;
    property OnChangeGameResult: TNotifyEvent
      read FOnChangeGameResult write SetOnChangeGameResult;
    // Functions
    function GetMoveChain(LastItem: TNotationNode): TMoveChain;
    function GetBegIter: TNotationIterator;
    function GetEndIter: TNotationIterator;
    function PrevNode(Node: TNotationNode): TNotationNode;
    function NextNode(Node: TNotationNode): TNotationNode;
    function LastMoveNode(LastItem: TNotationNode;
      Direction: TMoveDirection = mdBackward): TMoveNode;
    function LastMoveNode: TMoveNode;
    function IsRepetitions: boolean;
    function GameFinished: boolean;
    // Other methods
    procedure Clear(const ABaseBoard: RRawBoard); overload;
    procedure Update; override;
    procedure UpdateGameResult(RepetitionCheck: boolean);
    procedure AssignTo(ATarget: TDoubleLinkList); override;
    procedure DoChange(RecalcGameEnd: boolean);
    procedure DoChange; override;
    constructor Create; override;
    constructor Create(AParent: TNotationNode);
    destructor Destroy; override;
  end;

procedure IncNode(var Node: TNotationNode);
procedure DecNode(var Node: TNotationNode);
procedure AssignNotationTag(var WasTag: TNotationObjectTag; NewTag: TNotationObjectTag);

implementation

procedure IncNode(var Node: TNotationNode);
// Changes Node to the next one.
begin
  NotationUtils.IncNode(TListNode(Node));
end;

procedure DecNode(var Node: TNotationNode);
// Changes Node to the previous one.
begin
  NotationUtils.DecNode(TListNode(Node));
end;

procedure AssignNotationTag(var WasTag: TNotationObjectTag; NewTag: TNotationObjectTag);
// Copies WasTag to NewTag.
begin
  FreeAndNil(WasTag);
  if NewTag = nil then
    Exit;
  WasTag := TNotationObjectTagClass(NewTag.ClassType).Create;
  WasTag.Assign(NewTag);
end;

{ EPGNReadWrite }

constructor EPGNReadWrite.Create(AResult: TPGNReadWriteResult);
begin
  inherited Create(PGNReadWriteResultToString[AResult]);
end;

{ TNotationObjectTag }

constructor TNotationObjectTag.Create;
begin
end;

procedure TNotationObjectTag.Assign(Source: TNotationObjectTag);
// Copies Source to Self.
begin
  Source.AssignTo(Self);
end;

{ TNotationNode }

function TNotationNode.GetNext: TNotationNode;
begin
  Result := TNotationNode(inherited Next);
end;

function TNotationNode.GetPrev: TNotationNode;
begin
  Result := TNotationNode(inherited Prev);
end;

procedure TNotationNode.SetOnChange(AValue: TNotifyEvent);
begin
  if FOnChange = AValue then
    Exit;
  // OnChange can be set from property only in root!
  if FParent <> nil then
    raise ENotationList.CreateFmt(SPropertyInRoot, ['OnChange']);
  // assign
  FOnChange := AValue;
  // update for children
  Update(FParent);
end;

procedure TNotationNode.SetOnChangeGameResult(AValue: TNotifyEvent);
begin
  if FOnChangeGameResult = AValue then
    Exit;
  // OnChangeGameResult can be set from property only in root!
  if FParent <> nil then
    raise ENotationList.CreateFmt(SPropertyInRoot, ['OnChangeGameResult']);
  // assign
  FOnChangeGameResult := AValue;
  // update for children
  Update(FParent);
end;

procedure TNotationNode.SetParent(AValue: TNotationList);
begin
  if FParent = AValue then
    Exit;
  Update(AValue);
end;

procedure TNotationNode.DoChange;
// Calls when something has changed.
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TNotationNode.Update(AParent: TNotationList);
// Updates this node and its children.
begin
  FParent := AParent;
  if FParent <> nil then
  begin
    FOnChange := FParent.OnChange;
    FOnChangeGameResult := FParent.OnChangeGameResult;
  end;
end;

procedure TNotationNode.AssignTo(Target: TListNode);
begin
  (Target as TNotationNode).Update(FParent);
  AssignNotationTag((Target as TNotationNode).FObjTag, Self.FObjTag);
end;

constructor TNotationNode.Create;
begin
  inherited Create;
  FObjTag := nil;
  FParent := nil;
end;

constructor TNotationNode.Create(AParent: TNotationList);
begin
  Create;
  Update(AParent);
end;

destructor TNotationNode.Destroy;
begin
  FreeAndNil(FObjTag);
  inherited Destroy;
end;

{ TMoveNode }

procedure TMoveNode.SetMove(AValue: RChessMove);
begin
  if FMove = AValue then
    Exit;
  FMove := AValue;
  CalcNewBoard;
  DoChange;
end;

procedure TMoveNode.SetOldBoard(AValue: RRawBoard);
begin
  if FOldBoard = AValue then
    Exit;
  FOldBoard := AValue;
  CalcNewBoard;
  DoChange;
end;

procedure TMoveNode.CalcNewBoard;
// Calculates FNewBoard.
var
  ABoard: TChessBoard;
begin
  ABoard := TChessBoard.Create(False);
  try
    ABoard.RawBoard := FOldBoard;
    ABoard.MakeMove(FMove);
    FNewBoard := ABoard.RawBoard;
  finally
    FreeAndNil(ABoard);
  end;
end;

procedure TMoveNode.AssignTo(Target: TListNode);
begin
  (Target as TMoveNode).FOldBoard := FOldBoard;
  (Target as TMoveNode).FNewBoard := FNewBoard;
  (Target as TMoveNode).FMove := FMove;
  (Target as TMoveNode).FClockMark := FClockMark;
  inherited AssignTo(Target);
end;

procedure TMoveNode.UpdateBoth(AOldBoard: RRawBoard; AMove: RChessMove);
// Assigning both OldBoard and Move.
begin
  FMove := AMove;
  FOldBoard := AOldBoard;
  CalcNewBoard;
  DoChange;
end;

function TMoveNode.FirstMove: boolean;
  // Returns True, if this move in the notation must be written as first move.
  // For example, move "e5" will be written as "1... e5" if FirstMove = True and
  // just "e5" if FirstMove = False.
var
  CurNode: TNotationNode;
begin
  Result := False;
  CurNode := Prev;
  while CurNode <> nil do
  begin
    if CurNode is TMoveNode then
      Exit;
    if CurNode is TVariationNode then
      Break;
    if CurNode is TLongCommentNode then
      Break;
    if CurNode is TShortCommentNode then
    begin { skip }
    end;
    DecNode(CurNode);
  end;
  Result := True;
end;

constructor TMoveNode.Create(AParent: TNotationList; AOldBoard: RRawBoard;
  AMove: RChessMove);
begin
  inherited Create(AParent);
  FMove := AMove;
  FOldBoard := AOldBoard;
  CalcNewBoard;
end;

{ TTextCommentNode }

procedure TTextCommentNode.SetComment(AValue: string);
begin
  if FComment = AValue then
    Exit;
  FComment := AValue;
  DoChange;
end;

procedure TTextCommentNode.AssignTo(Target: TListNode);
begin
  (Target as TTextCommentNode).FComment := FComment;
  inherited AssignTo(Target);
end;

constructor TTextCommentNode.Create(AParent: TNotationList; const AComment: string);
begin
  inherited Create(AParent);
  FComment := AComment;
end;

{ TNAGLabelNode }

procedure TNAGNode.SetNAG(AValue: byte);
begin
  if FNAG = AValue then
    Exit;
  FNAG := AValue;
  DoChange;
end;

procedure TNAGNode.AssignTo(Target: TListNode);
begin
  (Target as TNAGNode).FNAG := FNAG;
  inherited AssignTo(Target);
end;

constructor TNAGNode.Create(AParent: TNotationList; ANAG: byte);
begin
  inherited Create(AParent);
  FNAG := ANAG;
end;

{ TVariationNode }

procedure TVariationNode.SetList(AValue: TNotationList);
begin
  if (FList = AValue) or (AValue = nil) then
    Exit;
  FList.Assign(AValue);
end;

procedure TVariationNode.Update(AParent: TNotationList);
begin
  inherited Update(AParent);
  FList.Update;
end;

procedure TVariationNode.AssignTo(Target: TListNode);
begin
  (Target as TVariationNode).SetList(FList);
  inherited AssignTo(Target);
end;

constructor TVariationNode.Create;
begin
  inherited Create;
  FList := TNotationList.Create(Self);
end;

destructor TVariationNode.Destroy;
begin
  FreeAndNil(FList);
  inherited Destroy;
end;

{ TNotationIterator }

function TNotationIterator.IsFirst: boolean;
  // Returns True if current node is first node (we can't do Prev).
begin
  if FList = nil then
    Exit(True);
  // it must be main line and Node = nil
  Result := (FNode = nil) and ((FList.Parent = nil) or (FList.Parent.Parent = nil));
end;

function TNotationIterator.IsLast: boolean;
  // Returns True if current node is last node (we can't do Next).
begin
  if FList = nil then
    Exit(True);
  // it must be main line and Node = List.Last
  Result := (FNode = FList.Last) and ((FList.Parent = nil) or
    (FList.Parent.Parent = nil));
end;

function TNotationIterator.IsFirstMove: boolean;
  // Returns True if current node is first move (we can't do PrevMove).
begin
  if List = nil then
    Exit(True);
  // it must be main line and Node = nil
  Result := (FNode = nil) and ((FList.Parent = nil) or (FList.Parent.Parent = nil));
end;

function TNotationIterator.IsLastMove: boolean;
  // Returns True if current node is last move (we can't do NextMove).
begin
  if List = nil then
    Exit(True);
  // it must have no moves after Node in this list
  Result := FList.LastMoveNode = FNode;
end;

function TNotationIterator.Next: boolean;
  // Goes to the next node.
begin
  // check if we can do it
  if IsLast then
    Exit(False);
  Result := True;
  // let's go!
  BeginUpdate;
  // if last node in list - go out of the variation
  if FNode = FList.Last then
  begin
    FNode := FList.Parent;
    FList := FNode.Parent;
  end
  // otherwise, just go to the next node
  else
  begin
    FNode := FList.NextNode(FNode);
    // if next node is variation - "dive" into it.
    if (FNode <> nil) and (FNode is TVariationNode) then
    begin
      FList := TVariationNode(FNode).List;
      FNode := nil;
    end;
  end;
  EndUpdate;
  DoChange;
end;

function TNotationIterator.Prev: boolean;
  // Goes to the previous node.
begin
  // check if we can do it
  if IsFirst then
    Exit(False);
  Result := True;
  // let's go!
  BeginUpdate;
  // if it's a variation node - "dive" into it.
  if (FNode <> nil) and (FNode is TVariationNode) then
  begin
    FList := TVariationNode(FNode).List;
    FNode := TNotationNode(FList.Last);
  end
  // if Node = nil (beginning of the list) - go out of the variation
  else if FNode = nil then
  begin
    FNode := TNotationNode(FList.Parent.Prev);
    FList := FList.Parent.Parent;
  end
  // otherwise, just go to the previous node
  else
    FNode := TNotationNode(FNode.Prev);
  EndUpdate;
  DoChange;
end;

function TNotationIterator.NextMove: boolean;
  // Goes to the next move.
begin
  // check if we can do it
  if IsLastMove then
    Exit(False);
  Result := True;
  // let's go!
  BeginUpdate;
  // just find the next move in the list
  FNode := FList.LastMoveNode(FList.NextNode(FNode), mdForward);
  EndUpdate;
  DoChange;
end;

function TNotationIterator.PrevMove: boolean;
  // Goes to the previous move.
begin
  // check if we can do it
  if IsFirstMove then
    Exit(False);
  Result := True;
  // let's go!
  BeginUpdate;
  // find the previous move in the list
  if FNode <> nil then
    FNode := FList.LastMoveNode(FNode.Prev, mdBackward);
  // go up until we reach the top of the structure
  // or our Node will be non-Nil.
  while (FNode = nil) and (FList.Parent <> nil) and (FList.Parent.Parent <> nil) do
  begin
    // go up
    FNode := FList.Parent;
    FList := FNode.Parent;
    // find last move
    FNode := FList.LastMoveNode(FNode.Prev, mdBackward);
    // skip it
    FNode := FList.LastMoveNode(FNode.Prev, mdBackward);
  end;
  EndUpdate;
  DoChange;
end;

procedure TNotationIterator.SetValues(AList: TNotationList; ANode: TNotationNode);
// Assign both List and Node.
begin
  FList := AList;
  FNode := ANode;
  DoChange;
end;

function TNotationIterator.EqualTo(AIter: TNotationIterator): boolean;
  // Returns True if iterators point at the same position in the same list.
begin
  Result := (Self.FList = AIter.FList) and (Self.FNode = AIter.FNode);
end;

constructor TNotationIterator.Create;
begin
  FList := nil;
  FNode := nil;
end;

procedure TNotationIterator.Assign(Source: TNotationIterator);
begin
  Source.AssignTo(Self);
end;

procedure TNotationIterator.AssignTo(Target: TNotationIterator);
begin
  Target.FList := FList;
  Target.FNode := FNode;
  Target.DoChange;
end;

{ TNotationList }

function TNotationList.GetBaseBoardFEN: string;
begin
  FChessBoard.RawBoard := BaseBoard;
  Result := FChessBoard.FENString;
end;

function TNotationList.GetCurBoard: RRawBoard;
var
  Node: TMoveNode;
begin
  Node := LastMoveNode;
  if Node = nil then
    Result := BaseBoard
  else
    Result := Node.NewBoard;
end;

function TNotationList.GetCurBoardFEN: string;
begin
  FChessBoard.RawBoard := CurBoard;
  Result := FChessBoard.FENString;
end;

function TNotationList.GetFirst: TNotationNode;
begin
  Result := TNotationNode(inherited First);
end;

function TNotationList.GetLast: TNotationNode;
begin
  Result := TNotationNode(inherited Last);
end;

function TNotationList.GetOnChange: TNotifyEvent;
begin
  Result := inherited OnChange;
end;

function TNotationList.GetPGNString: string;
var
  S: string;
  Res: TPGNReadWriteResult;
begin
  Result := '';
  try
    Res := SaveToPGNString(S, True);
  finally
    Result := CutString(S, PGNStrLen);
  end;
  if Res <> prOK then
    raise EPGNReadWrite.Create(Res);
end;

procedure TNotationList.SetGameResult(AValue: RGameResult);
begin
  if FGameResult = AValue then
    Exit;
  FGameResult := AValue;
  DoChangeGameResult;
end;

procedure TNotationList.SetPGNString(AValue: string);
var
  I: integer;
  Res: TPGNReadWriteResult;
begin
  I := 1;
  Res := ParseFromPGNString(DeCutString(AValue), I);
  if Res <> prOK then
    raise EPGNReadWrite.Create(Res);
end;

procedure TNotationList.SetOnChangeGameResult(AValue: TNotifyEvent);
begin
  if FOnChangeGameResult = AValue then
    Exit;
  if FParent <> nil then
    raise ENotationList.CreateFmt(SPropertyInRoot, ['OnChangeGameResult']);
  FOnChangeGameResult := AValue;
  Update;
end;

procedure TNotationList.InternalSetOnChange(AValue: TNotifyEvent);
// Internal SetOnChange (allows to change OnChange not from the root).
begin
  inherited OnChange := AValue;
end;

procedure TNotationList.SetOnChange(AValue: TNotifyEvent);
begin
  if OnChange = AValue then
    Exit;
  if FParent <> nil then
    raise ENotationList.CreateFmt(SPropertyInRoot, ['OnChange']);
  InternalSetOnChange(AValue);
  Update;
end;

procedure TNotationList.DoUpdateItems(ABeg, AEnd: TListNode);
var
  It: TListNode;
begin
  inherited DoUpdateItems(ABeg, AEnd);
  It := ABeg;
  NotationUtils.IncNode(AEnd);
  while (It <> nil) and (It <> AEnd) do
  begin
    (It as TNotationNode).Update(Self);
    NotationUtils.IncNode(It);
  end;
end;

procedure TNotationList.DoChangeGameResult;
begin
  if Assigned(FOnChangeGameResult) then
    FOnChangeGameResult(Self);
end;

// PGNParser.inc contains ParseFromPGNString & SaveToPGNString.
{$I PGNParser.inc}

function TNotationList.GetMoveChain(LastItem: TNotationNode): TMoveChain;
  // Returns the move chain that ends in LastItem.
var
  Iter: TNotationIterator;

  procedure RecursivePut(AList: TNotationList; ANode: TNotationNode);
  // Fills the move chain recursively.
  begin
    Iter.SetValues(AList, ANode);
    // first move is out exit from the recursion
    if Iter.IsFirstMove then
    begin
      Result.Clear(AList.BaseBoard);
      Exit;
    end;
    // otherwise, find the prev move and launch from it recursively
    Iter.PrevMove;
    RecursivePut(Iter.List, Iter.Node);
    Result.Add((ANode as TMoveNode).Move);
  end;

begin
  // create our chain
  Result := TMoveChain.Create;
  Result.Validation := False;
  // assign iterator
  Iter := TNotationIterator.Create;
  Iter.SetValues(Self, LastMoveNode(LastItem));
  if Iter.Node = nil then
    Iter.PrevMove;
  // put everything recursively
  RecursivePut(Iter.List, Iter.Node);
  // finish the chain getting
  FreeAndNil(Iter);
  Result.Validation := True;
end;

function TNotationList.GetBegIter: TNotationIterator;
  // Returns the iterator to the beginning.
begin
  Result := TNotationIterator.Create;
  Result.FList := Self;
  Result.FNode := nil;
end;

function TNotationList.GetEndIter: TNotationIterator;
  // Returns the iterator to the ending.
begin
  Result := TNotationIterator.Create;
  Result.FList := Self;
  Result.FNode := TNotationNode(Last);
end;

function TNotationList.PrevNode(Node: TNotationNode): TNotationNode;
begin
  Result := TNotationNode(inherited PrevNode(Node));
end;

function TNotationList.NextNode(Node: TNotationNode): TNotationNode;
begin
  Result := TNotationNode(inherited NextNode(Node));
end;

function TNotationList.LastMoveNode(LastItem: TNotationNode;
  Direction: TMoveDirection): TMoveNode;
  // Searches for nearest move node. It starts searching from LastItem and goes
  // in a given direction. Returns the first move node that it meets. If it meets
  // no move nodes, returns Nil.
var
  It: TNotationNode;
begin
  Result := nil;
  It := LastItem;
  if It = nil then
    Exit;
  while not (It is TMoveNode) do
  begin
    if Direction = mdForward then
      IncNode(It)
    else
      DecNode(It);
    if It = nil then
      Exit;
  end;
  Result := It as TMoveNode;
end;

function TNotationList.LastMoveNode: TMoveNode;
  // Returns the last move node.
begin
  Result := LastMoveNode(Last);
end;

function TNotationList.IsRepetitions: boolean;
  // Returns True if draw by repetitions.
var
  Iter: TNotationIterator;
  RepCount: integer;
  CmpBoard: RRawBoard;

  function CmpBoards(const A, B: RRawBoard): boolean; inline;
    // Board comparator (unusual because we need no to compare such fields as
    // MoveCounter and MoveNumber).
  begin
    Result := RRepBoard(A) = RRepBoard(B);
  end;

begin
  // set the iterator
  Iter := TNotationIterator.Create;
  Iter.SetValues(Self, LastMoveNode);
  if Iter.Node = nil then
    Iter.PrevMove;
  // iterating through the moves
  RepCount := 0;
  CmpBoard := CurBoard;
  while not Iter.IsFirstMove do
  begin
    if CmpBoards((Iter.Node as TMoveNode).NewBoard, CmpBoard) then
      Inc(RepCount);
    Iter.PrevMove;
  end;
  // compare with BaseBoard
  if CmpBoards(Iter.List.BaseBoard, CmpBoard) then
    Inc(RepCount);
  // finish the method
  FreeAndNil(Iter);
  Result := RepCount >= 3;
end;

function TNotationList.GameFinished: boolean;
  // Returns True if the game was finished.
begin
  Result := GameResult.Winner <> gwNone;
end;

procedure TNotationList.Clear(const ABaseBoard: RRawBoard);
// Clears the board with the specified BaseBoard.
begin
  BeginUpdate;
  FBaseBoard := ABaseBoard;
  Clear;
  EndUpdate;
  DoChange;
end;

procedure TNotationList.Update;
begin
  if (FParent = nil) or (FParent.Parent = nil) then
    FDepth := 0
  else
    FDepth := FParent.Parent.Depth + 1;
  if FParent <> nil then
  begin
    InternalSetOnChange(FParent.FOnChange);
    FOnChangeGameResult := FParent.FOnChangeGameResult;
  end;
  inherited Update;
end;

procedure TNotationList.UpdateGameResult(RepetitionCheck: boolean);
// Updates the game result.
begin
  FChessBoard.RawBoard := CurBoard;
  if not RepetitionCheck then
    GameResult := FChessBoard.GetGameResult
  else
  begin
    if IsRepetitions then
      GameResult := MakeGameResult(geRepetitions, gwDraw)
    else
      GameResult := FChessBoard.GetGameResult;
  end;
end;

procedure TNotationList.AssignTo(ATarget: TDoubleLinkList);
var
  Target: TNotationList;
begin
  Target := ATarget as TNotationList;
  if Target = Self then
    Exit;
  Target.BeginUpdate;
  // assigning
  Target.FBaseBoard := Self.FBaseBoard;
  Target.FGameResult := Self.FGameResult;
  Target.FClockMark := Self.FClockMark;
  AssignNotationTag(Target.FObjTag, Self.FObjTag);
  inherited AssignTo(ATarget);
  // end assigning
  Target.EndUpdate;
  Target.Update;
  Target.DoChange;
end;

procedure TNotationList.DoChange;
begin
  DoChange(False);
end;

procedure TNotationList.DoChange(RecalcGameEnd: boolean);
begin
  inherited DoChange;
  if (not Updating) and RecalcGameEnd then
    UpdateGameResult(True);
end;

constructor TNotationList.Create;
begin
  inherited;
  FChessBoard := TChessBoard.Create(False);
  FBaseBoard := FChessBoard.RawBoard;
  FParent := nil;
  FObjTag := nil;
  FGameResult := MakeGameResult(geNone, gwNone);
end;

constructor TNotationList.Create(AParent: TNotationNode);
begin
  Create;
  FParent := AParent;
end;

destructor TNotationList.Destroy;
begin
  FreeAndNil(FChessBoard);
  FreeAndNil(FObjTag);
  inherited Destroy;
end;

end.
