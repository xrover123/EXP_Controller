unit crypt;

interface
type
  TCrOper = (coEncrypt, coDecrypt);
const
  litter: char = #10;
  PswLen: integer = 30;

function
  myCrypt(const psw: String; oper: TCrOper; Ch: char; ChCnt: integer): String;

implementation

uses SysUtils;

var
  Buf: Array[0..255] of AnsiChar;
const
  BufLen: integer = SizeOf(Buf);

procedure PCCode(out w:word); stdcall;
  external 'key.dll' name 'PCCode';
procedure psw_encrypt(code: word; InOutBuf: PAnsiChar; BufLen: Integer); stdcall;
  external 'crypt.dll' name 'psw_encrypt';
procedure psw_decrypt(code: word; InOutBuf: PAnsiChar; BufLen: Integer); stdcall;
  external 'crypt.dll' name 'psw_decrypt';

function easyCrypt(const psw: String; oper: TCrOper): String;
  var w: word;
begin
  PCCode(w);
  StrPCopy(Buf, psw);
  case oper of
    coEncrypt: psw_encrypt(w,Buf,BufLen);
    coDecrypt: psw_decrypt(w,Buf,BufLen);
    end;
  result:=Buf;
end;
function
  myCrypt(const psw: String; oper: TCrOper; Ch: char; ChCnt: integer): String;
  var S: String;
      i: integer;
begin
  case oper of
    coEncrypt:
      begin
      S := psw;
      i:=Length(S);
      if i < ChCnt then
        begin
        setLength(S, ChCnt);
        for i:=i+1 to ChCnt do S[i]:=Ch;
        end;
      result := easyCrypt(S,coEncrypt);
      end;
    coDecrypt:
      begin
      S := easyCrypt(psw,coDecrypt);
      i := pos(Ch, S);
      if i > 0 then setLength(S, i - 1);
      result := S;
      end;
    end;
end;
end.
