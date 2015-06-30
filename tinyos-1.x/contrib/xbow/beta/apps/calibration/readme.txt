CALIBRATION Beta Project

- There are four subdirectories in this directory:
1.caltest
	- It is the test application based on MDA300. we can install it to MDA300 and listen to it.
2.xcmd_cal
	- It is the command tool to set excitation settings. Only two existed files were changed. they are xapps.h and Makefile. And three files are added to the directory "\apps\". They are Calibration.h, cmd_Calibration.c and mda300calib.c . We can replace these files in the directory \xbow\beta\tools\src\xcmd and make the application. then we can use xcmd to test the new calibration project.
3.XCommand_cal
	- nothing was changed but add a struct in xcommand.h . we can replace xcommand.h in the directory \xbow\tos\lib\XLib . If you don't want to change the original file, you can move xcommand.h to the directory caltest. then caltest can be compiled well.
4. xlisten_cal
	- If we want to use xlisten to receive the message from the MOTE, we must add some code in mda300.c to parse the packet 7 for calibration. so you should move mda300.c in this directory to the directory \tools\src\xlisten\boards\. Then recompile it and you can receive the calibration packet for MDA300.

/*****************************************************************************/
STRUCTURE
we have two kinds of information to be stored in sensorboard EEPROM .
BoardInfo and calibration packet.
BoardInfo is as follows:
typedef struct BoardInfo {
  uint16_t  typeinfo;
  uint8_t   infolen;
} __attribute__ ((packed)) BoardInfo;
typeinfo is made up of two BYTE, one byte is the sensorboard ID, one byte is index. As for MDA300, the typeinfo is 0x8100. 
infolen is the length of the calibration packet for MDA300.

Calibration packet for MDA300
typedef struct PData7 {
  uint16_t vref;
  uint16_t humid;
  uint16_t humtemp;
  uint16_t adc_channels;  
  uint16_t dig_channels;  
  uint16_t rev_channels;
} __attribute__ ((packed)) PData7;

/************************************************************************/

HOW TO USE XCMD TO SET EXCITATION SETTINGS:
we have only two command for calibration
1. set_bdinfo : set board info
2. set_cal :  set calibration infomation.
each command have three kinds of format.

1. search table by name
fg: xcmd set_bdinfo T[MDA300,BD_TYPE,8100] -a=52
will set the sensorboard typeinfo 0x8100;
T : search table type.
MDA300: get board id by the name.
BD_TYPE: search parameter should be set by the name.
8100: the value to be set. It is hexadecimal. 

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
remember: before any calibration test, you should execute such command to make sure board type has been stored in EEPROM of the sensorboard. If no board type , no calibration infomation can be set.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

2. set WORD
fg: xcmd set_cal W[8100,2,4444] -a=52
will set calibration infomation.
W: a Word will be set.
8100: board type is 8100. As for MDA300, always be 8100. (hexadecimal)
2: offset. From PData7, we can see humid will be set. (hexadecimal)
4444:value to be set. humid will be 0x4444. (hexadecimal)

3. set BYTE
fg: xcmd set_bdinfo B[8100,2,c] -a=52
will set board infomation.
W: a Word will be set.
8100: board type is 8100. As for MDA300, always be 8100. (hexadecimal)
2: offset. From BoardInfo , we can see infolen will be set. (hexadecimal)
c:value to be set. infolen will be 0x0c. (hexadecimal)

/***********************************************************************/
All the commands by search TALBE
xcmd set_bdinfo T[MDA300,BD_TYPE,8100] -a=52	//set board type info
xcmd set_bdinfo T[MDA300,BD_LEN,c] -a=52	//set calibration packet len
xcmd set_cal T[MDA300,VREF,**] -a=52	//set calibration info "vref"
xcmd set_cal T[MDA300,HUMID,**] -a=52	//set calibration info "humid"
xcmd set_cal T[MDA300,HUMTEMP,**] -a=52	//set calibration info "humtemp"
xcmd set_cal T[MDA300,ADCCH,**] -a=52	//set calibration info "adc_channels"
xcmd set_cal T[MDA300,DIGCH,**] -a=52	//set calibration info "dig_channels"
xcmd set_cal T[MDA300,REVCH,**] -a=52	//set calibration info "rev_channels"
/************************************************************************/