object ServerContainer: TServerContainer
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 260
  Width = 492
  object SparkleHttpSysDispatcher: TSparkleHttpSysDispatcher
    Left = 72
    Top = 16
  end
  object XDataServer: TXDataServer
    BaseUrl = 'http://+:2001/tms/xdata'
    Dispatcher = SparkleHttpSysDispatcher
    Pool = XDataConnectionPool
    EntitySetPermissions = <>
    SwaggerOptions.Enabled = True
    SwaggerOptions.AuthMode = Jwt
    SwaggerUIOptions.Enabled = True
    SwaggerUIOptions.ShowFilter = True
    SwaggerUIOptions.TryItOutEnabled = True
    Left = 216
    Top = 16
    object XDataServerCORS: TSparkleCorsMiddleware
      Origin = '*'
    end
    object XDataServerJWT: TSparkleJwtMiddleware
      Secret = 'ThisIsAReallyLongSecretToMeetTheXDataLengthRequirements'
    end
    object XDataServerCompress: TSparkleCompressMiddleware
    end
  end
  object XDataConnectionPool: TXDataConnectionPool
    Connection = AureliusConnection
    Left = 216
    Top = 72
  end
  object AureliusConnection: TAureliusConnection
    Left = 216
    Top = 128
  end
  object FDConnection1: TFDConnection
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
  object FDQuery1: TFDQuery
    Connection = FDConnection1
    Left = 352
    Top = 160
  end
end
