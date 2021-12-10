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
    This file contains classes to parse and view the PGN tags.
}
unit NotationTags;

{$I CompilerDirectives.inc}
{$B-}

interface

uses
  SysUtils, AvgLvlTree, ChessUtils, PGNUtils;

const
  StandardPGNTags: array [1 .. 8] of string =
    (
    '[Event "?"]',
    '[Site "?"]',
    '[Date "????.??.??"]',
    '[Round "-"]',
    '[White "?"]',
    '[Black "?"]',
    '[Result "*"]',
    '[TimeControl "-"]'
    );
  StandardPGNTagNames: array [1 .. 10] of string =
    ('Event', 'Site', 'Date', 'Round', 'White', 'Black', 'Result',
    'TimeControl', 'SetUp', 'FEN');
  TagFormat = '[%s "%s"]';
  Separators = [#0 .. #32];

type

  { TPGNTags }

  TPGNTags = class(TChessObject)
  private
    FMap: TStringToStringTree;
    FTagSeparator: string;
    // Getters / Setters
    function GetTags(const AName: string): string;
    function GetTagString: string;
    procedure SetTags(AName: string; const AValue: string);
    procedure SetTagSeparator(const AValue: string);
    procedure SetTagString(AValue: string);
    // Helpful methods
    function AddTagFromStr(const TagStr: string; var P: integer): boolean;
    function TagNameToExternal(const ATagName: string): string;
    function ExternalToTagName(const AExternal: string): string;
  public
    // Properties
    property TagSeparator: string read FTagSeparator write SetTagSeparator;
    property TagString: string read GetTagString write SetTagString;
    property Tags[AName: string]: string read GetTags write SetTags; default;
    // Methods
    procedure AddTagRoster;
    procedure FullClear;
    procedure Clear;
    procedure AddTag(const AName, AValue: string);
    procedure AddTag(ATag: string);
    procedure AddTags(TagsStr: string);
    procedure AddTagsFromStr(const TagStr: string; var P: integer);
    procedure RemoveTag(const AName: string);
    procedure Assign(Source: TPGNTags);
    procedure AssignTo(Target: TPGNTags);
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TPGNTags }

function TPGNTags.GetTags(const AName: string): string;
begin
  Result := FMap.Values[ExternalToTagName(AName)];
end;

function TPGNTags.GetTagString: string;
var
  It: PStringToStringItem;
begin
  Result := '';
  for It in FMap do
    Result += Format(TagFormat, [TagNameToExternal(It^.Name),
      StringToTagValue(It^.Value)]) + FTagSeparator;
end;

procedure TPGNTags.SetTags(AName: string; const AValue: string);
begin
  AName := ExternalToTagName(AName);
  if AName = '' then
    Exit;
  FMap.Values[AName] := AValue;
  DoChange;
end;

procedure TPGNTags.SetTagSeparator(const AValue: string);
begin
  if FTagSeparator = AValue then
    Exit;
  FTagSeparator := AValue;
end;

procedure TPGNTags.SetTagString(AValue: string);
begin
  BeginUpdate;
  Clear;
  AddTags(AValue);
  EndUpdate;
  DoChange;
end;

function TPGNTags.AddTagFromStr(const TagStr: string; var P: integer): boolean;
  // Adds a tag from TagStr. It starts searching for tag from position P.
var
  TagName, TagValue: string;
  SlashOpened, WasSlashOpened: boolean;
begin
  Result := False;
  // skip separators
  while (P <= Length(TagStr)) and (TagStr[P] in Separators) do
    Inc(P);
  if P > Length(TagStr) then
    Exit;
  // check for '[' and skip it
  if TagStr[P] <> '[' then
    Exit;
  Inc(P);
  if P > Length(TagStr) then
    Exit;
  // parsing a tag name
  TagName := '';
  while (P <= Length(TagStr)) and (TagStr[P] <> '"') do
  begin
    TagName += TagStr[P];
    Inc(P);
  end;
  TagName := Trim(TagName);
  if P > Length(TagStr) then
    Exit;
  // skip '"'
  Inc(P);
  if P > Length(TagStr) then
    Exit;
  // parsing a tag value
  TagValue := '';
  SlashOpened := False;
  WasSlashOpened := False;
  while P <= Length(TagStr) do
  begin
    WasSlashOpened := SlashOpened;
    if SlashOpened then
      SlashOpened := False
    else
      SlashOpened := TagStr[P] = TagBackSlash;
    if not SlashOpened then
    begin
      if (not WasSlashOpened) and (TagStr[P] = '"') then
        Break;
      TagValue += TagStr[P];
    end;
    Inc(P);
  end;
  if P > Length(TagStr) then
    Exit;
  // skip '"'
  Inc(P);
  if P > Length(TagStr) then
    Exit;
  // search for ']'
  while (P <= Length(TagStr)) and (TagStr[P] <> ']') do
    Inc(P);
  if P > Length(TagStr) then
    Exit;
  // skip ']'
  Inc(P);
  // add the new tag
  Tags[TagName] := TagValue;
  Result := True;
end;

function TPGNTags.TagNameToExternal(const ATagName: string): string;
  // Converts internal tag name to external one.
  // In internal tag names, special tags like "Event", "Site", "Date", etc.
  // are named in the following way:
  // #0'Event', #1'Site', #2'Date', etc.
var
  C: char;
begin
  Result := '';
  for C in ATagName do
    if not (C in Separators) then
      Result += C;
end;

function TPGNTags.ExternalToTagName(const AExternal: string): string;
  // Converts external tag name to internal one.
var
  C: char;
  I: integer;
begin
  Result := '';
  for C in AExternal do
    if not (C in Separators) then
      Result += C;
  for I := Low(StandardPGNTagNames) to High(StandardPGNTagNames) do
    if LowerCase(Result) = LowerCase(StandardPGNTagNames[I]) then
    begin
      Result := Chr(I) + StandardPGNTagNames[I];
      Exit;
    end;
end;

procedure TPGNTags.AddTagRoster;
// Adds the tag roster.
var
  S: string;
begin
  BeginUpdate;
  for S in StandardPGNTags do
    AddTag(S);
  EndUpdate;
  DoChange;
end;

procedure TPGNTags.FullClear;
// Clears the tags without adding a tag roster.
begin
  FMap.Clear;
  DoChange;
end;

procedure TPGNTags.Clear;
// Clears the tags with adding a tag roster.
begin
  BeginUpdate;
  FullClear;
  AddTagRoster;
  EndUpdate;
  DoChange;
end;

procedure TPGNTags.AddTag(const AName, AValue: string);
// Adds the tag with name AName and value AValue.
begin
  Tags[AName] := AValue;
end;

procedure TPGNTags.AddTag(ATag: string);
// Adds the tag from ATag.
var
  P: integer;
begin
  P := 1;
  AddTagFromStr(ATag, P);
end;

procedure TPGNTags.AddTags(TagsStr: string);
// Adds tags from TagsStr.
var
  P: integer;
begin
  P := 1;
  AddTagsFromStr(TagsStr, P);
end;

procedure TPGNTags.AddTagsFromStr(const TagStr: string; var P: integer);
// Adds tags from TagStr. It starts searching for tags from position P.
var
  WasP: integer;
begin
  BeginUpdate;
  WasP := P;
  while AddTagFromStr(TagStr, P) do
    WasP := P;
  P := WasP;
  EndUpdate;
  DoChange;
end;

procedure TPGNTags.RemoveTag(const AName: string);
// Removes a tag.
begin
  FMap.Remove(ExternalToTagName(AName));
  DoChange;
end;

procedure TPGNTags.Assign(Source: TPGNTags);
// Copies Source to Self.
begin
  Source.AssignTo(Self);
end;

procedure TPGNTags.AssignTo(Target: TPGNTags);
// Copies Self to Target.
begin
  Target.TagSeparator := Self.TagSeparator;
  Target.FMap.Assign(Self.FMap);
end;

constructor TPGNTags.Create;
begin
  inherited;
  FTagSeparator := LineEnding;
  FMap := TStringToStringTree.Create(False);
  Clear;
end;

destructor TPGNTags.Destroy;
begin
  FreeAndNil(FMap);
end;

end.
