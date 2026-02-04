This is a derivative version of https://github.com/Lulu04/PacMan.

It offers the option to choose uos as the audio manager.

The file `/PacMan/Units/pacman_define.inc` allows you to choose the audio system to use.

Here is its content:

`{$DEFINE useuos} // Uncomment to use UOS and comment out to use Alsound Audio`.

You can modify it to choose the audio system to use.

Note that if you make any changes, you will have to recompile everything (using the `-B` parameter) because FPC sometimes ignores changes made to `.inc` files.
# PAC-MAN
a clone of the original game written entirely in FreePascal with Lazarus IDE.  
## Dependencies
You need to have the following package installed in your IDE:
- LazopenGLContext - provided with Lazarus
- BGRABitmap - https://github.com/bgrabitmap/bgrabitmap
- OGLCScene - https://github.com/Lulu04/OGLCScene
- ALSound - https://github.com/Lulu04/ALSound
When all packages are installed, open and compile the project under Lazarus.  
## About ALSound
Internally ALSound use LibSndFile and OpenALSoft library. The two binaries are provided with the package. If you want to use your own binaries, please go to https://github.com/Lulu04/ALSound and see the instructions.  
## Known bugs
- When PacMac eat a ghost, its direction change to the left. I've never been able to find that bug...
- When player lose a life, sometime Blinky start to move before all other sprites.  
## Credits
###Graphics:
https://www.spriters-resource.com/arcade/pacman/  reworked in vectorial with Inkscape  

###Sounds:
https://www.classicgaming.cc/classics/pac-man/
other sounds riped from original game with Mame + Audacity, recording the sound card output (loop back).  

###Fonts:
https://www.classicgaming.cc/classics/pac-man/
DynaPuff font: https://fonts.google.com/specimen/DynaPuff?categoryFilters=Feeling:%2FExpressive%2FCute  

###Game logic:
https://pacman.holenet.info/#Chapter_2
