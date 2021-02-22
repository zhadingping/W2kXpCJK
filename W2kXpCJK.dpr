program W2kXpCJK;

uses
  Vcl.Forms,
  W2kXpCJKUnit in 'W2kXpCJKUnit.pas' {MainFrm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
