unit dxfwriteutils;

interface

uses
  dxftypes, dxfwrite, dxfparseutils;

procedure WriteBlock(w: TDxfWriter; const b: TDxfBlock);
procedure WriteBlockEnd(w: TDxfWriter; const b: TDxfBlockEnd);
procedure WritePoint(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer = 10);
procedure WritePoint2D(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer = 10);

function IfEmpt(const check, def: string): string;

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
procedure WriteBlockEnt(w: TDxfWriter; const b: TDxfEntity; WriteSpace: Boolean);
begin
  w.WriteStr(CB_HANDLE, b.Handle);
  if b.appDefGroup<>'' then begin
  end;
  w.WriteStr(CB_OWNERHANDLE, b.Owner);
  w.WriteStr(CB_SUBCLASS,    b.SubClass);
  w.WriteInt(CB_SPACEFLAG,   b.SpaceFlag);
  w.WriteStr(CB_LAYERNAME,   b.LayerName);
  w.WriteStr(CB_SUBCLASS,    b.Subclass2);
end;

procedure WriteBlock(w: TDxfWriter; const b: TDxfBlock);
begin
  if not Assigned(w) then Exit;
  WriteCtrl(w, NAME_BLOCK);
  WriteBlockEnt(w, b.Ent, b.Ent.SpaceFlag<>0);
  w.WriteStr(CB_NAME, b.BlockName);
  w.WriteInt(CB_FLAGS, b.BlockFlags);
  w.WriteStr(CB_BLOCKNAME, b.BlockName2);
  w.WriteStr(CB_XREFPATH, b.XRef);
  if b.Descr<>'' then w.WriteStr(CB_DESCR, b.Descr);
end;

procedure WriteBlockEnd(w: TDxfWriter; const b: TDxfBlockEnd);
begin
  if not Assigned(w) then Exit;
  WriteCtrl(w, NAME_ENDBLK);
  WriteBlockEnt(w, b.Ent, false);
end;

end.
