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
    This unit contains various utilities and algorithms (e. g. TPair
    implementation and binary search algorithm).
}
unit Utilities;

{$I CompilerDirectives.inc}

interface

uses
  FGL;

type
  TBinSearchCheckFunc = function(X: integer): boolean of object;

  { TPair }

  generic TPair<T1, T2> = record
    First: T1;
    Second: T2;
    class operator=(A, B: TPair): Boolean;
    class function MakePair(A: T1; B: T2): TPair; static;
  end;

  TPairIntInt = specialize TPair<integer, integer>;
  TVectorPairIntInt = specialize TFPGList<TPairIntInt>;

function BinSearch(Check: TBinSearchCheckFunc): integer;

implementation

function BinSearch(Check: TBinSearchCheckFunc): integer;
  // Check function must return False if X < Val and True otherwise.
  // Val may be any positive integer value.
  // BinSearch finds and returns this Val in O(log(Val)) guesses.
var
  L, R, M: integer;
begin
  L := 1;
  R := 1;
  while Check(R) do
    R := R * 2;
  while L < R do
  begin
    M := L + (R - L + 1) div 2;
    if Check(M) then
      L := M
    else
      R := M - 1;
  end;
  Result := L;
end;

{ TPair }

class operator TPair.=(A, B: TPair): boolean;
begin
  Result := (A.First = B.First) and (A.Second = B.Second)
end;

class function TPair.MakePair(A: T1; B: T2): TPair; static;
begin
  Result.First := A;
  Result.Second := B;
end;

end.
