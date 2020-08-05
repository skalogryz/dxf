program testwrite;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, dxfwrite
  { you can add units after this };

var
  d : TStringStream;
  w : TDxfWriter;
begin
  d := TStringStream.Create;
  try
    w := TDxfAsciiWriter.Create;
    w.SetDest(d, false);
    w.WriteStr(0, 'SECTION');
    w.WriteStr(0, 'ENDSEC');
    w.WriteStr(0, 'EOF');

    writeln('output:');
    writeln(d.DataString);
  finally
    w.Free;
    d.Free;
  end;
end.

