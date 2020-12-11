program testreadwritefile;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, dxfwrite, dxfclasses, dxftypes, dxfparseutils;

procedure TestReadWrite(const fn: string);
var
  f: TDxfFile;
begin
  f:=TDxfFile.Create;
  try
    ReadFile(fn, f);
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

