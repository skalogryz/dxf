unit dxfwriteutils;

interface

uses
  Classes, SysUtils,
  dxftypes, dxfwrite, dxfclasses;

type
// todo: move it to dxf parseutils
  TDxfSpacingHeader = record
    Base         : string;     // $*BASE          9 $UCSBASE 2                                9 $PUCSBASE 2
    Name         : string;     // $*NAME          9 $UCSNAME 2                                9 $PUCSNAME 2
    Origin       : TDxfPoint;  // $*ORG           9 $UCSORG 10 0.0 20 0.0 30 0.0              9 $PUCSORG 10 0.0 20 0.0 30 0.0
    OriginBack   : TDxfPoint;  // $*ORGBACK       9 $UCSXDIR 10 1.0 20 0.0 30 0.0             9 $PUCSXDIR 10 1.0 20 0.0 30 0.0
    OriginBottom : TDxfPoint;  // $*ORGBOTTOM     9 $UCSYDIR 10 0.0 20 1.0 30 0.0             9 $PUCSYDIR 10 0.0 20 1.0 30 0.0
    OriginFront  : TDxfPoint;  // $*ORGFRONT      9 $UCSORTHOREF 2                            9 $PUCSORTHOREF 2
    OriginLeft   : TDxfPoint;  // $*ORGLEFT       9 $UCSORTHOVIEW 70    0                     9 $PUCSORTHOVIEW 70    0
    OriginRight  : TDxfPoint;  // $*ORGRIGHT      9 $UCSORGTOP 10 0.0 20 0.0 30 0.0           9 $PUCSORGTOP 10 0.0 20 0.0 30 0.0
    OriginTop    : TDxfPoint;  // $*ORGTOP        9 $UCSORGBOTTOM 10 0.0 20 0.0 30 0.0        9 $PUCSORGBOTTOM 10 0.0 20 0.0 30 0.0
    OrthoRef     : string;     // $*ORTHOREF      9 $UCSORGLEFT 10 0.0 20 0.0 30 0.0          9 $PUCSORGLEFT 10 0.0 20 0.0 30 0.0
    OrthoView    : Integer;    // $*ORTHOVIEW     9 $UCSORGRIGHT 10 0.0 20 0.0 30 0.0         9 $PUCSORGRIGHT 10 0.0 20 0.0 30 0.0
    XDir         : TDxfPoint;  // $*XDIR          9 $UCSORGFRONT 10 0.0 20 0.0 30 0.0         9 $PUCSORGFRONT 10 0.0 20 0.0 30 0.0
    YDir         : TDxfPoint;  // $*YDIR          9 $UCSORGBACK 10 0.0 20 0.0 30 0.0          9 $PUCSORGBACK 10 0.0 20 0.0 30 0.0
  end;

  TDxfAcadHeader = record
    Version   : string;     // 9 $ACADVER        1 AC1015
    MaintVer  : integer;    // 9 $ACADMAINTVER  70 20
  end;

  TDxfUserHeader = record
    UserI1: Integer;   // 9 $USERI1 70    0
    UserI2: Integer;   // 9 $USERI2 70   0
    UserI3: Integer;   // 9 $USERI3 70   0
    UserI4: Integer;   // 9 $USERI4 70    0
    UserI5: Integer;   // 9 $USERI5 70    0
    UserRR1: double;   // 9 $USERR1 40 0.0
    UserRR2: double;   // 9 $USERR2 40 0.0
    UserRR3: double;   // 9 $USERR3 40 0.0
    UserRR4: double;   // 9 $USERR4 40 0.0
    UserRR5: double;   // 9 $USERR5 40 0.0
  end;

  // current editor settings
  TDxfCurrentSettings = record
    Layer               : string;  // 9 $CLAYER         8 EL_DEVICE  // Current layer name
// 9 $CMLSTYLE 2 Standard       // Current multiline style name
// 9 $CMLJUST 70    0     // Current multiline justification:
// 9 $CMLSCALE 40 1.0  // Current multiline scale
// 9 $ELEVATION 40 0.0 // Current elevation set by ELEV command
// 9 $THICKNESS 40 0.0      // Current thickness set by ELEV command
// 9 $PELEVATION 40 Current paper space elevation
// 9 $TEXTSTYLE      7 STANDARD  // Current text style name
    EntityColor         : Integer; // 9 $CECOLOR       62  256       // Current entity color number:  0 = BYBLOCK; 256 = BYLAYER
    EntityLineTypeScale : Double;  // 9 $CELTSCALE     40 1.0
    //     9 $XEDIT 290    1 // Controls whether the current drawing can be edited inplace when being referenced by another drawing.
  end;

  TDxfHeader = record
    acad : TDxfAcadHeader;
    Ucs  : TDxfSpacingHeader;
    PUcs : TDxfSpacingHeader; // Paper space
  end;

{
9 $DWGCODEPAGE    3 ANSI_1251
9 $INSBASE       10 0.0 20 0.0 30 0.0
9 $EXTMIN        10 -2.5 20 -2.5 30 0.0
9 $EXTMAX        10 2.5 20 2.5 30 0.0
9 $LIMMIN        10 0.0 20 0.0
9 $LIMMAX        10 420.0 20 297.0
9 $ORTHOMODE     70    0
9 $REGENMODE     70    1
9 $FILLMODE      70    1
9 $QTEXTMODE     70    0
9 $MIRRTEXT      70    1
9 $LTSCALE       40 1.0
9 $ATTMODE       70    1
9 $TEXTSIZE      40 2.5
9 $TRACEWID      40 1.0


9 $CELTYPE        6 ByLayer
9 $DISPSILH      70    0
9 $DIMSCALE      40 1.0
9 $DIMASZ        40 2.5
9 $DIMEXO        40 0.625
9 $DIMDLI        40 3.75
9 $DIMRND        40 0.0
9 $DIMDLE        40 0.0
9 $DIMEXE        40 1.25
9 $DIMTP         40 0.0
9 $DIMTM         40 0.0
9 $DIMTXT        40 2.5
9 $DIMCEN 40 -2.5
9 $DIMTSZ 40 0.0
9 $DIMTOL 70    0
9 $DIMLIM 70    0
9 $DIMTIH 70    0
9 $DIMTOH 70    1
9 $DIMSE1 70    0
9 $DIMSE2 70    0
9 $DIMTAD 70    1
9 $DIMZIN 70    8
9 $DIMBLK 1 None
9 $DIMASO 70    1
9 $DIMSHO 70    1
9 $DIMPOST 1
9 $DIMAPOST 1
9 $DIMALT 70    0
9 $DIMALTD 70    3
9 $DIMALTF 40 0.03937007874016
9 $DIMLFAC 40 100.0
9 $DIMTOFL 70    1
9 $DIMTVP 40 0.0
9 $DIMTIX 70    0
9 $DIMSOXD 70    0
9 $DIMSAH 70    0
9 $DIMBLK1 1
9 $DIMBLK2 1
9 $DIMSTYLE 2 MY
9 $DIMCLRD 70  256
9 $DIMCLRE 70  256
9 $DIMCLRT 70  256
9 $DIMTFAC 40 1.0
9 $DIMGAP 40 0.625
9 $DIMJUST 70    0
9 $DIMSD1 70    0
9 $DIMSD2 70    0
9 $DIMTOLJ 70    1
9 $DIMTZIN 70    8
9 $DIMALTZ 70   8
9 $DIMALTTZ 70    8
9 $DIMUPT 70    0
9 $DIMDEC 70    4
9 $DIMTDEC 70    4
9 $DIMALTU 70    2
9 $DIMALTTD 70   3
9 $DIMTXSTY 7 STANDARD
9 $DIMAUNIT 70    0
9 $DIMADEC 70    0
9 $DIMALTRND 40 0.0
9 $DIMAZIN 70    0
9 $DIMDSEP 70   46
9 $DIMATFIT 70    3
9 $DIMFRAC 70    0
9 $DIMLDRBLK 1 None
9 $DIMLUNIT 70    2
9 $DIMLWD 70   -2
9 $DIMLWE 70   -2
9 $DIMTMOVE 70   2
9 $LUNITS 70    2
9 $LUPREC 70    4
9 $SKETCHINC 40 1.0
9 $FILLETRAD 40 10.0
9 $AUNITS 70    0
9 $AUPREC 70    0
9 $MENU 1 .

9 $LIMCHECK 70    0
9 $CHAMFERA 4010.0
9 $CHAMFERB 40 10.0
9 $CHAMFERC 40 0.0
9 $CHAMFERD 40 0.0
9 $SKPOLY 70    0
9 $TDCREATE   40 2452500.693435810
9 $TDUCREATE  40 2452500.485102477
9 $TDUPDATE   40 2454843.156291413
9 $TDUUPDATE  40 2454842.947958079
9 $TDINDWG    40 1.1395893750
9 $TDUSRTIMER 40 1.1395855903
9 $USRTIMER   70 1
9 $ANGBASE 50 0.0
9 $ANGDIR 70    0
9 $PDMODE 70    3
9 $PDSIZE 40 0.0
9 $PLINEWID 40 0.0
9 $SPLFRAME 70 0
9 $SPLINETYPE 70    6
9 $SPLINESEGS 70    8
9 $HANDSEED 5 1B3
9 $SURFTAB1 70    6
9 $SURFTAB2 70    6
9 $SURFTYPE 70    6
9 $SURFU 70    6
9 $SURFV 70    6


9 $WORLDVIEW 70   1
9 $SHADEDGE 70    3
9 $SHADEDIF 70   70
9 $TILEMODE 70    1
9 $MAXACTVP 70   64
9 $PINSBASE 10 0.0 20 0.0 30 0.0
9 $PLIMCHECK 70    0
9 $PEXTMIN 10 0.0 20 0.0 30 0.0
9 $PEXTMAX 10 0.0 20 0.0 30 0.0
9 $PLIMMIN 10 0.0 20 0.0
9 $PLIMMAX 10 12.0 20 9.0
9 $UNITMODE 70    0
9 $VISRETAIN 70    1
9 $PLINEGEN 70    0
9 $PSLTSCALE 70    1
9 $TREEDEPTH 70 3020

9 $PROXYGRAPHICS 70    1
9 $MEASUREMENT 70    0
9 $CELWEIGHT 370   -1
9 $ENDCAPS 280    0
9 $JOINSTYLE 280   0
9 $LWDISPLAY 290   0
9 $INSUNITS 70    0
9 $HYPERLINKBASE 1
9 $STYLESHEET 1

9 $CEPSNTYPE 380    0
9 $PSTYLEMODE 290    1
9 $FINGERPRINTGUID 2 {C6BCC4B8-0A70-4D6B-8BC3-38669135F434}
9 $VERSIONGUID 2 {703F571C-B03F-455F-A924-D4402EC0C5D8}
9 $EXTNAMES 290    1
9 $PSVPSCALE 40 0.0
9 $OLESTARTUP 290   0 // unknown
}

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
procedure WriteHeaderVarFlt(w: TDxfWriter; const Name: string; v: double; codeGroup: Integer);
procedure WriteHeaderVarPnt(w: TDxfWriter; const Name: string; const v: TDxfPoint);
procedure WriteHeaderVarPnt2d(w: TDxfWriter; const Name: string; const v: TDxfPoint);

procedure WriteAcadHeader(w: TDxfWriter; const h: TDxfAcadHeader);

procedure WriteStartSection(w: TDxfWriter; const SecName: string);

procedure WriteEntityBase(w: TDxfWriter; e: TDxfEntity);

procedure WriteLine(w: TDxfWriter; l: TDxfLine);
procedure WriteCircle(w: TDxfWriter; c: TDxfCircle);

procedure WriteAnyEntity(w: TDxfWriter; e: TDxfEntity);
procedure WriteEntityList(w: TDxfWriter; lst: TList{of TDxfEntity});

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
procedure WriteBlockEnt(w: TDxfWriter; const b: TDxfBlockEntity; WriteSpaceFlag: Boolean);
begin
  w.WriteStr(CB_HANDLE, b.Handle);
  //if b.appDefGroup<>'' then begin
  //  // todo: support for custom application codes
  //end;
  w.WriteStr(CB_OWNERHANDLE, b.Owner);
  w.WriteStr(CB_SUBCLASS,    IfEmpt(b.SubClass, _AcDbEntity));
  if WriteSpaceFlag then w.WriteInt(CB_SPACEFLAG,   b.SpaceFlag);
  w.WriteStr(CB_LAYERNAME,   b.LayerName);
end;

procedure WriteBlock(w: TDxfWriter; const b: TDxfBlock);
begin
  if not Assigned(w) then Exit;
  WriteCtrl(w, NAME_BLOCK);
  WriteBlockEnt(w, b, b.SpaceFlag<>0);
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
  WriteBlockEnt(w, b, false);
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

procedure WriteHeaderVarPnt2d(w: TDxfWriter; const Name: string;
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

procedure WriteFile(w: TDxfWriter; src: TDxfFile);
begin
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
