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

    AddDefaultTables(f);
    AddDefaultClasses(f);
    AddLine(f, Point(0,0), Point(10,20));
    AddDefaultObjects(f);

    FillHandles(f);
    LinksToHandles(f);

    WriteFileAscii('output.dxf', f);
  finally
    f.Free;
  end;
end.

