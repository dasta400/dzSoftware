1 REM Descending tones on Channel A
2 REM using OUT direct to the PSG
10 L=125:REM Delay counter
11 R=&h20:REM PSG Register port
12 D=&h21:REM PSG Data port
20 OUT R,7 : REM select the mixer register
21 OUT D,62 : REM enable channel A only
22 OUT R,8 : REM select channel A volume
23 OUT D,15 : REM set it to maximum
24 OUT R,0 : REM select channel A pitch
30 FOR N=1 TO 255
31 OUT D,N : REM set picth to N
32 GOSUB 100:REM do a delay
33 NEXT N
40 GOTO 20
100 FOR X=1 TO L:NEXT X:RETURN
