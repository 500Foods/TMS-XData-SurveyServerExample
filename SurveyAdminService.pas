unit SurveyAdminService;

interface

uses
  System.Classes,
  XData.Security.Attributes,
  XData.Service.Common;

type
  [ServiceContract]
  ISurveyAdminService = interface(IInvokable)
    ['{18375DB7-2E25-4688-B286-270FA7417C89}']

    // The default is [HttpPost]

    function Login(Email: string; Password: string; ClientVersion: string; ClientRelease: string):string;

    [Authorize] function GetSurveys: TStream;
    [Authorize] function GetSurveyByID(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    [Authorize] function GetSurveyInfo(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    [Authorize] function GetSurveyChangeHistory(SID: String; SurveyName: String; SurveyGroup: String): TStream;

    [Authorize] function NewSurvey(SID: String; SName: String; SGroup: String; SLink: String; SData: String; Change: String): TStream;
    [Authorize] function UpdateSurvey(SID: String; SurveyGroup: String; SurveyName: String; SurveyLink: String; SurveyData: String; Changes: String): TStream;
    [Authorize] function DeleteSurvey(SID: String; SurveyGroup: String; SurveyName: String): TStream;

    [Authorize] function GetQuestions(SID: String): TStream;
    [Authorize] function SetQuestions(SID: String; Questions: String): TStream;

    [Authorize] function GetSurveyNotes(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    [Authorize] function AddSurveyNote(SID: String; NoteID: String; Note: String; SurveyName: String; SurveyGroup: String): TStream;
    [Authorize] function DeleteSurveyNote(SID: String; NoteID: String; SurveyName: String; SurveyGroup: String): TStream;

    [Authorize] function GetSurveyPermissions(SID: String; SurveyName: String; SurveyGroup: String): TStream;
    [Authorize] function SetSurveyPermissions(SID: String; SurveyName: String; SurveyGroup: String; AccountID: String; FirstName: String; LastName: String; Permissions: String): TStream;

    [Authorize] function GetAccounts: TStream;
    [Authorize] function UpdateAccount(AccountID: String; FirstName: String; LastName: String; EMail: String): TStream;
    [Authorize] function NewAccount(AccountID: String; FirstName: String; LastName: String; EMail: String; Password: String; Security: String): TStream;
    [Authorize] function DeleteAccount(AccountID: String; FirstName: String; LastName: String; EMail: String): TStream;
    [Authorize] function SetPassword(AccountID: String; FirstName: String; LastName: String; EMail: String; Password: String): TStream;

    [Authorize] function ReportIssue(SID: String; IssueID: String; Issue: String; Category: String; SurveyName: String; SurveyGroup: String; ActivityLog: String; ActivityLogSize: Integer): TStream;
    [Authorize] function GetAllIssues: TStream;
    [Authorize] function SetIssueStatus(IssueID: String; Status: String): TStream;
    [Authorize] function GetIssueActivityLog(IssueID: String): TStream;

    [Authorize] function GetAllFeedback: TStream;
    [Authorize] function GetFeedbackActivityLog(FeedbackID: String): TStream;

    [Authorize] function GetAllResponses: TStream;

    [Authorize] function GetHistory(Days: Integer): TStream;
    [Authorize] function GetHistoryRange(Start: String; Finish:String): TStream;

  end;

implementation

initialization
  RegisterServiceType(TypeInfo(ISurveyAdminService));

end.
