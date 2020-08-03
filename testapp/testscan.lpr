program readtest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils, Classes, dxfparse, dxftypes
  { you can add units after this };

var
  fs  : TFileStream;
  bs  : TDxfScanner;
begin
  if ParamCount=0 then begin
    writeln('please specify input file name');
    Exit;
  end;
  fs := TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyNone);
  try
    bs := DxfAllocScanner(fs, false);
    try
      while bs.Next <> scEof do begin
        if bs.LastScan = scError then begin
          writeln('err: ', bs.ErrStr);
          Exit;
        end;
        case bs.datatype of
          dtUnknown:        writeln('unknown');
          dtInt16, dtInt32: writeln('  value: ', bs.ValInt);
          dtInt64:          writeln('  value: ', bs.ValInt64);
          dtStr2049, dtStr255, dtStrHex
          :
            writeln('  value: ', bs.ValStr);
          dtDouble:
            writeln('  value: ', bs.ValFloat);
          dtBoolean:
            writeln('  value: ', bs.ValInt);
          dtBin1:
            writeln('   value length: ', bs.ValBinLen);
        end;
      end;
    finally
      bs.Free;
    end;
  finally
    fs.Free;
  end;
end.

