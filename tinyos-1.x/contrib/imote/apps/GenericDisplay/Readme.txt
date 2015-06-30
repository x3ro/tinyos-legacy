This application is the generic receiver for the TempSensor, Accelerometer, 
and CamSensor applications.

Note:
This application uses the reliability protocol for the camera sensor file
transfer.  The reliability protocol limits the size of 
the address to 1 byte.  As a result, you have to use two motes that have the 
same 3 most significant hex digits for the imote address.  Also, you need to 
set the ADDR_OFFSET define in the platform/UtilitiesM.nc to match these digits.
e.g : mote address 0x87130, 0x87140
#define ADDR_OFFSET 0x87100
