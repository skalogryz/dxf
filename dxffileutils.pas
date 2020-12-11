unit dxffileutils;

interface

uses 
  dxftypes, dxfclasses;

procedure AddDefaultBlocks(dxf: TDxfFile);

implementation

procedure AddDefaultBlocks(dxf: TDxfFile);
var
  b : TDxfFileBlock;
begin
  b := dxf.AddBlock;
  b.BlockName := '*Model_Space';
  b.BlockName2 := '*Model_Space';

  b := dxf.AddBlock;
  b.BlockName := '*Paper_Space';
  b.BlockName2 := '*Paper_Space';

end;

end.
