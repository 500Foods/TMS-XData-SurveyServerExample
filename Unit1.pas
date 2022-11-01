unit Unit1;

interface

uses
  System.SysUtils,
  System.Classes,

  Sparkle.Comp.HttpSysDispatcher,
  Sparkle.HttpServer.Module,
  Sparkle.HttpServer.Context,
  Sparkle.Comp.Server,
  Sparkle.Comp.CompressMiddleware,
  Sparkle.Comp.JwtMiddleware,
  Sparkle.Comp.CorsMiddleware,

  Aurelius.Comp.Connection,
  Aurelius.Drivers.Interfaces,

  XData.Aurelius.ModelBuilder,
  XData.Comp.ConnectionPool,
  XData.Server.Module,
  XData.Comp.Server,

  Data.DB,

  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Phys,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  FireDAC.Phys.SQLite,

  // We want access to TApplication
  // Otherwise we wouldn't normally need these

  Vcl.Forms,
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellApi,

  PsAPI,
  TlHelp32,

  MiscObj,
  HashObj;

type
  TServerContainer = class(TDataModule)
    SparkleHttpSysDispatcher: TSparkleHttpSysDispatcher;
    XDataServer: TXDataServer;
    XDataConnectionPool: TXDataConnectionPool;
    AureliusConnection: TAureliusConnection;
    XDataServerCORS: TSparkleCorsMiddleware;
    XDataServerJWT: TSparkleJwtMiddleware;
    XDataServerCompress: TSparkleCompressMiddleware;
    FDConnection1: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDQuery1: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
  public
    REST_URL:string;
    SWAG_URL: string;
  end;

var
  ServerContainer: TServerContainer;
  AppVersionString: String;
  AppVersionShort: String;
  AppVersionLast: String;
  ReleaseDate: TDateTime;
  AppRelease: String;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure GetVersionInfo;
var
  verblock: PVSFIXEDFILEINFO;
  versionMS: cardinal;
  versionLS: cardinal;
  verlen: cardinal;
  rs: TResourceStream;
  m: TMemoryStream;
  p: pointer;
  s: cardinal;
begin
  // Adapted from https://stackoverflow.com/questions/1717844/how-to-determine-delphi-application-version
  m := TMemoryStream.Create;
  try
    rs := TResourceStream.CreateFromID(HInstance,1,RT_VERSION);
    try
      m.CopyFrom(rs,rs.Size);
    finally
      rs.Free;
    end;
    m.Position := 0;
    if VerQueryValue(m.Memory,'\',pointer(verblock),verlen) then
    begin
      VersionMS := verblock.dwFileVersionMS;
      VersionLS := verblock.dwFileVersionLS;
      AppVersionString := 'Core Server '+
          IntToStr(versionMS shr 16)+'.'+
          IntToStr(versionMS and $FFFF)+'.'+
          IntToStr(VersionLS shr 16)+'.'+
          IntToStr(VersionLS and $FFFF);
      AppVersionShort :=
          IntToStr(versionMS shr 16)+'.'+
          IntToStr(versionMS and $FFFF)+'.'+
          IntToStr(VersionLS shr 16)+'.'+
          IntToStr(VersionLS and $FFFF);
      AppVersionLast := IntToStr(VersionLS and $FFFF);
    end;
    if VerQueryValue(m.Memory,PChar('\\StringFileInfo\\'+
      IntToHex(GetThreadLocale,4)+IntToHex(GetACP,4)+'\\FileDescription'),p,s) or
        VerQueryValue(m.Memory,'\\StringFileInfo\\040904E4\\FileDescription',p,s) then //en-us
          AppVersionString := PChar(p)+' '+AppVersionString;
  finally
    m.Free;
  end;

  FileAge(ParamStr(0), ReleaseDate);
  AppRelease := FormatDateTime('yyyy-MMM-dd', ReleaseDate);
end;

procedure TServerContainer.DataModuleCreate(Sender: TObject);
var
  sha2: TSHA2Hash;
  password: string;
begin

  // figure out whether we're operating in dev mode or production mode
  if ParamStr(1) = 'DEV' then
  begin
    XDataServer.BaseURL := 'http://+:2001/tms/xdata';
    REST_URL := 'http://localhost:2001/tms/data';
    SWAG_URL := 'http://localhost:2001/tms/xdata/swaggerui';
  end
  else
  begin
    XDataServer.BaseURL := 'https://+:10101/500Surveys';
    REST_URL := 'https://carnival.500foods.com:10101/500Surveys';
    SWAG_URL := 'https://carnival.500foods.com:10101/500Surveys/swaggerui';
  end;

  // NOW we can start this
  SparkleHttpSysDispatcher.Active := True;

  // Setup SwaggerUI Content
  TXDataModelBuilder.LoadXMLDoc(XDataServer.Model);
  XDataServer.Model.Title := 'Survey API';
  XDataServer.Model.Version := '1.0';
  XDataServer.Model.Description :=
    '### Overview'#13#10 +
    'This is the REST API for interacting with the Survey project.';


  // FDConnection component dropped on form
  // FDPhysSQLiteDriverLink component droppoed on form
  // FDQuery component dropped on form


  // This creates the database if it doesn't already exist
  FDManager.Open;
  FDConnection1.Params.Clear;
  FDConnection1.Params.DriverID := 'SQLite';
  FDConnection1.Params.Database := 'SurveyData.sqlite';
  FDConnection1.Params.Add('Synchronous=Full');
  FDConnection1.Params.Add('LockingMode=Normal');
  FDConnection1.Params.Add('SharedCache=False');
  FDConnection1.Params.Add('UpdateOptions.LockWait=True');
  FDConnection1.Params.Add('BusyTimeout=10000');
  FDConnection1.Params.Add('SQLiteAdvanced=page_size=4096');

  // Connect to the database

  // NOTE: This connection is just used for creating the database
  //       and adding some status information, not a general pooled
  //       connection or anything shared that might normally be setup
  //       in this space

  FDConnection1.Open;

  // Create the tables if they don't already exist
  FDQuery1.Connection := FDConnection1;
  with FDQuery1 do
  begin
    SQL.Clear;

    SQL.Add('create table if not exists accounts ('+
              'account_id char(38),'+
              'email text,'+
              'first_name text,'+
              'last_name text,'+
              'password_hash text,'+
              'security char(5)'+
            ');');

    SQL.Add('create table if not exists surveys ('+
              'survey_id char(38),'+
              'survey_name text,'+
              'survey_group text,'+
              'survey_link text,'+
              'survey text'+
            ');');

    SQL.Add('create table if not exists permissions ('+
              'survey_id char(38),'+
              'account_id char(38),'+
              'permissions char(5)'+
            ');');

    SQL.Add('create table if not exists changes ('+
              'survey_id char(38),'+
              'account_id char(38),'+
              'ipaddr varchar(50),'+
              'utc_stamp text,'+
              'change text'+
            ');');

    SQL.Add('create table if not exists history ('+
              'utc_stamp text,'+
              'ipaddr varchar(50),'+
              'account_id varchar(38),'+
              'survey_id varchar(38),'+
              'endpoint text'+
            ');');

    SQL.Add('create table if not exists notes ('+
              'utc_stamp text,'+
              'note_id varchar(38),'+
              'account_id varchar(38),'+
              'survey_id varchar(38),'+
              'note text'+
            ');');

    SQL.Add('create table if not exists issues ('+
              'utc_stamp text,'+
              'issue_id varchar(38),'+
              'account_id varchar(38),'+
              'survey_id varchar(38),'+
              'category text,'+
              'resolution text,'+
              'activitylog text,'+
              'activitylog_size integer,'+
              'issue text'+
            ');');

    SQL.Add('create table if not exists feedback ('+
              'utc_stamp text,'+
              'feedback_id varchar(38),'+
              'client_id varchar(38),'+
              'survey_id varchar(38),'+
              'stage text,'+
              'resolution text,'+
              'activitylog text,'+
              'activitylog_size integer,'+
              'feedback text'+
            ');');

    SQL.Add('create table if not exists questions ('+
              'survey_id varchar(38),'+
              'question_list text'+
            ');');

    SQL.Add('create table if not exists responses ('+
              'utc_stamp text,'+
              'survey_id varchar(38),'+
              'client_id varchar(38),'+
              'response text'+
            ');');

    // Not implmenented yet
    SQL.Add('create table if not exists library ('+
              'library_id varchar(38),'+
              'library_name text,'+
              'question_type integer,'+
              'question_options text'+
            ');');

  end;
  FDQuery1.ExecSQL;


  // if there are no accounts, create a default account
  // Default Username: setup
  // Default Password: password1234
  with FDQuery1 do
  begin
    SQL.Clear;
    SQL.Add('select count(*) usercount from accounts;');
  end;
  FDQuery1.Open;

  if FDQuery1.FieldByName('usercount').AsInteger = 0 then
  begin

    // Generate password hash
    sha2 := TSHA2Hash.Create;
    sha2.HashSizeBits := 256;
    sha2.OutputFormat := hexa;
    sha2.Unicode := noUni;
    password := sha2.Hash('password1234');
    sha2.Free;

    with FDQuery1 do
    begin
      SQL.Clear;
      SQL.Add('insert into accounts values("{D10C19DE-7253-42FB-85CB-A1E0F378BFC0}","setup","Default","User","'+password+'","WWWWW");');
    end;
    FDQuery1.ExecSQL;

    with FDQuery1 do
    begin
      SQL.Clear;
      SQL.Add('insert into history (utc_stamp, endpoint) values(current_timestamp, "'+Application.Title+' Database Created");');
    end;
    FDQuery1.ExecSQL;
    sleep(1);

  end;

  // Log server startup as a history event
  GetVersionInfo;

  with FDQuery1 do
  begin
    SQL.Clear;
    SQL.Add('insert into history (utc_stamp, endpoint) values(current_timestamp, "Release: '+AppRelease+'");');
  end;
  FDQuery1.ExecSQL;
  sleep(1);

  with FDQuery1 do
  begin
    SQL.Clear;
    SQL.Add('insert into history (utc_stamp, endpoint) values(current_timestamp, "Version: '+AppVersionShort+'");');
  end;
  FDQuery1.ExecSQL;
  sleep(1);

  with FDQuery1 do
  begin
    SQL.Clear;
    SQL.Add('insert into history (utc_stamp, endpoint) values(current_timestamp, "'+Application.Title+' Started");');
  end;
  FDQuery1.ExecSQL;


  // We're all done here
  FDConnection1.Close;

end;

end.
