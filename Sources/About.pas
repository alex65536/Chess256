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
    This file contains about box.
}
unit About;

{$I CompilerDirectives.inc}

interface

uses
  LicenseInfo, SysUtils, StdCtrls, ExtCtrls, ApplicationForms, VersionResource,
  Forms, Controls;

resourcestring
  SVersionFmt = 'version %s';

type

  { TAboutBox }

  TAboutBox = class(TApplicationForm)
    AppBuildDate: TLabel;
    AppDeveloper: TLabel;
    AppVersion: TLabel;
    CenterBevel: TBevel;
    CloseBtn: TButton;
    LicenseInfoBtn: TButton;
    ButtonPanel: TPanel;
    TopBevel: TBevel;
    BottomBevel: TBevel;
    DeveloperEMail: TLabel;
    HaveNiceGame: TLabel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LAppBuildDate: TLabel;
    LAppDeveloper: TLabel;
    LDeveloperEMail: TLabel;
    NamePanel: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure CloseBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LicenseInfoBtnClick(Sender: TObject);
  public
    function GetAppVersion: string;
  end;

var
  AboutBox: TAboutBox;

implementation

uses
  Resource
  {$IFDEF WINDOWS}
  , WinPEImageReader
  {$ELSE}
  , ElfReader
  {$ENDIF};

{$R *.lfm}

{ TAboutBox }

procedure TAboutBox.FormCreate(Sender: TObject);
// Initializes some labels on creation.
var
  DateFmt: TFormatSettings;
  ViewFmt: string = 'dd.mm.yyyy';
  BuildDateFmt: string = '%s %s';
begin
  AppVersion.Caption := Format(SVersionFmt, [GetAppVersion]);
  DateFmt.ShortDateFormat := 'y/m/d';
  DateFmt.DateSeparator := '/';
  AppBuildDate.Caption :=
    Format(BuildDateFmt, [FormatDateTime(ViewFmt, StrToDateTime(
      {$INCLUDE %DATE%}, DateFmt)), {$INCLUDE %TIME%}]);
  ScaleLabelsFromTags;
end;

procedure TAboutBox.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TAboutBox.FormShow(Sender: TObject);
begin
  // If top labels are bigger than the rest of the text, we make it fill all
  // the width. Without this code the part of the top label will be hidden.
  if TopBevel.Width < NamePanel.Width then
    NamePanel.AnchorSideLeft.Side := asrTop;
  AdjustSize;
end;

procedure TAboutBox.LicenseInfoBtnClick(Sender: TObject);
begin
  LicenseInfoFrom.ShowModal;
end;

function TAboutBox.GetAppVersion: string;
  // Returns the application version from its resources.
const
  AppVersionName = 'ProductVersion';
var
  Res: TResources;
  I: integer;
  Reader: TAbstractResourceReader;
  V: TVersionResource;
  Q: string;
begin
  // the code used from lazresexplorer (a Lazarus example)
  {$IFDEF WINDOWS}
  Reader := TWinPEImageResourceReader.Create;
  {$ELSE}
  Reader := TElfResourceReader.Create;
  {$ENDIF}
  Res := TResources.Create;
  Res.LoadFromFile(Application.ExeName, Reader);
  V := nil;
  for I := 0 to Res.Count - 1 do
    if Res[i] is TVersionResource then
      V := Res[i] as TVersionResource;
  if V = nil then
    Result := '?.?.?.?'
  else
  begin
    Result := '';
    for I := 0 to V.StringFileInfo.Count - 1 do
    begin
      try
        Q := V.StringFileInfo.Items[I].Values[AppVersionName];
      except
        Q := '';
      end;
      Result := Q;
    end;
  end;
  FreeAndNil(Res);
  FreeAndNil(Reader);
end;

end.
