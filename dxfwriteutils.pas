unit dxfwriteutils;

interface

uses
  Classes, SysUtils,
  dxftypes, dxfwrite, dxfclasses;

procedure WriteBlock(w: TDxfWriter; const b: TDxfBlock);
procedure WriteBlockEnd(w: TDxfWriter; const b: TDxfBlockEnd);
procedure WritePoint(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer = 10);
procedure WriteExtrusionPoint(w: TDxfWriter; const b: TDxfPoint);
procedure WritePoint2D(w: TDxfWriter; const b: TDxfPoint; const XCodeBase: Integer = 10);

procedure WriteOptInt(w: TDxfWriter; v, def: Integer; codeGroup: integer);
procedure WriteOptFlt(w: TDxfWriter; v, def: double; codeGroup: integer; const epsilon: double = DEF_EPSILON);
procedure WriteOptStr(w: TDxfWriter; const v, def: string; codeGroup: integer);

// returns def, if check is an empty string (no trimming check)
// otherwise returns check
function IfEmpt(const check, def: string): string; inline;

procedure WriteHeaderVarStr(w: TDxfWriter; const Name: string; const v: string; codeGroup: Integer);
procedure WriteHeaderVarInt(w: TDxfWriter; const Name: string; v: Integer; codeGroup: Integer);
procedure WriteHeaderVarFlt(w: TDxfWriter; const Name: string; v: double; codeGroup: Integer = CB_VARFLOAT);
procedure WriteHeaderVarPnt(w: TDxfWriter; const Name: string; const v: TDxfPoint);
procedure WriteHeaderVarP2d(w: TDxfWriter; const Name: string; const v: TDxfPoint);

procedure WriteAcadHeader(w: TDxfWriter; const h: TDxfAcadHeader);

procedure WriteStartSection(w: TDxfWriter; const SecName: string);

procedure WriteEntityBase(w: TDxfWriter; e: TDxfEntity);

procedure WriteLine(w: TDxfWriter; l: TDxfLine);
procedure WriteCircle(w: TDxfWriter; c: TDxfCircle);

procedure WriteAnyEntity(w: TDxfWriter; e: TDxfEntity);
procedure WriteEntityList(w: TDxfWriter; lst: TList{of TDxfEntity});

procedure WriteHeaderVars(w: TDxfWriter; header: TDxfHeader);

procedure WriteFileAscii(const dstFn: string; src: TDxfFile);
procedure WriteFileAscii(const dst: TStream; src: TDxfFile);
procedure WriteFile(w: TDxfWriter; src: TDxfFile);

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

procedure WriteExtrusionPoint(w: TDxfWriter; const b: TDxfPoint);
begin
  if not Assigned(w) or isSamePoint(b, DefExtrusionPoint) then Exit; // it's the same as default
  WritePoint(w, b, CB_X_EXTRUSION);
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
procedure WriteBlockEnt(w: TDxfWriter; const b: TDxfBlockEntity);
begin
  w.WriteStr(CB_HANDLE, b.Handle);
  //if b.appDefGroup<>'' then begin
  //  // todo: support for custom application codes
  //end;
  w.WriteStr(CB_OWNERHANDLE, b.Owner);
  w.WriteStr(CB_SUBCLASS,    IfEmpt(b.SubClass, _AcDbEntity));
  WriteOptInt(w, b.SpaceFlag, 0, CB_SPACEFLAG);
  w.WriteStr(CB_LAYERNAME,   b.LayerName);
end;

procedure WriteBlock(w: TDxfWriter; const b: TDxfBlock);
begin
  if not Assigned(w) then Exit;
  WriteCtrl(w, NAME_BLOCK);
  WriteBlockEnt(w, b);
  w.WriteStr(CB_SUBCLASS, IfEmpt(b.Subclass2, _AcDbBlockBegin));
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
  WriteBlockEnt(w, b);
  w.WriteStr(CB_SUBCLASS, IfEmpt(b.Subclass2, _AcDbBlockEnd));
end;

procedure WriteHeaderVarStr(w: TDxfWriter; const Name: string; const v: string; codeGroup: Integer);
begin
  w.WriteStr(CB_VARNAME, Name);
  w.WriteStr(codeGroup, v);
end;

procedure WriteHeaderVarInt(w: TDxfWriter; const Name: string; v: Integer; codeGroup: Integer);
begin
  w.WriteStr(CB_VARNAME, Name);
  w.WriteInt(codeGroup, v);
end;

procedure WriteHeaderVarFlt(w: TDxfWriter; const Name: string; v: double; codeGroup: Integer);
begin
  w.WriteStr(CB_VARNAME, Name);
  w.WriteFloat(codeGroup, v);
end;

procedure WriteHeaderVarPnt(w: TDxfWriter; const Name: string;
  const v: TDxfPoint);
begin
  w.WriteStr(CB_VARNAME, Name);
  WritePoint(w, v)
end;

procedure WriteHeaderVarP2d(w: TDxfWriter; const Name: string;
  const v: TDxfPoint);
begin
  w.WriteStr(CB_VARNAME, Name);
  WritePoint2d(w, v)
end;

procedure WriteAcadHeader(w: TDxfWriter; const h: TDxfAcadHeader);
begin
  WriteHeaderVarStr(w, vACADVER, h.Version, CB_VARVALUE);
  if h.MaintVer<>0 then
    WriteHeaderVarInt(w, vACADMAINTVER, h.MaintVer, CB_FLAGS);
end;

procedure WriteStartSection(w: TDxfWriter; const SecName: string);
begin
  w.WriteStr(CB_CONTROL, NAME_SECTION);
  w.WriteStr(CB_SECTION_NAME, SecName);
end;

procedure WriteEntityBase(w: TDxfWriter; e: TDxfEntity);
begin
  if not Assigned(w) or not Assigned(e) or (e.EntityType ='') then Exit;
  w.WriteStr(CB_CONTROL, e.EntityType);
  w.WriteStr(CB_HANDLE, e.Handle);

  w.WriteStr(330, e.Owner);
  w.WriteStr(100, e.SubClass);
  if (e.SpaceFlag<>0) then w.WriteInt(67 , e.SpaceFlag);
  if (e.AppTableLayout<>'') then w.WriteStr(410, e.AppTableLayout);
  w.WriteStr(8  , e.LayerName    );
  if (e.LineTypeName<>'') and (e.LineTypeName<>'BYLAYER') then w.WriteStr(6  , e.LineTypeName );
  if (e.HardPtrId<>'') and (e.HardPtrId<>'BYLAYER') then w.WriteStr(347, e.HardPtrId    );
  if (e.ColorNumber<>256) then w.Writeint(62 , e.ColorNumber  );

  // according to documents, it's NOT omitted... hmm
  WriteOptInt(w, e.LineWidth, 0, 370);

  WriteOptFlt(w, e.LineScale, DEF_LINESCALE, 48);
  WriteOptInt(w, e.isHidden,  DEF_HIDDEN, 60);

  if (e.ProxyBytesCount>0) then begin
    w.WriteInt(92,e.ProxyBytesCount);
    //todo:
    //  e.ProxyGraph      := ConsumeInt array of byte; // 310s
  end;

  WriteOptInt(w, e.Color,        0,  420);
  WriteOptStr(w, e.ColorName,    '', 430);
  WriteOptInt(w, e.Transperancy, 0,  440);
  WriteOptStr(w, e.PlotObj,      '', 390);
  WriteOptInt(w, e.ShadowMode,   0,  284);

  w.WriteStr(100, e.Subclass2);
end;

procedure WriteLine(w: TDxfWriter; l: TDxfLine);
begin
  WriteEntityBase(w, l);
  WriteOptFlt(w, l.Thickness, DEF_THICKENS, CB_THICKNESS);
  WritePoint(w, l.StartPoint, CB_X);
  WritePoint(w, l.EndPoint, CB_X_ENDPOINT);
  WriteExtrusionPoint(w, l.Extrusion);
end;

procedure WriteCircle(w: TDxfWriter; c: TDxfCircle);
begin
  WriteEntityBase(w, c);
  WriteOptFlt(w, c.Thickness, DEF_THICKENS, CB_THICKNESS);
  WritePoint(w, c.CenterPoint);
  w.WriteFloat(CB_RADIUS, c.Radius);
  WriteExtrusionPoint(w, c.Extrusion);
end;

procedure WriteAnyEntity(w: TDxfWriter; e: TDxfEntity);
begin
  if not Assigned(w) or not Assigned(e) then Exit;
  if e is TDxfLine then WriteLine(w, TDxfLine(e))
  else if e is TDxfCircle then  WriteCircle(w, TDxfCircle(e))
end;

procedure WriteEntityList(w: TDxfWriter; lst: TList);
var
  i : integer;
begin
  if not Assigned(w) or not Assigned(lst) then Exit;
  for i:=0 to lst.Count-1 do
    WriteAnyEntity(w, TDxfEntity(lst[i]));
end;

procedure WriteFileAscii(const dstFn: string; src: TDxfFile);
var
  fs : TFileStream;
begin
  fs := TFileStream.Create(dstFn, fmCreate);
  try
    WriteFileAscii(fs, src);
  finally
    fs.Free;
  end;
end;

procedure WriteFileAscii(const dst: TStream; src: TDxfFile);
var
  w : TDxfAsciiWriter;
begin
  w := TDxfAsciiWriter.Create;
  try
    w.SetDest(dst, false);
    WriteFile(w, src);
  finally
    w.Free;
  end;
end;

procedure WriteHeaderVars(w: TDxfWriter; header: TDxfHeader);
begin
  WriteHeaderVarStr(w, vACADVER,      header.acad.Version,         CB_VARVALUE);
  WriteHeaderVarInt(w, vACADMAINTVER, header.acad.MaintVer,        CB_VARINT);

  WriteHeaderVarStr(w, vDWGCODEPAGE,  header.base.CodePage,        3);
  WriteHeaderVarPnt(w, vINSBASE,      header.Base.InsPoint);
  WriteHeaderVarPnt(w, vEXTMIN,       header.Base.ExtLowLeft);
  WriteHeaderVarPnt(w, vEXTMAX,       header.Base.ExtUpRight);
  WriteHeaderVarP2d(w, vLIMMIN,       header.Base.LimLowLeft);
  WriteHeaderVarP2d(w, vLIMMAX,       header.Base.LimUpRight);
  WriteHeaderVarInt(w, vORTHOMODE,    header.Base.isOrtho,         CB_VARINT);
  WriteHeaderVarInt(w, vREGENMODE,    header.Base.isRegen,         CB_VARINT);
  WriteHeaderVarInt(w, vFILLMODE,     header.Base.isFill,          CB_VARINT);
  WriteHeaderVarInt(w, vQTEXTMODE,    header.Base.isQText,         CB_VARINT);
  WriteHeaderVarInt(w, vMIRRTEXT,     header.Base.isMirrText,      CB_VARINT);
  WriteHeaderVarFlt(w, vLTSCALE,      header.Base.LineTypeScale);
  WriteHeaderVarInt(w, vATTMODE,      header.Base.AttrVisMode,     CB_VARINT);
  WriteHeaderVarFlt(w, vTEXTSIZE,     header.Base.TextHeight,      CB_VARFLOAT);
  WriteHeaderVarFlt(w, vTRACEWID,     header.Base.TraceWidth,      CB_VARFLOAT);
  WriteHeaderVarStr(w, vTEXTSTYLE,    header.Sel.TextStyle,        7);
  WriteHeaderVarStr(w, vCLAYER,       header.Sel.Layer,            CB_LAYERNAME);
  WriteHeaderVarStr(w, vCELTYPE,      header.Sel.EntLineType,      6);
  WriteHeaderVarInt(w, vCECOLOR,      header.Sel.EntColor,         62);
  WriteHeaderVarFlt(w, vCELTSCALE,    header.Sel.EntLineTypeScale);
  WriteHeaderVarInt(w, vDISPSILH,     header.Sel.DispSilhMode,     CB_VARINT);

  WriteHeaderVarFlt(w, vDIMSCALE     ,header.Dim.Scale     );
  WriteHeaderVarFlt(w, vDIMASZ       ,header.Dim.ArrowSize );
  WriteHeaderVarFlt(w, vDIMEXO       ,header.Dim.ExtLineOfs);
  WriteHeaderVarFlt(w, vDIMDLI       ,header.Dim.DimLineInc);
  WriteHeaderVarFlt(w, vDIMRND       ,header.Dim.RoundVal  );
  WriteHeaderVarFlt(w, vDIMDLE       ,header.Dim.DimLineExt);
  WriteHeaderVarFlt(w, vDIMEXE       ,header.Dim.ExtLineExt);
  WriteHeaderVarFlt(w, vDIMTP        ,header.Dim.PlusToler );
  WriteHeaderVarFlt(w, vDIMTM        ,header.Dim.MinusToler);
  WriteHeaderVarFlt(w, vDIMTXT       ,header.Dim.TextHeight);
  WriteHeaderVarFlt(w, vDIMCEN       ,header.Dim.CenterSize);
  WriteHeaderVarFlt(w, vDIMTSZ       ,header.Dim.TickSize  );
  WriteHeaderVarInt(w, vDIMTOL       ,header.Dim.Tolerance, CB_VARINT);
  WriteHeaderVarInt(w, vDIMLIM       ,header.Dim.Limits   , CB_VARINT);
  WriteHeaderVarInt(w, vDIMTIH       ,header.Dim.isTextIns, CB_VARINT);
  WriteHeaderVarInt(w, vDIMTOH       ,header.Dim.isTextOut, CB_VARINT);
  WriteHeaderVarInt(w, vDIMSE1       ,header.Dim.isSupExt1, CB_VARINT);
  WriteHeaderVarInt(w, vDIMSE2       ,header.Dim.isSupExt2, CB_VARINT);
  WriteHeaderVarInt(w, vDIMTAD       ,header.Dim.isTextAbove, CB_VARINT);
  WriteHeaderVarInt(w, vDIMZIN       ,header.Dim.SupZeros   , CB_VARINT);
  WriteHeaderVarStr(w, vDIMBLK       ,header.Dim.ArrowBlock ,  1);
  WriteHeaderVarInt(w, vDIMASO       ,header.Dim.isAssocDim , CB_VARINT);
  WriteHeaderVarInt(w, vDIMSHO       ,header.Dim.isRecompDim, CB_VARINT);
  WriteHeaderVarStr(w, vDIMPOST      ,header.Dim.Suffix      , 1);
  WriteHeaderVarStr(w, vDIMAPOST     ,header.Dim.AltSuffix   , 1);
  WriteHeaderVarInt(w, vDIMALT       ,header.Dim.isUseAltUnit, CB_VARINT);
  WriteHeaderVarInt(w, vDIMALTD      ,header.Dim.AltDec      , CB_VARINT);
  WriteHeaderVarFlt(w, vDIMALTF      ,header.Dim.AltScale    );
  WriteHeaderVarFlt(w, vDIMLFAC      ,header.Dim.LinearScale );
  WriteHeaderVarInt(w, vDIMTOFL      ,header.Dim.isTextOutExt , CB_VARINT);
  WriteHeaderVarFlt(w, vDIMTVP       ,header.Dim.TextVertPos   );
  WriteHeaderVarInt(w, vDIMTIX       ,header.Dim.isForceTextIns, CB_VARINT);
  WriteHeaderVarInt(w, vDIMSOXD      ,header.Dim.isSuppOutExt  , CB_VARINT);
  WriteHeaderVarInt(w, vDIMSAH       ,header.Dim.isUseSepArrow , CB_VARINT);
  WriteHeaderVarStr(w, vDIMBLK1      ,header.Dim.ArrowBlock1   , 1);
  WriteHeaderVarStr(w, vDIMBLK2      ,header.Dim.ArrowBlock2   , 1);
  WriteHeaderVarStr(w, vDIMSTYLE     ,header.Dim.StyleName     , 2);
  WriteHeaderVarInt(w, vDIMCLRD      ,header.Dim.LineColor     , CB_VARINT);
  WriteHeaderVarInt(w, vDIMCLRE      ,header.Dim.ExtLineColor  , CB_VARINT);
  WriteHeaderVarInt(w, vDIMCLRT      ,header.Dim.TextColor     , CB_VARINT);
  WriteHeaderVarFlt(w, vDIMTFAC      ,header.Dim.DispTolerance );
  WriteHeaderVarFlt(w, vDIMGAP       ,header.Dim.LineGap       );
  WriteHeaderVarInt(w, vDIMJUST      ,header.Dim.HorzTextJust  , CB_VARINT);
  WriteHeaderVarInt(w, vDIMSD1       ,header.Dim.isSuppLine1   , CB_VARINT);
  WriteHeaderVarInt(w, vDIMSD2       ,header.Dim.isSuppLine2   , CB_VARINT);
  WriteHeaderVarInt(w, vDIMTOLJ      ,header.Dim.VertJustTol   , CB_VARINT);
  WriteHeaderVarInt(w, vDIMTZIN      ,header.Dim.ZeroSupTol    , CB_VARINT);
  WriteHeaderVarInt(w, vDIMALTZ      ,header.Dim.ZeroSupAltUnitTol, CB_VARINT);
  WriteHeaderVarInt(w, vDIMALTTZ     ,header.Dim.ZeroSupAltTol   , CB_VARINT);
  WriteHeaderVarInt(w, vDIMUPT       ,header.Dim.isEditCursorText, CB_VARINT);
  WriteHeaderVarInt(w, vDIMDEC       ,header.Dim.DecPlacesPrim   , CB_VARINT);
  WriteHeaderVarInt(w, vDIMTDEC      ,header.Dim.DecPlacesOther  , CB_VARINT);
  WriteHeaderVarInt(w, vDIMALTU      ,header.Dim.UnitsFormat     , CB_VARINT);
  WriteHeaderVarInt(w, vDIMALTTD     ,header.Dim.DecPlacesAltUnit, CB_VARINT);
  WriteHeaderVarStr(w, vDIMTXSTY     ,header.Dim.TextStyle       , 7);
  WriteHeaderVarInt(w, vDIMAUNIT     ,header.Dim.AngleFormat     , CB_VARINT);
  WriteHeaderVarInt(w, vDIMADEC      ,header.Dim.AngleDecPlaces  , CB_VARINT);
  WriteHeaderVarFlt(w, vDIMALTRND    ,header.Dim.RoundValAlt     );
  WriteHeaderVarInt(w, vDIMAZIN      ,header.Dim.ZeroSupAngUnit  , CB_VARINT);
  WriteHeaderVarInt(w, vDIMDSEP      ,header.Dim.DecSeparator    , CB_VARINT);
  WriteHeaderVarInt(w, vDIMATFIT     ,header.Dim.TextArrowPlace  , CB_VARINT);
  WriteHeaderVarStr(w, vDIMLDRBLK    ,header.Dim.ArrowBlockLead  , 1);
  WriteHeaderVarInt(w, vDIMLUNIT     ,header.Dim.Units           , CB_VARINT);
  WriteHeaderVarInt(w, vDIMLWD       ,header.Dim.LineWeight      , CB_VARINT);
  WriteHeaderVarInt(w, vDIMLWE       ,header.Dim.LineWeightExt   , CB_VARINT);
  WriteHeaderVarInt(w, vDIMTMOVE     ,header.Dim.TextMove        , CB_VARINT);
end;

procedure WriteFile(w: TDxfWriter; src: TDxfFile);
var
  i  : integer;
  fb : TDxfFileBlock;
begin
  if not Assigned(w) or not Assigned(src) then Exit;
  WriteStartSection(w, NAME_HEADER);
  WriteHeaderVars(w, src.header);
  w.WriteStr(CB_CONTROL, NAME_ENDSEC);

  WriteStartSection(w, NAME_BLOCKS);
  for i := 0 to src.blocks.Count-1 do begin
    fb := TDxfFileBlock(src.blocks[i]);
    if not Assigned(fb) then Continue;
    WriteBlock(w, fb);
    WriteEntityList(w, fb._entities);
    WriteBlockEnd(w, fb._blockEnd);
  end;
  w.WriteStr(CB_CONTROL, NAME_ENDSEC);

  WriteStartSection(w, NAME_ENTITIES);
  WriteEntityList(w, src.entities);
  w.WriteStr(CB_CONTROL, NAME_ENDSEC);

  w.WriteStr(CB_CONTROL, NAME_EOF);
end;

procedure WriteOptInt(w: TDxfWriter; v, def: Integer; codeGroup: integer);
begin
  if v = def then Exit;
  w.WriteInt(codeGroup, v);
end;

procedure WriteOptFlt(w: TDxfWriter; v, def: double; codeGroup: integer; const epsilon: double);
begin
  if isSameDbl(v,def,epsilon) then Exit;
  w.WriteFloat(codeGroup, v);
end;

procedure WriteOptStr(w: TDxfWriter; const v, def: string; codeGroup: integer);
begin
  if ((def = '') and (v='')) or (def = v) then Exit;
  w.WriteStr(codeGroup, v);
end;


end.
