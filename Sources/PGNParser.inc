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
    This is the core of the PGN parser. It contains just two methods ;)
}

// TODO: add "%" support
// TODO: add variation compression
// TODO: remove empty variations
// TODO: add saving & parsing the game result reasons
// TODO: forbid reading past the game end (?)
// TODO: add Chess256 specific markers for game end in the variations

function TNotationList.ParseFromPGNString(const S: string;
  var Pos: integer): TPGNReadWriteResult;
  // Parses a PGN string and puts it to the list.
type
  TSetChar = set of char;

const
  CloseVar = ')';
  CharSet = [#0 .. #255];
  SeparatorSet = [#0 .. #32, '.', ')'];
  NotSeparatorSet = CharSet - SeparatorSet + [CloseVar];
  DigitSet = ['0' .. '9'];
  MoveNumberSet = DigitSet + ['.'];
  NotDigitSet = CharSet - DigitSet;
  OpenComm = '{';
  CloseComm = '}';
  OpenVar = '(';
  NAGSym = '$';

var
  Res: TPGNReadWriteResult;
  MoveConverter: TPGNMoveConverter;
  GameResultParsed: boolean;

  function GetString(const StopOn: TSetChar): string;
    // Returns a string that starts with current position and finishes with a
    // character that comes before character from StopOn set. Then, it updates
    // current position.
  var
    WasPos: integer;
  begin
    WasPos := Pos;
    while (Pos <= Length(S)) and not (S[Pos] in StopOn) do
      Inc(Pos);
    if WasPos > Length(S) then
      Result := ''
    else
      Result := Copy(S, WasPos, Pos - WasPos);
  end;

  procedure GoToLexeme;
  // Goes to the next lexeme.
  begin
    GetString(NotSeparatorSet);
  end;

  function IsMoveNumber(const S: string): boolean;
    // Returns True if S is a move number.
  var
    C: char;
  begin
    Result := False;
    for C in S do
      if not (C in MoveNumberSet) then
        Exit;
    Result := True;
  end;

  procedure PutGameResult(AWinner: TGameWinner);
  // Puts the final game result lexeme.
  begin
    UpdateGameResult(True);
    // if not have a game result yet - put it
    if (FGameResult.Winner = gwNone) and (AWinner <> gwNone) then
      GameResult := MakeGameResult(geOther, AWinner)
    // if the game has already finished and we try to put other game result, throw a error
    else if FGameResult.Winner <> AWinner then
      Res := prDifferentGameResults;
    GameResultParsed := True;
  end;

  procedure ParseComment;
  // Adds a comment.
  var
    Comment: string;
  begin
    Inc(Pos);
    Comment := PGNCommentToString(GetString([CloseComm]));
    Add(TTextCommentNode.Create(nil, Comment));
    if Pos > Length(S) then
      Res := prUnclosedComment
    else
      Inc(Pos);
  end;

  procedure ParseNAG;
  // Adds a NAG label.
  var
    Num: byte;
    Code: integer;
  begin
    Inc(Pos);
    GoToLexeme;
    Val(GetString(NotDigitSet), Num, Code);
    if Code <> 0 then
    begin
      Res := prInvalidNAG;
      Num := 0;
    end;
    if Num <> 0 then
      Add(TNAGNode.Create(nil, Num));
  end;

  procedure ParseVariation;
  // Adds a variation.
  var
    Node: TVariationNode;
    WasMoveNode: TMoveNode;
  begin
    // we cannot put variations before moves
    WasMoveNode := LastMoveNode;
    if WasMoveNode = nil then
    begin
      Res := prWrongVariationPosition;
      Exit;
    end;
    Inc(Pos);
    // create a node
    Node := Add(TVariationNode.Create(nil)) as TVariationNode;
    Node.Update(Self);
    Node.List.Clear(WasMoveNode.OldBoard);
    // parse it
    Res := Node.List.ParseFromPGNString(S, Pos);
    if (Res = prOk) and (Pos > Length(S)) then
      Res := prUnclosedVariation;
    if Pos <= Length(S) then
      Inc(Pos);
  end;


  procedure ParseNumberOrMove;
  // Adds a move, a move number or a game result.
  var
    Processed: boolean;
    Str: string;
    Move: RChessMove;
  begin
    Str := GetString(SeparatorSet);
    // game results (put them using PutGameResult)
    Processed := True;
    if (Str = '1-0') or (Str = '1-O') or (Str = '1-o') then
      PutGameResult(gwWhite)
    else if (Str = '0-1') or (Str = 'O-1') or (Str = 'o-1') then
      PutGameResult(gwBlack)
    else if (Str = '1/2-1/2') or (Str = '1/2-1\2') or
      (Str = '1\2-1/2') or (Str = '1\2-1\2') then
      PutGameResult(gwDraw)
    else if (Str = '*') then
      PutGameResult(gwNone)
    else
      Processed := False;
    if Processed then
      Exit;
    // move numbers (just skip it)
    if IsMoveNumber(Str) then
      Exit;
    // finally, moves
    try
      MoveConverter.RawBoard := CurBoard;
      Move := MoveConverter.ParseMove(Str);
    except
      Res := prBadMove;
    end;
    if Res = prBadMove then
      Exit;
    Add(TMoveNode.Create(nil, CurBoard, Move));
  end;

begin
  try
    // initialize it
    BeginUpdate;
    Clear(FBaseBoard);
    GameResultParsed := False;
    MoveConverter := TPGNMoveConverter.Create;
    MoveConverter.RawBoard := FBaseBoard;
    Res := prOK;
    // now, search for lexemes
    while Pos <= Length(S) do
    begin
      GoToLexeme;
      // if we reached the end or met ")" - stop parsing
      if (Pos > Length(S)) or (S[Pos] = CloseVar) then
        Break;
      // check for what lexeme is it
      if S[Pos] = OpenComm then
        ParseComment // comment
      else if S[Pos] = NAGSym then
        ParseNAG // nag label
      else if S[Pos] = OpenVar then
        ParseVariation // variation
      else
        ParseNumberOrMove; // move, move number or game result
      // if error - stop parsing
      if Res <> prOK then
        Break;
      // if parser a game result lexeme - stop parsing
      if GameResultParsed then
      begin
        Pos := Length(S) + 1;
        Break;
      end;
    end;
    Result := Res;
  finally
    FreeAndNil(MoveConverter);
    EndUpdate;
    DoChange(not GameResultParsed);
    Update;
  end;
end;

function TNotationList.SaveToPGNString(out S: string;
  SaveGameResult: boolean): TPGNReadWriteResult;
  // Returns the PGN string of the list.
var
  MoveConverter: TPGNMoveConverter;
  Item: TNotationNode;
  Q: string;
begin
  S := '';
  Result := prOK;
  try
    MoveConverter := TPGNMoveConverter.Create;
    MoveConverter.RawBoard := FBaseBoard;
    // iterate through the items and convert them into PGN.
    Item := First;
    while Item <> nil do
    begin
      if Item <> First then
        S += ' ';
      // move
      if Item is TMoveNode then
        with Item as TMoveNode do
        begin
          S += MoveConverter.GetMoveSeparator(FirstMove) +
            MoveConverter.GetMoveString(Move);
          MoveConverter.RawBoard := NewBoard;
        end
      // comment
      else if Item is TTextCommentNode then
        with Item as TTextCommentNode do
        begin
          S += '{' + StringToPGNComment(Comment) + '}';
        end
      // nag
      else if Item is TNAGNode then
        with Item as TNAGNode do
        begin
          S += '$' + IntToStr(NAG);
        end
      // variation
      else if Item is TVariationNode then
        with Item as TVariationNode do
        begin
          Result := List.SaveToPGNString(Q, False);
          if Result <> prOK then
            Break;
          S += '(' + Q + ')';
        end
      // unrecoginized node
      else
        Result := prWrongNode;
      // check & go further
      if Result <> prOK then
        Break;
      IncNode(Item);
    end;
    // add game result (not allowed in variations)
    if (Result = prOK) and SaveGameResult then
    begin
      if First <> nil then
        S += ' ';
      S += GameResultMeanings[FGameResult.Winner];
    end;
  finally
    FreeAndNil(MoveConverter);
  end;
end;

