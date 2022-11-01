unit SurveyClientServiceImplementation;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  XData.Sys.Exceptions,

  Sparkle.Security,

  System.Classes,
  System.SysUtils,

  Bcl.Jose.Core.JWT,
  Bcl.Jose.Core.Builder,

  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  FireDAC.Comp.BatchMove,
  FireDAC.Comp.BatchMove.Dataset,
  FireDAC.Comp.BatchMove.JSON,

  SurveyClientService;

type
  [ServiceImplementation]
  TSurveyClientService = class(TInterfacedObject, ISurveyClientService)
  private

    function GetSurvey(SurveyLink: String; ClientID: String): TStream;
    function GetQuestions(SurveyID: String; ClientID: String): TStream;
    function SaveResponses(SurveyID: String; ClientID: String; Responses: String): TStream;
    function Feedback(ClientID: String; SID: String; FeedbackID: String; Feedback: String; Stage: String; SurveyName: String; SurveyGroup: String; ActivityLog: String; ActivityLogSize: Integer): TStream;

  end;

implementation

uses UnitSupport;

function TSurveyClientService.Feedback(ClientID: String; SID, FeedbackID, Feedback, Stage, SurveyName, SurveyGroup, ActivityLog: String; ActivityLogSize: Integer): TStream;
var
  fdc: TFDConnection;
  qry: TFDQuery;

  response: String;

begin

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, ClientID, SID, 'Feedback [ '+Stage+' ]');

  // Populate query: feedback (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into feedback');
    SQL.Add('  (utc_stamp, client_id, survey_id, feedback_id, feedback, stage, resolution, activitylog, activitylog_size)');
    SQL.Add('values(');
    SQL.Add('  CURRENT_TIMESTAMP,');
    SQL.Add('  :CID,');
    SQL.Add('  :SID,');
    SQL.Add('  :FID,');
    SQL.Add('  :AFEEDBACK,');
    SQL.Add('  :ASTAGE,');
    SQL.Add('  "New Feedback",');
    SQL.Add('  :ALOG,');
    SQL.Add('  :ALOGSIZE');
    SQL.Add(');');
    ParamByName('CID').AsString := ClientID;
    ParamByName('SID').AsString := SID;
    ParamByName('FID').AsString := FeedbackID;
    ParamByName('AFEEDBACK').AsString := Feedback;
    ParamByName('ASTAGE').AsString := Stage;
    ParamByName('ALOG').AsString := ActivityLog;
    ParamByName('ALOGSIZE').AsInteger := ActivityLogSize;
  end;
  qry.ExecSQL;

  // Send this back
  Response := '{"Reply":"Feedback Accepted. Thank you."}';
  Result := TStringStream.Create(Response);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyClientService.GetQuestions(SurveyID, ClientID: String): TStream;
var
  fdc: TFDConnection;
  qry: TFDQuery;

  Questions: String;

begin

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, ClientID, SurveyID, 'GetQuestions');

  // Populate query: questions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  question_list');
    SQL.Add('     from  questions');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SurveyID;
  end;
  qry.Open;

  Questions := qry.FieldByName('question_list').AsString;
  if Questions = '' then Questions := '[]';

  // Return query as JSON stream
  Result := TStringStream.Create(Questions);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyClientService.GetSurvey(SurveyLink: String; ClientID:String): TStream;
var
  fdc: TFDConnection;
  qry: TFDQuery;

  SurveyID: String;
  SurveyName: String;
  SurveyGroup: String;
  SurveyData: String;
begin

  // Similar to GetSurveyByID but using the Link value as the identifier
  // And also no JWT here

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);


  // Populate query: surveys, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  survey, survey_id, survey_name, survey_group');
    SQL.Add('     from  surveys');
    SQL.Add('    where  survey_link = :LID;');
    ParamByName('LID').AsString := SurveyLink;
  end;
  qry.Open;

  // Return query as JSON stream
  SurveyData := qry.FieldByName('survey').AsString;
  SurveyID := qry.FieldByName('survey_id').AsString;
  SurveyName := qry.FieldByName('survey_name').AsString;
  SurveyGroup := qry.FieldByName('survey_group').AsString;
  if SurveyData = '' then
  begin
    SurveyData := '{}';
    SurveyID := 'Survey Not Found';
  end;
  Result := TStringStream.Create(SurveyData);

  // Record what we're up to
  // We're doing this after rather than before as we don't know the SurveyName or group ahead of time
  Support.LogHistory(qry, ClientID, SurveyID, 'GetSurvey [ '+SurveyLink+': '+SurveyGroup+'/'+SurveyName+' ]');


  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyClientService.SaveResponses(SurveyID, ClientID, Responses: String): TStream;
var
  fdc: TFDConnection;
  qry: TFDQuery;

  response: String;

begin

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, ClientID, SurveyID, 'Response Received');

  // Note: Some DBs support an "update or insert" call but some don't
  //       Here we handle them separately.  As there are likely to be
  //       many updates and only one insert, we prioritize the update

  // Populate query: feedback (update)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('update responses');
    SQL.Add('  set ');
    SQL.Add('    utc_stamp = CURRENT_TIMESTAMP,');
    SQL.Add('    response = :ARESPONSE');
    SQL.Add('  where');
    SQL.Add('    survey_id = :SID');
    SQL.Add('    and client_id = :CID');
    SQL.Add(';');
    ParamByName('SID').AsString := SurveyID;
    ParamByName('CID').AsString := ClientID;
    ParamByName('ARESPONSE').AsString := Responses;
  end;
  qry.ExecSQL;

  // Populate query: feedback (insert)
  if qry.RowsAffected = 0 then
  begin
    with qry do
    begin
      SQL.Clear;
      SQL.Add('insert into responses');
      SQL.Add('  (utc_stamp, survey_id, client_id, response)');
      SQL.Add('values(');
      SQL.Add('  CURRENT_TIMESTAMP,');
      SQL.Add('  :SID,');
      SQL.Add('  :CID,');
      SQL.Add('  :ARESPONSE');
      SQL.Add(');');
      ParamByName('SID').AsString := SurveyID;
      ParamByName('CID').AsString := ClientID;
      ParamByName('ARESPONSE').AsString := Responses;
    end;
    qry.ExecSQL;
  end;

  // Send this back
  Response := '{"Reply":"Responses Received. Thank you."}';
  Result := TStringStream.Create(Response);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

initialization
  RegisterServiceType(TSurveyClientService);

end.
