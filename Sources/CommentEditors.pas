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
    This unit contains a dialog to create/edit comments.
}
unit CommentEditors;

{$I CompilerDirectives.inc}

interface

uses
  Controls, ExtCtrls, ButtonPanel, StdCtrls, ApplicationForms, ChessGUIUtils, Graphics,
  SysUtils, Classes, LCLType, VisualNotation;

type

  { TCommentEditor }

  TCommentEditor = class(TApplicationForm)
    ButtonPanel: TButtonPanel;
    CommentText: TLabel;
    Memo: TMemo;
    Panel: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
  private
    function GetComment: string;
    procedure SetComment(AValue: string);
  public
    property Comment: string read GetComment write SetComment;
    function Execute: boolean;
  end;

var
  CommentEditor: TCommentEditor;

implementation

{$R *.lfm}

{ TCommentEditor }

procedure TCommentEditor.FormCreate(Sender: TObject);
begin
  Memo.Font.Name := DefaultChessFont;
  Memo.Font.Size := DefaultChessFontSize;
  Memo.Font.Color := HighlightTable[nhComment];
end;

procedure TCommentEditor.FormKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    ButtonPanel.OKButton.Click;
    Key := 0;
  end;
end;

function TCommentEditor.GetComment: string;
begin
  Result := AdjustLineBreaks(Memo.Text);
end;

procedure TCommentEditor.SetComment(AValue: string);
begin
  Memo.Text := AValue;
end;

function TCommentEditor.Execute: boolean;
  // Executes the dialog.
begin
  Result := ShowModal = mrOk;
  if Comment = '' then
    Result := False;
end;

end.
