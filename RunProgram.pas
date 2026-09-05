unit RunProgram;

interface
function RunEXEAndWait(const FilePath, Parameters, WorkingDir: string): Boolean;
implementation
uses Windows;
function RunEXEAndWait(const FilePath, Parameters, WorkingDir: string): Boolean;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  Result := False;

  // Инициализация структур
  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);

  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.wShowWindow := SW_SHOWNORMAL;

  // Запуск процесса
  if CreateProcess(
    nil,                        // Имя модуля (если nil, берётся из командной строки)
    PChar(FilePath + ' ' + Parameters), // Командная строка
    nil,                      // Атрибуты безопасности процесса
    nil,                      // Атрибуты безопасности потока
    False,                  // Наследование дескрипторов
    0,                      // Флаги создания
    nil,                    // Окружение (наследует от родителя)
    PChar(WorkingDir),      // Рабочая директория
    StartupInfo,            // Структура StartupInfo
    ProcessInfo             // Структура ProcessInformation
  ) then
  begin
    // Ожидание завершения процесса
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);

    // Получение кода возврата (опционально)
    // GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);

    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ProcessInfo.hProcess);
    Result := True;
  end;
end;

end.
 