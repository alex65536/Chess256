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
    This file contains a message receiver. It receives and processes the messages
    sent from the notation to TVisualChessNotation component).
}

procedure TVisualChessNotation.MsgReceiver(Sender: TObject; Message: TNotationMessage);

// Message handler methods

  procedure MsgUpdate;
  begin
    FullRefreshList;
  end;

  procedure MsgRestore;
  begin
    RedrawList;
  end;

  procedure MsgIteratorChange;
  begin
    MoveIter(FChessNotation.Iterator);
    UpdateCursor;
  end;

  procedure MsgInsert;
  begin
    UpdateList;
  end;

  procedure MsgInsertTail;
  begin
    UpdateList;
  end;

  procedure MsgDeletingTail(ANode: TNotationNode);
  var
    Beg, Len: integer;
  begin
    FTextViewer.BeginUpdate;
    GetTailParams(ANode, Beg, Len);
    FTextViewer.DeleteText(Beg, Len);
  end;

  procedure MsgDeletedTail;
  begin
    UpdateList;
    FTextViewer.EndUpdate;
  end;

  procedure MsgDeleting(ANode: TNotationNode);
  var
    Beg, Len: integer;
  begin
    FTextViewer.BeginUpdate;
    GetNodeParams(ANode, Beg, Len);
    FTextViewer.DeleteText(Beg, Len);
  end;

  procedure MsgDeleted;
  begin
    UpdateList;
    FTextViewer.EndUpdate;
  end;

  procedure MsgEdit;
  begin
    UpdateList;
    // the iterator doesn't change after TEditMessage, so we do it here.
    MoveIter(FChessNotation.Iterator);
    UpdateCursor;
  end;

  procedure MsgMovingUpDown(It1, It2: TNotationNode);
  var
    Beg1, Len1, Beg2, Len2: integer;
    Tmp: integer;
    AChunk: TAbstractTextChunk;
  begin
    FTextViewer.BeginUpdate;
    GetNodeParams(It1, Beg1, Len1);
    GetNodeParams(It2, Beg2, Len2);
    if Beg1 > Beg2 then
    begin // swap
      Tmp := Beg1;
      Beg1 := Beg2;
      Beg2 := Tmp;
      Tmp := Len1;
      Len1 := Len2;
      Len2 := Tmp;
    end;
    AChunk := FTextViewer.Copy(Beg1, Len1);
    FTextViewer.DeleteText(Beg1, Len1);
    FTextViewer.InsertText(AChunk, Beg1 + Len2, 1, Len1);
    FreeAndNil(AChunk);
  end;

  procedure MsgMovedUpDown;
  begin
    UpdateList;
    FTextViewer.EndUpdate;
  end;

  procedure MsgChangeGameEnd;
  begin
    UpdateList;
    MsgIteratorChange; // the iterator doesn't change when the game end changes!
  end;

begin
  // determine what kind of message it is and call the method to handle it.
  if Message is TUpdateMessage then
  begin
    MsgUpdate;
    Exit;
  end;
  if Message is TRestoreMessage then
  begin
    MsgRestore;
    Exit;
  end;
  if Message is TIteratorChangeMessage then
  begin
    MsgIteratorChange;
    Exit;
  end;
  if Message is TInsertMessage then
  begin
    MsgInsert;
    Exit;
  end;
  if Message is TInsertTailMessage then
  begin
    MsgInsertTail;
    Exit;
  end;
  if Message is TDeletingTailMessage then
  begin
    MsgDeletingTail((Message as TDeletingTailMessage).Node);
    Exit;
  end;
  if Message is TDeletingMessage then
  begin
    MsgDeleting((Message as TDeletingMessage).Node);
    Exit;
  end;
  if Message is TDeletedMessage then
  begin
    MsgDeleted;
    Exit;
  end;
  if Message is TDeletedTailMessage then
  begin
    MsgDeletedTail;
    Exit;
  end;
  if Message is TEditMessage then
  begin
    MsgEdit;
    Exit;
  end;
  if Message is TMovingUpDownMessage then
  begin
    with Message as TMovingUpDownMessage do
      MsgMovingUpDown(Node1, Node2);
    Exit;
  end;
  if Message is TMovedUpDownMessage then
  begin
    MsgMovedUpDown;
    Exit;
  end;
  if Message is TChangeGameEndMessage then
  begin
    MsgChangeGameEnd;
    Exit;
  end;
  // to add new messages (if it's nessesary) ...
  raise EVisualNotation.Create(Format(SUnknownNotationMessage, [Message.ClassName]));
end;

