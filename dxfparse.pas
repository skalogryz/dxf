unit dxfparse;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dxftypes;

{
NOTE: Accommodating DXF files from future releases of AutoCAD®  will be easier
      if you write your DXF processing program in a table-driven way, ignore undefined
      group codes, and make no assumptions about the order of group codes in an
      entity. With each new AutoCAD release, new group codes will be added to entities
      to accommodate additional features.
}

type
  TDxfScanResult = (scError, scValue, scEof);

  TDxfScanner = class(TObject)
  public
    function Next: TDxfScanResult; virtual; abstract;
  end;

  { TDxfAsciiScanner }

  TDxfAsciiScanner = class(TDxfScanner)
  private
    lineStart : integer;
    function GetLineOfs: Integer;
  public
    buf    : string;
    idx    : integer;

    lineNum  : integer;

    codegroup : Integer;
    value     : string;
    errStr    : string;
    function Next: TDxfScanResult; override;
    procedure SetBuf(const astr: string);
    function ValueAsInt(const def: integer = 0): Integer;
    function ValueAsDouble(const def: double = 0): double;
    property LineOfs: Integer read GetLineOfs;
  end;

  { TDxfBinaryScanner }

  TDxfBinaryScanner = class(TDxfScanner)
  public
    src: TStream;
    codegroup : Integer;
    value     : string;
    datatype  : TDxfType;
    intVal    : Integer;
    intVal64  : Int64;
    flVal     : double;
    isEof     : Boolean;
    function Next: TDxfScanResult; override;
  end;

function ConsumeCodeBlock(p : TDxfAsciiScanner; expCode: Integer; var value: string): Boolean;


type
  TDxfParseResult = (
    prUnknown,   //unrecognized structure
    prError,
    prEof,
    prSecStart,
    prSecEnd,
    prClassStart,
    prClassAttr,
    prTableStart,
    prTableAttr,
    prVarName,
    prVarValue,
    prComment
  );

  { TDxfParser }

  TDxfParser = class(TObject)
  protected
    mode : integer;
    inSec: integer;
    function ParseHeader(t: TDxfAsciiScanner): TDxfParseResult;
  public
    scanner: TDxfAsciiScanner;
    secName: string;
    varName: string;
    tableName: string;
    handle : string;
    ErrStr : string;
    function Next: TDxfParseResult;
  end;

implementation

const
  LBChars = [#10,#13];
  Digits  = ['0'..'9'];
  Signs   = ['-','+'];
  SignDigits = Digits + Signs;

function SkipLineBreak(const s: string; var idx: integer): Boolean;
var
  inich : Char;
  sec   : Char;
begin
  if (idx < 0) or (idx>length(s)) then begin
    Result := true;
    Exit;
  end;

  Result := false;
  inich := s[idx];
  if (inich <> #10) and (inich<>#13) then Exit;

  Result := true;
  inc(idx);
  if (idx>length(s)) then Exit;

  sec := s[idx];
  if ((sec <> #10) and (sec<>#13)) or (sec = inich) then Exit;

  inc(idx);
end;

{ TDxfBinaryScanner }

function ReadNullChar(src: TStream): string;
var
  buf : string;
  i   : integer;
  b   : byte;
begin
  SetLength(buf, 32);
  i:=1;
  while true do begin
    b := src.ReadByte;
    if b = 0 then break;
    if i>length(buf) then
      SetLength(buf, length(buf) * 2);
    buf[i]:=char(b);
    inc(i);
  end;
  SetLength(buf, i-1);
  Result:=buf;
end;

function TDxfBinaryScanner.Next: TDxfScanResult;
begin
  value := '';
  intVal := 0;
  intVal64 := 0;

  if isEof then begin
    Result := scEof;
    Exit;
  end;

  Result := scValue;
  codegroup := src.ReadWord;
  datatype := DxfDataType(codegroup);
  case datatype of
    dtStr2049, dtStr255, dtStrHex:
    begin
      value := ReadNullChar(src);
      if (length(value)=3) and (value[1]='E')
        and (value[2]='O') and (value[3]='F') then
        isEof := true;
    end;
    dtBoolean: begin
      intVal := src.ReadByte;
      intVal64 := intVal;
    end;
    dtInt16: begin
      intVal := Int16(src.ReadWord);
      intVal64 := intVal;
    end;
    dtInt32: begin
      intVal := Int32(src.ReadDWord);
      intVal64 := intVal;
    end;
    dtDouble:
      src.Read(flVal, sizeof(flVal));
  end;
end;

{ TDxfAsciiScanner }

function TDxfAsciiScanner.GetLineOfs: Integer;
begin
  Result:=idx - lineStart;
end;

function TDxfAsciiScanner.Next: TDxfScanResult;
var
  i   : integer;
  err : integer;
begin

  if (idx>length(buf)) then begin
    Result:=scEof;
    Exit;
  end;
  while (idx<=length(buf)) and not (buf[idx] in SignDigits) do inc(idx);
  i := idx;
  if (idx<=length(buf)) and (buf[idx] in Signs) then inc(idx);
  while (idx<=length(buf)) and (buf[idx] in Digits) do inc(idx);
  Val(Copy(buf, i, idx-i), codegroup, err);
  if err<>0 then begin
    errStr := 'invalid block code format'; // integer expected
    Result := scError;
    Exit;
  end;
  while not (idx<=length(buf)) and (buf[idx] in LBChars) do inc(idx);

  if not SkipLineBreak(buf, idx) then begin
    errStr := 'expecting end of line'; // integer expected
    Result := scError;
    Exit;
  end;

  i:=idx;
  while (idx<=length(buf)) and not (buf[idx] in LBChars) do inc(idx);
  value := Copy(buf, i, idx-i);
  SkipLineBreak(buf, idx);

  Result := scValue;
end;

procedure TDxfAsciiScanner.SetBuf(const astr: string);
begin
  lineNum := 1;
  buf := astr;
  idx := 1;
end;

function TDxfAsciiScanner.ValueAsInt(const def: integer): Integer;
var
  err : integer;
begin
  Val(value, Result, err);
  if err <> 0 then Result := def;
end;

function TDxfAsciiScanner.ValueAsDouble(const def: double): double;
var
  err : integer;
begin
  Val(value, Result, err);
  if err <> 0 then Result := def;
end;

function ConsumeCodeBlock(p : TDxfAsciiScanner; expCode: Integer; var value: string): Boolean;
begin
  Result := Assigned(p);
  if not Result then Exit;
  Result := p.Next = scValue;
  if not Result then Exit;
  Result := p.codegroup = expCode;
  if Result then Value := p.value;
end;

function TDxfParser.ParseHeader(t: TDxfAsciiScanner): TDxfParseResult;
begin
  if (t.codegroup = CB_VARNAME) then begin
    varName := t.value;
    Result := prVarName
  end else if (varName<>'') then
    Result := prVarValue;
end;

function TDxfParser.Next: TDxfParseResult;
var
  //mode    : integer; // 0 - core, 1 - header
  t     : TDxfAsciiScanner;
  res   : TDxfScanResult;

  procedure SetError(const msg: string);
  begin
    ErrStr := msg;
    Result := prError;
  end;

const
  MODE_ROOT    = 0;
  MODE_HEADER  = 1;
  MODE_CLASSES = 2;
  MODE_TABLES  = 3;
begin
  if not Assigned(scanner) then begin
    SetError('no scanner');
    Exit;
  end;
  Result := prUnknown;

  t := scanner;
  res := t.Next;

  if res = scError then begin
    SetError('scanner error: '+t.errStr);
    Exit;
  end else if res = scEof then begin
    Result := prEof;
    Exit;
  end;

  if (t.codegroup = 0) then begin
    if (t.value = 'EOFN') then begin
      t.Next;
      Result := prEof;
      Exit; // end of file
    end else if (t.value ='SECTION') then begin
      if inSec>0 then begin
        SetError('nested section is not allowed');
        Exit;
      end;
      if not ConsumeCodeBlock(t, CB_SECNAME, secName) then begin
        SetError('expected section name');
        Exit;
      end;
      Result := prSecStart;

      if secName = 'HEADER' then mode := MODE_HEADER
      else if secName = 'CLASSES' then mode := MODE_CLASSES
      else if secName = 'TABLES' then mode := MODE_TABLES;
      inc(inSec);

    end else if (t.value ='ENDSEC') then begin
      dec(inSec);
      if inSec<0 then begin
        SetError( 'unexpected end of section');
        Exit;
      end;

      if mode = MODE_HEADER then varName := '';

      secName := '';
      mode := 0;

      Result := prSecEnd;
    end else if (t.value = 'CLASS') and (mode = MODE_CLASSES) then begin
      Result := prClassStart;
    end else if (t.value = 'TABLE') and (mode = MODE_TABLES) then begin
      Result := prTableStart;
      tableName := '';
      handle := '';
    end;
  end else begin
    case mode of
      MODE_HEADER:
        Result := ParseHeader(t);
      MODE_CLASSES:
        Result := prClassAttr; // it's always class attribute
      MODE_TABLES:
      begin
        case t.codegroup of
          CB_TABLE_NAME: tableName := t.value;
          CB_TABLE_HANDLE: Handle := t.value;
        end;
        Result := prTableAttr;
      end;
    else
      writelN('mode=',mode);
      //MODE_ROOT:
      //  SetError('unexpected code group');
    end;
  end;
end;

end.

