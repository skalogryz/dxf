unit dxfwrite;

{$ifdef fpc}{$mode delphi}{$H+}{$endif}

interface

uses
  SysUtils, Classes, dxftypes;

type

  { TDxfWriter }

  TDxfWriter = class(TObject)
  public
    procedure SetDest(ASource: TStream; OwnStream: Boolean); virtual; abstract;
    procedure WriteInt16(codeGroup: integer; v: int16); virtual; abstract;
    procedure WriteInt32(codeGroup: integer; v: int32); virtual; abstract;
    procedure WriteStrPart(codeGroup: integer; const s: string); virtual; abstract;
    procedure WriteFloat(codeGroup: integer; f: double); virtual; abstract;
    procedure WriteFlt(codeGroup: integer; f: double);
    procedure WriteBin(codeGroup: integer; const data; dataLen: integer); virtual; abstract;
    procedure WriteStr(codeGroup: integer; const data: string; maxLen: Integer = -1);
    // tries to determine the 16 vs 32 based on the group code
    procedure WriteInt(codeGroup: integer; v: integer);
  end;

  { TDxfAsciiWriter }

  TDxfAsciiWriter = class(TDxfWriter)
    Dst    : TStream;
    OwnDst : Boolean;
    destructor Destroy; override;
    procedure SetDest(ADst: TStream; AOwnStream: Boolean); override;
    procedure WriteInt16(codeGroup: integer; v: int16); override;
    procedure WriteInt32(codeGroup: integer; v: int32); override;
    procedure WriteStrPart(codeGroup: integer; const s: string); override;
    procedure WriteFloat(codeGroup: integer; f: double); override;
    procedure WriteBin(codeGroup: integer; const data; dataLen: integer); override;
    function FloatToStr(d: double): string; virtual;
  end;

  { TDxfBinaryWriter }

  TDxfBinaryWriter = class(TDxfWriter)
    Dst    : TStream;
    OwnDst : Boolean;
    destructor Destroy; override;
    procedure SetDest(ADst: TStream; AOwnStream: Boolean); override;
    procedure WriteInt16(codeGroup: integer; v: int16); override;
    procedure WriteInt32(codeGroup: integer; v: int32); override;
    procedure WriteStrPart(codeGroup: integer; const s: string); override;
    procedure WriteFloat(codeGroup: integer; f: double); override;
    procedure WriteBin(codeGroup: integer; const data; dataLen: integer); override;

    procedure WriteCG(codeGroup: integer);
    procedure WriteHeader;
  end;

procedure TextCodeGroupToDst(codeGroup: integer; d: TStream); {$ifdef fpc}inline;{$endif}
procedure TextStrToDst(const s: string; d: TStream); {$ifdef fpc}inline;{$endif}
procedure TextLFToDst(d: TStream); {$ifdef fpc}inline;{$endif}

const
  LF = #13#10;

procedure WrStartSection(w: TDxfWriter; const SecName: string);
procedure WrEndSection(w: TDxfWriter);
procedure WrEndOfFile(w: TDxfWriter);
procedure WrName(w: TDxfWriter; const AName: string);
procedure WrHandle(w: TDxfWriter; const AHandle: string; CodeGroup: Integer = CB_HANDLE );

implementation

procedure TextCodeGroupToDst(codeGroup: integer; d: TStream); {$ifdef fpc}inline;{$endif}
var
  s : string;
begin
  s := IntToStr(codegroup);
  d.Write(s[1], length(s));
  d.Write(LF[1], length(LF));
end;

procedure TextStrToDst(const s: string; d: TStream); {$ifdef fpc}inline;{$endif}
begin
  if s = '' then Exit;
  d.Write(s[1], length(s));
end;

procedure TextLFToDst(d: TStream); {$ifdef fpc}inline;{$endif}
begin
  d.Write(LF[1], length(LF));
end;

{ TDxfWriter }

procedure TDxfWriter.WriteFlt(codeGroup: integer; f: double);
begin
  WriteFloat(codeGroup, f);
end;

procedure TDxfWriter.WriteStr(codeGroup: integer; const data: string;
  maxLen: Integer);
var
  s : string;
begin
  if maxLen<=0 then begin
    if DxfDataType(codeGroup) = dtStr2049 then
      maxLen := MAX_STREX
    else
      maxLen := MAX_STR;
  end;

  s := data;
  repeat
    WriteStrPart(codegroup, Copy(s, 1, maxLen));
    if length(s) < maxLen then s := ''
    else s := Copy(s, maxLen, length(s));
  until s = '';
end;

procedure TDxfWriter.WriteInt(codeGroup: integer; v: integer);
begin
  case DxfDataType(codegroup) of
    dtInt16: WriteInt16(codeGroup, Int16(v));
    dtInt32,
    dtInt64: WriteInt32(codeGroup, v);
    dtDouble: WriteFloat(codeGroup, v);
  else
    WriteStr(codeGroup, intToStr(v));
  end;
end;

{ TDxfBinaryWriter }

destructor TDxfBinaryWriter.Destroy;
begin
  if OwnDst then Dst.Free;
  inherited Destroy;
end;

procedure TDxfBinaryWriter.SetDest(ADst: TStream; AOwnStream: Boolean);
begin
  Dst := ADst;
  OwnDst := AOwnStream;
end;

procedure TDxfBinaryWriter.WriteInt16(codeGroup: integer; v: int16);
begin
  WriteCG(codeGroup);
  dst.Write(v, sizeof(v));
end;

procedure TDxfBinaryWriter.WriteInt32(codeGroup: integer; v: int32);
begin
  WriteCG(codeGroup);
  dst.Write(v, sizeof(v));
end;

procedure TDxfBinaryWriter.WriteStrPart(codeGroup: integer; const s: string);
var
  b: byte;
begin
  WriteCG(codeGroup);
  if s<>'' then
    dst.Write(s[1], length(s));
  b:=0;
  dst.Write(b, sizeof(b))
end;

procedure TDxfBinaryWriter.WriteFloat(codeGroup: integer; f: double);
begin
  WriteCG(codeGroup);
  dst.Write(f, sizeof(f));
end;

procedure TDxfBinaryWriter.WriteBin(codeGroup: integer; const data;
  dataLen: integer);
var
  b : byte;
begin
  WriteCG(codeGroup);
  b:=byte(dataLen);
  dst.Write(b, sizeof(b));
  dst.Write(data, b);
end;

procedure TDxfBinaryWriter.WriteCG(codeGroup: integer);
begin
  dst.Write( Int16(codegroup), 2);
end;

procedure TDxfBinaryWriter.WriteHeader;
var
  s : string;
begin
  s := DxfBinaryHeader;
  dst.Write(s[1], length(s));
end;

{ TDxfAsciiWriter }

destructor TDxfAsciiWriter.Destroy;
begin
  if OwnDst then Dst.Free;
  inherited Destroy;
end;

procedure TDxfAsciiWriter.SetDest(ADst: TStream; AOwnStream: Boolean);
begin
  Dst := ADst;
  OwnDst := AOwnStream;
end;

procedure TDxfAsciiWriter.WriteInt16(codeGroup: integer; v: int16);
begin
  TextCodeGroupToDst(codeGroup, dst);
  TextStrToDst(IntToStr(v), dst);
  TextLFToDst(dst);
end;

procedure TDxfAsciiWriter.WriteInt32(codeGroup: integer; v: int32);
begin
  TextCodeGroupToDst(codeGroup, dst);
  TextStrToDst(IntToStr(v), dst);
  TextLFToDst(dst);
end;

procedure TDxfAsciiWriter.WriteStrPart(codeGroup: integer; const s: string);
begin
  TextCodeGroupToDst(codeGroup, dst);
  TextStrToDst(s, dst);
  TextLFToDst(dst);
end;

procedure TDxfAsciiWriter.WriteFloat(codeGroup: integer; f: double);
var
  s : string;
begin
  TextCodeGroupToDst(codeGroup, dst);
  s := Self.FloatToStr(f);
  TextStrToDst(s, dst);
  TextLFToDst(dst);
end;

procedure TDxfAsciiWriter.WriteBin(codeGroup: integer; const data;
  dataLen: integer);
var
  s : string;
begin
  TextCodeGroupToDst(codeGroup, dst);
  if dataLen > 0 then begin
    s:='';
    SetLength(s, dataLen * 2);
    BinToHex(PChar(@data), @s[1], dataLen);
    TextStrToDst(s, dst);
  end;
  TextLFToDst(dst);
end;

function TDxfAsciiWriter.FloatToStr(d: double): string;
var
  i : integer;
const
  DEF_PREC = 17;
begin
  Str(d:0:DEF_PREC, Result);
  if Result = '' then Exit;

  for i:=length(Result)-1 downto 1 do begin
    if Result[i]<>'0' then begin
      if Result[i]='.' then Result := Copy(Result, 1, i+1) // grabbing one extra zero. to get 10.0
      else Result := Copy(Result, 1, i);
      Exit;
    end;
  end;
end;

procedure WrStartSection(w: TDxfWriter; const SecName: string);
begin
  w.WriteStr(CB_CONTROL, NAME_SECTION);
  w.WriteStr(CB_NAME, SecName);
end;

procedure WrEndSection(w: TDxfWriter);
begin
  w.WriteStr(CB_CONTROL, NAME_ENDSEC);
end;

procedure WrEndOfFile(w: TDxfWriter);
begin
  w.WriteStr(CB_CONTROL, NAME_EOF);
end;

procedure WrName(w: TDxfWriter; const AName: string);
begin
  if AName ='' then Exit;
  w.WriteStr(CB_NAME, AName);
end;

procedure WrHandle(w: TDxfWriter; const AHandle: string; CodeGroup: Integer);
begin
  if AHandle = '' then Exit;
  w.WriteStr(CodeGroup, AHandle);
end;

end.
