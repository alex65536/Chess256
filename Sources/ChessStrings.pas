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
    This unit contains some string constants and routines used in Chess 256.
}
unit ChessStrings;

{$I CompilerDirectives.inc}

interface

uses
  SysUtils, ChessRules;

resourcestring
  SWhite = 'White';
  SBlack = 'Black';
  SResultWins = '%s wins.';
  SResultDraw = 'Draw.';
  SReasonCheckmates = '%s checkmates.';
  SReasonResign = '%s resigns.';
  SReasonStalemate = 'Stalemate.';
  SReason50Moves = 'Draw by 50 moves rule.';
  SReasonByAgreement = 'Draw by agreement.';
  SReasonRepetitions = 'Draw by repetitions.';
  SReasonInsufficientMaterial = 'Draw by insufficient material.';
  SReasonTimeForfeit = '%s forfeits on time.';
  SReasonEngineFault = '%s engine error.';
  SDrawOffer = '%s offers you the draw. Do you agree?';
  SIllegalPawnPosition = 'Pawns cannot stay on lines "1" and "8".';
  SNoKing = 'One of the sides hasn''t got a king.';
  SOpponentKingAttacked = 'The opponent king is under attack.';
  STooManyKings = 'There cannot be more than one white king and more than one black king.';
  STooManyPieces = 'There cannot be more than 16 pieces of each color.';

const
  ChessPieceChars: array [TPieceColor, TPieceKind] of string =
    (
    ('', '♙', '♘', '♗', '♖', '♕', '♔'),
    ('', '♟', '♞', '♝', '♜', '♛', '♚')
    );
  GameResultWinners: array [TGameWinner] of string = ('', '1-0', '0-1', '½-½');
  SSideNames: array [TPieceColor] of string = (SWhite, SBlack);

function GameWinnerToString(AWinner: TGameWinner): string;
function GameResultToString(const AResult: RGameResult): string;
function GetDrawOffer(OffererSide: TPieceColor): string;
function ValidationResultToString(AResult: TValidationResult): string;

implementation

function GameWinnerToString(AWinner: TGameWinner): string;
  // Converts game winner to string.
begin
  case AWinner of
    gwNone: Result := '';
    gwWhite: Result := Format(SResultWins, [SWhite]);
    gwBlack: Result := Format(SResultWins, [SBlack]);
    gwDraw: Result := SResultDraw;
  end;
end;

function GameResultToString(const AResult: RGameResult): string;
  // Converts game result to string.
var
  WinSide: TPieceColor;
begin
  if AResult.Winner = gwWhite then
    WinSide := pcWhite
  else
    WinSide := pcBlack;
  case AResult.Kind of
    geNone, geOther: Result := GameWinnerToString(AResult.Winner);
    geCheckMate: Result := Format(SReasonCheckmates, [SSideNames[WinSide]]);
    geResign: Result := Format(SReasonResign, [SSideNames[not WinSide]]);
    geStaleMate: Result := SReasonStalemate;
    ge50Moves: Result := SReason50Moves;
    geByAgreement: Result := SReasonByAgreement;
    geRepetitions: Result := SReasonRepetitions;
    geInsufficientMaterial: Result := SReasonInsufficientMaterial;
    geTimeForfeit: Result := Format(SReasonTimeForfeit, [SSideNames[not WinSide]]);
    geEngineFault: Result := Format(SReasonEngineFault, [SSideNames[not WinSide]]);
  end;
end;

function GetDrawOffer(OffererSide: TPieceColor): string;
  // Returns draw offer message.
begin
  Result := Format(SDrawOffer, [SSideNames[OffererSide]]);
end;

function ValidationResultToString(AResult: TValidationResult): string;
  // Converts a validation result to string.
begin
  Result := '';
  case AResult of
    vrIllegalPawnPosition: Result := SIllegalPawnPosition;
    vrNoKing: Result := SNoKing;
    vrOpponentKingAttacked: Result := SOpponentKingAttacked;
    vrTooManyKings: Result := STooManyKings;
    vrTooManyPieces: Result := STooManyPieces;
  end;
end;

end.
