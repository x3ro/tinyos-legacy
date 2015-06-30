//  $Id: HIL.c,v 1.3 2004/12/15 07:36:01 szewczyk Exp $
/* "Copyright (c) 2000-2004 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */


/*
  @author Robert Szewczyk <szewczyk@eecs.berkeley.edu>

  Low level routines for accessing JTAG over USB on telos rev b. 

  @author Chris Liechti <cliechti@gmx.net>
 
  Original HIL driver for a variety of low latency JTAG pods.  Please see
  LICENSE.txt in the current directory.  

  This drivers require FTDI's D2xx drivers to be installed and configured for
  the device.  The functionality has only been tested under Windows, though
  there are Linux D2XX drivers.


  Extensive effort has been made to hide the USB latency.  As a rule of thumb:
  HIL_* functions only construct the JTAG waveforms, but do not actually send
  them or resynchronize the result.  

  To allow for reading out the data, markers are defined for every JTAG_IR or
  JTAG_DR function invocation.  The last marker can be obtained by calling
  HIL_GetMarker().  

  HIL_Resync() needs to be called before any reads can occur.  Reading out the
  parameters is done through HIL_ReadMarker(). 

  HIL_Flush will clear the buffers and markers.  

  I defined two convinience functions:  
  getLastMarker() -- will resynchronize, obtain the last value (and return
  it), and flush the state of the interface
  checkMacro() -- will resynchronize, compare a chosen return value to a
  chosen marker, and flush the state.  For simplicity of the interface, the
  markers are treated as a stack, top of the stack is 1, the next element is
  2, etc.  This function is useful when we want to check that, say, an IR
  scan issued 5 scans ago is in fact returning a JTAG ID.  

  *** FUTURE WORK/TODO ****
  - break out this file into a cleaner abstraction.  In particular, it seems
  that the I2C interface, and an SPI interface could be made into more generic
  modules;  similar observation holds for the resynchronization.  Furthermore,
  the buffer management could be improved, resync might simply extract all the
  data from the scan, etc.  Many other thoughts, but at this point, this shows
  the basic functionality and I need to check it in.  
  - port hte interface to libftdi -- the user-space direct interface to the
  FTDI chips that works under Linux (and possibly under Win32).
-- RS. 
*/

// Hardware Interface Layer (HIL).

// The functions within this file implement the Hardware Interface Layer
// required by the MSP430 debug DLL/so.

// #includes. -----------------------------------------------------------------
#undef __linux__
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
//#include <conio.h>
#include "Basic_Types.h"
#include "FTD2XX.H"

// If linking in the HIL object file directly into the app, uncomment the two
//lines below. 
//#undef WINAPI
//#define WINAPI 
#include "HIL.h"

// #defines. ------------------------------------------------------------------

/* Parallel port data register bits (Write-only). */
#define TCK     0x10  //DTR 
#define TMS     0x08  //CTS, I think 
#define TDO     0x40  //DCD 
#define TDI     0x80  //RI  
#define TCLK    TDI    // Same as TDI
#define SDA     0x10  //DTR
#define SCL     0x04  //RTS

#define VCC     0x10
#define OSC32   0x20
#define OSCPRG  0x40
#define PWR     (0x80 + 0x40 + 0x20)    // Needed for FET430x110

#define CTRL_RST    0x01
#define CTRL_TCK    0x04
#define CTRL_TMS    0x08
#define CTRL_TDI    0x10
#define CTRL_TDO    0x20
/* Parallel port control register bits (Write-only). */
#define RST     0x01
#define EN_TCLK 0x02
#define TST     0x04
#define EN_JTAG 0x08

#define DEFAULT_VCC         3000    // Default Vcc to 3V (3000mV).
#define DEFAULT_RSTDELAY    10      // Default RST/NMI delay to 10mSec.
void debug_signal(int n, unsigned char *buf);
// (File) Global variables. ---------------------------------------------------

static char useTDI = TRUE;          // Shift intructions using TDI (else use TDO [while securing device]).

static unsigned char portData = TMS|TCK|TDI;  // Copy of write-only parallel port data register.
static unsigned char portCtrl = 0;  // Copy of write-only parallel port control register.
static unsigned char swState = 0;
#if 0
#if defined(HIL_PPDEV)  ||  defined(HIL_REDIRECTIO)
static int fd = 0;                  //file handle for parport/ppdev

static struct timeval _tstart;
static struct timeval _tend;
static struct timezone tz;
#else
static LARGE_INTEGER _tstart;
static LARGE_INTEGER _tend;
static LARGE_INTEGER freq;
#endif

#endif
static LARGE_INTEGER _tstart;
static LARGE_INTEGER _tend;
static LARGE_INTEGER freq;
FT_HANDLE fd = 0;
FT_STATUS s =0;

// (Local) Function prototypes. -----------------------------------------------

static BYTE ReadTDI(void);
static BYTE ReadTDO(void);
static void PrepTCLK(void);

#define StoreTCLK()     ((portData  &   TCLK))
#define RestoreTCLK(x)  ((x == 0)  ?  ClrTCLK()  :  SetTCLK())


static __inline__ void ClkTCK(void)
{
    ClrTCK();
    SetTCK();
}

#define OUTBUF_SIZE 32768
#define INBUF_SIZE  32768
#define USB_BUF_SIZE 16384

static unsigned char outbuf[OUTBUF_SIZE];
static unsigned char inbuf[INBUF_SIZE];
static unsigned char tmpbuf[INBUF_SIZE];
static int markbuf[128];
static int markbufpos = 0;
static int outbufpos = 0;
static int inbufpos = 0;

static unsigned int debug_level=3;


static char* hilErrorStrings[] = {
    "No Error",
    "FTDI: invalid handle",
    "FTDI: device not found",
    "FTDI: device not opened",
    "FTDI: I/O error",
    "FTDI: insufficient resources",
    "FTDI: invalid parameter",
    "FTDI: invalid baud rate",
    "FTDI: device not opened for erase",
    "FTDI: device not opened for write",
    "FTDI: failed to write device",
    "FTDI: EEPROM read failed",
    "FTDI: EEPROM write failed", 
    "FTDI: EEPROM erase failed",
    "FTDI: EEPROM not present",
    "FTDI: EEPROM not programmed",
    "FTDI: invalid arguments",
    "FTDI: not supported", 
    "FTDI: something bad happened"
};

STATUS_T WINAPI HIL_Log(unsigned int level, const char *format, ...) {
    if (debug_level > level) {
        va_list args;
        va_start(args, format);
        vfprintf(stderr, format, args);
        va_end(args);
    }
    return STATUS_OK;
}


void outdata(FT_HANDLE fd, unsigned char data) {
    outbuf[outbufpos++] = data;
    if (outbufpos >= OUTBUF_SIZE) {
	debug_signal(outbufpos, outbuf);
	outbufpos = 0;
    }
}

/* I2C routines;  */

void setSDA(unsigned char i) {
    if (i) 
	portData |= SDA;
    else 
	portData &= ~SDA;
    outdata(fd, portData);
}

void setSCL(unsigned char i) {
    if (i) 
	portData |= SCL;
    else
	portData &= ~SCL;
    outdata(fd, portData);
}
	

void I2CStart() {
    setSDA(1);
    setSCL(1);
    setSDA(0);
}

void I2CStop() {
    setSDA(0);
    setSCL(1);
    setSDA(1);
}

void I2CWriteBit(unsigned char out) {
    setSCL(0);
    setSDA(out);
    setSCL(1);
    setSDA(out);
    setSCL(0);
}

void I2CWriteByte(unsigned char out) {
    I2CWriteBit((out >> 7) & 0x01);
    I2CWriteBit((out >> 6) & 0x01);
    I2CWriteBit((out >> 5) & 0x01);
    I2CWriteBit((out >> 4) & 0x01);
    I2CWriteBit((out >> 3) & 0x01);
    I2CWriteBit((out >> 2) & 0x01);
    I2CWriteBit((out >> 1) & 0x01);
    I2CWriteBit( out       & 0x01);
    I2CWriteBit(0);
}

void I2CWriteCmd(unsigned char addr, unsigned cmd) {
    I2CStart();
    I2CWriteByte( 0x90 | (addr <<1) ); 
    I2CWriteByte(cmd);
    I2CStop();
}


/* ----------------------------------------------------------------------------
Function:
 STATUS_T WINAPI HIL_Initialize(CHAR const *port);

Description:
 Initialize the interface.

Parameters:
 port:    Interface port reference (application specific). for now, the string
 is expected to be the number of the device connected to the USB bus
 (1,2,3... etc.)

Returns:
 STATUS_OK:    The interface was initialized.
 STATUS_ERROR: The interface was not initialized.

Notes:
 1. port is the parameter provided to MSP430_Initialize().
*/
STATUS_T WINAPI HIL_Initialize(CHAR const *port)
{
    DWORD numDevs=0;
    char buffer[128];
    QueryPerformanceCounter(&_tstart);
    s = FT_ListDevices(&numDevs, buffer, FT_LIST_NUMBER_ONLY);
    if (s != FT_OK) {
	HIL_Log(1, "Could not find suitable device: %d\n", s);
	return STATUS_ERROR;
    }
    if (numDevs == 1) { // only a single device, likely the common case
	s = FT_Open(0, &fd);
    } else { // otherwise use the port number
	s = FT_Open(atoi(port), &fd);
    }
    if (s != FT_OK) {
	HIL_Log(1, "Open failed: %s\n", hilErrorStrings[s]);
	return STATUS_ERROR;
    }
    // set the data rate; FT_SetDivisor proved more reliable than using
    // FT_SetBaudRate.  Valid divisors should be divisible by 48 -- for
    // bitbanging there seems to be a 16-fold increase in the clock rate, and
    // the lowest 3 bits always refer to fractional clock divisors that we
    // would want to stay away from 
    s = FT_SetDivisor(fd, 96); 
			       
    if (s != FT_OK) {
	HIL_Log(1, "Setting baud rate failed: %s\n", hilErrorStrings[s]);
	FT_Close(fd);
	fd = 0;
	return STATUS_ERROR;
    }
    
    //Set timeouts
    s = FT_SetTimeouts(fd, 5, 0); // 5 ms timeout
    if (s != FT_OK) {
	HIL_Log(1, "Could not set the timeouts: %s\n", hilErrorStrings[s]);
	FT_Close(fd);
	fd =0 ;
	return STATUS_ERROR;
    }
    //Enter the bit-bang mode, TDO is the only input.
    s = FT_SetBitMode(fd, 0xff & ~TDO, 1);
    if (s != FT_OK) {
	HIL_Log(1, "Could not enter the bitbang mode: %s\n", hilErrorStrings[s]);
	FT_Close(fd);
	fd = 0;
	return STATUS_ERROR;
    }
    //Latency timer.  Currently set to default value, later will investigate
    //the performance implications of different latency timers. 
    s = FT_SetLatencyTimer(fd,1);
    if (s != FT_OK) {
	HIL_Log(1, "Could not set the latency timer: %d\n", hilErrorStrings[s]);
	FT_Close(fd);
	fd = 0;
	return STATUS_ERROR;
    }
    return (STATUS_OK);
}

/* ----------------------------------------------------------------------------
Function:
 STATUS_T WINAPI HIL_Open(void);

Description:
 Enable the JTAG interface to the device.

Parameters:

Returns:
 STATUS_OK:    The JTAG interface was opened.
 STATUS_ERROR: The JTAG interface was not opened.

Notes:
 1. The setting of Vpp to 0 is dependent upon the interface hardware.
 2. HIL_Open() calls HIL_Connect().
*/
STATUS_T WINAPI HIL_Open(void)
{
    HIL_Release(); // Negate control signals before applying power.
    HIL_VPP(0);
    HIL_Connect();
    
    return (STATUS_OK);
}

/* ----------------------------------------------------------------------------
Function:
 STATUS_T WINAPI HIL_Connect(void);

Description:
 Enable the JTAG connection to the device.

Parameters:

Returns:
 STATUS_OK:    The JTAG connection to the device was enabled.
 STATUS_ERROR: The JTAG connection to the device was not enabled.

Notes:
*/
STATUS_T WINAPI HIL_Connect(void)
{
    swState = CTRL_TDO |CTRL_TDI |CTRL_TMS|CTRL_TCK;
    I2CWriteCmd(0, swState);
    return (STATUS_OK);
}

/* ----------------------------------------------------------------------------
Function:
 STATUS_T WINAPI HIL_Release(void);

Description:
 Release the JTAG interface to the device.

Parameters:

Returns:
 STATUS_OK:    The interface was released.
 STATUS_ERROR: The interface was not released.

Notes:
 1. All JTAG interface signals should be tristated and negated.
*/
STATUS_T WINAPI HIL_Release(void)
{
    swState = 0; //release everything
    I2CWriteCmd(0, swState);
#if 0
    // Disable Jtag signal (TDI, TDO, TMS, TCK) buffers.
    portCtrl &= ~(EN_JTAG | EN_TCLK);
    // Disable RST signal buffer.
    portCtrl &= ~EN_TCLK;
#if defined(HIL_PPDEV)
#if defined(__linux__)
    if (ioctl(fd, PPWCONTROL, &portCtrl))
#elif defined(__FreeBSD__)
    if (ioctl(fd, PPISCTRL, &portCtrl))
#endif
    {
        perror("ioctl");
        return (STATUS_ERROR);
    }
#else
    out_byte(port_base + CTRLOFF, portCtrl);
#endif
    HIL_TDI(0);
    HIL_TMS(1);
    HIL_TCK(1);
    HIL_TCLK(1);
    HIL_RST(1);
    HIL_TST(0);
#endif
    return (STATUS_OK);
}

/* ----------------------------------------------------------------------------
Function:
 STATUS_T WINAPI HIL_Close(LONG vccOff);

Description:
 Close the interface.

Parameters:
 vccOff: Turn off the device Vcc (0 volts) if TRUE.

Returns:
 STATUS_OK:    The interface was closed.
 STATUS_ERROR: The interface was not closed.

Notes:
*/
STATUS_T WINAPI HIL_Close(LONG vccOff)
{
    // Turn off device Vcc, negate control signals, and cleanup parallel port.
    if (vccOff)
        HIL_VCC(0); // Turn off device Vcc.
    HIL_Release(); // Disable (tri-state) control signals.
    FT_Close(fd);
    return (STATUS_OK);
}

#define INSTRUCTION_LEN 8
#define BITS_LEN        16

/* ----------------------------------------------------------------------------
Function:
 LONG WINAPI HIL_JTAG_IR(LONG instruction);

Description:
 The specified JTAG instruction is shifted into the device.

Parameters:
 instruction: The JTAG instruction to be shifted into the device.

Returns:
 The byte shifted out from the device (on TDO).

Notes:
 1. The byte instruction is passed as a LONG
 2. The byte result is returned as a LONG.
 3. This function must operate in conjunction with HIL_TEST_VPP(). When the parameter to
    HIL_TEST_VPP is FALSE, shift instructions into the device via TDO. No results are shifted out.
    When the parameter to HIL_TEST_VPP is TRUE, shift instructions into the device via TDI/VPP and
    shift results out of the device via TDO. 
*/
long long total_time_ir= 0L;
long long total_time_dr=0L;
LONG WINAPI HIL_JTAG_IR(LONG instruction)
{
    WORD i;
    int tdo;
    int tclk;
    LARGE_INTEGER _ts, _te;
    QueryPerformanceCounter(&_ts);
    tclk = portData & TCLK; // Preserve TCLK (pin shared with TDI).

    // Jtag state machine: Run Test Idle.
    SetTMS();
    // JTAG FSM state = Select DR Scan
    ClkTCK();
    // JTAG FSM state = Select IR Scan
    ClkTCK();
    
    ClrTMS();
    // JTAG FSM state = Capture IR
    ClkTCK();
    // JTAG FSM state = Shift IR
    ClkTCK();
    
    tdo = 0;
    markbuf[markbufpos++]=outbufpos;
    HIL_Log(2,"JTAG_IR Mark: %d\n",outbufpos);
    for (i = 0;  i < INSTRUCTION_LEN;  i++) // Shift in instruction on TDI (LSB first).
    {
        // Normally shift-in the instruction using TDI. However, while securing a device which takes Vpp via the
        // TDI/VPP pin, shift-in the instruction using TDO. There is no value shifted out of TDO at that time.
        if ((instruction & 1))
        {
            if (useTDI)
                SetTDI();
            else
                SetTDO();
        }
        else
        {
            if (useTDI)
                ClrTDI();
            else
                ClrTDO();
        }
        instruction >>= 1;
        if (i == INSTRUCTION_LEN - 1)
            SetTMS(); // Prepare to exit state.
        ClkTCK();

        // Capture TDO. Expect JTAG version (unless shift-in is using TDO).
        tdo <<= 1;
        if (useTDI  &&  ReadTDO())
            tdo |= 1;
    }
    RestoreTCLK(tclk);
    PrepTCLK();         // Set JTAG FSM back into Run-Test/Idle
    SetTMS();           // Set TMS to default state (minimize power
			// consumption).
    QueryPerformanceCounter(&_te);
    total_time_ir += (_te.QuadPart - _ts.QuadPart);
    return tdo;
}

/* ----------------------------------------------------------------------------
Function:
 LONG WINAPI HIL_TEST_VPP(LONG mode);

Description:
 Set the operational mode of HIL_JTAG_IR().

Parameters:
 mode: FALSE: JTAG instructions are shifted into the device via TDO. No results are shifted out.
              During secure operations, Vpp is applied on TDI/VPP.
       TRUE:  JTAG instructions are shifted into the device via TDI/VPP and results are shifted out
              via TDO. During secure operations, Vpp is applied on TEST.

Returns:
 The previous mode (FALSE: TDO, TRUE: TDI/VPP).

Notes:
 1. This function operates in conjunction with HIL_JTAG_IR() and HIL_VPP().
 2. Since the FET Interface Module does not support routing the shift-in bit stream to TDO, this
    function has no significant effect (other than setting the associated file global variable).
*/
LONG WINAPI HIL_TEST_VPP(LONG mode)
{
    LONG oldMode = (LONG) useTDI;

    useTDI = (char) mode;
    return (oldMode);
}

/* ----------------------------------------------------------------------------
Function:
 LONG WINAPI HIL_JTAG_DR(LONG data, LONG bits);

Description:
 The specified JTAG data is shifted into the device.

Parameters:
 data: The JTAG data to be shifted into the device.
 bits: The number of JTAG data bits to be shifted into the device (8 or 16).

Returns:
 "bits" bits shifted out from the device (on TDO).

Notes:
 1. The byte or word data is passed as a LONG.
 2. The byte or word result is returned as a LONG.
*/
LONG WINAPI HIL_JTAG_DR(LONG data, LONG bits)
{
    WORD tdo;
    DWORD read[BITS_LEN];
    int i;
    int tclk;
    LARGE_INTEGER _ts, _te;
    QueryPerformanceCounter(&_ts);

    tclk = portData & TCLK; // Preserve TCLK (pin shared with TDI).
    tdo = 0;
    bits = (bits > BITS_LEN)  ?  BITS_LEN  :  bits; // Limit the number of bits supported.

    /* Jtag state machine: Run Test Idle. */
    SetTMS();
    ClkTCK(); /* Jtag state machine: Select DR Scan. */
    ClrTMS();
    ClkTCK(); /* Jtag state machine: Capture DR. */
    ClkTCK(); /* Jtag state machine: Shift DR. */
    markbuf[markbufpos++] = outbufpos;
    HIL_Log(2, "JTAG_DR Mark: %d\n",outbufpos);
    for (i = bits - 1;  i >= 0;  i--) // Shift in data on TDI (MSB first).
    {
        if ((data & (1 << i)))
            SetTDI();
        else
            ClrTDI();
        if (i == 0)
            SetTMS(); // Prepare to exit state.
        ClkTCK();

        /* Capture data on TDO. */
        read[bits - 1 - i] = ReadTDO();
    }
    RestoreTCLK(tclk);
    // Jtag state machine: Exit 1 DR.
    ClkTCK(); // Jtag state machine: Update DR.
    ClrTMS();
    ClkTCK(); // Jtag state machine: Run Test Idle.
    SetTMS(); // Set TMS to default state (minimize power consumption).

    for (i = tdo = 0;  i < bits;  i++)
        tdo = (tdo << 1) | ((read[i] & TDO) == TDO);

    QueryPerformanceCounter(&_te);
    total_time_ir += (_te.QuadPart - _ts.QuadPart);
    return (tdo);
}

/* ----------------------------------------------------------------------------
Function:
 STATUS_T WINAPI HIL_VCC(LONG voltage);

Description:
 Set the device Vcc pin to voltage/1000 volts.

Parameters:
 voltage: The device Vcc pin is set to voltage/1000 volts.

Returns:
 STATUS_OK:    The Vcc was set to voltage.
 STATUS_ERROR: The Vcc was not set to voltage.

Notes:
 1. This function is dependant upon the interface hardware. The FET interface module does not
    support this functionality.
 2. A "voltage" of zero (0) turns off voltage to the device.
 3. If the interface hardware does not support setting the device voltage to a specific value,
    a non-zero value should cause the device voltage to be set to a value within the device
    Vcc specification (i.e., a default Vcc). Insure that the default Vcc voltage supports FLASH
    operations.
 4. Insure that Vcc is stable before returning from this function.
*/
STATUS_T WINAPI HIL_VCC(LONG voltage)
{
    //method is unsupported with my USB interface -- RS
#if 0
    if (voltage)
    {
        // Power on
        portData |= PWR; // Apply power to the regulator.
        outdata(fd,portData);
        portData |= VCC; // Enable the regulator.
        outdata(fd,portData);
    }
    else
    {
        // Power off
        portData &= ~(VCC | PWR);
        outdata(fd,portData);
    }

    HIL_DelayMSec(10); // Delay 10mSec to give the device time to power-up.
#endif
    return (STATUS_OK);
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_TST(LONG state);

Description:
 Set the state of the device TST pin.

Parameters:
 state: The device TST pin is set to state (0/1).

Returns:

Notes:
 1. Not all MSP430 devices have a TST pin.
*/
void WINAPI HIL_TST(LONG state)
{
    HIL_DelayMSec(10);           //for slow hardware
    if (state)
        portCtrl |= TST;
    else
        portCtrl &= ~TST;
    //    ioctl(fd, PPWCONTROL, &portCtrl);
    HIL_DelayMSec(10);          //for slow hardware
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_TCK(LONG state);

Description:
 Set the state of the device TCK pin.

Parameters:
 state: The device TCLK pin is set to state (0/1/POS_EDGE (0->1)/NEG_EDGE (1->0)).

Returns:

Notes:
*/
void WINAPI HIL_TCK(LONG state)
{
    switch (state)
    {
    case 0:
        portData &= ~TCK;
        outdata(fd,portData);
        outdata(fd,portData);
        break;
    case POS_EDGE:
        portData &= ~TCK;
        outdata(fd,portData);
        portData |=  TCK;
        outdata(fd,portData);
        break;
    case NEG_EDGE: 
        portData |=  TCK;
        outdata(fd,portData);
        portData &= ~TCK;
        outdata(fd,portData);
        break;
    default:
        portData |=  TCK;
        outdata(fd,portData);
        break;
    }
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_TMS(LONG state);

Description:
 Set the state of the device TMS pin.

Parameters:
 state: The device TMS pin is set to state (0/1).

Returns:

Notes:
*/
void WINAPI HIL_TMS(LONG state)
{
    if (state)
        portData |= TMS;
    else
        portData &= ~TMS;
    outdata(fd,portData);
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_TDI(LONG state);

Description:
 Set the state of the device TDI pin.

Parameters:
 state: The device TDI pin is set to state (0/1).

Returns:

Notes:
*/
void WINAPI HIL_TDI(LONG state)
{
    if (state)
        portData |= TDI;
    else
        portData &= ~TDI;
    outdata(fd,portData);
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_TDO(LONG state);

Description:
 Set the state of the device TDO pin.

Parameters:
 state: The device TDO pin is set to state (0/1).

Returns:

Notes:
*/
void WINAPI HIL_TDO(LONG state)
{
    if (state)
        portData |= TDO;
    else
        portData &= ~TDO;
    outdata(fd,portData);
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_TCLK(LONG state);

Description:
 Set the state of the device TCLK pin.

Parameters:
 state: The device TCLK pin is set to state (0/1/POS_EDGE (0->1)/NEG_EDGE (1->0)).

Returns:

Notes:
*/
void WINAPI HIL_TCLK(LONG state)
{
    switch (state)
    {
	case 0:
	    portData &= ~TCLK;
	    outdata(fd,portData);
	    break;
	case POS_EDGE:
	    portData &= ~TCLK;
	    outdata(fd,portData);
	    portData |=  TCLK;
	    outdata(fd,portData);
	    break;
	case NEG_EDGE:
	    portData |=  TCLK;
	    outdata(fd,portData);
	    portData &= ~TCLK;
	    outdata(fd,portData);
	    break;
	default:
	    portData |=  TCLK;
	    outdata(fd,portData);
	    break;
    }
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_RST(LONG state);

Description:
 Set the state of the device RST pin.

Parameters:
 state: The device RST pin is set to state (0/1).

Returns:

Notes:
*/
void WINAPI HIL_RST(LONG state)
{

    if (state) { //RESET high, disconnect and rely on the pullups
	if (swState & CTRL_RST) { // reset is closed, need to to pull it up.
	    swState |= CTRL_TCK; //connect TCK
	    swState &= ~CTRL_RST; // disconnect (i.e. pullup) reset
	    I2CWriteCmd(0, swState);
	} //else the RST is already disconnected; do nothing
    } else {
	if ((swState & CTRL_RST) == 0) {
	    swState &= ~CTRL_TCK; //disconnect TCK, even though it will be too late 
	    swState |= CTRL_RST; // pull down the reset line 
	    I2CWriteCmd(0, swState);
	}
    }
    if (state)
        HIL_DelayMSec(DEFAULT_RSTDELAY);
}

/* ----------------------------------------------------------------------------
Function:
 STATUS_T WINAPI HIL_VPP(LONG voltage);

Description:
 Set the device Vpp pin to voltage/1000 volts.

Parameters:
 voltage: The device Vpp pin is set to voltage/1000 volts.

Returns:
 STATUS_OK:    The Vpp was set to voltage.
 STATUS_ERROR: The Vpp was not set to voltage.

Notes:
 1. This function is dependant upon the interface hardware. The FET interface module does not
    support this functionality.
 2. A "voltage" of zero (0) turns off Vpp voltage to the device.
 3. If the interface hardware does not support setting the device Vpp voltage to a specific value,
    a non-zero value should cause the device Vpp voltage to be set to a value within the device
    Vpp specification (i.e., a default Vpp). Insure that the default Vpp voltage supports FLASH
    operations.
 4. The parameter to HIL_TEST_VPP() can be used to determine if VPP is applied to TDI/VPP (FALSE)
    or to TEST/VPP (TRUE).
 5. Insure that Vpp is stable before returning from this function.
*/
STATUS_T WINAPI HIL_VPP(LONG voltage)
{
    /* TODO: not implemented on the parallel port JTAG device */
    return (STATUS_OK);
}

// Time delay and timer functions ---------------------------------------------

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_DelayMSec(LONG mSeconds);

Description:
 Delay for mSeconds milliseconds.

Parameters:
 mSeconds: The delay time (milliseconds).

Returns:

Notes:
 1. The precision of this delay function does not have to be high; "approximate" milliseconds delay is
    sufficient. Rather, the length of the delay needs to be determined precisely. The length of the delay
    is determined precisely by computing the difference of a timer value read before the delay and the
    timer value read after the delay.
*/
void WINAPI HIL_DelayMSec(LONG mSeconds)
{
#if 0
#if defined(HIL_PPDEV)  ||  defined(HIL_DIRECTIO)
    usleep(mSeconds*1000);
#else
    clock_t goal;
    for (goal = clock() + mSeconds;  clock() < goal;  )
        __asm__ volatile(" ");
#endif
#endif
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_StartTimer(void);

Description:
 Start the (precision) timer.

Parameters:

Returns:

Notes:
 The timer should have a resolution of at least one millisecond.
*/
void WINAPI HIL_StartTimer(void)
{
#if 0 
#if defined(HIL_PPDEV)  ||  defined(HIL_DIRECTIO)
    gettimeofday(&_tstart, &tz);
#else
    QueryPerformanceCounter(&_tstart);
#endif
#endif
}

/* ----------------------------------------------------------------------------
Function:
 ULONG WINAPI HIL_ReadTimer(void);

Description:
 Read the (precision) timer.

Parameters:

Returns:
 The value of the timer.

Notes:
 The timer should have a resolution of at least one millisecond.
*/
ULONG WINAPI HIL_ReadTimer(void)
{
#if 0
#if defined(HIL_PPDEV)  ||  defined(HIL_DIRECTIO)
    long long t1;
    long long t2;

    gettimeofday(&_tend, &tz);
    t1 = ((long long) _tstart.tv_sec)*1000 + _tstart.tv_usec/1000;
    t2 = ((long long) _tend.tv_sec)*1000 + _tend.tv_usec/1000;
    return t2 - t1;
#else
    QueryPerformanceCounter(&_tend);
    return (1000*(_tend.QuadPart - _tstart.QuadPart))/(freq.QuadPart);
#endif
#else
    return 0;
#endif
}

/* ----------------------------------------------------------------------------
Function:
 void WINAPI HIL_StopTimer(void);

Description:
 Stop the (precision) timer.

Parameters:

Returns:

Notes:
*/
void WINAPI HIL_StopTimer(void)
{
    //nop
}

// HIL local support functions. -----------------------------------------------

/* Parallel port status register functions. */
static BYTE ReadTDI(void)
{
    BYTE ret;
#if 0
#if defined(HIL_PPDEV)
    ioctl(fd, PPRSTATUS, &ret);
#else
    ret = in_byte(port_base + STATOFF);
#endif
#endif
    return ret & TDI;
}

/* Parallel port status register functions. */
static BYTE ReadTDO(void)
{
    BYTE ret;
#if 0 
#if defined(HIL_PPDEV)
    ioctl(fd, PPRSTATUS, &ret);
#else
    ret = in_byte(port_base + STATOFF);
#endif
#endif

    return ret & TDO;
}

LONG WINAPI HIL_ReadTDO(void) {
    return ReadTDO() != 0;      //return a boolean
}


//----------------------------------------------------------------------------
/* This function sets the target JTAG state machine (JTAG FSM) back into the 
   Run-Test/Idle state after a shift access.
*/
static void PrepTCLK(void)
{
    // JTAG FSM = Exit-DR
    ClkTCK();
    // JTAG FSM = Update-DR
    ClrTMS();
    ClkTCK();
    // JTAG FSM = Run-Test/Idle
}


void debug_signal(int n, unsigned char *buf) {
    char buf_TMS[85];
    char buf_TDI[85];
    char buf_TCK[85];
    char buf_TDO[85];
    int i = 4;
    int j=0;
    // need the debug level to be at least 3 or more to produce the signals
    if (debug_level < 3) 
	return;
    strcpy(buf_TMS, "TMS:");
    strcpy(buf_TDI, "TDI:");
    strcpy(buf_TCK, "TCK:");
    strcpy(buf_TDO, "TDO:");
    while (n>0) { 
	if (buf[j] & TMS) 
	    buf_TMS[i] = '-';
	else 
	    buf_TMS[i] = '_';


	if (buf[j] & TDI) 
	    buf_TDI[i] = '-';
	else 
	    buf_TDI[i] = '_';


	if (buf[j] & TCK) 
	    buf_TCK[i] = '-';
	else 
	    buf_TCK[i] = '_';


	if (buf[j] & TDO) 
	    buf_TDO[i] = '-';
	else 
	    buf_TDO[i] = '_';	

	i++; n--;j++;
	if ((i>78) &&  (n > 0)) {
	    buf_TMS[i] = '\n';
	    buf_TDI[i] = '\n';
	    buf_TCK[i] = '\n';
	    buf_TDO[i] = '\n';
	    i++;
	    buf_TMS[i] = 0;
	    buf_TDI[i] = 0;
	    buf_TCK[i] = 0;
	    buf_TDO[i] = 0;
	    HIL_Log(3,buf_TMS);
	    HIL_Log(3,buf_TDI);
	    HIL_Log(3,buf_TCK);
	    HIL_Log(3,buf_TDO);
	    HIL_Log(3,"\n");
	    i=4;
	}
    }
	    buf_TMS[i] = '\n';
	    buf_TDI[i] = '\n';
	    buf_TCK[i] = '\n';
	    buf_TDO[i] = '\n';
	    i++;
	    buf_TMS[i] = 0;
	    buf_TDI[i] = 0;
	    buf_TCK[i] = 0;
	    buf_TDO[i] = 0;
	    HIL_Log(3,buf_TMS);
	    HIL_Log(3,buf_TDI);
	    HIL_Log(3,buf_TCK);
	    HIL_Log(3,buf_TDO);	
}
void *memmem
     (const void *haystack, size_t haystack_len, const void *needle, size_t needle_len)
{
    const char *begin;
    const char *const last_possible
        = (const char *) haystack + haystack_len - needle_len;

    if (needle_len == 0)
        /* The first occurrence of the empty string is deemed to occur at
           the beginning of the string.  */
        return (void *) haystack;

    /* Sanity check, otherwise the loop might search through the whole
       memory.  */
    if (__builtin_expect(haystack_len < needle_len, 0))
        return NULL;

    for (begin = (const char *) haystack; begin <= last_possible; ++begin)
        if (begin[0] == ((const char *) needle)[0] &&
            !memcmp((const void *) &begin[1],
                    (const void *) ((const char *) needle + 1),
                    needle_len - 1))
            return (void *) begin;

    return NULL;
}

// The purpose of this function is to resynchronize the write and read
// buffers. We will be re-synchronizing using a short sequence (XX bytes) from
// the first marker
#define SIGNATURE_LENGTH 16
void debug_sync();
long long total_time_sent= 0L;
long long total_time_read=0L;
STATUS_T WINAPI HIL_Resync() {
    unsigned char buf[USB_BUF_SIZE];
    unsigned char buf1[USB_BUF_SIZE+SIGNATURE_LENGTH];
    unsigned char *marker;
    unsigned char *bufptr;
    DWORD numRead, rxq, txq, sq;
    LARGE_INTEGER _tstart1 , _twrite, _tend, freq, _tbeg;
    long long _tw, _tr;
    int i; // general counter 
    int j; // counter for total bytes read
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&_tend); 
    _tw = ((1000L * (((long long) _tend.QuadPart) - 
		     ((long long) _tstart.QuadPart)) /
	    ((long long) freq.QuadPart)));
    HIL_Log(1, "HIL_Resync: begin  elapsed time since start of the program %ld\n",
	    _tw);
    memset(buf1, 0, USB_BUF_SIZE+SIGNATURE_LENGTH);
    marker = &(outbuf[markbuf[0]]);
    //    printf("Searching for a signature:\n");
    // debug_signal(SIGNATURE_LENGTH, marker);
    j = outbufpos;
    //    FT_Purge(fd, FT_PURGE_RX);
    //
    //we don't expect that any data valid was read in before we invoked the
    //write; issue the read since it is much faster than the purge
    FT_GetStatus(fd, &rxq, &txq, &sq);
    FT_Read(fd, buf, rxq, &numRead);
    memset(buf, 0, USB_BUF_SIZE);
    QueryPerformanceCounter(&_tstart1);
    HIL_Log(2, "HIL Resync:  at the start RX %d, TX %d, status %d\n", rxq, txq, sq); 
    _tw = ((1000L * (((long long) _tstart1.QuadPart) - 
		     ((long long) _tend.QuadPart)) /
	    ((long long) freq.QuadPart)));
    HIL_Log(1, "HIL_Resync: startup and purge took %d ms\n", _tw);
    while (j > 0) {
	FT_Write(fd, outbuf, outbufpos, &numRead);
	HIL_Log(1,"HIL_Resync: Written %d bytes\n", numRead);
	j-= numRead;
    }
    QueryPerformanceCounter(&_twrite);
    FT_GetStatus(fd, &rxq, &txq, &sq);
    HIL_Log(2, "HIL Resync:  after write RX %d, TX %d, status %d\n", rxq, txq, sq); 
    // Snarf the initial chunk of data
    
    FT_Read(fd, buf, outbufpos, &numRead);
    HIL_Log(2, "Initial call, read %d\n", numRead);
    //TODO: Check if there is a need to flush the incoming read queues.  
    if (markbufpos == 0) // there are no markers, it's OK to return. 
	return STATUS_OK;

    for (i=0; i< SIGNATURE_LENGTH; i++) {
	buf1[i] = 0;
    }
    
    for (i=0; i< numRead; i++) {
	buf1[i+SIGNATURE_LENGTH] = buf[i] & (TDI | TMS|TCK|SDA|SCL);
    }
    j=numRead;
    bufptr = memmem(buf1, numRead+SIGNATURE_LENGTH, marker, SIGNATURE_LENGTH);
    while ((bufptr == NULL) && (j < 65536*2)) {
	// copy the last few data points
	for (i=0; i< SIGNATURE_LENGTH; i++) {
	    buf1[i] = buf[numRead - SIGNATURE_LENGTH + i] & (TDI | TMS|TCK|SDA|SCL);
	}
	FT_Read(fd, buf, USB_BUF_SIZE, &numRead);
	HIL_Log(3, "searching for start, read an additional %d bytes\n", numRead);
	j+=numRead;
	HIL_Log(3, "We're up to %d bytes now\n", j);
	// copy the signal after the previous chunk
	for (i=0; i< numRead; i++) {
	    buf1[i+SIGNATURE_LENGTH] = (buf[i] & (TDI | TMS|TCK|SDA|SCL));
	}
	bufptr = memmem(buf1, numRead+SIGNATURE_LENGTH, marker, SIGNATURE_LENGTH);
    }
    if (bufptr == NULL) {
	HIL_Log(1,"JTAG syncronization failed after writing %d and reading %d bytes\n", outbufpos, j);
	return STATUS_ERROR;
    }
    QueryPerformanceCounter(&_tend);
    _tw = ((1000L*(((long long)_twrite.QuadPart) - 
		   ((long long)_tstart1.QuadPart)) / 
	    ((long long)freq.QuadPart)));
    total_time_sent+=_tw;
    _tr = ((1000L*(((long long)_tend.QuadPart) - 
		   ((long long)_twrite.QuadPart))) / 
	   ((long long)freq.QuadPart));
    total_time_read+=_tr;
    HIL_Log(1, "Time spent writting: %ld\n", _tw);
    HIL_Log(1, "Time spent reading:  %ld\n", _tr);
    HIL_Log(1, "Time spent totalwritting: %ld\n", total_time_sent);
    HIL_Log(1, "Time spent totalreading:  %ld\n", total_time_read);
    

    HIL_Log(1,"HIL_Resync: found signiture after reading %d bytes, at offset %d\n", j, bufptr-buf1);
    memcpy(inbuf, &(buf[bufptr-buf1-SIGNATURE_LENGTH]), numRead-(bufptr-buf1-SIGNATURE_LENGTH));
    inbufpos = numRead-(bufptr-buf1-SIGNATURE_LENGTH);
    HIL_Log(1, "Read %d bytes\n", inbufpos);
    while (inbufpos < (outbufpos-markbuf[0])) {
	FT_Read(fd, &(inbuf[inbufpos]), (outbufpos-markbuf[0])-inbufpos, & numRead);
	HIL_Log(1,"Read additional %d bytes, in pos %d\n", numRead, inbufpos+numRead);
	inbufpos+=numRead;
    }
    //    debug_signal(70, inbuf);
    //debug_sync();
    //    QueryPerformanceCounter(&_tend); 
    _tw = ((1000L * (((long long) _twrite.QuadPart) - 
		     ((long long) _tstart.QuadPart)) /
	    ((long long) freq.QuadPart)));
    HIL_Log(1, "HIL_Resync: end  elapsed time since start of the program %ld\n",
	    _tw);
    return STATUS_OK;
}


LONG  HIL_ReadMarker_wtdi(LONG marker, LONG bits) {
    LONG tdo = 0;
    int lidx;
    int i;
    int j;
    lidx = markbuf[marker];
    // printf("Last word location at offset %d\n", lidx);
    //    debug_signal(40, &(outbuf[lidx]));
    i=0;
    tdo=0;
    while(outbuf[lidx++] & TCK); //wait for the falling edge
    while((lidx < outbufpos) && (i < bits)) {
	while ((lidx < outbufpos) && ((outbuf[lidx++] & TCK)==0));//search for the rising edge
	tdo<<=1;
	if (outbuf[lidx] & TDI) {
	    tdo |= 1;
	}
	i++; 
	while ((lidx < outbufpos) && (outbuf[lidx++] & TCK)); //wait for the falling edge
	//	printf("i %d \n", lidx);
    }
    if (lidx >= outbufpos) {
	HIL_Log(1,"Not enough rising edges.  Corrupt signal?\n");	
	HIL_Log(1,"INBUF pos: %d, OUTBUFPOS %d, Marker 0 %d\n", inbufpos, outbufpos, markbuf[0]);
	HIL_Log(1,"Not enough rising edges.  Corrupt signal? Read signal:\n");
	debug_signal(inbufpos, inbuf);
	HIL_Log(1, "\n\nCompared with the written signal:\n\n"); 
	j = inbufpos;
	if ((outbufpos- markbuf[0]) < j) 
	    j = outbufpos- markbuf[0];
	for (i = 0; i < j; i++) {
	    tmpbuf[i] = inbuf[i] ^ outbuf[i+markbuf[0]];
	}
	debug_signal(j, tmpbuf);
    } 
    return tdo;
}
LONG HIL_ReadMarker_rtdi(LONG marker, LONG bits) {
    LONG tdo = 0;
    int lidx;
    int i;

    lidx = markbuf[marker]-markbuf[0];
    // printf("Last word location at offset %d\n", lidx);
    //    debug_signal(40, &(inbuf[lidx]));
    i=0;
    tdo=0;
    while(inbuf[lidx++] & TCK); //wait for the falling edge
    while((lidx < inbufpos) && (i < bits)) {
	while ((lidx < inbufpos) && ((inbuf[lidx++] & TCK)==0));//search for the rising edge
	tdo<<=1;
	if (inbuf[lidx] & TDI) {
	    tdo |= 1;
	}
	i++; 
	while ((lidx < inbufpos) && (inbuf[lidx++] & TCK)); //wait for the falling edge
	//	printf("i %d \n", lidx);
    }
    if (lidx >= inbufpos) {
	HIL_Log(1,"Not enough rising edges.  Corrupt signal?");
    } 
#if 0
    if (bits == 8) 
	HIL_Log(1,"0x%02x\n", tdo);
    else 
	HIL_Log(1,"0x%04x\n",tdo);
#endif
    return tdo;
}

void debug_sync() {
    int i;
    int wi, ri, ro;
    int n,m,next_marker;
    HIL_Log(4, "W_TDI \tR_TDI \tR_TDO\n");
    for (i=0; i < markbufpos; i++) {
	if ((i+1) == markbufpos) {
	    next_marker = outbufpos;
	} else {
	    next_marker = markbuf[i+1];
	}
	if ((next_marker - markbuf[i]) <75) {
	    wi = 		HIL_ReadMarker_wtdi(i, F_BYTE);
	    ri = 		HIL_ReadMarker_rtdi(i, F_BYTE);
	    ro = 		HIL_ReadMarker(i, F_BYTE);
	} else {
	    wi = 		HIL_ReadMarker_wtdi(i, F_WORD);
	    ri = 		HIL_ReadMarker_rtdi(i, F_WORD);
	    ro = 		HIL_ReadMarker(i, F_WORD);
	}
	HIL_Log(4, "0x%04x  0x%04x  0x%04x\n", 	wi,ri,	ro);
#if 0
	if (wi != ri ) {
	    HIL_Log(1, "Received signal\n");
	    debug_signal(outbufpos-markbuf[0], inbuf);
	    HIL_Log(1, "Original signal\n");
	    debug_signal(outbufpos-markbuf[0], outbuf+markbuf[0]);
	    HIL_Log(1, "\n\nCompared with the written signal:\n\n"); 
	    m = inbufpos;
	    if ((outbufpos- markbuf[0]) < m) 
		m = outbufpos- markbuf[0];
	    for (n = 0; n < m; n++) {
		tmpbuf[n] = inbuf[n] ^ outbuf[n+markbuf[0]];
	    }
	    debug_signal(m, tmpbuf);
	}
#endif
    }
}
LONG WINAPI HIL_ReadMarker(LONG marker, LONG bits) {
    LONG tdo = 0;
    int lidx;
    int i;
    int j;
    lidx = markbuf[marker]-markbuf[0];
    // printf("Last word location at offset %d\n", lidx);
    //    debug_signal(40, &(inbuf[lidx]));
    i=0;
    tdo=0;
    while(inbuf[lidx++] & TCK); //wait for the falling edge
    while((lidx < inbufpos) && (i < bits)) {
	while ((lidx < inbufpos) && ((inbuf[lidx++] & TCK)==0));//search for the rising edge
	tdo<<=1;
	if (inbuf[lidx] & TDO) {
	    tdo |= 1;
	}
	i++; 
	while ((lidx < inbufpos) && (inbuf[lidx++] & TCK)); //wait for the falling edge
	//	printf("i %d \n", lidx);
    }
    if (lidx >= inbufpos) {
	HIL_Log(1,"Not enough rising edges.  Corrupt signal? Read signal:\n");
#if 0 
       	debug_signal(inbufpos, inbuf);
	HIL_Log(1, "\n\nCompared with the written signal:\n\n"); 
	j = inbufpos;
	if ((outbufpos- markbuf[0]) < j) 
	    j = outbufpos- markbuf[0];
	for (i = 0; i < j; i++) {
	    tmpbuf[i] = inbuf[i] ^ outbuf[i+markbuf[0]];
	}
	debug_signal(j, tmpbuf);
#endif	
    }
#if 0    
    if (bits == 8) 
	HIL_Log(1,"0x%02x\n", tdo);
    else 
	HIL_Log(1,"0x%04x\n",tdo);
#endif
    return tdo;
}

void WINAPI HIL_Flush() {
    //should this function also flush the queues in the FTDI device???
    HIL_Log(1,"HIL_Flush\n");
    markbufpos = 0;
    outbufpos = 0;
    inbufpos = 0;
    memset(inbuf, 0, INBUF_SIZE);
}

LONG WINAPI getLastValue(int bits) {
    int retval;
    if (HIL_Resync() == STATUS_OK) {
	retval = HIL_ReadMarker(markbufpos-1, bits);
	HIL_Log(1,"getLastValue: lastValue 0x%04x\n", retval&((1<<bits)-1));
    } 
    HIL_Flush();
    return retval;
}

WORD WINAPI checkMacro(int stackPosition, int bits, int expected) {
    int mask;
    if (bits == F_WORD) 
	mask = 0xffff;
    else 
	mask = 0xff;
    if (HIL_Resync() == STATUS_OK) {
	if ((HIL_ReadMarker(markbufpos-stackPosition, bits) & mask) == (expected&mask)) {
	    HIL_Flush();
	    return STATUS_OK;
	} else {
	    return STATUS_ERROR;
	}
    } else {
	return STATUS_ERROR;
    }
}


int WINAPI HIL_GetMarker() {
    return markbufpos-1;
}
