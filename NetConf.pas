unit NetConf;

interface
uses Classes;
const
  MAX_ADAPTER_NAME_LENGTH = 256;
  MAX_ADAPTER_DESCRIPTION_LENGTH = 128;
  MAX_ADAPTER_ADDRESS_LENGTH = 8;

  ERROR_BUFFER_OVERFLOW = 111;
  ERROR_INVALID_PARAMETER = 87;
  ERROR_NO_DATA = 232;
  ERROR_NOT_SUPPORTED = 50;
  ERROR_SUCCESS = 0;

var ERROR_STATUS: byte;

type
  TMacAddress = array[0..5] of byte; // MAC address

  TIPAddressString = array[0..15] of char;
  PIPAddrString = ^TIPAddrString;
  TIPAddrString = record
    Next: PIPAddrString;
    IPAddress: TIPAddressString;
    IPNetMask: TIPAddressString;
    Context: integer;
  end;
  PIPAdapterInfo = ^TIPAdapterInfo;
  TIPAdapterInfo = record
    Next: PIPAdapterInfo;
    ComboIndex: integer;
    AdapterName: array[0..MAX_ADAPTER_NAME_LENGTH + 3] of char; 
    Description: array[0..MAX_ADAPTER_DESCRIPTION_LENGTH + 3] of char;
    AddressLength: integer;
    Address: TMacAddress; //array[1..MAX_ADAPTER_ADDRESS_LENGTH] of byte;
    Index: integer;
    _Type: integer;
    DHCPEnabled: integer;
    CurrentIPAddress: PIPAddrString;
    IPAddressList: TIPAddrString;
    GatewayList: TIPAddrString;
    DHCPServer: TIPAddrString;
    HaveWINS: LongBool;
    PrimaryWINSServer: TIPAddrString;
    SecondaryWINSServer: TIPAddrString;
    LeaseObtained: integer;
    LeaseExpires: integer;
  end;

procedure GetNICDeviceInfo(var Alist: TStringList);
function GetCriptCode: word;

implementation

{-------------------------------------------------------------------------------
  Procedure: MacToStr
  Author:    Mass
  DateTime:  2009.09.28
  Arguments: AMac: TMacAddress; ADelimiter: Char = '-'
  Result:    string
  Purpose:   Преобразование структуры MAC-адреса в строку
-------------------------------------------------------------------------------}

function MacToStr(AMac: TMacAddress; ADelimiter: Char = '-'): string;
var
  ch1, ch2: Byte;
  i: Integer;
begin
  Result := '';
  for i := 0 to Length(AMac) - 1 do
  begin
    ch1 := AMac[i] and $F0;
    ch1 := ch1 shr 4;
    if ch1 > 9 then
      ch1 := ch1 + Ord('A') - 10
    else
      ch1 := ch1 + Ord('0');
    ch2 := AMac[i] and $0F;
    if ch2 > 9 then
      ch2 := ch2 + Ord('A') - 10
    else
      ch2 := ch2 + Ord('0');
    Result := Result + Chr(ch1) + Chr(ch2);
    if i < 5 then
      Result := Result + ADelimiter;
  end;
end;

{-------------------------------------------------------------------------------
  Procedure: GetAdaptersInfo
  Author:    Mass
  DateTime:  2009.09.28
  Arguments: AdapterInfo: PIPAdapterInfo; var BufLen: integer
  Result:    integer
  Purpose:   Считать системные параметры всех сетевых адаптеров компьютера
-------------------------------------------------------------------------------}

function GetAdaptersInfo(AdapterInfo: PIPAdapterInfo; 
  var BufLen: integer): integer; stdcall; 
  external 'iphlpapi.dll' name 'GetAdaptersInfo';

{-------------------------------------------------------------------------------
  Procedure: GetNICDeviceInfo
  Author:    Mass
  DateTime:  2009.09.28
  Arguments: var Alist: TStringList
  Result:    None
  Purpose:   Считать параметры (IP, MAC) всех сетевых адаптеров компьютера
-------------------------------------------------------------------------------}

procedure GetNICDeviceInfo(var Alist: TStringList);
var
  adapterInfo: PIPAdapterInfo;
  size, res: integer;
  ip, mac: string;
begin
  size := 5120;
  GetMem(adapterInfo, size);
  res := GetAdaptersInfo(adapterInfo, size);

  if (res <> ERROR_SUCCESS) then
  begin
    SetLastError(res);
    ERROR_STATUS:=1;
  end;
  while adapterInfo <> nil do
  begin
    ip := adapterInfo^.IPAddressList.IPAddress;
    mac := MacToStr(adapterInfo^.Address);
    if (Length(ip) > 0) and (Length(mac) > 0) then
      Alist.Add(ip+'='+mac); //, adapterInfo^.AddressLength
    adapterInfo := adapterInfo^.Next;
  end;
  adapterInfo := nil;
  FreeMem(adapterInfo);
  ERROR_STATUS:=0;
end;

function MyStrToInt(S:String):integer;
const V = '0123456789ABCDEF';
      R = 16;
var i,x,d: integer;
begin
d:=R;
x:=pos(S[length(S)],V)-1;
for i:=length(S)-1 downto 1 do
  begin
  x:=x+(pos(S[i],V)-1)*d;
  d:=d*R;
  end;
result:=x;
end;
{
function GetCriptCode: word;
var i: integer;
    IpMacList: TStringList;
    IP,MAC: String;
    w,curr: word;
begin
  IpMacList := TStringList.Create;
  GetNICDeviceInfo(IpMacList);
  result := 0;
  for i := IpMacList.Count - 1 downto 0 do
    begin
    IP := IpMacList.Names[i];
    if IP<>'0.0.0.0' then
      begin
      MAC := IpMacList.ValueFromIndex[i];
      if MAC<>'00-00-00-00-00-00' then
        begin
        result := MyStrToInt(MAC);
        break;
        end;
      end;
    end;
}
function GetCriptCode: word;
var i: integer;
    IpMacList: TStringList;
    IP,MAC: AnsiString;
    w,curr: word;
    adapterInfo: PIPAdapterInfo;
    size, res: integer;
begin

  size := 5120;
  GetMem(adapterInfo, size);
  res := GetAdaptersInfo(adapterInfo, size);

  if (res <> ERROR_SUCCESS) then
  begin
    SetLastError(res);
    ERROR_STATUS:=1;
  end;
  while adapterInfo <> nil do
  begin
    ip := adapterInfo^.IPAddressList.IPAddress;
    mac := MacToStr(adapterInfo^.Address);
    if (Length(ip) > 0) and (Length(mac) > 0) then
      begin

      if IP<>'0.0.0.0' then
        begin
        if MAC<>'00-00-00-00-00-00' then
          begin
          result := MyStrToInt(MAC);
          break;
          end;
        end;

      end;
    adapterInfo := adapterInfo^.Next;
  end;
  FreeMem(adapterInfo);
  adapterInfo := nil;
end;

end.
