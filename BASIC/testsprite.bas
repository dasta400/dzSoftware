1 REM Shows a 8x8 sprite on the screen
10 VSCREEN 2,8,0
11 RESTORE: REM Only needed if run other program
20 REM Set VRAM address 0x1800 for writting
21 REM For some reason address must be 0x1800-1
30 OUT 17,&HFF
41 OUT 17,&H17
40 REM Write sprite pattern to VRAM
50 FOR I=1 TO 8
60 READ B:OUT 16,B
70 NEXT I
80 REM Set VRAM address 0x3B00 for writting
81 REM For some reason address must be 0x3B00-1
90 OUT 17,&HFF
91 OUT 17,&H3A
100 REM Write sprite attributes to VRAM
101 OUT 16,10: REM Verti. coord.
102 OUT 16,10: REM Horiz. coord.
103 OUT 16,0: REM Spr. Name PTR
104 OUT 16,&H0C: REM Early CLK and Colour
110 END
120 DATA 16,16,254,124,56,108,68,0

1 REM Shows a 16x16 sprite on the screen
10 VSCREEN 2,16,0
11 RESTORE: REM Only needed if run other program
20 REM Set VRAM address 0x1800 for writting
21 REM For some reason address must be 0x1800-1
30 OUT 17,&HFF
41 OUT 17,&H17
40 REM Write sprite pattern to VRAM
50 FOR I=1 TO 32
60 READ B:OUT 16,B
70 NEXT I
80 REM Set VRAM address 0x3B00 for writting
81 REM For some reason address must be 0x3B00-1
90 OUT 17,&HFF
91 OUT 17,&H3A
100 REM Write sprite attributes to VRAM
101 OUT 16,10: REM Verti. coord.
102 OUT 16,10: REM Horiz. coord.
103 OUT 16,0: REM Spr. Name PTR
104 OUT 16,&H0C: REM Early CLK and Colour
110 END
120 DATA 0,0,1,1,1,3,3,7
121 DATA 7,15,31,63,60,24,0,0
122 DATA 0,0,128,128,128,192,192,224
123 DATA 224,240,248,252,60,24,0,0














10 VSCREEN 2
20 VPOKE &H1800,&H10
21 VPOKE &H1801,&H10
22 VPOKE &H1802,&HFE
23 VPOKE &H1803,&H7C
24 VPOKE &H1804,&H38
25 VPOKE &H1805,&H6C
26 VPOKE &H1806,&H44
27 VPOKE &H1847,&H00
30 VPOKE &H3B00,&H0A
31 VPOKE &H3B01,&H0A
32 VPOKE &H3B02,&H00
33 VPOKE &H3B03,&H0C
