program testclasses;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, dxftypes, dxfparse, dxfclasses
  { you can add units after this };

var
  dxf : TDxfFile;
begin
  if ParamCount=0 then begin
    writeln('please specify file .dxf');
    Exit;
  end;
  dxf := TDxfFile.Create;
  try
    DxfLoadFromFile(ParamStr(1), dxf);
    DxfFileDump(dxf);
  finally
    dxf.Free;
  end;
end.

