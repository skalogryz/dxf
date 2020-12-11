unit dxfparseutils;

interface

uses
  dxftypes, dxfparse, dxfclasses;

procedure ParseClass(p: TDxfParser; c: TDxfClass);
procedure ParseBlockEntity(p: TDxfParser; e: TDxfBlockEntity);
procedure ParseBlock(p: TDxfParser; b: TDxfBlock);
procedure ParseBlockEnd(p: TDxfParser; b: TDxfBlockEnd);
procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X);
procedure ParseScale(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X_SCALE);

procedure ParseLine(p: TDxfParser; l: TDxfLine);
procedure ParseCircle(p: TDxfParser; c: TDxfCircle);
procedure ParseSolid(p: TDxfParser; s: TDxfSolid);
procedure ParseInsert(p: TDxfParser; i: TDxfInsert);
procedure ParsePolyLine(p: TDxfParser; l: TDxfPolyLine);
procedure ParseVertex(p: TDxfParser; v: TDxfVertex);


procedure ParseEntity(p: TDxfParser; e: TDxfEntity);
function ParseEntityFromType(p: TDxfParser; const tp: string): TDxfEntity; // parser must be at 0 / EntityName pair
function ParseEntity(p: TDxfParser): TDxfEntity; // parser must be at 0 / EntityName pair

implementation

procedure ParseScale(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X_SCALE);
begin
  pt.x := ConsumeFlt(p, XCodeGroup + 0, 0);
  pt.y := ConsumeFlt(p, XCodeGroup + 1, 0);
  pt.z := ConsumeFlt(p, XCodeGroup + 2, 0);
end;

procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X);
begin
  pt.x := ConsumeFlt(p, XCodeGroup, 0);
  pt.y := ConsumeFlt(p, XCodeGroup + 10, 0);
  pt.z := ConsumeFlt(p, XCodeGroup + 20, 0);
end;

procedure ParseBlockEntity(p: TDxfParser; e: TDxfBlockEntity);
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

procedure ParseBlock(p: TDxfParser; b: TDxfBlock );
begin
  ParseBlockEntity(p, b);
  b.BlockName  := ConsumeStr(p, CB_NAME);
  b.BlockFlags := ConsumeInt(p, CB_FLAGS);
  ParsePoint(p, b.basePoint);
  b.BlockName2 := ConsumeStr(p, CB_BLOCKNAME);
  b.XRef       := ConsumeStr(p, CB_XREFPATH);
  b.Descr      := ConsumeStr(p, CB_DESCr);
end;

procedure ParseBlockEnd(p: TDxfParser; b: TDxfBlockEnd);
begin
  ParseBlockEntity(p, b);
end;

procedure ParseClass(p: TDxfParser; c: TDxfClass);
begin
  c.recName    := ConsumeStr(p, CB_DXFRECNAME );  {1  }
  c.cppName    := ConsumeStr(p, CB_CPPNAME    );  {2  }
  c.appName    := ConsumeStr(p, CB_APPANME    );  {3  }
  c.ProxyFlags := ConsumeInt(p, CB_PROXYFLAG  );  {90 }
  c.InstCount  := ConsumeInt(p, CB_INSTCOUNT  );  {91 }
  c.WasProxy   := ConsumeInt(p, CB_WASAPROXY  );  {280}
  c.IsAnEntity := ConsumeInt(p, CB_ISENTITY   );  {281}
end;

procedure ParseEntity(p: TDxfParser; e: TDxfEntity);
begin
  //e.EntityType    := ConsumeStr(p, 0);
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

procedure ParseLine(p: TDxfParser; l: TDxfLine);
begin
  ParseEntity(p, l);
  l.Thickness := ConsumeFlt(p, CB_THICKNESS);
  ParsePoint(p, l.StartPoint, CB_X);
  ParsePoint(p, l.EndPoint, CB_X_ENDPOINT);
  ParsePoint(p, l.Extrusion, CB_X_EXTRUSION);
end;

procedure ParseCircle(p: TDxfParser; c: TDxfCircle);
begin
  ParseEntity(p, c);
  c.Thickness := ConsumeFlt(p, CB_THICKNESS);
  ParsePoint(p, c.CenterPoint, CB_X);
  c.Radius := ConsumeFlt(p, CB_RADIUS);
  ParsePoint(p, c.Extrusion, CB_X_EXTRUSION);
end;

procedure ParseSolid(p: TDxfParser; s: TDxfSolid);
begin
  ParseEntity(p, s);
  ParsePoint(p, s.Corner1, CB_X0);
  ParsePoint(p, s.Corner2, CB_X1);
  ParsePoint(p, s.Corner3, CB_X2);
  ParsePoint(p, s.Corner4, CB_X3);

  s.Thickness := ConsumeFlt(p, CB_THICKNESS);
  ParsePoint(p, s.Extrusion, CB_X_EXTRUSION);
end;

procedure ParseInsert(p: TDxfParser; i: TDxfInsert);
begin
  ParseEntity(p, i);
  i.AttrFlag := ConsumeInt(p, 66);
  i.BlockName := ConsumeStr(p, 2);
  ParsePoint(p, i.InsPoint);
  ParseScale(p, i.Scale);
  i.Rotation := ConsumeFlt(p, 50);
  i.ColCount := ConsumeInt(p, 70, 1);
  i.RowCount := ConsumeInt(p, 71, 1);
  i.ColSpace := ConsumeFlt(p, 44);
  i.RowSpace := ConsumeFlt(p, 45);
  ParsePoint(p, i.Extrusion, CB_X_EXTRUSION);
end;

procedure ParsePolyLine(p: TDxfParser; l: TDxfPolyLine);
begin
  ParseEntity(p, l);
  l.ObsFlag := ConsumeInt(p, 66);
  ParsePoint(p, l.ElevPoint, CB_X);
  l.Thickness := ConsumeFlt(p, CB_THICKNESS);
  l.PolyFlags := ConsumeInt(p, CB_FLAGS);
  l.StartWidth := ConsumeFlt(p, 40);
  l.EndWidth := ConsumeFlt(p, 41);

  l.MCount   := ConsumeInt(p, 71);
  l.NCount   := ConsumeInt(p, 72);
  l.MDensity := ConsumeInt(p, 73);
  l.NDensity := ConsumeInt(p, 74);
  l.SurfType := ConsumeInt(p, 75);
  ParsePoint(p, l.Extrusion, CB_X_EXTRUSION);
end;

procedure ParseVertex(p: TDxfParser; v: TDxfVertex);
begin
  ParseEntity(p, v);
  v.SubClass3   := ConsumeStr(p, 100);
  ParsePoint(p, v.Location);
  v.StartWidth  := ConsumeFlt(p, 40);
  v.EndWidth    := ConsumeFlt(p, 41);
  v.Buldge      := ConsumeFlt(p, 42);
  v.Flags       := ConsumeInt(p, 70);
  v.TangentDir  := ConsumeFlt(p, 50);
  v.PolyFace[0] := ConsumeInt(p, 71);
  v.PolyFace[1] := ConsumeInt(p, 72);
  v.PolyFace[2] := ConsumeInt(p, 73);
  v.PolyFace[3] := ConsumeInt(p, 74);
  v.VertexIdx   := ConsumeInt(p, 91)
end;

function ParseEntityFromType(p: TDxfParser; const tp: string): TDxfEntity; // parser must be at 0 / EntityName pair
var
  nm : string;
begin
  Result := nil;
  if tp='' then Exit;

  nm := upcase(tp);
  case nm[1] of
    'C':
      if nm = ET_CIRCLE then begin
        Result := TDxfCircle.Create;
        ParseCircle(p, TDxfCircle(Result));
      end;
    'I':
      if nm = ET_INSERT then begin
        Result := TDxfInsert.Create;
        ParseInsert(p, TDxfInsert(Result));
      end;
    'L':
      if nm = ET_LINE then begin
        Result := TDxfLine.Create;
        ParseLine(p, TDxfLine(Result));
      end;
    'P':
      if nm = ET_POLYLINE then begin
        Result := TDxfPolyLine.Create;
        ParsePolyLine(p, TDxfPolyLine(Result));
      end;
    'S':
      if nm = ET_SOLID then begin
        Result := TDxfSolid.Create;
        ParseSolid(p, TDxfSolid(Result));
      end;
  end;
end;

function ParseEntity(p: TDxfParser): TDxfEntity; // parser must be at 0 / EntityName pair
var
  nm : string;
begin
  if p.scanner.CodeGroup <> CB_CONTROL then begin
    Result := nil;
    Exit;
  end;
  nm := p.scanner.ValStr;
  if nm ='' then begin
    Result := nil;
    Exit;
  end;
  Result := ParseEntityFromType(p, nm);
end;

end.
