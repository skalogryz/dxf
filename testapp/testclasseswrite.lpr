program testclasseswrite;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, dxfwrite, dxfclasses, dxfparse;

var
  dxf : TDxfFile;
  res : string;
begin
  if ParamCount=0 then begin
    writeln('please specify file name');
    Exit;
  end;
  dxf := TDxfFile.Create;
  try
    DxfLoadFromFile(ParamStr(1), dxf);
    res := DxfSaveToString(dxf);
    write(res);
  finally
    dxf.Free;
  end;
end.

