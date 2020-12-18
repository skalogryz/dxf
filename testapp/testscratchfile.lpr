program testscratchfile;

{$mode objfpc}{$H+}

uses
  Classes, dxftypes, dxfclasses, dxfwriteutils, dxffileutils;

var
  f : TDxfFile;
begin
  f := TDxfFile.Create;
  try
    DefaultHeader(f.header);
    writeln('def blocks');
    AddDefaultBlocks(f);
    writeln('norm block');
    NormalizeBlocks(f);
    writeln('def table');
    AddDefaultTables(f);

    writeln('def classes');
    AddDefaultClasses(f);
    //AddLine(f, Point(0,0), Point(10,20));
    writeln('def objects');
    AddDefaultObjects(f);

    writeln('filling handles');
    FillHandles(f);
    writeln('linking handles');
    LinksToHandles(f);

    WriteFileAscii('output.dxf', f);
  finally
    f.Free;
  end;
end.

