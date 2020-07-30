program readtest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils, Classes, dxfparse, dxfclasses, dxftypes
  { you can add units after this };

var
  dxf : TDxfFile;
  fs  : TFileStream;
  bs  : TDxfBinaryScanner;
begin
  if ParamCount=0 then begin
    writeln('please specify input file name');
    Exit;
  end;

  fs := TFileStream.Create(ParamStr(1), fmOpenRead);
  bs := TDxfBinaryScanner.Create;
  try
    fs.Position:=22;
    bs.src := fs;
    repeat
      bs.Next;
      writeln('codeGroup: ', bs.codegroup);
      case bs.datatype of
        dtUnknown:        writeln('unknown');
        dtInt16, dtInt32: writeln('  value: ', bs.intVal);
        dtInt64:          writeln('  value: ', bs.intVal64);
        dtStr2049, dtStr255, dtStrHex:
                          writeln('  value: ', bs.value);
        dtDouble:
                          writeln('  value: ', bs.flVal);
        dtBoolean:
                          writeln('  value: ', bs.intVal);
      end;
      //writeln('    value: ', bs.value);
    until not (bs.datatype in [
      dtDouble, dtBoolean,
      dtInt16, dtInt32, dtInt64,
      dtStr2049, dtStr255, dtStrHex]);
    writeln('offset: ', fs.Position,' ',IntToHex(fs.Position, 8));

(*

codeGroup: 100
  value: AcDbXrecord
codeGroup: 280  0x118
  value: 1
codeGroup: 310
  value: ⌂(
codeGroup: 0
  value:
codeGroup: 1
  value:
codeGroup: 198
unknown




000009E989: 00 4A 01 32 41 37 00 66 │ 00 7D 00 4A 01 32 41 37   J☺2A7 f } J☺2A7
              |     |                                     |
000009E999: 00 64 00 41 63 44 62 58 │ 72 65 63 6F 72 64 00 18   d AcDbXrecord ↑
              | i16 | 310 | strhex  |
000009E9A9: 01 01 00 36 01 7F 28 00 │ 00 00 00 01 00 00 C6 00  ☺☺ 6☺⌂(    ☺  Æ

000009E9B9: 00 00 01 00 08 00 00 00 │ 00 00 00 C6 00 00 00 00    ☺ ◘      Æ

*)

  finally
    fs.Free;
    bs.Free;
  end;
  {dxf := TDxfFile.Create;
  try
    LoadASCIIFromFile(ParamStr(1), dxf);


  finally
    dxf.Free;
  end;}
end.

