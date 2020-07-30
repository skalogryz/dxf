unit dxfclasses;

interface

uses
  Classes, SysUtils, dxftypes, dxfparse;

type
  TDxfHeader = class(TObject)
  public
    MaintVer   : Int16;  // $ACADMAINTVER
    AutoCadVer : string; // $ACADVER
    AngBase    : double; // $ANGBASE
    AndDir     : Int16;  // $ANGDIR // 1 = Clockwise angles 0 = Counterclockwise angles
  end;

  { TDxfFile }

  TDxfFile = class(TObject)
  public
    header : TDxfHeader;
    constructor Create;
    destructor Destroy; override;
  end;

type
  THeaderReadProc = procedure(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; var Handled: Boolean);

procedure RegisterHeaderVar(proc: THeaderReadProc);
procedure UnregisterHeaderVar(proc: THeaderReadProc);
procedure RunHeaderVarProc(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; out Handled: Boolean);
procedure DefaultHeaderVar(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; var Handled: Boolean);

procedure LoadASCIIFromString(const data: string; dst: TDxfFile);
procedure LoadASCIIFromStream(const st: TStream; dst: TDxfFile);
procedure LoadASCIIFromFile(const st: string; dst: TDxfFile);

implementation

type

  { TDxfFileBuilder }

  TDxfFileBuilder = class(TInterfacedObject)
  protected
    procedure StartSection(const secName: string);
    procedure HeaderVar(const varName: string; const codeBlock: Integer; const value: string);
    procedure EndOfSection(const secName: string);
  public
    dst : TDxfFile;
    constructor Create(adst: TDxfFile);
  end;

{ TDxfFileBuilder }

procedure TDxfFileBuilder.StartSection(const secName: string);
begin
  writeln('START SECTION: ', secName);
end;

procedure TDxfFileBuilder.HeaderVar(const varName: string;
  const codeBlock: Integer; const value: string);
var
  hnd : Boolean;
begin
  writeln('reading VAR: ', varName,' with [', codeBlock, '] ',value);
  hnd := false;
  RunHeaderVarProc(dst.header, varName, codeBlock, value, hnd);
end;

procedure TDxfFileBuilder.EndOfSection(const secName: string);
begin
  writeln('END SECTION: ', secName);
end;

constructor TDxfFileBuilder.Create(adst: TDxfFile);
begin
  inherited Create;
  dst:=adst;
end;

{ TDxfFile }

constructor TDxfFile.Create;
begin
  inherited Create;
  header := TDxfHeader.Create;
end;

destructor TDxfFile.Destroy;
begin
  header.Free;
  inherited;
end;

procedure RegisterHeaderVar(proc: THeaderReadProc);
begin

end;

procedure UnregisterHeaderVar(proc: THeaderReadProc);
begin

end;

procedure RunHeaderVarProc(Header: TDxfHeader; const curVar: string;
  codeblock: Integer; const value: string; out Handled: Boolean);
begin
  Handled := false;
  DefaultHeaderVar(Header, curVar, codeblock, value, Handled);
end;

procedure DefaultHeaderVar(Header: TDxfHeader; const curVar: string;
  codeblock: Integer; const value: string; var Handled: Boolean);
begin
  Handled := true;
  if curVar = '' then begin
  end else
    Handled := false;
end;


procedure LoadASCIIFromString(const data: string; dst: TDxfFile);
var
  t : TDxfAsciiScanner;
  p :  TDxfParser;
  bld : TDxfFileBuilder;
  res : TDxfParseResult;
  done : boolean;
begin
  if (data = '') then Exit;

  t := TDxfAsciiScanner.Create;
  p := TDxfParser.Create;
  try
    t.SetBuf(data);
    p.scanner := t;

    done := false;
    while not done do begin
      res := p.Next;
      //writeln('res = ', res);
      case res of
        prSecStart: writeln('section start: ', p.secName);
        prSecEnd:   writeln('section end:   ', p.secName);
        prVarName:  writeln('value: ',p.varName);
        prError: begin
          writeln('err: ', p.ErrStr);
          done := true;
        end;
        prEof: begin
          writeln('done');
          done := true;
        end;
      end;
    end;
  finally
    p.Free;
    t.Free;
  end;
end;

procedure LoadASCIIFromStream(const st: TStream; dst: TDxfFile);
var
  buf : string;
begin
  SetLength(buf, st.Size);
  if st.Size>0 then begin
    st.Read(buf[1], length(buf));
    LoadASCIIFromString(buf, dst);
  end;
end;

procedure LoadASCIIFromFile(const st: string; dst: TDxfFile);
var
  f : TFileStream;
begin
  f := TFileStream.Create(st, fmOpenRead or fmShareDenyNone);
  try
    LoadASCIIFromStream(f, dst);
  finally
    f.Free;
  end;
end;

end.
