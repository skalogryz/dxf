unit dxffileutils;

interface

uses
  Types, SysUtils, Classes,
  dxftypes, dxfclasses, HashStrings;

procedure AddDefaultObjects(dxf: TDxfFile);
procedure AddDefaultBlocks(dxf: TDxfFile);

procedure NormalizeBlocks(dxf : TDxfFile);

procedure AddDefaultTables(dxf: TDxfFile);
procedure AddDefaultClasses(dxf: TDxfFile);

// UpdateHeader indicates if "HandleSeed" of the dxf file should be updated
// to include the latest "filled" handle
procedure FillHandles(dxf: TDxfFile; UpdateHeader: Boolean = true);

function AddLine(afile: TDxfFile; const p1, p2: TPoint): TDxfLine;

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

  c := dxf.AddClass;
  c.recName := 'DICTIONARYVAR';
  c.cppName := 'AcDbDictionaryVar';

  c := dxf.AddClass;
  c.recName := 'ACDBPLACEHOLDER';
  c.cppName := 'AcDbPlaceHolder';

  c := dxf.AddClass;
  c.recName := 'LAYOUT';
  c.cppName := 'AcDbLayout';

  c := dxf.AddClass;
  c.recName := 'TABLESTYLE';
  c.cppName := 'AcDbTableStyle';
end;

function AddLine(afile: TDxfFile; const p1, p2: TPoint): TDxfLine;
begin
  Result:=TDxfLine.Create;
  PointToDfxPoint(p1, Result.StartPoint);
  PointToDfxPoint(p2, Result.EndPoint);
  afile.AddEntity(Result);
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

procedure AddDefaultTables(dxf: TDxfFile);
var
  t : TDxfTable;
  ap : TDxfAppIdEntry;
  br : TDxfBlockRecordEntry;
begin
  t := TDxfTable.Create;
  t.Name := 'VPORT';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'LTYPE';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);
  AllocLType(t, 'ByBlock','');
  AllocLType(t, 'ByLayer','');
  AllocLType(t, 'CONTINUOUS','Solid line');

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
  h.acad.MaintVer := 6;
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
  {
  h.Sel.EntLineType := 'ByLayer'; // reference to LType
  h.Sel.EntColor := CECOLOR_BYLAYER;
  h.Dim.Scale := 1;
  h.Dim.ArrowSize := 2.5;
  h.Dim.ExtLineOfs        := 0.65;
  h.Dim.DimLineInc        := 3.75;  // ($DIMDLI)
  h.Dim.ExtLineExt        := 1.25;  // ($DIMEXE)
  h.Dim.TextHeight        := 2.5;   // ($DIMTXT)
  h.Dim.CenterSize        := -2.5;  // ($DIMCEN)
  h.Dim.isTextOut         := 1;     // ($DIMTOH)
  h.Dim.isTextAbove       := 1;     // ($DIMTAD)
  h.Dim.SupZeros          := 8; // ($DIMZIN)
  }
{h.Dim.ArrowBlock        : string;  // ($DIMBLK)
h.Dim.isAssocDim        : Integer; // ($DIMASO)
h.Dim.isRecompDim       : Integer; // ($DIMSHO)
h.Dim.Suffix            : string;  // ($DIMPOST)
h.Dim.AltSuffix         : string;  // ($DIMAPOST)
h.Dim.isUseAltUnit      : integer; // ($DIMALT)
h.Dim.AltDec            : integer; // ($DIMALTD)
h.Dim.AltScale          : double;  // ($DIMALTF)
h.Dim.LinearScale       : double;  // ($DIMLFAC)
h.Dim.isTextOutExt      : Integer; // ($DIMTOFL)
h.Dim.TextVertPos       : double;  // ($DIMTVP)
h.Dim.isForceTextIns    : Integer; // ($DIMTIX)
h.Dim.isSuppOutExt      : Integer; // ($DIMSOXD)
h.Dim.isUseSepArrow     : Integer; // ($DIMSAH)
h.Dim.ArrowBlock1       : string;  // ($DIMBLK1)
h.Dim.ArrowBlock2       : string;  // ($DIMBLK2)
h.Dim.StyleName         : string;  // ($DIMSTYLE)
h.Dim.LineColor         : integer; // ($DIMCLRD)
h.Dim.ExtLineColor      : integer; // ($DIMCLRE)
h.Dim.TextColor         : integer; // ($DIMCLRT)
h.Dim.DispTolerance     : double;  // ($DIMTFAC)
h.Dim.LineGap           : double;  // ($DIMGAP)
h.Dim.HorzTextJust      : integer; // ($DIMJUST)
h.Dim.isSuppLine1       : Integer; // ($DIMSD1)
h.Dim.isSuppLine2       : Integer; // ($DIMSD2)
h.Dim.VertJustTol       : Integer; // ($DIMTOLJ)
h.Dim.ZeroSupTol        : Integer; // ($DIMTZIN)
h.Dim.ZeroSupAltUnitTol : Integer; // ($DIMALTZ)
h.Dim.ZeroSupAltTol     : Integer; // ($DIMALTTZ)
h.Dim.isEditCursorText  : Integer; // ($DIMUPT)
h.Dim.DecPlacesPrim     : Integer; // ($DIMDEC)
h.Dim.DecPlacesOther    : Integer; // ($DIMTDEC)
h.Dim.UnitsFormat       : Integer; // ($DIMALTU)
h.Dim.DecPlacesAltUnit  : Integer; // ($DIMALTTD)
h.Dim.TextStyle         : string;  // ($DIMTXSTY)
h.Dim.AngleFormat       : Integer; // ($DIMAUNIT)
h.Dim.AngleDecPlaces    : Integer; // ($DIMADEC)
h.Dim.RoundValAlt       : double;  // ($DIMALTRND)
h.Dim.ZeroSupAngUnit    : Integer; // ($DIMAZIN)
h.Dim.DecSeparator      : Integer; // ($DIMDSEP)
h.Dim.TextArrowPlace    : Integer; // ($DIMATFIT)
h.Dim.ArrowBlockLead    : string;  // ($DIMLDRBLK)
h.Dim.Units             : Integer; // ($DIMLUNIT)
h.Dim.LineWeight        : Integer; // ($DIMLWD)
h.Dim.LineWeightExt     : Integer; // ($DIMLWE)
h.Dim.TextMove          : Integer; // ($DIMTMOVE)
h.Dim.UnitFrac          : Integer; // DIMFRAC
h.Dim.ArrowBlockId      : string;  // ($DIMBLK1)
h.Dim.ArrowBlockId1     : string;  // ($DIMBLK1)
h.Dim.ArrowBlockId2     : string;  // ($DIMBLK2)
// oboslete
__Units: Integer;          // ($DIMUNIT)    Se
__TextArrowPlace: Integer; // ($DIMFIT)    Con}

end;
end.
