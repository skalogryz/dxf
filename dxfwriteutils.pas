unit dxfwriteutils;

interface

uses
  dxftypes, dxfwrite, dxfparseutils;

procedure WriteBlock(w: TDxfWriter; const b: TDxfBlock);
procedure WriteBlockEnd(w: TDxfWriter; const b: TDxfBlockEnd);
procedure WritePoint(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer = 10);
procedure WritePoint2D(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer = 10);

// returns def, if check is an empty string (no trimming check)
// otherwise returns check
function IfEmpt(const check, def: string): string; inline;

implementation

const
  XOFS = 0;
  YOFS = 10;
  ZOFS = 20;

procedure WritePoint(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer);
begin
  if not Assigned(w) then Exit;
  w.WriteFloat(XCodeBase + XOFS, b.x);
  w.WriteFloat(XCodeBase + YOFS, b.y);
  w.WriteFloat(XCodeBase + ZOFS, b.z);
end;

procedure WritePoint2D(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer = 10);
begin
  if not Assigned(w) then Exit;
  w.WriteFloat(XCodeBase + XOFS, b.x);
  w.WriteFloat(XCodeBase + YOFS, b.y);
end;

function IfEmpt(const check, def: string): string;
begin
  if (check = '') then Result := def
  else Result :=check;
end;

procedure WriteCtrl(w: TDxfWriter; const tp: string);
begin
  w.WriteStr(CB_CONTROL, tp);
end;

// todo: this will change!
procedure WriteBlockEnt(w: TDxfWriter; const b: TDxfEntity; WriteSpaceFlag: Boolean);
begin
  w.WriteStr(CB_HANDLE, b.Handle);
  if b.appDefGroup<>'' then begin
    // todo: support for custom application codes
  end;
  w.WriteStr(CB_OWNERHANDLE, b.Owner);
  w.WriteStr(CB_SUBCLASS,    IfEmpt(b.SubClass, _AcDbEntity));
  if WriteSpaceFlag then w.WriteInt(CB_SPACEFLAG,   b.SpaceFlag);
  w.WriteStr(CB_LAYERNAME,   b.LayerName);
end;

procedure WriteBlock(w: TDxfWriter; const b: TDxfBlock);
begin
  if not Assigned(w) then Exit;
  WriteCtrl(w, NAME_BLOCK);
  WriteBlockEnt(w, b.Ent, b.Ent.SpaceFlag<>0);
  w.WriteStr(CB_SUBCLASS, IfEmpt(b.Ent.Subclass2, _AcDbBlockBegin));
  w.WriteStr(CB_NAME, b.BlockName);
  w.WriteInt(CB_FLAGS, b.BlockFlags);
  WritePoint(w, b.BasePoint);
  w.WriteStr(CB_BLOCKNAME, b.BlockName2);
  w.WriteStr(CB_XREFPATH, b.XRef);
  if b.Descr<>'' then w.WriteStr(CB_DESCR, b.Descr);
end;

procedure WriteBlockEnd(w: TDxfWriter; const b: TDxfBlockEnd);
begin
  if not Assigned(w) then Exit;
  WriteCtrl(w, NAME_ENDBLK);
  WriteBlockEnt(w, b.Ent, false);
  w.WriteStr(CB_SUBCLASS, IfEmpt(b.Ent.Subclass2, _AcDbBlockEnd));
end;

end.
