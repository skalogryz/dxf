program testscratchfile;

{$mode objfpc}{$H+}

uses
  Classes, dxftypes, dxfclasses, dxfwriteutils, dxffileutils;

var
  f : TDxfFile;
begin
  f := TDxfFile.Create;
  try
    AddDefaultBlocks(f);
    NormalizeBlocks(f);
    AddDefaultClasses(f);

    WriteFileAscii('output.dxf', f);
  finally
    f.Free;
  end;
end.

