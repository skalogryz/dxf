program testreadwritefile;

{$ifdef fpc}
{$mode delphi}{$H+}
{$WARN 5066 off : Symbol "$1" is deprecated: "$2"}
{$endif}

uses
  Classes, SysUtils, dxfwrite, dxfclasses, dxftypes, dxfparseutils, dxfwriteutils;

procedure TestReadWrite(const fn: string);
var
  f  : TDxfFile;
  tm : LongWord;
begin
  f:=TDxfFile.Create;
  try
    tm:=GetTickCount;
    ReadFile(fn, f);
    tm:=GetTickCount-tm;
    writeln('read in ', tm, 'ms');
    DxfFileDump(f);

    tm:=GetTickCount;
    WriteFileAscii(ChangeFileExt(fn, '.outdxf'), f);
    tm:=GetTickCount-tm;
    writeln('written in ', tm, 'ms');
  finally
    f.Free;
  end;
end;

var
  fn : string;
begin
  if ParamCount=0 then begin
    writeln('please specify input .dxf file');
    exit;
  end;
  fn := ParamStr(1);
  if not FileExists(fn) then begin
    writeln('file ',fn,' does not exist');
    Exit;
  end;

  TestReadWrite(fn);

end.

