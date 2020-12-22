unit dxffileutils;

interface

uses
  Types, SysUtils, Classes,
  dxftypes, dxfclasses, HashStrings;

const
  DEFAULT_LAYER = '0';  // this is Layer Name
  DEFAULT_LINESTYLE = 'CONTINUOUS';

procedure AddDefaultObjects(dxf: TDxfFile);
procedure AddDefaultBlocks(dxf: TDxfFile);

procedure NormalizeBlocks(dxf : TDxfFile);

procedure AddDefaultTables(dxf: TDxfFile);
procedure AddDefaultClasses(dxf: TDxfFile);

// UpdateHeader indicates if "HandleSeed" of the dxf file should be updated
// to include the latest "filled" handle
procedure FillHandles(dxf: TDxfFile; UpdateHeader: Boolean = true);

function AddLine(afile: TDxfFile; const p1, p2: TPoint; const ALayerName: string = DEFAULT_LAYER): TDxfLine;
function AddPolyLine(afile: TDxfFile; const p: array of TPoint; const ALayerName: string = DEFAULT_LAYER): TDxfPolyLine;
function AddEndSeq(afile : TDxfFile; const ALayerName: string = DEFAULT_LAYER): TDxfSeqEnd;

function AddLine2d(afile: TDxfFile; const p1, p2: TDxfPoint; const ALayerName: string = DEFAULT_LAYER): TDxfLine;

procedure PointToDfxPoint(const src: TPoint; var dst: TDxfPoint; z: double = 0);

// updates "_Owner" and "_RefId" to the actual reference
// based on Handle and Owner values.
// Should be used after loading file
procedure HandlesToLinks(dxf: TDxfFile);

// updates "Owner" and "RefID" based on the r
// Should be used before saving a file (after manual manipulation)
// Handles must be populated prior to calling this procedure
// FillHandles() can be used!
procedure LinksToHandles(dxf: TDxfFile);

procedure GatherDxfBase(dxf: TDxfFile; dst: TList);

const
  ZERO_HANDLE = '0';

function FindByHandle(dxf: TDxfFile; const h: string): TDxfBase;
function FindTableByHandle(dxf: TDxfFile; const h: string): TDxfTable;
function FindTableByName(dxf: TDxfFile; const n: string): TDxfTable;
function FindDictByHandle(dxf: TDxfFile; const h: string): TDxfDictionary;
procedure DeleteObject(dxf: TDxfFile; const h: string);

procedure DefaultHeader(var h: TDxfHeader);

function IntToHandle(it: integer): string;

function AllocLayer(dst: TDxfTable; const Name: string;
  const DefLineType: string;
  ColorNum: Integer = 7): TDxfLayerEntry;

procedure InitFingerPrintId(var h: TDxfHeader);
procedure InitVersionId(var h: TDxfHeader);
procedure UpdateVersionIds(var h: TDxfHeader);

implementation

procedure AddDefaultBlocks(dxf: TDxfFile);
var
  b : TDxfFileBlock;
begin
  b := dxf.AddBlock;
  b.BlockName := '*Model_Space';
  b.BlockName2 := '*Model_Space';
  b.LayerName := '0';
  b._blockEnd.LayerName := '0';

  b := dxf.AddBlock;
  b.BlockName := '*Paper_Space';
  b.BlockName2 := '*Paper_Space';
  b.LayerName := '0';
  b._blockEnd.LayerName := '0';

end;

procedure NormalizeBlocks(dxf : TDxfFile);
var
  i : integer;
  bf : TDxfFileBlock;
begin
  for i:=0 to dxf.blocks.Count-1 do begin
    bf := TDxfFileBlock(dxf.blocks[i]);
    // block end is owned by the stating block
    bf._blockEnd.Owner := bf.Handle;
  end;
end;

procedure AddDefaultClasses(dxf: TDxfFile);
var
  c : TDxfClass;
begin
  if not Assigned(dxf) then Exit;

  c := dxf.AddClass;   
  c.recName := 'ACDBDICTIONARYWDFLT';
  c.cppName := 'AcDbDictionaryWithDefault';
  c.appName := APPName_ObjectDBX_Cls;

  c := dxf.AddClass;
  c.recName := 'DICTIONARYVAR';
  c.cppName := 'AcDbDictionaryVar';
  c.appName := APPName_ObjectDBX_Cls;
  c.ProxyFlags := 2047;

  c := dxf.AddClass;
  c.recName := 'ACDBPLACEHOLDER';
  c.cppName := 'AcDbPlaceHolder';
  c.appName := APPName_ObjectDBX_Cls;

  c := dxf.AddClass;
  c.recName := 'LAYOUT';
  c.cppName := 'AcDbLayout';
  c.appName := APPName_ObjectDBX_Cls;

  c := dxf.AddClass;
  c.recName := 'TABLESTYLE';
  c.cppName := 'AcDbTableStyle';
  c.appName := APPName_ObjectDBX_Cls;
  c.ProxyFlags := 4095;
end;

function AddLine(afile: TDxfFile; const p1, p2: TPoint; const ALayerName: string): TDxfLine;
begin
  Result:=TDxfLine.Create;
  PointToDfxPoint(p1, Result.StartPoint);
  PointToDfxPoint(p2, Result.EndPoint);
  Result.LayerName := ALayerName;
  Result.ColorNumber := CECOLOR_BYLAYER;
  afile.AddEntity(Result);
end;

function AddLine2d(afile: TDxfFile; const p1, p2: TDxfPoint; const ALayerName: string = DEFAULT_LAYER): TDxfLine;
begin
  Result:=TDxfLine.Create;
  Result.StartPoint := p1;
  Result.EndPoint := p2;
  Result.LayerName := ALayerName;
  Result.ColorNumber := CECOLOR_BYLAYER;
  afile.AddEntity(Result);
end;

function AddPolyLine(afile: TDxfFile; const p: array of TPoint; const ALayerName: string = DEFAULT_LAYER): TDxfPolyLine;
var
  i : integer;
  v : TDxfVertex;
begin
  Result := TDxfPolyLine.Create;
  Result.LayerName := ALayerName;
  afile.AddEntity(Result);
  for i:=0 to length(p)-1 do begin
    v := TDxfVertex.Create;
    v.LayerName := AlayerName;
    PointToDfxPoint(p[i], v.Location);
    afile.AddEntity(v);
  end;
  AddEndSeq(afile, ALayerName);
end;

function AddEndSeq(afile : TDxfFile; const ALayerName: string = DEFAULT_LAYER): TDxfSeqEnd;
begin
  Result := TDxfSeqEnd.Create;
  Result.LayerName := ALayerName;
  afile.AddEntity( Result );
end;

procedure PointToDfxPoint(const src: TPoint; var dst: TDxfPoint; z: double);
begin
  dst.x := src.X;
  dst.y := src.Y;
  dst.z := z;
end;

function HandleToInt(const it: string): Integer;
var
  err : integer;
begin
  err := 0;
  Result := 0;
  Val('$'+it, Result, err);
  if err <> 0 then Result := 0;
end;

function IntToHandle(it: integer): string;
var
  i : integer;
begin
  if it = 0 then begin
    Result := ZERO_HANDLE;
    Exit;
  end;
  Result := IntToHex(it, 16);
  i:=1;
  while (i <= length(Result)) and (Result[i]='0') do inc(i);
  Result := Copy(Result, i, length(Result));
end;

procedure FillHandles(dxf: TDxfFile; UpdateHeader: Boolean);
var
  i : integer;
  e : TDxfBase;
  h : integer;
  h2 : integer;
  l : TList;
begin
  h:=32;
  l:=TList.Create;
  try
    GatherDxfBase(dxf, l);

    // making sure the seed is the latest handle
    for i:=0 to l.Count-1 do begin
      e := TDxfBase(l[i]);
      if e.Handle<>'' then begin
        h2 := HandleToInt(e.Handle);
        if h2 > h then h:=h2+1; // try the next!
      end;
    end;

    for i:=0 to l.Count-1 do begin
      e := TDxfBase(l[i]);
      if e.Handle = '' then begin
        e.Handle:=IntToHandle(h);
        inc(h);
      end;
    end;

    if UpdateHeader then
      dxf.header.Base.NextHandle := IntToHandle(h);
  finally
    l.Free;
  end;
end;

procedure AddDefaultObjects(dxf: TDxfFile);
var
  root : TDxfDictionary;

  function AllocEntryDictionary(const EntryName: string): TDxfDictionary;
  var
    e    : TDxfDictionaryEntry;
    d    : TDxfDictionary;
  begin
    e:=root.AddEntry;
    e.EntryName := EntryName;
    d := TDxfDictionary.Create;
    d._Owner := root;
    dxf.objects.Add(d);
    e._Ref := d;
    Result := d;
  end;

begin
  root := TDxfDictionary.Create;
  dxf.objects.Add(root);

  AllocEntryDictionary('ACAD_COLOR');
  AllocEntryDictionary('ACAD_LAYOUT');
  AllocEntryDictionary('ACAD_MATERIAL');
  AllocEntryDictionary('ACAD_MLINESTYLE');
  AllocEntryDictionary('ACAD_PLOTSETTINGS');
  AllocEntryDictionary('ACAD_PLOTSTYLENAME'); // ACDBDICTIONARYWDFLT (D4) "" ACDBPLACEHOLDER (D5)
  AllocEntryDictionary('ACAD_TABLESTYLE');
  AllocEntryDictionary('ACDBHEADERROUNDTRIPXREC');
  AllocEntryDictionary('AcDbVariableDictionary');
end;

procedure HandlesToLinks(dxf: TDxfFile);
var
  h   : THashedStringList;
  i   : integer;
  j   : integer;
  b   : TDxfBase;
  own : TDxfBase;
begin
  h := THashedStringList.Create;
  try
    for i:=0 to dxf.objects.Count-1 do begin
      b := TDxfBase(dxf.objects[i]);
      h.AddObject(b.Handle, b);
    end;
    for i:=0 to dxf.entities.Count-1 do begin
      b := TDxfBase(dxf.objects[i]);
      h.AddObject(b.Handle, b);
    end;

    for i:=0 to h.Count-1 do begin
      b := TDxfBase(h.Objects[i]);
      if (b._Owner = nil) then begin
        j := h.IndexOf(b.Owner);
        if j>=0 then
          b._Owner := TDxfBase(h.Objects[j]);
      end;
    end;

  finally
    h.Free;
  end;

end;

procedure LinksToHandles(dxf: TDxfFile);
var
  i, j  : integer;
  blist : TList;
  b     : TDxfBase;
  d     : TDxfDictionary;
  e     : TDxfDictionaryEntry;
begin
  blist := TList.Create;
  try
    GatherDxfBase(dxf, blist);
    for i := 0 to blist.Count-1 do begin
      b := TDxfBase(blist[i]);
      if Assigned(b._Owner) and (b.Owner = '') then
        b.Owner := b._Owner.Handle
      else if not Assigned(b._Owner) and (b.Owner = '') then
        b.Owner := ZERO_HANDLE;

      if (b is TDxfDictionary) then begin
        d := TDxfDictionary(b);
        for j:=0 to d.Entries.Count-1 do begin
          e := TDxfDictionaryEntry(d.Entries[j]);
          if Assigned(e._Ref) and (e.RefId = '') then
            e.refId := e._Ref.Handle;
        end;
      end;
    end;
  finally
    blist.Free;
  end;

end;

procedure GatherDxfBase(dxf: TDxfFile; dst: TList);
var
  i : integer;
  b : TDxfBase;
  j : integer;
  t : TDxfTable;
begin
  if not Assigned(dxf) or not Assigned(dst) then Exit;
  for i:=0 to dxf.tables.Count-1 do begin
    b := TDxfBase(dxf.tables[i]);
    dst.Add(b);
    t := TDxfTable(b);
    for j := 0 to t.Count-1 do
      dst.Add(t.Entry[j]);
  end;
  for i:=0 to dxf.objects.Count-1 do begin
    b := TDxfBase(dxf.objects[i]);
    dst.Add(b);
  end;
  for i:=0 to dxf.entities.Count-1 do begin
    b := TDxfBase(dxf.entities[i]);
    dst.Add(b);
  end;
  for i:=0 to dxf.blocks.Count-1 do begin
    b := TDxfBase(dxf.blocks[i]);
    dst.Add(b);
    dst.Add(TDxfFileBlock(b)._blockEnd);
  end;
end;

function AllocLType(dst: TDxfTable; const Name: string; const Desc: string): TDxfLTypeEntry;
const
  DEF_ALIGN_CODE = 65;
begin
  Result := TDxfLTypeEntry.Create;
  Result.EntryType := TE_LTYPE;
  Result.SubClass  := 'AcDbSymbolTableRecord';
  Result.SubClass2 := 'AcDbLinetypeTableRecord';
  Result._Owner := dst;
  dst.AddItem(Result);
  Result.LineType := Name;
  Result.Descr := Desc;
  Result.AlignCode := DEF_ALIGN_CODE;
end;

function AllocLayer(dst: TDxfTable; const Name: string;
  const DefLineType: string;
  ColorNum: Integer = 7): TDxfLayerEntry;
begin
  Result := TDxfLayerEntry.Create;
  Result.EntryType := TE_LAYER;
  Result.SubClass  := 'AcDbSymbolTableRecord';
  Result.SubClass2 := 'AcDbLayerTableRecord';
  Result._Owner := dst;
  dst.AddItem(Result);
  Result.LayerName := Name;
  Result.LineType := DefLineType;
  Result.ColorNum := ColorNum;
  Result.Lineweight := Lineweight_Standard;
end;

function AllocVPort(owner: TDxfTable; const VPortName: string): TDxfVPortEntry;
begin
  Result := TDxfVPortEntry.Create;
  Result.EntryType := TE_VPORT;
  Result.SubClass := CLS_AcDbSymbolTableRecord;
  Result.SubClass2 := CLS_AcDbViewportTableRecord;
  Result.ViewName := VPortName;
  Result.LeftLow := DxfPoint(0,0);
  Result.UpRight := DxfPoint(1,1);
  Result.ViewCenter := DxfPoint(355,50);
  Result.SnapBase := DxfPoint(0,0);
  Result.SnapSpace := DxfPoint(1,1);
  Result.GridSpace := DxfPoint(0,0);
  Result.ViewDir   := DxfPoint(0,0,1);
  Result.ViewTarget:= DxfPoint(0,0,0);

  Result._40 := 455;
  Result._41 := 2.5;
  Result.LensLen := 50;
  Result.FrontClipOfs  := 0;
  Result.BackClipOfs   := 0;
  Result.RotateAngle   := 0;
  Result.TwistAngle    := 0;
  Result.ViewMode      := 0;
  Result.CircleSides   := 10000;
  Result._73 := 0;
  Result._75 := 0;      
  Result._76 := 0;
  Result._77 := 0;      
  Result._78 := 0;      
  Result._65 := 1;
  Result.UCSOrigin := DxfPoint(0,0,0);
  Result.UCSXAxis := DxfPoint(1,0,0);
  Result.UCSYAxis := DxfPoint(0,1,0);
  Result.OrthType      := 0;

  if Assigned(Owner) then Owner.AddItem(Result);
end;

procedure AddDefaultTables(dxf: TDxfFile);
var
  t : TDxfTable;
  ap : TDxfAppIdEntry;
  br : TDxfBlockRecordEntry;
begin
  t := TDxfTable.Create;
  t.Name := 'VPORT';
  AllocVPort(t, '*Active');
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'LTYPE';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);
  AllocLType(t, 'ByBlock','');
  AllocLType(t, 'ByLayer','');
  AllocLType(t, DEFAULT_LINESTYLE,'Solid line');

  t := TDxfTable.Create;
  t.Name := 'LAYER';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);
  AllocLayer(t, '0', 'CONTINUOUS');

  t := TDxfTable.Create;
  t.Name := 'STYLE';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'VIEW';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'UCS';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'APPID';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

  ap := TDxfAppIdEntry.Create;
  ap.EntryType :='APPID';
  ap.SubClass := 'AcDbSymbolTableRecord';
  ap.AppData:='ACAD';
  ap.Flags:=0;
  ap.SubClass2 := 'AcDbRegAppTableRecord';
  ap._Owner := t;
  t.AddItem(ap);

  t := TDxfTable.Create;
  t.Name := 'DIMSTYLE';
  t.SubClass := 'AcDbSymbolTable';
  t.SubClass2 := 'AcDbDimStyleTable';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'BLOCK_RECORD';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);
  br := TDxfBlockRecordEntry.Create;
  br.EntryType := 'BLOCK_RECORD';
  br.SubClass := 'AcDbSymbolTableRecord';
  br.BlockName := '*Model_Space';
  br.SubClass2 := 'AcDbBlockTableRecord';
  br.LayoutId := '0';
  br._Owner := t;
  t.AddItem(br);

  br := TDxfBlockRecordEntry.Create;
  br.EntryType := 'BLOCK_RECORD';
  br.SubClass := 'AcDbSymbolTableRecord';
  br.BlockName := '*Paper_Space';
  br.SubClass2 := 'AcDbBlockTableRecord';
  br.LayoutId := '0'; // layer name
  br._Owner := t;
  t.AddItem(br);

end;

function FindByHandle(dxf: TDxfFile; const h: string): TDxfBase;
var
  f : TList;
  i : integer;
begin
  f := TList.Create;
  try
    writeln('search start: ', h);
    GatherDxfBase(dxf, f);
    for i:=0 to f.Count-1 do begin
      Result := TDxfBase(f[i]);
      writeln('compare: ', Result.Handle ,' / ', h);
      if Result.Handle = h then Exit;
    end;
    Result := nil;
  finally
    f.Free;
  end;
end;

function FindTableByHandle(dxf: TDxfFile; const h: string): TDxfTable;
var
  b : TDxfBase;
begin
  b := FindByHandle(dxf, h);
  if not (b is TDxfTable)
    then Result := nil
    else Result := TDxfTable(b);
end;

function FindTableByName(dxf: TDxfFile; const n: string): TDxfTable;
var
  i : integer;
begin
  for i := 0 to dxf.tables.Count-1 do
    if TDxfTable(dxf.tables[i]).Name = n then begin
      Result := TDxfTable(dxf.tables[i]);
      Exit;
    end;
  Result := nil;
end;

function FindDictByHandle(dxf: TDxfFile; const h: string): TDxfDictionary;
var
  b : TDxfBase;
begin
  b := FindByHandle(dxf, h);
  if not (b is TDxfDictionary)
    then begin
      writeln('lame lame: ', h);
      Result := nil
    end
    else Result := TDxfDictionary(b);
end;

procedure DeleteObject(dxf: TDxfFile; const h: string);
var
  i  : integer;
  ob : TDxfObject;
begin
  for i:=dxf.objects.Count-1 downto 0 do begin
    ob := TDxfObject(dxf.objects[i]);
    if ob.Handle = h then begin
      ob.Free;
      writeln('deleting: ' ,i,' ',h);
      dxf.objects.Delete(i);
    end;
  end;
end;

procedure DefaultHeader(var h: TDxfHeader);
begin
  h.acad.Version := ACAD_VER_2000;
  h.acad.MaintVer := 20; // default maintenance version
  h.acad.isExtNames := 1;
  h.Base.CodePage := DEFAULT_CODEPAGE;
  H.BASE.ExtLowLeft.x:=-2.5;
  H.BASE.ExtLowLeft.Y:=-2.5;
  H.BASE.ExtUpRight.x:=+2.5;
  H.BASE.ExtUpRight.Y:=+2.5;
  H.BASE.LimUpRight.x:=420;
  H.BASE.LimUpRight.Y:=297;
  h.base.isRegen := 1;
  h.base.isFill := 1;
  h.base.LineTypeScale := 1;
  h.base.AttrVisMode := 1;
  h.Sel.TextStyle := DEFAULT_TEXTSTYLE;  // this must be non-empty valid style!

  h.sel.Layer := '0';

  h.Base.TextHeight := 0.2;
  h.Base.TraceWidth := 0.05;
  h.Sel.EntLineType := 'ByLayer';
  h.Sel.EntLineTypeScale := 1;
  h.Sel.EntColor := CECOLOR_BYLAYER;


  h.Dim.Scale      := 1;      // $DIMSCALE
  h.Dim.ArrowSize  := 0.18;   // $DIMASZ
  h.Dim.ExtLineOfs := 0.0625; // $DIMEXO
  h.Dim.DimLineInc := 0.38;   // ($DIMDLI)
  h.Dim.ExtLineExt := 0.18;   // ($DIMEXE)
  h.Dim.TextHeight := 0.18;   // ($DIMTXT)
  h.Dim.CenterSize := 0.09;   // ($DIMCEN)
  h.Dim.isTextIns  := 1;
  h.Dim.isTextOut  := 1;
  h.Dim.isAssocDim  := 1; // ($DIMASO)
  h.Dim.isRecompDim := 1; // ($DIMSHO)
  h.Dim.AltDec      := 2; // ($DIMALTD)
  h.Dim.AltScale    := 25.4;  // ($DIMALTF)
  h.Dim.LinearScale := 1.0;   // $DIMLFAC
  h.Dim.StyleName   := DEFAULT_TEXTSTYLE;
  h.Dim.DispTolerance := 1.0;  // $DIMTFAC
  h.Dim.LineGap       := 0.09; // $DIMGAP
  h.Dim.VertJustTol   := 1;    // ($DIMTOLJ)
  h.Dim.DecPlacesPrim := 4;    // ($DIMDEC)
  h.Dim.UnitsFormat   := 2;    // ($DIMALTU)
  h.Dim.DecPlacesAltUnit := 2; // ($DIMALTTD)
  h.Dim.TextStyle        := DEFAULT_TEXTSTYLE;  // ($DIMTXSTY)
  h.Dim.DecSeparator    := 46; // ($DIMDSEP)
  h.Dim.TextArrowPlace  := 3; // ($DIMATFIT)
  h.Dim.Units := LenUnitFmt_Decimal;  // ($DIMLUNIT)
  h.Dim.LineWeight    := Lineweight_ByLayer; // ($DIMLWD)
  h.Dim.LineWeightExt := Lineweight_ByLayer; // ($DIMLWE)
  h.Dim.DecPlacesOther := 4; // ($DIMTDEC)

  h.Base.DistFormat  := LenUnitFmt_Decimal; // $LUNITS
  h.base.DistPrec    := 4;  // $LUPREC
  h.base.SketchInc   := 0.1;    // ($SKETCHINC) 40   Sketch record increment

  h.base.MenuName := '.';
  h.base.SplineFrame := 0;
  h.base.SplineCurvType := 6;
  h.Base.LineSegments := 8;  // ($SPLINESEGS)  Number of line segments per spline patch

  h.Base.MeshCount1 := 6;  // ($SURFTAB1)   70  Number of mesh tabulations in first direction
  h.Base.MeshCount2 := 6;  // ($SURFTAB2)   70  Number of mesh tabulations in second direction
  h.Base.SurfType := 6;
  h.Base.SurfType := 6;
  h.Base.SurfDensityM := 6; // ($SURFU)      70  Surface density (for PEDIT Smooth) in M direction
  h.Base.SurfDensityN := 6; // ($SURFV)      70  Surface density (for PEDIT Smooth) in N direction

  h.Ucs.Base := '';
  h.Ucs.Name := '';
  h.Ucs.Origin := DxfPoint(0,0,0);
  h.Ucs.XDir := DxfPoint(1,0,0);
  h.Ucs.YDir := DxfPoint(0,1,0);
  h.Ucs.OrthoRef := '';
  h.Ucs.OrthoView := 0;
  h.Ucs.OriginTop := DxfPoint(0,0,0);
  h.Ucs.OriginBack   := DxfPoint(0,0,0);
  h.Ucs.OriginBottom := DxfPoint(0,0,0);
  h.Ucs.OriginFront  := DxfPoint(0,0,0);
  h.Ucs.OriginLeft   := DxfPoint(0,0,0);
  h.Ucs.OriginRight  := DxfPoint(0,0,0);

  h.PUcs.Base := '';
  h.PUcs.Name := '';
  h.PUcs.Origin := DxfPoint(0,0,0);
  h.PUcs.XDir := DxfPoint(1,0,0);
  h.PUcs.YDir := DxfPoint(0,1,0);
  h.PUcs.OrthoRef := '';
  h.PUcs.OrthoView := 0;
  h.PUcs.OriginTop := DxfPoint(0,0,0);
  h.PUcs.OriginBack   := DxfPoint(0,0,0);
  h.PUcs.OriginBottom := DxfPoint(0,0,0);
  h.PUcs.OriginFront  := DxfPoint(0,0,0);
  h.PUcs.OriginLeft   := DxfPoint(0,0,0);
  h.PUcs.OriginRight  := DxfPoint(0,0,0);

  h.Base.isWorldView  := 1; // $WORLDVIEW
  h.Base.ShadeEdge    := ShadeEdge_Color; // $SHADEDGE
  h.Base.ShadeDiffuse := 70; // $SHADEDIF
  h.Base.isTileMode   := 1;  // $TILEMODE
  h.Base.MaxViewPorts := 64; // $MAXACTVP

  h.Base.PaperLimUpRight := DxfPoint(12, 9);
  h.Base.isRetainXRefVis := 1;
  h.Base.PaperLineScaling := 1;
  h.Base.SpaceTreeDepth := 3020;
  h.Sel.MultiLineStyle := DEFAULT_TEXTSTYLE;
  h.Sel.MultiLineScale := 1.0;
  h.Base.isProxyImageSave := 1;
  h.Base.NewObjLineWeight := Linewieght_ByBlock;
  h.Base.DefaultUnits := UNITS_NO;
  h.Base.isInPlaceEditin := 1;
  h.base.isColorDepmode := 1;


  {
  h.Sel.EntLineType := 'ByLayer'; // reference to LType
  h.Dim.isTextOut         := 1;     // ($DIMTOH)
  h.Dim.isTextAbove       := 1;     // ($DIMTAD)
  h.Dim.SupZeros          := 8; // ($DIMZIN)
  }
{h.Dim.ArrowBlock        : string;  // ($DIMBLK)
h.Dim.Suffix            : string;  // ($DIMPOST)
h.Dim.AltSuffix         : string;  // ($DIMAPOST)
h.Dim.isUseAltUnit      : integer; // ($DIMALT)
h.Dim.LinearScale       : double;  // ($DIMLFAC)
h.Dim.isTextOutExt      : Integer; // ($DIMTOFL)
h.Dim.TextVertPos       : double;  // ($DIMTVP)
h.Dim.isForceTextIns    : Integer; // ($DIMTIX)
h.Dim.isSuppOutExt      : Integer; // ($DIMSOXD)
h.Dim.isUseSepArrow     : Integer; // ($DIMSAH)
h.Dim.ArrowBlock1       : string;  // ($DIMBLK1)
h.Dim.ArrowBlock2       : string;  // ($DIMBLK2)

h.Dim.LineColor         : integer; // ($DIMCLRD)
h.Dim.ExtLineColor      : integer; // ($DIMCLRE)
h.Dim.TextColor         : integer; // ($DIMCLRT)
h.Dim.DispTolerance     : double;  // ($DIMTFAC)
h.Dim.LineGap           : double;  // ($DIMGAP)
h.Dim.HorzTextJust      : integer; // ($DIMJUST)
h.Dim.isSuppLine1       : Integer; // ($DIMSD1)
h.Dim.isSuppLine2       : Integer; // ($DIMSD2)
h.Dim.ZeroSupTol        : Integer; // ($DIMTZIN)
h.Dim.ZeroSupAltUnitTol : Integer; // ($DIMALTZ)
h.Dim.ZeroSupAltTol     : Integer; // ($DIMALTTZ)
h.Dim.isEditCursorText  : Integer; // ($DIMUPT)
h.Dim.AngleFormat       : Integer; // ($DIMAUNIT)
h.Dim.AngleDecPlaces    : Integer; // ($DIMADEC)
h.Dim.RoundValAlt       : double;  // ($DIMALTRND)
h.Dim.ZeroSupAngUnit    : Integer; // ($DIMAZIN)
h.Dim.ArrowBlockLead    : string;  // ($DIMLDRBLK)
h.Dim.TextMove          : Integer; // ($DIMTMOVE)
h.Dim.UnitFrac          : Integer; // DIMFRAC
h.Dim.ArrowBlockId      : string;  // ($DIMBLK1)
h.Dim.ArrowBlockId1     : string;  // ($DIMBLK1)
h.Dim.ArrowBlockId2     : string;  // ($DIMBLK2)
// oboslete
__Units: Integer;          // ($DIMUNIT)    Se
__TextArrowPlace: Integer; // ($DIMFIT)    Con}
end;

procedure InitFingerPrintId(var h: TDxfHeader);
var
  g : TGuid;
begin
  CreateGUID(g);
  h.Base.FingerPrintGuid := GUIDToString(g);
end;

procedure InitVersionId(var h: TDxfHeader);
var
  g : TGuid;
begin
  CreateGUID(g);
  h.Base.VersionGuild := GUIDToString(g);
end;

procedure UpdateVersionIds(var h: TDxfHeader);
begin
  if h.Base.FingerPrintGuid = '' then InitFingerPrintId(h);
  InitVersionId(h);
end;

end.
