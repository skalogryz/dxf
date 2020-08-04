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

  TDxfCommonObj = class(TObject)
    Handle : string;
  end;

  TDxfDbSymbolTable = class(TDxfCommonObj)
  public
    Name : string;
  end;

  TDxfDbSymbolTableRecord = class
  end;

  TDxfDbRegAppTableRecord = class
  end;

  TDxfDbBlockTableRecord = class
  end;

  TDxfDbDimStyleTableRecord = class
  end;

  TDxfDbLayerTableRecord = class
  end;

  TDxfDbLinetypeTableRecord = class
  end;

  TDxfDbTextStyleTableRecord = class
  end;

  TDxfDbUCSTableRecord = class
  end;

  TDxfDbViewTableRecord = class
  end;

  TDxfDbViewportTableRecord = class
  end;

  TDxfDbEntity = class(TObject)
  end;

  TDxfDbBlockBegin = class(TDxfDbEntity)
  end;

  TDxfDbBlockEnd = class(TDxfDbEntity)
  end;

  { TDxfFile }

  TDxfFile = class(TObject)
  public
    header : TDxfHeader;
    tables : TList;
    constructor Create;
    destructor Destroy; override;
    function AddTable(const TableName: string): TDxfDbSymbolTable;
    procedure Clear;
  end;

type
  THeaderReadProc = procedure(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; var Handled: Boolean);

procedure RegisterHeaderVar(proc: THeaderReadProc);
procedure UnregisterHeaderVar(proc: THeaderReadProc);
procedure RunHeaderVarProc(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; out Handled: Boolean);
procedure DefaultHeaderVar(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; var Handled: Boolean);

procedure DxfLoadFromString(const data: string; dst: TDxfFile);
procedure DxfLoadFromStream(const st: TStream; dst: TDxfFile);
procedure DxfLoadFromFile(const st: string; dst: TDxfFile);

procedure DxfFileDump(dxf: TDxfFile);

implementation

{ TDxfFile }

constructor TDxfFile.Create;
begin
  inherited Create;
  header := TDxfHeader.Create;
  tables := TList.Create;
end;

destructor TDxfFile.Destroy;
begin
  tables.Free;
  header.Free;
  inherited;
end;

function TDxfFile.AddTable(const TableName: string): TDxfDbSymbolTable;
begin
  Result := TDxfDbSymbolTable.Create;
  Result.Name := TableName;
  tables.Add(Result);
end;

procedure TDxfFile.Clear;
var
  i : integer;
begin
  for i:=0 to tables.Count-1 do
    TObject(tables[i]).Free;
  tables.Clear;
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


procedure DxfLoadFromString(const data: string; dst: TDxfFile);
var
  st : TStringStream;
begin
  st := TStringStream.Create(data);
  try
    DxfLoadFromStream(st, dst);
  finally
    st.free;
  end;
end;

procedure DxfLoadFromStream(const st: TStream; dst: TDxfFile);
var
  sc   : TDxfScanner;
  p    : TDxfParser;
  res  : TDxfParseToken;
  done : boolean;
  tbl  : TDxfDbSymbolTable;
begin
  if not Assigned(st) or not Assigned(dst) then Exit;

  tbl := nil;
  sc := DxfAllocScanner(st, false);
  p := TDxfParser.Create;
  try
    p.scanner := sc;

    done := false;
    while not done do begin
      res := p.Next;

      case res of
        prTableStart: begin
          tbl := dst.AddTable( p.tableName );
          tbl.Handle := p.tableHandle;
        end;

        prTableAttr: begin
          case p.scanner.CodeGroup of
            CB_NAME:   tbl.Name := p.tableName;
            CB_HANDLE: tbl.Handle := p.tableHandle;
          end;
        end;

        prSecEnd: begin
          if tbl <> nil then tbl := nil;
        end;


        prError: begin
          done := true;
        end;
        prEof: begin
          done := true;
        end;

      end;
    end;
  finally
    p.Free;
    sc.Free;
  end;
end;

procedure DxfLoadFromFile(const st: string; dst: TDxfFile);
var
  f : TFileStream;
begin
  f := TFileStream.Create(st, fmOpenRead or fmShareDenyNone);
  try
    DxfLoadFromStream(f, dst);
  finally
    f.Free;
  end;
end;

procedure DxfFileDump(dxf: TDxfFile);
var
  i : integer;
  t : TDxfDbSymbolTable;
begin
  writeln('Tables: ', dxf.tables.Count);
  for i:=0 to dxf.tables.Count-1 do begin
    t := TDxfDbSymbolTable(dxf.tables[i]);
    writeln('  ',t.Name);
  end;
end;

end.
