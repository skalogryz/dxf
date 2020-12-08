unit dxfclasses;

interface

uses
  Classes, SysUtils, dxftypes, dxfparse, dxfwrite;

type
  TDxfHeader = class(TObject)
  public
    MaintVer   : Int16;  // $ACADMAINTVER
    AutoCadVer : string; // $ACADVER
    AngBase    : double; // $ANGBASE
    AndDir     : Int16;  // $ANGDIR // 1 = Clockwise angles 0 = Counterclockwise angles
  end;

  { TDxfCommonObj }

  TDxfCommonObj = class(TObject)
    Name   : string;
    Handle : string;
    procedure SetAttr(const codeGroup: Integer; scanner: TDxfScanner); virtual;
    procedure WriteAttr(w: TDxfWriter); virtual;
  end;

  { TDxfTable }

  TDxfTable = class(TDxfCommonObj)
  private
    fItems: TList;
    function GetObject(i: integer): TObject;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function AddItem(obj: TObject): Integer;
    procedure Clear;
    property Item[i: integer]: TObject read GetObject;
    property Count: Integer read GetCount;
  end;

  { TDxfEntity }

  TDxfEntity = class(TDxfCommonObj)
    LayerName   : string; // 8
    OwnerHandle : string; // 330
    procedure SetAttr(const codeGroup: Integer; scanner: TDxfScanner); override;
  end;

  TDxfPoint = record
    x,y,z: double;
  end;

  { TDxfInsert }

  TDxfInsert = class(TDxfEntity)
    BlockName  : string;
    VarFlag    : Int16;
    InsPt      : TDxfPoint;
    Scale      : TDxfPoint;
    ExtrDir    : TDxfPoint; // Extrusion direction
    ColSpacing : double;
    RowSpacing : double;
    ColCount   : integer;
    RowCount   : integer;
    RotAngle   : double;
    procedure SetAttr(const codeGroup: Integer; scanner: TDxfScanner); override;
  end;

  { TDxfLine }

  TDxfLine = class(TDxfEntity)
    StPt       : TDxfPoint; // Start Point
    EndPt      : TDxfPoint; // End Point
    Thickness  : Double;    // Thickness
    ExtrDir    : TDxfPoint; // Extrusion direction
    procedure SetAttr(const codeGroup: Integer; scanner: TDxfScanner); override;
  end;

  { TDxfPolyLine }

  TDxfPolyLine = class(TDxfEntity)
    Thickness  : Double;    // 39
    Flags      : Integer;   // 70
    StartWidth : Double;    // 40
    EndWidth   : Double;    // 41
    SurfType   : Int16;     // 75
    ExtrDir    : TDxfPoint; // 210, 220, 230
    procedure SetAttr(const codeGroup: Integer; scanner: TDxfScanner); override;
  end;

  { TDxfVertex }

  TDxfVertex = class(TDxfEntity)
    Pt         : TDxfPoint; // 10,20,30
    StartWidth : Double; // 40
    EndWidth   : Double; // 41
    Buldge     : Double; // 42
    TangentDir : Double; // 50
    Flags      : Integer; // 70
    PolyFace   : array [0..3] of Int16; // 71..74
    VertexIdx  : Integer; // 91
    procedure SetAttr(const codeGroup: Integer; scanner: TDxfScanner); override;
  end;

  { TDxfFile }

  TDxfFile = class(TObject)
  public
    header   : TDxfHeader;
    tables   : TList;
    entities : TList;
    blocks   : TList;
    constructor Create;
    destructor Destroy; override;
    function AddTable(const TableName: string): TDxfTable;
    function AddEntity(const EntityName: string): TDxfEntity;
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

function AllocEntity(const Name: string): TDxfEntity;

procedure PtrAttr(const codeGroup: Integer; scanner: TDxfScanner; var pt: TDxfPoint);

function DxfSaveToString(dst: TDxfFile): string;
procedure DxfSaveToStream(const st: TStream; dst: TDxfFile; binFormat: Boolean);
procedure DxfSaveToFile(const st: string; dst: TDxfFile; binFormat: Boolean);
procedure DxfSave(wr: TDxfWriter; dst: TDxfFile);

implementation

{ TDxfInsert }

procedure TDxfInsert.SetAttr(const codeGroup: Integer; scanner: TDxfScanner);
begin
  case codeGroup of
    66: VarFlag := scanner.ValInt;
    2:  BlockName := scanner.ValStr;
    10,20,30: PtrAttr(codeGroup, scanner, InsPt);
    41,42,43: PtrAttr(codeGroup, scanner, Scale);
    44: ColSpacing := scanner.ValFloat;
    45: RowSpacing := scanner.ValFloat;
    70: ColCount := scanner.ValInt;
    71: RowCount := scanner.ValInt;
    50: RotAngle := scanner.ValFloat;
    210,220,230: PtrAttr(codeGroup, scanner, ExtrDir);
  else
    inherited SetAttr(codeGroup, scanner);
  end;
end;

{ TDxfPolyLine }

procedure TDxfPolyLine.SetAttr(const codeGroup: Integer; scanner: TDxfScanner);
begin
  case codeGroup of
    39: Thickness  := scanner.ValFloat;
    70: Flags      := scanner.ValInt;
    40: StartWidth := scanner.ValFloat;
    41: EndWidth   := scanner.ValFloat;
    75: SurfType   := scanner.ValInt;
    210, 220, 230: PtrAttr(codeGroup, scanner, ExtrDir);
  else
    inherited SetAttr(codeGroup, scanner);
  end;
end;

{ TDxfEntity }

procedure TDxfEntity.SetAttr(const codeGroup: Integer; scanner: TDxfScanner);
begin
  case codeGroup of
    8: LayerName := scanner.ValStr;
  else
    //inherited SetAttr(codeGroup, scanner);
  end;
end;

{ TDxfLine }

procedure TDxfLine.SetAttr(const codeGroup: Integer; scanner: TDxfScanner);
begin
  case codeGroup of
    10, 20, 30: PtrAttr(codeGroup, scanner, StPt);
    11, 21, 31: PtrAttr(codeGroup, scanner, EndPt);
    210, 220, 230: PtrAttr(codeGroup, scanner, ExtrDir);
    39: Thickness := scanner.ValFloat;
  else
    inherited
  end;
end;

{ TDxfVertex }

procedure TDxfVertex.SetAttr(const codeGroup: Integer; scanner: TDxfScanner);
begin
  case codeGroup of
    10, 20, 30: PtrAttr(codeGroup, scanner, pt);
    40: StartWidth := scanner.ValFloat;
    41: EndWidth := scanner.ValFloat;
    42: Buldge := scanner.ValFloat;
    50: TangentDir := scanner.ValFloat;
    70: Flags := scanner.ValInt;
    71..74:
        PolyFace[codeGroup-71]:=scanner.ValInt;
    91: VertexIdx := scanner.ValInt;
  else
    inherited
  end;
end;

{ TDxfCommonObj }

procedure TDxfCommonObj.SetAttr(const codeGroup: Integer; scanner: TDxfScanner);
begin
  case codeGroup of
    CB_HANDLE: Handle := scanner.ValStr;
    CB_NAME: Name := scanner.ValStr;
  end;
end;

procedure TDxfCommonObj.WriteAttr(w: TDxfWriter);
begin

end;

{ TDxfTable }

constructor TDxfTable.Create;
begin
  inherited;
  fItems := TList.Create;
end;

destructor TDxfTable.Destroy;
begin
  Clear;
  fItems.Free;
  inherited Destroy;
end;

function TDxfTable.GetObject(i: integer): TObject;
begin
  if (i<0) or (i>=fItems.Count) then Result := nil
  else Result := TObject(FItems[i]);
end;

function TDxfTable.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TDxfTable.AddItem(obj: TObject): Integer;
begin
  if not Assigned(obj) then begin
    Result := -1;
    Exit;
  end;
  Result := fItems.Add(obj);
end;

procedure TDxfTable.Clear;
var
  i : integer;
begin
  for i:=0 to fItems.Count-1 do
    TObject(fItems[i]).free;
  fItems.Clear;
end;

{ TDxfFile }

constructor TDxfFile.Create;
begin
  inherited Create;
  header := TDxfHeader.Create;
  tables := TList.Create;
  entities := TList.Create;
end;

destructor TDxfFile.Destroy;
begin
  entities.Free;
  tables.Free;
  header.Free;
  inherited;
end;

function TDxfFile.AddTable(const TableName: string): TDxfTable;
begin
  Result := TDxfTable.Create;
  Result.Name := TableName;
  tables.Add(Result);
end;

function TDxfFile.AddEntity(const EntityName: string): TDxfEntity;
begin
  Result := AllocEntity(EntityName);
  entities.Add(Result);
end;

procedure TDxfFile.Clear;
var
  i : integer;
begin
  for i:=0 to tables.Count-1 do
    TObject(tables[i]).Free;
  tables.Clear;
  for i:=0 to entities.Count-1 do
    TObject(entities[i]).Free;
  entities.Clear;
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
  tbl  : TDxfTable;
  ent  : TDxfEntity;

  ln, ofs: integer;
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

        prEntityStart:
        begin
          if trim(p.EntityType) = '111' then begin
            p.scanner.GetLocationInfo(ln, ofs);
            writeln('odd entity type: ',ln,' ',ofs);
          end;
          ent := dst.AddEntity(p.EntityType);
          ent.Handle := p.EntityHandle;
        end;

        prEntityAttr:
        begin
          if Assigned(ent) then
            ent.SetAttr(p.scanner.CodeGroup, p.scanner);
        end;

        prSecEnd: begin
          tbl := nil;
          ent := nil;
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
  t : TDxfTable;
  e : TDxfEntity;
begin
  writeln('Tables: ', dxf.tables.Count);
  for i:=0 to dxf.tables.Count-1 do begin
    t := TDxfTable(dxf.tables[i]);
    writeln('  ',t.Name);
  end;
  writeln('Entities: ', dxf.entities.Count);
  for i:=0 to dxf.entities.Count-1 do begin
    e := TDxfEntity(dxf.entities[i]);
    writeln('  ',e.Name,' ',e.ClassName);
  end;
end;

function AllocEntity(const Name: string): TDxfEntity;
begin
  Result := nil;
  if Name='' then Exit;

  case Name[1] of
    'I':
      if Name='INSERT' then
        Result := TDxfInsert.Create;
    'L':
      if Name='LINE' then
        Result := TDxfLine.Create;
    'P':
      if Name='POLYLINE' then
        Result := TDxfPolyLine.Create;
    'V':
      if Name='VERTEX' then
        Result := TDxfVertex.Create;
  end;
  if not Assigned(Result) then
    Result := TDxfEntity.Create;
  Result.Name := Name;
end;

procedure PtrAttr(const codeGroup: Integer; scanner: TDxfScanner; var pt: TDxfPoint);
begin
  case codeGroup of
    10, 11, 41, 210: pt.x := scanner.ValFloat;
    20, 21, 42, 220: pt.y := scanner.ValFloat;
    30, 31, 43, 230: pt.z := scanner.ValFloat;
  end;
end;


function DxfSaveToString(dst: TDxfFile): string;
var
  st : TStringStream;
begin
  st := TStringStream.Create;
  try
    DxfSaveToStream(st, dst, false);
    Result := st.DataString;
  finally
    st.Free;
  end;
end;

procedure DxfSaveToStream(const st: TStream; dst: TDxfFile; binFormat: Boolean);
var
  w : TDxfWriter;
begin
  if binFormat then
    w := TDxfBinaryWriter.Create
  else
    w := TDxfAsciiWriter.Create;
  w.SetDest(st, false);
  DxfSave(w, dst);
end;

procedure DxfSaveToFile(const st: string; dst: TDxfFile; binFormat: Boolean);
var
  fs : TFileStream;
begin
  fs := TFileStream.Create(st, fmCreate);
  try
    DxfSaveToStream(fs, dst, binFormat);
  finally
    fs.Free;
  end;
end;

procedure DxfSave(wr: TDxfWriter; dst: TDxfFile);
var
  i : integer;
  e : TDxfEntity;
begin
  if not Assigned(wr) or not Assigned(dst) then Exit;

  WrStartSection(wr, NAME_ENTITIES);
  for i:=0 to dst.entities.Count-1 do begin
    e := TDxfEntity(dst.entities[i]);
    wr.WriteStr(CB_CONTROL, e.Name);
    WrHandle(wr, e.Handle);
    WrHandle(wr, e.OwnerHandle, CB_OWNERHANDLE);
  end;
  WrEndSection(wr);
  WrEndOfFile(wr);
end;

end.
