program testclasses;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, dxftypes, dxfparse, dxfclasses
  { you can add units after this };

begin
end.

