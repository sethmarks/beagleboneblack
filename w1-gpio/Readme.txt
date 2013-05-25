This device tree enables the use of w1-gpio device driver in linux on the Beaglebone Black.

This is tested with a DS18B20 temp sensor using the ubuntu 13.04 distro.  

Many many online resources were consulted to pull this together.  Many thanks to all those who
contributed information.  

INSTALL:
- This assumes that w1-gpio is compiled into the kernel.  If not load the module with modprobe w1-gpio.
  By default the w1-gpio driver is installed in the BBB ubuntu 12.04 distro:
  http://elinux.org/BeagleBoardUbuntu.  I am using 2013-04-26
- Compile the dts into a dtbo. (https://github.com/jadonk/validation-scripts/tree/master/test-capemgr)

.../beaglebone-angstrom-linux-gnueabi/linux-mainline-3.8.13-r23a/git/scripts/dtc/dtc -O dtb -o cape-bone-w1gpio-00A0.dtbo -b 0 -@ cape-bone-w1gpio-00A0.dts


- Install the dtbo file onto the beagleboneblack in the /lib/firmware directory

echo cape-bone-weather-00A1 > /sys/devices/bone_capemgr.9/slot


- Make sure the sensor is connected correctly and check if it shows up.

ls /sys/bus/w1/devices/ 


