unit dxfparseutils;

interface

uses
  Classes, SysUtils,
  dxftypes, dxfparse, dxfclasses;

procedure ParseClass(p: TDxfParser; c: TDxfClass);
procedure ParseBlockEntity(p: TDxfParser; e: TDxfBlockEntity);
procedure ParseBlock(p: TDxfParser; b: TDxfBlock);
procedure ParseBlockEnd(p: TDxfParser; b: TDxfBlockEnd);
procedure ParsePointDef(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer; const Def: TDxfPoint);
procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X);
procedure ParseExtrusionPoint(p: TDxfParser; var pt: TDxfPoint);
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

procedure ParseVariable(P: TDxfParser; hdr: TDxfHeader);

procedure ReadFile(const fn: string; dst: TDxfFile);
procedure ReadFile(const st: TStream; dst: TDxfFile);
procedure ReadFile(p: TDxfParser; dst: TDxfFile);

implementation

procedure ParseScale(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X_SCALE);
begin
  pt.x := ConsumeFlt(p, XCodeGroup + 0, 0);
  pt.y := ConsumeFlt(p, XCodeGroup + 1, 0);
  pt.z := ConsumeFlt(p, XCodeGroup + 2, 0);
end;

procedure ParsePointDef(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer; const Def: TDxfPoint);
begin
  pt.x := ConsumeFlt(p, XCodeGroup, def.x);
  pt.y := ConsumeFlt(p, XCodeGroup + 10, def.y);
  pt.z := ConsumeFlt(p, XCodeGroup + 20, def.z)
end;

procedure ParsePoint(p: TDxfParser; var pt: TDxfPoint; const XcodeGroup: Integer = CB_X);
begin
  ParsePointDef(p, pt, XcodeGroup, DefZeroPoint);
end;

procedure ParseExtrusionPoint(p: TDxfParser; var pt: TDxfPoint);
begin
  ParsePointDef(p, pt, CB_X_EXTRUSION, DefExtrusionPoint);
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
  e.ColorNumber  := ConsumeInt(p, 62,  256);
  e.LineWidth    := ConsumeInt(p, 370);

  e.LineScale       := ConsumeFlt(p, 48, 1.0);
  e.isHidden        := ConsumeInt(p, 60);
  e.ProxyBytesCount := ConsumeInt(p, 92);
  if (e.ProxyBytesCount>0) then begin
    //  e.ProxyGraph      := ConsumeInt array of byte; // 310s
  end;
  e.Color           := ConsumeInt(p, 420);
  e.ColorName       := ConsumeStr(p, 430);
  e.Transperancy    := ConsumeInt(p, 440);
  e.PlotObj         := ConsumeStr(p, 390);
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
  ParseExtrusionPoint(p, l.Extrusion);
end;

procedure ParseCircle(p: TDxfParser; c: TDxfCircle);
begin
  ParseEntity(p, c);
  c.Thickness := ConsumeFlt(p, CB_THICKNESS);
  ParsePoint(p, c.CenterPoint, CB_X);
  c.Radius := ConsumeFlt(p, CB_RADIUS);
  ParseExtrusionPoint(p, c.Extrusion);
end;

procedure ParseSolid(p: TDxfParser; s: TDxfSolid);
begin
  ParseEntity(p, s);
  ParsePoint(p, s.Corner1, CB_X0);
  ParsePoint(p, s.Corner2, CB_X1);
  ParsePoint(p, s.Corner3, CB_X2);
  ParsePoint(p, s.Corner4, CB_X3);

  s.Thickness := ConsumeFlt(p, CB_THICKNESS);
  ParseExtrusionPoint(p, s.Extrusion);
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
  ParseExtrusionPoint(p, i.Extrusion);
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
  ParseExtrusionPoint(p, l.Extrusion);
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

procedure ParseVariable(p: TDxfParser; hdr: TDxfHeader);
var
  v : string;
begin
  if not Assigned(p) or not Assigned(hdr) then Exit;
  v := p.varName;
  if (v = '') or (length(v)<=2) then Exit;

  case v[2] of
    'A':
      if v = vACADVER then hdr.acad.Version := ConsumeStr(p, CB_VARVALUE)
      else if v = vACADMAINTVER then hdr.acad.MaintVer := ConsumeInt(p, CB_VARINT)
      else if v = vATTMODE then hdr.Base.AttrVisMode := ConsumeInt(p, CB_VARINT)
      else if v = vAUNITS  then hdr.base.AnglesFormat := ConsumeInt(p, CB_VARINT)
      else if v = vAUPREC  then hdr.base.AnglesPrec   := ConsumeInt(p, CB_VARINT)
      else if v = vANGBASE then hdr.base.AngleBase    := ConsumeFlt(p, 50)
      else if v = vANGDIR  then hdr.base.isClockWise  := ConsumeInt(p, CB_VARINT)
      ;
    'C':
      if v = vCLAYER then hdr.Sel.Layer := ConsumeStr(p, CB_LAYERNAME)
      else if v = vCELTYPE   then hdr.Sel.EntLineType := ConsumeStr(p, 6)
      else if v = vCECOLOR   then hdr.Sel.EntColor := ConsumeInt(p, 62)
      else if v = vCELTSCALE then hdr.Sel.EntLineTypeScale := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vCHAMFERA  then hdr.Base.ChamferDist1 := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vCHAMFERB  then hdr.Base.ChamferDist2 := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vCHAMFERC  then hdr.Base.ChamferLen   := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vCHAMFERD  then hdr.Base.ChamferAngle := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vCELWEIGHT then hdr.base.NewObjLineWeight := ConsumeInt (p, 370)
      else if v = vCEPSNTYPE then hdr.base.PlotStype        := ConsumeInt (p, 380)
      else if v = vCMLSTYLE  then hdr.Sel.MultiLineStyle    := ConsumeStr (p, 2)
      else if v = vCMLJUST   then hdr.Sel.MultiLineJust     := ConsumeInt (p, CB_VARINT)
      else if v = vCMLSCALE  then hdr.Sel.MultiLineScale    := ConsumeFlt (p, 40)
      ;
    'D':
      if v = vDWGCODEPAGE then hdr.base.CodePage := ConsumeStr(p, 3)
      else if v = vDISPSILH then hdr.Sel.DispSilhMode := ConsumeInt(p, 7)
      else if v = vDIMSCALE then hdr.Dim.Scale          := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMASZ   then hdr.Dim.ArrowSize      := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMEXO   then hdr.Dim.ExtLineOfs     := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMDLI   then hdr.Dim.DimLineInc     := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMRND   then hdr.Dim.RoundVal       := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMDLE   then hdr.Dim.DimLineExt     := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMEXE   then hdr.Dim.ExtLineExt     := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMTP    then hdr.Dim.PlusToler      := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMTM    then hdr.Dim.MinusToler     := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMTXT   then hdr.Dim.TextHeight     := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMCEN   then hdr.Dim.CenterSize     := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMTSZ   then hdr.Dim.TickSize       := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMTOL   then hdr.Dim.Tolerance      := Consumeint(P, CB_VARINT)
      else if v = vDIMLIM   then hdr.Dim.Limits         := Consumeint(P, CB_VARINT)
      else if v = vDIMTIH   then hdr.Dim.isTextIns      := Consumeint(P, CB_VARINT)
      else if v = vDIMTOH   then hdr.Dim.isTextOut      := Consumeint(P, CB_VARINT)
      else if v = vDIMSE1   then hdr.Dim.isSupExt1      := Consumeint(P, CB_VARINT)
      else if v = vDIMSE2   then hdr.Dim.isSupExt2      := Consumeint(P, CB_VARINT)
      else if v = vDIMTAD   then hdr.Dim.isTextAbove    := Consumeint(P, CB_VARINT)
      else if v = vDIMZIN   then hdr.Dim.SupZeros       := Consumeint(P, CB_VARINT)
      else if v = vDIMBLK   then hdr.Dim.ArrowBlock     := Consumestr(P, CB_VARVALUE)
      else if v = vDIMASO   then hdr.Dim.isAssocDim     := ConsumeInt(P, CB_VARINT)
      else if v = vDIMSHO   then hdr.Dim.isRecompDim    := ConsumeInt(P, CB_VARINT)
      else if v = vDIMPOST  then hdr.Dim.Suffix         := ConsumeStr(p, CB_VARVALUE)
      else if v = vDIMAPOST then hdr.Dim.AltSuffix      := ConsumeStr(p, CB_VARVALUE)
      else if v = vDIMALT   then hdr.Dim.isUseAltUnit   := Consumeint(p, CB_VARINT)
      else if v = vDIMALTD  then hdr.Dim.AltDec         := Consumeint(p, CB_VARINT)
      else if v = vDIMALTF  then hdr.Dim.AltScale       := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMLFAC  then hdr.Dim.LinearScale    := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMTOFL  then hdr.Dim.isTextOutExt   := ConsumeInt(p, CB_VARINT)
      else if v = vDIMTVP   then hdr.Dim.TextVertPos    := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMTIX   then hdr.Dim.isForceTextIns := ConsumeInt(p, CB_VARINT)
      else if v = vDIMSOXD  then hdr.Dim.isSuppOutExt   := ConsumeInt(p, CB_VARINT)
      else if v = vDIMSAH   then hdr.Dim.isUseSepArrow  := ConsumeInt(p, CB_VARINT)
      else if v = vDIMBLK1  then hdr.Dim.ArrowBlock1    := Consumestr(p, CB_VARVALUE)
      else if v = vDIMBLK2  then hdr.Dim.ArrowBlock2    := Consumestr(p, CB_VARVALUE)
      else if v = vDIMSTYLE then hdr.Dim.StyleName      := Consumestr(p, 2)
      else if v = vDIMCLRD  then hdr.Dim.LineColor      := Consumeint(p, CB_VARINT)
      else if v = vDIMCLRE  then hdr.Dim.ExtLineColor   := Consumeint(p, CB_VARINT)
      else if v = vDIMCLRT  then hdr.Dim.TextColor      := Consumeint(p, CB_VARINT)
      else if v = vDIMTFAC  then hdr.Dim.DispTolerance  := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMGAP   then hdr.Dim.LineGap        := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMJUST  then hdr.Dim.HorzTextJust   := Consumeint(p, CB_VARINT)
      else if v = vDIMSD1   then hdr.Dim.isSuppLine1    := ConsumeInt(p, CB_VARINT)
      else if v = vDIMSD2   then hdr.Dim.isSuppLine2    := ConsumeInt(p, CB_VARINT)
      else if v = vDIMTOLJ  then hdr.Dim.VertJustTol    := ConsumeInt(p, CB_VARINT)
      else if v = vDIMTZIN  then hdr.Dim.ZeroSupTol     := ConsumeInt(p, CB_VARINT)
      else if v = vDIMALTZ  then hdr.Dim.ZeroSupAltUnitTol := ConsumeInt(p, CB_VARINT)
      else if v = vDIMALTTZ then hdr.Dim.ZeroSupAltTol    := ConsumeInt(p, CB_VARINT)
      else if v = vDIMUPT   then hdr.Dim.isEditCursorText := ConsumeInt(p, CB_VARINT)
      else if v = vDIMDEC   then hdr.Dim.DecPlacesPrim    := ConsumeInt(p, CB_VARINT)
      else if v = vDIMTDEC  then hdr.Dim.DecPlacesOther   := ConsumeInt(p, CB_VARINT)
      else if v = vDIMALTU  then hdr.Dim.UnitsFormat      := ConsumeInt(p, CB_VARINT)
      else if v = vDIMALTTD then hdr.Dim.DecPlacesAltUnit := ConsumeInt(p, CB_VARINT)
      else if v = vDIMTXSTY then hdr.Dim.TextStyle       := ConsumeStr(p, 7)
      else if v = vDIMAUNIT then hdr.Dim.AngleFormat     := ConsumeInt(p, CB_VARINT)
      else if v = vDIMADEC  then hdr.Dim.AngleDecPlaces  := ConsumeInt(p, CB_VARINT)
      else if v = vDIMALTRND then hdr.Dim.RoundValAlt    := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vDIMAZIN   then hdr.Dim.ZeroSupAngUnit := ConsumeInt(p, CB_VARINT)
      else if v = vDIMDSEP   then hdr.Dim.DecSeparator   := ConsumeInt(p, CB_VARINT)
      else if v = vDIMATFIT  then hdr.Dim.TextArrowPlace := ConsumeInt(p, CB_VARINT)
      else if v = vDIMLDRBLK then hdr.Dim.ArrowBlockLead := ConsumeStr(p, CB_VARVALUE)
      else if v = vDIMLUNIT  then hdr.Dim.Units          := ConsumeInt(p, CB_VARINT)
      else if v = vDIMLWD    then hdr.Dim.LineWeight     := ConsumeInt(p, CB_VARINT)
      else if v = vDIMLWE    then hdr.Dim.LineWeightExt  := ConsumeInt(p, CB_VARINT)
      else if v = vDIMTMOVE  then hdr.Dim.TextMove       := ConsumeInt(p, CB_VARINT)
      ;
    'E':
      if v = vEXTMIN then ParsePoint(p, hdr.Base.ExtLowLeft)
      else if v = vEXTMAX then ParsePoint(p, hdr.Base.ExtUpRight)
      else if v = vELEVATION then hdr.Sel.Elev := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vEXTNAMES  then hdr.acad.isExtNames  := ConsumeInt(p, 290)
      else if v = vENDCAPS   then hdr.base.LineEndCaps := ConsumeInt(p, 280)
      ;
    'F':
      if v = vFILLMODE then hdr.Base.isFill := ConsumeInt(p, CB_VARINT)
      else if v = vFILLETRAD then hdr.Base.FilletRadius := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vFINGERPRINTGUID then hdr.base.FingerPrintGuid := ConsumeStr(p ,2)
      ;
    'H':
      if v = vHANDSEED then hdr.Base.NextHandle := ConsumeStr(p, 5)
      else if v = vHYPERLINKBASE   then hdr.base.RelHyperLink     := ConsumeStr(p,1)
      ;
    'I':
      if v = vINSBASE then ParsePoint(p, hdr.Base.InsPoint)
      else if v = vINSUNITS then hdr.base.DefaultUnits := ConsumeInt(p,CB_VARINT)
      ;
    'J':
      if v = vJOINSTYLE then hdr.base.LineJointStyle := ConsumeInt(p,280)
      ;
    'L':
      if v = vLIMMIN then ParsePoint(p, hdr.Base.LimLowLeft)
      else if v = vLIMMAX    then ParsePoint(p, hdr.Base.LimUpRight)
      else if v = vLTSCALE   then hdr.Base.LineTypeScale := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vLUNITS    then hdr.Base.DistFormat := ConsumeInt(p, CB_VARINT)
      else if v = vLUPREC    then hdr.Base.DistPrec   := ConsumeInt(p, CB_VARINT)
      else if v = vLIMCHECK  then hdr.Base.isLimCheck := ConsumeInt(p, CB_VARINT)
      else if v = vLWDISPLAY then hdr.base.isLineShow := ConsumeInt(p,290)
      ;
    'M':
      if v = vMIRRTEXT then hdr.Base.isMirrText := ConsumeInt(p, CB_VARINT)
      else if v = vMENU        then hdr.Base.MenuName := ConsumeStr(p, CB_VARVALUE)
      else if v = vMEASUREMENT then hdr.base.MeasureUnits := ConsumeInt(p,CB_VARINT)
      else if v = vMAXACTVP    then hdr.Base.MaxViewPorts := ConsumeInt(p,CB_VARINT)
      ;
    'O':
      if v = vORTHOMODE then hdr.Base.isOrtho := ConsumeInt(p, CB_VARINT);
    'P':
      if v = vPUCSBASE then hdr.PUcs.Base := ConsumeStr(p, 2)
      else if v = vPUCSNAME then hdr.PUcs.Name := ConsumeStr(p, 2)
      else if v = vPUCSORG  then ParsePoint(p, hdr.PUcs.Origin)
      else if v = vPUCSXDIR then ParsePoint(p, hdr.PUcs.XDir)
      else if v = vPUCSYDIR then ParsePoint(p, hdr.PUcs.YDir)
      else if v = vPUCSORTHOREF  then hdr.PUcs.OrthoRef := ConsumeStr(p, 2)
      else if v = vPUCSORTHOVIEW then hdr.PUcs.OrthoView := ConsumeINT(p, CB_VARINT)
      else if v = vPUCSORGTOP    then ParsePoint(p, hdr.PUcs.OriginTop)
      else if v = vPUCSORGBOTTOM then ParsePoint(p, hdr.PUcs.OriginBottom)
      else if v = vPUCSORGLEFT   then ParsePoint(p, hdr.PUcs.OriginLeft)
      else if v = vPUCSORGRIGHT  then ParsePoint(p, hdr.PUcs.OriginRight)
      else if v = vPUCSORGFRONT  then ParsePoint(p, hdr.PUcs.OriginFront)
      else if v = vPUCSORGBACK   then ParsePoint(p, hdr.PUcs.OriginBack)
      else if v = vPELEVATION    then hdr.Sel.PaperElev := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vPDMODE        then hdr.Base.PtDispMode   := ConsumeInt(p, CB_VARINT)
      else if v = vPDSIZE        then hdr.Base.PtDispSize   := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vPLINEWID      then hdr.Base.DefPolyWidth := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vPSVPSCALE       then hdr.base.ViewPortScale    := ConsumeFlt(p,40)
      else if v = vPSTYLEMODE      then hdr.base.isColorDepmode   := ConsumeInt(p,290)
      else if v = vPROXYGRAPHICS   then hdr.base.isProxyImageSave := ConsumeInt(p,CB_VARINT)
      else if v = vPLINEGEN        then hdr.Base.LineTypePatt     := ConsumeInt(p,CB_VARINT)
      else if v = vPSLTSCALE       then hdr.Base.PaperLineScaling := ConsumeInt(p,CB_VARINT)
      else if v = vPINSBASE        then ParsePoint(p, hdr.Base.PaperInsPoint)
      else if v = vPLIMCHECK       then hdr.Base.isPaperLimCheck := ConsumeInt(p,CB_VARINT)
      else if v = vPEXTMIN         then ParsePoint(p, hdr.Base.PaperExtLowLeft)
      else if v = vPEXTMAX         then ParsePoint(p, hdr.Base.PaperExtUpRight)
      else if v = vPLIMMIN         then ParsePoint(p, hdr.Base.PaperLimLowLeft)
      else if v = vPLIMMAX         then ParsePoint(p, hdr.Base.PaperLimUpRight)
      ;
    'Q':
      if v = vQTEXTMODE then hdr.Base.isQText := ConsumeInt(p, CB_VARINT);
    'R':
      if v = vREGENMODE then hdr.Base.isRegen := ConsumeInt(p, CB_VARINT);
    'S':
      if v = vSKETCHINC  then hdr.Base.SketchInc      := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vSKPOLY     then hdr.Base.isSketchPoly   := Consumeint(p, CB_VARINT)
      else if v = vSPLINETYPE then hdr.Base.SplineCurvType := Consumeint(p, CB_VARINT)
      else if v = vSPLINESEGS then hdr.Base.LineSegments   := Consumeint(p, CB_VARINT)
      else if v = vSURFTAB1   then hdr.Base.MeshCount1     := Consumeint(p, CB_VARINT)
      else if v = vSURFTAB2   then hdr.Base.MeshCount2     := Consumeint(p, CB_VARINT)
      else if v = vSURFTYPE   then hdr.Base.SurfType       := Consumeint(p, CB_VARINT)
      else if v = vSURFU      then hdr.Base.SurfDensityM   := Consumeint(p, CB_VARINT)
      else if v = vSURFV      then hdr.Base.SurfDensityN   := Consumeint(p, CB_VARINT)
      else if v = vSHADEDGE   then hdr.Base.ShadeEdge    := ConsumeInt(p,CB_VARINT)
      else if v = vSHADEDIF   then hdr.Base.ShadeDiffuse := ConsumeInt(p,CB_VARINT)
      ;
    'T':
      if v = vTEXTSIZE then hdr.Base.TextHeight := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTRACEWID then hdr.Base.TraceWidth := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTEXTSTYLE then hdr.Sel.TextStyle := ConsumeStr(p, 7)
      else if v = vTHICKNESS    then hdr.Sel.Thickness := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTDCREATE     then hdr.Time.CreateTimeLocal := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTDUCREATE    then hdr.Time.CreateTimeUniv  := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTDUPDATE     then hdr.Time.UpdateTimeLocal := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTDUUPDATE    then hdr.Time.UpdateTimeUniv  := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTDINDWG      then hdr.Time.TotalTime       := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTDUSRTIMER   then hdr.Time.ElasedTime      := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vTREEDEPTH    then hdr.Base.SpaceTreeDepth := ConsumeInt(p,CB_VARINT)
      else if v = vTILEMODE     then hdr.Base.isTileMode := ConsumeInt(p,CB_VARINT)
      ;
    'U':
      if v = vUSERI1 then hdr.User.I1 := ConsumeInt(p, CB_VARINT)
      else if v = vUSERI2 then hdr.User.I2 := ConsumeInt(p, CB_VARINT)
      else if v = vUSERI3 then hdr.User.I3 := ConsumeInt(p, CB_VARINT)
      else if v = vUSERI4 then hdr.User.I4 := ConsumeInt(p, CB_VARINT)
      else if v = vUSERI5 then hdr.User.I5 := ConsumeInt(p, CB_VARINT)
      else if v = vUSERR1 then hdr.User.R1 := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vUSERR2 then hdr.User.R2 := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vUSERR3 then hdr.User.R3 := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vUSERR4 then hdr.User.R4 := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vUSERR5 then hdr.User.R5 := ConsumeFlt(p, CB_VARFLOAT)
      else if v = vUSRTIMER then hdr.Time.isTimerOn := ConsumeInt(p, CB_VARINT)
      else if v = vUNITMODE then hdr.Base.UnitMode := ConsumeInt(p,CB_VARINT)
      else if v = vUCSBASE then hdr.Ucs.Base := ConsumeStr(p, 2)
      else if v = vUCSNAME then hdr.Ucs.Name := ConsumeStr(p, 2)
      else if v = vUCSORG  then ParsePoint(p, hdr.Ucs.Origin)
      else if v = vUCSXDIR then ParsePoint(p, hdr.Ucs.XDir)
      else if v = vUCSYDIR then ParsePoint(p, hdr.Ucs.YDir)
      else if v = vUCSORTHOREF  then hdr.Ucs.OrthoRef := ConsumeStr(p, 2)
      else if v = vUCSORTHOVIEW then hdr.Ucs.OrthoView := ConsumeINT(p, CB_VARINT)
      else if v = vUCSORGTOP    then ParsePoint(p, hdr.Ucs.OriginTop)
      else if v = vUCSORGBOTTOM then ParsePoint(p, hdr.Ucs.OriginBottom)
      else if v = vUCSORGLEFT   then ParsePoint(p, hdr.Ucs.OriginLeft)
      else if v = vUCSORGRIGHT  then ParsePoint(p, hdr.Ucs.OriginRight)
      else if v = vUCSORGFRONT  then ParsePoint(p, hdr.Ucs.OriginFront)
      else if v = vUCSORGBACK   then ParsePoint(p, hdr.Ucs.OriginBack)
      ;
    'V':
      if v = vVERSIONGUID then hdr.base.VersionGuild := ConsumeStr(p,2)
      else if v = vVISRETAIN then hdr.Base.isRetainXRefVis := ConsumeInt(p,CB_VARINT)
      ;
    'W':
      if v = vWORLDVIEW then hdr.Base.isWorldView := ConsumeInt(p,CB_VARINT)
      ;
    'X':
      if v = vXEDIT then hdr.base.isInPlaceEditin := ConsumeInt(p, 290)
      ;
  end;
end;

procedure ReadFile(const fn: string; dst: TDxfFile);
var
  f : TFileStream;
begin
  f := TFileStream.Create(fn, fmOpenRead or fmShareDenyNone);
  try
    ReadFile(f, dst);
  finally
    f.Free;
  end;
end;

procedure ReadFile(const st: TStream; dst: TDxfFile);
var
  sc : TDxfScanner;
  p  : TDxfParser;
begin
  sc := DxfAllocScanner(st, false);
  p := TDxfParser.Create;
  try
    p.scanner := sc;
    ReadFile(p, dst);
  finally
    p.Free;
    sc.Free;
  end;
end;

procedure ReadFile(p: TDxfParser; dst: TDxfFile);
var
  res  : TDxfParseToken;
  done : boolean;
  tbl  : TDxfTable;
  ent  : TDxfEntity;

  //ln, ofs: integer;
  b : TDxfFileBlock;
  dummyEnd : TDxfBlockEnd;
  cls : TDxfClass;
begin
  if not Assigned(p) or not Assigned(dst) then Exit;

  b:=nil;
  done := false;
  dummyEnd := TDxfBlockEnd.Create;
  try
    while not done do begin
      res := p.Next;
      case res of
        prVarName: begin
          ParseVariable(p, dst.header);
        end;

        prTableStart: begin
          tbl := dst.AddTable( p.tableName );
          tbl.Handle := p.tableHandle;
        end;

        prTableAttr: begin
          case p.scanner.CodeGroup of
            CB_NAME:   tbl.Name := p.tableName;
            CB_HANDLE: tbl.Handle := p.tableHandle;
          end;
        end;

        prBlockStart: begin
          b := dst.AddBlock;
          ParseBlock(p, b);
        end;

        prBlockEnd: begin
          if b<>nil then
            ParseBlockEnd(p, b._blockEnd)
          else
            ParseBlockEnd(p, dummyEnd);
          b := nil;
        end;

        prEntityStart, prEntityInBlock:
        begin
          ent := ParseEntityFromType(p, p.EntityType);
          if Assigned(b) then
            b.AddEntity(ent)
          else
            dst.AddEntity(ent);
        end;

        prClassStart:
        begin
          cls := dst.AddClass;
          ParseClass(p, cls);
        end;


        prSecEnd: begin
          tbl := nil;
          ent := nil;
        end;

        prError: begin
          done := true;
        end;
        prEof: begin
          done := true;
        end;

      else
       // prEntityAttr - we should never get this one!

      end;
    end;
  finally
    dummyEnd.Free;
  end;

end;

end.
