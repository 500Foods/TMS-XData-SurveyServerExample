object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'TMS XData Server'
  ClientHeight = 242
  ClientWidth = 472
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMinimized
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    472
    242)
  PixelsPerInch = 96
  TextHeight = 13
  object mmInfo: TMemo
    Left = 8
    Top = 40
    Width = 456
    Height = 194
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object btStart: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 1
    OnClick = btStartClick
  end
  object btStop: TButton
    Left = 90
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 2
    OnClick = btStopClick
  end
  object btSwagger: TButton
    Left = 171
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Swagger'
    TabOrder = 3
    OnClick = btSwaggerClick
  end
  object btRedoc: TButton
    Left = 252
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Redoc'
    TabOrder = 4
    OnClick = btRedocClick
  end
  object btEMail: TButton
    Left = 333
    Top = 8
    Width = 75
    Height = 25
    Caption = 'E-Mail'
    TabOrder = 5
    OnClick = btEMailClick
  end
  object tmrInit: TTimer
    Enabled = False
    OnTimer = tmrInitTimer
    Left = 104
    Top = 104
  end
  object tmrStart: TTimer
    Enabled = False
    OnTimer = tmrStartTimer
    Left = 160
    Top = 104
  end
  object DBConn: TFDConnection
    Params.Strings = (
      'SharedCache=False'
      'LockingMode=Normal'
      'JournalMode=WAL'
      'StringFormat=Unicode'
      
        'Database=C:\Users\Andrew Simard\Documents\Embarcadero\Studio\Pro' +
        'jects\TMS-XData-SurveyServerExample\Win64\Debug\SurveyData.sdb'
      'Encrypt=aes-256'
      'DriverID=SQLite')
    Left = 352
    Top = 64
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    Left = 352
    Top = 112
  end
  object Query1: TFDQuery
    Connection = DBConn
    Left = 352
    Top = 160
  end
end
