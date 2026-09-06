program ExpManager;

uses
  Forms, SysUtils,
  Unit1 in 'Unit1.pas' {Main},
  RunProgram in 'RunProgram.pas';

{$R *.res}

begin
  hMutexProg := 0;
  if (ParamCount<>1) or (UpperCase(ParamStr(1))<>'-V') then
    if not IsSingleInstance('') then Halt(1);
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
