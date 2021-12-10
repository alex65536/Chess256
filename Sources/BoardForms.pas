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
    This file contains a form that views a chessboard.
}
unit BoardForms;

{$I CompilerDirectives.inc}

interface

uses
  ActnList, ApplicationForms, ChessBoards, ChessRules, NotationForms,
  PromoteDialog, ImbalanceFrame, Utilities;

type

  { TBoardForm }

  TBoardForm = class(TApplicationForm)
    ImbalanceFrm: TImbalance;
    InvertBoardAction: TAction;
    ActionList: TActionList;
    VisualBoard: TVisualChessBoard;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure InvertBoardActionExecute(Sender: TObject);
    procedure VisualBoardMoveQuery(Sender: TObject; SrcX, SrcY, DstX, DstY: integer);
  private
    FTextureContainer: TTextureContainer;
    // Getters / Setters
    function GetBoard: TChessBoard;
    procedure SetTextureContainer(AValue: TTextureContainer);
    // Other methods
    function ResizerCheck(X: integer): boolean;
  public
    property Board: TChessBoard read GetBoard;
    property TextureContainer: TTextureContainer
      read FTextureContainer write SetTextureContainer;
  end;

var
  BoardForm: TBoardForm;

implementation

{$R *.lfm}

{ TBoardForm }

procedure TBoardForm.VisualBoardMoveQuery(Sender: TObject;
  SrcX, SrcY, DstX, DstY: integer);
var
  Move: RChessMove;
begin
  Move := Board.GetMove(SrcX, SrcY, DstX, DstY);
  if Move.Kind = mkImpossible then
    Exit;
  if Move.Kind = mkPromote then
    Move.PromoteTo := PromoteDlg.Execute(Board.MoveSide);
  NotationForm.ChessNotation.AddMove(Move);
end;

procedure TBoardForm.FormCreate(Sender: TObject);
begin
  VisualBoard.DragDropMode := ddDragQuery;
  VisualBoard.OnMoveQuery := @VisualBoardMoveQuery;
  ImbalanceFrm.Board := VisualBoard;
end;

procedure TBoardForm.FormResize(Sender: TObject);
begin
  ImbalanceFrm.Height := BinSearch(@ResizerCheck);
end;

procedure TBoardForm.InvertBoardActionExecute(Sender: TObject);
begin
  VisualBoard.InvertBoard;
end;

function TBoardForm.GetBoard: TChessBoard;
begin
  Result := VisualBoard.ChessBoard;
end;

procedure TBoardForm.SetTextureContainer(AValue: TTextureContainer);
begin
  if FTextureContainer = AValue then
    Exit;
  FTextureContainer := AValue;
  VisualBoard.TextureContainer := FTextureContainer;
  ImbalanceFrm.TextureContainer := FTextureContainer;
end;

function TBoardForm.ResizerCheck(X: integer): boolean;
var
  BoardH, CellH: integer;
begin
  BoardH := ClientHeight - X;
  CellH := VisualBoard.GetCellHeightOnResizing(ClientWidth, BoardH);
  Result := CellH >= X;
end;

end.
