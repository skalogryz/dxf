unit dxfparseutils;

interface

uses
  dxfparse, dxftypes;

type
  TDxfPoint = record
    x,y,z : double;
  end;

  TDxfClass = record
    recName    : string;  // 1
    cppName    : string;  // 2
    appName    : string;  // 3
    ProxyFlags : integer; // 90
    InstCount  : integer; // 91
    WasProxy   : integer; // 280
    IsAnEntity : integer; // 281
  end;

  TDxfBlockEntity = record
    Handle       : string;  // 5
    appDefGroup  : string;  // 102
    Owner        : string;  //
    SubClass     : string;  // 100
    SpaceFlag    : int32;   // 67 -- optional!!!  (seen on Paper_Source)
    LayerName    : string;  // 8
    Subclass2    : string;  // 100
  end;

  TDxfBlock = record
    Ent        : TDxfBlockEntity;
    BlockName  : string;    // 2
    BlockFlags : integer;   // 70
    BasePoint  : TDxfPoint; // 10 20 30
    BlockName2 : string;    // 3
    XRef       : string;    // 1
    Descr      : string;    // 4
  end;

  TDxfBlockEnd = record
    Ent        : TDxfBlockEntity; // no special fields for EndBlock
  end;

  // todo:
  TDxfValue = record
    s   : string;
    i   : integer;
    i64 : int64;
    f   : double;
  end;

  TDxfValuesList = record
    count     : integer;
    vales     : array of TDxfValue;
  end;

  TDxfEntity = record
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
  end;

  TDxfLine = record
    ent         : TDxfEntity;
    Thickness   : double;
    StartPoint  : TDxfPoint;
    EndPoint    : TDxfPoint;
    Extrusion   : TDxfPoint;
  end;

  ParseMasterEntity = record
    entType : string;
    line    : TDxfLine;
  end;

procedure ParseClass(p: TDxfParser; var c: TDxfClass);
procedure ParseBlockEntity(p: TDxfParser; var e: TDxfBlockEntity);
procedure ParseBlock(p: TDxfParser; var b: TDxfBlock);
procedure ParseBlockEnd(p: TDxfParser; var b: TDxfBlockEnd);
procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X);
procedure ParseEntity(p: TDxfParser; var e: TDxfEntity);
procedure ParseLine(p: TDxfParser; var l: TDxfLine);

implementation

procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X);
begin
  pt.x := ConsumeFlt(p, XCodeGroup, 0);
  pt.y := ConsumeFlt(p, XCodeGroup + 10, 0);
  pt.z := ConsumeFlt(p, XCodeGroup + 20, 0);
end;

procedure ParseBlockEntity(p: TDxfParser; var e: TDxfBlockEntity);
begin
  e.Handle    := ConsumeStr(p, CB_HANDLE);

  e.appDefGroup := '';
  // todo: collect application defined codes
  if (p.scanner.CodeGroup = CB_APPDEFNAME) then begin
    p.Next; // skipping over the initial 102 "{blah"
    while p.scanner.CodeGroup <> CB_APPDEFNAME do begin // 102
      // consumeing initial 102
      //e.appDefGroup := e.appDefGroup + p.scanner.ValStr;
      p.Next;
    end;
    p.Next; // skipping over the trailing 102 "}"
  end;

  e.Owner     := ConsumeStr(p, CB_OWNERHANDLE);
  e.SubClass  := ConsumeStr(p, CB_SUBCLASS);
  e.SpaceFlag := ConsumeInt(p, CB_SPACEFLAG);
  e.LayerName := ConsumeStr(p, CB_LAYERNAME);
  e.Subclass2 := ConsumeStr(p, CB_SUBCLASS);
end;

procedure ParseBlock(p: TDxfParser; var b: TDxfBlock );
begin
  ParseBlockEntity(p, b.Ent);
  b.BlockName  := ConsumeStr(p, CB_NAME);
  b.BlockFlags := ConsumeInt(p, CB_FLAGS);
  ParsePoint(p, b.basePoint);
  b.BlockName2 := ConsumeStr(p, CB_BLOCKNAME);
  b.XRef       := ConsumeStr(p, CB_XREFPATH);
  b.Descr      := ConsumeStr(p, CB_DESCr);
end;

procedure ParseBlockEnd(p: TDxfParser; var b: TDxfBlockEnd);
begin
  ParseBlockEntity(p, b.Ent);
end;

procedure ParseClass(p: TDxfParser; var c: TDxfClass);
begin
  c.recName    := ConsumeStr(p, CB_DXFRECNAME );  {1  }
  c.cppName    := ConsumeStr(p, CB_CPPNAME    );  {2  }
  c.appName    := ConsumeStr(p, CB_APPANME    );  {3  }
  c.ProxyFlags := ConsumeInt(p, CB_PROXYFLAG  );  {90 }
  c.InstCount  := ConsumeInt(p, CB_INSTCOUNT  );  {91 }
  c.WasProxy   := ConsumeInt(p, CB_WASAPROXY  );  {280}
  c.IsAnEntity := ConsumeInt(p, CB_ISENTITY   );  {281}
end;

procedure ParseEntity(p: TDxfParser; var e: TDxfEntity);
begin
  e.EntityType    := ConsumeStr(p, 0);
  e.Handle        := ConsumeStr(p, 5);
  {appName       := ConsumeStr(p, 120);
  appValues     : TDxfValuesList;  // 120+custom}
  {ACAD_Reactors : TDxfValuesList;  // 120+330
  ACAD_XDict    : TDxfValuesList;  // 120+360}

  e.Owner        := ConsumeStr(p, 330);
  e.SubClass     := ConsumeStr(p, 100);
  e.SpaceFlag    := ConsumeInt(p, 67);   // 67 -- optional!!!  (seen on Paper_Source)
  e.AppTableLayout := ConsumeStr(p, 410);
  e.LayerName    := ConsumeStr(p, 8);
  e.LineTypeName := ConsumeStr(p, 6,   'BYLAYER');
  e.HardPtrId    := ConsumeStr(p, 347, 'BYLAYER');
  e.ColorNumber  := ConsumeStr(p, 62,  'BYLAYER');
  e.LineWidth    := ConsumeInt(p, 370);

  e.LineScale       := ConsumeFlt(p, 48);
  e.isVisible       := ConsumeInt(p, 60);
  e.ProxyBytesCount := ConsumeInt(p, 92);
  if (e.ProxyBytesCount>0) then begin
    //  e.ProxyGraph      := ConsumeInt array of byte; // 310s
  end;
  e.Color           := ConsumeInt(p, 420);
  e.ColorName       := ConsumeStr(p, 430);
  e.Transperancy    := ConsumeInt(p, 440);
  e.PoltObj         := ConsumeStr(p, 390);
  e.ShadowMode      := ConsumeInt(p, 284);

  //      : string;  // 347
  //  ColorNumber  : string;  // 62
  e.Subclass2    := ConsumeStr(p, 100);
end;

procedure ParseLine(p: TDxfParser; var l: TDxfLine);
begin
  ParseEntity(p, l.ent);
  l.Thickness := ConsumeFlt(p, 39);
  ParsePoint(p, l.StartPoint, CB_X);
  ParsePoint(p, l.StartPoint, CB_X_ENDPOINT);
  ParsePoint(p, l.StartPoint, CB_X_EXTRUSION);
end;


end.
