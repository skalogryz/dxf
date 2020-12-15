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
procedure WriteHeaderVarSpace(w: TDxfWriter; const hdr: TDxfSpacingHeader; isPaper: Boolean);

procedure WriteAcadHeader(w: TDxfWriter; const h: TDxfAcadHeader);

procedure WriteStartSection(w: TDxfWriter; const SecName: string);

procedure WriteEntityBase(w: TDxfWriter; e: TDxfEntity);

procedure WriteLine(w: TDxfWriter; l: TDxfLine);
procedure WriteCircle(w: TDxfWriter; c: TDxfCircle);

procedure WriteAnyEntity(w: TDxfWriter; e: TDxfEntity);
procedure WriteEntityList(w: TDxfWriter; lst: TList{of TDxfEntity});

procedure WriteTableEntry(w: TDxfWriter; e: TDxfTableEntry);
procedure WriteAppId(w: TDxfWriter; e: TDxfAppIdEntry);
procedure WriteBlockRecord(w: TDxfWriter; e: TDxfBlockRecordEntry);
procedure WriteDimStyle(w: TDxfWriter; e: TDxfDimStyleEntry);
procedure WriteLayerTableEntry(w: TDxfWriter; e: TDxfLayerEntry);
procedure WriteLType(w: TDxfWriter; e: TDxfLTypeEntry);
procedure WriteStyleTableEntry(w: TDxfWriter; e: TDxfStyleEntry);
procedure WriteUCSTableEntry(w: TDxfWriter; e: TDxfUCSEntry);
procedure WriteView(w: TDxfWriter; e: TDxfViewEntry);
procedure WriteVPort(w: TDxfWriter; e: TDxfVPortEntry);
procedure WriteAnyEntry(w: TDxfWriter; e: TDxfTableEntry);

procedure WriteTableHeader(w: TDxfWriter; tbl: TDxfTable);
procedure WriteTable(w: TDxfWriter; tbl: TDxfTable);
procedure WriteHeaderVars(w: TDxfWriter; header: TDxfHeader);

procedure Write102Values(w: TDxfWriter; vl: TDxfValuesList);
procedure WriteObject(w: TDxfWriter; obj: TDxfObject);
procedure WriteAcDbDictionaryWDFLT(w: TDxfWriter; obj: TDxfAcDbDictionaryWDFLT);
procedure WriteDictionary(w: TDxfWriter; obj: TDxfDictionary);
procedure WriteXRecord(w: TDxfWriter; obj: TDxfXRecord);
procedure WriteTableStyle(w: TDxfWriter; obj: TDxfTableStyle);
procedure WriteAnyObject(w: TDxfWriter; obj: TDxfObject);

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

procedure WriteClass(w: TDxfWriter; c: TDxfClass);
begin
  if not Assigned(w) or not Assigned(c) then Exit;
  WriteCtrl(w, NAME_CLASS);
  w.WriteStr(CB_DXFRECNAME, c.recName   );  {1  }
  w.WriteStr(CB_CPPNAME   , c.cppName   );  {2  }
  w.WriteStr(CB_APPANME   , c.appName   );  {3  }
  w.WriteInt(CB_PROXYFLAG , c.ProxyFlags);  {90 }
  WriteOptInt(w, c.InstCount, 0, CB_INSTCOUNT );  {91 }
  w.WriteInt(CB_WASAPROXY , c.WasProxy  );  {280}
  w.WriteInt(CB_ISENTITY  , c.IsAnEntity);  {281}
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

procedure WriteHeaderVarSpace(w: TDxfWriter; const hdr: TDxfSpacingHeader; isPaper: Boolean);
begin
  if isPaper then begin
    WriteHeaderVarStr(w, vPUCSBASE      , hdr.Base, 2);
    WriteHeaderVarStr(w, vPUCSNAME      , hdr.Name, 2);
    WriteHeaderVarPnt(w, vPUCSORG       , hdr.Origin);
    WriteHeaderVarPnt(w, vPUCSXDIR      , hdr.XDir);
    WriteHeaderVarPnt(w, vPUCSYDIR      , hdr.YDir);

    WriteHeaderVarStr(w, vPUCSORTHOREF  , hdr.OrthoRef, 2);
    WriteHeaderVarInt(w, vPUCSORTHOVIEW , hdr.OrthoView, CB_VARINT);
    WriteHeaderVarPnt(w, vPUCSORGTOP    , hdr.OriginTop);
    WriteHeaderVarPnt(w, vPUCSORGBOTTOM , hdr.OriginBottom);
    WriteHeaderVarPnt(w, vPUCSORGLEFT   , hdr.OriginLeft);

    WriteHeaderVarPnt(w, vPUCSORGRIGHT  , hdr.OriginRight);
    WriteHeaderVarPnt(w, vPUCSORGFRONT  , hdr.OriginFront);
    WriteHeaderVarPnt(w, vPUCSORGBACK   , hdr.OriginBack);
  end else begin
    WriteHeaderVarStr(w, vUCSBASE      , hdr.Base, 2);
    WriteHeaderVarStr(w, vUCSNAME      , hdr.Name, 2);
    WriteHeaderVarPnt(w, vUCSORG       , hdr.Origin);
    WriteHeaderVarPnt(w, vUCSXDIR      , hdr.XDir);
    WriteHeaderVarPnt(w, vUCSYDIR      , hdr.YDir);

    WriteHeaderVarStr(w, vUCSORTHOREF  , hdr.OrthoRef, 2);
    WriteHeaderVarInt(w, vUCSORTHOVIEW , hdr.OrthoView, CB_VARINT);
    WriteHeaderVarPnt(w, vUCSORGTOP    , hdr.OriginTop);
    WriteHeaderVarPnt(w, vUCSORGBOTTOM , hdr.OriginBottom);
    WriteHeaderVarPnt(w, vUCSORGLEFT   , hdr.OriginLeft);

    WriteHeaderVarPnt(w, vUCSORGRIGHT  , hdr.OriginRight);
    WriteHeaderVarPnt(w, vUCSORGFRONT  , hdr.OriginFront);
    WriteHeaderVarPnt(w, vUCSORGBACK   , hdr.OriginBack);
  end;
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

procedure Write102Values(w: TDxfWriter; vl: TDxfValuesList);
var
  i : integer;
  v : TDxfValue;
begin
  if not Assigned(w) or not Assigned(vl) or (vl.Count = 0) then Exit;
  w.WriteStr(CB_GROUPSTART, vl.Name);
  for i:=0 to vl.Count-1 do begin
    v := TDxfValue(vl.values[i]);
    case v.valType of
      dvtStr: w.WriteStr(v.cg, v.s);
      dvtInt: w.WriteInt(v.cg, v.i);
      dvtInt64: w.WriteInt(v.cg, v.i64);
      dvtFloat: w.WriteFloat(v.cg, v.f);
    end;
  end;
  w.WriteStr(CB_GROUPSTART, '}');
end;

procedure WriteObject(w: TDxfWriter; obj: TDxfObject);
begin
  WriteCtrl(w, obj.ObjectType);
  w.WriteStr(CB_HANDLE, obj.Handle);
  Write102Values(w, obj.AppCodes);
  Write102Values(w, obj.Reactors);
  Write102Values(w, obj.XDict);
  w.WriteStr(CB_OWNERHANDLE, obj.Owner);
end;

procedure WriteAcDbDictionaryWDFLT(w: TDxfWriter; obj: TDxfAcDbDictionaryWDFLT);
var
  i   : integer;
  de  : TDxfDictionaryEntry;
begin
  WriteObject(w, obj);
  w.WriteStr(CB_SUBCLASS, obj.SubClass2);
  w.WriteInt(281, obj.CloneFlag);
  for i := 0 to obj.Entries.Count-1 do begin
    de := TDxfDictionaryEntry(obj.Entries[i]);
    w.WriteStr(CB_DICT_ENTRYNAME,  de.EntryName);
    w.WriteStr(CB_DICT_ENTRYOWNER, de.Owner);
  end;
  w.WriteStr(CB_SUBCLASS, obj.SubClass3);
  w.WriteStr(340, obj.DefaultID);
end;

procedure WriteDictionary(w: TDxfWriter; obj: TDxfDictionary);
var
  de : TDxfDictionaryEntry;
  i  : Integer;
const
  ACAD_XREC_ROUNDTRIP = 'ACAD_XREC_ROUNDTRIP'; // something special?
begin
  WriteObject(w, obj);
  w.WriteStr(CB_SUBCLASS, obj.SubClass2);
  WriteOptInt( w, obj.isHardOwner, 0, 280);
  w.WriteInt(281, obj.CloneFlag);
  for i := 0 to obj.Entries.Count-1 do begin
    de := TDxfDictionaryEntry(obj.Entries[i]);
    w.WriteStr(CB_DICT_ENTRYNAME,  de.EntryName);
    if de.EntryName = ACAD_XREC_ROUNDTRIP then
      w.WriteStr(360, de.Owner)
    else
      w.WriteStr(CB_DICT_ENTRYOWNER, de.Owner);
  end;
end;

procedure WriteDictionaryVar(w: TDxfWriter; obj: TDxfDictionaryVar);
begin
  WriteObject(w, obj);
  w.WriteStr(CB_SUBCLASS, obj.SubClass2);
  w.WriteInt(280, obj.SchemaNum);
  w.WriteStr(1,   obj.Value);
end;

procedure WriteXRecord(w: TDxfWriter; obj: TDxfXRecord);
var
  i : integer;
  v : TDxfValue;
begin
  WriteObject(w, obj);
  w.WriteStr(CB_SUBCLASS, obj.SubClass2);
  w.WriteInt(280, obj.CloneFlag);
  for i:= 0 to obj.XRec.Count-1 do begin
    v := TDxfValue(obj.XRec.values[i]);
    case v.valType of
      dvtInt:   w.WriteInt(v.cg, v.i);
      dvtInt64: w.WriteInt(v.cg, v.i64);
      dvtFloat: w.WriteFloat(v.cg, v.f);
    else
      w.WriteStr(v.cg, v.s);
    end;
  end;
end;

procedure WriteTableStyle(w: TDxfWriter; obj: TDxfTableStyle);
var
  c : TDxfTableCell;
  i : integer;
begin
  WriteObject(w, obj);
  w.WriteStr  (CB_SUBCLASS, obj.SubClass2);
  w.WriteInt  (280, obj.VerNum );
  w.WriteStr  (  3, obj.Descr  );
  w.WriteInt  ( 70, obj.FlowDir);
  w.WriteInt  ( 71, obj.Flags  );
  w.WriteFloat( 40, obj.HorzMargin);
  w.WriteFloat( 41, obj.VertMargin);
  w.WriteInt  (280, obj.isTitleSupp);
  w.WriteInt  (281, obj.isColHeadSupp);

  for i:=0 to obj.Cells.Count-1 do begin
    c := TDxfTableCell(obj.Cells[i]);
    w.WriteStr(7, c.StyleName);
    WriteOptFlt(w, c.Height        ,0, 140);
    WriteOptInt(w, c.Align         ,0, 170);
    WriteOptInt(w, c.Color         ,-1,  62);
    WriteOptInt(w, c.FillColor     ,0,  63);
    WriteOptInt(w, c.isUseFillColor,-1, 283);
    WriteOptInt(w, c.CellDataType  ,0,  90);
    WriteOptInt(w, c.CellUnit      ,0,  91);

    WriteOptInt(w, c.BordType1     ,-1, 274);
    WriteOptInt(w, c.isBordVis1    ,-1, 284);
    WriteOptInt(w, c.BordColor1    ,-1,  64);

    WriteOptInt(w, c.BordType2     ,-1, 275);
    WriteOptInt(w, c.isBordVis2    ,-1, 285);
    WriteOptInt(w, c.BordColor2    ,-1,  65);

    WriteOptInt(w, c.BordType3     ,-1, 276);
    WriteOptInt(w, c.isBordVis3    ,-1, 286);
    WriteOptInt(w, c.BordColor3    ,-1,  66);

    WriteOptInt(w, c.BordType4     ,-1, 277);
    WriteOptInt(w, c.isBordVis4    ,-1, 287);
    WriteOptInt(w, c.BordColor4    ,-1,  67);

    WriteOptInt(w, c.BordType5     ,-1, 278);
    WriteOptInt(w, c.isBordVis5    ,-1, 288);
    WriteOptInt(w, c.BordColor5    ,-1,  68);

    WriteOptInt(w, c.BordType6     ,-1, 279);
    WriteOptInt(w, c.isBordVis6    ,-1, 289);
    WriteOptInt(w, c.BordColor6    ,-1,  69);
  end;

end;

procedure WriteAnyObject(w: TDxfWriter; obj: TDxfObject);
begin
  if not Assigned(w) or not Assigned(obj) then Exit;
  if obj is TDxfDictionary then WriteDictionary(w, TDxfDictionary(obj))
  else if obj is TDxfAcDbDictionaryWDFLT then WriteAcDbDictionaryWDFLT(w, TDxfAcDbDictionaryWDFLT(obj))
  else if obj is TDxfXRecord then WriteXRecord(w, TDxfXRecord(obj))
  else if obj is TDxfTableStyle then WriteTableStyle(w, TDxfTableStyle(obj))
  else if obj is TDxfDictionaryVar then WriteDictionaryVar(w, TDxfDictionaryVar(obj))
  ;
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

procedure WriteTable(w: TDxfWriter; tbl: TDxfTable);
var
  i : integer;
begin
  if not Assigned(w) or not Assigned(tbl) then Exit;
  WriteTableHeader(w, tbl);
  for i:=0 to tbl.Count-1 do
    WriteAnyEntry(w, tbl.Entry[i]);
  WriteCtrl(w, NAME_ENDTAB);
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

  WriteHeaderVarInt(w, vLUNITS       ,header.Base.DistFormat     , CB_VARINT);
  WriteHeaderVarInt(w, vLUPREC       ,header.base.DistPrec       , CB_VARINT);
  WriteHeaderVarFlt(w, vSKETCHINC    ,header.base.SketchInc      );
  WriteHeaderVarFlt(w, vFILLETRAD    ,header.base.FilletRadius   );
  WriteHeaderVarInt(w, vAUNITS       ,header.base.AnglesFormat   , CB_VARINT);
  WriteHeaderVarInt(w, vAUPREC       ,header.base.AnglesPrec     , CB_VARINT);
  WriteHeaderVarStr(w, vMENU         ,header.base.MenuName       , 1);
  WriteHeaderVarFlt(w, vELEVATION    ,header.Sel.Elev      );
  WriteHeaderVarFlt(w, vPELEVATION   ,header.sel.PaperElev );
  WriteHeaderVarFlt(w, vTHICKNESS    ,header.sel.Thickness );
  WriteHeaderVarInt(w, vLIMCHECK     ,header.base.isLimCheck     , CB_VARINT);
  WriteHeaderVarFlt(w, vCHAMFERA     ,header.base.ChamferDist1   );
  WriteHeaderVarFlt(w, vCHAMFERB     ,header.base.ChamferDist2   );
  WriteHeaderVarFlt(w, vCHAMFERC     ,header.base.ChamferLen     );
  WriteHeaderVarFlt(w, vCHAMFERD     ,header.base.ChamferAngle   );
  WriteHeaderVarInt(w, vSKPOLY       ,header.base.isSketchPoly   , CB_VARINT);

  WriteHeaderVarFlt(w, vTDCREATE     ,header.Time.CreateTimeLocal );
  WriteHeaderVarFlt(w, vTDUCREATE    ,header.Time.CreateTimeUniv  );
  WriteHeaderVarFlt(w, vTDUPDATE     ,header.Time.UpdateTimeLocal );
  WriteHeaderVarFlt(w, vTDUUPDATE    ,header.Time.UpdateTimeUniv  );
  WriteHeaderVarFlt(w, vTDINDWG      ,header.Time.TotalTime       );
  WriteHeaderVarFlt(w, vTDUSRTIMER   ,header.Time.ElasedTime      );
  WriteHeaderVarInt(w, vUSRTIMER     ,header.Time.isTimerOn , CB_VARINT);

  WriteHeaderVarFlt(w, vANGBASE      ,header.base.AngleBase      , 50 );
  WriteHeaderVarInt(w, vANGDIR       ,header.base.isClockWise    , CB_VARINT);

  WriteHeaderVarInt(w, vPDMODE       ,header.base.PtDispMode     , CB_VARINT);
  WriteHeaderVarFlt(w, vPDSIZE       ,header.base.PtDispSize     );
  WriteHeaderVarFlt(w, vPLINEWID     ,header.base.DefPolyWidth   );
    //: Integer; // ($SPLFRAME) 70
  WriteHeaderVarInt(w, vSPLINETYPE   ,header.base.SplineCurvType , CB_VARINT);
  WriteHeaderVarInt(w, vSPLINESEGS   ,header.base.LineSegments   , CB_VARINT);
  WriteHeaderVarStr(w, vHANDSEED     ,header.base.NextHandle     , 5);
  WriteHeaderVarInt(w, vSURFTAB1     ,header.base.MeshCount1     , CB_VARINT);
  WriteHeaderVarInt(w, vSURFTAB2     ,header.base.MeshCount2     , CB_VARINT);
  WriteHeaderVarInt(w, vSURFTYPE     ,header.base.SurfType       , CB_VARINT);
  WriteHeaderVarInt(w, vSURFU        ,header.base.SurfDensityM   , CB_VARINT);
  WriteHeaderVarInt(w, vSURFV        ,header.base.SurfDensityN   , CB_VARINT);

  WriteHeaderVarSpace(w, header.Ucs, false);
  WriteHeaderVarSpace(w, header.PUcs, true);

  WriteHeaderVarInt(w, vUSERI1       ,header.User.I1, CB_VARINT);
  WriteHeaderVarInt(w, vUSERI2       ,header.User.I2, CB_VARINT);
  WriteHeaderVarInt(w, vUSERI3       ,header.User.I3, CB_VARINT);
  WriteHeaderVarInt(w, vUSERI4       ,header.User.I4, CB_VARINT);
  WriteHeaderVarInt(w, vUSERI5       ,header.User.I5, CB_VARINT);
  WriteHeaderVarFlt(w, vUSERR1       ,header.User.R1, CB_VARFLOAT);
  WriteHeaderVarFlt(w, vUSERR2       ,header.User.R2, CB_VARFLOAT);
  WriteHeaderVarFlt(w, vUSERR3       ,header.User.R3, CB_VARFLOAT);
  WriteHeaderVarFlt(w, vUSERR4       ,header.User.R4, CB_VARFLOAT);
  WriteHeaderVarFlt(w, vUSERR5       ,header.User.R5, CB_VARFLOAT);

  WriteHeaderVarInt(w, vWORLDVIEW       ,header.Base.isWorldView      ,CB_VARINT);
  WriteHeaderVarInt(w, vSHADEDGE        ,header.Base.ShadeEdge        ,CB_VARINT);
  WriteHeaderVarInt(w, vSHADEDIF        ,header.Base.ShadeDiffuse     ,CB_VARINT);
  WriteHeaderVarInt(w, vTILEMODE        ,header.Base.isTileMode       ,CB_VARINT);
  WriteHeaderVarInt(w, vMAXACTVP        ,header.Base.MaxViewPorts     ,CB_VARINT);
  WriteHeaderVarPnt(w, vPINSBASE        ,header.Base.PaperInsPoint);
  WriteHeaderVarInt(w, vPLIMCHECK       ,header.Base.isPaperLimCheck  ,CB_VARINT);
  WriteHeaderVarPnt(w, vPEXTMIN         ,header.Base.PaperExtLowLeft);
  WriteHeaderVarPnt(w, vPEXTMAX         ,header.Base.PaperExtUpRight);
  WriteHeaderVarP2d(w, vPLIMMIN         ,header.Base.PaperLimLowLeft);
  WriteHeaderVarP2d(w, vPLIMMAX         ,header.Base.PaperLimUpRight);
  WriteHeaderVarInt(w, vUNITMODE        ,header.Base.UnitMode         ,CB_VARINT);
  WriteHeaderVarInt(w, vVISRETAIN       ,header.Base.isRetainXRefVis  ,CB_VARINT);
  WriteHeaderVarInt(w, vPLINEGEN        ,header.Base.LineTypePatt     ,CB_VARINT);
  WriteHeaderVarInt(w, vPSLTSCALE       ,header.Base.PaperLineScaling ,CB_VARINT);
  WriteHeaderVarInt(w, vTREEDEPTH       ,header.Base.SpaceTreeDepth   ,CB_VARINT);
  WriteHeaderVarStr(w, vCMLSTYLE        ,header.Sel.MultiLineStyle    ,2);
  WriteHeaderVarInt(w, vCMLJUST         ,header.Sel.MultiLineJust     ,CB_VARINT);
  WriteHeaderVarFlt(w, vCMLSCALE        ,header.Sel.MultiLineScale    ,40);
  WriteHeaderVarInt(w, vPROXYGRAPHICS   ,header.base.isProxyImageSave ,CB_VARINT);
  WriteHeaderVarInt(w, vMEASUREMENT     ,header.base.MeasureUnits     ,CB_VARINT);
  WriteHeaderVarInt(w, vCELWEIGHT       ,header.base.NewObjLineWeight ,370);
  WriteHeaderVarInt(w, vENDCAPS         ,header.base.LineEndCaps      ,280);
  WriteHeaderVarInt(w, vJOINSTYLE       ,header.base.LineJointStyle   ,280);
  WriteHeaderVarInt(w, vLWDISPLAY       ,header.base.isLineShow       ,290);
  WriteHeaderVarInt(w, vINSUNITS        ,header.base.DefaultUnits     ,CB_VARINT);
  WriteHeaderVarStr(w, vHYPERLINKBASE   ,header.base.RelHyperLink     ,1);
  WriteHeaderVarInt(w, vXEDIT           ,header.base.isInPlaceEditin  ,290);
  WriteHeaderVarInt(w, vCEPSNTYPE       ,header.base.PlotStype        ,380);
  WriteHeaderVarInt(w, vPSTYLEMODE      ,header.base.isColorDepmode   ,290);
  WriteHeaderVarStr(w, vFINGERPRINTGUID ,header.base.FingerPrintGuid  ,2);
  WriteHeaderVarStr(w, vVERSIONGUID     ,header.base.VersionGuild     ,2);
  WriteHeaderVarInt(w, vEXTNAMES        ,header.acad.isExtNames       ,290);
  WriteHeaderVarFlt(w, vPSVPSCALE       ,header.base.ViewPortScale    ,40);

end;

procedure WriteFile(w: TDxfWriter; src: TDxfFile);
var
  i   : integer;
  fb  : TDxfFileBlock;
  cl  : TDxfClass;
  obj : TDxfObject;
begin
  if not Assigned(w) or not Assigned(src) then Exit;
  WriteStartSection(w, NAME_HEADER);
  WriteHeaderVars(w, src.header);
  w.WriteStr(CB_CONTROL, NAME_ENDSEC);

  WriteStartSection(w, NAME_CLASSES);
  for i := 0 to src.classes.Count - 1 do begin
    cl := TDxfClass(src.classes[i]);
    WriteClass(w, cl);
  end;
  w.WriteStr(CB_CONTROL, NAME_ENDSEC);

  WriteStartSection(w, NAME_TABLES);
  for i := 0 to src.tables.Count - 1 do begin
    WriteTable(w, TDxfTable(src.tables[i]));
  end;
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

  WriteStartSection(w, NAME_OBJECTS);
  for i := 0 to src.objects.Count - 1 do begin
    obj := TDxfObject(src.objects[i]);
    WriteAnyObject(w, obj);
  end;
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

procedure WriteTableEntry(w: TDxfWriter; e: TDxfTableEntry);
begin
  WriteCtrl(w, e.EntryType);
  if e.EntryType = NAME_DIMSTYLE then
    w.WriteStr(CB_DIMHANDLE, e.Handle)
  else
    w.WriteStr(CB_HANDLE, e.Handle);
  w.WriteStr(CB_OWNERHANDLE, e.Owner);
  w.WriteStr(CB_SUBCLASS, e.SubClass);
end;

procedure WriteAppId(w: TDxfWriter; e: TDxfAppIdEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr( CB_SUBCLASS, e.SubClass2);
  w.WriteStr( CB_NAME    , e.AppData  );
  w.WriteInt( CB_VARINT  , e.Flags    );
end;

procedure WriteBlockRecord(w: TDxfWriter; e: TDxfBlockRecordEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr(CB_SUBCLASS ,e.SubClass2   );
  w.WriteStr(CB_NAME     ,e.BlockName   );
  w.WriteStr(340         ,e.LayoutId    );
  WriteOptInt(w, e.InsertUnit,   0, CB_VARINT);
  WriteOptInt(w, e.isExplodable, 0,  280);
  WriteOptInt(w, e.isScalable,   0,  281);
  WriteOptStr(w, e.PreviewBin,  '',  310);
  WriteOptInt(w, e.isScalable,   0,  281);
  WriteoptStr(w, e.XDataApp,    '', 1001);
end;

procedure WriteDimStyle(w: TDxfWriter; e: TDxfDimStyleEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr(CB_SUBCLASS, e.SubClass2);
  w.WriteStr(CB_NAME,   e.Dim.StyleName);
  w.WriteInt(CB_VARINT, e.Flags);

  WriteOptStr(w ,e.Dim.Suffix        ,'',  3 );
  WriteOptStr(w ,e.Dim.AltSuffix     ,'',  4 );
  WriteOptStr(w ,e.Dim.ArrowBlock    ,'',  5 );
  WriteOptStr(w ,e.Dim.ArrowBlock1   ,'',  6 );
  WriteOptStr(w ,e.Dim.ArrowBlock2   ,'',  7 );
  WriteOptFlt(w ,e.Dim.Scale         ,0 ,  40 );
  WriteOptFlt(w ,e.Dim.ArrowSize     ,0 ,  41);
  WriteOptFlt(w ,e.Dim.ExtLineOfs    ,0 ,  42);
  WriteOptFlt(w ,e.Dim.DimLineInc    ,0 ,  43);
  WriteOptFlt(w ,e.Dim.ExtLineExt    ,0 ,  44);
  WriteOptFlt(w ,e.Dim.RoundVal      ,0 ,  45);
  WriteOptFlt(w ,e.Dim.DimLineExt    ,0 ,  46);
  WriteOptFlt(w ,e.Dim.PlusToler     ,0 ,  47);
  WriteOptFlt(w ,e.Dim.MinusToler    ,0 ,  48);
  WriteOptFlt(w ,e.Dim.TextHeight    ,0 , 140);
  WriteOptFlt(w ,e.Dim.CenterSize    ,0 , 141);
  WriteOptFlt(w ,e.Dim.TickSize      ,0 , 142);
  WriteOptFlt(w ,e.Dim.AltScale      ,0 , 143);
  WriteOptFlt(w ,e.Dim.LinearScale   ,0 , 144);
  WriteOptFlt(w ,e.Dim.TextVertPos   ,0 , 145);
  WriteOptFlt(w ,e.Dim.DispTolerance ,0 , 146);
  WriteOptFlt(w ,e.Dim.LineGap       ,0 , 147);
  WriteOptFlt(w ,e.Dim.RoundValAlt   ,0 , 148);
  WriteOptInt(w ,e.Dim.Tolerance     ,0 ,  71);
  WriteOptInt(w ,e.Dim.Limits        ,0 ,  72);
  w.WriteInt( 73 ,e.Dim.isTextIns        );
  WriteOptInt(w ,e.Dim.isTextOut     ,0 ,  74);
  WriteOptInt(w ,e.Dim.isSupExt1     ,0 ,  75);
  WriteOptInt(w ,e.Dim.isSupExt2     ,0 ,  76);
  w.WriteInt( 77 ,e.Dim.isTextAbove      );
  w.WriteInt( 78 ,e.Dim.SupZeros         );
  w.WriteInt( 79 ,e.Dim.ZeroSupAngUnit   );
  w.WriteInt(170 ,e.Dim.isUseAltUnit     );
  w.WriteInt(171 ,e.Dim.AltDec           );
  w.WriteInt(172 ,e.Dim.isTextOutExt     );
  WriteOptInt(w ,e.Dim.isUseSepArrow ,0  , 173);
  WriteOptInt(w ,e.Dim.isForceTextIns,0  , 174);
  WriteOptInt(w ,e.Dim.isSuppOutExt  ,0  , 175);
  w.WriteInt(176 ,e.Dim.LineColor        );
  w.WriteInt(177 ,e.Dim.ExtLineColor     );
  w.WriteInt(178 ,e.Dim.TextColor        );
  WriteOptInt(w ,e.Dim.AngleDecPlaces  ,0, 179);
  WriteOptInt(w ,e.Dim.__Units         ,0, 270);
  WriteOptInt(w ,e.Dim.DecPlacesPrim   ,0, 271);
  WriteOptInt(w ,e.Dim.DecPlacesOther  ,0, 272);
  WriteOptInt(w ,e.Dim.UnitsFormat     ,0, 273);
  WriteOptInt(w ,e.Dim.DecPlacesAltUnit,0, 274);
  WriteOptInt(w ,e.Dim.AngleFormat     ,0, 275);
  WriteOptInt(w ,e.Dim.UnitFrac        ,0, 276);
  WriteOptInt(w ,e.Dim.Units           ,0, 277);
  WriteOptInt(w ,e.Dim.DecSeparator    ,0, 278);
  WriteOptInt(w ,e.Dim.TextMove        ,0, 279);
  WriteOptInt(w ,e.Dim.HorzTextJust    ,0, 280);
  WriteOptInt(w ,e.Dim.isSuppLine1     ,0, 281);
  WriteOptInt(w ,e.Dim.isSuppLine2     ,0, 282);
  WriteOptInt(w ,e.Dim.VertJustTol     ,0, 283);
  WriteOptInt(w ,e.Dim.ZeroSupTol       ,0,284);
  WriteOptInt(w ,e.Dim.ZeroSupAltUnitTol,0,285);
  WriteOptInt(w ,e.Dim.ZeroSupAltTol    ,0,286);
  WriteOptInt(w ,e.Dim.__TextArrowPlace ,0,287);
  WriteOptInt(w ,e.Dim.isEditCursorText ,0,288);
  WriteOptInt(w ,e.Dim.TextArrowPlace   ,0,289);
  WriteOptStr(w ,e.Dim.TextStyle       ,'',340);
  WriteOptStr(w ,e.Dim.ArrowBlockLead  ,'',341);
  WriteOptStr(w ,e.Dim.ArrowBlockId    ,'',342);
  WriteOptStr(w ,e.Dim.ArrowBlockId1   ,'',343);
  WriteOptStr(w ,e.Dim.ArrowBlockId2   ,'',344);
  WriteOptInt(w ,e.Dim.LineWeight       ,0,371);
  WriteOptInt(w ,e.Dim.LineWeightExt    ,0,372);
end;

procedure WriteLayerTableEntry(w: TDxfWriter; e: TDxfLayerEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr(100, e.SubClass2  );
  w.WriteStr(  2, e.LayerName  );
  w.WriteInt( 70, e.Flags      );
  w.WriteInt( 62, e.ColorNum   );
  w.WriteStr(  6, e.LineType   );
  WriteOptInt(w, e.isPlotting, 0, 290);
  w.WriteInt(370, e.Lineweight );
  w.WriteStr(390, e.PlotStyleID);
  WriteOptStr(w, e.MatObjID, '', 347);
end;

procedure WriteLType(w: TDxfWriter; e: TDxfLTypeEntry);
var
  i : integer;
begin
  WriteTableEntry(w, e);
  w.WriteStr  (100, e.SubClass2    );
  w.WriteStr  (  2, e.LineType     );
  w.WriteInt  ( 70, e.Flags        );
  w.WriteStr  (  3, e.Descr        );
  w.WriteInt  ( 72, e.AlignCode    );
  w.WriteInt  ( 73, e.LineTypeElems);
  w.WriteFloat( 40, e.TotalPatLen  );
  WriteOptFlt(w, e.Len,        0, 49);
  WriteOptInt(w, e.Flags2,     0, 74);
  WriteOptInt(w, e.ShapeNum,   0, 75);
  WriteOptStr(w, e.StyleObjId,'',340);

  for i:=0 to length(e.ScaleVal)-1 do  WriteOptFlt(w, e.ScaleVal[i],  0, 46);
  for i:=0 to length(e.RotateVal)-1 do WriteOptFlt(w, e.RotateVal[i], 0, 50);
  for i:=0 to length(e.XOfs)-1 do      WriteOptFlt(w, e.XOfs[i],      0, 44);
  for i:=0 to length(e.YOfs)-1 do      WriteOptFlt(w, e.YOfs[i],      0, 45);

  WriteOptStr(w, e.TextStr,'',9);
end;

procedure WriteStyleTableEntry(w: TDxfWriter; e: TDxfStyleEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr  ( 100 , e.SubClass2  );
  w.WriteStr  (   2 , e.StyleName  );
  w.WriteInt  (  70 , e.Flags      );
  w.WriteFloat(  40 , e.FixedHeight);
  w.WriteFloat(  41 , e.WidthFactor);
  w.WriteFloat(  50 , e.Angle      );
  w.WriteInt  (  71 , e.TextFlags  );
  w.WriteFloat(  42 , e.LastHeight );
  w.WriteStr  (   3 , e.FontName   );
  w.WriteStr  (   4 , e.BigFontName);
  WriteOptStr (w, e.FullFont, '', 1017);
end;

procedure WriteUCSTableEntry(w: TDxfWriter; e: TDxfUCSEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr  (100, e.SubClass2);
  w.WriteStr  (  2, e.UCSName  );
  w.WriteInt  ( 70, e.Flags    );
  WritePoint(w, e.Origin, 10);
  WritePoint(w, e.XDir,   11);
  WritePoint(w, e.YDir,   12);
  w.WriteInt  ( 79, e.Zero     );
  w.WriteFloat(146, e.Elev     );
  w.WriteStr  (346, e.BaseUCS  );
  w.WriteInt  ( 71, e.OrthType );
  WritePoint(w, e.UCSRelOfs, 13);
end;

procedure WriteView(w: TDxfWriter; e: TDxfViewEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr  (100 , e.SubClass2);
  w.WriteStr  (  2 , e.ViewName );
  w.WriteInt  ( 70 , e.Flags    );
  w.WriteFloat( 40 , e.Height   );
  WritePoint2D(w, e.CenterPoint, 10);
  w.WriteFloat(41  , e.Width);
  WritePoint  (w, e.ViewDir,     11);
  WritePoint  (w, e.TargetPoint, 12);
  w.WriteFloat( 42, e.LensLen     );
  w.WriteFloat( 43, e.FontClipOfs );
  w.WriteFloat( 44, e.BackClipOfs );
  w.WriteFloat( 50, e.TwistAngle  );
  w.WriteInt  ( 71, e.ViewMode    );
  w.WriteInt  (281, e.RenderMode  );
  w.WriteInt  ( 72, e.isUcsAssoc  );
  w.WriteInt  ( 73, e.isCameraPlot);
  w.WriteStr  (332, e.BackObjId   );
  w.WriteStr  (334, e.LiveSectId  );
  w.WriteStr  (348, e.StyleId     );
  w.WriteStr  (361, e.OwnerId     );
  // The following codes appear only if code 72 is set to 1.
  if e.isUcsAssoc <> 0 then begin
    WritePoint(w, e.UCSOrig  , 110);
    WritePoint(w, e.UCSXAxis , 111);
    WritePoint(w, e.UCSYAxis , 112);
    w.WriteInt  (  79 ,e.OrthType );
    w.WriteFloat( 146 ,e.UCSElev  );
    w.WriteStr  ( 345 ,e.UCSID    );
    w.WriteStr  ( 346 ,e.UCSBaseID);
  end;
end;

procedure WriteVPort(w: TDxfWriter; e: TDxfVPortEntry);
begin
  WriteTableEntry(w, e);
  w.WriteStr  (100,e.SubClass2);
  w.WriteStr  (  2,e.ViewName );
  w.WriteInt  ( 70,e.Flags    );
  WritePoint2d(w, e.LeftLow    , 10);
  WritePoint2d(w, e.UpRight    , 11);
  WritePoint2d(w, e.ViewCenter , 12);
  WritePoint2d(w, e.SnapBase   , 13);
  WritePoint2d(w, e.SnapSpace  , 14);
  WritePoint2d(w, e.GridSpace  , 15);
  WritePoint  (w, e.ViewDir    , 16);
  WritePoint  (w, e.ViewTarget , 17);
  w.WriteFloat( 40,e._40);
  w.WriteFloat( 41,e._41);
  w.WriteFloat( 42,e.LensLen     );
  w.WriteFloat( 43,e.FrontClipOfs);
  w.WriteFloat( 44,e.BackClipOfs );
  WriteOptFlt(w,e.Height,0, 45);
  w.WriteFloat( 50,e.RotateAngle );
  w.WriteFloat( 51,e.TwistAngle  );
  w.WriteInt  ( 71,e.ViewMode    );
  w.WriteInt  ( 72,e.CircleSides );
  w.WriteInt  ( 74,e.UCSICON     );
  w.WriteStr  (331,e.FrozeLayerId);
  //w.WriteStr( 441,e.FrozeLayerId);
  w.WriteInt  ( 70,e.PerspFlag   );
  w.WriteStr  (  1,e.PlotStyle   );
  w.WriteInt  (281,e.RenderMode  );
  WritePoint(w, e.UCSOrigin, 110);
  WritePoint(w, e.UCSXAxis , 111);
  WritePoint(w, e.UCSYAxis , 112);
  WriteOptStr(w, e.UCSId      , '', 345);
  WriteOptStr(w, e.UCSBaseId  , '', 346);
  w.WriteInt  ( 79, e.OrthType     );
  w.WriteFloat(146, e.Elevation    );
  WriteOptInt(w, e.PlotShade, 0, 170);
  WriteOptInt(w, e.GridLines, 0,  61);
  WriteOptStr(w, e.BackObjId    ,'', 332);
  WriteOptStr(w, e.ShadePlotId  ,'', 333);
  WriteOptStr(w, e.VisualStyleId,'', 348);
  WriteOptInt(w, e.isDefLight   ,0 , 292);
  WriteOptInt(w, e.DefLightType ,0 , 282);
  WriteOptFlt(w, e.Brightness   ,0 , 141);
  WriteOptFlt(w, e.Contract     ,0 , 142);
  WriteOptInt(w, e.Color1       ,0 ,  63);
  WriteOptInt(w, e.Color2       ,0 , 421);
  WriteOptInt(w, e.Color3       ,0 , 431);
end;

procedure WriteAnyEntry(w: TDxfWriter; e: TDxfTableEntry);
begin
  if e is TDxfAppIdEntry then
    WriteAppId(w, TDxfAppIdEntry(e))
  else if e is TDxfBlockRecordEntry then
    WriteBlockRecord(w, TDxfBlockRecordEntry(e))
  else if e is TDxfDimStyleEntry then
    WriteDimStyle(w, TDxfDimStyleEntry(e))
  else if e is TDxfLayerEntry then
    WriteLayerTableEntry(w, TDxfLayerEntry(e))
  else if e is TDxfLTypeEntry then
    WriteLType(w, TDxfLTypeEntry(e))
  else if e is TDxfStyleEntry then
    WriteStyleTableEntry(w, TDxfStyleEntry(e))
  else if e is TDxfUCSEntry then
    WriteUCSTableEntry(w, TDxfUCSEntry(e))
  else if e is TDxfViewEntry then
    WriteView(w, TDxfViewEntry(e))
  else if e is TDxfVPortEntry then
    WriteVPort(w, TDxfVPortEntry(e))
  ;
end;

procedure WriteTableHeader(w: TDxfWriter; tbl: TDxfTable);
begin
  WriteCtrl(w, NAME_TABLE);
  w.WriteStr(CB_NAME, tbl.Name);
  w.WriteStr(CB_HANDLE, tbl.Handle);
  w.WriteStr(CB_OWNERHANDLE, tbl.Owner);
  w.WriteStr(CB_SUBCLASS, tbl.SubClass);
  w.WriteInt(CB_VARINT, tbl.MaxNumber);

  if tbl.Name = NAME_DIMSTYLE then begin
    w.WriteStr(CB_SUBCLASS, tbl.SubClass2);
    w.WriteInt(71, tbl.IntVal2);
    w.WriteStr(340, tbl.Owner2);
  end;
end;

end.
