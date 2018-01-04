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
    This file contains TVisualChessClock - a visual component for drawing a
    chess clock.
}
unit ChessClock;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ChessTime, ChessRules,
  Graphics, Math, ChessGUIUtils, Utilities;

type
  TClockOrientation = (coVertical, coHorizontal);

  { TVisualChessClock }

  TVisualChessClock = class(TFrame)
    LWhite: TLabel;
    LBlack: TLabel;
    WhiteTime: TLabel;
    WhiteShape: TShape;
    BlackShape: TShape;
    WhitePanel: TPanel;
    BlackPanel: TPanel;
    BlackTime: TLabel;
    procedure FrameResize(Sender: TObject);
    procedure Changer(Sender: TObject);
  private
    FClock: TChessTimer;
    FOrientation: TClockOrientation;
    // Setters
    procedure SetClock(AValue: TChessTimer);
    procedure SetOrientation(AValue: TClockOrientation);
    // Checkers for text (for binary search)
    function HorzFontChecker(X: integer): boolean;
    function TopFontChecker(X: integer): boolean;
    function BottomFontChecker(X: integer): boolean;
  public
    property Orientation: TClockOrientation read FOrientation write SetOrientation;
    property Clock: TChessTimer read FClock write SetClock;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure MovePanels;
    procedure UpdateLabels;
  end;

implementation

const
  // For HorzFontChecker.
  HorzTextMargin = 6;
  HorzTextHeight = 0.75;
  HorzTextSpace = 0.1;
  // For TopFontChecker & BottomFontChecker.
  VertTextMargin = 6;
  // For TopFontChecker.
  TopSpaceRatio = 0.3;
  TopCaptionRatio = 0.5;
  // For BottomFontChecker.
  BottomSpaceRatio = 0.1;
  BottomCaptionRatio = 1 - TopCaptionRatio;

{$R *.lfm}

{ TVisualChessClock }

procedure TVisualChessClock.FrameResize(Sender: TObject);
begin
  MovePanels;
end;

procedure TVisualChessClock.Changer(Sender: TObject);
begin
  UpdateLabels;
end;

procedure TVisualChessClock.SetClock(AValue: TChessTimer);
begin
  if FClock = AValue then
    Exit;
  FClock := AValue;
end;

procedure TVisualChessClock.SetOrientation(AValue: TClockOrientation);
begin
  if FOrientation = AValue then
    Exit;
  FOrientation := AValue;
  MovePanels;
end;

function TVisualChessClock.HorzFontChecker(X: integer): boolean;
  // Checks if font with size X fits the clock's sizes (in horz orientation).
var
  W1, W2, W, H, MaxW, MaxH: integer;
begin
  // putting font sizes
  LWhite.Canvas.Font.Size := X;
  WhiteTime.Canvas.Font.Size := X;
  LBlack.Canvas.Font.Size := X;
  BlackTime.Canvas.Font.Size := X;
  // calculating max width of the text
  W1 := LWhite.Canvas.TextWidth(LWhite.Caption) +
    WhiteTime.Canvas.TextWidth(WhiteTime.Caption);
  W2 := LBlack.Canvas.TextWidth(LBlack.Caption) +
    BlackTime.Canvas.TextWidth(BlackTime.Caption);
  W := Max(W1, W2);
  // calculating max height of the text
  H := LWhite.Canvas.TextHeight(LWhite.Caption);
  // calculating max possible height & width
  MaxW := Round((Width - 2 * HorzTextMargin) * (1 - HorzTextSpace));
  MaxH := Round((Height div 2) * HorzTextHeight);
  // now, checking
  Result := False;
  if W > MaxW then
    Exit;
  if H > MaxH then
    Exit;
  Result := True;
end;

function TVisualChessClock.TopFontChecker(X: integer): boolean;
  // Checks if top font with size X fits the clock's sizes (in vert orientation).
var
  W1, W2, W, H, MaxW, MaxH: integer;
begin
  // putting font sizes
  LWhite.Canvas.Font.Size := X;
  LBlack.Canvas.Font.Size := X;
  // calculating max width of the text
  W1 := LWhite.Canvas.TextWidth(LWhite.Caption);
  W2 := LBlack.Canvas.TextWidth(LBlack.Caption);
  W := Max(W1, W2);
  // calculating max height of the text
  H := LWhite.Canvas.TextHeight(LWhite.Caption);
  // calculating max possible width & height
  MaxW := Round((Width div 2) * (1 - TopSpaceRatio));
  MaxH := Round((Height - 2 * VertTextMargin) * TopCaptionRatio);
  // now, checking
  Result := False;
  if W > MaxW then
    Exit;
  if H > MaxH then
    Exit;
  Result := True;
end;

function TVisualChessClock.BottomFontChecker(X: integer): boolean;
  // Checks if bottom font with size X fits the clock's sizes (in vert orientation).
var
  W1, W2, W, H, MaxW, MaxH: integer;
begin
  // putting font sizes
  WhiteTime.Canvas.Font.Size := X;
  BlackTime.Canvas.Font.Size := X;
  // calculating max width of the text
  W1 := WhiteTime.Canvas.TextWidth(WhiteTime.Caption);
  W2 := BlackTime.Canvas.TextWidth(BlackTime.Caption);
  W := Max(W1, W2);
  // calculating max height of the text
  H := WhiteTime.Canvas.TextHeight(WhiteTime.Caption);
  // calculating max possible width & height
  MaxW := Round((Width div 2) * (1 - BottomSpaceRatio));
  MaxH := Round((Height - 2 * VertTextMargin) * BottomCaptionRatio);
  // now, checking
  Result := False;
  if W > MaxW then
    Exit;
  if H > MaxH then
    Exit;
  Result := True;
end;

procedure TVisualChessClock.MovePanels;
// Updates panels' properties according to the orientation.
begin
  if FOrientation = coHorizontal then
  begin
    // for horizontal orientation
    WhitePanel.Align := alTop;
    WhitePanel.Height := Height div 2;
    BlackPanel.Align := alClient;
    BlackPanel.Height := Height div 2;
    LWhite.Align := alLeft;
    LBlack.Align := alLeft;
    WhiteTime.Align := alRight;
    BlackTime.Align := alRight;
  end
  else
  begin
    // for vertical orientation
    WhitePanel.Align := alLeft;
    WhitePanel.Width := Width div 2;
    BlackPanel.Align := alClient;
    BlackPanel.Width := Width div 2;
    LWhite.Align := alTop;
    LBlack.Align := alTop;
    WhiteTime.Align := alClient;
    BlackTime.Align := alClient;
  end;
  UpdateLabels;
end;

procedure TVisualChessClock.UpdateLabels;
// Updates labels' captions and font props.
var
  HorzFont, TopFont, BottomFont: integer;

  procedure UpdateHorizontal;
  // Updates labels' font sizes in horz orientation.
  begin
    HorzFont := BinSearch(@HorzFontChecker);
    LWhite.Font.Size := HorzFont;
    LBlack.Font.Size := HorzFont;
    WhiteTime.Font.Size := HorzFont;
    BlackTime.Font.Size := HorzFont;
  end;

  procedure UpdateVertical;
  // Updates labels' font sizes in vert orientation.
  begin
    TopFont := BinSearch(@TopFontChecker);
    BottomFont := BinSearch(@BottomFontChecker);
    LWhite.Font.Size := TopFont;
    LBlack.Font.Size := TopFont;
    WhiteTime.Font.Size := BottomFont;
    BlackTime.Font.Size := BottomFont;
  end;

begin
  // update WhiteTime
  WhiteTime.Caption := GetTimeString(FClock.Clock.Times[pcWhite]);
  with WhiteTime.Canvas.Font do
    if (FClock.Clock.Active = pcWhite) and (not FClock.Paused) then
      Style := [fsBold]
    else
      Style := [];
  WhiteTime.Font.Style := WhiteTime.Canvas.Font.Style;
  // update BlackTime
  BlackTime.Caption := GetTimeString(FClock.Clock.Times[pcBlack]);
  with BlackTime.Canvas.Font do
    if (FClock.Clock.Active = pcBlack) and (not FClock.Paused) then
      Style := [fsBold]
    else
      Style := [];
  BlackTime.Font.Style := BlackTime.Canvas.Font.Style;
  // update sizes
  if FOrientation = coHorizontal then
    UpdateHorizontal
  else
    UpdateVertical;
end;

constructor TVisualChessClock.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FClock := TChessTimer.Create;
  FClock.OnChange := @Changer;
  DoubleBuffered := True;
  WhitePanel.DoubleBuffered := True;
  BlackPanel.DoubleBuffered := True;
  FOrientation := coHorizontal;
  WhiteTime.Font.Name := DefaultChessFont;
  BlackTime.Font.Name := DefaultChessFont;
  LWhite.Font.Name := DefaultChessFont;
  LBlack.Font.Name := DefaultChessFont;
end;

destructor TVisualChessClock.Destroy;
begin
  FreeAndNil(FClock);
  inherited Destroy;
end;

end.
