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
    This unit implement "messaging system" for the chess notation. Messaging is
    the way to signal the changes made in the notation.
}
unit NotationMessaging;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, NotationLists;

type
  TNotationMessage = class(TObject);

  { TItemNotationMessage }

  TItemNotationMessage = class(TNotationMessage)
  private
    FNode: TNotationNode;
  public
    property Node: TNotationNode read FNode;
    constructor Create(ANode: TNotationNode);
  end;

  { TItemPairNotationMessage }

  TItemPairNotationMessage = class(TNotationMessage)
  private
    FNode1, FNode2: TNotationNode;
  public
    property Node1: TNotationNode read FNode1;
    property Node2: TNotationNode read FNode2;
    constructor Create(ANode1, ANode2: TNotationNode);
  end;

  { TListNotationMessage }

  TListNotationMessage = class(TNotationMessage)
  private
    FList: TNotationList;
  public
    property List: TNotationList read FList;
    constructor Create(AList: TNotationList);
  end;

  TNotationMessageClass = class of TNotationMessage;
  TNotationMessageReceiver = procedure(Sender: TObject;
    Message: TNotationMessage) of object;

  // The notation messages:

  // After full updating
  TUpdateMessage = class(TNotationMessage);
  // After restoring the state
  TRestoreMessage = class(TNotationMessage);
  // After changing an iterator
  TIteratorChangeMessage = class(TNotationMessage);
  // After inserting
  TInsertMessage = class(TItemNotationMessage);
  // After inserting a tail
  TInsertTailMessage = class(TItemNotationMessage);
  // Before deleting
  TDeletingMessage = class(TItemNotationMessage);
  // After deleting
  TDeletedMessage = class(TNotationMessage);
  // Before deleting the tail
  TDeletingTailMessage = class(TItemNotationMessage);
  // After deleting the tail
  TDeletedTailMessage = class(TNotationMessage);
  // Before moving up / down (Node1 should be earlier than Node2).
  TMovingUpDownMessage = class(TItemPairNotationMessage);
  // After moving up / down
  TMovedUpDownMessage = class(TNotationMessage);
  // After editing
  TEditMessage = class(TItemNotationMessage);
  // After changing the game end
  TChangeGameEndMessage = class(TListNotationMessage);

procedure SendNotationMessage(Sender: TObject; Message: TNotationMessage;
  Receiver: TNotationMessageReceiver);

implementation

procedure SendNotationMessage(Sender: TObject; Message: TNotationMessage;
  Receiver: TNotationMessageReceiver);
// Sends the Message to Receiver.
begin
  if Message = nil then
    Exit;
  try
    if Assigned(Receiver) then
      Receiver(Sender, Message);
  finally
    FreeAndNil(Message);
  end;
end;

{ TItemPairNotationMessage }

constructor TItemPairNotationMessage.Create(ANode1, ANode2: TNotationNode);
begin
  FNode1 := ANode1;
  FNode2 := ANode2;
end;

{ TItemNotationMessage }

constructor TItemNotationMessage.Create(ANode: TNotationNode);
begin
  FNode := ANode;
end;

{ TListNotationMessage }

constructor TListNotationMessage.Create(AList: TNotationList);
begin
  FList := AList;
end;

end.
