unit Unit1;

interface

uses
   Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ADODB, DBXpress, FMTBcd, SqlExpr, ExtCtrls,
  ComCtrls;

const VERSION = '3.0';

const IniFileName = 'exchange.ini';

type
  TMain = class(TForm)
    Label1: TLabel;
    ORAConnection: TSQLConnection;
    OraProc: TSQLStoredProc;
    V: TSQLQuery;
    PB: TProgressBar;
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SaveLogFile(S: String);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    Regime: byte;
    F_PATH: String;
    PropList: TStringList;
    Timer1: TTimer;
    bERR: boolean;
    LogFile: String;
    dCloseTime: TDateTime;
    bCloseTime: boolean;
    ErrorCount,MaxErrorCount: integer;
    sAnswer: String;

  public
    { Public declarations }
  end;

var
  Main: TMain;
  hMutexProg: THandle;

function IsSingleInstance(const AddMutex: String): Boolean;//Проверка единичного запуска

implementation

{$R *.dfm}
uses IniFiles, {EasyCript,} NetConf, FileFunc, RunProgram, crypt;

const LR:char=chr(10);

{
function GetPC: word; stdcall;
  external 'NetParam.dll' name 'GetPCCode';
}

function IsSingleInstance(const AddMutex: String): Boolean;//Проверка единичного запуска
const
  MutexPref = 'Global\Apsida-EXP_Controller';
var
  MutexName: String; // уникальное имя мьютекса

begin
  if AddMutex='' then
    MutexName := MutexPref
    else
    MutexName:=MutexPref+'('+AddMutex+')';
  // Пытаемся создать мьютекс. Если он уже есть — GetLastError вернёт ERROR_ALREADY_EXISTS
  hMutexProg := CreateMutex(nil, False, PChar(MutexName));

  if hMutexProg = 0 then
    raise Exception.Create('Не удалось создать мьютекс');

  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    // Мьютекс уже существует — значит, другой экземпляр запущен
    CloseHandle(hMutexProg);
    Result := False;
  end
  else
  begin
    // Мьютекса не было — мы его создали, значит, других экземпляров нет
    Result := True;
    // Не закрываем hMutex: пока процесс жив, мьютекс будет держать блокировку.
    // При завершении программы ОС сама его освободит.
  end;
end;

procedure TMain.FormShow(Sender: TObject);
var INI: TINIFile;
    S,FN,LOG,EXP_STATR: String;
    i,j,t: integer;
    WAIT_INT,WAIT_TIME: cardinal;
    EXP_END: String;
    PSW: String;
    w: word;
    LF: TextFile;
    LogCnt:integer;
    bErr: boolean;
    sERR: String;
    sSQL: String;
    SS: TStringList;
    HH: integer;
    MM: integer;
    //SP: TSQLStoredProc;
const ord_0 = ord('0');
const ord_9 = ord('9');
procedure StopFileCrt;
  var F: File;
  begin
  AssignFile(F,EXP_END);
  Rewrite(F);
  CloseFile(F);
  end;
procedure OpenLog;
  begin
  AssignFile(LF,LogFile);
  if FileExists(LogFile) then
    Append(LF)
    else
    Rewrite(LF);
  WriteLn(LF,'begin EXCHANGE('+DateTimeToStr(now)+')');
  LogCnt:=0;
  CloseFile(LF);
  end;
procedure SaveLog;
  begin
  if FileExists(LogFile) then
    Append(LF)
    else
    Rewrite(LF);
  WriteLN(LF,LOG);
  setLength(LOG,0);
  CloseFile(LF);
  end;
procedure SetLog(const MSG,endChar: String);
  begin
  SaveLog;
  end;
procedure CloseLog;
  begin
  if (Regime>0) and (Regime<10) then
    begin
    if FileExists(LogFile) then
      Append(LF)
      else
      Rewrite(LF);
    WriteLn(LF,'end EXCHANGE('+DateTimeToStr(now)+')'+LR);
    try
    CloseFile(LF);
    finally;
    end;
    end;
  end;
procedure ShowException(MSG: String);
  begin
  if Regime>=10 then
    ShowMessage(MSG)
  else if Regime>0 then
    begin
    SetLog(MSG,'');
    CloseLog;
    end;
  end;
procedure CloseFromError(MSG: String);
  begin
  bERR:=True;
  ShowException(MSG);
  INI.Free;
  Close;
  end;
procedure PrintIniExample;
  var T: TextFile;
  begin
  if not FileExists(FN) then
    begin
    AssignFile(T,extractFilePath(ParamStr(0))+'SAMPLE.INI');
    Rewrite(T);
    writeLN(T,'[FILES]#Секция описания файлов импорта');
    writeLN(T,'  FILE1=<Файл>;<Процедура импорта строки>');
    writeLN(T,'  FILE2=<Файл>;<Процедура импорта строки>');
    writeLN(T,'[DB]');
    writeLN(T,'  DB_NAME=<Псевдоним БД>');
    writeLN(T,'  USER=<Пользователь>');
    writeLN(T,'  PSW=<Закодированный пароль (записать пароль можно с помошью утилиты psw <пароль>)>');
    writeLN(T,'  PREP_PROC=<Процедура перед импортом>');
    writeLN(T,'  SAVE_PROC=<Процедура после импорта>');
    writeLN(T,'[OTHERS]');
    writeLN(T,'  REGIME=<0 - все сообщения выводятся в LOG (если он задан); 10 - сообщения выводятся.>');
    writeLN(T,'  LOG=<Лог файл>');
    CloseFile(T);
    Close
    end;
  end;
begin
Caption:='File exchange manager '+VERSION;
bERR:=False;
MaxErrorCount:=10;
ErrorCount:=0;
if ParamCount=1 then
  if (ParamStr(1)='-V') or (UpperCase(ParamStr(1))='-v') then
    begin
    Label1.Caption:='Version '+VERSION;
    PB.Visible:=False;
    exit
    end;
Label1.Caption:='Диспечер файлового обмена.';//Application.ProcessMessages;
Main.Update;
FN := ExtractFilePath(ParamStr(0))+IniFileName;
if not FileExists(FN) then PrintIniExample;

try
INI:=TINIFile.Create(FN);


S := UpperCase(INI.ReadString('OTHERS','REGIME','0'));
if (S='0') or (S='SILENCE') or (S='SILENT') then
  begin
  FN:=trim(INI.ReadString('OTHERS','LOG',''));
  if FN[Length(FN)]='\' then
    FN:=FN+trim(INI.ReadString('OTHERS','COMMAND_LOG',''))
    else
    FN:=trim(INI.ReadString('OTHERS','COMMAND_LOG',FN));
  LogFile:=FN;
  if length(FN)>0 then
    begin
    OpenLog;
    Regime:=1;
    end
    else
    Regime:=0;
  end
else if (S='10') or (S='DEBUG') or (S='SHOW_MESSAGE') then
  Regime:=10;

FN:=trim(INI.ReadString('OTHERS','PERIOD',''));
if length(FN)=0 then
  bCloseTime:=False
  else
  begin
  for i:=1 to length(FN) do if FN[i]='+' then FN[i]:=',';
  SS := TStringList.Create;
  SS.CommaText:=FN;
  dCloseTime:=now();
  bCloseTime:=True;
  for i:=0 to SS.Count-1 do
    begin
    FN:=UpperCase(SS.Strings[i]);
    case FN[Length(FN)] of
      'D': dCloseTime:=dCloseTime+StrToInt(copy(FN,1,length(FN)-1));
      'H': dCloseTime:=dCloseTime+StrToInt(copy(FN,1,length(FN)-1))/(24);
      'M': dCloseTime:=dCloseTime+StrToInt(copy(FN,1,length(FN)-1))/(24*60);
      end;
    end;
  SS.Destroy;
  end;
FN:=trim(INI.ReadString('SHEDULER','EXP_END',''));
if length(FN)=0 then
  bCloseTime:=False
  else
  begin
  bCloseTime:=True;
  i := pos(':', FN);
  if (i > 0) and
     TryStrToInt(copy(FN, 1, i-1), HH) and
     TryStrToInt(copy(FN, i+1, length(FN) - i), MM) then
    dCloseTime := date + EncodeTime(HH, MM, 0, 0)
    else
    dCloseTime:=date+EncodeTime(23, 0, 0, 0);
  end;

{
try
  w := GetPC;//GetCriptCode;
  bErr:=False
  except on E: Exception do
    begin
    bErr:=True;
    sErr:=E.Message;
    end;
  end;

if bErr then
  if ParamCount>=2 then
    SetLog(sErr,LR)
    else
    begin
    CloseFromError('Процедура получения ключа выдала ошибку: '+sErr);
    exit
    end;
}
//DLM:=trim(INI.ReadString('FILE','DLM',','));
Label1.Caption:='Чтение файла инициализации.';//Application.ProcessMessages;
Main.Update;
ORAConnection.Params.Values['DataBase']:=INI.ReadString('DB','DB_NAME',ParamStr(1));
ORAConnection.Params.Values['User_Name']:=INI.ReadString('DB','USER',ParamStr(2));
if bErr then
  ORAConnection.Params.Values['Password'] := ParamStr(3)
  else
  begin
  PSW := INI.ReadString('DB','PSW','');
  try
    PSW := myCrypt(PSW,coDecrypt,litter,PswLen);
    except on E: Exception do
      begin
      CloseFromError('Процедура расшифровки выдала ошибку: '+E.Message);
      exit;
      end;
    end;
{  if PSW='' then
    PSW := ParamStr(3)
    else
    begin
    PSW := DecryptStr(PSW,w);
    j := length(PSW);
    t := j;
    for i := 1 to j do
      if PSW[i] = chr(10) then
        begin
        t:=i-1;
        break;
        end;
    if t<>j then SetLength(PSW,t);
    end;}
  ORAConnection.Params.Values['Password'] := PSW;
  end;
Label1.Caption:='Connect '+ORAConnection.Params.Values['User_Name']+'@'+ORAConnection.Params.Values['DataBase']+'.' ;//Application.ProcessMessages;
Main.Update;
try
  ORAConnection.Connected:=True
  except on E: Exception do
    begin
    CloseFromError
      (
      LR+'DBName='+ORAConnection.Params.Values['DataBase']+
      LR+'USER='+ORAConnection.Params.Values['User_Name']+
      //LR+'Password='+ORAConnection.Params.Values['Password']+
      LR+LR+E.Message
      );
    exit
    end;
  end;
if not ORAConnection.Connected then
  begin
  CloseFromError('База данных закрыта!');
  exit
  end
  else
  begin
  MaxErrorCount:=INI.ReadInteger('FILE','ERR_COUNT',10);
  PropList := TStringList.Create;
  F_PATH:=trim(INI.ReadString('FILE','EXE_FILE_PATH',ExtractFilePath(ParamStr(0))));
  Label1.Caption:='Connectted '+ORAConnection.Params.Values['User_Name']+'@'+ORAConnection.Params.Values['DataBase']+'.' ;//Application.ProcessMessages;
  Main.Update;
  OraProc.StoredProcName:=trim(INI.ReadString('DB','COMMAND_PROC',''));
  if OraProc.StoredProcName<>'' then
    begin
    //OraProc.ExecProc;
    OraProc.Params.Clear;
    OraProc.Params.CreateParam(ftVariant,'nRN',ptInput);
    with OraProc.Params.CreateParam(ftString,'sPARAMS',ptInput) do
      begin
      Size:=2000;
      end;
    OraProc.Prepared:=True;
    end;

  sSQL := trim(INI.ReadString('DB','COMMAND_VIEW',''));
  if sSQL='' then
    begin
    CloseFromError('Не задан запрос с коммандами.');
    exit
    end;
  V.SQL.Text:='select nRN,sCOMMAND,sPARAMS from '+sSQL;
  V.Active:=True;
  V.Active:=False;

  Label1.Caption:='Подключение к БД произошло удачно.';//Application.ProcessMessages;
  Main.Update;
  SetLog(Label1.Caption,LR);
  sAnswer := trim(INI.ReadString('FILE','ANSWER',ExtractFilePath(ParamStr(0))+'Answer.prm'));
  end;
//ORAConnection.Commit(TS);
Timer1:=TTimer.Create(self);
Timer1.Interval:=INI.ReadInteger('DB','CHECK_INTERVAL',1)*1000;
Timer1.OnTimer:=Timer1Timer;
Timer1.Enabled:=True;
INI.Free;
except on E:Exception do
  begin
  //ORAConnection.Rollback(TS);
  if (Regime>0) and (Regime<10) then
    begin
    CloseFromError(E.Message);
    exit
    end
  else if Regime>=10 then ShowMessage('Ошибка: ' + E.Message);
  if INI<>nil then
    begin
    INI.Free;
    Close;
    end;
  end;
end;
end;

procedure TMain.Timer1Timer(Sender: TObject);
var P, S, ERR: String;
    VR: Variant;
    bERR: boolean;
    SS: TStringList;
    sRN: String;
    i: integer;
procedure run(const sFileName: String; var sERR: String);
  var
  g:TStartupInfo;
  h:TProcessInformation;
  begin
  try
    if not RunEXEAndWait(sFileName,'',ExtractFilePath(sFileName)) then
      sERR:='Произошла ошибка при запуске exe-файла.';

    except on E: Exception do
      begin
      sERR:=E.Message;
      SaveLogFile('('+DateTimeToStr(now)+
                  ') Команда "RUN '+P+
                  '" закончилась с ошибкой:'+#10+
                  E.Message
                 );
      bERR:=True;
      end;
    end;
  end;
begin

i:=0;
bERR:=True;
while i<MaxErrorCount do
  try
    if V.Active then
      V.Refresh
      else
      V.Active:=True;
    bERR:=False;
    break;
    except
    try
      inc(i);
      ORAConnection.Connected := False;
      V.Active:=False;
      ORAConnection.Connected := True;
      except
      continue;
      end;
    end;
if bERR then
  begin
  SaveLogFile('end EXCHANGE('+DateTimeToStr(now)+') Сервис необходимо перезапустить.');
  Close;
  exit;
  end;

try
while not V.Eof do
  begin
  bERR:=False;
  if V.FieldByName('sCOMMAND').AsString = 'RUN' then
    begin
    S:=V.FieldByName('sPARAMS').AsString;
    PropList.Text:=S;
    P:=PropList.Values['EXE'];
    sRN:=V.FieldByName('nRN').AsString;
    if FileExists(sAnswer) then DeleteFile(sAnswer);

    //V.Active:=False;
    //ORAConnection.Connected:=False;

    run(F_PATH+P,ERR);

    //ORAConnection.Connected:=True;
    //V.Active:=True;

    SS:=TStringList.Create;
    if FileExists(sAnswer) then SS.LoadFromFile(sAnswer);

    try
      OraProc.Params.ParamByName('nRN').AsString:=sRN;
      if length(ERR)>0 then SS.Add('RUN_ERR='+ERR);
      OraProc.Params.ParamByName('sPARAMS').AsString:=SS.Text;
      OraProc.ExecProc;
      except on E: Exception do
        begin
        bERR:=True;
        SaveLogFile('('+DateTimeToStr(now)+') Отсылка ответа на запрос "RUN" не удалась!'+#10+E.Message);
        end;
      end;

    SS.Free;

    if not bERR then SaveLogFile('('+DateTimeToStr(now)+') RUN '+P);
    //continue;
    end
    else if V.FieldByName('sCOMMAND').AsString = 'CHECK' then
      begin
      try
        OraProc.Params.ParamByName('nRN').AsString:=V.FieldByName('nRN').AsString;
        OraProc.Params.ParamByName('sPARAMS').AsString:='CHECK=TRUE';
        OraProc.ExecProc;
        SaveLogFile('('+DateTimeToStr(now)+') CHECK');
        except on E: Exception do
          begin
          bERR:=True;
          SaveLogFile('('+DateTimeToStr(now)+') Отсылка ответа на запрос "CHECK" не удалась!'+#10+E.Message);
          end;
        end;
      end;
    if bERR then
      if ErrorCount>MaxErrorCount then
        begin
        SaveLogFile('('+DateTimeToStr(now)+') Превышено максимальное число ошибок ('+IntToStr(MaxErrorCount)+').');
        SaveLogFile('end EXCHANGE('+DateTimeToStr(now)+') Сервис необходимо перезапустить.');
        Close;
        exit
        end
        else
        inc(ErrorCount);

    V.Next;
    end;
//V.Active:=False;
if PB.Position=PB.Max then
  PB.Position:=0
  else
  PB.Position:=PB.Position+1;
if bCloseTime then
  if now()>=dCloseTime then
    Close;

except on E: Exception do
  begin
  SaveLogFile('('+DateTimeToStr(now)+') '+E.Message);
  end;
end;
end;

procedure TMain.SaveLogFile(S: String);
var
  LF: TextFile;
begin
  AssignFile(LF,LogFile);
  if FileExists(LogFile) then
    Append(LF)
    else
    Rewrite(LF);
  WriteLn(LF,S+LR);
  CloseFile(LF);
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
if PB.Visible then
  if not bERR then
    begin
    SaveLogFile('end EXCHANGE('+DateTimeToStr(now)+')');
    end;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
if hMutexProg <> 0 then
  begin
    CloseHandle(hMutexProg);
    hMutexProg := 0;
  end;
end;

end.
