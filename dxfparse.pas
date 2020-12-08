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

  { TDxfScanner }

  TDxfScanner = class(TObject)
  protected
    function DoNext(var errmsg: string): TDxfScanResult; virtual; abstract;
  public
    LastScan   : TDxfScanResult; // set by Next, result of DoNext
    DataType   : TDxfType;       // set by DoNext. Defaulted to dtUnknown. if DoNext() returns dtUnknown
                                 // but CodeGroup is set to a non-negative value, it tries to determine the actual type
    ErrStr     : string;         // the error set by Next, returned via errmsg of DoNext
    CodeGroup  : Integer;        // set by DoNext
    ValStr     : string;         // set by DoNext
    ValInt     : Int32;          // set by DoNext
    ValInt64   : Int64;          // set by DoNext
    ValBin     : array of byte;  // set by DoNext
    ValBinLen  : Integer;        // set by DoNext
    ValFloat   : Double;         // set by DoNext
    // Binds a source ot the scanner. if OWnStream, the Scanner will free source, if the scanner is freed
    procedure SetSource(ASource: TStream; OwnStream: Boolean); virtual; abstract;

    // reads the next pair in the
    function Next: TDxfScanResult;

    // Returns the information about the current position
    // LineNum <= 0, if reading is binary Offset value indicates the offset in the stream
    // LineNum >=1, the reading is text the line number is indicatd. Offset is zero
    procedure GetLocationInfo(out LineNum, Offset: Integer); virtual; abstract;
  end;

  { TDxfAsciiScanner }

  TDxfAsciiScanner = class(TDxfScanner)
  private
    fSrc      : TStream;
    fSrcOwn   : Boolean;
  protected
    function DoNext(var errmsg: string): TDxfScanResult; override;
    function PrepareValues: Boolean;
  public
    buf    : string;
    idx    : integer;
    lineNum  : integer;
    procedure SetSource(ASource: TStream; OwnStream: Boolean); override;
    destructor Destroy; override;
    procedure SetBuf(const astr: string);
    procedure GetLocationInfo(out ALineNum, AOffset: Integer); override;
  end;

  { TDxfBinaryScanner }

  // Parses the binary input Stream. Note thet the binary header
  // must skipped over, prior to calling SetSource
  TDxfBinaryScanner = class(TDxfScanner)
  protected
    function DoNext(var errmsg: string): TDxfScanResult; override;
  public
    src       : TStream;
    srcStart  : Int64;
    srcOwn    : Boolean;
    isEof     : Boolean;
    destructor Destroy; override;
    procedure SetSource(ASource: TStream; OwnStream: Boolean); override;
    procedure GetLocationInfo(out ALineNum, AOffset: Integer); override;
  end;

// tries to detect if stream is binary or not.
// note the Stream is read for the first 22-bytes to detect
// if it's binary or not.
function DxfisBinary(AStream: TStream): Boolean;

// Allocates the scanner according to the stream type. (SetSource method is called)
// for binary, the header is also skipped over
// The Stream must allow random-access, because it's first read using isBinary.
// after reading the position might be shifted back for ASCII reading
function DxfAllocScanner(AStream: TStream; OwnStream: boolean): TDxfScanner;

function DxfValAsStr(s: TDxfScanner): string;

function ConsumeCodeBlock(p : TDxfScanner; expCode: Integer; var value: string): Boolean;

type
  TDxfParseToken = (
    prUnknown,   //unrecognized entry in the file
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
    prBlockStart, // encountered 0/BLOCK
    prBlockAttr,  // still within block
    prEntityInBlock,
    prBlockEnd,   //
    prEntityAttr,
    prEntityStart,
    prObjAttr,
    prComment
  );

  { TDxfParser }

  TDxfParser = class(TObject)
  protected
    mode : integer;
    inSec: integer;
    function ParseRoot(t: TDxfScanner; var newmode: Integer): TDxfParseToken;
    function ParseHeader(t: TDxfScanner; var newmode: integer): TDxfParseToken;
    function ParseClasses(t: TDxfScanner; var newmode: integer): TDxfParseToken;
    function ParseTables(t: TDxfScanner; var newmode: integer): TDxfParseToken;
    function ParseBlocks(t: TDxfScanner; var newmode: integer): TDxfParseToken;
    function ParseEntities(t: TDxfScanner; var newmode: integer): TDxfParseToken;
    function DoNext: TDxfParseToken;
    procedure SetError(const msg: string);
  public
    token     : TDxfParseToken;
    scanner   : TDxfScanner;
    secName   : string;
    varName   : string;
    tableName : string;
    tableHandle  : string;
    handle       : string;
    Comment      : string;
    ErrStr       : string;

    BlockHandle  : string;
    EntityType   : string; // entity type
    EntityHandle : string;
    function Next: TDxfParseToken;
  end;

const
  INVALID_CODEGROUP = $10000; // the code group max is $FFFF. Int16

const
  MODE_ROOT     = 0;
  MODE_HEADER   = 1;
  MODE_CLASSES  = 2;
  MODE_TABLES   = 3;
  MODE_BLOCKS   = 4;
  MODE_ENTITIES = 5;
  MODE_OBJECTS  = 6;
  MODE_ENTITIESINBLOCK = 7;

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

{ TDxfScanner }

function TDxfScanner.Next: TDxfScanResult;
begin
  ValStr := '';
  ValInt := 0;
  ValInt64 := 0;
  ValBinLen := 0;
  ValFloat := 0;
  CodeGroup := INVALID_CODEGROUP;
  DataType := dtUnknown;
  ErrStr := '';
  try
    LastScan := DoNext(ErrStr);
  except
    on E: Exception do begin
      LastScan := scError;
      ErrStr := E.Message;
    end
  end;
  Result := LastScan;
end;

destructor TDxfBinaryScanner.Destroy;
begin
  if srcOwn then src.Free;
  inherited Destroy;
end;

procedure TDxfBinaryScanner.SetSource(ASource: TStream; OwnStream: Boolean);
begin
  if not Assigned(ASource) then Exit;
  src := ASource;
  srcStart := src.Position;
  srcOwn := OwnStream;
end;

procedure TDxfBinaryScanner.GetLocationInfo(out ALineNum, AOffset: Integer);
begin
  ALineNum := 0;
  if Assigned(src) then
    AOffset := src.Position - srcStart
  else
    AOffset := 0;
end;

function TDxfBinaryScanner.DoNext(var errmsg: string): TDxfScanResult;
var
  sz : integer;
begin
  if isEof or (src.Position>=src.Size) then begin
    Result := scEof;
    Exit;
  end;

  Result := scValue;
  codegroup := src.ReadWord;
  datatype := DxfDataType(codegroup);
  case datatype of
    dtBin1: begin
      sz := src.ReadByte;
      SetLength(ValBin, sz);
      src.Read(ValBin[0], sz);
    end;
    dtStr2049, dtStr255, dtStrHex:
    begin
      ValStr := ReadNullChar(src);
      if (length(ValStr)=3) and (ValStr[1]='E')
        and (ValStr[2]='O') and (ValStr[3]='F') then
        isEof := true;
    end;
    dtBoolean: begin
      ValInt := src.ReadByte;
    end;
    dtInt16: begin
      ValInt := Int16(src.ReadWord);
    end;
    dtInt32: begin
      ValInt := Int32(src.ReadDWord);
    end;
    dtDouble:
      src.Read(ValFloat, sizeof(ValFloat));
  end;
end;

{ TDxfAsciiScanner }

procedure TDxfAsciiScanner.SetSource(ASource: TStream; OwnStream: Boolean);
var
  sz : Int64;
  s  : string;
begin
  if not Assigned(ASource) then Exit;
  fSrc := ASource;
  fSrcOwn := OwnStream;
  SetLength(s, fSrc.Size-fSrc.Position);
  if length(s)>0 then fSrc.Read(s[1], length(s));
  SetBuf(s);
end;

destructor TDxfAsciiScanner.Destroy;
begin
  if fSrcOwn then fSrc.Free;
  inherited Destroy;
end;

function TDxfAsciiScanner.DoNext(var errmsg: string): TDxfScanResult;
var
  i   : integer;
  err : integer;
begin

  if (idx>length(buf)) then begin
    Result:=scEof;
    Exit;
  end;
  while (idx<=length(buf)) and not (buf[idx] in SignDigits) do begin
    if buf[idx] in LBChars then begin
      SkipLineBreak(buf, idx);
      inc(lineNum);
    end else
      inc(idx);
  end;
  i := idx;
  if (idx<=length(buf)) and (buf[idx] in Signs) then inc(idx);

  while (idx<=length(buf)) and (buf[idx] in Digits) do inc(idx);
  Val(Copy(buf, i, idx-i), codegroup, err);
  if err<>0 then begin
    errmsg := 'invalid block code format'; // integer expected
    Result := scError;
    Exit;
  end;
  while not (idx<=length(buf)) and (buf[idx] in LBChars) do inc(idx);

  if not SkipLineBreak(buf, idx) then begin
    errmsg := 'expecting end of line'; // integer expected
    Result := scError;
    Exit;
  end;
  inc(LineNum);

  i:=idx;
  while (idx<=length(buf)) and not (buf[idx] in LBChars) do inc(idx);
  ValStr := Copy(buf, i, idx-i);

  PrepareValues;

  Result := scValue;
end;

function TDxfAsciiScanner.PrepareValues: Boolean;
var
  err : integer;
begin
  Result := true;
  DataType := DxfDataType(CodeGroup);
  case DataType of
    dtInt16, dtInt32, dtBoolean:  begin
      Val(ValStr, ValInt, err);
      Result := err = 0;
      ValInt64 := ValInt;
    end;
    dtInt64: begin
      Val(ValStr, ValInt64, err);
      Result := err = 0;
    end;
    dtDouble: begin
      Val(ValStr, ValFloat, err);
      Result := err = 0;
    end;
    dtBin1:
    begin
      if ValStr = '' then
        ValBinLen := 0
      else begin
        ValBinLen :=length(valStr) div 2;
        if length(valBin) < valBinLen then
          SetLength(valBin, valBinLen);
        HexToBin(@ValStr[1], @valBin[0], valBinLen);
      end;
    end;
  end;
end;

procedure TDxfAsciiScanner.SetBuf(const astr: string);
begin
  lineNum := 1;
  buf := astr;
  idx := 1;
end;

procedure TDxfAsciiScanner.GetLocationInfo(out ALineNum, AOffset: Integer);
begin
  ALineNum := lineNum;
  AOffset := 0;
end;

function ConsumeCodeBlock(p : TDxfScanner; expCode: Integer; var value: string): Boolean;
begin
  Result := Assigned(p);
  if not Result then Exit;
  Result := p.Next = scValue;
  if not Result then Exit;
  Result := p.codegroup = expCode;
  if Result then Value := p.ValStr;
end;

function TDxfParser.ParseRoot(t: TDxfScanner; var newmode: Integer): TDxfParseToken;
begin
  if (t.codegroup = 0) then begin
    if (t.ValStr = NAME_EOF) then begin
      t.Next;
      Result := prEof;
      Exit; // end of file
    end else if (t.valStr = NAME_SECTION) then begin
      if inSec>0 then begin
        SetError('nested section is not allowed');
        Result := prError;
        Exit;
      end;
      if not ConsumeCodeBlock(t, CB_SECTION_NAME, secName) then begin
        SetError('expected section name');
        Result := prError;
        Exit;
      end;
      Result := prSecStart;

      if secName = NAME_HEADER then newmode := MODE_HEADER
      else if secName = NAME_CLASSES then newmode := MODE_CLASSES
      else if secName = NAME_TABLES then newmode := MODE_TABLES
      else if secName = NAME_BLOCKS then newmode := MODE_BLOCKS
      else if secName = NAME_ENTITIES then newMode := MODE_ENTITIES
      else if secName = NAME_OBJECTS then newMode := MODE_OBJECTS;

    end else if (t.valStr=NAME_ENDSEC) then begin

      if mode = MODE_HEADER then varName := '';

      secName := '';
      mode := 0;

      Result := prSecEnd;
    {end else if (t.valStr = 'TABLE') and (mode = MODE_TABLES) then begin
      Result := prTableStart;
      tableName := '';
      handle := '';}
    end;
  end;
end;

function TDxfParser.ParseHeader(t: TDxfScanner; var newmode: integer): TDxfParseToken;
begin
  if (t.codegroup = CB_VARNAME) then begin
    varName := t.ValStr;
    Result := prVarName
  end else if (varName<>'') then
    Result := prVarValue;
end;

function TDxfParser.ParseClasses(t: TDxfScanner; var newmode: integer
  ): TDxfParseToken;
begin
  if (t.valStr = NAME_CLASS) then
    Result := prClassStart
  else
    Result := prClassAttr;
end;

function TDxfParser.ParseTables(t: TDxfScanner; var newmode: integer): TDxfParseToken;
begin
  if (t.valStr = NAME_TABLE) then begin
    Result := prTableStart;
    tableName := '';
    Handle := '';
    ConsumeCodeBlock(t, CB_NAME, tableName);
    ConsumeCodeBlock(t, CB_HANDLE, tableHandle);
  end
  else
    Result := prTableAttr;
end;

function TDxfParser.ParseBlocks(t: TDxfScanner; var newmode: integer): TDxfParseToken;
begin
  if (t.CodeGroup = CB_CONTROL) and (t.valStr = NAME_BLOCK) then begin
    Result := prBlockStart;
    Handle := '';
    ConsumeCodeBlock(t, CB_HANDLE, BlockHandle);
  end else if (t.CodeGroup = CB_CONTROL) and (t.valStr = NAME_ENDBLK) then begin
    Result := prBlockEnd;
    Handle := '';
    ConsumeCodeBlock(t, CB_HANDLE, BlockHandle);
  end else if (t.CodeGroup = CB_CONTROL) then begin
    // Entity!
    Result := ParseEntities(t, newmode);
    newmode := MODE_ENTITIESINBLOCK;
  end else begin
    if (t.CodeGroup = CB_HANDLE) and (BlockHandle = '') then BlockHandle := t.ValStr;
    Result := prBlockAttr;
  end;
end;

function TDxfParser.ParseEntities(t: TDxfScanner; var newmode: integer
  ): TDxfParseToken;
begin
  if (newmode = MODE_ENTITIESINBLOCK) and (t.CodeGroup = 0) and (t.ValStr = NAME_ENDBLK) then begin
    newmode := MODE_BLOCKS; // return to block parsing mode
    Result := ParseBlocks(t, newmode);
  end else if (t.CodeGroup = 0) then begin
    EntityType := t.ValStr;
    Result := prEntityStart;
    EntityHandle := '';
    ConsumeCodeBlock(t, CB_HANDLE, EntityHandle);
  end else begin
    if (t.CodeGroup = CB_HANDLE) and (Handle = '') then EntityHandle := t.ValStr;
    Result := prEntityAttr;
  end;
end;

function TDxfParser.DoNext: TDxfParseToken;
var
  //mode    : integer; // 0 - core, 1 - header
  t     : TDxfScanner;
  res   : TDxfScanResult;

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

  if (t.CodeGroup=CB_COMMENT) then begin
    comment := t.ValStr;
    Result := prComment;
  end else if (t.CodeGroup=0) and (t.ValStr = NAME_ENDSEC) then begin
    Result := prSecEnd
  end else if (t.CodeGroup=0) and (t.ValStr = NAME_EOF) then begin
    Result := prEof
  end else
    case mode of
      MODE_ROOT:
        Result := ParseRoot(t, mode);
      MODE_HEADER: begin
        Result := ParseHeader(t, mode);
      end;
      MODE_CLASSES:
        Result := ParseClasses(t, mode); // it's always class attribute
      MODE_BLOCKS:
        Result := ParseBlocks(t, mode);
      MODE_ENTITIES, MODE_ENTITIESINBLOCK:
        Result := ParseEntities(t, mode);
      MODE_OBJECTS:
        Result := prObjAttr;
      MODE_TABLES:
        Result := ParseTables(t, mode);
    end;

  case Result of
    prSecStart:
      inc(inSec);
    prSecEnd: begin
      dec(inSec);
      mode := MODE_ROOT;
    end;
  end;

end;

procedure TDxfParser.SetError(const msg: string);
begin
  ErrStr := msg;
end;

function TDxfParser.Next: TDxfParseToken;
begin
  token := DoNext;
  Result := token;
end;

function DxfisBinary(AStream: TStream): Boolean;
var
  buf : string;
  sz  : integer;
  pos : int64;
begin
  Result := Assigned(AStream);
  if not Result then Exit;

  SetLength(buf, length(DxfBinaryHeader));
  Result := AStream.Read(buf[1], length(buf)) = length(buf);
  if not Result then Exit;

  Result := buf = DxfBinaryHeader;
end;

function DxfAllocScanner(AStream: TStream; OwnStream: boolean): TDxfScanner;
var
  pos : Int64;
begin
  if not Assigned(AStream) then begin
    Result := nil;
    Exit;
  end;
  pos := AStream.Position;
  if DxfisBinary(AStream) then
    Result := TDxfBinaryScanner.Create
  else begin
    AStream.Position := pos;
    Result := TDxfAsciiScanner.Create;
  end;
  Result.SetSource(AStream, OwnStream);
end;

function DxfValAsStr(s: TDxfScanner): string;
begin
  if not Assigned(s) then begin
    Result := '';
    exit;
  end;
  case s.DataType of
    dtUnknown:
      Result := s.ValStr;
    dtBoolean, dtInt16, dtInt32:
      Result := IntToStr(s.ValInt);
    dtInt64:
      Result := IntToStr(s.ValInt64);
    dtDouble: begin
      Str(s.ValFloat, Result);
    end;
    dtStr2049, dtStr255, dtStrHex:
      Result := s.ValStr;
    dtBin1: begin
      SetLength(Result, s.ValBinLen*2);
      if length(Result)>0 then
        BinToHex(@s.ValBin[0], @Result[1], s.ValBinLen);
    end;

  end;
end;

end.

