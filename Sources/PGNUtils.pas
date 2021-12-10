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
    This file contains some utilities for processing the PGN chess format (e. g.
    cutting strings to the length of 80 characters and making a single line back,
    escaping the content of PGN headers and comments). For PGN header escaping,
    backslash is used. For comment escaping, Chess 256 uses the way Rybka Aquarium
    does: It puts (^) character, then a character code.
}
unit PGNUtils;

{$I CompilerDirectives.inc}

interface

uses
  SysUtils, LazUTF8;

const
  PGNStrLen = 79;

  TagBackSlash = '\';
  NumActivator = '^';
  MustSlashChars = ['"', '\'];
  CommentAllowedSet = [#32 .. #255] - ['}', '^'];
  NumberSet = ['0' .. '9'];
  SeparatorSet = [#0 .. #32];

function StringToPGNComment(const AString: string): string;
function PGNCommentToString(const PGNComment: string): string;
function StringToTagValue(const AString: string): string;
function TagValueToString(const TagValue: string): string;
function CutString(const S: string; MaxLength: integer): string;
function DeCutString(S: string): string;

implementation

function StringToPGNComment(const AString: string): string;
  // Converts string to a PGN comment.
  // All the wrong characters are replaced to ^<char index>
  // Example: comment "{^}" will be replaced to "{^94 ^125 }"
var
  I: integer;
begin
  Result := '';
  for I := 1 to Length(AString) do
    if AString[I] in CommentAllowedSet then
      Result += AString[I]
    else
      Result += '^' + IntToStr(Ord(AString[I])) + ' ';
end;

function PGNCommentToString(const PGNComment: string): string;
  // Converts a PGN comment to string.
var
  NumActive: boolean;
  CurNum: integer;
  I: integer;
  WriteChar: boolean;
begin
  Result := '';
  NumActive := False;
  CurNum := 0;
  for I := 1 to Length(PGNComment) do
  begin
    WriteChar := True;
    if NumActive then
    begin
      if PGNComment[I] in NumberSet then
      begin
        CurNum := CurNum * 10 + Ord(PGNComment[I]) - Ord('0');
        WriteChar := False;
      end
      else
      begin
        NumActive := False;
        Result += Chr(CurNum);
        WriteChar := PGNComment[I] <> ' ';
      end;
    end;
    if WriteChar then
    begin
      if PGNComment[I] = NumActivator then
      begin
        NumActive := True;
        CurNum := 0;
      end
      else
        Result += PGNComment[I];
    end;
  end;
  if NumActive then
    Result += Chr(CurNum);
end;

function StringToTagValue(const AString: string): string;
  // Converts a string to tag value.
  // " is replaced by \"
  // \ is replaced by \\
var
  C: char;
begin
  Result := '';
  for C in AString do
    if C in MustSlashChars then
      Result += TagBackSlash + C
    else
      Result += C;
end;

function TagValueToString(const TagValue: string): string;
  // Converts a tag value to string.
var
  SlashOpened: boolean;
  C: char;
begin
  Result := '';
  SlashOpened := False;
  for C in TagValue do
  begin
    if SlashOpened then
      SlashOpened := False
    else
      SlashOpened := C = TagBackSlash;
    if not SlashOpened then
      Result += C;
  end;
end;

function CutString(const S: string; MaxLength: integer): string;
  // Cuts the string into lines with maximum length (in UTF8 chars) = MaxLength.
var
  I: integer;
  CurRow: integer;
  Res: string;
  Wrd: string;
  First: boolean;

  procedure AddWord(const S: string);
  // Adds a word to the result.
  begin
    // if first word in the line - add it fully.
    if First then
    begin
      CurRow += UTF8Length(S);
      Res += S;
      First := False;
    end
    // else add only if it's enough place for it
    else
    begin
      if UTF8Length(S) + CurRow + 1 <= MaxLength then
      begin
        CurRow += UTF8Length(S) + 1;
        Res += ' ' + S;
      end
      else
      begin
        CurRow := UTF8Length(S);
        Res += LineEnding + S;
      end;
    end;
    Wrd := '';
  end;

begin
  Res := '';
  CurRow := 0;
  Wrd := '';
  First := True;
  for I := 1 to Length(S) do
    if S[I] in SeparatorSet then
      AddWord(Wrd)
    else
      Wrd += S[I];
  AddWord(Wrd);
  if CurRow <> 0 then
    Res += LineEnding;
  Result := Res;
end;

function DeCutString(S: string): string;
  // Removes the line breaks from the string and makes it single-line.
var
  I: integer;
begin
  S := AdjustLineBreaks(S, tlbsCR);
  Result := '';
  for I := 1 to Length(S) do
    case S[I] of
      #0 .. #31: Result += ' '
      else
        Result += S[I];
    end;
end;

end.
