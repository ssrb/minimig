The PCB for Minimig rev1.1 is a two-layer PCB.
The bottom layer is used mainly as a ground plane. The top layer is used as a signal plane.
Because there are no seperate power planes, all large IC's have a small local powerplane in the top layer. This local plane is coupled tightly to the global gnd using LOTS of capacitors. This way, only 2 layers are needed. Almost all decoupling capacitors are mounted at the bottom side of the board.

layers from top to bottom

TSK - silkscreen
TMK - top solder mask
TOP - top copper
BOT - bottom copper
BMK - bottom solder mask
BSK - bottom silk screen (OPTIONAL)

All gerber files have embedded apertures so there are no seperate aperture files.
NCD is the N/C drill file.
Rev 1.1 of the Minimig PCB does not need any patches.

