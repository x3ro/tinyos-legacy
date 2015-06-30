This FlashViewer java app supports the FlashViewer nesC app on the mote. 

It lets the user control the flash on the mote through the BlockStorage interface.
This allows you to experiment with flash behavior and double check
that your flash programs are working correctly.

I always alias "flashviewer" to com.rincon.flashviewer.FlashViewer on my cygwin, 
then you just install the flashviewer app on the mote, run your serialforwarder,
and type "flashviewer" and you're good to go.

Here are some examples

reading flash, from address 0x0 to address 0x1200:
flashviewer -read 0x0 0x1200

reading flash, from address, 0x10000 to address 0x200:
flashviewer -read 0x10000 0x200

writing characters to flash:
flashviewer -write HelloWorld!

mounting to a volume in flash:
flashviewer -mount 0

erasing a volume in flash:
flashviewer -erase


