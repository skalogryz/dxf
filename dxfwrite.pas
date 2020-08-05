unit dxfwrite;

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
    procedure WriteBin(codeGroup: integer; const data; dataLen: integer); virtual; abstract;
    procedure WriteStr(codeGroup: integer; const data: string; maxLen: Integer = -1);
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

procedure TextCodeGroupToDst(codeGroup: integer; d: TStream); inline;
procedure TextStrToDst(const s: string; d: TStream); inline;
procedure TextLFToDst(d: TStream); inline;

const
  LF = #13#10;

implementation

procedure TextCodeGroupToDst(codeGroup: integer; d: TStream); inline;
var
  s : string;
begin
  s := IntToStr(codegroup);
  d.Write(s[1], length(s));
  d.Write(LF[1], length(LF));
end;

procedure TextStrToDst(const s: string; d: TStream); inline;
begin
  if s = '' then Exit;
  d.Write(s[1], length(s));
end;

procedure TextLFToDst(d: TStream); inline;
begin
  d.Write(LF[1], length(LF));
end;

{ TDxfWriter }

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
  dst.WriteWord(Word(v));
end;

procedure TDxfBinaryWriter.WriteInt32(codeGroup: integer; v: int32);
begin
  WriteCG(codeGroup);
  dst.WriteDWord(DWord(v));
end;

procedure TDxfBinaryWriter.WriteStrPart(codeGroup: integer; const s: string);
begin
  WriteCG(codeGroup);
  if s<>'' then
    dst.Write(s[1], length(s));
  dst.WriteByte(0);
end;

procedure TDxfBinaryWriter.WriteFloat(codeGroup: integer; f: double);
begin
  WriteCG(codeGroup);
  dst.Write(f, sizeof(f));
end;

procedure TDxfBinaryWriter.WriteBin(codeGroup: integer; const data;
  dataLen: integer);
begin
  WriteCG(codeGroup);
  dst.WriteByte(byte(dataLen));
  dst.Write(data, byte(dataLen));
end;

procedure TDxfBinaryWriter.WriteCG(codeGroup: integer);
begin
  dst.WriteWord( Word(Int16(codegroup)));
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
  Str(f, s);
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

end.
