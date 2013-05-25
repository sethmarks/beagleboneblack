beableboneblack
===============

Random Beaglebone Black (BBB) Code

I have a BeagleBone Black just for fun.  I spent a significant amount of time trying to get 
some things working and in the process I appreciated all the folks that posed their knowledge
online.  It is a fairly new board and had some significant changes since the beaglebone.
In particular the kernel change to 3.8 seemed to change some basic operations of GPIO and
w1-gpio via device trees and the changes in the pinmux interface.

Included in this repository are the following:

1) A working device tree "firmware" file that enables w1-gpio to function in the BBB.
   I use the ubuntu disto for the BBB so Angstrom may or may not have the same results.
   On ubuntu the w1-gpio driver is build in the standard kernel from:
   http://elinux.org/BeagleBoardUbuntu

2) Very basic PRU interface to control GPIOs.
   This is a blocking non-interrupt driven very basic interface but it is fast.
   I am attempting to use it to communicate with a DHT11. 



