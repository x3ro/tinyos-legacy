/******************************************************************************
MODULE	INPISP for MICA platforms	      
PURPOSE: In-Network Program Bootloader for MICA2 ATMega 128 platform

DESCRIPTION
 Bootloader for the Atmel atmega 128 processor. 
 Accesses MOTOROLA srec format binary image from external FLASH (via SPI bus)
 Parses  srec address and opcode/data
 Writes opcode/data to address in uC FLASH
 When the process has completed, it sets up the watchdog timer, and loops until
   the watchdog reset.  Eventually it should reboot. 
   
FLASH SREC Structure
0	ProgID
1	
2	CID
3
4	SType
5	NofBytes
6	S0:ProgID, S1:Address
7
8	S1:Instruction0
...
   

*******************************************************************************
ATMEGA128 Boot & FLASH Parameters

FLASH Page Size = 128 words (256bytes)
FLASH Pages = 512 (128Kbytes)
FLASHEND = $FFFF (words)
BOOTSECTION
Minimum (512Bytes) $FE00 - $FFFF. Bootstart=$FE00  WORD ADDRESS

NOTE: gnu compiler/linker uses BYTE Addressing 

ATMega163 Parameters
FLASH PageSize = 64 words (128bytes)
FLASH Pages = 128
BootSection: 0x1C00 - 0x1FFF (maximum=1K)	<<WORD ADDRESS 


===============================================================================     
REVISION HISTORY
07jul03 mm disable WDTimer on entry
07apr03 mm removed S0 rec - all recs include program ID
30mar03	mm	revised record struct to include Program and CapsuleID
01jan03 mm compile under avr-gcc 3.3 for ATM128 native mode
29dec02	mm	modified for ATMEGA128
*/

#define JTAG
#define new
//#define new1
#define ATMega128

//----------------------INCLUDES --------------------------------------------
#include <avr/io.h>

#include "inttypes.h"
//#include <io.h>
#include <hardware.h>
#include <avr/wdt.h>
#ifdef new1
#include "avr/eeprom.h"
#endif

//----------------------DEFINITIONS --------------------------------------------
#define UINT8 char
#define UINT16 unsigned short
#define OK 1
#define FINI 2
#define ERROR 3
#define FALSE 0
#define TRUE 1
//uC FLASH Instructions
#define PAGE_ERASE 0x03
#define PAGE_LOAD  0x01
#define PAGE_WRITE 0x05
#define APP_ENABLE 0x11
#define SPMEN_BIT 0x01	//StoreProgramEnable bit

//External FLASH Instructions
#define EE_AUTOREAD 0x68	//<opcode:8><addr:24><fill:32>:then data streams out
#define EE_STATUS 0x57	//EE Status command
#define EE_BYTESPERPAGE 256 //nof actual bytes used in EEflash page

//ATMega FLASH Parameters
#ifdef ATMega163
#define UFPAGE_SIZEW 64		 //#of words per page
#define UFPAGE_SIZELOG 6 //shift word address to page address
#define UFPAGE_NOF 128
#endif
#ifdef ATMega128
#define UFPAGE_SIZEW 128		 //#of words per page
#define UFPAGE_SIZELOG 7 //shift word address to page address
#define UFPAGE_NOF 512
#endif

#define PROG_LENGTH 0x0004	 //Location in External FLASH where New Program length stored
#define UFLASH_ADDRESS_START 0x1000 //Destination (uC Flash) starting byte address
#define XFLASH_ADDRESS_START_PAGE 0x0001	//Source (Exernal Flash) starting address
#define XFLASH_ADDRESS_START_BYTE 0x00	//Source (Exernal Flash) starting address-skip 1st S0 record

#define SPMCR1 0x0068	   //equivalent to iom128 SPMCR w/o type

#define EE_SRECSIZE 32 //nof bytes per S record in EEFlash
#define STYPE_0 0
#define STYPE_1 1
#define STYPE_2 2
#define STYPE_9 9

//positions in FLASH Srex  
#define POS_PID 0	//new
#define POS_CID	POS_PID+2
#define POS_STYPE POS_CID+2
#define POS_SNOFB POS_STYPE+1
#define POS_S0_PID POS_SNOFB+1
#define POS_S0_CRC POS_S0_PID+2
#define POS_S1_ADDR POS_SNOFB+1
#define POS_S1_I0 POS_S1_ADDR+2	   //1st instruction

//EEPROM of ATMEga holds programid
#define AVREEPROM_PID_ADDR 		0xFF4  


#define strcat(...)
#define dbg(...)
#if 0
#define SET_CLOCK() sbi(PORTD, 3)
#define CLEAR_CLOCK() cbi(PORTD, 3)
#define MAKE_CLOCK_OUTPUT() sbi(DDRD, 3)
#define MAKE_CLOCK_INPUT() cbi(DDRD, 3)
#define SET_DATA() sbi(PORTD, 4)
#define CLEAR_DATA() cbi(PORTD, 4)
#define MAKE_DATA_OUTPUT() sbi(DDRD, 4)
#define MAKE_DATA_INPUT() cbi(DDRD, 4)
#define GET_DATA() (inp(PIND) >> 4) & 0x1
#endif
#define SET_CLOCK SET_I2C_BUS1_SCL_PIN
#define CLEAR_CLOCK CLR_I2C_BUS1_SCL_PIN
#define MAKE_CLOCK_OUTPUT MAKE_I2C_BUS1_SCL_OUTPUT
#define MAKE_CLOCK_INPUT MAKE_I2C_BUS1_SCL_INPUT

#define SET_DATA SET_I2C_BUS1_SDA_PIN
#define CLEAR_DATA CLR_I2C_BUS1_SDA_PIN
#define MAKE_DATA_OUTPUT MAKE_I2C_BUS1_SDA_OUTPUT
#define MAKE_DATA_INPUT MAKE_I2C_BUS1_SDA_INPUT
#define GET_DATA READ_I2C_BUS1_SDA_PIN

//-----------FUNCTION DECLARATIONS -------------------------------------------
/*****************************************************************************
__SPM(addr,command)
SelfProgramMode Operation
Load z register (R30/31) with addr
Load SPMCR register with command
Execute SPM instruction
SPMCR reg is at 0x0068 accessable only by STS (not I/O) instructions
*****************************************************************************/
#define __SPM(a, c) ({			\
    unsigned short __addr16 = (unsigned short) a; 	\
    unsigned char __cmd = (unsigned char) c;   \
    __asm__  __volatile__ (				\
			  "sts 0x0068, %0"	"\n\t" 	\
			   "spm" "\n\t"			\
              ".short 0xffff" "\n\t"        \
			  "nop" "\n\t"			\
			  :				\
			  : "r" (__cmd), "z" (__addr16) );				\
})

/**************************************************************************
SoftSPI bus macros
***************************************************************************/
static inline wait1() {
    asm volatile("nop" "\n\t");
    asm volatile("nop" "\n\t");
}
#define SPIOUTPUT     if (spi_out & 0x80) {	\
                           SET_FLASH_OUT_PIN();	\
                      } else {			\
	                   CLR_FLASH_OUT_PIN();	\
                      } 			\
                      spi_out <<=1;

#define SPIINPUT          spi_in <<= 1;			\
                          if (READ_FLASH_IN_PIN()) {	\
                        	spi_in |= 1;		\
                          } else {			\
                         	wait1();			\
                          }
/**************************************************************************/
void wait(void);
void fUPageFlush( UINT16 wUAddress );
void page_erase(unsigned short addr);
void page_write(unsigned short addr);
void page_load(unsigned short *pInstr, unsigned short addr);
void fSPMWait(void);
void reset();
char fEEStartRead( UINT16 PA, UINT16 BA);
unsigned short fEEGetInstruction(void);
UINT8 fEERead32( UINT8 *pEEBuff );
void fEEStopRead(void);	//deselect the flash
void fEEExecCommand(UINT8 opcode, UINT16 PA, UINT16 BA);
char fEEReady(void);
char fSPIInit(void);
UINT8 fSPIByte( UINT8 cOut);
void fSPIClockCycle(void);

//-----------CODE START-------------------------------------------------------
#ifdef JTAG
__asm__(".org 0x1f800, 0xff" "\n\t");
//and ENABLE appropriate line in makefile... 
//#Linker LIne for AVRSTUDIO JTAG (also see source file for changes)
//LD     = avr-ld -v -mavr5 -Map=BLMica2a.map -Tdata 0x800100
#endif
char _start(UINT16 wProgID, UINT16 wPageStart, UINT16 nwProgID, UINT8 param1)
{	
	UINT16 EEPageA;
	UINT16 EEByteA;		//EEFlash Addresss
    int i = 0;

	char bOK;
	UINT8 cNofBytes;
	UINT16 wDestAddrW;
	UINT16 wUAddress;
	UINT8 EEBuff[32];
	UINT8 *pEEBuff;
	UINT16 *pEEBuffW;
	UINT16 wPID;

    cli();	 //No INTERRUPTS allowed during reprogramming!!
	
//Note: uses CALLERS STACK POINTER
	wPID = wProgID;
	if( wPID != ~(nwProgID) )
		return; //error by caller -in future better to reboot?

//Disable WatchDog timer - may have been enabled by application
	wdt_disable();

	EEPageA = wPageStart;
	//Get IO Ports into defined state
    outp(0x00, DDRA);
    outp(0x00, DDRD);
    outp(0x00, DDRC);
    outp(0x00, DDRB);
    outp(0x00, PORTA);
    outp(0x00, PORTD);
    outp(0x00, PORTC);
    outp(0x00, PORTB);
    
    SET_RED_LED_PIN();
    SET_YELLOW_LED_PIN();
    SET_GREEN_LED_PIN();
    MAKE_RED_LED_OUTPUT();
    MAKE_YELLOW_LED_OUTPUT();
    MAKE_GREEN_LED_OUTPUT();
	fEEStopRead();	//deselect the flash

	fSPIInit();
    CLR_GREEN_LED_PIN();
	wUAddress = 0x00; 	//this MUST be fixed - should be first addr from srec
/*****************************************************************************
Get EEFlash Start Address (from caller)

Read out a 32byte SREC record from EEFlash
Check for valid SREC Type
Parse the SREC type (and write to UP program memory etc)
At end of each EEFlash Page
	Close Autoread
	Open next EE Page
Repeat until invalid/termination SREC type or error condition
****************************************************************************/

	//Starting point in EEFlash (Future caller will supply this)
  	EEPageA = XFLASH_ADDRESS_START_PAGE;
	EEByteA = XFLASH_ADDRESS_START_BYTE;
	//setup External Flash for autoinc readout
	fEEStartRead( EEPageA, EEByteA);
	bOK = 1;
	while (bOK==OK) {
	pEEBuff = &EEBuff[0];
	bOK = fEERead32(pEEBuff);		//Read a 32byte S record line
	switch( EEBuff[POS_STYPE] ) {
	case STYPE_1:
		//Verify Program ID - if wrong abort
		pEEBuffW = &EEBuff[POS_PID];
		wPID = (UINT16)*pEEBuffW;	
		if( wPID != wProgID){
			bOK = ERROR;	//exit-wrong PID
			break;
			}
		//S2 Parse
		cNofBytes = EEBuff[POS_SNOFB];
		pEEBuffW = &EEBuff[POS_S1_ADDR];		  //lsbyte in 2, most in 3
		//NOTE: wDestAddrW and wUAddress are BYTE addresses.
		wDestAddrW = (UINT16)*pEEBuffW;	

		pEEBuffW = &EEBuff[POS_S1_I0]; //point to first data element
		for (i=0;i<cNofBytes-4;i+=2 ){	//go by words
			if( wUAddress != (wDestAddrW & 0xFF00) ) {	//check crossing 128 word boundary
				CLR_RED_LED_PIN();
				fUPageFlush(wUAddress);	//flush the buffer into UP program memory
				wUAddress = wDestAddrW & 0xFF00;	 //make sure it is a page boundary
				SET_RED_LED_PIN();
				} //new UP page
			//write instruction word (2bytes) into UP buffer at Word aligned addresses
			page_load(pEEBuffW, wDestAddrW); //note UAddr stays at page boundary
			pEEBuffW++;
			wDestAddrW +=2; //increment by 2 bytes
			}//for i
		 break; //S1 rec

		case STYPE_9:
			//S9 Parse	 - boot address
			fUPageFlush(wUAddress);	//flush the last buffer into UP program memory
			pEEBuffW = &EEBuff[POS_S1_ADDR];   //same struct as S1 header
			wDestAddrW = (UINT16)*pEEBuffW;	//cheat - bigendian/littleendia pbm!!
			bOK = FINI;
			break;
		 case STYPE_0:   //verify correct ProgramID
			//S0 Parse	 - ProgID
			pEEBuffW = &EEBuff[POS_S0_PID];
			wPID = (UINT16)*pEEBuffW;	
#ifdef old
			if( wPID != wProgID)
				bOK = ERROR;	//exit-wrong PID  =legacy code/ignore record
#endif
			break;
		default:
			//ignore the record - move on to next...
			//bOK = ERROR;
			break;

		}//switch TYPE
//advance to next position in EEFlash
	EEByteA += EE_SRECSIZE;		//stepping thru flash page
	if( EEByteA > EE_BYTESPERPAGE-1 ){ //go to next EE Flash page
		fEEStopRead();	//deselect the eeprom
		EEPageA++;
		EEByteA = 0;
		fEEStartRead( EEPageA, EEByteA);
		//wait
		}
	}//while bOK
// Here if done with programming or error

//finished UP reprogramming
	fEEStopRead();	//deselect the flash
if( bOK == ERROR ) {
    reset();				//reboot :)
//	sei(); //reenable interrupts 	
//	return(FALSE);		 //wrong PID,no UP reprogramming done - return to application
	}
//Re Enable the Application section of uC Memory and wait until uC is ready
//    while (inp(SPMCR) & (1<<RWWSB)) {
   	__SPM(wUAddress,APP_ENABLE);
//    } //while inp

//UP Reprogrammed.
#ifdef new1
//update EEPROM with programid
    pEEBuff = &wProgID;	 //the prog id			   
	eeprom_write_byte (AVREEPROM_PID_ADDR, *pEEBuff++);//lsbyte
	eeprom_write_byte (AVREEPROM_PID_ADDR+1, *pEEBuff);//msbyte
#endif
    SET_GREEN_LED_PIN();
    reset();				//reboot :)
	return(TRUE); //never get here...
}
/*****************************************************************************
fUPageFlush
Erase and flush Instruction buffer into UP Program Memory page
*****************************************************************************/
void fUPageFlush( UINT16 wUAddress ) {
	page_erase(wUAddress);	//erase old program memory
	fSPMWait();	 //wait page_erase is finished
	//Flush(write) UF page buffer into flash
	page_write(wUAddress);	//write/flush uC buffer to FLASH - i.e. program it
	fSPMWait();	 //wait page_write is finished
	return;
}

/*****************************************************************************
reset
pass address for restart
*****************************************************************************/
void reset() {
    int i;
    wdt_enable(1);

    while(1){ //we be waiting...
	CLR_RED_LED_PIN();
	for (i=1; i != 0; i++);
	SET_RED_LED_PIN();
	for (i=1; i != 0; i++);
    }
}
/*****************************************************************************
fSPMWait
wait for SPM mode to complete
w*****************************************************************************/
void fSPMWait(void) {
    while (inp(SPMCR) & (SPMEN_BIT))
	return;
}
/*****************************************************************************
wait
waste some time
*****************************************************************************/
void wait(void) {
    char i;
    for (i =0; i < 20; i++) {
	__asm__ __volatile__ ("nop" "\n\t"::);
    }
}
/*****************************************************************************
page_erase
Erase FLASH page
addr is address of 1st byte in page. This is put in Z register.

Does NOT wait for SPM operation to complete before returning
*****************************************************************************/
void page_erase(unsigned short addr) {
    __SPM(addr, PAGE_ERASE);
    while(inp(SPMCR) & 0x01);
}
/*****************************************************************************
page_write
Write uC FLASH page
addr is address of 1st byte in page. This is put in Z register.

Waits until SPM operation is complete before returning
*****************************************************************************/
void page_write(unsigned short addr) {
    __SPM(addr, PAGE_WRITE);
    while(inp(SPMCR) & 0x01);	//wait for it to finish
}
/*****************************************************************************
page_load (instr,addr)
Store uC instruction (word) at addr in Page buffer
addr is a full 16bit byte address (includes Page address)

Instruction (instr) is placed in r0:r1
__SPM places addr in Z reg and executes PAGE_LOAD operation

Waits for SPM operation to complete before returning
*****************************************************************************/
void page_load(unsigned short *pInstr, unsigned short addr) {
	unsigned short instr;
	instr = *pInstr;
    __asm__ __volatile__ ("movw r0, %0" "\n\t"::"r" (instr):"r0", "r1");
    __SPM(addr, PAGE_LOAD);
    __asm__ __volatile__ ("clr r1" "\n\t"::);
    while(inp(SPMCR) & 0x01);
}
/*****************************************************************************
fEEGetInstruction
Returns an instruction read from EEFlash
Increments to next byte in EEFash
If at end of 256byte page (in TOS the pages are considered 256 bytes, not 264)
releases CS - stopping readout - and issues fEEStartRead at next page.
*****************************************************************************/
unsigned short fEEGetInstruction(void) {
    unsigned short retval;
	UINT16 i;
	retval = fSPIByte(0)& 0x00ff;	 //lsbyte
	i = (UINT16) (fSPIByte(0)<<8);
	retval = i | retval;	//make 16bits
    return retval;
}
/*****************************************************************************
fEERead32
Read 32 bytes from flash into buffer
*****************************************************************************/
UINT8 fEERead32( UINT8 *pEEBuff ) {
	char i;
	for (i=0;i<32;i++ )
		pEEBuff[i] = fSPIByte(0);
	return(1);
}
/*****************************************************************************
fEEStopRead
Releases EEFlash CS thereby terminating continuous readout operation
*****************************************************************************/
void fEEStopRead(void) {	//select the flash
	MAKE_FLASH_SELECT_OUTPUT();
	SET_FLASH_SELECT_PIN();
	return;
}
/*****************************************************************************
fEEStartRead(PageAddress,ByteAddress)
Setup EEFlash for continuous readout
EE Opcode = 0x68
Instruction Format
<opcode:8><address:24><fill:32>
<address:24> = <0x0:4, PA[10-0]:11, BA[8-0]:9>
Assert CS
Xmit Instruction
At end of instruction, SPI bus turned around to read in data bit on each SCLK.
CS is remains asserted
Succeeding SCLKS clock in bitwise data starting at <address> until CS released 
fEEStartRead
Execute an command+address to EEFlash
*****************************************************************************/
char fEEStartRead( UINT16 PA, UINT16 BA) {
//  void fEEExecCommand(UINT8 opcode, UINT16 PA, UINT16 BA) {
    // byte address, there are 8bytes per page that cannot be accessed. Will
    // use for CRC, etc.
    // command buffer is filled in reverse
	char cmdBuf[4];
	char i;
	cmdBuf[0] = EE_AUTOREAD; //opcode;	//EE Flash opcode
	cmdBuf[1] = (PA>>7)& 0x0F;	//PA[10:7] in lower nibble
	cmdBuf[2] = (PA<<1) + (BA>>8); //PA[6:0]+ BA[8]
	cmdBuf[3] = (UINT8) BA;		//BA[7:0]
	//select the flash
	MAKE_FLASH_SELECT_OUTPUT();
	CLR_FLASH_SELECT_PIN();

	for( i=0;i<4;i++)
		fSPIByte(cmdBuf[i]); //writeout the command
	for( i=0;i<4;i++)
		fSPIByte(0xAA);	//write out 4 fill bytes
	//EEFlash requires 1 additional (65th) clock to setup data on SOut pin
	fSPIClockCycle();
	return(0);
  }

/*****************************************************************************
fEEReady
Get EEFLash status (busy/idle)
issue 8bit opcode, read back status byte. MSB is READY/Busy
*****************************************************************************/
char fEEReady(void) {
   fSPIByte(EE_STATUS);
   return(fSPIByte(0) & 0x80);
}//fEEStatus   	

/*****************************************************************************
fSPIInit
*****************************************************************************/
char fSPIInit(void) {
    CLR_FLASH_CLK_PIN();
    MAKE_FLASH_CLK_OUTPUT();
    SET_FLASH_OUT_PIN();
    MAKE_FLASH_OUT_OUTPUT();
    CLR_FLASH_IN_PIN();
    MAKE_FLASH_IN_INPUT();
    return 1;
}
/*****************************************************************************
char fSPIByte
Write byte out spi port
Read byte in spi in port
*****************************************************************************/
UINT8 fSPIByte( UINT8 cOut) {
    UINT8 i;
    UINT8 spi_out = cOut;
    UINT8 spi_in = 0;
    for (i=0; i < 8; i++) {
		SPIOUTPUT;
		SET_FLASH_CLK_PIN();
		SPIINPUT;
		CLR_FLASH_CLK_PIN();
    }
	return(spi_in);
}
/*****************************************************************************
void fSPIClock(void) 
Toggle the SPIclk line
*****************************************************************************/
void fSPIClockCycle(void) {
	SET_FLASH_CLK_PIN();
	wait1();
	CLR_FLASH_CLK_PIN();
	return;
}

/*****************************************************************************
*****************************************************************************/

/*****************************************************************************/
/*ENDOFFILE******************************************************************/




