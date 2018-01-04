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
    This unit contains the position editor form.
}
unit PositionEditors;

{$I CompilerDirectives.inc}

interface

uses
  Classes, ExtCtrls, Buttons, StdCtrls, Spin, ButtonPanel, ChessBoards,
  ChessRules, Math, Controls, Clipbrd, Dialogs, ActnList, Menus, ApplicationForms,
  LCLType, ChessStrings;

type

  { TPositionEditor }

  TPositionEditor = class(TApplicationForm)
    BlackMoves: TToggleBox;
    FlipHorizontallyAction: TAction;
    FlipVerticallyAction: TAction;
    MainMenu: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    CursorBugFixTimer: TTimer;
    WhoMovesPanel: TPanel;
    PasteFENAction: TAction;
    CopyFENAction: TAction;
    InitialPositionAction: TAction;
    ClearBoardAction: TAction;
    ActionList: TActionList;
    ClrBoardBtn: TBitBtn;
    BlackBishopBtn: TSpeedButton;
    BlackCastlingGroup: TGroupBox;
    BlackKingBtn: TSpeedButton;
    BlackKnightBtn: TSpeedButton;
    BlackPawnBtn: TSpeedButton;
    BlackQueenBtn: TSpeedButton;
    BlackRookBtn: TSpeedButton;
    ButtonPanel: TButtonPanel;
    CopyFENBtn: TBitBtn;
    FlipHorzBtn: TBitBtn;
    FlipVertBtn: TBitBtn;
    PasteFENBtn: TBitBtn;
    InitialPosBtn: TBitBtn;
    CursorBtn: TSpeedButton;
    EditorToolPanel: TPanel;
    EnPassantLineCombo: TComboBox;
    EnPassantLineLabel: TLabel;
    EraserBtn: TSpeedButton;
    CastlingPanel: TGroupBox;
    BlackKingside: TCheckBox;
    MoveCounter: TSpinEdit;
    MoveCounterLabel: TLabel;
    MoveNumber: TSpinEdit;
    MoveNumberLabel: TLabel;
    Panel: TPanel;
    PiecePanel: TPanel;
    BlackQueenside: TCheckBox;
    Field: TVisualChessBoard;
    WhiteBishopBtn: TSpeedButton;
    WhiteCastlingGroup: TGroupBox;
    WhiteKingBtn: TSpeedButton;
    WhiteKingside: TCheckBox;
    WhiteKnightBtn: TSpeedButton;
    WhiteMoves: TToggleBox;
    WhitePawnBtn: TSpeedButton;
    WhiteQueenBtn: TSpeedButton;
    WhiteQueenside: TCheckBox;
    WhiteRookBtn: TSpeedButton;
    procedure BlackBishopBtnClick(Sender: TObject);
    procedure BlackKingBtnClick(Sender: TObject);
    procedure BlackKnightBtnClick(Sender: TObject);
    procedure BlackPawnBtnClick(Sender: TObject);
    procedure BlackQueenBtnClick(Sender: TObject);
    procedure BlackRookBtnClick(Sender: TObject);
    procedure CursorBugFixTimerTimer(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure WhiteBishopBtnClick(Sender: TObject);
    procedure WhiteKingBtnClick(Sender: TObject);
    procedure WhiteKnightBtnClick(Sender: TObject);
    procedure WhitePawnBtnClick(Sender: TObject);
    procedure WhiteQueenBtnClick(Sender: TObject);
    procedure WhiteRookBtnClick(Sender: TObject);
    procedure CursorBtnClick(Sender: TObject);
    procedure EraserBtnClick(Sender: TObject);
    procedure BlackMovesChange(Sender: TObject);
    procedure WhiteMovesChange(Sender: TObject);
    procedure InitialPositionActionExecute(Sender: TObject);
    procedure ClearBoardActionExecute(Sender: TObject);
    procedure CopyFENActionExecute(Sender: TObject);
    procedure PasteFENActionExecute(Sender: TObject);
    procedure FlipHorizontallyActionExecute(Sender: TObject);
    procedure FlipVerticallyActionExecute(Sender: TObject);
    procedure FormChangeBounds(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure SpeedButtonsPaint(Sender: TObject);
    procedure BoardClickCell(Sender: TObject; X, Y: integer; Button: TMouseButton);
    procedure TextureContainerChange(Sender: TObject);
  private
    FActivePiece: RBoardCell;
    FButtonChanging: integer;
    FOKBtnPressed: boolean;
    // Getters / Setters
    function GetRawBoard: RRawBoard;
    function GetTextureContainer: TTextureContainer;
    procedure SetRawBoard(AValue: RRawBoard);
    procedure SetTextureContainer(AValue: TTextureContainer);
    // Other methods
    procedure LoadFromBoard;
    procedure SaveToBoard;
  public
    // Properties
    property RawBoard: RRawBoard read GetRawBoard write SetRawBoard;
    property TextureContainer: TTextureContainer
      read GetTextureContainer write SetTextureContainer;
    // Methods
    function Execute: boolean;
  end;

var
  PositionEditor: TPositionEditor;

implementation

{$IfDef MainMenuImages}
uses
  GlyphKeepers;

{$EndIf}

{$R *.lfm}

{ TPositionEditor }

procedure TPositionEditor.BlackBishopBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkBishop, pcBlack);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcBlack, pkBishop];
end;

procedure TPositionEditor.BlackKingBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkKing, pcBlack);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcBlack, pkKing];
end;

procedure TPositionEditor.BlackKnightBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkKnight, pcBlack);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcBlack, pkKnight];
end;

procedure TPositionEditor.BlackPawnBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkPawn, pcBlack);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcBlack, pkPawn];
end;

procedure TPositionEditor.BlackQueenBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkQueen, pcBlack);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcBlack, pkQueen];
end;

procedure TPositionEditor.BlackRookBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkRook, pcBlack);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcBlack, pkRook];
end;

procedure TPositionEditor.CursorBugFixTimerTimer(Sender: TObject);
begin
  // sometimes, when mouse very quickly leaves the window,
  // the cursor doesn't disappear.
  // this timer fixes the bug (the bug is Windows only).
  {$IFDEF WINDOWS}
  Field.Repaint;
  {$ENDIF}
end;

procedure TPositionEditor.FormHide(Sender: TObject);
begin
  {$IFDEF WINDOWS}
  CursorBugFixTimer.Enabled := False;
  {$ENDIF}
end;

procedure TPositionEditor.WhiteBishopBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkBishop, pcWhite);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcWhite, pkBishop];
end;

procedure TPositionEditor.WhiteKingBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkKing, pcWhite);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcWhite, pkKing];
end;

procedure TPositionEditor.WhiteKnightBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkKnight, pcWhite);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcWhite, pkKnight];
end;

procedure TPositionEditor.WhitePawnBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkPawn, pcWhite);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcWhite, pkPawn];
end;

procedure TPositionEditor.WhiteQueenBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkQueen, pcWhite);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcWhite, pkQueen];
end;

procedure TPositionEditor.WhiteRookBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkRook, pcWhite);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidPieces[pcWhite, pkRook];
end;

procedure TPositionEditor.BlackMovesChange(Sender: TObject);
begin
  if FButtonChanging <> 0 then
    Exit;
  Inc(FButtonChanging);
  BlackMoves.Checked := True;
  WhiteMoves.Checked := False;
  SaveToBoard;
  Dec(FButtonChanging);
end;

procedure TPositionEditor.WhiteMovesChange(Sender: TObject);
begin
  if FButtonChanging <> 0 then
    Exit;
  Inc(FButtonChanging);
  BlackMoves.Checked := False;
  WhiteMoves.Checked := True;
  SaveToBoard;
  Dec(FButtonChanging);
end;

procedure TPositionEditor.CursorBtnClick(Sender: TObject);
begin
  Field.DragDropMode := ddDrag;
  Field.CursorID := -1;
end;

procedure TPositionEditor.EraserBtnClick(Sender: TObject);
begin
  FActivePiece := MakeBoardCell(pkNone, pcWhite);
  Field.DragDropMode := ddNone;
  Field.CursorID := tidEraser;
end;

procedure TPositionEditor.InitialPositionActionExecute(Sender: TObject);
begin
  SaveToBoard;
  Field.ChessBoard.InitialPosition;
  LoadFromBoard;
end;

procedure TPositionEditor.ClearBoardActionExecute(Sender: TObject);
begin
  SaveToBoard;
  Field.ChessBoard.ClearBoard;
  LoadFromBoard;
end;

procedure TPositionEditor.CopyFENActionExecute(Sender: TObject);
begin
  SaveToBoard;
  Clipboard.AsText := Field.ChessBoard.FENString;
end;

procedure TPositionEditor.PasteFENActionExecute(Sender: TObject);
begin
  try
    SaveToBoard;
    Field.ChessBoard.FENString := Clipboard.AsText;
    LoadFromBoard;
  except
    on E: EChessRules do
      MessageDlg(E.Message, mtError, [mbOK], 0);
    else
      raise;
  end;
end;

procedure TPositionEditor.FlipHorizontallyActionExecute(Sender: TObject);
begin
  SaveToBoard;
  Field.ChessBoard.FlipHorizontally;
  LoadFromBoard;
end;

procedure TPositionEditor.FlipVerticallyActionExecute(Sender: TObject);
begin
  SaveToBoard;
  Field.ChessBoard.FlipVertically;
  LoadFromBoard;
end;

procedure TPositionEditor.FormChangeBounds(Sender: TObject);
begin
  if (Constraints.MinHeight <> 0) or (Constraints.MinWidth <> 0) then
    Exit;
  Constraints.MinHeight := Height;
  Constraints.MinWidth := Width - Field.Width;
end;

procedure TPositionEditor.FormCreate(Sender: TObject);
begin
  // putting the tags to buttons
  WhitePawnBtn.Tag := tidPieces[pcWhite, pkPawn] * 2 + 0;
  WhiteKnightBtn.Tag := tidPieces[pcWhite, pkKnight] * 2 + 1;
  WhiteBishopBtn.Tag := tidPieces[pcWhite, pkBishop] * 2 + 0;
  WhiteRookBtn.Tag := tidPieces[pcWhite, pkRook] * 2 + 1;
  WhiteQueenBtn.Tag := tidPieces[pcWhite, pkQueen] * 2 + 0;
  WhiteKingBtn.Tag := tidPieces[pcWhite, pkKing] * 2 + 1;
  EraserBtn.Tag := tidEraser * 2 + 0;
  BlackPawnBtn.Tag := tidPieces[pcBlack, pkPawn] * 2 + 1;
  BlackKnightBtn.Tag := tidPieces[pcBlack, pkKnight] * 2 + 0;
  BlackBishopBtn.Tag := tidPieces[pcBlack, pkBishop] * 2 + 1;
  BlackRookBtn.Tag := tidPieces[pcBlack, pkRook] * 2 + 0;
  BlackQueenBtn.Tag := tidPieces[pcBlack, pkQueen] * 2 + 1;
  BlackKingBtn.Tag := tidPieces[pcBlack, pkKing] * 2 + 0;
  CursorBtn.Tag := tidCursor * 2 + 1;
  // updating Field's properties
  Field.OnClickCell := @BoardClickCell;
  Field.DragDropMode := ddDrag;
  Field.DrawSelection := False;
  Field.ChessBoard.AutoGenerateMoves := False;
  // other nessesary things
  FButtonChanging := 0;
  ButtonPanel.OKButton.ModalResult := mrNone;
  PiecePanel.DoubleBuffered := True;
end;

procedure TPositionEditor.FormKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
// Here, the shortcuts of the piece selection are declared.
var
  KeyProcessed: boolean;

  procedure ClickBtn(AButton: TSpeedButton);
  // Emulates clicking a button on the ButtonPanel.
  begin
    AButton.Down := True;
    AButton.OnClick(Self);
  end;

begin
  KeyProcessed := True;
  case Key of
    VK_E: ClickBtn(EraserBtn);
    VK_M: ClickBtn(CursorBtn);
    VK_P: if ssShift in Shift then
        ClickBtn(BlackPawnBtn)
      else
        ClickBtn(WhitePawnBtn);
    VK_N: if ssShift in Shift then
        ClickBtn(BlackKnightBtn)
      else
        ClickBtn(WhiteKnightBtn);
    VK_B: if ssShift in Shift then
        ClickBtn(BlackBishopBtn)
      else
        ClickBtn(WhiteBishopBtn);
    VK_R: if ssShift in Shift then
        ClickBtn(BlackRookBtn)
      else
        ClickBtn(WhiteRookBtn);
    VK_Q: if ssShift in Shift then
        ClickBtn(BlackQueenBtn)
      else
        ClickBtn(WhiteQueenBtn);
    VK_K: if ssShift in Shift then
        ClickBtn(BlackKingBtn)
      else
        ClickBtn(WhiteKingBtn)
    else
      KeyProcessed := False;
  end;
  if KeyProcessed then
    Key := 0;
end;

procedure TPositionEditor.FormShow(Sender: TObject);
begin
  {$IFDEF MainMenuImages}
  MainMenu.Images := GlyphKeeper.ImageList;
  {$ENDIF}
  {$IFDEF WINDOWS}
  CursorBugFixTimer.Enabled := True;
  {$ENDIF}
  WhiteMoves.Height := WhoMovesPanel.Height div 2;
end;

procedure TPositionEditor.OKButtonClick(Sender: TObject);
var
  Res: TValidationResult;
begin
  SaveToBoard;
  Res := Field.ChessBoard.ValidatePosition;
  if Res = vrOK then
  begin
    FOKBtnPressed := True;
    Close;
  end
  else
    MessageDlg(ValidationResultToString(Res), mtError, [mbOK], 0);
end;

procedure TPositionEditor.SpeedButtonsPaint(Sender: TObject);
var
  CellID: integer;
begin
  if not Assigned(TextureContainer) then
    Exit;
  with TSpeedButton(Sender), TextureContainer do
  begin
    CellID := IfThen(Tag and 1 = 0, tidCells[pcWhite], tidCells[pcBlack]);
    StretchDrawTexture(Canvas, ClientRect, CellID);
    StretchDrawTexture(Canvas, ClientRect, Tag shr 1);
    if Down then
      StretchDrawTexture(Canvas, ClientRect, tidSelection);
  end;
end;

procedure TPositionEditor.BoardClickCell(Sender: TObject; X, Y: integer;
  Button: TMouseButton);
var
  Piece: RBoardCell;
begin
  Piece := FActivePiece;
  if not (Button in [mbLeft, mbRight]) then
    Exit;
  if Button = mbRight then
    Piece.Color := not Piece.Color;
  Field.ChessBoard.Field[X, Y] := Piece;
end;

procedure TPositionEditor.TextureContainerChange(Sender: TObject);
begin
  Refresh;
end;

function TPositionEditor.GetRawBoard: RRawBoard;
begin
  Result := Field.ChessBoard.RawBoard;
end;

function TPositionEditor.GetTextureContainer: TTextureContainer;
begin
  Result := Field.TextureContainer;
end;

procedure TPositionEditor.SetRawBoard(AValue: RRawBoard);
begin
  Field.ChessBoard.RawBoard := AValue;
end;

procedure TPositionEditor.SetTextureContainer(AValue: TTextureContainer);
begin
  with Field do
  begin
    if TextureContainer <> nil then
      TextureContainer.RemoveHandlerOnChange(@Self.TextureContainerChange);
    TextureContainer := AValue;
    if TextureContainer <> nil then
      TextureContainer.AddHandlerOnChange(@Self.TextureContainerChange);
  end;
  Refresh;
end;

procedure TPositionEditor.LoadFromBoard;
// Updates the Editor from the board.
begin
  Inc(FButtonChanging);
  with Field.ChessBoard.RawBoard do
  begin
    // castling
    WhiteKingside.Checked := AllowCastling[pcWhite, csKingSide];
    WhiteQueenside.Checked := AllowCastling[pcWhite, csQueenSide];
    BlackKingside.Checked := AllowCastling[pcBlack, csKingSide];
    BlackQueenside.Checked := AllowCastling[pcBlack, csQueenSide];
    // move side
    WhiteMoves.Checked := MoveSide = pcWhite;
    BlackMoves.Checked := MoveSide = pcBlack;
    // move number
    Self.MoveNumber.Value := MoveNumber;
    // move counter
    Self.MoveCounter.Value := MoveCounter;
    // enpassant
    EnPassantLineCombo.ItemIndex := EnPassantLine + 1;
  end;
  Dec(FButtonChanging);
end;

procedure TPositionEditor.SaveToBoard;
// Updates the board from the Editor.
begin
  with Field.ChessBoard.RawBoard do
  begin
    // castling
    AllowCastling[pcWhite, csKingSide] := WhiteKingside.Checked;
    AllowCastling[pcWhite, csQueenSide] := WhiteQueenside.Checked;
    AllowCastling[pcBlack, csKingSide] := BlackKingside.Checked;
    AllowCastling[pcBlack, csQueenSide] := BlackQueenside.Checked;
    // move side
    if WhiteMoves.Checked then
      MoveSide := pcWhite
    else
      MoveSide := pcBlack;
    // move number
    MoveNumber := Self.MoveNumber.Value;
    // move counter
    MoveCounter := Self.MoveCounter.Value;
    // enpassant
    EnPassantLine := EnPassantLineCombo.ItemIndex - 1;
  end;
  Field.ChessBoard.DoChange;
end;

function TPositionEditor.Execute: boolean;
  // Executes the dialog.
begin
  FOKBtnPressed := False;
  LoadFromBoard;
  ShowModal;
  Result := FOKBtnPressed;
end;

end.
