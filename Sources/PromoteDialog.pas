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
    This unit contains a dialog to choose a piece if which a pawn will be
    promoted.
}
unit PromoteDialog;

{$I CompilerDirectives.inc}

interface

uses
  Classes, Graphics, Buttons, ChessBoards, ChessRules, ApplicationForms,
  LCLType, ScaleDPI;

const
  StdGlyphSize = 64;

type

  { TPromoteDlg }

  TPromoteDlg = class(TApplicationForm)
    KnightPromote: TBitBtn;
    QueenPromote: TBitBtn;
    RookPromote: TBitBtn;
    BishopPromote: TBitBtn;
    procedure BishopPromoteClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure KnightPromoteClick(Sender: TObject);
    procedure QueenPromoteClick(Sender: TObject);
    procedure RookPromoteClick(Sender: TObject);
  private
    FActivePiece: TPieceKind;
    FTextureContainer: TTextureContainer;
    procedure SetTextureContainer(AValue: TTextureContainer);
  protected
    procedure AddGlyphs(AColor: TPieceColor);
  public
    property TextureContainer: TTextureContainer
      read FTextureContainer write SetTextureContainer;
    function Execute(AColor: TPieceColor): TPieceKind;
  end;

var
  PromoteDlg: TPromoteDlg;

implementation

{$R *.lfm}

{ TPromoteDlg }

procedure TPromoteDlg.KnightPromoteClick(Sender: TObject);
begin
  FActivePiece := pkKnight;
  Close;
end;

procedure TPromoteDlg.QueenPromoteClick(Sender: TObject);
begin
  FActivePiece := pkQueen;
  Close;
end;

procedure TPromoteDlg.RookPromoteClick(Sender: TObject);
begin
  FActivePiece := pkRook;
  Close;
end;

procedure TPromoteDlg.BishopPromoteClick(Sender: TObject);
begin
  FActivePiece := pkBishop;
  Close;
end;

procedure TPromoteDlg.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
// Here, the shortcuts of piece selection are declared.
var
  KeyProcessed: boolean;
begin
  Shift := Shift; // to make the compiler happy.
  KeyProcessed := True;
  case Key of
    VK_N: KnightPromote.Click;
    VK_B: BishopPromote.Click;
    VK_R: RookPromote.Click;
    VK_Q: QueenPromote.Click
    else
      KeyProcessed := False;
  end;
  if KeyProcessed then
    Key := 0;
end;

procedure TPromoteDlg.SetTextureContainer(AValue: TTextureContainer);
begin
  if FTextureContainer = AValue then
    Exit;
  FTextureContainer := AValue;
end;

procedure TPromoteDlg.AddGlyphs(AColor: TPieceColor);
// Adds the glyphs.
var
  GlyphSize: integer;
begin
  GlyphSize := ScaleX(StdGlyphSize, WasDPI);
  if Assigned(FTextureContainer) then
    with FTextureContainer do
    begin
      MakeBitmap(KnightPromote.Glyph, GlyphSize,
        tidCells[AColor], tidPieces[AColor, pkKnight]);
      MakeBitmap(BishopPromote.Glyph, GlyphSize,
        tidCells[not AColor], tidPieces[AColor, pkBishop]);
      MakeBitmap(RookPromote.Glyph, GlyphSize,
        tidCells[AColor], tidPieces[AColor, pkRook]);
      MakeBitmap(QueenPromote.Glyph, GlyphSize,
        tidCells[not AColor], tidPieces[AColor, pkQueen]);
    end
  else
  begin
    KnightPromote.Glyph.Clear;
    BishopPromote.Glyph.Clear;
    RookPromote.Glyph.Clear;
    QueenPromote.Glyph.Clear;
  end;
end;

function TPromoteDlg.Execute(AColor: TPieceColor): TPieceKind;
  // Executes the dialog for piece color AColor. Returns the selected piece kind.
begin
  FActivePiece := pkNone;
  AddGlyphs(AColor);
  ShowModal;
  Result := FActivePiece;
end;

end.
