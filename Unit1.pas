unit Unit1;

interface

uses
  System.SysUtils,
  System.Classes,

  Sparkle.HttpServer.Module,
  Sparkle.HttpServer.Context,
  Sparkle.Comp.Server,
  Sparkle.Comp.HttpSysDispatcher,
  Sparkle.Comp.CorsMiddleware,
  Sparkle.Comp.CompressMiddleware,
  Sparkle.Comp.JwtMiddleware,

  Aurelius.Drivers.Interfaces,
  Aurelius.Comp.Connection,

  XData.Comp.ConnectionPool,
  XData.Server.Module,
  XData.Comp.Server,
  XData.Aurelius.ModelBuilder,

  Data.DB,

  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLite,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client;

type
  TServerContainer = class(TDataModule)
    SparkleHttpSysDispatcher: TSparkleHttpSysDispatcher;
    XDataServer: TXDataServer;
    XDataConnectionPool: TXDataConnectionPool;
    AureliusConnection: TAureliusConnection;
    XDataServerCORS: TSparkleCorsMiddleware;
    XDataServerJWT: TSparkleJwtMiddleware;
    XDataServerCompress: TSparkleCompressMiddleware;
    procedure DataModuleCreate(Sender: TObject);
  end;

var
  ServerContainer: TServerContainer;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TServerContainer.DataModuleCreate(Sender: TObject);
begin
  // Setup SwaggerUI Content
  TXDataModelBuilder.LoadXMLDoc(XDataServer.Model);
  XDataServer.Model.Title := 'Survey API';
  XDataServer.Model.Version := '1.0';
  XDataServer.Model.Description :=
    '### Overview'#13#10 +
    'This is the REST API for interacting with the Survey project.';

end;

end.
