program ExpManager;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Main},
  RunProgram in 'RunProgram.pas';

{$R *.res}

begin
  hMutexProg := 0;
  if not IsSingleInstance('') then Halt(1);
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
