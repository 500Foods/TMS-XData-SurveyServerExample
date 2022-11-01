program SurveyServer;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {ServerContainer: TDataModule},
  Unit2 in 'Unit2.pas' {MainForm},
  SurveyAdminService in 'SurveyAdminService.pas',
  SurveyAdminServiceImplementation in 'SurveyAdminServiceImplementation.pas',
  SurveyClientService in 'SurveyClientService.pas',
  SurveyClientServiceImplementation in 'SurveyClientServiceImplementation.pas',
  UnitSupport in 'UnitSupport.pas' {Support: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'XData Survey Server';
  Application.CreateForm(TServerContainer, ServerContainer);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSupport, Support);
  Application.Run;
end.
