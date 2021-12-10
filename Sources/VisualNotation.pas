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
    This unit contains TVisualChessNotation - a component to visualize the chess
    notation.
}
unit VisualNotation;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  Classes, SysUtils, Forms, Controls, NotationLists, NotationMessaging,
  ChessNotation, Graphics, MoveConverters, TextViewBase, ChessRules, NAGUtils,
  ChessGUIUtils, ChessStrings, PersistentNotation;

resourcestring
  SUnknownNotationMessage = 'MsgReceiver cannot recognize a message "%s".';
  SUnknownNode = 'Unknown node in UpdateTag.';

type
  TNotationHighlight = (nhMove, nhFirstMove, nhComment, nhVariation, nhGameEnd);

const
  HighlightTable: array [TNotationHighlight] of TColor =
    (clWindowText, clBlue, clNavy, clMaroon, clGreen);
  IndentPerDepth = 10;

type

  { RNotationNodeInfo }

  RNotationNodeInfo = record
    ViewText: string;
    Highlight1, Highlight2: TNotationHighlight;
    DividePoint: integer;
    Indent: integer;
    // Moves cache
    CachedStr1, CachedStr2, CachedStr3: string;
    // Comparison operators
    class operator=(const A, B: RNotationNodeInfo): Boolean;
    class operator<>(const A, B: RNotationNodeInfo): Boolean;
  end;

  { TNotationNodeInfo }

  TNotationNodeInfo = class(TNotationObjectTag)
  public
    Info: RNotationNodeInfo;
    constructor Create(const AInfo: RNotationNodeInfo); overload;
    procedure AssignTo(Target: TNotationObjectTag); override;
  end;

  { TMyControl }

  TMyControl = class(TControl)
  public
    property OnMouseDown;
  end;

  EVisualNotation = class(Exception);

  { TVisualChessNotation }

  TVisualChessNotation = class(TFrame)
  private
    FTextViewer: TBaseTextViewer;
    FTextPosition: integer;
    FChessNotation: TPersistentChessNotation;
    // Tag work methods
    function AssignTag(ATag: TNotationNodeInfo;
      const Info: RNotationNodeInfo): TNotationNodeInfo;
    function GetTag(It: TNotationIterator): TNotationNodeInfo;
    procedure DrawTag(ATag: TNotationNodeInfo);
    // Tag associated iterators work methods
    procedure AssignInfo(It: TNotationIterator; const Info: RNotationNodeInfo);
    procedure AssignTail(const Info: RNotationNodeInfo);
    function GetItemLen(It: TNotationIterator): integer;
    function GetTailLen: integer;
    function GetTailTag: TNotationNodeInfo;
    procedure SetTailTag(AValue: TNotationNodeInfo);
    function UpdateTag(It: TNotationIterator): boolean;
    function UpdateTail: boolean;
    procedure DrawItem(It: TNotationIterator);
    procedure DrawTail;
    // Getters / Setters
    function GetBoard: TChessBoard;
    procedure SetBoard(AValue: TChessBoard);
    // Other methods
    function NAGToString(NAG: byte): string;
  protected
    // Main refreshing method. Iterator values are (nil, nil) if it's the tail.
    function GetInfo(WasTag: TNotationNodeInfo;
      It: TNotationIterator): RNotationNodeInfo;
    // Event handlers
    procedure MsgReceiver(Sender: TObject; Message: TNotationMessage);
    procedure BeginActionNotifier(Sender: TObject);
    procedure EndActionNotifier(Sender: TObject);
    procedure TextViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
  public
    property TailTag: TNotationNodeInfo read GetTailTag write SetTailTag;
    // Refreshing & updating ( these ones must work in O(N) )
    procedure UpdateCursor;
    procedure ClearList;
    procedure UpdateList;
    procedure FullRefreshList;
    procedure RedrawList;
    // Calculating text positions of iterators
    procedure GetTextParams(ABeg, AEnd: TNotationIterator; out Beg, Len: integer);
    procedure GetNodeParams(ANode: TNotationNode; out Beg, Len: integer);
    procedure GetTailParams(ANode: TNotationNode; out Beg, Len: integer);
    // Going to a definite position
    procedure MoveIter(Pos: TNotationIterator);
    procedure GoToPosition(Pos: integer);
    // Destructor
    destructor Destroy; override;
  published
    constructor Create(AOwner: TComponent); override;
    property ChessNotation: TPersistentChessNotation read FChessNotation;
    property Board: TChessBoard read GetBoard write SetBoard;
  end;

implementation

{$R *.lfm}

{ RNotationNodeInfo }

class operator RNotationNodeInfo.=(const A, B: RNotationNodeInfo): boolean;
begin
  Result := (A.ViewText = B.ViewText) and (A.Indent = B.Indent) and
    (A.Highlight1 = B.Highlight1) and (A.Highlight2 = B.Highlight2) and
    (A.DividePoint = B.DividePoint);
end;

class operator RNotationNodeInfo.<>(const A, B: RNotationNodeInfo): boolean;
begin
  Result := not (A = B);
end;

{ TNotationNodeInfo }

constructor TNotationNodeInfo.Create(const AInfo: RNotationNodeInfo);
begin
  inherited Create;
  Info := AInfo;
end;

procedure TNotationNodeInfo.AssignTo(Target: TNotationObjectTag);
begin
  (Target as TNotationNodeInfo).Info := Self.Info;
end;

{ TVisualChessNotation }

function TVisualChessNotation.AssignTag(ATag: TNotationNodeInfo;
  const Info: RNotationNodeInfo): TNotationNodeInfo;
  // Makes ATag.Info := Info (creates the tag if nessesary).
begin
  if ATag = nil then
    ATag := TNotationNodeInfo.Create;
  ATag.Info := Info;
  Result := ATag;
end;

function TVisualChessNotation.GetTag(It: TNotationIterator): TNotationNodeInfo;
  // Returns the tag assigned to iterator It.
begin
  if It.Node = nil then
    Result := It.List.ObjTag as TNotationNodeInfo
  else
    Result := It.Node.ObjTag as TNotationNodeInfo;
end;

procedure TVisualChessNotation.DrawTag(ATag: TNotationNodeInfo);
// Draws the tag at FTextPosition.
var
  Style: TCharStyle;

  procedure InsString(const S: string);
  // Inserts S to FTextPosition and updates FTextPosition.
  begin
    FTextViewer.InsertText(S, Style, FTextPosition);
    FTextPosition += Length(S);
  end;

begin
  with ATag.Info do
  begin
    Style.Indent := Indent;
    // draw before DividePoint
    if DividePoint <> 0 then
    begin
      Style.Style := Ord(Highlight1) + 1;
      InsString(Copy(ViewText, 1, DividePoint));
    end;
    // draw after DividePoint
    if DividePoint <> Length(ViewText) then
    begin
      Style.Style := Ord(Highlight2) + 1;
      InsString(Copy(ViewText, DividePoint + 1, Length(ViewText) - DividePoint));
    end;
  end;
end;

procedure TVisualChessNotation.AssignInfo(It: TNotationIterator;
  const Info: RNotationNodeInfo);
// Assigns Info to the tag associated with It.
begin
  if It.Node = nil then
    It.List.ObjTag := AssignTag(It.List.ObjTag as TNotationNodeInfo, Info)
  else
    It.Node.ObjTag := AssignTag(It.Node.ObjTag as TNotationNodeInfo, Info);
end;

procedure TVisualChessNotation.AssignTail(const Info: RNotationNodeInfo);
// Assigns Info to the tail tag.
begin
  TailTag := AssignTag(TailTag, Info);
end;

function TVisualChessNotation.GetItemLen(It: TNotationIterator): integer;
  // Returns the length of the text representation of It.
begin
  Result := Length(GetTag(It).Info.ViewText);
end;

function TVisualChessNotation.GetTailLen: integer;
  // Returns the length of the tail.
begin
  Result := Length(TailTag.Info.ViewText);
end;

function TVisualChessNotation.GetTailTag: TNotationNodeInfo;
begin
  Result := FChessNotation.ObjTag as TNotationNodeInfo;
end;

procedure TVisualChessNotation.SetTailTag(AValue: TNotationNodeInfo);
begin
  FChessNotation.ObjTag := AValue;
end;

function TVisualChessNotation.UpdateTag(It: TNotationIterator): boolean;
  // Updates the tag assigned with It. Returns True if the tag info was changed.
var
  WasTag: TNotationNodeInfo;
  WasInfo: RNotationNodeInfo;
  Info: RNotationNodeInfo;
begin
  WasTag := GetTag(It);
  if WasTag <> nil then
    WasInfo := WasTag.Info;
  // calcutlating the new info
  Info := GetInfo(WasTag, It);
  // applying the new info
  if WasTag = nil then
    Result := True
  else
    Result := WasInfo <> Info;
  AssignInfo(It, Info);
end;

function TVisualChessNotation.UpdateTail: boolean;
  // Updates the tail tag. Returns True if the tag info was changed.
var
  WasTag: TNotationNodeInfo;
  WasInfo: RNotationNodeInfo;
  It: TNotationIterator;
  Info: RNotationNodeInfo;
begin
  It := TNotationIterator.Create;
  It.SetValues(nil, nil);
  try
    WasTag := TailTag;
    if WasTag <> nil then
      WasInfo := WasTag.Info;
    // calcutlating the new info ...
    Info := GetInfo(WasTag, It);
    // applying the new info
    if WasTag = nil then
      Result := True
    else
      Result := WasInfo <> Info;
    AssignTail(Info);
  finally
    FreeAndNil(It);
  end;
end;

procedure TVisualChessNotation.DrawItem(It: TNotationIterator);
// Draws a tag associated with It.
begin
  DrawTag(GetTag(It));
end;

procedure TVisualChessNotation.DrawTail;
// Draws a tail tag.
begin
  DrawTag(TailTag);
end;

function TVisualChessNotation.GetBoard: TChessBoard;
begin
  Result := FChessNotation.Board;
end;

procedure TVisualChessNotation.SetBoard(AValue: TChessBoard);
begin
  FChessNotation.Board := AValue;
end;

function TVisualChessNotation.NAGToString(NAG: byte): string;
  // Converts NAG label to string.
begin
  Result := NAGStrings[NAG];
  if Result = '' then
    Result := '�';
end;

// GetInfo method
{$I NotationNodeDrawer.inc}

// MsgReceiver method
{$I NotationMsgReceiver.inc}

procedure TVisualChessNotation.BeginActionNotifier(Sender: TObject);
begin
  FTextViewer.BeginUpdate;
end;

procedure TVisualChessNotation.EndActionNotifier(Sender: TObject);
begin
  FTextViewer.EndUpdate;
end;

{$HINTS OFF}
procedure TVisualChessNotation.TextViewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  if Button <> mbLeft then
    Exit;
  GoToPosition(FTextViewer.CharAtPos(X, Y));
end;

{$HINTS ON}

procedure TVisualChessNotation.UpdateCursor;
// Updates the cursor position.
begin
  FTextViewer.CursorPos := FTextPosition - 1;
end;

procedure TVisualChessNotation.ClearList;
// Clears the text and all the tags there.
var
  ATag: TNotationNodeInfo;
  Iter: TNotationIterator;
begin
  // clear text
  FTextViewer.Text := ' ';
  FTextPosition := 0;
  // iterate through the tags and clear their texts
  Iter := FChessNotation.GetBegIter;
  repeat
    ATag := GetTag(Iter);
    if ATag <> nil then
      ATag.Info.ViewText := '';
  until not Iter.Next;
  // clear tail tag also.
  if TailTag <> nil then
    TailTag.Info.ViewText := '';
  FreeAndNil(Iter);
end;

procedure TVisualChessNotation.UpdateList;
// Updates all the text (if some tags changed).
var
  Chunk: TAbstractTextChunk;
  Iter: TNotationIterator;
  WasPos, WasLen, WasSize: integer;
  LastSaved: longint;
begin
  // initialize
  WasSize := Length(FTextViewer.Text);
  Chunk := FTextViewer.Copy(1, WasSize);
  FTextViewer.BeginUpdate;
  FTextViewer.Clear;
  FTextPosition := 1;
  WasPos := 1;
  LastSaved := 1;
  // FTextPosition - current text position
  // WasPos - current position in chunk
  // LastSaved - position from what we should push prom the chunk
  Iter := FChessNotation.GetBegIter;
  // now, iterate through the text pieces.
  repeat
    // calculating old length
    if GetTag(Iter) = nil then
      WasLen := 0
    else
      WasLen := GetItemLen(Iter);
    // if the tag has changed - redraw it
    if UpdateTag(Iter) then
    begin
      // push unchanged text from the chunk
      FTextViewer.AddText(Chunk, LastSaved, WasPos - LastSaved);
      // draw new text
      DrawItem(Iter);
      // update LastSaved
      LastSaved := WasPos + WasLen;
    end
    else
    begin
      // just use old text for this tag
      FTextPosition += WasLen;
    end;
    WasPos += WasLen;
  until not Iter.Next;
  // update the tail...
  begin
    // calculating old length
    if TailTag = nil then
      WasLen := 0
    else
      WasLen := GetTailLen;
    // if the tag has changed - redraw it
    if UpdateTail then
    begin
      // push unchanged text from the chunk
      FTextViewer.AddText(Chunk, LastSaved, WasPos - LastSaved);
      // draw new text
      DrawTail;
      // update LastSaved
      LastSaved := WasPos + WasLen;
    end
    else
    begin
      // just use old text for this tag
      FTextPosition += WasLen;
    end;
    WasPos += WasLen;
  end;
  // push the rest of the chunk
  FTextViewer.AddText(Chunk, LastSaved, WasSize - LastSaved + 1);
  // finish updating
  FreeAndNil(Iter);
  FreeAndNil(Chunk);
  FTextViewer.CursorPos := -1;
  FTextViewer.EndUpdate;
end;

procedure TVisualChessNotation.FullRefreshList;
// Fully refreshes the text.
begin
  FTextViewer.BeginUpdate;
  ClearList;
  UpdateList;
  FTextViewer.EndUpdate;
end;

procedure TVisualChessNotation.RedrawList;
// Just redraws the list.
var
  Iter: TNotationIterator;
begin
  FTextViewer.BeginUpdate;
  FTextViewer.Clear;
  FTextPosition := 1;
  // draw the nodes
  Iter := FChessNotation.GetBegIter;
  repeat
    DrawItem(Iter);
  until not Iter.Next;
  FreeAndNil(Iter);
  // draw the tail
  DrawTail;
  // finish the operation
  FTextViewer.AddText(' ', DefaultCharStyle);
  FTextViewer.EndUpdate;
end;

procedure TVisualChessNotation.GetTextParams(ABeg, AEnd: TNotationIterator;
  out Beg, Len: integer);
// Returns what text piece [Beg, Len] is drawn with iterators ABeg .. AEnd.
var
  Pos: integer;
  Iter: TNotationIterator;
begin
  FTextViewer.BeginUpdate;
  Beg := 0;
  Pos := 1;
  Iter := FChessNotation.GetBegIter;
  repeat
    if Iter.EqualTo(ABeg) then
      Beg := Pos;
    Pos += GetItemLen(Iter);
    if Iter.EqualTo(AEnd) then
      Len := Pos - Beg;
  until not Iter.Next;
  FreeAndNil(Iter);
  FTextViewer.EndUpdate;
end;

procedure TVisualChessNotation.GetNodeParams(ANode: TNotationNode;
  out Beg, Len: integer);
// Returns what text piece [Beg, Len] is drawn with ANode.
var
  ABeg, AEnd: TNotationIterator;
begin
  ABeg := TNotationIterator.Create;
  AEnd := TNotationIterator.Create;
  if ANode is TVariationNode then
    ABeg.SetValues((ANode as TVariationNode).List, nil)
  else
    ABeg.SetValues(ANode.Parent, ANode);
  AEnd.SetValues(ANode.Parent, ANode);
  GetTextParams(ABeg, AEnd, Beg, Len);
  FreeAndNil(ABeg);
  FreeAndNil(AEnd);
end;

procedure TVisualChessNotation.GetTailParams(ANode: TNotationNode;
  out Beg, Len: integer);
// Returns what text piece [Beg, Len] is drawn with nodes from ANode to the end of the list.
var
  ABeg, AEnd: TNotationIterator;
begin
  ABeg := TNotationIterator.Create;
  AEnd := TNotationIterator.Create;
  if ANode is TVariationNode then
    ABeg.SetValues((ANode as TVariationNode).List, nil)
  else
    ABeg.SetValues(ANode.Parent, ANode);
  AEnd.SetValues(ANode.Parent, ANode.Parent.Last);
  GetTextParams(ABeg, AEnd, Beg, Len);
  FreeAndNil(ABeg);
  FreeAndNil(AEnd);
end;

procedure TVisualChessNotation.MoveIter(Pos: TNotationIterator);
// Moves the text position to iterator pos.
var
  It: TNotationIterator;
begin
  FTextPosition := 1;
  It := FChessNotation.GetBegIter;
  repeat
    FTextPosition += GetItemLen(It);
    if It.EqualTo(Pos) then
      Break;
  until not It.Next;
  FreeAndNil(It);
end;

procedure TVisualChessNotation.GoToPosition(Pos: integer);
// Goes to position Pos in text.
var
  It: TNotationIterator;
  PosL, PosR: integer;
begin
  FTextPosition := 1;
  It := FChessNotation.GetBegIter;
  // find nearest right position
  repeat
    FTextPosition += GetItemLen(It);
    if FTextPosition > Pos then
      Break;
  until not It.Next;
  PosR := FTextPosition;
  // find nearest left position
  PosL := FTextPosition - GetItemLen(It);
  // determine which one is nearer
  if Abs(PosL - Pos) < Abs(PosR - Pos) then
    It.Prev;
  // apply the new iterator
  FChessNotation.Iterator.Assign(It);
  FreeAndNil(It);
end;

constructor TVisualChessNotation.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTextViewer := TTextViewer.Create(Self);
  FTextViewer.Control.Parent := Self;
  FTextViewer.Control.Align := alClient;
  TMyControl(FTextViewer.Control).OnMouseDown := @TextViewMouseDown;
  FChessNotation := TPersistentChessNotation.Create(nil);
  FChessNotation.OnSendMessage := @MsgReceiver;
  FChessNotation.OnBeginActionNotify := @BeginActionNotifier;
  FChessNotation.OnEndActionNotify := @EndActionNotifier;
  FTextPosition := 1;
  DoubleBuffered := True;
  UpdateCursor;
end;

destructor TVisualChessNotation.Destroy;
begin
  FreeAndNil(FChessNotation);
  inherited Destroy;
end;

procedure InitHighlightStyles;
// Creates the highlight styles.
var
  AFont: TFont;
  I: TNotationHighlight;
begin
  Styles[0].Name := DefaultChessFont;
  Styles[0].Size := DefaultChessFontSize;
  AFont := TFont.Create;
  AFont.Name := DefaultChessFont;
  AFont.Size := DefaultChessFontSize;
  for I := Low(TNotationHighlight) to High(TNotationHighlight) do
  begin
    AFont.Color := HighlightTable[I];
    AddStyle(AFont);
  end;
  FreeAndNil(AFont);
end;

initialization
  InitHighlightStyles;

end.
