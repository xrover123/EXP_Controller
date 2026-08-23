program ExpManager;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Main},
  RunProgram in 'RunProgram.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
