unit dxftypes;

interface

const
  CB_SECNAME = 2; // section name
  CB_VARNAME = 9; // variable name

  CB_TABLE_NAME   = 2;
  CB_TABLE_HANDLE = 5;

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

  // $CSHADOW
  CSHADOW_CASTRECV  = 0; // Casts and receives shadows
  CSHADOW_CASTONLY  = 1; // Casts shadows
  CSHADOW_RECVONLY  = 2; // Receives shadows
  CSHADOW_IGNORE    = 3; // Ignores shadows

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

// from Group Code Value Types
function DxfDataType(groupCode: Integer): TDxfType;

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
