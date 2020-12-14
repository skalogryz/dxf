program testreadwritefile;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, dxfwrite, dxfclasses, dxftypes, dxfparseutils, dxfwriteutils;

procedure DumpEntities(const en: TList; const pfx: string );
var
  i : integer;
  e : TDxfEntity;
begin
  if not Assigned(en) or (en.Count=0) then Exit;
  for i := 0 to en.Count-1 do begin
    e := TDxfEntity(en[i]);
    write(pfx, e.EntityType);
    if e is TDxfInsert then
      write(' @',TDxfInsert(e).BlockName);
    writeln;
  end;
end;

procedure TestReadWrite(const fn: string);
var
  f  : TDxfFile;
  tm : LongWord;
begin
  f:=TDxfFile.Create;
  try
    tm:={%H-}GetTickCount;
    ReadFile(fn, f);
    tm:=GetTickCount-tm;
    writeln('read in ', tm, 'ms');
    DxfFileDump(f);

    tm:={%H-}GetTickCount;
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

