object MainFrm: TMainFrm
  Left = 0
  Top = 0
  ActiveControl = StartGame
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #28216#25103#32321#31616#30721#36716#25442#22823#24072
  ClientHeight = 83
  ClientWidth = 523
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GameExe: TLabeledEdit
    Left = 59
    Top = 11
    Width = 353
    Height = 21
    EditLabel.Width = 48
    EditLabel.Height = 13
    EditLabel.Caption = #28216#25103#25991#20214
    LabelPosition = lpLeft
    LabelSpacing = 5
    ReadOnly = True
    TabOrder = 0
  end
  object SelectGame: TButton
    Left = 421
    Top = 9
    Width = 93
    Height = 25
    Caption = #36873#25321#28216#25103
    TabOrder = 1
    OnClick = SelectGameClick
  end
  object StartGame: TButton
    Left = 421
    Top = 50
    Width = 93
    Height = 25
    Caption = #21270#32321#20026#31616
    TabOrder = 2
    OnClick = StartGameClick
  end
  object SelectGMdlg: TOpenDialog
    Filter = #28216#25103#20027#31243#24207'|*.exe'
    Left = 64
    Top = 40
  end
end
