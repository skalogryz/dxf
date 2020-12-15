unit dxffileutils;

interface

uses
  Types, SysUtils, Classes,
  dxftypes, dxfclasses, HashStrings;

procedure AddDefaultObjects(dxf: TDxfFile);
procedure AddDefaultBlocks(dxf: TDxfFile);

procedure NormalizeBlocks(dxf : TDxfFile);

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
  e : TDxfEntity;
  h : integer;
begin
  h:=0;
  for i:=0 to dxf.entities.Count-1 do begin
    e := TDxfEntity(dxf.entities[i]);
    if e.Handle = '' then begin
      e.Handle:='H'+IntToStr(h);
      inc(h);
    end;
  end;
end;

procedure AddDefaultObjects(dxf: TDxfFile);
begin
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
    for i:=0 to dxf.objects.Count-1 do begin
      b := TDxfBase(dxf.objects[i]);
      blist.Add(b);
    end;
    for i:=0 to dxf.entities.Count-1 do begin
      b := TDxfBase(dxf.objects[i]);
      blist.Add(b);
    end;
    for i := 0 to blist.Count-1 do begin
      b := TDxfBase(blist[i]);
      if Assigned(b._Owner) and (b.Owner = '') then
        b.Owner := b._Owner.Handle;
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

end.
