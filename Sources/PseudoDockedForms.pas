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
    This unit implements the containers for PseudoDock Chess 256 interface.
    PseudoDock is a design when all the forms are docked into the main window.
    You can change their size and close some of them. It is "pseudo" because
    you cannot change their relative position. Their position is hardcoded in
    the MainForm.lfm using panels.
    This was a good (though not complete) solution in 2016, because AnchorDocking
    was not stable enough, but it has been improved much from that time. In the
    future, this unit will be removed and PseudoDock will be replaced with
    AnchorDocking.
}

// TODO : Delete this unit, replace PseudoDock with AnchorDocking!
unit PseudoDockedForms;

{$I CompilerDirectives.inc}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Buttons, Graphics,
  ApplicationForms;

type

  { TSpeedButton }

  TSpeedButton = class(Buttons.TSpeedButton)
  protected
    procedure Paint; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: integer;
      WithThemeSpace: boolean); override;
  end;

  { TPseudoDockContainer }

  TPseudoDockContainer = class(TFormContainer)
    CaptionLabel: TLabel;
    CaptionPanel: TPanel;
    HideButton: TSpeedButton;
    procedure HideButtonClick(Sender: TObject);
    procedure OwnerFormResized(Sender: TObject);
    procedure SplitterMoved(Sender: TObject);
    procedure FormCaptionChange(Sender: TObject);
  private
    FMoveRatioX, FMoveRatioY: double;
    FOnCaptionChange: TNotifyEvent;
    FOnHideForm: TNotifyEvent;
    FOnShowForm: TNotifyEvent;
    FOwnerForm: TWinControl;
    FSplitter: TSplitter;
    FFormWasBorderStyle: TBorderStyle;
    // Getters / Setters
    procedure SetOwnerForm(AValue: TWinControl);
    procedure SetSplitter(AValue: TSplitter);
    // Other methods
    procedure AlignSplitter;
  protected
    // Properties
    property Splitter: TSplitter read FSplitter write SetSplitter;
    // Other methods
    function GetShown: boolean; override;
    procedure BindForm(AForm: TApplicationForm); override;
    procedure UnbindForm; override;
  public
    // Properties
    property OwnerForm: TWinControl read FOwnerForm write SetOwnerForm;
    // Events
    property OnCaptionChange: TNotifyEvent read FOnCaptionChange write FOnCaptionChange;
    property OnHideForm: TNotifyEvent read FOnHideForm write FOnHideForm;
    property OnShowForm: TNotifyEvent read FOnShowForm write FOnShowForm;
    // Methods
    procedure AfterConstruction; override;
    procedure HideForm; override;
    procedure ShowForm; override;
    destructor Destroy; override;
  end;

function DockFormToPanel(AForm: TApplicationForm; AOwnerForm: TWinControl;
  APanel: TCustomPanel; ASplitter: TSplitter; CanHide: boolean): TPseudoDockContainer;

implementation

function DockFormToPanel(AForm: TApplicationForm; AOwnerForm: TWinControl;
  APanel: TCustomPanel; ASplitter: TSplitter; CanHide: boolean): TPseudoDockContainer;
  // Puts AForm into TPseudoDockContainer and puts the container into APanel.
  // Returns the created container.
var
  Container: TPseudoDockContainer;
begin
  Container := TPseudoDockContainer.Create(APanel);
  Container.Parent := APanel;
  Container.Align := alClient;
  Container.Form := AForm;
  Container.OwnerForm := AOwnerForm;
  Container.HideButton.Enabled := CanHide;
  Container.Splitter := ASplitter;
  Result := Container;
end;

{$R *.lfm}

{ TSpeedButton }

procedure TSpeedButton.Paint;
var
  ABitmap: TBitmap;
  Dif: integer;
begin
  // i don't like to see "Hide" button as a standard TSpeedButton.
  // i will paint it by myself
  // ABitmap will be the buffer
  ABitmap := TBitmap.Create;
  try
    with ABitmap do
    begin
      // set the buffer size
      SetSize(Glyph.Width, Glyph.Height);
      // filling the buffer with color (color depends on button state)
      Canvas.Brush.Style := bsSolid;
      case FState of
        bsUp: Canvas.Brush.Color := RGBToColor(192, 0, 0);
        bsDisabled: Canvas.Brush.Color := RGBToColor(150, 150, 150);
        bsDown: Canvas.Brush.Color := RGBToColor(160, 0, 0);
        bsExclusive: Canvas.Brush.Color := RGBToColor(255, 0, 0);
        bsHot: Canvas.Brush.Color := RGBToColor(255, 0, 0);
      end;
      Canvas.FillRect(0, 0, Width, Height);
      // calculating the glyph offset
      if FState = bsDown then
        Dif := Height div Self.Height
      else
        Dif := 0;
      // drawing the glyph
      DrawGlyph(Canvas, Rect(0, 0, Width, Height), Point(Dif, Dif), FState,
        Self.Transparent, 0);
    end;
    // now, draw the buffer into our button
    Canvas.StretchDraw(Rect(0, 0, Width, Height), ABitmap);
  finally
    FreeAndNil(ABitmap);
  end;
end;

procedure TSpeedButton.CalculatePreferredSize(
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: boolean);
begin
  inherited CalculatePreferredSize(PreferredWidth, PreferredHeight,
    WithThemeSpace);
  PreferredHeight := Canvas.TextHeight('X');
  PreferredWidth := PreferredHeight;
end;

{ TPseudoDockContainer }

procedure TPseudoDockContainer.HideButtonClick(Sender: TObject);
begin
  HideForm;
end;

procedure TPseudoDockContainer.OwnerFormResized(Sender: TObject);
begin
  if not Assigned(FSplitter) then
    Exit;
  // proportonally stretch the container
  Parent.SetBounds(Parent.Left, Parent.Top,
    Round(FMoveRatioX * (OwnerForm.ClientWidth + 1)),
    Round(FMoveRatioY * (OwnerForm.ClientHeight + 1)));
  AlignSplitter;
end;

procedure TPseudoDockContainer.SplitterMoved(Sender: TObject);
begin
  if FSplitter = nil then
    Exit;
  // calc what part of the owner form our container take (in ratio)
  // nessesary to stretch proportionally when resized
  FMoveRatioX := (Parent.Width - 1) / (OwnerForm.ClientWidth + 1);
  FMoveRatioY := (Parent.Height - 1) / (OwnerForm.ClientHeight + 1);
  if FMoveRatioX < 0 then
    FMoveRatioX := 0;
  if FMoveRatioY < 0 then
    FMoveRatioY := 0;
end;

procedure TPseudoDockContainer.FormCaptionChange(Sender: TObject);
begin
  CaptionLabel.Caption := Form.Caption;
  if Assigned(FOnCaptionChange) then
    FOnCaptionChange(Self);
end;

procedure TPseudoDockContainer.SetOwnerForm(AValue: TWinControl);
begin
  if FOwnerForm = AValue then
    Exit;
  if Assigned(FOwnerForm) then
    FOwnerForm.RemoveHandlerOnResize(@OwnerFormResized);
  FOwnerForm := AValue;
  if Assigned(FOwnerForm) then
    FOwnerForm.AddHandlerOnResize(@OwnerFormResized);
end;

procedure TPseudoDockContainer.SetSplitter(AValue: TSplitter);
begin
  if FSplitter = AValue then
    Exit;
  if Assigned(FSplitter) then
    FSplitter.OnMoved := nil;
  FSplitter := AValue;
  if Assigned(FSplitter) then
  begin
    FSplitter.OnMoved := @SplitterMoved;
    FSplitter.OnMoved(Self);
  end;
end;

procedure TPseudoDockContainer.AlignSplitter;
// Puts the splitter in such way that it can resize our container.
begin
  if Assigned(FSplitter) then
  begin
    case FSplitter.Align of
      alTop: FSplitter.Top := Parent.Top + 1;
      alBottom: FSplitter.Top :=
          Parent.Top + Parent.Height - FSplitter.Height - 1;
      alLeft: FSplitter.Left := Parent.Left + 1;
      alRight: FSplitter.Left := Parent.Left + Parent.Width - FSplitter.Width - 1;
    end;
  end;
end;

function TPseudoDockContainer.GetShown: boolean;
  // Returns True if the container is shown.
begin
  Result := Parent.Visible;
end;

procedure TPseudoDockContainer.BindForm(AForm: TApplicationForm);
// Binds the form to the container.
begin
  inherited;
  CaptionLabel.Caption := AForm.Caption;
  AForm.BorderStyle := bsNone;
  AForm.Visible := True;
  AForm.Parent := Self;
  AForm.Align := alClient;
  AForm.OnCaptionChange := @FormCaptionChange;
end;

procedure TPseudoDockContainer.UnbindForm;
// Unbinds the from from the container.
begin
  if Form = nil then
    Exit;
  Form.BorderStyle := FFormWasBorderStyle;
  Form.Parent := nil;
  Form.Align := alNone;
  Form.OnCaptionChange := nil;
  CaptionPanel.Caption := '';
  inherited;
end;

procedure TPseudoDockContainer.AfterConstruction;

  procedure LoadGlyph;
  // Loads the glyph from resources.
  var
    PNG: TPortableNetworkGraphic;
  begin
    PNG := TPortableNetworkGraphic.Create;
    try
      PNG.LoadFromResourceName(HINSTANCE, 'PseudoDock.CloseBtn');
      HideButton.Glyph.Assign(PNG);
    finally
      FreeAndNil(PNG);
    end;
  end;

begin
  inherited AfterConstruction;
  CaptionPanel.DoubleBuffered := True;
  CaptionPanel.Font.Size := 11;
  BorderSpacing.Around := 1;
  LoadGlyph;
  HideButton.AutoSize := True;
end;

procedure TPseudoDockContainer.HideForm;
// Hides the container.
begin
  Form.Hide;
  Parent.Visible := False;
  if Assigned(FSplitter) then
    FSplitter.Visible := False;
  if Assigned(FOnHideForm) then
    FOnHideForm(Self);
end;

procedure TPseudoDockContainer.ShowForm;
// Shows the container.
begin
  Form.Show;
  Parent.Visible := True;
  FSplitter.Visible := True;
  AlignSplitter;
  if Assigned(FOnShowForm) then
    FOnShowForm(Self);
end;

destructor TPseudoDockContainer.Destroy;
begin
  OwnerForm := nil;
  inherited Destroy;
end;

end.
