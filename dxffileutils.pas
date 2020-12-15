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

procedure FillHandles(dxf: TDxfFile);

function AddLine(afile: TDxfFile; const p1, p2: TPoint): TDxfLine;

procedure PointToDfxPoint(const src: TPoint; dst: TDxfPoint; z: double = 0);

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

implementation

procedure AddDefaultBlocks(dxf: TDxfFile);
var
  b : TDxfFileBlock;
begin
  b := dxf.AddBlock;
  b.BlockName := '*Model_Space';
  b.BlockName2 := '*Model_Space';

  b := dxf.AddBlock;
  b.BlockName := '*Paper_Space';
  b.BlockName2 := '*Paper_Space';

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

procedure PointToDfxPoint(const src: TPoint; dst: TDxfPoint; z: double);
begin
  dst.x := src.X;
  dst.y := src.Y;
  dst.z := z;
end;

procedure FillHandles(dxf: TDxfFile);
var
  i : integer;
  e : TDxfBase;
  h : integer;
  l : TList;
begin
  h:=0;
  l:=TList.Create;
  try
    GatherDxfBase(dxf, l);
    for i:=0 to l.Count-1 do begin
      e := TDxfBase(l[i]);
      if e.Handle = '' then begin
        e.Handle:='H'+IntToStr(h);
        inc(h);
      end;
    end;
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
begin
  if not Assigned(dxf) or not Assigned(dst) then Exit;
  for i:=0 to dxf.tables.Count-1 do begin
    b := TDxfBase(dxf.tables[i]);
    dst.Add(b);
  end;
  for i:=0 to dxf.objects.Count-1 do begin
    b := TDxfBase(dxf.objects[i]);
    dst.Add(b);
  end;
  for i:=0 to dxf.entities.Count-1 do begin
    b := TDxfBase(dxf.entities[i]);
    dst.Add(b);
  end;
end;

procedure AddDefaultTables(dxf: TDxfFile);
var
  t : TDxfTable;
begin
  t := TDxfTable.Create;
  t.Name := 'VPORT';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'LTYPE';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'LAYER';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

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

  t := TDxfTable.Create;
  t.Name := 'DIMSTYLE';
  t.SubClass := 'AcDbSymbolTable';
  t.SubClass2 := 'AcDbDimStyleTable';
  dxf.tables.Add(t);

  t := TDxfTable.Create;
  t.Name := 'BLOCK_RECORD';
  t.SubClass := 'AcDbSymbolTable';
  dxf.tables.Add(t);

end;

end.
