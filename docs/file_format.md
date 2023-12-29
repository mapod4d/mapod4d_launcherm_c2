# Update files format

## Src file
Il file che deve essere split.

## Dst directory
La directory dove i file split sono memorizzati

## CHUNKSIZE
Dimensione in byte del chunk

## brick size
= CHUNKSIZE * 1000

## Split process
Open the file
Read CHUNKSIZE block
compress CHUNKSIZE block (if it is necessary)
write CHUNKSIZE block in the brick



## Schema
<tt>

									 test.exe
Src file |---------------------------------------------------------------|
Brick           test_01                   test_02               test_03
		 |------------------------||------------------------||-----------|
chunk       0      1      2     3     0      1      2     3     0     1
		 |-----||-----||-----||---||-----||-----||-----||---||-----||----|

</tt>
