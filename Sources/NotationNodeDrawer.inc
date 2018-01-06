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
    This include file contains a routine that displays the notation nodes in
    TVisualChessNotation.
}

function TVisualChessNotation.GetInfo(WasTag: TNotationNodeInfo;
  It: TNotationIterator): RNotationNodeInfo;
  // Returns the info how to draw a given node.
  // In the future versions it can be moved somewher to apply different notation themes.

  procedure CacheMove(const Board: RRawBoard; const Move: RChessMove;
  var AInfo: RNotationNodeInfo);
  // Caches moves (move converting is a slow operation, so we'll cache them).
  var
    Converter: TNotationMoveConverter;
  begin
    if WasTag <> nil then
      Exit;
    Converter := TNotationMoveConverter.Create(Board);
    try
      AInfo.CachedStr1 := Converter.GetMoveString(Move);
    except
      AInfo.CachedStr1 := '{illegal move}';
    end;
    AInfo.CachedStr2 := Converter.GetMoveSeparator(True);
    AInfo.CachedStr3 := Converter.GetMoveSeparator(False);
    FreeAndNil(Converter);
  end;

  function MustLineEnding: boolean;
    // Returns True if there must be a line ending before the node.
  begin
    if (It.Node <> nil) and (It.Node.Prev <> nil) and
      (It.Node.Prev is TVariationNode) then
      Exit(True);
    if (It.Node = nil) and (It.List.Parent <> nil) then
      Exit(True);
    Result := False;
  end;

  function MustSpace: boolean;
    // Returns True if there must be a space before the node.
  begin
    Result := (It.Node <> nil) and (It.Node.Prev <> nil) and not
      (It.Node.Prev is TVariationNode);
  end;

  function GetGameEnd(List: TNotationList): string;
    // Returns the game end string.
  begin
    if List.Last = nil then
      Result := ''
    else if List.Last is TVariationNode then
      Result := LineEnding
    else
      Result := ' ';
    with List.GameResult do
      if Winner <> gwNone then
        Result += GameResultWinners[Winner]
      else if Result <> LineEnding then
        Result := '';
  end;

var
  MoveHighlight: TNotationHighlight;
  Node: TNotationNode;

begin
  if WasTag <> nil then
    Result := WasTag.Info
  else
  begin
    Result.ViewText := '';
    Result.Highlight1 := nhGameEnd;
    Result.Highlight2 := nhMove;
    Result.DividePoint := 0;
    Result.Indent := 0;
    Result.CachedStr1 := '';
    Result.CachedStr2 := '';
    Result.CachedStr3 := '';
  end;
  // it's a tail
  if (It.Node = nil) and (It.List = nil) then
  begin
    // add game end
    Result.Indent := 0;
    Result.Highlight2 := nhMove;
    Result.ViewText := GetGameEnd(ChessNotation.List);
    Result.DividePoint := Length(Result.ViewText);
    Exit;
  end;
  // selecting highlighting for moves
  if It.List.Parent = nil then
    MoveHighlight := nhMove
  else
  begin
    // in variations, first move is drawn as nhFirstMove,
    // the others are drawn with nhVariation.
    Node := It.List.LastMoveNode(It.Node);
    DecNode(Node);
    Node := It.List.LastMoveNode(Node);
    if Node = nil then
      MoveHighlight := nhFirstMove
    else
      MoveHighlight := nhVariation;
  end;
  // calculating separators of ViewText and Indent.
  Result.ViewText := '';
  if MustSpace then
    Result.ViewText := ' ';
  if MustLineEnding then
    Result.ViewText := LineEnding;
  Result.Indent := IndentPerDepth * It.List.Depth;
  // start of the notation
  if It.IsFirst then
  begin
    Result.ViewText := '';
    Result.Highlight2 := MoveHighlight;
    Exit;
  end;
  // start of the variation
  if It.Node = nil then
  begin
    Result.ViewText += '[';
    Result.Highlight2 := nhFirstMove;
    Exit;
  end;
  // end of the variation
  if It.Node is TVariationNode then
  begin
    // recalc indent
    Inc(Result.Indent, IndentPerDepth);
    // add game end
    if (It.Node as TVariationNode).List.Last is TVariationNode then
      Result.ViewText := LineEnding
    else
      Result.ViewText := '';
    with It.Node as TVariationNode do
      Result.ViewText := GetGameEnd(List);
    Result.DividePoint := Length(Result.ViewText);
    // add "]"
    Result.ViewText += ']';
    Result.Highlight2 := nhFirstMove;
    Exit;
  end;
  // move
  if It.Node is TMoveNode then
    with It.Node as TMoveNode do
    begin
      CacheMove(OldBoard, Move, Result);
      if FirstMove then
        Result.ViewText += Result.CachedStr2 + Result.CachedStr1
      else
        Result.ViewText += Result.CachedStr3 + Result.CachedStr1;
      Result.Highlight2 := MoveHighlight;
      Exit;
    end;
  // nag
  if It.Node is TNAGNode then
    with It.Node as TNAGNode do
    begin
      if Result.ViewText <> LineEnding then
        Result.ViewText := '';
      Result.ViewText += NAGToString(NAG);
      Result.Highlight2 := MoveHighlight;
      Exit;
    end;
  // comment
  if It.Node is TTextCommentNode then
  begin
    Result.ViewText += (It.Node as TTextCommentNode).Comment;
    Result.Highlight2 := nhComment;
    Exit;
  end;
  // node is unrecognized
  Result.Highlight2 := MoveHighlight;
  Result.ViewText := ' {$unknownNode}';
  raise EVisualNotation.Create(SUnknownNode);
end;

