The FlashBridge interface is built on top of the PageEEPROM component.
This is definitely not the best way to do this.  On the bottom of my 
TODO list is port the FlashBridge component directly to the AT45DB.

The AT45DB is a flash chip that emulates EEPROM through its on-board
RAM buffers.  Writes to the chip actually perform a read-modify-write
operation which takes twice as long as a regular write operation.
Because of the RAM buffers, it is necessary to flush() data after you
have written it to ensure that data gets placed into non-volatile memory.

The erase() function is not necessary to call before writing if you are strictly 
using the AT45DB flash for your application.  Calling erase will simply write
0xFF fill bytes to the entire flash sector.  This helps ensure platform
compatibility.

@author David Moss


