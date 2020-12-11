unit dxfclasses;

interface

uses
  Classes, SysUtils, dxftypes, dxfparse, dxfwrite;

type
  TDxfPoint = record
    x,y,z: double;
  end;

// todo: move it to dxf parseutils
  TDxfSpacingHeader = record
    Base         : string;     // $*BASE          9 $UCSBASE 2                                9 $PUCSBASE 2
    Name         : string;     // $*NAME          9 $UCSNAME 2                                9 $PUCSNAME 2
    Origin       : TDxfPoint;  // $*ORG           9 $UCSORG 10 0.0 20 0.0 30 0.0              9 $PUCSORG 10 0.0 20 0.0 30 0.0
    OriginBack   : TDxfPoint;  // $*ORGBACK       9 $UCSXDIR 10 1.0 20 0.0 30 0.0             9 $PUCSXDIR 10 1.0 20 0.0 30 0.0
    OriginBottom : TDxfPoint;  // $*ORGBOTTOM     9 $UCSYDIR 10 0.0 20 1.0 30 0.0             9 $PUCSYDIR 10 0.0 20 1.0 30 0.0
    OriginFront  : TDxfPoint;  // $*ORGFRONT      9 $UCSORTHOREF 2                            9 $PUCSORTHOREF 2
    OriginLeft   : TDxfPoint;  // $*ORGLEFT       9 $UCSORTHOVIEW 70    0                     9 $PUCSORTHOVIEW 70    0
    OriginRight  : TDxfPoint;  // $*ORGRIGHT      9 $UCSORGTOP 10 0.0 20 0.0 30 0.0           9 $PUCSORGTOP 10 0.0 20 0.0 30 0.0
    OriginTop    : TDxfPoint;  // $*ORGTOP        9 $UCSORGBOTTOM 10 0.0 20 0.0 30 0.0        9 $PUCSORGBOTTOM 10 0.0 20 0.0 30 0.0
    OrthoRef     : string;     // $*ORTHOREF      9 $UCSORGLEFT 10 0.0 20 0.0 30 0.0          9 $PUCSORGLEFT 10 0.0 20 0.0 30 0.0
    OrthoView    : Integer;    // $*ORTHOVIEW     9 $UCSORGRIGHT 10 0.0 20 0.0 30 0.0         9 $PUCSORGRIGHT 10 0.0 20 0.0 30 0.0
    XDir         : TDxfPoint;  // $*XDIR          9 $UCSORGFRONT 10 0.0 20 0.0 30 0.0         9 $PUCSORGFRONT 10 0.0 20 0.0 30 0.0
    YDir         : TDxfPoint;  // $*YDIR          9 $UCSORGBACK 10 0.0 20 0.0 30 0.0          9 $PUCSORGBACK 10 0.0 20 0.0 30 0.0
  end;

  TDxfAcadHeader = record
    Version   : string;     // 9 $ACADVER        1 AC1015
    MaintVer  : integer;    // 9 $ACADMAINTVER  70 20
  end;

  TDxfUserHeader = record
    UserI1: Integer;   // 9 $USERI1 70    0
    UserI2: Integer;   // 9 $USERI2 70   0
    UserI3: Integer;   // 9 $USERI3 70   0
    UserI4: Integer;   // 9 $USERI4 70    0
    UserI5: Integer;   // 9 $USERI5 70    0
    UserRR1: double;   // 9 $USERR1 40 0.0
    UserRR2: double;   // 9 $USERR2 40 0.0
    UserRR3: double;   // 9 $USERR3 40 0.0
    UserRR4: double;   // 9 $USERR4 40 0.0
    UserRR5: double;   // 9 $USERR5 40 0.0
  end;

  // current editor settings
  TDxfCurrentSettings = record
    Layer               : string;  // 9 $CLAYER         8 EL_DEVICE  // Current layer name
// 9 $CMLSTYLE 2 Standard       // Current multiline style name
// 9 $CMLJUST 70    0     // Current multiline justification:
// 9 $CMLSCALE 40 1.0  // Current multiline scale
// 9 $ELEVATION 40 0.0 // Current elevation set by ELEV command
// 9 $THICKNESS 40 0.0      // Current thickness set by ELEV command
// 9 $PELEVATION 40 Current paper space elevation
// 9 $TEXTSTYLE      7 STANDARD  // Current text style name
    EntityColor         : Integer; // 9 $CECOLOR       62  256       // Current entity color number:  0 = BYBLOCK; 256 = BYLAYER
    EntityLineTypeScale : Double;  // 9 $CELTSCALE     40 1.0
    //     9 $XEDIT 290    1 // Controls whether the current drawing can be edited inplace when being referenced by another drawing.
  end;

  TDxfHeader = class(TObject)
    acad : TDxfAcadHeader;
    Ucs  : TDxfSpacingHeader;
    PUcs : TDxfSpacingHeader; // Paper space
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
    ColorNumber     : Integer;  // 62
    LineWidth       : Integer; // 370
    LineScale       : Double;  // 48
    isHidden        : Integer; // 60
    ProxyBytesCount : Integer; // 92
    ProxyGraph      : array of byte; // 310s
    Color           : Integer; // 420
    ColorName       : string;  // 430
    Transperancy    : Integer; // 440
    PlotObj         : string;  // 390
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
    _blockEnd : TDxfBlockEnd;
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

procedure DxfFileDump(dxf: TDxfFile);

procedure PtrAttr(const codeGroup: Integer; scanner: TDxfScanner; var pt: TDxfPoint);

const
  DefZeroPoint : TDxfPoint = (x:0; y:0; z:0);
  DefExtrusionPoint : TDxfPoint = (x:0; y:0; z:1);

const
  DEF_EPSILON = 0.0000001;

function isSamePoint(const a,b: TDxfPoint; epsilon: Double = DEF_EPSILON): Boolean;
function isSameDbl(a,b: double; epsilon: Double = DEF_EPSILON): Boolean; inline;

implementation

function isSameDbl(a,b: double; epsilon: Double): Boolean; inline;
begin
  Result := (a=b) or (Abs(a-b)<epsilon);
end;

function isSamePoint(const a,b: TDxfPoint; epsilon: Double): Boolean;
begin
  Result:= isSameDbl(a.x,b.x, epsilon)
    and isSameDbl(a.y,b.y, epsilon)
    and isSameDbl(a.z,b.z, epsilon);
end;

{ TDxfFileBlock }

constructor TDxfFileBlock.Create;
begin
  inherited Create;
  _entities := TList.Create;
  _blockEnd := TDxfBlockEnd.Create;
end;

destructor TDxfFileBlock.Destroy;
var
  i : integer;
begin
  for i:=0 to _entities.Count-1 do
    TObject(_entities[i]).Free;
  _entities.Free;
  _blockEnd.Free;
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
