# Programs for MS BASIC 4.7b on dastaZ80

## descendOUT.bas

Plays a descending tone on Channel A (Left), using the _OUT_ command that writes directly to the PSG ports.

## descendSPOKE.bas

Plays a descending tone on Channel A (Left), using the _SPOKE_  command, added by me to MS BASIC, that writes direclty to the PSG registers.

## mandelbrot.bas

Draws a full colour Mandelbrot set, in 26 lines, to the High Resolution Screen (VGA). It takes 4 minutes and 21 seconds to do the whole drawing.

![mandelbrot.bas](mandelbrot.png "mandelbrot.bas")

## pileibniz.bas

Calculates the value of Pi (3.14159) using the [Leibniz formula](https://en.wikipedia.org/wiki/Leibniz_formula_for_%CF%80).

In line 20 (_20 IT=1000_), _IT_ is the number of iterations. The bigger the number, the more accurate Pi number we'll get, but of course it takes longer to calculate.

Some tests I did:

* One iteration (IT=1): less than a second. Pi=4
* Ten iterations (IT=10): less than a second. Pi=3.33968
* Hundred iterations (IT=100): less than a second. Pi=3.1216
* Thousand iterations (IT=1000): 4.83 seconds. Pi=3.13959
* Ten thousand iterations (IT=10000): 46.89 seconds. Pi=3.1414
* Hundred thousand iterations (IT=100000): 7 minutes 40 seconds. Pi=3.1416

As a conclusion; hundred thousand iterations is totally accurate, as Pi value is 3.14159 which rounded up is 3.1416, but it took 7 minutes more than the ten thousand iterations just for that extra accuracy in the last digit.

## printchr.bas

Prints all printable ASCII characters from 33 to 254.

Characters from the ASCII extended table (128-254) are only visible when using the High Resolution Screen (VGA). On a terminal (e.g. minicom), those characters are shown as �

## testPSGchannels.bas

Plays the note C on the selected channel: A=Left, B=Right, C=Both

## testPSGmusic.bas

Plays a small part of the tune for the videogame [Army Moves](https://en.wikipedia.org/wiki/Army_Moves) by Manuel Cubedo.

## Not my own programs

Here (folder _notmine_) I'm including programs from other authors.

* **fourinarow.bas**: _Four In A Row_ game published in the book _David H. Ahl's More BASIC Computer Games_ (1979), to which I added some clear screen (_CLS_) commands to make it a bit more user friendly.
