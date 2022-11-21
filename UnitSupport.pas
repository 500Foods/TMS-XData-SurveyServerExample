unit UnitSupport;

interface

uses
  System.SysUtils,
  System.Classes,

  XData.Server.Module,
  XData.Service.Common,
  XData.Sys.Exceptions,

  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  FireDAC.Comp.BatchMove,
  FireDAC.Comp.BatchMove.Dataset,
  FireDAC.Comp.BatchMove.JSON;

type
  TSupport = class(TDataModule)
  private
    { Private declarations }
  public
    { Public declarations }

    procedure ConnectQuery(var conn: TFDConnection; var qry: TFDQuery);
    procedure CleanupQuery(var conn: TFDConnection; var qry: TFDQuery);
    procedure FireDACtoSimpleJSON(qry: TFDQuery; JSON: TStream);

    procedure LogHistory(qry: TFDQuery; account: string; client_version: string; client_release: string; survey: string; description: string);
  end;

var
  Support: TSupport;

implementation


uses Unit1, Unit2;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TSupport.ConnectQuery(var conn: TFDConnection; var qry: TFDQuery);
begin
  try
    // Establish a new connection for each endpoint invocation (not ideal!)
    conn := TFDConnection.Create(nil);
    conn.Params.Clear;
    conn.Params.DriverID := 'SQLite';
    conn.Params.Database := 'SurveyData.sqlite';
    conn.Params.Add('Synchronous=Full');
    conn.Params.Add('LockingMode=Normal');
    conn.Params.Add('SharedCache=False');
    conn.Params.Add('UpdateOptions.LockWait=True');
    conn.Params.Add('BusyTimeout=10000');
    conn.Params.Add('SQLiteAdvanced=page_size=4096');
    conn.Open;

    // Create a query to do our work
    qry := TFDQuery.Create(nil);
    qry.Connection := conn;

  except on E: Exception do
    begin
      // If the above fails, not a good thing, but at least try and make a note as to why
      Mainform.mmInfo.Lines.Add('[ '+E.ClassName+' ] '+E.Message);
    end;
  end;
end;

procedure TSupport.CleanupQuery(var conn: TFDConnection; var qry: TFDQuery);
begin
  try
    // Cleanup query that was created
    qry.Close;
    qry.Free;

    // Cleanup connection that was created
    conn.close;
    conn.Free;

  except on E: Exception do
    begin
      // If the above fails, not a good thing, but at least try and make a note as to why
      MainForm.mmInfo.Lines.Add('[ '+E.ClassName+' ] '+E.Message);
    end;
  end;
end;

procedure TSupport.FireDACtoSimpleJSON(qry: TFDQuery; JSON: TStream);
var
  bm: TFDBatchMove;
  bw: TFDBatchMoveJSONWriter;
  br: TFDBatchMoveDataSetReader;
begin
  bm := TFDBatchMove.Create(nil);
  bw := TFDBatchMoveJSONWriter.Create(nil);
  br := TFDBatchMoveDataSetReader.Create(nil);
  try
    br.Dataset := qry;
    bw.Stream := JSON;
    bm.Reader := br;
    bm.Writer := bw;
    bm.Execute;
  finally
    br.Free;
    bw.Free;
    bm.Free;
  end;
end;

procedure TSupport.LogHistory(qry: TFDQuery; account: string; client_version: string; client_release: string; survey: string; description: string);
begin
  // Populate query: history (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into history');
    SQL.Add('  (utc_stamp, ipaddr, account_id, survey_id, endpoint, client_ver, client_rel)');
    SQL.Add('values(');
    SQL.Add('  current_timestamp,');
    SQL.Add('  :IPADDR,');
    SQL.Add('  :ACCOUNT,');
    SQL.Add('  :SID,');
    SQL.Add('  :ENDPOINT,');
    SQL.Add('  :CLIENTV,');
    SQL.Add('  :CLIENTR');
    SQL.Add(');');
    ParamByName('IPADDR').AsString := TXDataOperationContext.Current.Request.RemoteIP;
    ParamByName('ACCOUNT').AsString := account;
    ParamByName('CLIENTV').AsString := client_version;
    ParamByName('CLIENTR').AsString := client_release;
    ParamByName('SID').AsString := survey;
    ParamByName('ENDPOINT').AsString := description;
  end;
  qry.ExecSQL;
end;

end.
