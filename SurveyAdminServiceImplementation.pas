unit SurveyAdminServiceImplementation;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  XData.Sys.Exceptions,

  Sparkle.Security,

  System.Classes,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,

  Bcl.Jose.Core.JWT,
  Bcl.Jose.Core.Builder,


  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  FireDAC.Comp.BatchMove,
  FireDAC.Comp.BatchMove.Dataset,
  FireDAC.Comp.BatchMove.JSON,

  MiscObj,
  HashObj,

  SurveyAdminService;

type
  [ServiceImplementation]
  TSurveyAdminService = class(TInterfacedObject, ISurveyAdminService)
  private

    function Login(Email: string; Password: string):string;

    function GetSurveys: TStream;
    function GetSurveyByID(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    function GetSurveyInfo(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    function GetSurveyChangeHistory(SID: String; SurveyName: String; SurveyGroup: String): TStream;

    function NewSurvey(SID: String; SName: String; SGroup: String; SLink: String; SData: String; Change: String): TStream;
    function UpdateSurvey(SID: String; SurveyGroup: String; SurveyName: String; SurveyLink: String; SurveyData: String; Changes: String): TStream;
    function DeleteSurvey(SID: String; SurveyGroup: String; SurveyName: String): TStream;

    function GetQuestions(SID: String): TStream;
    function SetQuestions(SID: String; Questions: String): TStream;

    function GetSurveyNotes(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    function AddSurveyNote(SID: String; NoteID: String; Note: String; SurveyName: String; SurveyGroup: String): TStream;
    function DeleteSurveyNote(SID: String; NoteID: String; SurveyName: String; SurveyGroup: String): TStream;

    function GetSurveyPermissions(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    function SetSurveyPermissions(SID: String; SurveyName: String; SurveyGroup: String; AccountID: String; FirstName: String; LastName: String; Permissions: String): TStream;

    function GetAccounts: TStream;
    function UpdateAccount(AccountID: String; FirstName: String; LastName: String; EMail: String): TStream;
    function NewAccount(AccountID: String; FirstName: String; LastName: String; EMail: String; Password: String; Security: String): TStream;
    function DeleteAccount(AccountID: String; FirstName: String; LastName: String; EMail: String): TStream;
    function SetPassword(AccountID: String; FirstName: String; LastName: String; EMail: String; Password: String): TStream;

    function ReportIssue(SID: String; IssueID: String; Issue: String; Category: String; SurveyName: String; SurveyGroup: String; ActivityLog: String; ActivityLogSize: Integer): TStream;
    function GetAllIssues: TStream;
    function SetIssueStatus(IssueID: String; Status: String): TStream;
    function GetIssueActivityLog(IssueID: String): TStream;

    function GetAllFeedback: TStream;
    function GetFeedbackActivityLog(FeedbackID: String): TStream;

    function GetAllResponses: TStream;

    function GetHistory(Days: Integer): TStream;

  end;

implementation

uses Unit1, Unit2, UnitSupport;



function TSurveyAdminService.AddSurveyNote(SID, NoteID, Note: String; SurveyName: String; SurveyGroup: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'AddSurveyNote [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: notes (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into notes');
    SQL.Add('  (utc_stamp, survey_id, account_id, note_id, note)');
    SQL.Add('values(');
    SQL.Add('  CURRENT_TIMESTAMP,');
    SQL.Add('  :SID,');
    SQL.Add('  :ACCOUNT,');
    SQL.Add('  :NID,');
    SQL.Add('  :ANOTE');
    SQL.Add(');');
    ParamByName('SID').AsString := SID;
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
    ParamByName('NID').AsString := NoteID;
    ParamByName('ANOTE').AsString := Note;
  end;
  qry.ExecSQL;

  // Populate query: notes, accounts, surveys (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  notes.utc_stamp, notes.note_id, accounts.first_name, accounts.last_name, accounts.email, notes.note, surveys.survey_name, surveys.survey_group');
    SQL.Add('     from  notes');
    SQL.Add('             left outer join accounts');
    SQL.Add('               on  notes.account_id = accounts.account_id');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on  notes.survey_id = surveys.survey_id');
    SQL.Add('    where  notes.survey_id = :SURVEYID');
    SQL.Add(' order by  notes.utc_stamp desc;');
    ParamByName('SURVEYID').AsString := SID;
  end;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.DeleteAccount(AccountID, FirstName, LastName, EMail: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'DeleteAccount [ '+FirstName+' '+LastName+' ]');

  // Populate query: accounts (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from accounts');
    SQL.Add('where');
    SQL.Add('  account_id = :AID');
    SQL.Add('  and first_name = :FNAME');
    SQL.Add('  and last_name = :LNAME');
    SQL.Add('  and email = :MAIL');
    SQL.Add(';');
    ParamByName('AID').AsString := AccountID;
    ParamByName('FNAME').AsString := FirstName;
    ParamByName('LNAME').AsString := LastName;
    ParamByName('MAIL').AsString := EMail;
  end;
  qry.ExecSQL;

  // Populate query: accounts, issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  accounts.account_id, first_name, last_name, email, coalesce(openissues,0) openissues, security');
    SQL.Add('     from  accounts');
    SQL.Add('             left outer join (  select  account_id, count(*) as openissues');
    SQL.Add('                                  from  issues');
    SQL.Add('                                 where  resolution <> "Closed"');
    SQL.Add('                              group by  account_id) as accountissues');
    SQL.Add('             on accounts.account_id = accountissues.account_id;');
  end;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.DeleteSurvey(SID: String; SurveyGroup: String; SurveyName: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to delete surveys
  if Copy(usr.Claims.Find('security').asString,2,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: DeleteSurvey');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'DeleteSurvey [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: surveys (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from surveys');
    SQL.Add('where survey_id = :SID;');
    ParamByName('SID').AsString := SID;
  end;
  qry.ExecSQL;

  // Populate query: permissions (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from permissions');
    SQL.Add('where survey_id = :SID;');
    ParamByName('SID').AsString := SID;
  end;
  qry.ExecSQL;

  // Populate query: changes (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from changes');
    SQL.Add('where survey_id = :SID;');
    ParamByName('SID').AsString := SID;
  end;
  qry.ExecSQL;

  // Populate query: notes (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from notes');
    SQL.Add('where survey_id = :SID;');
    ParamByName('SID').AsString := SID;
  end;
  qry.ExecSQL;

  // Populate query: questions (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from questions');
    SQL.Add('where survey_id = :SID;');
    ParamByName('SID').AsString := SID;
  end;
  qry.ExecSQL;

  // Populate query: responses (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from responses');
    SQL.Add('where survey_id = :SID;');
    ParamByName('SID').AsString := SID;
  end;
  qry.ExecSQL;

  // Populate query: surveys, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  surveys.survey_id, surveys.survey_name, survey_group, survey_link, permissions.permissions');
    SQL.Add('     from  surveys, permissions');
    SQL.Add('    where  surveys.survey_id = permissions.survey_id');
    SQL.Add('      and  permissions.account_id = :ACCOUNT');
    SQL.Add(' order by  surveys.survey_group, surveys.survey_name;');
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.DeleteSurveyNote(SID: String; NoteID: String; SurveyName: String; SurveyGroup: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'DeleteSurveyNote [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: notes (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete from notes');
    SQL.Add('where');
    SQL.Add('  survey_id = :SID');
    SQL.Add('  and note_id = :NID');
    SQL.Add(';');
    ParamByName('SID').AsString := SID;
    ParamByName('NID').AsString := NoteID;
  end;
  qry.ExecSQL;

  // Populate query: notes, accounts, surveys (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  notes.utc_stamp, notes.note_id, accounts.first_name, accounts.last_name, accounts.email, notes.note, surveys.survey_name, surveys.survey_group');
    SQL.Add('     from  notes');
    SQL.Add('             left outer join accounts');
    SQL.Add('               on  notes.account_id = accounts.account_id');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on  notes.survey_id = surveys.survey_id');
    SQL.Add('    where  notes.survey_id = :SURVEYID');
    SQL.Add(' order by  notes.utc_stamp desc;');
    ParamByName('SURVEYID').AsString := SID;
  end;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetAccounts: TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetAccounts');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetAccounts');

  // Populate query: accounts, issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  accounts.account_id, first_name, last_name, email, coalesce(openissues,0) openissues, security');
    SQL.Add('     from  accounts');
    SQL.Add('             left outer join (  select  account_id, count(*) as openissues');
    SQL.Add('                                  from  issues');
    SQL.Add('                                 where  resolution <> "Closed"');
    SQL.Add('                              group by  account_id) as accountissues');
    SQL.Add('             on accounts.account_id = accountissues.account_id;');
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetAllFeedback: TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetAllFeedback');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetAllIssues');

  // Populate query: accounts, issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  feedback.utc_stamp, feedback_id, feedback.survey_id, stage, feedback, resolution, activitylog_size, coalesce(survey_name, "Missing Name") survey_name, coalesce(survey_group,"Missing Group") survey_group');
    SQL.Add('     from  feedback');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on feedback.survey_id = surveys.survey_id;');
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);
end;

function TSurveyAdminService.GetAllIssues: TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetAllIssues');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetAllIssues');

  // Populate query: accounts, issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  issues.utc_stamp, issue_id, issues.survey_id, issues.account_id, category, issue, resolution, activitylog_size, first_name, last_name, email, survey_name, survey_group');
    SQL.Add('     from  issues');
    SQL.Add('             left outer join accounts');
    SQL.Add('               on issues.account_id = accounts.account_id');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on issues.survey_id = surveys.survey_id;');
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;


function TSurveyAdminService.GetAllResponses: TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

  Responses :TJSONArray;
  Response: TJSONObject;
  NewResponse: TJSONObject;

  SID,
  SName,
  SGroup,
  STime,
  SClient: String;

  Final: String;
  i: integer;
begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetAllResponses');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetAllResponses');

  // Populate query: responses, surveys (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  utc_stamp, responses.survey_id, client_id, response, survey_name, survey_group');
    SQL.Add('     from  responses');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on responses.survey_id = surveys.survey_id;');
  end;
  qry.Open;

  // Here, a set of responses is stored as a JSON object but what we'd really prefer is a JSON array with
  // a separate element for each individual response.  This would be trival in SQL if there was a record
  // for each separate response.  So here we're 'unpacking' the responses to get the same end result
  // This could also be done on the client.

  Responses := TJSONArray.Create;

  while not(qry.EOF) do
  begin
    SID := qry.FieldByName('survey_id').AsString;
    SGroup := qry.FieldByName('survey_group').AsString;
    SName := qry.FieldByName('survey_name').AsString;
    STime := qry.FieldByName('utc_stamp').AsString;
    SClient := qry.FieldByName('client_id').AsString;
    Response := TJSONObject.ParseJSONValue(qry.FieldByName('response').AsString) as TJSONObject;

    i := 0;
    while (i < Response.Count) do
    begin
      // Each record looks like this.  Repetitive? Certainly.  We also cheat a bit by having the client insert
      // the query name and survey name as part of the response so we don't have to go and look them up separately.

      NewResponse := TJSONObject.Create;
      NewResponse.AddPair('SurveyID',SID);
      NewResponse.AddPair('SurveyGroup',SGroup);
      NewResponse.AddPair('SurveyName',SName);
      NewResponse.AddPair('SurveyTime',STime);
      NewResponse.AddPair('SurveyClient',SClient);
      NewResponse.AddPair('Order', TJSONNumber.Create(i));
      NewResponse.AddPair('QuestionID', Copy(Response.Pairs[i].JSONString.Value, 1, Pos(':', Response.Pairs[i].JSONString.Value)-1));
      NewResponse.AddPair('QuestionName', Copy(Response.Pairs[i].JSONString.Value,Pos(':', Response.Pairs[i].JSONString.Value)+1,maxint));
      NewResponse.AddPair('Response', Response.Pairs[i].JSONValue.Value);
      Final := NewResponse.ToString;
      NewResponse.Free;

      // Managing memory here - NewResponse (TJSONObject) has to be treated carefully, so here we're converting it to a string and
      // then disposing of it, and then adding the string to the Response.  Haven't check whether this catches everything.

      Responses.Add(TJSONObject.ParseJSONValue(Final) as TJSONObject);
      i := i + 1;
    end;

    qry.Next;
    Response.Free;
  end;

  // Take the results and stream back to client
  Final := Responses.ToString;
  Result := TStringStream.Create(Final);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

  Responses.Free;

end;

function TSurveyAdminService.GetFeedbackActivityLog(FeedbackID: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');
  if not(usr.Claims.Exists('security')) then raise EXDataHttpUnauthorized.Create('Missing credentials');

  // Make sure this account has access to view history
  if Copy(usr.Claims.Find('security').asString,5,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetFeedbackActivityLog');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetFeedbackActivityLog');

  // Populate query: feedback (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  activitylog');
    SQL.Add('     from  feedback');
    SQL.Add('    where  feedback_id = :FID;');
    ParamByName('FID').AsString := FeedbackID;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetHistory(Days: Integer): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');
  if not(usr.Claims.Exists('security')) then raise EXDataHttpUnauthorized.Create('Missing credentials');

  // Make sure this account has access to view history
  if Copy(usr.Claims.Find('security').asString,5,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetHistory');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetHistory [ '+IntToStr(Days)+'d ]');

  // Populate query: history, accounts (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  utc_stamp, ipaddr, history.account_id, first_name, last_name, email, survey_id, endpoint, ');
    SQL.Add('           ROW_NUMBER () OVER ( ORDER BY utc_stamp desc ) ID');
    SQL.Add('     from  history left outer join accounts');
    SQL.Add('             on  history.account_id = accounts.account_id');
    SQL.Add('    where  utc_stamp > date("now","utc",:DAYS)');
    SQL.Add(' order by  utc_stamp desc;');
    ParamByName('DAYS').AsString := IntToStr(-Days)+' days';
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetIssueActivityLog(IssueID: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');
  if not(usr.Claims.Exists('security')) then raise EXDataHttpUnauthorized.Create('Missing credentials');

  // Make sure this account has access to view history
  if Copy(usr.Claims.Find('security').asString,5,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetIssueActivityLog');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetIssueActivityLog');

  // Populate query: issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  activitylog');
    SQL.Add('     from  issues');
    SQL.Add('    where  issue_id = :IID;');
    ParamByName('IID').AsString := IssueID;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetQuestions(SID: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

  Questions: String;
begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetQuestions');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'GetQuestions');

  // Populate query: questions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  question_list');
    SQL.Add('     from  questions');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;

  Questions := qry.FieldByName('question_list').AsString;
  if Questions = '' then Questions := '[]';

  // Return query as JSON stream
  Result := TStringStream.Create(Questions);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetSurveyByID(SID: String; SurveyName: String; SurveyGroup: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

  SurveyData: String;
begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetSurveyByID');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'GetSurveyByID [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: surveys, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  survey, permissions.permissions');
    SQL.Add('     from  surveys, permissions');
    SQL.Add('    where  surveys.survey_id = permissions.survey_id');
    SQL.Add('      and  surveys.survey_id = :SURVEYID;');
    SQL.Add('      and  permissions.account_id = :ACCOUNT;');
    ParamByName('SURVEYID').AsString := SID;
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
  end;
  qry.Open;

  SurveyData := qry.FieldByName('survey').AsString;
  if SurveyData = '' then SurveyData := '{}';

  // Return query as JSON stream
  Result := TStringStream.Create(SurveyData);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetSurveyChangeHistory(SID: String; SurveyName: String; SurveyGroup: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetSurveyChangeHistory');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'GetSurveyChangeHistory [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: changes, accounts, surveys (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  changes.utc_stamp, accounts.first_name, accounts.last_name, accounts.email, changes.change, surveys.survey_name, surveys.survey_group');
    SQL.Add('     from  changes');
    SQL.Add('             left outer join accounts');
    SQL.Add('               on  changes.account_id = accounts.account_id');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on  changes.survey_id = surveys.survey_id');
    SQL.Add('    where  changes.survey_id = :SURVEYID');
    SQL.Add(' order by  changes.utc_stamp desc;');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetSurveyInfo(SID: String; SurveyName: String; SurveyGroup: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

  SurveyInfo: TStringList;
  SurveySize: Int64;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetSurveyInfo');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'GetSurveyInfo [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Going to be generating a set of data to be returned, adding pieces to a list as we go
  SurveyInfo := TStringList.Create;

  // Populate query: surveys (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  survey_name, survey_group, survey');
    SQL.Add('     from  surveys');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveySize := Length(qry.FieldByName('survey').asString);

  // Populate query: changes (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  min(utc_stamp) created, max(utc_stamp) updated, count(*) numchanges');
    SQL.Add('     from  changes');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;

  // Manually construct JSON to be returned
  SurveyInfo.Add('{"ID":"1","KEY":"Survey First Created","VALUE":"'+FormatDateTime('yyyy-MMM-dd (ddd) HH:nn:ss', qry.FieldByName('created').AsDateTime)+'"},');
  SurveyInfo.Add('{"ID":"2","KEY":"Survey Last Updated","VALUE":"'+FormatDateTime('yyyy-MMM-dd (ddd) HH:nn:ss', qry.FieldByName('updated').AsDateTime)+'"},');
  SurveyInfo.Add('{"ID":"3","KEY":"Number of Updates","VALUE":"'+qry.FieldByName('numchanges').AsString+'"},');
  SurveyInfo.Add('{"ID":"4","KEY":"Survey Size (Bytes)","VALUE":"'+IntToStr(SurveySize)+'"},');

  // Populate query: history (select)
  // Exclude Development IPs
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(distinct ipaddr) num');
    SQL.Add('     from  history');
    SQL.Add('    where  survey_id = :SURVEYID');
    SQL.Add('      and  (endpoint like "GetSurvey [%")');
    SQL.Add('      and  not(ipaddr in ("::1","127.0.0.1","174.7.120.10"))');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"5","KEY":"Unique Visitors (By IP)","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: history (select)
  // Exclude Development IPs
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(distinct account_id) num');
    SQL.Add('     from  history');
    SQL.Add('    where  survey_id = :SURVEYID');
    SQL.Add('      and  (endpoint like "GetSurvey [%")');
    SQL.Add('      and  not(ipaddr in ("::1","127.0.0.1","174.7.120.10"))');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"6","KEY":"Unique Visitors (By ID)","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: questions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(*) num');
    SQL.Add('     from  questions');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"7","KEY":"Question Count","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: responses (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(*) num');
    SQL.Add('     from  responses');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"8","KEY":"Response Count","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: feedback (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(*) num');
    SQL.Add('     from  feedback');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"9","KEY":"Feedback Count","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(*) num');
    SQL.Add('     from  issues');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"10","KEY":"Issue Count","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(*) num');
    SQL.Add('     from  permissions');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"11","KEY":"Adminstrators","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: notes (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(*) num');
    SQL.Add('     from  notes');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;
  SurveyInfo.Add('{"ID":"12","KEY":"Notes","VALUE":"'+qry.FieldByName('num').AsString+'"},');

  // Populate query: changes (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  count(*) num');
    SQL.Add('     from  changes');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;

  SurveyInfo.Add('{"ID":"13","KEY":"Changes","VALUE":"'+qry.FieldByName('num').AsString+'"}');

  // Return query as JSON stream
  Result := TStringStream.Create('['+SurveyInfo.Text+']');

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetSurveyNotes(SID: String; SurveyName: String; SurveyGroup: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetSurveyNotes');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'GetSurveyNotes [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: notes, accounts, surveys (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  notes.utc_stamp, notes.note_id, accounts.first_name, accounts.last_name, accounts.email, notes.note, surveys.survey_name, surveys.survey_group');
    SQL.Add('     from  notes');
    SQL.Add('             left outer join accounts');
    SQL.Add('               on  notes.account_id = accounts.account_id');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on  notes.survey_id = surveys.survey_id');
    SQL.Add('    where  notes.survey_id = :SURVEYID');
    SQL.Add(' order by  notes.utc_stamp desc;');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;


function TSurveyAdminService.GetSurveyPermissions(SID, SurveyName, SurveyGroup: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetSurveyPermissions');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'GetSurveyPermissions [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: accounts, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  accounts.account_id, first_name, last_name, email, perms.permissions, case when perms.permissions is null then false else true end access');
    SQL.Add('     from  accounts');
    SQL.Add('             left outer join ( select  account_id, permissions');
    SQL.Add('                                 from  permissions');
    SQL.Add('                                where  permissions.survey_id = :SID ) perms');
    SQL.Add('               on accounts.account_id = perms.account_id;');
    ParamByName('SID').AsString := SID;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.GetSurveys: TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: GetSurveys');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'GetSurveys');

  // Populate query: surveys, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  surveys.survey_id, surveys.survey_name, survey_group, survey_link, permissions.permissions');
    SQL.Add('     from  surveys, permissions');
    SQL.Add('    where  surveys.survey_id = permissions.survey_id');
    SQL.Add('      and  permissions.account_id = :ACCOUNT');
    SQL.Add(' order by  surveys.survey_group, surveys.survey_name;');
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.Login(Email, Password: string): string;
var
  fdc: TFDConnection;
  qry: TFDQuery;

  JWT: TJWT;
  sha2: TSHA2Hash;
  password_hash: String;
  account: String;

begin

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Populate query: accounts (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  password_hash,account_id, first_name, last_name, security');
    SQL.Add('     from  accounts');
    SQL.Add('    where  email=:EMAIL;');
    ParamByName('EMAIL').AsString := EMail;
  end;
  qry.Open;

  if (qry.RecordCount = 1) then
  begin

    // We've got a valid account, to start with
    account := qry.FieldByName('account_id').asString;

    // Get SHA-256 hash of password supplied by the user
    sha2 := TSHA2Hash.Create;
    sha2.HashSizeBits := 256;
    sha2.OutputFormat := hexa;
    sha2.Unicode := noUni;
    password_hash := sha2.Hash(Password);
    sha2.Free;

    // Check if it matches the hash stored in the database
    if (qry.FieldByName('password_hash').AsString = password_hash) then
    begin
      // It does! So create a JWT
      JWT := TJWT.Create;
      try
        // Setup some Claims
        JWT.Claims.Issuer := 'XData Survey Server';
        JWT.Claims.IssuedAt := Now;
        JWT.Claims.Expiration := Now + 1;
        JWT.Claims.SetClaimOfType<string>( 'email', EMail );
        JWT.Claims.SetClaimOfType<string>( 'account', account );
        JWT.Claims.SetClaimOfType<string>( 'security', qry.FieldByName('security').asString );
        JWT.Claims.SetClaimOfType<string>( 'first', qry.FieldByName('first_name').asString );
        JWT.Claims.SetClaimOfType<string>( 'last', qry.FieldByName('last_name').asString );
        JWT.Claims.SetClaimOfType<string>( 'issued', FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now));

        // Generate the actual JWT
        Result := 'Bearer '+TJOSE.SHA256CompactToken(ServerContainer.XDataServerJWT.Secret, JWT);

        // Record what we're up to
        Support.LogHistory(qry, account, '', 'Login [ Successful ]');

      finally
        JWT.Free;
      end;
    end
    else
    begin
      // Passwords didn't match
      Result := 'Incorrect E-Mail / Password';

      // Record what we're up to
      Support.LogHistory(qry, account, '', 'Login [ Failed: Password ]');

      // Send this back
      raise EXDataHttpUnauthorized.Create('Incorrect E-Mail / Password');

    end;
  end
  else
  begin
    // Account not found
    // Lots of good reasons to NOT distinguish this error from an incorrect
    // password error but the option is here either way.
    Result := 'Incorrect E-Mail / Password';

    // Record what we're up to
    Support.LogHistory(qry, EMail, '', 'Login [ Failed: Account ]');

    // Send this back
    raise EXDataHttpUnauthorized.Create('Incorrect E-Mail / Password')
  end;

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.NewAccount(AccountID, FirstName, LastName, EMail, Password, Security: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;

  qry: TFDQuery;
  sha2: TSHA2Hash;
  password_hash: String;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, AccountID, 'NewAccount [ '+FirstName+' '+LastName+' ]');

  // Create password hash
  sha2 := TSHA2Hash.Create;
  sha2.HashSizeBits := 256;
  sha2.OutputFormat := hexa;
  sha2.Unicode := noUni;
  password_hash := sha2.Hash(Password);
  sha2.Free;

  // Populate query: accounts (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into accounts');
    SQL.Add('  (account_id, first_name, last_name, email, password_hash, security)');
    SQL.Add('values(');
    SQL.Add('  :AID,');
    SQL.Add('  :FNAME,');
    SQL.Add('  :LNAME,');
    SQL.Add('  :MAIL,');
    SQL.Add('  :PASS,');
    SQL.Add('  :KEYS');
    SQL.Add(');');
    ParamByName('AID').AsString := AccountID;
    ParamByName('FNAME').AsString := FirstName;
    ParamByName('LNAME').AsString := LastName;
    ParamByName('MAIL').AsString := EMail;
    ParamByName('PASS').AsString := password_hash;
    ParamByName('KEYS').AsString := Security;
  end;
  qry.ExecSQL;

  // Populate query: accounts, issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  accounts.account_id, first_name, last_name, email, coalesce(openissues,0) openissues, security');
    SQL.Add('     from  accounts');
    SQL.Add('             left outer join (  select  account_id, count(*) as openissues');
    SQL.Add('                                  from  issues');
    SQL.Add('                                 where  resolution <> "Closed"');
    SQL.Add('                              group by  account_id) as accountissues');
    SQL.Add('             on accounts.account_id = accountissues.account_id;');
  end;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.NewSurvey(SID, SName, SGroup, SLink: String; SData: String; Change: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;
begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'NewSurvey [ '+SGROUP+' ]');

  // Populate query: surveys (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into surveys');
    SQL.Add('  (survey_id, survey_name, survey_group, survey_link, survey)');
    SQL.Add('values(');
    SQL.Add('  :SID,');
    SQL.Add('  :SNAME,');
    SQL.Add('  :SGROUP,');
    SQL.Add('  :SLINK,');
    SQL.Add('  :SDATA');
    SQL.Add(');');
    ParamByName('SID').AsString := SID;
    ParamByName('SNAME').AsString := SName;
    ParamByName('SGROUP').AsString := SGroup;
    ParamByName('SLINK').AsString := SLink;
    ParamByName('SDATA').AsString := SData;
  end;
  qry.ExecSQL;

  // Populate query: permissions (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into permissions');
    SQL.Add('  (survey_id, account_id, permissions)');
    SQL.Add('values(');
    SQL.Add('  :SID,');
    SQL.Add('  :ACCOUNT,');
    SQL.Add('  :PERMISSIONS');
    SQL.Add(');');
    ParamByName('SID').AsString := SID;
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
    ParamByName('PERMISSIONS').AsString := 'YYYYY';
  end;
  qry.ExecSQL;

  // Populate query: changes (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into changes');
    SQL.Add('  (survey_id, account_id, ipaddr, utc_stamp, change)');
    SQL.Add('values(');
    SQL.Add('  :SID,');
    SQL.Add('  :ACCOUNT,');
    SQL.Add('  :IPADDR,');
    SQL.Add('  current_timestamp,');
    SQL.Add('  :CHANGE');
    SQL.Add(');');
    ParamByName('SID').AsString := SID;
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
    ParamByName('IPADDR').AsString := TXDataOperationContext.Current.Request.RemoteIP;
    ParamByName('CHANGE').AsString := Change;
  end;
  qry.ExecSQL;

  // Populate query: surveys, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  surveys.survey_id, surveys.survey_name, survey_group, survey_link, permissions.permissions');
    SQL.Add('     from  surveys, permissions');
    SQL.Add('    where  surveys.survey_id = permissions.survey_id');
    SQL.Add('      and  permissions.account_id = :ACCOUNT');
    SQL.Add(' order by  surveys.survey_group, surveys.survey_name;');
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.ReportIssue(SID, IssueID, Issue, Category, SurveyName, SurveyGroup: String; ActivityLog: String; ActivityLogSize: Integer): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

  response: String;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'ReportIssue [ '+Category+' ]');

  // Populate query: issues (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into issues');
    SQL.Add('  (utc_stamp, survey_id, account_id, issue_id, issue, category, resolution, activitylog, activitylog_size)');
    SQL.Add('values(');
    SQL.Add('  CURRENT_TIMESTAMP,');
    SQL.Add('  :SID,');
    SQL.Add('  :ACCOUNT,');
    SQL.Add('  :IID,');
    SQL.Add('  :ANISSUE,');
    SQL.Add('  :ACATEGORY,');
    SQL.Add('  "New",');
    SQL.Add('  :ALOG,');
    SQL.Add('  :ALOGSIZE');
    SQL.Add(');');
    ParamByName('SID').AsString := SID;
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
    ParamByName('IID').AsString := IssueID;
    ParamByName('ANISSUE').AsString := Issue;
    ParamByName('ACATEGORY').AsString := Category;
    ParamByName('ALOG').AsString := ActivityLog;
    ParamByName('ALOGSIZE').AsInteger := ActivityLogSize;
  end;
  qry.ExecSQL;

  // Return query as JSON stream
  Response := '{"Reply":"Issue Accepted. Thank you."}';
  Result := TStringStream.Create(Response);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.SetIssueStatus(IssueID, Status: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to update surveys
  if Copy(usr.Claims.Find('security').asString,3,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: SetIssueStatus');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, IssueID, 'SetIssueStatus [ '+Status+' ]');

  // Populate query: issues (update)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('update issues');
    SQL.Add('  set');
    SQL.Add('    resolution = :STAT');
    SQL.Add('where');
    SQL.Add('  issue_id = :IID');
    ParamByName('IID').AsString := IssueID;
    ParamByName('STAT').AsString := Status;
  end;
  qry.ExecSQL;

  // Populate query: issues, accounts, surveys (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  issues.utc_stamp, issue_id, issues.survey_id, issues.account_id, category, issue, resolution, activitylog_size, first_name, last_name, email, survey_name, survey_group');
    SQL.Add('     from  issues');
    SQL.Add('             left outer join accounts');
    SQL.Add('               on issues.account_id = accounts.account_id');
    SQL.Add('             left outer join surveys');
    SQL.Add('               on issues.survey_id = surveys.survey_id;');
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.SetPassword(AccountID, FirstName, LastName,
  EMail, Password: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

  sha2: TSHA2Hash;
  password_hash: String;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to update surveys
  if Copy(usr.Claims.Find('security').asString,3,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: SetPassword');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'SetPassword [ '+FirstName+' '+LastName+' ]');

  // Get SHA-256 hash of password
  sha2 := TSHA2Hash.Create;
  sha2.HashSizeBits := 256;
  sha2.OutputFormat := hexa;
  sha2.Unicode := noUni;
  password_hash := sha2.Hash(Password);
  sha2.Free;

  // Populate query: accounts (update)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('update accounts');
    SQL.Add('  set');
    SQL.Add('    password_hash = :PASS');
    SQL.Add('where');
    SQL.Add('  account_id = :AID');
    SQL.Add('  and first_name = :FNAME');
    SQL.Add('  and last_name = :LNAME');
    SQL.Add('  and email = :MAIL;');
    ParamByName('PASS').AsString := password_hash;
    ParamByName('AID').AsString := AccountID;
    ParamByName('FNAME').AsString := FirstName;
    ParamByName('LNAME').AsString := LastName;
    ParamByName('MAIL').AsString := EMail;
  end;
  qry.ExecSQL;

  // Populate query: accounts, issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  accounts.account_id, first_name, last_name, email, coalesce(openissues,0) openissues, security');
    SQL.Add('     from  accounts');
    SQL.Add('             left outer join (  select  account_id, count(*) as openissues');
    SQL.Add('                                  from  issues');
    SQL.Add('                                 where  resolution <> "Closed"');
    SQL.Add('                              group by  account_id) as accountissues');
    SQL.Add('             on accounts.account_id = accountissues.account_id;');
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.SetQuestions(SID, Questions: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

  NewQuestions: String;
begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: SetQuestions');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
//  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'SetQuestions');

  // Populate query: questions (update)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   update  questions');
    SQL.Add('      set  question_list = :QLIST');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
    ParamByName('QLIST').AsString := Questions;
  end;
  qry.ExecSQL;

  if qry.rowsAffected = 0 then
  begin
    // Populate query: questions (insert)
    with qry do
    begin
      SQL.Clear;
      SQL.Add('insert into questions');
      SQL.Add('  (survey_id, question_list)');
      SQL.Add('values (');
      SQL.Add(' :SURVEYID,');
      SQL.Add(' :QLIST');
      SQL.Add(');');
      ParamByName('SURVEYID').AsString := SID;
      ParamByName('QLIST').AsString := Questions;
    end;
    qry.ExecSQL;
  end;

  // Populate query: questions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  question_list');
    SQL.Add('     from  questions');
    SQL.Add('    where  survey_id = :SURVEYID');
    ParamByName('SURVEYID').AsString := SID;
  end;
  qry.Open;

  NewQuestions := qry.FieldByName('question_list').AsString;
  if NewQuestions = '' then NewQuestions := '[]';

  // Return query as JSON stream
  Result := TStringStream.Create(NewQuestions);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.SetSurveyPermissions(SID, SurveyName, SurveyGroup, AccountID, FirstName, LastName, Permissions: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to view surveys
  if Copy(usr.Claims.Find('security').asString,1,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: SetSurveyPermissions');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'SetSurveyPermissions [ '+SurveyGroup+'/'+SurveyName+': '+FirstName+' '+LastName+' ]');

  // Populate query: permissions (delete)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('delete  from permissions');
    SQL.Add(' where  survey_id = :SID');
    SQL.Add('   and  account_id = :AID;');
    ParamByName('SID').AsString := SID;
    ParamByName('AID').AsString := AccountID;
  end;
  qry.ExecSQL;

  // Insert record only if they have at least some permissions
  if Permissions <> 'NNNNN' then
  begin
    // Populate query: permissions (insert)
    with qry do
    begin
      SQL.Clear;
      SQL.Add('insert into permissions');
      SQL.Add('  (survey_id, account_id, permissions)');
      SQL.Add('values (');
      SQL.Add('   :SID,');
      SQL.Add('   :AID,');
      SQL.Add('   :PERMS');
      SQL.Add(');');
      ParamByName('SID').AsString := SID;
      ParamByName('AID').AsString := AccountID;
      ParamByName('PERMS').AsString := Permissions;
    end;
    qry.ExecSQL;
  end;

  // Populate query: accounts, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  accounts.account_id, first_name, last_name, email, perms.permissions, case when perms.permissions is null then false else true end access');
    SQL.Add('     from  accounts');
    SQL.Add('             left outer join ( select  account_id, permissions');
    SQL.Add('                                 from  permissions');
    SQL.Add('                                where  permissions.survey_id = :SID ) perms');
    SQL.Add('               on accounts.account_id = perms.account_id;');
    ParamByName('SID').AsString := SID;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.UpdateAccount(AccountID, FirstName, LastName, EMail: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;

begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to update surveys
  if Copy(usr.Claims.Find('security').asString,3,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: UpdateAccount');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, '', 'UpdateAccount [ '+FirstName+' '+LastName+' ]');

  // Populate query: accounts (update)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('update accounts');
    SQL.Add('  set');
    SQL.Add('    first_name = :FNAME,');
    SQL.Add('    last_name = :LNAME,');
    SQL.Add('    email = :MAIL');
    SQL.Add('where account_id = :AID;');
    ParamByName('AID').AsString := AccountID;
    ParamByName('FNAME').AsString := FirstName;
    ParamByName('LNAME').AsString := LastName;
    ParamByName('MAIL').AsString := EMail;
  end;
  qry.ExecSQL;

  // Populate query: accounts, issues (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  accounts.account_id, first_name, last_name, email, coalesce(openissues,0) openissues, security');
    SQL.Add('     from  accounts');
    SQL.Add('             left outer join (  select  account_id, count(*) as openissues');
    SQL.Add('                                  from  issues');
    SQL.Add('                                 where  resolution <> "Closed"');
    SQL.Add('                              group by  account_id) as accountissues');
    SQL.Add('             on accounts.account_id = accountissues.account_id;');
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

function TSurveyAdminService.UpdateSurvey(SID, SurveyGroup, SurveyName, SurveyLink: String; SurveyData: String; Changes: String): TStream;
var
  usr: IUserIdentity;
  fdc: TFDConnection;
  qry: TFDQuery;
begin

  // Got a usable JWT?
  usr := TXDataOperationContext.Current.Request.User;
  if (usr = nil) then raise EXDataHttpUnauthorized.Create('Failed authentication');
  if not(usr.Claims.Exists('account')) then raise EXDataHttpUnauthorized.Create('Missing account');

  // Make sure this account has access to update surveys
  if Copy(usr.Claims.Find('security').asString,3,1) <> 'W' then raise EXDataHttpUnauthorized.Create('Not Authorized: UpdateSurvey');

  // CRITICAL TODO: Check that the account has appropriate privileges for this operation

  // Returning JSON
  TXDataOperationContext.Current.Response.Headers.SetValue('content-type', 'application/json');
  Result := TMemoryStream.Create;

  // Create a query
  Support.ConnectQuery(fdc, qry);

  // Record what we're up to
  Support.LogHistory(qry, usr.Claims.Find('account').AsString, SID, 'UpdateSurvey [ '+SurveyGroup+'/'+SurveyName+' ]');

  // Populate query: surveys (update)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('update surveys');
    SQL.Add('  set');
    SQL.Add('    survey_name = :SNAME,');
    SQL.Add('    survey_group = :SGROUP,');
    SQL.Add('    survey_link = :SLINK,');
    SQL.Add('    survey = :SDATA');
    SQL.Add('where survey_id = :SID;');
    ParamByName('SID').AsString := SID;
    ParamByName('SNAME').AsString := SurveyName;
    ParamByName('SGROUP').AsString := SurveyGroup;
    ParamByName('SLINK').AsString := SurveyLink;
    ParamByName('SDATA').AsString := SurveyData;
  end;
  qry.ExecSQL;

  // Populate query: changes (insert)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('insert into changes');
    SQL.Add('  (survey_id, account_id, ipaddr, utc_stamp, change)');
    SQL.Add('values(');
    SQL.Add('  :SID,');
    SQL.Add('  :ACCOUNT,');
    SQL.Add('  :IPADDR,');
    SQL.Add('  current_timestamp,');
    SQL.Add('  :CHANGE');
    SQL.Add(');');
    ParamByName('SID').AsString := SID;
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
    ParamByName('IPADDR').AsString := TXDataOperationContext.Current.Request.RemoteIP;
    ParamByName('CHANGE').AsString := Changes;
  end;
  qry.ExecSQL;

  // Populate query: surveys, permissions (select)
  with qry do
  begin
    SQL.Clear;
    SQL.Add('   select  surveys.survey_id, surveys.survey_name, survey_group, survey_link, permissions.permissions');
    SQL.Add('     from  surveys, permissions');
    SQL.Add('    where  surveys.survey_id = permissions.survey_id');
    SQL.Add('      and  permissions.account_id = :ACCOUNT');
    SQL.Add(' order by  surveys.survey_group, surveys.survey_name;');
    ParamByName('ACCOUNT').AsString := usr.Claims.Find('account').AsString;
  end;
  qry.Open;

  // Return query as JSON stream
  Support.FireDACtoSimpleJSON(qry, Result);

  // Cleanup What We Created
  Support.CleanupQuery(fdc, qry);

end;

initialization
  RegisterServiceType(TSurveyAdminService);

end.
