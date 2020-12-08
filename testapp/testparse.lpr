program testparse;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils, Classes, dxftypes, dxfparse, dxfparseutils;

procedure DumpBlock(const bl: TDxfBlock);
begin
  writeln('block started: ', bl.Ent.Handle,' ',bl.BlockName,' ',bl.BlockName2,' [',bl.Descr,']; Owner: ', bl.Ent.Owner);
end;

procedure ParseInputFile(const fn: string);
var
  f : TFileStream;
  p : TDxfParser;
  ln,ofs: integer;
  mem : TMemoryStream;
  inBlock: Boolean;
  bl  : TDxfBlock;
begin
  inBlock := false;
  mem := TMemoryStream.Create;
  try
    f := TFileStream.Create(fn, fmOpenRead or fmShareDenyNone);
    try
      mem.CopyFrom(f, f.size);
      mem.Position := 0;
    finally
      f.Free;
    end;
  except
    Exit;
  end;
  p := TDxfParser.Create;
  try
    p.scanner := DxfAllocScanner(mem, true);
    while p.Next <> prError do begin
      if p.token = prEof then Break;

      p.scanner.GetLocationInfo(ln, ofs);
      if p.token = prSecStart then begin
        writeln('start section ', p.secName,' at ', ln,'/',ofs);
      end else if p.token = prBlockStart then begin
        //writeln('block start! at ', ln,'/',ofs);
        ParseBlock(p, bl);
        DumpBlock(bl);
        inBlock := true;
      end else if p.token = prBlockEnd then begin
        writeln('block end ',' at ', ln,'/',ofs);
        inBlock := false;
      end;

      //if inBlock and (p.Token<>prBlockStart) then begin
      //  writeln('   >',p.token,' ',p.scanner.CodeGroup, ' ',p.Scanner.DataType,' ', p.scanner.ValStr);
      //end;

      if p.token = prUnknown then begin
        writeln('value: ', p.scanner.CodeGroup,' ', DxfValAsStr(p.scanner));
        p.scanner.GetLocationInfo(ln, ofs);
        writeln(p.scanner.ClassName);
        if (ln<=0) then writeln('offset: ', INtToHex(ofs, 8))
        else writeln('line: ', ln, ' col: ', ofs);
        Break;
      end;
    end;
    if p.token = prError then
      writeln('err: ', p.ErrStr);

  finally
    p.Free;
  end;
end;

var
  tm : QWord;
begin
  if ParamCount=0 then begin
    writeln('please specify .dxf file');
    Exit;
  end;
  tm := GetTickCount64;
  ParseInputFile(ParamStr(1));
  tm := QWord(GetTickCount64 - tm);
  writeln('tm: ', tm);
end.

