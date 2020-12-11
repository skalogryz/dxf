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

  { TDxfTable }

  TDxfTable = class(TObject)
  private
    fItems: TList;
    function GetObject(i: integer): TObject;
    function GetCount: Integer;
  public
    Name : string;
    Handle : string;
    constructor Create;
    destructor Destroy; override;
    function AddItem(obj: TObject): Integer;
    procedure Clear;
    property Item[i: integer]: TObject read GetObject;
    property Count: Integer read GetCount;
  end;

  TDxfPoint = record
    x,y,z: double;
  end;

  // todo:
  TDxfValue = class
    s   : string;
    i   : integer;
    i64 : int64;
    f   : double;
  end;

  TDxfValuesList = class
    count     : integer;
    vales     : array of TDxfValue;
  end;

  { TDxfEntity }

  TDxfEntity = class
    EntityType      : string; // 0. Not parsed, but assigned elsewhere
    Handle          : string;          // 5
    appName         : string;          // 120 (value of)
    appValues       : TDxfValuesList;  // 120+custom
    ACAD_Reactors   : TDxfValuesList;  // 120+330
    ACAD_XDict      : TDxfValuesList;  // 120+360
    Owner           : string;  // 330
    SubClass        : string;  // 100 (should be AcDbEntity)
    SpaceFlag       : int32;   // 67 -- optional!!!  (seen on Paper_Source)
    AppTableLayout  : string; // 410
    LayerName       : string;  // 8
    LineTypeName    : string;  // 6 (default BYLAYER)
    HardPtrId       : string;  // 347
    ColorNumber     : string;  // 62
    LineWidth       : Integer; // 370
    LineScale       : Double;  // 48
    isVisible       : Integer; // 60
    ProxyBytesCount : Integer; // 92
    ProxyGraph      : array of byte; // 310s
    Color           : Integer; // 420
    ColorName       : string;  // 430
    Transperancy    : Integer; // 440
    PoltObj         : string;  // 390
    ShadowMode      : Integer; // 284
    Subclass2       : string;  // 100
    constructor Create(const AEntityType: string = '');
  end;

  { TDxfInsert }

  TDxfInsert = class(TDxfEntity)
    AttrFlag   : Integer;
    BlockName  : string;
    InsPoint   : TDxfPoint;
    Scale      : TDxfPoint;
    Rotation   : double;
    ColCount   : integer;
    RowCount   : integer;
    ColSpace   : double;
    RowSpace   : double;
    Extrusion  : TDxfPoint; // Extrusion direction
    constructor Create(const AEntityType: string = ET_INSERT);
  end;

  TDxfClass = class
    recName    : string;  // 1
    cppName    : string;  // 2
    appName    : string;  // 3
    ProxyFlags : integer; // 90
    InstCount  : integer; // 91
    WasProxy   : integer; // 280
    IsAnEntity : integer; // 281
  end;

  TDxfBlockEntity = class
    Handle       : string;  // 5
    appDefGroup  : string;  // 102
    Owner        : string;  //
    SubClass     : string;  // 100
    SpaceFlag    : int32;   // 67 -- optional!!!  (seen on Paper_Source)
    LayerName    : string;  // 8
    Subclass2    : string;  // 100
  end;

  { TDxfBlock }

  TDxfBlock = class(TDxfBlockEntity)
    BlockName  : string;    // 2
    BlockFlags : integer;   // 70
    BasePoint  : TDxfPoint; // 10 20 30
    BlockName2 : string;    // 3
    XRef       : string;    // 1
    Descr      : string;    // 4
  end;

  TDxfBlockEnd = class (TDxfBlockEntity)
    // no special fields for EndBlock
  end;

  { TDxfCircle }

  TDxfCircle = class(TDxfEntity)
    Thickness   : double;
    CenterPoint : TDxfPoint;
    Radius      : double;
    Extrusion   : TDxfPoint;
    constructor Create(const AEntityType: string = ET_CIRCLE);
  end;

  { TDxfSolid }

  TDxfSolid = class(TDxfEntity)
    Corner1     : TDxfPoint;
    Corner2     : TDxfPoint;
    Corner3     : TDxfPoint;
    Corner4     : TDxfPoint;
    Thickness   : double;
    Extrusion   : TDxfPoint;
    constructor Create(const AEntityType: string = ET_SOLID);
  end;

  { TDxfLine }

  TDxfLine = class(TDxfEntity)
    Thickness   : double;
    StartPoint  : TDxfPoint;
    EndPoint    : TDxfPoint;
    Extrusion   : TDxfPoint;
    constructor Create(const AEntityType: string = ET_LINE);
  end;

  { TDxfPolyLine }

  TDxfPolyLine = class(TDxfEntity)
    ObsFlag    : Integer;
    ElevPoint  : TDxfPoint;
    Thickness  : Double;
    PolyFlags  : Integer;
    StartWidth : Double;
    EndWidth   : Double;
    MCount     : Integer;
    NCount     : Integer;
    MDensity   : Integer;
    NDensity   : Integer;
    SurfType   : Integer;
    Extrusion  : TDxfPoint; //
    constructor Create(const AEntityType: string = ET_POLYLINE);
  end;

  { TDxfVertex }

  TDxfVertex = class(TDxfEntity)
    SubClass3  : string;
    Location   : TDxfPoint; // 10,20,30
    StartWidth : Double; // 40
    EndWidth   : Double; // 41
    Buldge     : Double; // 42
    Flags      : Integer; // 70
    TangentDir : Double; // 50
    PolyFace   : array [0..3] of Integer; // 71..74
    VertexIdx  : Integer; // 91
    constructor Create(const AEntityType: string = ET_VERTEX);
  end;

  { TDxfFileBlock }

  TDxfFileBlock = class(TDxfBlock)
  public
    _entities : TList;
    constructor Create;
    destructor Destroy; override;
    procedure AddEntity(ent: TDxfEntity);
  end;

  { TDxfFile }

  TDxfFile = class(TObject)
  public
    header   : TDxfHeader;
    tables   : TList;
    entities : TList; // of TDxfEntitie
    blocks   : TList; // of TDxfFileBlock
    constructor Create;
    destructor Destroy; override;
    function AddTable(const TableName: string): TDxfTable;
    procedure AddEntity(ent: TDxfEntity);
    function AddBlock: TDxfFileBlock;
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

procedure PtrAttr(const codeGroup: Integer; scanner: TDxfScanner; var pt: TDxfPoint);

function DxfSaveToString(dst: TDxfFile): string;
procedure DxfSaveToStream(const st: TStream; dst: TDxfFile; binFormat: Boolean);
procedure DxfSaveToFile(const st: string; dst: TDxfFile; binFormat: Boolean);
procedure DxfSave(wr: TDxfWriter; dst: TDxfFile);

implementation


{ TDxfFileBlock }

constructor TDxfFileBlock.Create;
begin
  _entities := TList.Create;
end;

destructor TDxfFileBlock.Destroy;
var
  i : integer;
begin
  for i:=0 to _entities.Count-1 do
    TObject(_entities[i]).Free;
  _entities.Free;
  inherited Destroy;
end;

procedure TDxfFileBlock.AddEntity(ent: TDxfEntity);
begin
  if not Assigned(ent) then Exit;
  _entities.Add(ent);
end;

{ TDxfVertex }

constructor TDxfVertex.Create(const AEntityType: string);
begin
  inherited Create(AEntityType)
end;

{ TDxfPolyLine }

constructor TDxfPolyLine.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfInsert }

constructor TDxfInsert.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
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
  blocks := TList.Create;
  entities := TList.Create;
end;

destructor TDxfFile.Destroy;
var
  i : integer;
begin
  for i:=0 to entities.Count-1 do
    TObject(entities[i]).Free;
  entities.Free;
  for i:=0 to blocks.Count-1 do
    TObject(blocks[i]).Free;
  blocks.Free;
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

procedure TDxfFile.AddEntity(ent: TDxfEntity);
begin
  if not Assigned(ent) then Exit;
  entities.Add(ent);
end;

function TDxfFile.AddBlock: TDxfFileBlock;
begin
  Result := TDxfFileBlock.Create;
  blocks.Add(Result);
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
          //if trim(p.EntityType) = '111' then begin
          //  p.scanner.GetLocationInfo(ln, ofs);
          //  writeln('odd entity type: ',ln,' ',ofs);
          //end;
          //ent := dst.AddEntity(p.EntityType);
          //ent.Handle := p.EntityHandle;
        end;

        prEntityAttr:
        begin
          //if Assigned(ent) then
          //  ent.SetAttr(p.scanner.CodeGroup, p.scanner);
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
    //writeln('  ',e.Name,' ',e.ClassName);
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
  //Result.Name := Name;
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
  st := TStringStream.Create('');
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
{
  WrStartSection(wr, NAME_ENTITIES);
  for i:=0 to dst.entities.Count-1 do begin
    e := TDxfEntity(dst.entities[i]);
    wr.WriteStr(CB_CONTROL, e.Name);
    WrHandle(wr, e.Handle);
    WrHandle(wr, e.OwnerHandle, CB_OWNERHANDLE);
  end;
  WrEndSection(wr);
  WrEndOfFile(wr);}
end;

{ TDxfSolid }

constructor TDxfSolid.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfCircle }

constructor TDxfCircle.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfLine }

constructor TDxfLine.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfEntity }

constructor TDxfEntity.Create(const AEntityType: string);
begin
  inherited Create;
  Self.EntityType := AEntityType;
end;


end.
