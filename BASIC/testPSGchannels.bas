1 REM Plays the note C on selected channel
2 REM Ctrl+C to stop
10 REM Initialise PSG
20 FOR R=0 TO 13
30 SPOKE R,0
40 NEXT R
41 SPOKE 7,191
50 INPUT"Which Channel (A/B/C/0=Silence)";W$
60 IF W$="A" THEN 100
70 IF W$="B" THEN 200
80 IF W$="C" THEN 300
90 IF W$="0" THEN 20
95 GOTO 50:REM None of the above
100 REM Play note C in channel A
110 SPOKE 0,172:REM Fine Tune Ch A
120 SPOKE 1,1:REM Coarse Tune Ch A
130 SPOKE 8,12:REM volume=12
140 SPOKE 7,254:REM Activate Ch. A only
150 GOTO 50
200 REM Play note C in channel B
210 SPOKE 2,172:REM Fine Tune Ch B
220 SPOKE 3,1:REM Coarse Tune Ch B
230 SPOKE 9,12:REM volume=12
240 SPOKE 7,253:REM Activate Ch. B only
250 GOTO 50
300 REM Play note C in channel C
310 SPOKE 4,172:REM Fine Tune Ch C
320 SPOKE 5,1:REM Coarse Tune Ch C
330 SPOKE 10,12:REM volume=12
340 SPOKE 7,251:REM Activate Ch. C only
350 GOTO 50
