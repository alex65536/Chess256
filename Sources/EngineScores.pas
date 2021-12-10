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
    This unit implements routines to show the position score chosen by engine.
}
unit EngineScores;

{$I CompilerDirectives.inc}

interface

uses
  SysUtils, ChessRules, ChessStrings;

const
  DefaultMate = 2147483647;
  DefaultScore = 2147483647;

type
  TScoreKind = (skUpperBound, skNormal, skLowerBound);
  TScoreValue = integer;

  { RPositionScore }

  RPositionScore = record
    Kind: TScoreKind;
    Mate: integer;
    Score: integer; // in centipawns
    class operator=(const A, B: RPositionScore): Boolean;
  end;

resourcestring
  SMateCounter = '%s wins in %d';
  SUnknownScore = 'Unknown';

const
  DefaultPositionScore: RPositionScore =
    (
    Kind: skNormal;
    Mate: DefaultMate;
    Score: DefaultScore
    );
  KindStrMeanings: array [TScoreKind] of string = ('≤', '', '≥');

procedure InvertScore(var AScore: RPositionScore);
function PositionScoreToString(const AScore: RPositionScore): string;

implementation

procedure InvertScore(var AScore: RPositionScore);
// Inverts the score (if the score was for white, make it for black and vice versa).
begin
  if AScore.Mate <> DefaultMate then
    AScore.Mate := -AScore.Mate;
  if AScore.Score <> DefaultScore then
    AScore.Score := -AScore.Score;
  if AScore.Kind = skUpperBound then
    AScore.Kind := skLowerBound
  else
  if AScore.Kind = skLowerBound then
    AScore.Kind := skUpperBound;
end;

function PositionScoreToString(const AScore: RPositionScore): string;
  // Converts the score to string.
var
  S: string;
  Temp: integer;
  MoveSide: TPieceColor;
begin
  if AScore.Mate = DefaultMate then
  begin
    if AScore.Score = DefaultScore then
      Result := SUnknownScore // unknown score
    else
    begin
      // simple score
      Result := KindStrMeanings[AScore.Kind];
      if AScore.Score >= 0 then
        Result += '+'
      else
        Result += '-';
      Temp := Abs(AScore.Score);
      S := IntToStr(Temp mod 100);
      while Length(S) < 2 do
        S := '0' + S;
      Result += IntToStr(Temp div 100) + '.' + S;
    end;
  end
  else
  begin
    // mate
    if AScore.Mate >= 0 then
      MoveSide := pcWhite
    else
      MoveSide := pcBlack;
    Result := Format(SMateCounter, [SSideNames[MoveSide], Abs(AScore.Mate)]);
  end;
end;

{ RPositionScore }

class operator RPositionScore.=(const A, B: RPositionScore): boolean;
begin
  Result := (A.Kind = B.Kind) and (A.Score = B.Score) and (A.Mate = B.Mate);
end;

end.
