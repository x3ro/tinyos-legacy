BLACKBOOKCONNECT 
@author David Moss (dmm@rincon.com)

I aliased "blackbook" to "java com.rincon.blackbook.BlackbookConnect"

First, connect to the mote with SerialForwarder and
let's look at what's available in Blackbook:


$ blackbook
Not enough arguments!

Blackbook Usage:
com.rincon.blackbook.TestBlackbook [interface] -[command] <params>
_____________________________________
  BDictionary
        -open <filename> <minimum size>
        -close
        -insert <key> <value> <length>
        -retrieve <key>
        -remove <key>
        -getFirstKey
        -getNextKey <current key>

  BFileDelete
        -delete <filename>

  BFileDir
        -getTotalFiles
        -getTotalNodes
        -getFreeSpace
        -checkExists <filename>
        -readFirst
        -readNext <current filename>
        -getReservedLength <filename>
        -getDataLength <filename>
        -checkCorruption <filename>

  BFileRead
        -open <filename>
        -close
        -read <amount>
        -seek <address>
        -skip <amount>
        -getRemaining

  BFileWrite
        -open <filename>
        -close
        -save
        -append <written data>
        -getRemaining



BFILEWRITE INTERFACE
Let's open a file for writing with at least 0x1000 bytes (4096 bytes).
Blackbook will attempt to allocate the minimum requested size, but 
the actual writable size will extend to the next page boundary. 

$ blackbook bfilewrite
Not enough arguments
  BFileWrite
        -open <filename>
        -close
        -save
        -append <written data>
        -getRemaining
       
Open a file for writing with 0x1000 bytes:

$ blackbook bfilewrite -open testfile 0x1000
BFileWrite opened SUCCESS:

4328 bytes

Note the 4328 bytes allocated is a bit larger than 0x1000 (4096 bytes).
This is because there is some overhead in writing a file - 
If you want to get technical: the metadata, filename, etc. 
gets written to flash and then the actual data portion (17 pages worth)
of the node is extended to the next page boundary.  If you immediately close
the file now, the actual size of that node on flash will still be 
17 pages long, which is kind of a waste flash space.  So be careful
with opening files too big and then closing them too soon.

How much space do we have available for writing again?
$ blackbook bfilewrite -getremaining
4328 bytes available for writing

Now let's append some data.  The command line just acts as an example:

$ blackbook bfilewrite -append writing_to_my_file
BFileWrite append SUCCESS: 18 bytes

Save the file incase a catastrophic failure occurs:
$ blackbook bfilewrite -save
BFileWrite save SUCCESS

Continue appending data:
$ blackbook bfilewrite -append 1234567890
BFileWrite append SUCCESS: 10 bytes

Now how many bytes do we have available?
$ blackbook bfilewrite -getremaining
4300 bytes available for writing

Close the file.  You do not need to save the file immediately before closing.
$ blackbook bfilewrite -close
Closed SUCCESS

You can have multiple files open for reading and writing at the same
time, and you can have the same file open for reading and writing
simultaneously.
To access multiple files for writing at the same time, or reading
at the same time, you'll wire up your app to two or more
Blackbook parameterized read or write interfaces.



BFILEDIR INTERFACE
$ blackbook bfiledir
Not enough arguments
  BFileDir
        -getTotalFiles
        -getTotalNodes
        -getFreeSpace
        -checkExists <filename>
        -readFirst
        -readNext <current filename>
        -getReservedLength <filename>
        -getDataLength <filename>
        -checkCorruption <filename>

The space allocated to hold file and node information in RAM
is configurable in the BlackbookConst.h file.  You can increase
or decrease the amount of files/nodes on your own at compile time by defining

  CFLAGS += -DMAX_FILES=8
  CFLAGS += -DNODES_PER_FILE=3

in the Makefile.  By default, 
Blackbook provides 8 files with a minimum of 3 nodes each, for a total
of 24 nodes.   Nodes are the actual allocated spaces
in flash that hold information, and nodes cannot cross sector
bounds.  So for one large file, you may have 1 file containing
15 nodes on the flash.  RAM is the only constraint here.  Anyway....

Get the total files and nodes used by the file system:

$ blackbook bfiledir -gettotalfiles
2 total files

$ blackbook bfiledir -gettotalnodes
2 total nodes


Get the approximate free space on flash.  This is approximate because
sometimes deleted files already exist on flash that are taking up
space.. that space will get cleaned up by the garbage collector (BClean),
but it's not guaranteed. 

$ blackbook bfiledir -getfreespace
1045842 bytes available


Here's how you traverse the existing filenames on the file system.  First you
start off with the command readFirst, or just call readNext(NULL) in
your app, then call readNext with the current filename as the argument:

$ blackbook bfiledir -readFirst
BFileDir next file SUCCESS: chkpoint.bb_

$ blackbook bfiledir -readnext chkpoint.bb_
BFileDir next file SUCCESS: testfile

$ blackbook bfiledir -readnext testfile
BFileDir next file FAIL: No next file


So two files on our file system:  chkpoint.bb_ and testfile.
Let's check if the file we just wrote is corrupted:

$ blackbook bfiledir -checkcorruption testfile
BFileDir corruption check SUCCESS: File OK


We can check to see if files exist:

$ blackbook bfiledir -checkExists testfile
BFileDir exists check SUCCESS: File Exists

$ blackbook bfiledir -checkExists testfile1
BFileDir exists check SUCCESS: File does not exist


And we can find out stats on these files:
$ blackbook bfiledir -getDataLength testfile
28 bytes

$ blackbook bfiledir -getReservedLength testfile
4328 bytes reserved



BFILEREAD INTERFACE
$ blackbook bfileread
Not enough arguments
  BFileRead
        -open <filename>
        -close
        -read <amount>
        -seek <address>
        -skip <amount>
        -getRemaining
        
        
First let's open our testfile. Even though the chkpoint.bb_ file is in use
by the file system, you can still open it for reading if you want because
reading it will not alter the contents.  But the chkpoing.bb_ file contains
a lot of binary data you shouldn't worry about anyway.  So, let's open
the testfile we created earlier:

$ blackbook bfileread -open testfile
BFileRead opened SUCCESS: testfile
        28 bytes
        

Read some data:
$ blackbook bfileread -read 18
BFileRead readDone SUCCESS: 18 bytes read

77 72 69 74 69 6E 67 5F   74 6F 5F 6D 79 5F 66 69   |  writing_  to_my_fil
6C 65                                               |   e


$ blackbook bfileread -read 18
BFileRead readDone SUCCESS: 10 bytes read

31 32 33 34 35 36 37 38   39 30                     |  12345678  90


$ blackbook bfileread -read 18
BFileRead readDone SUCCESS: 0 bytes read

                                                    |
                                                    

The BFileRead interface supports random read access.  Let's rewind
back to the beginning by seeking address 0:

$ blackbook bfileread -seek 0
Seek success

$ blackbook bfileread -skip 10
Skip success

$ blackbook bfileread -getRemaining
18 bytes remaining

$ blackbook bfileread -read 18
BFileRead readDone SUCCESS: 18 bytes read

5F 6D 79 5F 66 69 6C 65   31 32 33 34 35 36 37 38   |  _my_file  123456789
39 30                                               |   0


And that's that.  Now let's close the file:
$ blackbook bfileread -close
Closed SUCCESS



BFILEDELETE INTERFACE
There's really only one command to the BFileDelete interface, and
it should be pretty self-explanatory:

$ blackbook bfiledelete
Not enough arguments
  BFileDelete
        -delete <filename>


$ blackbook bfiledelete -delete testfile
BFileDelete delete SUCCESS



BDICTIONARY INTERFACE
$ blackbook BDictionary
Not enough arguments
  BDictionary
        -open <filename> <minimum size>
        -close
        -insert <key> <value> <length>
        -retrieve <key>
        -remove <key>
        -getFirstKey
        -getNextKey <current key>
        
The BDictionary interface provides a lot of cool new features for letting
your apps interact with the flash.  Let your imagination run.

First let's open a dictionary file and reserve 0x1000 (4096 bytes) for
entries.  I'll call the file 'myTest.dict'

Dictionary files are different than binary files, although 
they can be read with BFileRead like binary files (but the data won't mean
much to anything else other than the Dictionary interface).  If it's 
the first time you're opening the dictionary, the 0x1000 bytes will
be reserved. If the dictionary already exists, your request for a minimum
reserved length is ignored and the size used to initially create the file
is loaded.

$ blackbook bdictionary -open myTest.dict 0x1000
BDictionary opened SUCCESS: 4328 bytes


Now let's insert some key-values pairs.  Keys are size uint32_t.
Values can be any size, up to the end of the file.

Like AM types, keys are managed by the components and applications 
themselves. You could produce a hash function or generate a crc for 
a string to make the keys more natural, but you risk conflicting keys.  
Each time an old key is re-inserted, the old value is lost.  The 12 
at the end denotes my value "I_Like_Steak" is 12 bytes long.

$ blackbook bdictionary -insert 0xBEEF I_Like_Steak 12
BDictionary inserted SUCCESS: Key 0xBEEF Inserted

$ blackbook bdictionary -insert 0xBABE Sup? 4
BDictionary inserted SUCCESS: Key 0xBABE Inserted

Keep in mind Java doesn't support unsigned anything, so sometimes
you may get a 0xFFFFFFFF<yourkey>  from the Java CLI if your key is really big

We can find the keys that exist in this dictionary file.
Get the first key, and then use it as the argument to getNextKey, 
just like in BFileDir:

$ blackbook bdictionary -getFirstKey
BDictionary next key SUCCESS: Next Key is 0xBEEF

$ blackbook bdictionary -getnextkey 0xBEEF
BDictionary next key SUCCESS: Next Key is 0xBABE

$ blackbook bdictionary -getnextkey 0xBABE
BDictionary next key FAIL


We can retrieve the values from a given key:

$ blackbook bdictionary -retrieve 0xbeef
BDictionary retrieved SUCCESS
49 5F 4C 69 6B 65 5F 53   74 65 61 6B               |  I_Like_S  teak

$ blackbook bdictionary -retrieve 0xbabe
BDictionary retrieved SUCCESS
53 75 70 3F                                         |  Sup?


Keys that don't exist return fail in the retrieve event:
$ blackbook bdictionary -retrieve 0x0
BDictionary retrieved FAIL


Remove a key:
$ blackbook bdictionary -remove 0xbeef
BDictionary removed SUCCESS: Key 0xBEEF Removed

Update an existing key:
$ blackbook bdictionary -insert 0xbabe hello_again 11
BDictionary inserted SUCCESS: Key 0xBABE Inserted

$ blackbook bdictionary -retrieve 0xbabe
BDictionary retrieved SUCCESS
68 65 6C 6C 6F 5F 61 67   61 69 6E                  |  hello_ag  ain

$ blackbook bdictionary -close
Closed SUCCESS


You can keep inserting and updating keys indefinitely, and if your file
size runs out a new file will be created somewhere on flash with the
valid keys from the original.  The only time inserting keys should fail
is when you insert all unique, valid keys in a single file and fill
up all the reserved space to the point where even copying out the
valid keys to a new file won't free up any space.

This dictionary stuff can be very useful for storing application settings.
The following code won't actually work, but the flow
will give you an idea of what you can do:

  // Here are some settings we want to keep on flash
  typedef struct settings {
    uint16_t securityLevel;
    uint32_t frameCount;
    bool radioSecurityEnabled;
    bool uartSecurityEnabled;
  } settings;

  ...
  
  settings securitySettings;
  
  ...
  
  // When blackbook is done booting:
  call BDictionary.open("Settings.sec", 0x500);
  // Load your settings from flash, assume key 0x53C:
  call BDictionary.retrieve(0x53C, &securitySettings, sizeof(securitySettings));
  
  ...
  
  event void BDictionary.retrieved(...) {
    if(result) {
      // The settings were loaded correctly into
      // the securitySettings struct.  No casting or
      // anything to do
      
    } else {
      // Setup default settings, and save it to flash for the next reboot:
      securitySettings.securityLevel = 5;
      securitySettings.frameCount = 0;
      securitySettings.radioSecurityEnabled = TRUE;
      securitySettings.uartSecurityEnabled = FALSE;
      call BDictionary.insert(0x53C, &securitySettings, sizeof(securitySettings));
    }
  }
  
