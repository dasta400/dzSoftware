1 REM Calculates the value of Pi
2 REM using the Leibniz formula
3 REM "IT" is the number of iterations
4 REM the bigger the number, the more
5 REM accurate Pi will be, but of course
6 REM it takes longer
10 CNT=1:PI=0:SUM=0
20 IT=1000
30 FOR I=1 TO IT STEP 2
40 SUM=1/I
50 IF COUNTER-2*INT(COUNTER/2)=0 THEN SUM=-SUM
60 COUNTER=COUNTER+1:PI=PI+SUM
70 NEXT I
80 PI=PI*-4
90 PRINT "PI =";PI
100 END
