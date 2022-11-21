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

    function GetSurvey(SurveyLink, ClientID, ClientVersion, ClientRelease: String): TStream;
    function GetQuestions(SurveyID, ClientID, ClientVersion, ClientRelease: String): TStream;
    function SaveResponses(SurveyID, ClientID, clientVersion, ClientRlease, Responses, Question: String): TStream;
    function Feedback(SurveyID, ClientID, ClientVersion, ClientRelease, FeedbackID, Feedback, Stage, ActivityLog: String): TStream;

  end;

implementation

initialization
  RegisterServiceType(TypeInfo(ISurveyClientService));

end.
