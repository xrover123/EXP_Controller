object Main: TMain
  Left = 701
  Top = 135
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'File exchange manager 2.2'
  ClientHeight = 69
  ClientWidth = 376
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 27
    Top = 24
    Width = 3
    Height = 13
  end
  object PB: TProgressBar
    Left = 24
    Top = 24
    Width = 329
    Height = 17
    Max = 60
    TabOrder = 0
  end
  object ORAConnection: TSQLConnection
    ConnectionName = 'OracleConnection'
    DriverName = 'Oracle'
    GetDriverFunc = 'getSQLDriverORACLE'
    LibraryName = 'dbexpora.dll'
    LoginPrompt = False
    Params.Strings = (
      'DriverName=Oracle'
      'DataBase='
      'User_Name='
      'Password='
      'RowsetSize=20'
      'BlobSize=-1'
      'ErrorResourceFile='
      'LocaleCode=0000'
      'Oracle TransIsolation=ReadCommited'
      'OS Authentication=False'
      'Multiple Transaction=False'
      'Trim Char=False')
    VendorLib = 'oci.dll'
    Left = 8
  end
  object OraProc: TSQLStoredProc
    MaxBlobSize = -1
    Params = <
      item
        DataType = ftString
        ParamType = ptInput
      end
      item
        DataType = ftString
        ParamType = ptOutput
      end>
    SQLConnection = ORAConnection
    Left = 72
  end
  object V: TSQLQuery
    MaxBlobSize = -1
    Params = <>
    SQLConnection = ORAConnection
    Left = 112
  end
end
