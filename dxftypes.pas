unit dxftypes;

{$ifdef fpc}{$mode delphi}{$H+}{$endif}

interface

{$ifndef fpc}
type
  Int16 = SmallInt;
  Int32 = Integer;
{$endif}

const
  DxfBinaryHeader = 'AutoCAD Binary DXF'#13#10#26#0;

const
  CB_CONTROL    = 0; // control
  CB_XREFPATH   = 1;
  CB_NAME       = 2; // section name
  CB_BLOCKNAME  = 3; // block name
  CB_DESCR      = 4;
  CB_HANDLE     = 5; // handle value
  CB_LAYERNAME  = 8; // layername

  CB_SECTION_NAME = CB_NAME;
  CB_TABLE_NAME   = CB_NAME;
  CB_TABLE_HANDLE = CB_HANDLE;

  CB_OWNERHANDLE  = 330;
  CB_COMMENT      = 999;

  CB_SPACEFLAG    = 67;
  CB_FLAGS        = 70;

  CB_SUBCLASS     = 100;
  CB_APPDEFNAME   = 102;
  CB_GROUPSTART   = 102;

  CB_X            = 10;
  CB_Y            = 20;
  CB_Z            = 30;
  CB_X0           = CB_X;
  CB_Y0           = CB_Y;
  CB_Z0           = CB_Z;
  CB_X1           = 11;
  CB_Y1           = 21;
  CB_Z1           = 31;
  CB_X2           = 12;
  CB_Y2           = 22;
  CB_Z2           = 32;
  CB_X3           = 13;
  CB_Y3           = 23;
  CB_Z3           = 33;
  CB_X_ENDPOINT   = CB_X1;
  CB_Y_ENDPOINT   = CB_Y1;
  CB_Z_ENDPOINT   = CB_Z1;
  CB_X_SCALE      = 41;
  CB_Y_SCALE      = 42;
  CB_Z_SCALE      = 43;
  CB_X_EXTRUSION  = 210;
  CB_Y_EXTRUSION  = 220;
  CB_Z_EXTRUSION  = 230;

  // for class
  CB_DXFRECNAME   = 1;
  CB_CPPNAME      = 2;
  CB_APPANME      = 3;
  CB_PROXYFLAG    = 90;
  CB_INSTCOUNT    = 91;
  CB_WASAPROXY    = 280;
  CB_ISENTITY     = 281;

  // for entities
  CB_THICKNESS    = 39;
  CB_RADIUS       = 40;

  // for header
  CB_VARVALUE  = 1;
  CB_VARNAME   = 9; // variable name
  CB_VARINT    = 70;
  CB_VARFLOAT  = 40;

  // for table
  CB_DIMHANDLE  = 105;

const
  NAME_OBJECTS  = 'OBJECTS';
  NAME_ENTITIES = 'ENTITIES';
  NAME_BLOCKS   = 'BLOCKS';
  NAME_BLOCK    = 'BLOCK';
  NAME_ENDBLK   = 'ENDBLK';
  NAME_TABLES   = 'TABLES';
  NAME_TABLE    = 'TABLE';
  NAME_ENDTAB   = 'ENDTAB';
  NAME_CLASSES  = 'CLASSES';
  NAME_CLASS    = 'CLASS';
  NAME_HEADER   = 'HEADER';
  NAME_SECTION  = 'SECTION';
  NAME_ENDSEC   = 'ENDSEC';
  NAME_EOF      = 'EOF';


  NAME_DIMSTYLE = 'DIMSTYLE';
const
  // $ANGDIR
  ANGDIR_CLOCKWISE        = 1;
  ANGDIR_COUNTERCLOCKWISE = 0;

  // $ATTMODE
  ATTMODE_NONE   = 0;
  ATTMODE_NORMAL = 1;
  ATTMODE_ALL    = 2;

  // $CECOLOR
  CECOLOR_BYBLOCK = 0;
  CECOLOR_BYLAYER = 256;

  // $CEPSNTYPE
  CEPSNTYPE_BYLAYER = 0; // Plot style by layer
  CEPSNTYPE_BYBLOCK = 1; // Plot style by block
  CEPSNTYPE_BYDICT  = 2; // = Plot style by dictionary default
  CEPSNTYPE_BYOBJId = 3; // = Plot style by object ID/handle

  // $CMLJUST
  CMLJUST_TOP       = 0;
  CMLJUST_MIDDLE    = 1;
  CMLJUST_BOTTOM    = 2;

  // $CSHADOW  (used in entity shadow mode 284)
  CSHADOW_CASTRECV  = 0; // Casts and receives shadows
  CSHADOW_CASTONLY  = 1; // Casts shadows
  CSHADOW_RECVONLY  = 2; // Receives shadows
  CSHADOW_IGNORE    = 3; // Ignores shadows

const
  CLASS_PROXY_NOOP        = $0000; // No operations allowed
  CLASS_PROXY_ERASE       = $0001; // Erase allowed
  CLASS_PROXY_TRANSFORM   = $0002; // Transform allowed
  CLASS_PROXY_COLOR       = $0004; // Color change allowed
  CLASS_PROXY_LAYER       = $0008; // Layer change allowed
  CLASS_PROXY_LINETYPE    = $0010; // Linetype change allowed
  CLASS_PROXY_LINESCALE   = $0020; // Linetype scale change allowed
  CLASS_PROXY_VISIBLE     = $0040; // Visibility change allowed
  CLASS_PROXY_CLONE       = $0080; // Cloning allowed
  CLASS_PROXY_LINEWEIGHT  = $0100; // Lineweight change allowed
  CLASS_PROXY_PLOTSTYLE   = $0200; // Plot Style Name change allowed
  CLASS_PROXY_ALL_NOCLONE = $037F; // All operations except cloning allowed
  CLASS_PROXY_ALL         = $03FF; // All operations allowed
  CLASS_PROXY_NO_WARN     = $0400; // Disables proxy warning dialog
  CLASS_PROXY_R13         = $8000; // R13 format proxy

const
  // used for $INSUNITS (vINSUNITS)
  UNITS_NO        = 0;  // Unitless
  UNITS_INCHES    = 1;  // Inches
  UNITS_FEET      = 2;  // Feet
  UNITS_MILES     = 3;  // Miles
  UNITS_MM        = 4;  // Millimeters
  UNITS_CM        = 5;  // Centimeters
  UNITS_METERS    = 6;  // Meters
  UNITS_KM        = 7;  // Kilometers
  UNITS_MINCHES   = 8;  // Microinches
  UNITS_MILS      = 9;  // Mils
  UNITS_YARDS     = 10; // Yards
  UNITS_ANGSTROMS = 11; // Angstroms
  UNITS_NM        = 12; // Nanometers
  UNITS_MICRONS   = 13; // Microns
  UNITS_DM        = 14; // Decimeters
  UNITS_DECAM     = 15; // Decameters
  UNITS_HECTOM    = 16; // Hectometer
  UNITS_GM        = 17; // Gigameters
  UNITS_ASTRO     = 18; // Astronomical units
  UNITS_LIGHTYEAR = 19; // Light years
  UNITS_PARSEC    = 20; // Parsecs

  // for $UNITMODE. it's a bit field
  UNITMODE_FRAC   = 1;  // Show fractions for units available (where applicable). I.e. feet-and-inches


  TABLE_ENTRY_FLAG_XREF     = 16; // If set, table entry is externally dependent on an xref
  TABLE_ENTRY_FLAG_XREF_RES = 32; // If both this bit and bit 16 are set, the externally dependent xref has been successfully resolved
  TABLE_ENTRY_FLAG_REFERRED = 64; // If set, the table entry was referenced by at least one entity in the drawing the last time
                            // the drawing was edited. (This flag is for the benefit of AutoCAD commands. It can be ignored
                            // by most programs that read DXF files and need not be set by programs that write DXF files)

  APPID_FLAG_XREF        = TABLE_ENTRY_FLAG_XREF;
  APPID_FLAG_XREF_RES    = TABLE_ENTRY_FLAG_XREF_RES;
  APPID_FLAG_REFERRED    = TABLE_ENTRY_FLAG_REFERRED;

  DIMSTYLE_FLAG_XREF     = TABLE_ENTRY_FLAG_XREF;
  DIMSTYLE_FLAG_XREF_RES = TABLE_ENTRY_FLAG_XREF_RES;
  DIMSTYLE_FLAG_REFERRED = TABLE_ENTRY_FLAG_REFERRED;

  LAYER_FLAG_FROZEN      = 1; // Layer is frozen; otherwise layer is thawed
  LAYER_FLAG_FROZEN_NEW  = 2; // Layer is frozen by default in new viewports
  LAYER_FLAG_LOCKED      = 4; // Layer is locked
  LAYER_FLAG_XREF        = TABLE_ENTRY_FLAG_XREF;
  LAYER_FLAG_XREF_RES    = TABLE_ENTRY_FLAG_XREF_RES;
  LAYER_FLAG_REFERRED    = TABLE_ENTRY_FLAG_REFERRED;

  LTYPE_FLAG_XREF        = TABLE_ENTRY_FLAG_XREF;
  LTYPE_FLAG_XREF_RES    = TABLE_ENTRY_FLAG_XREF_RES;
  LTYPE_FLAG_REFERRED    = TABLE_ENTRY_FLAG_REFERRED;

  STYLE_FLAG_FROZEN      = 1; // If set, this entry describes a shape
  STYLE_FLAG_LOCKED      = 4; // Vertical text
  STYLE_FLAG_XREF        = TABLE_ENTRY_FLAG_XREF;
  STYLE_FLAG_XREF_RES    = TABLE_ENTRY_FLAG_XREF_RES;
  STYLE_FLAG_REFERRED    = TABLE_ENTRY_FLAG_REFERRED;

  STYLE_FLAGTEXT_BACKWARD = 2; // Text is backward (mirrored in X)
  STYLE_FLAGTEXT_UPSIDE   = 4; // Text is upside down (mirrored in Y)

  UCS_FLAG_XREF          = TABLE_ENTRY_FLAG_XREF;
  UCS_FLAG_XREF_RES      = TABLE_ENTRY_FLAG_XREF_RES;
  UCS_FLAG_REFERRED      = TABLE_ENTRY_FLAG_REFERRED;

  UCS_ORTHO_TOP     = 1;
  UCS_ORTHO_BOTTOM  = 2;
  UCS_ORTHO_FRONT   = 3;
  UCS_ORTHO_BACK    = 4;
  UCS_ORTHO_LEFT    = 5;
  UCS_ORTHO_RIGHT   = 6;

  VIEW_FLAG_XREF     = TABLE_ENTRY_FLAG_XREF;
  VIEW_FLAG_XREF_RES = TABLE_ENTRY_FLAG_XREF_RES;
  VIEW_FLAG_REFERRED = TABLE_ENTRY_FLAG_REFERRED;

  // All rendering modes other than 2D Optimized engage the new 3D graphics pipeline. These
  // values directly correspond to the SHADEMODE command and the
  // AcDbAbstractViewTableRecord::RenderMode enum
  RENDERMODE_2D          = 0; // 2D Optimized (classic 2D)
  RENDERMODE_WIRE        = 1; // Wireframe
  RENDERMODE_HIDDENLINE  = 2; // Hidden line
  RENDERMODE_FLAT        = 3; // Flat shaded
  RENDERMODE_GOURAUD     = 4; // Gouraud shaded
  RENDERMODE_FLATWIRE    = 5; // Flat shaded with wireframe
  RENDERMODE_GOURAUDWIRE = 6; // Gouraud shaded with wireframe

  LIGHT_ONEDISTANT = 1; // One distant light
  LIGHT_TWODISTANT = 2; // Two distant lights

  BLOCK_FLAG_NONE        = 0; // Indicates none of the following flags apply
  BLOCK_FLAG_ANONYMOUS   = 1; // This is an anonymous block generated by hatching,
                              // associative dimensioning, other internal operations, or an application
  BLOCK_FLAG_NON_CONST   = 2; // This block has non-constant attribute definitions (this bit is not set
                              // if the block has any attribute Definitions that are constant, or has
                              // no attribute definitions at all)
  BLOCK_FLAG_EXT_REF     = 4; // This block is an external reference (xref)
  BLOCK_FLAG_OVERLAY     = 8; // This block is an xref overlay
  BLOCK_FLAG_XREF        = TABLE_ENTRY_FLAG_XREF;
  BLOCK_FLAG_XREF_RES    = TABLE_ENTRY_FLAG_XREF_RES;
  BLOCK_FLAG_REFERRED    = TABLE_ENTRY_FLAG_REFERRED;

type
  TDxfType = (
    dtUnknown,
    dtInt16,   // in binary it's int16
    dtInt32,   // in binary it's int32
    dtInt64,   // in binary it's int64
    dtDouble,  // in binary it's double
    dtStr2049, // in binary it's null-char
    dtStr255,  // in binary it's null-char
    dtBoolean, // in binary it's int8
    dtStrHex,  // in binary it's null-char
    dtBin1     // in Textural representation this is a StrHex.
               // For Binary it's 1 byte of the size followed
               // by the chunk of bytes
  );

const
  MAX_STR   = 255;
  MAX_STREX = 2049;

const
  // default names and string constant used in a dxf file
  _AcDbEntity      = 'AcDbEntity';
  _AcDbBlockBegin  = 'AcDbBlockBegin';
  _AcDbBlockEnd    = 'AcDbBlockEnd';
  vACADVER         = '$ACADVER';
  vACADMAINTVER    = '$ACADMAINTVER';
  vUCSBASE         = '$UCSBASE';
  vUCSNAME         = '$UCSNAME';
  vUCSORG          = '$UCSORG';
  vUCSXDIR         = '$UCSXDIR';
  vUCSYDIR         = '$UCSYDIR';
  vUCSORTHOREF     = '$UCSORTHOREF';
  vUCSORTHOVIEW    = '$UCSORTHOVIEW';
  vUCSORGTOP       = '$UCSORGTOP';
  vUCSORGBOTTOM    = '$UCSORGBOTTOM';
  vUCSORGLEFT      = '$UCSORGLEFT';
  vUCSORGRIGHT     = '$UCSORGRIGHT';
  vUCSORGFRONT     = '$UCSORGFRONT';
  vUCSORGBACK      = '$UCSORGBACK';
  vPUCSBASE        = '$PUCSBASE';
  vPUCSNAME        = '$PUCSNAME';
  vPUCSORG         = '$PUCSORG';
  vPUCSXDIR        = '$PUCSXDIR';
  vPUCSYDIR        = '$PUCSYDIR';
  vPUCSORTHOREF    = '$PUCSORTHOREF';
  vPUCSORTHOVIEW   = '$PUCSORTHOVIEW';
  vPUCSORGTOP      = '$PUCSORGTOP';
  vPUCSORGBOTTOM   = '$PUCSORGBOTTOM';
  vPUCSORGLEFT     = '$PUCSORGLEFT';
  vPUCSORGRIGHT    = '$PUCSORGRIGHT';
  vPUCSORGFRONT    = '$PUCSORGFRONT';
  vPUCSORGBACK     = '$PUCSORGBACK';
  vUSERI1          = '$USERI1';
  vUSERI2          = '$USERI2';
  vUSERI3          = '$USERI3';
  vUSERI4          = '$USERI4';
  vUSERI5          = '$USERI5';
  vUSERR1          = '$USERR1';
  vUSERR2          = '$USERR2';
  vUSERR3          = '$USERR3';
  vUSERR4          = '$USERR4';
  vUSERR5          = '$USERR5';
  vCLAYER          = '$CLAYER';
  vCMLSTYLE        = '$CMLSTYLE';
  vCMLJUST         = '$CMLJUST';
  vCMLSCALE        = '$CMLSCALE';
  vELEVATION       = '$ELEVATION';
  vTHICKNESS       = '$THICKNESS';
  vPELEVATION      = '$PELEVATION';
  vTEXTSTYLE       = '$TEXTSTYLE';
  vCECOLOR         = '$CECOLOR';
  vCELTSCALE       = '$CELTSCALE';
  vXEDIT           = '$XEDIT';
  vDWGCODEPAGE     = '$DWGCODEPAGE';
  vINSBASE         = '$INSBASE';
  vEXTMIN          = '$EXTMIN';
  vEXTMAX          = '$EXTMAX';
  vLIMMIN          = '$LIMMIN';
  vLIMMAX          = '$LIMMAX';
  vORTHOMODE       = '$ORTHOMODE';
  vREGENMODE       = '$REGENMODE';
  vFILLMODE        = '$FILLMODE';
  vQTEXTMODE       = '$QTEXTMODE';
  vMIRRTEXT        = '$MIRRTEXT';
  vLTSCALE         = '$LTSCALE';
  vATTMODE         = '$ATTMODE';
  vTEXTSIZE        = '$TEXTSIZE';
  vTRACEWID        = '$TRACEWID';
  vCELTYPE         = '$CELTYPE';
  vDISPSILH        = '$DISPSILH';
  vDIMSCALE        = '$DIMSCALE';
  vDIMASZ          = '$DIMASZ';
  vDIMEXO          = '$DIMEXO';
  vDIMDLI          = '$DIMDLI';
  vDIMRND          = '$DIMRND';
  vDIMDLE          = '$DIMDLE';
  vDIMEXE          = '$DIMEXE';
  vDIMTP           = '$DIMTP';
  vDIMTM           = '$DIMTM';
  vDIMTXT          = '$DIMTXT';
  vDIMCEN          = '$DIMCEN';
  vDIMTSZ          = '$DIMTSZ';
  vDIMTOL          = '$DIMTOL';
  vDIMLIM          = '$DIMLIM';
  vDIMTIH          = '$DIMTIH';
  vDIMTOH          = '$DIMTOH';
  vDIMSE1          = '$DIMSE1';
  vDIMSE2          = '$DIMSE2';
  vDIMTAD          = '$DIMTAD';
  vDIMZIN          = '$DIMZIN';
  vDIMBLK          = '$DIMBLK';
  vDIMASO          = '$DIMASO';
  vDIMSHO          = '$DIMSHO';
  vDIMPOST         = '$DIMPOST';
  vDIMAPOST        = '$DIMAPOST';
  vDIMALT          = '$DIMALT';
  vDIMALTD         = '$DIMALTD';
  vDIMALTF         = '$DIMALTF';
  vDIMLFAC         = '$DIMLFAC';
  vDIMTOFL         = '$DIMTOFL';
  vDIMTVP          = '$DIMTVP';
  vDIMTIX          = '$DIMTIX';
  vDIMSOXD         = '$DIMSOXD';
  vDIMSAH          = '$DIMSAH';
  vDIMBLK1         = '$DIMBLK1';
  vDIMBLK2         = '$DIMBLK2';
  vDIMSTYLE        = '$DIMSTYLE';
  vDIMCLRD         = '$DIMCLRD';
  vDIMCLRE         = '$DIMCLRE';
  vDIMCLRT         = '$DIMCLRT';
  vDIMTFAC         = '$DIMTFAC';
  vDIMGAP          = '$DIMGAP';
  vDIMJUST         = '$DIMJUST';
  vDIMSD1          = '$DIMSD1';
  vDIMSD2          = '$DIMSD2';
  vDIMTOLJ         = '$DIMTOLJ';
  vDIMTZIN         = '$DIMTZIN';
  vDIMALTZ         = '$DIMALTZ';
  vDIMALTTZ        = '$DIMALTTZ';
  vDIMUPT          = '$DIMUPT';
  vDIMDEC          = '$DIMDEC';
  vDIMTDEC         = '$DIMTDEC';
  vDIMALTU         = '$DIMALTU';
  vDIMALTTD        = '$DIMALTTD';
  vDIMTXSTY        = '$DIMTXSTY';
  vDIMAUNIT        = '$DIMAUNIT';
  vDIMADEC         = '$DIMADEC';
  vDIMALTRND       = '$DIMALTRND';
  vDIMAZIN         = '$DIMAZIN';
  vDIMDSEP         = '$DIMDSEP';
  vDIMATFIT        = '$DIMATFIT';
  vDIMFRAC         = '$DIMFRAC';
  vDIMLDRBLK       = '$DIMLDRBLK';
  vDIMLUNIT        = '$DIMLUNIT';
  vDIMLWD          = '$DIMLWD';
  vDIMLWE          = '$DIMLWE';
  vDIMTMOVE        = '$DIMTMOVE';
  vLUNITS          = '$LUNITS';
  vLUPREC          = '$LUPREC';
  vSKETCHINC       = '$SKETCHINC';
  vFILLETRAD       = '$FILLETRAD';
  vAUNITS          = '$AUNITS';
  vAUPREC          = '$AUPREC';
  vMENU            = '$MENU';
  vLIMCHECK        = '$LIMCHECK';
  vCHAMFERA        = '$CHAMFERA';
  vCHAMFERB        = '$CHAMFERB';
  vCHAMFERC        = '$CHAMFERC';
  vCHAMFERD        = '$CHAMFERD';
  vSKPOLY          = '$SKPOLY';
  vTDCREATE        = '$TDCREATE';
  vTDUCREATE       = '$TDUCREATE';
  vTDUPDATE        = '$TDUPDATE';
  vTDUUPDATE       = '$TDUUPDATE';
  vTDINDWG         = '$TDINDWG';
  vTDUSRTIMER      = '$TDUSRTIMER';
  vUSRTIMER        = '$USRTIMER';
  vANGBASE         = '$ANGBASE';
  vANGDIR          = '$ANGDIR';
  vPDMODE          = '$PDMODE';
  vPDSIZE          = '$PDSIZE';
  vPLINEWID        = '$PLINEWID';
  vSPLFRAME        = '$SPLFRAME';
  vSPLINETYPE      = '$SPLINETYPE';
  vSPLINESEGS      = '$SPLINESEGS';
  vHANDSEED        = '$HANDSEED';
  vSURFTAB1        = '$SURFTAB1';
  vSURFTAB2        = '$SURFTAB2';
  vSURFTYPE        = '$SURFTYPE';
  vSURFU           = '$SURFU';
  vSURFV           = '$SURFV';
  vWORLDVIEW       = '$WORLDVIEW';
  vSHADEDGE        = '$SHADEDGE';
  vSHADEDIF        = '$SHADEDIF';
  vTILEMODE        = '$TILEMODE';
  vMAXACTVP        = '$MAXACTVP';
  vPINSBASE        = '$PINSBASE';
  vPLIMCHECK       = '$PLIMCHECK';
  vPEXTMIN         = '$PEXTMIN';
  vPEXTMAX         = '$PEXTMAX';
  vPLIMMIN         = '$PLIMMIN';
  vPLIMMAX         = '$PLIMMAX';
  vUNITMODE        = '$UNITMODE';
  vVISRETAIN       = '$VISRETAIN';
  vPLINEGEN        = '$PLINEGEN';
  vPSLTSCALE       = '$PSLTSCALE';
  vTREEDEPTH       = '$TREEDEPTH';
  vPROXYGRAPHICS   = '$PROXYGRAPHICS';
  vMEASUREMENT     = '$MEASUREMENT';
  vCELWEIGHT       = '$CELWEIGHT';
  vENDCAPS         = '$ENDCAPS';
  vJOINSTYLE       = '$JOINSTYLE';
  vLWDISPLAY       = '$LWDISPLAY';
  vINSUNITS        = '$INSUNITS';
  vHYPERLINKBASE   = '$HYPERLINKBASE';
  vSTYLESHEET      = '$STYLESHEET';
  vCEPSNTYPE       = '$CEPSNTYPE';
  vPSTYLEMODE      = '$PSTYLEMODE';
  vFINGERPRINTGUID = '$FINGERPRINTGUID';
  vVERSIONGUID     = '$VERSIONGUID';
  vEXTNAMES        = '$EXTNAMES';
  vPSVPSCALE       = '$PSVPSCALE';
  vOLESTARTUP      = '$OLESTARTUP';

const
  // Entity
  ET_3DFACE            = '3DFACE';
  ET_3DSOLID           = '3DSOLID';
  ET_ACAD_PROXY_ENTITY = 'ACAD_PROXY_ENTITY';
  ET_ARC               = 'ARC';
  ET_ATTDEF            = 'ATTDEF';
  ET_ATTRIB            = 'ATTRIB';
  ET_BODY              = 'BODY';
  ET_CIRCLE            = 'CIRCLE';
  ET_DIMENSION         = 'DIMENSION';
  ET_ELLIPSE           = 'ELLIPSE';
  ET_HATCH             = 'HATCH';
  ET_HELIX             = 'HELIX';
  ET_IMAGE             = 'IMAGE';
  ET_INSERT            = 'INSERT';
  ET_LEADER            = 'LEADER';
  ET_LIGHT             = 'LIGHT';
  ET_LINE              = 'LINE';
  ET_LWPOLYLINE        = 'LWPOLYLINE';
  ET_MESH              = 'MESH';
  ET_MLINE             = 'MLINE';
  ET_MLEADERSTYLE      = 'MLEADERSTYLE';
  ET_MLEADER           = 'MLEADER';
  ET_MTEXT             = 'MTEXT';
  ET_OLEFRAME          = 'OLEFRAME';
  ET_POINT             = 'POINT';
  ET_POLYLINE          = 'POLYLINE';
  ET_RAY               = 'RAY';
  ET_REGION            = 'REGION';
  ET_SECTION           = 'SECTION';
  ET_SEQEND            = 'SEQEND';
  ET_SHAPE             = 'SHAPE';
  ET_SOLID             = 'SOLID';
  ET_SPLINE            = 'SPLINE';
  ET_SUN               = 'SUN';
  ET_SURFACE           = 'SURFACE';
  ET_TABLE             = 'TABLE';
  ET_TEXT              = 'TEXT';
  ET_TOLERANCE         = 'TOLERANCE';
  ET_TRACE             = 'TRACE';
  ET_UNDERLAY          = 'UNDERLAY';
  ET_VERTEX            = 'VERTEX';
  ET_WIPEOUT           = 'WIPEOUT';
  ET_XLINE             = 'XLINE';

  // Table Entry
  TE_APPID        = 'APPID';
  TE_BLOCK_RECORD = 'BLOCK_RECORD';
  TE_DIMSTYLE     = 'DIMSTYLE';
  TE_LAYER        = 'LAYER';
  TE_LTYPE        = 'LTYPE';
  TE_STYLE        = 'STYLE';
  TE_UCS          = 'UCS';
  TE_VIEW         = 'VIEW';
  TE_VPORT        = 'VPORT';

  // Object Types
  OT_ACAD_PROXY_OBJECT   = 'ACAD_PROXY_OBJECT';
  OT_ACDBDICTIONARYWDFLT = 'ACDBDICTIONARYWDFLT';
  OT_ACDBPLACEHOLDER     = 'ACDBPLACEHOLDER';
  OT_DATATABLE           = 'DATATABLE';
  OT_DICTIONARY          = 'DICTIONARY';
  OT_DICTIONARYVAR       = 'DICTIONARYVAR';
  OT_DIMASSOC            = 'DIMASSOC';
  OT_FIELD               = 'FIELD';
  OT_GEODATA             = 'GEODATA';
  OT_GROUP               = 'GROUP';
  OT_IDBUFFER            = 'IDBUFFER';
  OT_IMAGEDEF            = 'IMAGEDEF';
  OT_IMAGEDEF_REACTOR    = 'IMAGEDEF_REACTOR';
  OT_LAYER_INDEX         = 'LAYER_INDEX';
  OT_LAYER_FILTER        = 'LAYER_FILTER';
  OT_LAYOUT              = 'LAYOUT';
  OT_LIGHTLIST           = 'LIGHTLIST';
  OT_MATERIAL            = 'MATERIAL';
  OT_MLINESTYLE          = 'MLINESTYLE';
  OT_OBJECT_PTR          = 'OBJECT_PTR';
  OT_PLOTSETTINGS        = 'PLOTSETTINGS';
  OT_RASTERVARIABLES     = 'RASTERVARIABLES';
  OT_RENDER              = 'RENDER';
  OT_SECTION             = 'SECTION';
  OT_SPATIAL_INDEX       = 'SPATIAL_INDEX';
  OT_SPATIAL_FILTER      = 'SPATIAL_FILTER';
  OT_SORTENTSTABLE       = 'SORTENTSTABLE';
  OT_TABLESTYLE          = 'TABLESTYLE';
  OT_UNDERLAYDEFINITION  = 'UNDERLAYDEFINITION';
  OT_VISUALSTYLE         = 'VISUALSTYLE';
  OT_VBA_PROJECT         = 'VBA_PROJECT';
  OT_WIPEOUTVARIABLES    = 'WIPEOUTVARIABLES';
  OT_XRECORD             = 'XRECORD';

const
  // for object
  CB_DICT_ENTRYNAME  = 3;
  CB_DICT_ENTRYOWNER = 350;

// from Group Code Value Types
function DxfDataType(groupCode: Integer): TDxfType;

const
  DEF_THICKENS  = 0.0; // entity 39
  DEF_LINESCALE = 1.0; // entity 48
  DEF_HIDDEN    = 0;   // entity 60

const
  ACAD_VER_R10  = 'AC1006'; // Release 10 (1988)
  ACAD_VER_R11  = 'AC1009'; // Release 11 (1990)
  ACAD_VER_R12  = 'AC1009'; // Release 12 (1992)
  ACAD_VER_R13  = 'AC1012'; // Release 13 (1994)
  ACAD_VER_R14  = 'AC1014'; // Release 14 (1997)
  ACAD_VER_2000 = 'AC1015'; // AutoCAD 2000
  ACAD_VER_2004 = 'AC1018'; // AutoCAD 2004
  ACAD_VER_2007 = 'AC1021'; // AutoCAD 2007
  ACAD_VER_2010 = 'AC1024'; // AutoCAD 2010
  ACAD_VER_2013 = 'AC1027'; // AutoCAD 2013
  ACAD_VER_2018 = 'AC1032'; // AutoCAD 2018

  GROUPLIST_REACTORS    = '{ACAD_REACTORS';
  GROUPLIST_XDICTIONARY = '{ACAD_XDICTIONARY';

  CLS_AcDbDictionary            = 'AcDbDictionary';
  CLS_AcDbDictionaryWithDefault = 'AcDbDictionaryWithDefault';
  CLS_AcDbPlaceHolder           = 'AcDbPlaceHolder';
  CLS_AcDbLayout                = 'AcDbLayout';
  CLS_AcDbTableStyle            = 'AcDbTableStyle';
  CLS_AcDbSymbolTable           = 'AcDbSymbolTable';
  CLS_AcDbEntity                = 'AcDbEntity';
  CLS_AcDbLine                  = 'AcDbLine';
  CLS_AcDbVertex                = 'AcDbVertex';
  CLS_AcDb2dVertex              = 'AcDb2dVertex';
  CLS_AcDb3dPolylineVertex      = 'AcDb3dPolylineVertex';
  CLS_AcDb2dPolyline            = 'AcDb2dPolyline';
  CLS_AcDb3dPolyline            = 'AcDb3dPolyline';

  Lineweight_Standard = -3;
  Lineweight_ByLayer  = -2;
  Linewieght_ByBlock  = -1;
  // 0-211 = an integer representing 100th of mm

  //Polyline flag (bit-coded; default = 0):
  Polyline_Closed     = 1;   // This is a closed polyline (or a polygon mesh closed in the M direction)
  Polyline_Curve      = 2;   // Curve-fit vertices have been added
  Polyline_Spline     = 4;   // Spline-fit vertices have been added
  Polyline_3d         = 8;   // This is a 3D polyline
  Polyline_2dMesh     = 16;  // This is a 3D polygon mesh
  Polyline_ClosedMesh = 32;  // The polygon mesh is closed in the N direction
  Polyline_Polyface   = 64;  // The polyline is a polyface mesh
  Polyline_ContLType  = 128; // The linetype pattern is generated continuously around the vertices of this polyline

  SurfType_Nosmooth    = 0;  // No smooth surface fitted
  SurfType_QuadBSpline = 5;  // Quadratic B-spline surface
  SutfType_CubicBSplne = 6;  // Cubic B-spline surface
  SurfType_Bezier      = 8;  // Bezier surface

const
  CODEPAGE_ANSI_1251 = 'ANSI_1251';
  DEFAULT_CODEPAGE   = CODEPAGE_ANSI_1251;
  DEFAULT_TEXTSTYLE  = 'STANDARD'; // used for TextStyles Block or Header vars

  APPName_ObjectDBX_Cls = 'ObjectDBX Classes';

implementation

function DxfDataType(groupCode: Integer): TDxfType;
begin
  case groupCode of
    0..9: Result := dtStr2049;
    10..39: Result := dtDouble; // 3d double
    40..59: Result := dtDouble;
    60..79: Result := dtInt16;
    // 80?
    90..99: Result := dtInt32;
    100, 102, 105: Result := dtStr255;
    110..119,
    120..129,
    130..139: Result := dtDouble;
    140..149: Result := dtDouble; // Double precision scalar floating-point value
    160..169: Result := dtInt64;
    170..179: Result := dtInt16;
    210..239: Result := dtDouble;
    270..279,
    280..289: Result := dtInt16;
    290..299: Result := dtBoolean;
    300..309: Result := dtStr255;
    310..319: Result := dtBin1;
    320..329,
    330..369: Result := dtStrHex;
    370..379,
    380..389: Result := dtInt16;
    390..399: Result := dtStrHex;
    400..409: Result := dtInt16;
    410..419: Result := dtStr255;
    420..429: Result := dtInt32;
    430..439: Result := dtStr255;
    440..449: Result := dtInt32;
    450..459: Result := dtInt32; // Long?
    460..469: Result := dtDouble; // Long?
    470..479: Result := dtStr255;
    480..489: Result := dtStrHex;
         999: Result := dtStr2049;
    1000..1009: Result := dtStr2049;
    1010..1059: Result := dtDouble;
    1060..1070: Result := dtInt16;
          1071: Result := dtInt32;
  else
    Result := dtUnknown;
  end;
end;

end.
