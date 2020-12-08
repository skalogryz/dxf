unit dxfparseutils;

interface

uses
  dxfparse, dxftypes;

type
  TDxfPoint = record
    x,y,z : double;
  end;

  TDxfEntity = record
    Handle       : string;  // 5
    appDefGroup  : string;  // 102
    Owner        : string;  //
    SubClass     : string;  // 102
    LayerName    : string;  // 8
    Subclass2    : string;  // 102
  end;

  TDxfBlock = record
    Ent        : TDxfEntity;
    BlockName  : string;    // 2
    BlockFlags : integer;   // 70
    BasePoint  : TDxfPoint; // 10 20 30
    BlockName2 : string;    // 3
    XRef       : string;    // 1
    Descr      : string;    // 4
  end;

  TDxfEndBlock = record
  end;

procedure ParseEnt(p: TDxfParser; var e: TDxfEntity);
procedure ParseBlock(p: TDxfParser; var b: TDxfBlock);
procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint);

implementation

procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint);
begin
  pt.x := 0;
  pt.y := 0;
  pt.z := 0;
  case p.scanner.CodeGroup of
    CB_X: begin
      pt.x := p.scanner.ValFloat;
      p.Next;
    end;
  end;
  case p.scanner.CodeGroup of
    CB_Y: begin
      pt.y := p.scanner.ValFloat;
      p.Next;
    end;
  end;
  case p.scanner.CodeGroup of
    CB_Z: begin
      pt.z := p.scanner.ValFloat;
      p.Next;
    end;
  end;
end;

procedure ParseEnt(p: TDxfParser; var e: TDxfEntity);
begin
  e.Handle    := '';
  e.appDefGroup := '';
  e.Owner     := '';
  e.SubClass  := '';
  e.LayerName := '';
  e.Subclass2 := '';
  if p.scanner.CodeGroup = CB_HANDLE then begin
    e.Handle := p.scanner.ValStr;
    p.Next;
  end;

  while p.scanner.CodeGroup = CB_APPDEFNAME do begin // 102
    e.appDefGroup := e.appDefGroup + p.scanner.ValStr;
    p.Next;
  end;

  if p.scanner.CodeGroup = CB_OWNERHANDLE then begin
    e.Owner := p.scanner.ValStr;
    p.Next;
  end;

  if p.scanner.CodeGroup = CB_SUBCLASS then begin
    e.SubClass := p.scanner.ValStr;
    p.Next;
  end;

  if p.scanner.CodeGroup = CB_LAYERNAME then begin
    e.Owner := p.scanner.ValStr;
    p.Next;
  end;

  if p.scanner.CodeGroup = CB_SUBCLASS then begin
    e.SubClass2 := p.scanner.ValStr;
    p.Next;
  end;

end;

procedure ParseBlock(p: TDxfParser; var b: TDxfBlock );
begin
  ParseEnt(p, b.Ent);
  b.BlockName  := '';
  b.BlockFlags := 0;
  b.BlockName2 := '';
  b.XRef       := '';
  b.Descr      := '';

  if p.scanner.CodeGroup = CB_NAME then begin
    b.BlockName := p.scanner.ValStr;
    p.Next;
  end;
  if p.scanner.CodeGroup = CB_FLAGS then begin
    b.BlockFlags := p.scanner.ValInt;
    p.Next;
  end;
  ParsePoint(p, b.basePoint);
  if p.scanner.CodeGroup = CB_BLOCKNAME then begin
    b.BlockName2 := p.scanner.ValStr;
    p.Next;
  end;
  if p.scanner.CodeGroup = CB_XREFPATH then begin
    b.XRef := p.scanner.ValStr;
    p.Next;
  end;
  if p.scanner.CodeGroup = CB_DESCR then begin
    b.Descr := p.scanner.valStr;
    p.Next;
  end;
end;

end.
