
MEMORYSTICK
@author David Moss (dmm@rincon.com)

Make sure your serial forwarder is enabled and BlackbookConnect is installed
on the mote before using the Java MemoryStick program.

I alias "memorystick" to "java com.rincon.blackbook.memorystick.MemoryStick"

$ memorystick
Not enough arguments
  MemoryStick
        -get [filename on mote] [as <filename on computer>]
        -put [filename on computer] [as <filename on mote>]
        -dir
        -delete [filename on mote]
        -isCorrupt [filename on mote]
        -freeSpace
        
        
$ memorystick -dir
2 total files:
        myTest.dict
        chkpoint.bb_


$ memorystick -delete myTest.dict
File deleted on mote.


$ memorystick -put BlackbookConnectM.nc
Writing BlackbookConn (25140 bytes)
  [##################################################] 100%

25140 bytes written to BlackbookConnectM.nc


$ memorystick -dir
2 total files:
        BlackbookConn
        chkpoint.bb_


$ memorystick -get BlackbookConn as DownloadedFile.txt
Getting BlackbookConn  (25140 bytes)
  [##################################################] 100%

25140 bytes read into C:\TinyOS\cygwin\opt\tinyos-1.1.15\contrib\Rincon\Apps\Bla
ckbook3\demos\BlackbookConnect\DownloadedFile.txt


$ diff DownloadedFile.txt BlackbookConnectM.nc

$ memorystick -isCorrupt BlackbookConn
Please wait, this could take awhile for large files...
File is OK on flash!

$ memorystick -freeSpace
950364 bytes available

$ memorystick -delete BlackbookConn
File deleted on mote.

$ memorystick -freeSpace
925020 bytes available

Remember, free space is approximate. The file size went down because the 
BlackbookConn file was finalized and deleted on flash, but
if we really needed more bytes than 925020, the garbage collector
would just allocate it.  Your data doesn't get erased until
the garbage collector says it should get erased.


