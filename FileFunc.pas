unit FileFunc;

interface
function isTextOpen( var f: TextFile ) : boolean;
function isFileOpen( var f: File ) : boolean;
procedure ChangeExt(var FileName: String; const NewExt: String);

implementation
function isTextOpen( var f: TextFile ) : boolean;
begin
   with TTextRec(f) do
     Result := (Handle<>0) and (Mode<>fmClosed)
end;

function isFileOpen( var f: File ) : boolean;
begin
   with TFileRec(f) do
     Result := (Handle<>0) and (Mode<>fmClosed)
end;

procedure ChangeExt(var FileName: String; const NewExt: String);
var i,j,n,t: integer;
begin
j:=Length(FileName)+2;//j - начало расширения с учетом того, что файл без расширения
n:=Length(NewExt);
for i:=j-2 downto 1 do
  case FileName[i] of
    '.': begin j:=i+1;break;end;  //начало расширения сразу после точки
    '\': break;//начало расширения сразу после названия файла, но еще надо поставить точку
    end;
setLength(FileName,j+n-1);
FileName[j-1]:='.';//Точки может и не быть, если файл без расширения
for i:=j to j+n-1 do FileName[i]:=NewExt[i-j+1];
end;

end.
