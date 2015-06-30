BlackbookConnect Dictionary-Only

Review the other readme's in the BlackbookFullConnect directory.




This is the application I used to debug Blackbook, but it does
everything you want it to.  You can use it
to see exactly how Blackbook works and what it does.  It essentially
takes all the interfaces to Blackbook and makes them available
to you on the computer, so you can run commands from the computer
to the mote, just as if you were part of the mote itself.  The 
Java interfaces in the com.rincon.blackbook directory
are just like the interfaces you'd see on the mote itself.

When BlackbookConnect is compiled to the mote, a green LED means
the FlashBridgeViewer is running, and a yellow/blue LED means
the BlackbookConnect stuff is running. You'll see the yellow/blue
LED go off when a sector is being erased.

There are 3 basic chunks of functionality provided by BlackbookConnect:

1. Execute all commands and receive all events from all interfaces
   provided by Blackbook on the computer.
   
2. View the status of all nodes, sectors, and file structs inside
   Blackbook. This is useful mostly for debugging or to fill your
   curiosity.
   
3. View the contents of the flash through the FlashBridgeViewer interface
   to see what Blackbook is doing under the hood.
   
Two Java applications work with BlackbookConnect to show off the features.
You'll need to copy the com.rincon.<whatever> directories into your own 
tinyos-1.x/tools/java directory.  These apps will interact
with BlackbookConnect:

com.rincon.blackbook.BlackbookConnect
com.rincon.blackbook.memorystick.MemoryStick
com.rincon.blackbook.printstatus.PrintFile
com.rincon.blackbook.printstatus.PrintNode
com.rincon.blackbook.printstatus.PrintSector
com.rincon.flashbridgeviewer.FlashViewer


Read the "blackbookconnect_readme.txt" for information 
and a walk through of all the stuff you can do with the Blackbook
interfaces from your desktop.

Read the "memorystick_readme.txt" for information and a walk
through of all the stuff you can do with the MemoryStick application


Shoot me some feedback on how this stuff works out for you.  Enjoy...

@author David Moss (dmm@rincon.com)


_____________________________________________________________________
com.rincon.blackbook.BlackbookConnect





