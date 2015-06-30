The FlashViewer simply uses the BlockStorage interface to access flash.

If you want to use the FlashBridge interface to access flash, go into the
/tos/lib/FlashBridge/apps/FlashBridgeViewer directory and compile that one.






You can setup FlashViewer as a standalone app, but if you're developing and testing
software that writes to flash, just wire it up to include it in your system. It uses
the BlockStorage interface to access flash, so format your flash first with the BlockStorage
format utility.

It requires the Transceiver and State components to be in your library, they'll
be compatible with the rest of your system. Right now the Makefile to test the
FlashViewer points the system to look for the Transceiver and State components in
your TinyOS library.  You may want to fix this to point it wherever the Transceiver
and State folders exist on your system.


Requires /contrib/rincon/tools/com/rincon/flashviewer Java app.

This FlashViewer java app supports the FlashViewer nesC app on the mote.

It lets the user control the flash on the mote through the BlockStorage interface.
This allows you to experiment with flash behavior and double check
that your flash programs are working correctly.

I always alias "flashviewer" to com.rincon.flashviewer.FlashViewer on my cygwin, 
then you just install the flashviewer app on the mote, run your serialforwarder,
and type "flashviewer" and you're good to go.

Here are some example commands:

$ flashviewer
No arguments found
Usage: java com.rincon.flashviewer [mote] [command]
  COMMANDS
    -read [start address] [range]
    -write [start address] [22 characters]
    -erase
    -commit
    -mount [volume id]
    -ping


I'm reading from an STM25P80 telos flash chip:
$ flashviewer -ping
Pong! The mote has FlashViewer installed.

You can see I uploaded a file to it called com.zip:
$ flashviewer -read 0x0 0x100
0x0 to 0x100
_________________________________________________
03 03 37 E4 63 6F 6D 2E   7A 69 70 00 00 00 00 00   |  ??7?com.  zip
00 00 FF FF 50 4B 03 04   0A 00 00 00 00 00 41 59   |      PK??
67 34 00 00 00 00 00 00   00 00 00 00 00 00 0B 00   |   4              ?
00 00 63 6F 6D 2F 72 69   6E 63 6F 6E 2F 50 4B 03   |    com/ri  ncon/PK??
04 0A 00 00 00 00 00 90   53 39 34 00 00 00 00 00   |
00 00 00 00 00 00 00 14   00 00 00 63 6F 6D 2F 72   |         ¶     com/ri
69 6E 63 6F 6E 2F 63 6F   6D 70 6F 72 74 73 2F 50   |   ncon/co  mports/PK
4B 03 04 14 00 00 00 08   00 DA 82 2D 34 CE FE 46   |   ??¶     ??-4??FF
46 FE 02 00 00 A7 05 00   00 24 00 00 00 63 6F 6D   |   ??  º?    $   com/
2F 72 69 6E 63 6F 6E 2F   63 6F 6D 70 6F 72 74 73   |   rincon/  comports/
2F 43 6F 6D 50 6F 72 74   73 24 31 2E 63 6C 61 73   |   ComPort  s$1.class
73 7D 53 5D 53 12 61 14   7E 5E 04 57 71 4D 25 CD   |   }S]S?a¶  ~^?WqM%??
B0 52 29 4A 40 01 C9 2C   13 B3 8C B2 A8 45 2D 8C   |   R)J@??,  ????¿E-??
D2 1A 67 D6 75 07 D6 81   5D 5A 96 C6 2E BA E9 CA   |   ?g?u??  ]Z??.????
BF E0 2F E8 A6 9B 2E 52   CB 99 A6 EB 7E 54 D3 79   |   ?/?ª?.R  ??ª?~T?y_
5F 40 CD AF 9D D9 7D CF   7B CE 73 9E F3 B9 7F FE   |   @?»??}?  {?s?????

I can erase this sector:
$ flashviewer -erase
SUCCESS: Erase complete

And then write some bytes to it:
$ flashviewer -write 0 ThisIsFlashViewer!
Writing data
0x54 0x68 0x69 0x73 0x49 0x73 0x46 0x6c 0x61 0x73 0x68 0x56 0x69 0x65 0x77 0x65
0x72 0x21
SUCCESS: 18 bytes written to 0x0

And then read it back:
$ flashviewer -read 0x0 0x20
0x0 to 0x20
_________________________________________________
54 68 69 73 49 73 46 6C   61 73 68 56 69 65 77 65   |  ThisIsFl  ashViewer
72 21 FF FF FF FF FF FF   FF FF FF FF FF FF FF FF   |   !                



