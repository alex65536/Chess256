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
    This unit is created to make a TTextViewer - a class for viewing the
    formatted text. Using TAbstractTextViewer, you can create your own
    class to view text.
    Actually, the implementation of TAbstractTextViewer is done in TextViewImpl.pas.
}

{
  Creation date: 13.06.2016.

  This unit is tested for Lazarus 1.6 - 1.8, FPC 3.0.0 - 3.0.4.
  THIS UNIT IS BETA, IT CAN BE IMPROVED!!!

  To be made:
    (*) A method for drawing on custom canvas (for printing).
}
unit TextViewBase;

{$I CompilerDirectives.inc}

interface

uses
  SysUtils, Classes, Controls, Graphics, FGL;

type

  { TCharStyle }

  TCharStyle = record
    Style: integer;
    Indent: integer;
    class operator=(A, B: TCharStyle): Boolean;
  end;

const
  DefaultCharStyle: TCharStyle =
    (
    Style: 0;
    Indent: 0;
    );

type
  TAbstractTextChunk = class(TObject);

  { TAbstractTextViewer }

  TAbstractTextViewer = class(TComponent)
  protected
    // Abstract methods, to be overridden...
    function GetControl: TControl; virtual; abstract;
    function GetText: string; virtual; abstract;
    function GetCursorPos: integer; virtual; abstract;
    procedure SetCursorPos(const AValue: integer); virtual; abstract;
    function GetCharStyle(I: integer): TCharStyle; virtual; abstract;
    procedure DoUpdate; virtual; abstract;
    // Internals (also abstract)
    procedure InternalInsertText(const S: string; const AStyle: TCharStyle;
      Beg: integer); overload; virtual; abstract;
    procedure InternalInsertText(AChunk: TAbstractTextChunk; Pos, Beg, Len: integer);
      overload; virtual; abstract;
    procedure InternalAddText(const S: string; const AStyle: TCharStyle);
      overload; virtual; abstract;
    procedure InternalAddText(AChunk: TAbstractTextChunk; Beg, Len: integer);
      overload; virtual; abstract;
    procedure InternalDeleteText(Beg, Len: integer); virtual; abstract;
    procedure InternalSetText(const S: string; const AStyle: TCharStyle);
      virtual; abstract;
    procedure InternalClear; virtual; abstract;
    function InternalCharAtPos(X, Y: integer): integer; virtual; abstract;
    function InternalCopy(Beg, Len: integer): TAbstractTextChunk; virtual; abstract;
  private
    FUpdating: integer;
  protected
    procedure SetText(const AValue: string);
    procedure Update;
  public
    // Properties
    property CharStyle[I: integer]: TCharStyle read GetCharStyle;
    // Methods
    function IsUpdating: boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure InsertText(const S: string; const AStyle: TCharStyle;
      Beg: integer); overload;
    procedure InsertText(AChunk: TAbstractTextChunk; Pos, Beg, Len: integer); overload;
    procedure AddText(const S: string; const AStyle: TCharStyle); overload;
    procedure AddText(AChunk: TAbstractTextChunk; Beg, Len: integer); overload;
    procedure DeleteText(Beg, Len: integer);
    procedure SetText(const S: string; const AStyle: TCharStyle);
    procedure Clear;
    function CharAtPos(X, Y: integer): integer;
    function Copy(Beg, Len: integer): TAbstractTextChunk;
  published
    // Properties
    property Control: TControl read GetControl;
    property Text: string read GetText write SetText;
    property CursorPos: integer read GetCursorPos write SetCursorPos;
    // Methods
    constructor Create(AOwner: TComponent); override;
  end;

  TBaseTextViewer = TAbstractTextViewer;
  TAbstractTextViewerClass = class of TAbstractTextViewer;

// TTextViewer is a default text viewer class. You may re-assign it.
var
  TTextViewer: TAbstractTextViewerClass;

function MakeStyle(AStyle: integer; AIndent: integer): TCharStyle;

function GetStyleCount: integer;
function GetStyles(I: integer): TFont;
function AddStyle(AFont: TFont): integer;
procedure PutStyle(ACanvas: TCanvas; AStyle: TCharStyle);

property StyleCount: Integer read GetStyleCount;
property Styles[I: Integer]: TFont read GetStyles;

implementation

type
  TFontList = specialize TFPGObjectList<TFont>;

var
  FFonts: TFontList;

function MakeStyle(AStyle: integer; AIndent: integer): TCharStyle;
  // Makes the char style.
begin
  Result.Indent := AIndent;
  Result.Style := AStyle;
end;

function GetStyleCount: integer;
  // Returns the style count.
begin
  Result := FFonts.Count;
end;

function GetStyles(I: integer): TFont;
  // Returns a styles with the specified index.
begin
  Result := FFonts[I];
end;

function AddStyle(AFont: TFont): integer;
  // Adds a style to list. It copies AFont!
var
  AddFont: TFont;
begin
  AddFont := TFont.Create;
  AddFont.Assign(AFont);
  Result := FFonts.Add(AddFont);
end;

procedure PutStyle(ACanvas: TCanvas; AStyle: TCharStyle);
// Puts a style to canvas.
begin
  ACanvas.Font.Assign(GetStyles(AStyle.Style));
end;

{ TCharStyle }

class operator TCharStyle.=(A, B: TCharStyle): boolean;
begin
  Result := (A.Style = B.Style) and (A.Indent = B.Indent);
end;

{ TAbstractTextViewer }

procedure TAbstractTextViewer.SetText(const AValue: string);
// Sets the text as AValue.
begin
  SetText(AValue, DefaultCharStyle);
end;

procedure TAbstractTextViewer.Update;
// Updates the control (called when the text has changed).
begin
  if not IsUpdating then
    DoUpdate;
end;

function TAbstractTextViewer.IsUpdating: boolean;
  // Returns true if updating the control is locked.
begin
  Result := FUpdating <> 0;
end;

procedure TAbstractTextViewer.BeginUpdate;
// Locks updating the control.
begin
  Inc(FUpdating);
end;

procedure TAbstractTextViewer.EndUpdate;
// Unlocks updating the control.
begin
  Dec(FUpdating);
  if FUpdating < 0 then
    FUpdating := 0;
  if FUpdating = 0 then
    Update;
end;

procedure TAbstractTextViewer.InsertText(const S: string;
  const AStyle: TCharStyle; Beg: integer);
// Inserts the string S with the style AStyle to position Beg.
begin
  InternalInsertText(S, AStyle, Beg);
  Update;
end;

procedure TAbstractTextViewer.InsertText(AChunk: TAbstractTextChunk;
  Pos, Beg, Len: integer);
// Inserts the chunk piece (Beg, Len) to position Pos.
begin
  InternalInsertText(AChunk, Pos, Beg, Len);
  Update;
end;

procedure TAbstractTextViewer.AddText(const S: string; const AStyle: TCharStyle);
// Adds the string S to the end.
begin
  InternalAddText(S, AStyle);
  Update;
end;

procedure TAbstractTextViewer.AddText(AChunk: TAbstractTextChunk; Beg, Len: integer);
// Adds the chunk piece (Beg, Len) to the end.
begin
  InternalAddText(AChunk, Beg, Len);
  Update;
end;

procedure TAbstractTextViewer.DeleteText(Beg, Len: integer);
// Deletes the piece (Beg, Len).
begin
  InternalDeleteText(Beg, Len);
  Update;
end;

procedure TAbstractTextViewer.SetText(const S: string; const AStyle: TCharStyle);
// Changes the text to S.
begin
  InternalSetText(S, AStyle);
  Update;
end;

procedure TAbstractTextViewer.Clear;
// Clears the text.
begin
  InternalClear;
  Update;
end;

function TAbstractTextViewer.CharAtPos(X, Y: integer): integer;
  // Returns the character index that stands on (X, Y) position on the control.
begin
  Result := InternalCharAtPos(X, Y);
end;

function TAbstractTextViewer.Copy(Beg, Len: integer): TAbstractTextChunk;
  // Copies the piece (Beg, Len) to the chunk.
begin
  Result := InternalCopy(Beg, Len);
end;

constructor TAbstractTextViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUpdating := 0;
end;

initialization
  FFonts := TFontList.Create(True);
  FFonts.Add(TFont.Create);

finalization
  FreeAndNil(FFonts);

end.
