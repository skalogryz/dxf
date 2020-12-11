unit dxffileutils;

interface

uses 
  dxftypes, dxfclasses;

procedure AddDefaultBlocks(dxf: TDxfFile);

procedure NormalizeBlocks(dxf : TDxfFile);

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

procedure NormalizeBlocks(dxf : TDxfFile);
var
  i : integer;
  bf : TDxfFileBlock;
begin
  for i:=0 to dxf.blocks.Count-1 do begin
    bf := TDxfFileBlock(dxf.blocks[i]);
    // block end is owned by the stating block
    bf._blockEnd.Owner := bf.Handle;
  end;
end;

end.
