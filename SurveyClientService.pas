unit SurveyClientService;

interface

uses
  System.Classes,
  XData.Service.Common;

type
  [ServiceContract]
  ISurveyClientService = interface(IInvokable)
    ['{95922108-B13F-48D8-8E1E-5077F0446F3A}']

    // The default is [HttpPost]
    // These do not need to be authorized

    function GetSurvey(SurveyLink: String; ClientID: String): TStream;
    function GetQuestions(SurveyID: String; ClientID: String): TStream;
    function SaveResponses(SurveyID: String; ClientID: String; Responses: String): TStream;
    function Feedback(ClientID: String; SID: String; FeedbackID: String; Feedback: String; Stage: String; SurveyName: String; SurveyGroup: String; ActivityLog: String; ActivityLogSize: Integer): TStream;

  end;

implementation

initialization
  RegisterServiceType(TypeInfo(ISurveyClientService));

end.
