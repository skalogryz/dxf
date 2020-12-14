unit dxfclasses;

interface

uses
  Classes, SysUtils, dxftypes, dxfparse;

type
  TDxfPoint = record
    x,y,z: double;
  end;
  TDxfPoint2D = TDxfPoint;

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

  // anything related to versioning of Autodesk
  TDxfAcadHeader = record
    Version    : string;    // ($ACADVER)      The AutoCAD drawing database version number:
                            //                 see ACAD_VER_XXX constants
    MaintVer   : Integer;   // ($ACADMAINTVER) Maintenance version number (should be ignored)
    isExtNames : Integer;   // ($EXTNAMES)     Controls symbol table naming:
                            //                 0 = Release 14 compatibility. Limits names to 31 characters
                            //                     in length. Names can include the letters A to Z, the numerals
                            //                     0 to 9, and the special characters dollar sign ($), underscore
                            //                     (_), and hyphen (-).
                            //                 1 = AutoCAD 2000. Names can be up to 255 characters in
                            //                     length, and can include the letters A to Z, the numerals 0
                            //                     to 9, spaces, and any special characters not used for other
                            //                     purposes by Microsoft Windows and AutoCAD
  end;


  TDxfTimeHeader = record
    CreateTimeLocal : Double;  // ($TDCREATE)   40  Local date/time of drawing creation
    CreateTimeUniv  : Double;  // ($TDUCREATE)  40  Universal date/time the drawing was created
    UpdateTimeLocal : Double;  // ($TDUPDATE)   40  Local date/time of last drawing update
    UpdateTimeUniv  : Double;  // ($TDUUPDATE)  40  Universal date/time of the last update/save
    TotalTime       : Double;  // ($TDINDWG)    40  Cumulative editing time for this drawing
    ElasedTime      : Double;  // ($TDUSRTIMER) 40  User-elapsed timer
    isTimerOn       : Integer; // ($USRTIMER)   70  0 = Timer off; 1 = Timer on
  end;

  // basic (global/default) configuration settings
  TDxfBaseHeader = record
    CodePage      : string;     // 9 $DWGCODEPAGE    3 ANSI_1251
    InsPoint      : TDxfPoint;  // 9 $INSBASE       10 0.0 20 0.0 30 0.0
    ExtLowLeft    : TDxfPoint;  // 9 $EXTMIN        10 -2.5 20 -2.5 30 0.0
    ExtUpRight    : TDxfPoint;  // 9 $EXTMAX        10 2.5 20 2.5 30 0.0
    LimLowLeft    : TDxfPoint;  // ($LIMMIN) XY drawing limits lower-left corner (in WCS)
    LimUpRight    : TDxfPoint;  // ($LIMMAX) XY drawing limits upper-right corner (in WCS)
    // is it "current setting?"
    isOrtho       : Integer;    // ($ORTHOMODE) Ortho mode on if nonzero,
    isRegen       : Integer;    // ($REGENMODE) REGENAUTO mode on if nonzero
    isFill        : Integer;    // ($FILLMODE)  Fill mode on if nonzero
    isQText       : Integer;    // ($QUICKTEXT) Quick Text mode on if nonzero
    isMirrText    : Integer;    // ($MIRRTEXT)  Mirror text if nonzero
    LineTypeScale : Double;     // ($LTSCALE)   Global linetype scale
    AttrVisMode   : Integer;    // ($ATTMODE)  Attribute visibility:
                                //   0 = None
                                //   1 = Normal
                                //   2 = All
    TextHeight    : Double;     // ($TEXTSIZE) Default text height
    TraceWidth    : Double;     // ($TRACEWID) Default trace width

    DistFormat     : Integer;   // ($LUNITS) 70      Units format for coordinates and distances
    DistPrec       : Integer;   // ($LUPREC) 70      Units precision for coordinates and distances
    SketchInc      : Double;    // ($SKETCHINC) 40   Sketch record increment
    FilletRadius   : Double;    // ($FILLETRAD) 40   Fillet radius
    AnglesFormat   : Integer;   // ($AUNITS) 70      Units format for angles
    AnglesPrec     : Integer;   // ($AUPREC) 70      Units precision for angles
    MenuName       : string;    // ($MENU)  1        Name of menu file
    // : Double;  // ($ELEVATION) 40   Current elevation set by ELEV command
    // : Double;  // ($PELEVATION) 40  Current paper space elevation
    //: Double;  // ($THICKNESS) 40
    isLimCheck     : Integer;   // ($LIMCHECK) 70
    ChamferDist1   : Double;    // ($CHAMFERA) 40    First chamfer distance
    ChamferDist2   : Double;    // ($CHAMFERB) 40    Second chamfer distance
    ChamferLen     : Double;    // ($CHAMFERC) 40    Chamfer length
    ChamferAngle   : Double;    // ($CHAMFERD) 40    Chamfer angle
    isSketchPoly   : Integer;   // ($SKPOLY) 70      0 = Sketch lines; 1 = Sketch polylines
    //: Double;  // ($TDCREATE) 40    Local date/time of drawing creation
    //: Double;  // ($TDUCREATE) 40   Universal date/time the drawing was created
    //: Double;  // ($TDUPDATE) 40    Local date/time of last drawing update
    //: Double;  // ($TDUUPDATE) 40   Universal date/time of the last update/save
    //: Double;  // ($TDINDWG) 40     Cumulative editing time for this drawing
    //: Double;  // ($TDUSRTIMER) 40  User-elapsed timer
    //: Integer; // ($USRTIMER) 70    0 = Timer off; 1 = Timer on
    AngleBase      : Double;    // ($ANGBASE)    50  Angle 0 direction
    isClockWise    : Integer;   // ($ANGDIR)     70  1 = Clockwise angles 0 = Counterclock wise angles

    PtDispMode     : Integer;   // ($PDMODE)     70  Point display mode
    PtDispSize     : Double;    // ($PDSIZE)     40  Point display size
    DefPolyWidth   : Double;    // ($PLINEWID)   40  Default polyline width
    //: Integer; // ($SPLFRAME) 70
    SplineCurvType : Integer;   // ($SPLINETYPE) 70  Spline curve type for PEDIT Spline
    LineSegments   : Integer;   // ($SPLINESEGS) 70  Number of line segments per spline patch
    NextHandle     : string;    // ($HANDSEED)    5  Next available handle
    MeshCount1     : Integer;   // ($SURFTAB1)   70  Number of mesh tabulations in first direction
    MeshCount2     : Integer;   // ($SURFTAB2)   70  Number of mesh tabulations in second direction
    SurfType       : Integer;   // ($SURFTYPE)   70  Surface type for PEDIT Smooth
    SurfDensityM   : Integer;   // ($SURFU)      70  Surface density (for PEDIT Smooth) in M direction
    SurfDensityN   : Integer;   // ($SURFV)      70  Surface density (for PEDIT Smooth) in N direction

    isWorldView    : Integer;   // ($WORLDVIEW      )   70  // 1 = Set UCS to WCS during DVIEW/VPOINT 0 = Don't change UCS
    ShadeEdge      : Integer;   // ($SHADEDGE       )   70     0 = Faces shaded, edges not highlighted
                                //                             1 = Faces shaded, edges highlighted in black
                                //                             2 = Faces not filled, edges in entity color
                                //                             3 = Faces in entity color, edges in black
    ShadeDiffuse   : Integer;   // ($SHADEDIF       )   70  Percent ambient/diffuse light; range 1-100; default 70
    isTileMode     : Integer;   // ($TILEMODE       )   70  1 for previous release compatibility mode; 0 otherwise
    MaxViewPorts   : Integer;   // ($MAXACTVP       )   70  Sets maximum number of viewports to be regenerated
    PaperInsPoint  : TDxfPoint; // ($PINSBASE       )   10  Paper space insertion base point
    isPaperLimCheck: Integer;   // ($PLIMCHECK      )   70  Limits checking in paper space when nonzero
    PaperExtLowLeft: TDxfPoint; // ($PEXTMIN        )   10  Minimum X, Y, and Z extents for paper space
    PaperExtUpRight: TDxfPoint; // ($PEXTMAX        )   10  Maximum X, Y, and Z extents for paper space
    PaperLimLowLeft: TDxfPoint; // ($PLIMMIN        )   10  Minimum X and Y limits in paper space
    PaperLimUpRight: TDxfPoint; // ($PLIMMAX        )   10  Maximum X and Y limits in paper space
    UnitMode       : Integer;   // ($UNITMODE       )   70  Low bit set = Display fractions, feet-and-inches, and surveyor's angles in input format
    isRetainXRefVis: Integer;   // ($VISRETAIN      )   70  0 = Don't retain xref-dependent visibility settings
                                //                          1 = Retain xref-dependent visibility settings
    LineTypePatt   : Integer;   // ($PLINEGEN       )   70 Governs the generation of linetype patterns around the vertices of a 2D polyline:
                                //                         1 = Linetype is generated in a continuous pattern around vertices of the polyline
                                //                         0 = Each segment of the polyline starts and ends with a dash
    PaperLineScaling : Integer; // ($PSLTSCALE      )   70  Controls paper space linetype scaling:
                                //                           1 = No special linetype scaling
                                //                           0 = Viewport scaling governs linetype scaling
    SpaceTreeDepth   : Integer; // ($TREEDEPTH      )   70  Specifies the maximum depth of the spatial index
    isProxyImageSave : Integer; // ($PROXYGRAPHICS  )   70  Controls the saving of proxy object images
    MeasureUnits     : Integer; // ($MEASUREMENT    )   70  Sets drawing units: 0 = English; 1 = Metric
    NewObjLineWeight : Integer; // ($CELWEIGHT      )  370  Lineweight of new objects
    LineEndCaps      : Integer; // ($ENDCAPS        )  280  Lineweight endcaps setting for new objects: 0 = none; 1 = round; 2 = angle; 3 = square
    LineJointStyle   : Integer; // ($JOINSTYLE      )  280  Lineweight joint setting for new objects:
                                //                          0=none; 1= round; 2 = angle; 3 = flat
    isLineShow       : Integer; // ($LWDISPLAY      )  290  Controls the display of lineweights on the Model or Layout tab:
                                //                          0 = Lineweight is not displayed
                                //                          1 = Lineweight is displayed
    DefaultUnits     : Integer; // ($INSUNITS       )   70  Default drawing units for AutoCAD DesignCenter blocks:
                                //                          0 = Unitless; 1 = Inches; 2 = Feet; 3 = Miles; 4 = Millimeters;
                                //                          5 = Centimeters; 6 = Meters; 7 = Kilometers; 8 = Microinches;
                                //                          9 = Mils; 10 = Yards; 11 = Angstroms; 12 = Nanometers;
                                //                          13 = Microns; 14 = Decimeters; 15 = Decameters;
                                //                          16 = Hectometers; 17 = Gigameters; 18 = Astronomical units;
                                //                          19 = Light years; 20 = Parsecs
    RelHyperLink     : string;  // ($HYPERLINKBASE  )    1  Path for all relative hyperlinks in the drawing. If null, the drawing path is used
    //// ($STYLESHEET     )    1 - NOOO
    isInPlaceEditin  : Integer; // ($XEDIT          )  290 Controls whether the current drawing can be edited inplace when being referenced by another drawing.
                                //                         0 = Can't use in-place reference editing
                                //                         1 = Can use in-place reference editing
    PlotStype        : Integer; // ($CEPSNTYPE      )  380 Plot style type of new objects:
                                //                         0 = Plot style by layer
                                //                         1 = Plot style by block
                                //                         2 = Plot style by dictionary default
                                //                         3 = Plot style by object ID/handle
    isColorDepmode   : Integer; // ($PSTYLEMODE     )  290  Indicates whether the current drawing is in a Color-Dependent or Named Plot Style mode:
                                //                          0 = Uses named plot style tables in the current drawing
                                //                          1 = Uses color-dependent plot style tables in the current drawing
    FingerPrintGuid  : string;  // ($FINGERPRINTGUID)    2   Set at creation time, uniquely identifies a particular drawing
    VersionGuild     : string;  // ($VERSIONGUID    )    2  Uniquely identifies a particular version of a drawing. Updated when the drawing is modified
    ViewPortScale    : double; // ($PSVPSCALE      )   40   View scale factor for new viewports:
    //                           0 = Scaled to fit
    //                           >0 = Scale factor (a positive real value)
    // ($OLESTARTUP     )  290 - NOO
  end;

  TDxfUserHeader = record
    I1: Integer;   // ($USERI1) Five integer variables intended for use by third-party developers
    I2: Integer;   // ($USERI2)
    I3: Integer;   // ($USERI3)
    I4: Integer;   // ($USERI4)
    I5: Integer;   // ($USERI5)
    R1: double;    // ($USERR1) Five real variables intended for use by third-party developers
    R2: double;    // ($USERR2)
    R3: double;    // ($USERR3)
    R4: double;    // ($USERR4)
    R5: double;    // ($USERR5)
  end;

  // current editor settings
  TDxfCurrentSettings = record
    Layer               : string;  // ($CLAYER)    Current layer name
    MultiLineStyle      : string;  // ($CMLSTYLE)  Current multiline style name
    MultiLineJust       : Integer; // ($CMLJUST)   Current multiline justification:
    MultiLineScale      : double;  // ($CMLSCALE)  Current multiline scale
    EntLineType         : string;  // ($CELTYPE)   Entity linetype name, or BYBLOCK or BYLAYER
    TextStyle           : string;  // ($TEXTSTYLE) Current text style name
    EntColor            : Integer; // ($CECOLOR)   Current entity color number:  0 = BYBLOCK; 256 = BYLAYER
    EntLineTypeScale    : Double;  // ($CELTSCALE) Current entity linetype scale
    DispSilhMode        : Integer; // ($DISPSILH)  Controls the display of silhouette curves of body objects in

    Elev                : Double;  // ($ELEVATION) 40   Current elevation set by ELEV command
    PaperElev           : Double;  // ($PELEVATION) 40  Current paper space elevation
    Thickness           : Double;  // ($THICKNESS) 40   Current thickness set by ELEV command
  end;

  TDxfDimensions = record
    // sub divide intos common, "format"(decplaces), "text", "arrows", "extension"
    Scale             : double;  // ($DIMSCALE)    Overall dimensioning scale factor
    ArrowSize         : double;  // ($DIMASZ)      Dimensioning arrow size
    ExtLineOfs        : double;  // ($DIMEXO)      Extension line offset
    DimLineInc        : double;  // ($DIMDLI)      Dimension line increment
    RoundVal          : double;  // ($DIMRND)      Rounding value for dimension distances
    DimLineExt        : double;  // ($DIMDLE)      Dimension line extension
    ExtLineExt        : double;  // ($DIMEXE)      Extension line extension
    PlusToler         : double;  // ($DIMTP)       Plus tolerance
    MinusToler        : double;  // ($DIMTM)       Minus tolerance
    TextHeight        : double;  // ($DIMTXT)      Dimensioning text height
    CenterSize        : double;  // ($DIMCEN)      Size of center mark/lines
    TickSize          : double;  // ($DIMTSZ)      Dimensioning tick size: 0 = No ticks
    Tolerance         : integer; // ($DIMTOL)      Dimension tolerances generated if nonzero
    Limits            : integer; // ($DIMLIM)      Dimension limits generated if nonzero
    isTextIns         : integer; // ($DIMTIH)      Text inside horizontal if nonzero
    isTextOut         : integer; // ($DIMTOH)      Text outside horizontal if nonzero
    isSupExt1         : integer; // ($DIMSE1)      First extension line suppressed if nonzero
    isSupExt2         : integer; // ($DIMSE2)      Second extension line suppressed if nonzero
    isTextAbove       : integer; // ($DIMTAD)      Text above dimension line if nonzero
    SupZeros          : integer; // ($DIMZIN)      Controls suppression of zeros for primary unit values:
                                 //                0 = Suppresses zero feet and precisely zero inches
                                 //                1 = Includes zero feet and precisely zero inches
                                 //                2 = Includes zero feet and suppresses zero inches
                                 //                3 = Includes zero inches and suppresses zero feet
    ArrowBlock        : string;  // ($DIMBLK)      Arrow block name
    isAssocDim        : Integer; // ($DIMASO)      1 = Create associative dimensioning
                                 //                0 = Draw individual entities
    isRecompDim       : Integer; // ($DIMSHO)      1 = Recompute dimensions while dragging
                                 //                0 = Drag original image
    Suffix            : string;  // ($DIMPOST)     General dimensioning suffix
    AltSuffix         : string;  // ($DIMAPOST)    Alternate dimensioning suffix
    isUseAltUnit      : integer; // ($DIMALT)      Alternate unit dimensioning performed if nonzero
    AltDec            : integer; // ($DIMALTD)     Alternate unit decimal places
    AltScale          : double;  // ($DIMALTF)     Alternate unit scale factor
    LinearScale       : double;  // ($DIMLFAC)     Linear measurements scale factor
    isTextOutExt      : Integer; // ($DIMTOFL)     If text is outside extensions, force line extensions between extensions if nonzero
    TextVertPos       : double;  // ($DIMTVP)      Text vertical position
    isForceTextIns    : Integer; // ($DIMTIX)      Force text inside extensions if nonzero
    isSuppOutExt      : Integer; // ($DIMSOXD)     Suppress outside-extensions dimension lines if nonzero
    isUseSepArrow     : Integer; // ($DIMSAH)      Use separate arrow blocks if nonzero
    ArrowBlock1       : string;  // ($DIMBLK1)     First arrow block name
    ArrowBlock2       : string;  // ($DIMBLK2)     Second arrow block name
    StyleName         : string;  // ($DIMSTYLE)    Dimension style name
    LineColor         : integer; // ($DIMCLRD)     Dimension line color: range is 0 = BYBLOCK; 256 = BYLAYER
    ExtLineColor      : integer; // ($DIMCLRE)     Dimension extension line color: range is 0 = BYBLOCK; 256 = BYLAYER
    TextColor         : integer; // ($DIMCLRT)     Dimension text color: range is 0 = BYBLOCK; 256 = BYLAYER
    DispTolerance     : double;  // ($DIMTFAC)     Dimension tolerance display scale factor
    LineGap           : double;  // ($DIMGAP)      Dimension line gap
    HorzTextJust      : integer; // ($DIMJUST)     Horizontal dimension text position:
                                 //                0 = Above dimension line and center-justified between extension lines
                                 //                1 = Above dimension line and next to first extension line
                                 //                2 = Above dimension line and next to second extension line
                                 //                3 = Above and center-justified to first extension line
                                 //                4 = Above and center-justified to second extension line
    isSuppLine1       : Integer; // ($DIMSD1)      Suppression of first extension line: 0 = Not suppressed; 1 = Suppressed
    isSuppLine2       : Integer; // ($DIMSD2)      Suppression of second extension line: 0 = Not suppressed; 1 = Suppressed
    VertJustTol       : Integer; // ($DIMTOLJ)     Vertical justification for tolerance values: 0 = Top; 1 = Middle; 2 = Bottom
    ZeroSupTol        : Integer; // ($DIMTZIN)     Controls suppression of zeros for tolerance values:
                                 //                0 = Suppresses zero feet and precisely zero inches
                                 //                1 = Includes zero feet and precisely zero inches
                                 //                2 = Includes zero feet and suppresses zero inches
                                 //                3 = Includes zero inches and suppresses zero feet
    ZeroSupAltUnitTol : Integer; // ($DIMALTZ)     Controls suppression of zeros for alternate unit dimension values:
                                 //                0 = Suppresses zero feet and precisely zero inches
                                 //                1 = Includes zero feet and precisely zero inches
                                 //                2 = Includes zero feet and suppresses zero inches
                                 //                3 = Includes zero inches and suppresses zero feet
    ZeroSupAltTol     : Integer; // ($DIMALTTZ)    Controls suppression of zeros for alternate tolerance values:
                                 //                0 = Suppresses zero feet and precisely zero inches
                                 //                1 = Includes zero feet and precisely zero inches
                                 //                2 = Includes zero feet and suppresses zero inches
                                 //                3 = Includes zero inches and suppresses zero feet
    isEditCursorText  : Integer; // ($DIMUPT)      Cursor functionality for user-positioned text:
                                 //                0 = Controls only the dimension line location
                                 //                1 = Controls the text position as well as the dimension line location
    DecPlacesPrim     : Integer; // ($DIMDEC)      Number of decimal places for the tolerance values of a primary units dimension
    DecPlacesOther    : Integer; // ($DIMTDEC)     Number of decimal places to display the tolerance values
    UnitsFormat       : Integer; // ($DIMALTU)     Units format for alternate units of all dimension style family members except angular:
                                 //                1 = Scientific; 2 = Decimal; 3 = Engineering;
                                 //                4 = Architectural (stacked); 5 = Fractional (stacked);
                                 //                6 = Architectural; 7 = Fractional
    DecPlacesAltUnit  : Integer; // ($DIMALTTD)    Number of decimal places for tolerance values of an alternate units dimension
    TextStyle         : string;  // ($DIMTXSTY)    Dimension text style
    AngleFormat       : Integer; // ($DIMAUNIT)    Angle format for angular dimensions:
                                 //                0 = Decimal degrees; 1 = Degrees/minutes/seconds;
                                 //                2 = Gradians; 3 = Radians; 4 = Surveyor's units
    AngleDecPlaces    : Integer; // ($DIMADEC)     Number of precision places displayed in angular dimensions
    RoundValAlt       : double;  // ($DIMALTRND)   Determines rounding of alternate units
    ZeroSupAngUnit    : Integer; // ($DIMAZIN)     Controls suppression of zeros for angular dimensions:
                                 //                0 = Displays all leading and trailing zeros
                                 //                1 = Suppresses leading zeros in decimal dimensions
                                 //                2 = Suppresses trailing zeros in decimal dimensions
                                 //                3 = Suppresses leading and trailing zeros
    DecSeparator      : Integer; // ($DIMDSEP)     Single-character decimal separator used when creating dimensions whose unit format is decimal
    TextArrowPlace    : Integer; // ($DIMATFIT)    Controls dimension text and arrow placement when space
                                 //                is not sufficient to place both within the extension lines:
                                 //                0 = Places both text and arrows outside extension lines
                                 //                1 = Moves arrows first, then text
                                 //                2 = Moves text first, then arrows
                                 //                3 = Moves either text or arrows, whichever fits best
                                 //                AutoCAD adds a leader to moved dimension text when DIMTMOVE is set to 1
    // ($DIMFRAC) (DOES NOT EXIST?)
    ArrowBlockLead    : string;  // ($DIMLDRBLK)   Arrow block name for leaders
    Units             : Integer; // ($DIMLUNIT)    Sets units for all dimension types except Angular:
                                 //                1 = Scientific; 2 = Decimal; 3 = Engineering;
                                 //                4 = Architectural; 5 = Fractional; 6 = Windows desktop
    LineWeight        : Integer; // ($DIMLWD)      Dimension line lineweight:
                                 //                -3 = Standard
                                 //                -2 = ByLayer
                                 //                -1 = ByBlock
                                 //                0-211 = an integer representing 100th of mm
    LineWeightExt     : Integer; // ($DIMLWE)      Extension line lineweight:
                                 //                -3 = Standard
                                 //                -2 = ByLayer
                                 //                -1 = ByBlock
                                 //                0-211 = an integer representing 100th of mm
    TextMove          : Integer; // ($DIMTMOVE)    Dimension text movement rules:
                                 //                0 = Moves the dimension line with dimension text
                                 //                1 = Adds a leader when dimension text is moved
                                 //                2 = Allows text to be moved freely without a leader

    UnitFrac          : Integer; // DIMFRAC
    ArrowBlockId      : string;  // ($DIMBLK1)     First arrow block name
    ArrowBlockId1     : string;  // ($DIMBLK1)     First arrow block name
    ArrowBlockId2     : string;  // ($DIMBLK2)     Second arrow block name
    // oboslete
    __Units: Integer;          // ($DIMUNIT)    Sets units for all dimension types except Angular:
    __TextArrowPlace: Integer; // ($DIMFIT)    Controls dimension text and arrow placement when space
  end;

  (*
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
  *)


  TDxfHeader = class(TObject)
    acad : TDxfAcadHeader;
    Base : TDxfBaseHeader;
    Sel  : TDxfCurrentSettings;
    Dim  : TDxfDimensions;
    Ucs  : TDxfSpacingHeader;
    PUcs : TDxfSpacingHeader; // Paper space
    User : TDxfUserHeader;
    Time : TDxfTimeHeader;
  end;

  { TDxfTableEntry }

  TDxfTableEntry = class(TObject)
  public
    EntryType   : string;
    Handle      : string;
    Owner       : string;
    SubClass    : string;
  end;

  { TDxfTable }

  TDxfTable = class(TObject)
  private
    fItems: TList;
    function GetObject(i: integer): TDxfTableEntry;
    function GetCount: Integer;
  public
    Name   : string;
    Handle : string;
    Owner  : string;
    SubClass : string;
    MaxNumber : integer;
    // dimstyle table headers:
    SubClass2 : string;
    IntVal2   : Integer;
    Owner2    : string;
    constructor Create;
    destructor Destroy; override;
    function AddItem(obj: TDxfTableEntry): Integer;
    procedure Clear;
    property Entry[i: integer]: TDxfTableEntry read GetObject;
    property Count: Integer read GetCount;
  end;

  TDxfAppIdEntry = class(TDxfTableEntry)
  public
    SubClass2 : string;
    AppData   : string;
    Flags     : integer;
  end;

  TDxfBlockRecordEntry = class(TDxfTableEntry)
  public
    SubClass2    : string;
    BlockName    : string;
    LayoutId     : string;
    InsertUnit   : Integer;
    isExplodable : Integer; // bool
    isScalable   : Integer; // bool
    // optional fields:
    PreviewBin   : string;
    XDataApp     : string; // 1001
    // 1000
    //todo: 1002 .. [1070 1070] 1002
  end;

  TDxfDimStyleEntry = class(TDxfTableEntry)
    SubClass2    : string;
    //StyleName    : string; // 2 (StyleName is in Dim)
    Flags        : Integer; //
    Dim          : TDxfDimensions;
  end;

  TDxfLayerEntry = class(TDxfTableEntry)
    SubClass2   : string;
    LayerName   : string;
    Flags       : Integer;
    ColorNum    : Integer;
    LineType    : string; // Line Type Name
    isPlotting  : Integer;
    Lineweight  : Integer;
    PlotStyleID : string;
    MatObjID    : string;
  end;

  TDxfLTypeEntry = class(TDxfTableEntry)
    SubClass2   : string;
    LineType    : string;    // Linetype name
    Flags       : Integer;
    Descr       : string;    // Descriptive text for linetype
    AlignCode   : Integer;   // Alignment code; value is always 65, the ASCII code for A
    LineTypeElems : Integer; // The number of linetype elements
    TotalPatLen   : Double;  // Total pattern length
    Len           : Double;  // Dash, dot or space length (one entry per element)
    Flags2        : Integer; // Complex linetype element type (one per element). Default is 0 (no embedded shape/text)
                             // The following codes are bit values:
                             // 1 = If set, code 50 specifies an absolute rotation; if not set, code 50 specifies a relative rotation
                             // 2 = Embedded element is a text string
                             // 4 = Embedded element is a shape
    ShapeNum      : Integer; // Shape number (one per element) if code 74 specifies an embedded shape
                             // If code 74 specifies an embedded text string, this value is set to 0
                             // If code 74 is set to 0, code 75 is omitted
    StyleObjId    : string;  // Pointer to STYLE object (one per element if code 74 > 0)
    ScaleVal      : array of Double;  // S = Scale value (optional); multiple entries can exist
    RotateVal     : array of Double;  // R = (relative) or A = (absolute) rotation value in radians of embedded shape or text; one per
                             // element if code 74 specifies an embedded shape or text string
    XOfs          : array of Double;  // X = X offset value (optional); multiple entries can exist
    YOfs          : array of Double;  // Y = Y offset value (optional); multiple entries can exist
    TextStr       : string;  // Text string (one per element if code 74 =
  end;

  TDxfStyleEntry = class(TDxfTableEntry)
    SubClass2   : string;
    StyleName   : string;
    Flags       : Integer; // Standard Flags. see STYLE_FLAG_* constants
    FixedHeight : Double;  // Fixed text height; 0 if not fixed
    WidthFactor : Double;  // Width Factor
    Angle       : Double;  // Oblique angle
    TextFlags   : Integer; // Text generation flags. see STYLE_FLAGTEXT_* constants
    LastHeight  : Double;  // Last height used
    FontName    : string;  // Primary font file name
    BigFontName : string;  // Bigfont file name; blank if none
    FullFont    : string;  // A long value which contains a truetype font’s pitch and family, charset, and italic and bold flags
  end;


  {
   Each 71/13,23,33 pair defines the UCS origin for a particular orthographic
   type relative to this UCS. For example, if the following pair is present, then
   invoking the UCS/LEFT command when UCSBASE is set to this UCS will cause
   the new UCS origin to become (1,2,3).
     71: 5
     13: 1.0
     23: 2.0
     33: 3.0
   If this pair were not present, then invoking the UCS/LEFT command would
   cause the new UCS origin to be set to this UCS's origin point.
  }

  TDxfUCSEntry = class(TDxfTableEntry)
    SubClass2   : string;     // 100
    UCSName     : string;     //   2
    Flags       : Integer;    //  70 Standard Flags. see UCS_FLAG_* constants
    Origin      : TDxfPoint;  // _10 Origin (in WCS)
    XDir        : TDxfPoint;  // _11 X-axis direction (in WCS)
    YDir        : TDxfPoint;  // _12 Y-axis direction (in WCS)
    Zero        : Integer;    //  79 Always Zero
    Elev        : Double;     // 146 Elevation
    BaseUCS     : string;     // 346 ID/handle of base UCS if this is an orthographic. This code is not present if the 79 code is 0. If
                              //     this code is not present and 79 code is non-zero, then base UCS is assumed to be WORLD
    OrthType    : Integer;    //  71 Orthographic type (optional; always appears in pairs with the 13, 23, 33 codes):
                              //     see UCS_ORTHO_* constants
    UCSRelOfs   : TDxfPoint;  // _13 Origin for this orthographic type relative to this UCS
  end;

  TDxfViewEntry = class(TDxfTableEntry)
    SubClass2   : string;     // 100
    ViewName    : string;     //   2
    Flags       : Integer;    //  70 Standard Flags. see VIEW_FLAG_* constants
    Height      : Double;     //  40 View height (in DCS)
    CenterPoint : TDxfPoint;  // _10 View center point (in DCS) 2D
    Width       : Double;     //  41 View width (in DCS)
    ViewDir     : TDxfPoint;  // _11 View direction from target (in WCS) 3D
    TargetPoint : TDxfPoint;  // _12 Target point (in WCS) APP: 3D point
    LensLen     : Double;     //  42 Lens length
    FontClipOfs : Double;     //  43 Front clipping plane (offset from target point)
    BackClipOfs : Double;     //  44 Back clipping plane (offset from target point)
    TwistAngle  : Double;     //  50 Twist angle
    ViewMode    : Integer;    //  71 View mode (see VIEWMODE system variable)
    RenderMode  : Integer;    // 281 Render mode. see RENDERMODE_* constants
                              //     All rendering modes other than 2D Optimized engage the new 3D graphics pipeline. These
                              //     values directly correspond to the SHADEMODE command and the AcDbAbstractViewTableRecord::
                              //     RenderMode enum
    isUcsAssoc  : Integer;    //  72 1 if there is a UCS associated to this view; 0 otherwise
    isCameraPlot: INteger;    //  73 1 if the camera is plottable
    BackObjId   : string;     // 332 Soft-pointer ID/handle to background object (optional)
    LiveSectId  : string;     // 334 Soft-pointer ID/handle to live section object (optional)
    StyleId     : string;     // 348 Hard-pointer ID/handle to visual style object (optional)
    OwnerId     : string;     // 361 Sun hard ownership ID

    // The following codes appear only if code 72 is set to 1. They define the UCS
    // that is associated to this view. This UCS will become the current UCS whenever
    // this view is restored (if code 72 is 0, the UCS is unchanged).
    UCSOrig   : TDxfPoint;    // 110 UCS origin (appears only if code 72 is set to 1) - 3D-Point
    UCSXAxis  : TDxfPoint;    // 111 UCS X-axis (appears only if code 72 is set to 1) - 3D-Point
    UCSYAxis  : TDxfPoint;    // 112 UCS Y-axis (appears only if code 72 is set to 1) - 3D-Point
    OrthType  : Integer;      //  79 Orthographic type of UCS (appears only if code 72 is set to 1):
    UCSElev   : Double;       // 146 UCS elevation (appears only if code 72 is set to 1)
    UCSID     : string;       // 345 ID/handle of AcDbUCSTableRecord if UCS is a named UCS.
                              //     If not present, then UCS is unnamed (appears only if code 72 is set to 1)
    UCSBaseID : string;       // 346 ID/handle of AcDbUCSTableRecord of base UCS if UCS is orthographic (79 code is nonzero).
                              //     If not present and 79 code is non-zero, then base UCS is taken to be WORLD (appears
                              //     only if code 72 is set to 1)
  end;


  TDxfVPortEntry = class(TDxfTableEntry)
    SubClass2     : string;       // 100
    ViewName      : string;       //   2
    Flags         : Integer;      //  70 Standard Flags. see VIEW_FLAG_* constants
    LeftLow       : TDxfPoint2d;  // _10 Lower-left corner of viewport   2d-point
    UpRight       : TDxfPoint2d;  // _11 Upper-right corner of viewport  2d-point
    ViewCenter    : TDxfPoint2d;  // _12 View center point (in DCS)      2d-point
    SnapBase      : TDxfPoint2d;  // _13 Snap base point (in DCS)        2d-point
    SnapSpace     : TDxfPoint2d;  // _14 Snap spacing X and Y            2d-point
    GridSpace     : TDxfPoint2d;  // _15 Grid spacing X and Y            2d-point
    ViewDir       : TDxfPoint;    // _16 View direction from target point (in WCS) 3d-point
    ViewTarget    : TDxfPoint;    // _17 View target point (in WCS) 3d-point
    LensLen       : Double;       //  42 Lens length
    FrontClipOfs  : Double;       //  43 Front clipping plane (offset from target point)
    BackClipOfs   : Double;       //  44 Back clipping plane (offset from target point)
    Height        : Double;       //  45 View height
    RotateAngle   : Double;       //  50 Snap rotation angle
    TwistAngle    : Double;       //  51 View twist angle
    CircleSides   : Integer;      //  72 Circle sides
    FrozeLayerId  : string;       // 331
                                  //  or Soft or hard-pointer ID/handle to frozen layer objects; repeats for each frozen layers
                                  // 441
    PerspFlag     : Integer;      //  70 Bit flags and perspective mode
    PlotStyle     : string;       //   1 Plot style sheet
    RenderMode    : Integer;      // 281 Render mode. See RENDERMODE_* constants
    ViewMode      : Integer;      //  71 View mode (see VIEWMODE system variable)
    UCSICON       : Integer;      //  74 UCSICON setting
    UCSOrigin     : TDxfPoint;    //_110 UCS origin
    UCSXAxis      : TDxfPoint;    //_111 UCS X-axis
    UCSYAxis      : TDxfPoint;    //_112 UCS Y-axis
    UCSId         : string;       // 345 ID/handle of AcDbUCSTableRecord if UCS is a named UCS. If not present, then UCS is unnamed
    UCSBaseId     : string;       // 346 ID/handle of AcDbUCSTableRecord of base UCS if UCS is orthographic (79 code is non-zero).
                                  //     If not present and 79 code is non-zero, then base UCS is taken to be WORLD

    OrthType      : Integer;      //  79 Orthographic type of UCS. See UCS_ORTHO_* const
    Elevation     : Double;       // 146 Elevation
    PlotShade     : Integer;      // 170 Shade plot setting
    GridLines     : Integer;      //  61 Major grid lines
    BackObjId     : string;       // 332 Soft-pointer ID/handle to background object (optional)
    ShadePlotId   : string;       // 333 Soft-pointer ID/handle to shade plot object (optional)
    VisualStyleId : string;       // 348 Hard-pointer ID/handle to visual style object (optional)
    isDefLight    : Integer;      // 292 Default Lighting On flag
    DefLightType  : integer;      // 282 Default Lighting type. See LIGHT_* constants
    Brightness    : Double;       // 141 Brightness
    Contract      : Double;       // 142 Contrast
    Color1        : Integer;      // 63, 421, 431 Ambient color (only output when non-black)
    Color2        : Integer;
    Color3        : Integer;

    _40           : Double;       // unknown, but present in the file!
    _41           : Double;       // unknown, but present in the file!
    _73           : Integer;      // unknown, but present in the file!
    _75           : Integer;      // unknown, but present in the file!
    _76           : Integer;      // unknown, but present in the file!
    _77           : Integer;      // unknown, but present in the file!
    _78           : Integer;      // unknown, but present in the file!
    _65           : Integer;      // unknown, but present in the file!
  end;

  // todo:
  TDxfValue = class
    s   : string;
    i   : integer;
    i64 : int64;
    f   : double;
  end;

  TDxfValuesList = class
    count     : integer;
    vales     : array of TDxfValue;
  end;

  { TDxfEntity }

  TDxfEntity = class
    EntityType      : string; // 0. Not parsed, but assigned elsewhere
    Handle          : string;          // 5
    appName         : string;          // 120 (value of)
    appValues       : TDxfValuesList;  // 120+custom
    ACAD_Reactors   : TDxfValuesList;  // 120+330
    ACAD_XDict      : TDxfValuesList;  // 120+360
    Owner           : string;  // 330
    SubClass        : string;  // 100 (should be AcDbEntity)
    SpaceFlag       : int32;   // 67 -- optional!!!  (seen on Paper_Source)
    AppTableLayout  : string; // 410
    LayerName       : string;  // 8
    LineTypeName    : string;  // 6 (default BYLAYER)
    HardPtrId       : string;  // 347
    ColorNumber     : Integer;  // 62
    LineWidth       : Integer; // 370
    LineScale       : Double;  // 48
    isHidden        : Integer; // 60
    ProxyBytesCount : Integer; // 92
    ProxyGraph      : array of byte; // 310
    Color           : Integer; // 420
    ColorName       : string;  // 430
    Transperancy    : Integer; // 440
    PlotObj         : string;  // 390
    ShadowMode      : Integer; // 284
    Subclass2       : string;  // 100
    constructor Create(const AEntityType: string = '');
  end;

  { TDxfInsert }

  TDxfInsert = class(TDxfEntity)
    AttrFlag   : Integer;
    BlockName  : string;
    InsPoint   : TDxfPoint;
    Scale      : TDxfPoint;
    Rotation   : double;
    ColCount   : integer;
    RowCount   : integer;
    ColSpace   : double;
    RowSpace   : double;
    Extrusion  : TDxfPoint; // Extrusion direction
    constructor Create(const AEntityType: string = ET_INSERT);
  end;

  TDxfClass = class
    recName    : string;  // 1
    cppName    : string;  // 2
    appName    : string;  // 3
    ProxyFlags : integer; // 90
    InstCount  : integer; // 91
    WasProxy   : integer; // 280
    IsAnEntity : integer; // 281
  end;

  TDxfBlockEntity = class
    Handle       : string;  // 5
    appDefGroup  : string;  // 102
    Owner        : string;  //
    SubClass     : string;  // 100
    SpaceFlag    : int32;   // 67 -- optional!!!  (seen on Paper_Source)
    LayerName    : string;  // 8
    Subclass2    : string;  // 100
  end;

  { TDxfBlock }

  TDxfBlock = class(TDxfBlockEntity)
    BlockName  : string;    // 2
    BlockFlags : integer;   // 70
    BasePoint  : TDxfPoint; // 10 20 30
    BlockName2 : string;    // 3
    XRef       : string;    // 1
    Descr      : string;    // 4
  end;

  TDxfBlockEnd = class (TDxfBlockEntity)
    // no special fields for EndBlock
  end;

  { TDxfCircle }

  TDxfCircle = class(TDxfEntity)
    Thickness   : double;
    CenterPoint : TDxfPoint;
    Radius      : double;
    Extrusion   : TDxfPoint;
    constructor Create(const AEntityType: string = ET_CIRCLE);
  end;

  { TDxfSolid }

  TDxfSolid = class(TDxfEntity)
    Corner1     : TDxfPoint;
    Corner2     : TDxfPoint;
    Corner3     : TDxfPoint;
    Corner4     : TDxfPoint;
    Thickness   : double;
    Extrusion   : TDxfPoint;
    constructor Create(const AEntityType: string = ET_SOLID);
  end;

  { TDxfLine }

  TDxfLine = class(TDxfEntity)
    Thickness   : double;
    StartPoint  : TDxfPoint;
    EndPoint    : TDxfPoint;
    Extrusion   : TDxfPoint;
    constructor Create(const AEntityType: string = ET_LINE);
  end;

  { TDxfPolyLine }

  TDxfPolyLine = class(TDxfEntity)
    ObsFlag    : Integer;
    ElevPoint  : TDxfPoint;
    Thickness  : Double;
    PolyFlags  : Integer;
    StartWidth : Double;
    EndWidth   : Double;
    MCount     : Integer;
    NCount     : Integer;
    MDensity   : Integer;
    NDensity   : Integer;
    SurfType   : Integer;
    Extrusion  : TDxfPoint; //
    constructor Create(const AEntityType: string = ET_POLYLINE);
  end;

  { TDxfVertex }

  TDxfVertex = class(TDxfEntity)
    SubClass3  : string;
    Location   : TDxfPoint; // 10,20,30
    StartWidth : Double; // 40
    EndWidth   : Double; // 41
    Buldge     : Double; // 42
    Flags      : Integer; // 70
    TangentDir : Double; // 50
    PolyFace   : array [0..3] of Integer; // 71..74
    VertexIdx  : Integer; // 91
    constructor Create(const AEntityType: string = ET_VERTEX);
  end;

  { TDxfFileBlock }

  TDxfFileBlock = class(TDxfBlock)
  public
    _entities : TList;
    _blockEnd : TDxfBlockEnd;
    constructor Create;
    destructor Destroy; override;
    procedure AddEntity(ent: TDxfEntity);
  end;

  { TDxfFile }

  TDxfFile = class(TObject)
  public
    header   : TDxfHeader;
    classes  : TList;
    tables   : TList;
    entities : TList; // of TDxfEntitie
    blocks   : TList; // of TDxfFileBlock
    constructor Create;
    destructor Destroy; override;
    function AddTable: TDxfTable;
    procedure AddEntity(ent: TDxfEntity);
    function AddBlock: TDxfFileBlock;
    function AddClass: TDxfClass;
    procedure Clear;
  end;

type
  THeaderReadProc = procedure(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; var Handled: Boolean);

procedure RegisterHeaderVar(proc: THeaderReadProc);
procedure UnregisterHeaderVar(proc: THeaderReadProc);
procedure RunHeaderVarProc(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; out Handled: Boolean);
procedure DefaultHeaderVar(Header: TDxfHeader; const curVar: string; codeblock: Integer; const value: string; var Handled: Boolean);

procedure DxfFileDump(dxf: TDxfFile);

procedure PtrAttr(const codeGroup: Integer; scanner: TDxfScanner; var pt: TDxfPoint);

const
  DefZeroPoint : TDxfPoint = (x:0; y:0; z:0);
  DefExtrusionPoint : TDxfPoint = (x:0; y:0; z:1);

const
  DEF_EPSILON = 0.0000001;

function isSamePoint(const a,b: TDxfPoint; epsilon: Double = DEF_EPSILON): Boolean;
function isSameDbl(a,b: double; epsilon: Double = DEF_EPSILON): Boolean; inline;

implementation

function isSameDbl(a,b: double; epsilon: Double): Boolean; inline;
begin
  Result := (a=b) or (Abs(a-b)<epsilon);
end;

function isSamePoint(const a,b: TDxfPoint; epsilon: Double): Boolean;
begin
  Result:= isSameDbl(a.x,b.x, epsilon)
    and isSameDbl(a.y,b.y, epsilon)
    and isSameDbl(a.z,b.z, epsilon);
end;

{ TDxfFileBlock }

constructor TDxfFileBlock.Create;
begin
  inherited Create;
  _entities := TList.Create;
  _blockEnd := TDxfBlockEnd.Create;
end;

destructor TDxfFileBlock.Destroy;
var
  i : integer;
begin
  for i:=0 to _entities.Count-1 do
    TObject(_entities[i]).Free;
  _entities.Free;
  _blockEnd.Free;
  inherited Destroy;
end;

procedure TDxfFileBlock.AddEntity(ent: TDxfEntity);
begin
  if not Assigned(ent) then Exit;
  _entities.Add(ent);
end;

{ TDxfVertex }

constructor TDxfVertex.Create(const AEntityType: string);
begin
  inherited Create(AEntityType)
end;

{ TDxfPolyLine }

constructor TDxfPolyLine.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfInsert }

constructor TDxfInsert.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfTable }

constructor TDxfTable.Create;
begin
  inherited;
  fItems := TList.Create;
end;

destructor TDxfTable.Destroy;
begin
  Clear;
  fItems.Free;
  inherited Destroy;
end;

function TDxfTable.GetObject(i: integer): TDxfTableEntry;
begin
  if (i<0) or (i>=fItems.Count) then Result := nil
  else Result := TDxfTableEntry(FItems[i]);
end;

function TDxfTable.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TDxfTable.AddItem(obj: TDxfTableEntry): Integer;
begin
  if not Assigned(obj) then begin
    Result := -1;
    Exit;
  end;
  Result := fItems.Add(obj);
end;

procedure TDxfTable.Clear;
var
  i : integer;
begin
  for i:=0 to fItems.Count-1 do
    TObject(fItems[i]).free;
  fItems.Clear;
end;

{ TDxfFile }

constructor TDxfFile.Create;
begin
  inherited Create;
  header := TDxfHeader.Create;
  tables := TList.Create;
  blocks := TList.Create;
  entities := TList.Create;
  classes := TList.Create;
end;

destructor TDxfFile.Destroy;
var
  i : integer;
begin
  for i:=0 to entities.Count-1 do
    TObject(entities[i]).Free;
  entities.Free;
  for i:=0 to blocks.Count-1 do
    TObject(blocks[i]).Free;
  blocks.Free;
  for i:=0 to classes.Count-1 do
    TObject(classes[i]).Free;
  classes.Free;
  tables.Free;
  header.Free;
  inherited;
end;

function TDxfFile.AddTable: TDxfTable;
begin
  Result := TDxfTable.Create;
  tables.Add(Result);
end;

procedure TDxfFile.AddEntity(ent: TDxfEntity);
begin
  if not Assigned(ent) then Exit;
  entities.Add(ent);
end;

function TDxfFile.AddBlock: TDxfFileBlock;
begin
  Result := TDxfFileBlock.Create;
  blocks.Add(Result);
end;

function TDxfFile.AddClass: TDxfClass;
begin
  Result:=TDxfClass.Create;
  classes.Add(Result);
end;

procedure TDxfFile.Clear;
var
  i : integer;
begin
  for i:=0 to tables.Count-1 do
    TObject(tables[i]).Free;
  tables.Clear;
  for i:=0 to entities.Count-1 do
    TObject(entities[i]).Free;
  entities.Clear;
end;

procedure RegisterHeaderVar(proc: THeaderReadProc);
begin

end;

procedure UnregisterHeaderVar(proc: THeaderReadProc);
begin

end;

procedure RunHeaderVarProc(Header: TDxfHeader; const curVar: string;
  codeblock: Integer; const value: string; out Handled: Boolean);
begin
  Handled := false;
  DefaultHeaderVar(Header, curVar, codeblock, value, Handled);
end;

procedure DefaultHeaderVar(Header: TDxfHeader; const curVar: string;
  codeblock: Integer; const value: string; var Handled: Boolean);
begin
  Handled := true;
  if curVar = '' then begin
  end else
    Handled := false;
end;

procedure DxfFileDump(dxf: TDxfFile);
var
  i : integer;
  t : TDxfTable;
  e : TDxfEntity;
begin
  writeln('Tables: ', dxf.tables.Count);
  for i:=0 to dxf.tables.Count-1 do begin
    t := TDxfTable(dxf.tables[i]);
    writeln('  ',t.Name);
  end;
  writeln('Entities: ', dxf.entities.Count);
  for i:=0 to dxf.entities.Count-1 do begin
    e := TDxfEntity(dxf.entities[i]);
    //writeln('  ',e.Name,' ',e.ClassName);
  end;
end;

function AllocEntity(const Name: string): TDxfEntity;
begin
  Result := nil;
  if Name='' then Exit;

  case Name[1] of
    'I':
      if Name='INSERT' then
        Result := TDxfInsert.Create;
    'L':
      if Name='LINE' then
        Result := TDxfLine.Create;
    'P':
      if Name='POLYLINE' then
        Result := TDxfPolyLine.Create;
    'V':
      if Name='VERTEX' then
        Result := TDxfVertex.Create;
  end;
  if not Assigned(Result) then
    Result := TDxfEntity.Create;
  //Result.Name := Name;
end;

procedure PtrAttr(const codeGroup: Integer; scanner: TDxfScanner; var pt: TDxfPoint);
begin
  case codeGroup of
    10, 11, 41, 210: pt.x := scanner.ValFloat;
    20, 21, 42, 220: pt.y := scanner.ValFloat;
    30, 31, 43, 230: pt.z := scanner.ValFloat;
  end;
end;


{ TDxfSolid }

constructor TDxfSolid.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfCircle }

constructor TDxfCircle.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfLine }

constructor TDxfLine.Create(const AEntityType: string);
begin
  inherited Create(AEntityType);
end;

{ TDxfEntity }

constructor TDxfEntity.Create(const AEntityType: string);
begin
  inherited Create;
  Self.EntityType := AEntityType;
end;


end.
