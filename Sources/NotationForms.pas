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
    This unit contains a form that shows the chess notation.
}
unit NotationForms;

{$I CompilerDirectives.inc}

interface

uses
  ApplicationForms, Forms, ChessRules, ChessNotation, VisualNotation, Classes,
  CommentEditors, NAGSelector, Clipbrd, NotationLists, Dialogs,
  ActnList, SysUtils, ChessStrings, MoveConverters, PersistentNotation;

resourcestring
  SEnterMovePrompt = 'Enter your move:';

type

  { TNotationForm }

  TNotationForm = class(TApplicationForm)
    RedoAction: TAction;
    UndoAction: TAction;
    GoNextAction: TAction;
    GoPrevAction: TAction;
    MakeMoveAction: TAction;
    PasteFENAction: TAction;
    CopyFENAction: TAction;
    PastePGNAction: TAction;
    CopyPGNAction: TAction;
    TruncateNotationAction: TAction;
    ClearNotationAction: TAction;
    EditNodeAction: TAction;
    InsertNAGAction: TAction;
    InsertCommentAction: TAction;
    GoLastAction: TAction;
    GoFirstAction: TAction;
    MoveRightAction: TAction;
    MoveLeftAction: TAction;
    DelNodeAction: TAction;
    ActionList: TActionList;
    Notation: TVisualChessNotation;
    procedure ClearNotationActionExecute(Sender: TObject);
    procedure ClearNotationActionUpdate(Sender: TObject);
    procedure CopyFENActionExecute(Sender: TObject);
    procedure CopyPGNActionExecute(Sender: TObject);
    procedure DelNodeActionExecute(Sender: TObject);
    procedure DelNodeActionUpdate(Sender: TObject);
    procedure EditNodeActionExecute(Sender: TObject);
    procedure EditNodeActionUpdate(Sender: TObject);
    procedure GoFirstActionExecute(Sender: TObject);
    procedure GoFirstActionUpdate(Sender: TObject);
    procedure GoLastActionExecute(Sender: TObject);
    procedure GoLastActionUpdate(Sender: TObject);
    procedure GoNextActionExecute(Sender: TObject);
    procedure GoNextActionUpdate(Sender: TObject);
    procedure GoPrevActionExecute(Sender: TObject);
    procedure GoPrevActionUpdate(Sender: TObject);
    procedure InsertCommentActionExecute(Sender: TObject);
    procedure InsertCommentActionUpdate(Sender: TObject);
    procedure InsertNAGActionExecute(Sender: TObject);
    procedure InsertNAGActionUpdate(Sender: TObject);
    procedure MakeMoveActionExecute(Sender: TObject);
    procedure MakeMoveActionUpdate(Sender: TObject);
    procedure MoveLeftActionExecute(Sender: TObject);
    procedure MoveLeftActionUpdate(Sender: TObject);
    procedure MoveRightActionExecute(Sender: TObject);
    procedure MoveRightActionUpdate(Sender: TObject);
    procedure PasteFENActionExecute(Sender: TObject);
    procedure PasteFENActionUpdate(Sender: TObject);
    procedure PastePGNActionExecute(Sender: TObject);
    procedure PastePGNActionUpdate(Sender: TObject);
    procedure RedoActionExecute(Sender: TObject);
    procedure RedoActionUpdate(Sender: TObject);
    procedure TruncateNotationActionExecute(Sender: TObject);
    procedure TruncateNotationActionUpdate(Sender: TObject);
    procedure UndoActionExecute(Sender: TObject);
    procedure UndoActionUpdate(Sender: TObject);
  private
    // Getters / Setters
    function GetChessBoard: TChessBoard;
    function GetChessNotation: TPersistentChessNotation;
    procedure SetChessBoard(AValue: TChessBoard);
  public
    // Properties
    property ChessBoard: TChessBoard read GetChessBoard write SetChessBoard;
    property ChessNotation: TPersistentChessNotation read GetChessNotation;
  end;

var
  NotationForm: TNotationForm;

implementation

{$R *.lfm}

{ TNotationForm }

procedure TNotationForm.ClearNotationActionExecute(Sender: TObject);
begin
  ChessNotation.Clear;
end;

procedure TNotationForm.ClearNotationActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanClear;
end;

procedure TNotationForm.CopyFENActionExecute(Sender: TObject);
begin
  Clipboard.AsText := ChessBoard.FENString;
end;

procedure TNotationForm.CopyPGNActionExecute(Sender: TObject);
begin
  Clipboard.AsText := ChessNotation.PGNString;
end;

procedure TNotationForm.DelNodeActionExecute(Sender: TObject);
begin
  ChessNotation.Erase(False);
end;

procedure TNotationForm.DelNodeActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanErase;
end;

procedure TNotationForm.EditNodeActionExecute(Sender: TObject);
begin
  if ChessNotation.CanEditComment then
  begin
    // it's a comment
    with ChessNotation.Iterator.Node as TTextCommentNode do
      CommentEditor.Comment := Comment;
    if not CommentEditor.Execute then
      Exit;
    ChessNotation.EditComment(CommentEditor.Comment);
    Exit;
  end;
  if ChessNotation.CanEditNAG then
  begin
    // it's a NAG
    with ChessNotation.Iterator.Node as TNAGNode do
      NAGSelect.NAG := NAG;
    if not NAGSelect.Execute then
      Exit;
    ChessNotation.EditNAG(NAGSelect.NAG);
    Exit;
  end;
end;

procedure TNotationForm.EditNodeActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled :=
    ChessNotation.CanEditComment or ChessNotation.CanEditNAG;
end;

procedure TNotationForm.GoFirstActionExecute(Sender: TObject);
begin
  ChessNotation.GoToStart;
end;

procedure TNotationForm.GoFirstActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := not ChessNotation.Iterator.IsFirst;
end;

procedure TNotationForm.GoLastActionExecute(Sender: TObject);
begin
  ChessNotation.GoToEnd;
end;

procedure TNotationForm.GoLastActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := not ChessNotation.Iterator.IsLast;
end;

procedure TNotationForm.GoNextActionExecute(Sender: TObject);
begin
  ChessNotation.Iterator.Next;
end;

procedure TNotationForm.GoNextActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := not ChessNotation.Iterator.IsLast;
end;

procedure TNotationForm.GoPrevActionExecute(Sender: TObject);
begin
  ChessNotation.Iterator.Prev;
end;

procedure TNotationForm.GoPrevActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := not ChessNotation.Iterator.IsFirst;
end;

procedure TNotationForm.InsertCommentActionExecute(Sender: TObject);
begin
  CommentEditor.Comment := '';
  if not CommentEditor.Execute then
    Exit;
  ChessNotation.InsertComment(CommentEditor.Comment);
end;

procedure TNotationForm.InsertCommentActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanInsertComment;
end;

procedure TNotationForm.InsertNAGActionExecute(Sender: TObject);
begin
  NAGSelect.NAG := 0;
  if not NAGSelect.Execute then
    Exit;
  ChessNotation.InsertNAG(NAGSelect.NAG);
end;

procedure TNotationForm.InsertNAGActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanInsertNAG;
end;

procedure TNotationForm.MakeMoveActionExecute(Sender: TObject);
var
  CurMove: string;
  Converter: TPGNMoveConverter;
begin
  Converter := TPGNMoveConverter.Create(ChessBoard.RawBoard);
  try
    // parse move
    CurMove := InputBox(Application.Title, SEnterMovePrompt, '');
    // make move
    if CurMove <> '' then
      ChessNotation.AddMove(Converter.ParseMove(CurMove));
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
  FreeAndNil(Converter);
end;

procedure TNotationForm.MakeMoveActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanAddMove;
end;

procedure TNotationForm.MoveLeftActionExecute(Sender: TObject);
begin
  ChessNotation.MoveUp;
end;

procedure TNotationForm.MoveLeftActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanMoveUp;
end;

procedure TNotationForm.MoveRightActionExecute(Sender: TObject);
begin
  ChessNotation.MoveDown;
end;

procedure TNotationForm.MoveRightActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanMoveDown;
  Resize;
end;

procedure TNotationForm.PasteFENActionExecute(Sender: TObject);
var
  Board: TChessBoard;
  Res: TValidationResult;
begin
  Board := TChessBoard.Create(False);
  try
    // parse FEN
    try
      Board.FENString := Clipboard.AsText;
    except
      on E: EChessRules do
      begin
        MessageDlg(E.Message, mtError, [mbOK], 0);
        FreeAndNil(Board);
        Exit;
      end
      else
        raise;
    end;
    // validate the position from FEN
    Res := Board.ValidatePosition;
    if Res = vrOK then
      ChessNotation.ClearCustom(Board.RawBoard)
    else
      MessageDlg(ValidationResultToString(Res), mtError, [mbOK], 0);
  finally
    FreeAndNil(Board);
  end;
end;

procedure TNotationForm.PasteFENActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanClearCustom;
end;

procedure TNotationForm.PastePGNActionExecute(Sender: TObject);
begin
  try
    ChessNotation.PGNString := Clipboard.AsText;
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TNotationForm.PastePGNActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanPaste;
end;

procedure TNotationForm.RedoActionExecute(Sender: TObject);
begin
  ChessNotation.Redo;
end;

procedure TNotationForm.RedoActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanRedo;
end;

procedure TNotationForm.TruncateNotationActionExecute(Sender: TObject);
begin
  ChessNotation.Truncate(False);
end;

procedure TNotationForm.TruncateNotationActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanTruncate;
end;

procedure TNotationForm.UndoActionExecute(Sender: TObject);
begin
  ChessNotation.Undo;
end;

procedure TNotationForm.UndoActionUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := ChessNotation.CanUndo;
end;

function TNotationForm.GetChessBoard: TChessBoard;
begin
  Result := ChessNotation.Board;
end;

procedure TNotationForm.SetChessBoard(AValue: TChessBoard);
begin
  ChessNotation.Board := AValue;
end;

function TNotationForm.GetChessNotation: TPersistentChessNotation;
begin
  Result := Notation.ChessNotation;
end;

end.
