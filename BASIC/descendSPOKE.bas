1 REM Descending tones on Channel A
2 REM using my MSBASIC command SPOKE
10 L=128
20 SPOKE 7,62 : REM enable only Ch. A on the mixer
21 SPOKE 8,15 : REM set Ch. A volume to maximum
30 FOR N=1 TO 255
31 SPOKE 0,N : REM set Ch. A tone
32 GOSUB 100 : REM do a delay
33 NEXT N
40 GOTO 20
100 FOR X=1 TO L:NEXT X:RETURN
