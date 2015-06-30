//  $Id: MSP430mspgcc.c,v 1.1 2004/12/03 23:55:11 szewczyk Exp $
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
  added a few minor tweaks to interface witht he Telos revB USB library.  
  modified the Memory Read to use MemReadQuick to avoid latency for every byte
  added calls to HIL_Resync and HIL_Flush as appropriate

  @author Chris Liechti <cliechti@gmx.net>
 
  Please see LICENSE.txt in the current directory.  
  
*/
// MSP430 DLL.
//
// This file contains the DLL functions.

// #includes. -----------------------------------------------------------------

#include <stdlib.h>
#include <string.h>

#include "defs.h"
#include "HIL.h"
#include "MSP430mspgcc.h"
#include "JTAGfunc.h"
#include "funclets.h"

// #defines. ------------------------------------------------------------------

#define DLL_VERSION         03      // DLL version * 10.

// (File) Global variables. ---------------------------------------------------
static BOOL jtagReleased = FALSE;
unsigned int debug_level = 0;

static const char* errorStrings[] = {
    "No error",
    "Could not initialize device interface",
    "Could not close device interface",
    "Invalid parameter(s)",
    "Could not find device (or device not supported)",
    "Unknown device",
    "Could not read device memory",
    "Could not write device memory",
    "Could not set device Vcc",
    "Could not reset device",
    "Could not set device operating frequency",
    "Could not erase device memory",
    "Could not run device",
    "Verification error",
    "Invalid error number",
};

// Global variables. ----------------------------------------------------------

int errorNumber = NO_ERR;       // Error number.
BOOL executeVerify = FALSE;     // Verify the stub code downloaded by executeCode().

// Functions. -----------------------------------------------------------------

/* ----------------------------------------------------------------------------
Initialize the interface.

Parameters:
 port:    Interface port reference (application specific).
 version: The version number of the MSP430 DLL is returned.

Returns:
 STATUS_OK:    The interface was initialized.
 STATUS_ERROR: The interface was not initialized.

Error codes:
 INITIALIZE_ERR

Notes:
 1. *** This function must be called first. ***
*/
STATUS_T WINAPI MSP430_Initialize(CHAR const * port, LONG* version) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_Initialize...\n");
    if (version) {
        *version = DLL_VERSION;
    }

    if (HIL_Initialize(port) != STATUS_OK) {
        RET_ERR(INITIALIZE_ERR);
    }
    // Just to be on the safe side, make sure the commands are flushed to the
    // device, and the queues are reinitialized
    HIL_Resync();
    HIL_Flush();
    RET_OK;
}

/* ----------------------------------------------------------------------------
Close the interface.

Parameters:
 vccOff: Turn off the device Vcc (0 volts) if TRUE.

Returns:
 STATUS_OK:    The interface was closed.
 STATUS_ERROR: The interface was not closed.

Error codes:
 CLOSE_ERR

Notes:
 1. If called, this function must be called last.
 2. This function calls user-supplied function: HIL_Close()
*/
STATUS_T WINAPI MSP430_Close(LONG vccOff) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_Close...\n");
    if (HIL_Close(vccOff) != STATUS_OK) {
        RET_ERR(CLOSE_ERR);
    }
    RET_OK;
}

/* ----------------------------------------------------------------------------
Configure the mode(s) of the device and/or the software.
currently supported options:
    VERIFICATION_MODE: enable verify of data downloaded into the device FLASH.

Parameters:
 mode:     The mode to be configured.
 value:    The mode value.

Returns:
 STATUS_OK:    The mode was configured.
 STATUS_ERROR: The mode was not configured.

Error codes:
 PARAMETER_ERR
*/
STATUS_T WINAPI MSP430_Configure(LONG mode, LONG value) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_Configure(0x%x, 0x%x)\n", mode, value);
    switch (mode) {
        case VERIFICATION_MODE:
            executeVerify = (BOOL) value;
            break;
        case RAMSIZE_OPTION:
            ramsize = value;
            MSP430_Log(1, "MSP430mspgcc: Changing RAMSIZE to %d\n", ramsize);
            break;
        case DEBUG_OPTION:
            debug_level = value;
            MSP430_Log(1, "MSP430mspgcc: Debug level set to %d\n", value);
            break;
        case FLASH_CALLBACK:
            flash_callback = (void *)value;
            MSP430_Log(1, "MSP430mspgcc: Set Flash progress Callback\n");
            break;
        default:
            RET_ERR(PARAMETER_ERR);
            //~ break;
    }
    RET_OK;
}

/* ----------------------------------------------------------------------------
Set the device Vcc pin to voltage/1000 volts.
A "voltage" of zero (0) turns off voltage to the device.
!! The FET interface does not support setting the voltage.
!! for nonzero values the power on the FET kits is enabled,
!! disables otherwise.

!! For Telos over USB, this function has no meaning.  

Parameters:
 voltage: The device Vcc pin is set to voltage/1000 volts.

Returns:
 STATUS_OK:    The Vcc was set
 STATUS_ERROR: The Vcc was not set

Error codes:
 PARAMETER_ERR
 VCC_ERR
*/
STATUS_T WINAPI MSP430_VCC(LONG voltage) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_VCC...\n");
#define MAX_VCC_Limit 3600
    if ((voltage < 0) || (voltage > MAX_VCC_Limit)) {
        RET_ERR(PARAMETER_ERR);
    }

    if (HIL_VCC(voltage) != STATUS_OK) {
        RET_ERR(VCC_ERR);
    }
    RET_OK;
}

/* ----------------------------------------------------------------------------
Initialize JTAG and reset device. This function has to be called before any other
function acessing the device can work.

Returns:
 STATUS_OK:    JTAG is connected and the device was reset.
 STATUS_ERROR: No connection or device not found.

Error codes:
 NO_DEVICE_ERR
 RESET_ERR
*/
STATUS_T WINAPI MSP430_Open(void) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_Open...\n");
    if (HIL_Open() == STATUS_OK) {      // Enable the JTAG interface to the device.
        return MSP430_Reset(RST_RESET|VCC_RESET, FALSE, FALSE); //needs a reset method with GetDevice
    } else {
        RET_ERR(NO_DEVICE_ERR);
    }
}


/* ----------------------------------------------------------------------------
Reset the device using the specified method(s). Optionally start device execution,
and release the JTAG control signals.

Parameters:
 method:      The bit mask specifying the method(s) to use to reset the device:
                PUC:     The device is reset using PUC (i.e., a "soft" reset).
                RST_NMI: The device is reset using the RST/NMI pin (i.e., a "hard" reset).
                VCC:     The device is reset by cycling power to the device.
 execute:     Start device execution (when TRUE).
 releaseJTAG: Release the JTAG control signals (when TRUE). execute must be TRUE.

Returns:
 STATUS_OK:    The device was reset (and optionally started [and JTAG control released])
 STATUS_ERROR: The device was not reset (and optionally started [and JTAG control released]).

Error codes:
 PARAMETER_ERR
 RESET_ERR
 RUN_ERR

Notes:
 1. It is possible to combine reset methods. The methods are applied in the following order:
    PUC then RST_NMI then VCC. If a reset operation fails, the next reset method (if any) is applied.
 2. Following reset by RST/NMI and/or VCC, a PUC is automatically executed to reset the device in
    such a way that it does not begin to execute a resident program (or garbage).
*/
STATUS_T WINAPI MSP430_Reset(LONG method, LONG execute, LONG releaseJTAG) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_Reset...\n");
    if (!method) {
        RET_ERR(PARAMETER_ERR);
    }

    //~ // Force a frequency set after reset.
    //~ eraseFrequencySet = programFrequencySet = FALSE;

    if (method & PUC_RESET) {                           //1st try: a PUC over JTAG
        ReleaseDevice(V_RESET);
        if (releaseJTAG) {
            if (HIL_Release() != STATUS_OK) {   // Release the JTAG control signals.
                MSP430_Log(2, "MSP430mspgcc: PUC_RESET but JTAG release FAILED\n");
                RET_ERR(RUN_ERR);
            }
	    HIL_Resync();
	    HIL_Flush();
            jtagReleased = TRUE;
            MSP430_Log(2, "MSP430mspgcc: PUC_RESET and JTAG release ok\n");
            RET_OK;
        } else {
            // Connect and synchronize with the CPU. The CPU is clocked with TCLK. Read/Write will be set.
            if (GetDevice() == STATUS_OK) {
                if (execute) {                              // should the application run?
                    HIL_JTAG_IR(IR_CNTRL_SIG_RELEASE);      // Start device
							    // execution (and
							    // 
							    // retain JTAG control signals).
		    HIL_Resync();
		    HIL_Flush();
                }
                MSP430_Log(2, "MSP430mspgcc: PUC_RESET ok\n");
                RET_OK;
            }
        }
        //just try next reset method if this one did not succeed
        
        //~ if (ExecutePUC() == STATUS_OK) {
            //~ if (syncCPU() == STATUS_OK) {
                //~ if (execute) {                          // should the application run?
                    //~ HIL_JTAG_IR(IR_CNTRL_SIG_RELEASE);  // Start device execution (and retain JTAG control signals).
                    //~ if (releaseJTAG) {                  // disconnect JTAG?
                        //~ if (HIL_Release() != STATUS_OK) {// Release the JTAG control signals.
                            //~ RET_ERR(RUN_ERR);
                        //~ }
                        //~ jtagReleased = TRUE;
                    //~ }
                //~ }
                //~ MSP430_Log(2, "MSP430mspgcc: PUC_RESET ok\n");
                //~ RET_OK;
            //~ }
        //~ }
    }
    if (method & RST_RESET) {                           //if first method failed, try hard reset
        // Assert (hard) ~RST/NMI.
        HIL_RST(0);
	HIL_Resync();
	HIL_Flush();
        HIL_DelayMSec(50);                              // keep it low for some time (discharge caps)
        HIL_RST(1);                                     // adds an other delay ater the pin is high

	HIL_Resync();
	HIL_Flush();
        if (releaseJTAG) {
            if (HIL_Release() != STATUS_OK) {   // Release the JTAG control signals.
                MSP430_Log(2, "MSP430mspgcc: RST_RESET but JTAG release FAILED\n");
                RET_ERR(RUN_ERR);
            }
            jtagReleased = TRUE;

	    HIL_Resync();
	    HIL_Flush();
            MSP430_Log(2, "MSP430mspgcc: RST_RESET and JTAG release ok\n");
            RET_OK;
        } else {
            // Connect and synchronize with the CPU. The CPU is clocked with TCLK. Read/Write will be set.
            if (GetDevice() == STATUS_OK) {
                if (execute) {                              // should the application run?
                    HIL_JTAG_IR(IR_CNTRL_SIG_RELEASE);      // Start device execution (and retain JTAG control signals).
                }
                MSP430_Log(2, "MSP430mspgcc: RST_RESET ok\n");

		HIL_Resync();
		HIL_Flush();
                RET_OK;
            }
        }
    }
    if (method & VCC_RESET) {
	MSP430_Log(0,"This reset method is unsupported (Reset VCC)"); 
    }

    RET_ERR(RESET_ERR);
}

/* ----------------------------------------------------------------------------
Erase the device FLASH memory. MSP430_Read_Memory() can be used to search the
address of a failed erase operation.
If address+length extends beyond the segment containing address, intermediate
segments are erased (and checked).

Parameters:
 type: ERASE_SEGMENT: Erase the segment containing 'address'.
       ERASE_MAIN:    Erase the Main memory.
       ERASE_ALL:     Erase the Main and Information memories.
 address:             Starting address of erase check operation. Must be word aligned.
 length:              Length of erase check operation (even number of bytes).

Returns:
 STATUS_OK:    The device FLASH memory was erased.
 STATUS_ERROR: The device FLASH memory was not erased.

Error codes:
 PARAMETER_ERR
 ERASE_ERR
*/
STATUS_T WINAPI MSP430_Erase(LONG type, LONG address, LONG length) {
    STATUS_T result = STATUS_OK;
    MSP430_Log(1, "MSP430mspgcc: MSP430_Erase...\n");
    
    if (((type != ERASE_SEGMENT) && (type != ERASE_MAIN) && (type != ERASE_ALL)) ||
           (address < 0) || (address + length > FLASH_END_ADDR + 1)) {
        RET_ERR(PARAMETER_ERR);
    }

    switch (type) {
        case ERASE_SEGMENT:
        {
            LONG segmentAddr;
            WORD segmentSize;
            // Erase each of the segments.
            for (segmentAddr = address; segmentAddr < (address + length); segmentAddr += segmentSize) {
                if ((result = eraseFlash(ERASE_SEGMENT, (WORD) segmentAddr)) != STATUS_OK) {
                    break;
                }
            
                // The segment size is dependent upon the adress.
                if (segmentAddr < 0x1100) {
                    segmentSize = INFO_SEGMENT_SIZE;            // Information memory.
                } else if (segmentAddr < 0x1200) {
                    segmentSize = FIRST_60K_SEGMENT_SIZE;       // The first segment of 60K devices is short.
                } else {
                    segmentSize = MAIN_SEGMENT_SIZE;            // Main memory.
                }
            }
            if (result != STATUS_ERROR) {
                //check the entire length for erasure.
                result = VerifyPSA(address, length/2, 0);
            }
            break; // ERASE_SEGMENT.
        }
        case ERASE_MAIN:
        case ERASE_ALL:
            result = eraseFlash((WORD) type, (WORD) address);
            break;
        default:
            result = STATUS_ERROR;
            break;
    }

    if (result != STATUS_OK) {
        RET_ERR(ERASE_ERR);
    }

    RET_OK;
}

/* ----------------------------------------------------------------------------
Read and write the device memory. "Device memory" includes the Special Function
Registers (i.e., peripheral registers), RAM, Information (FLASH) memory, and
Main (FLASH) memory.
The write to FLASH memory operation DOES NOT erase the FLASH, use MSP430_Erase
in advance to do so.

Parameters:
 address: The starting address of the device memory to be read or written.
 buffer:  The buffer into which device memory is read, or from which device memory is written.
 count:   The number of bytes of device memory read or written.
 rw:      Specify a read (READ) or write (WRITE) operation.

Returns:
 STATUS_OK:    The memory operation encountered no errors.
 STATUS_ERROR: The memory operation encountered errors.

Error codes:
 PARAMETER_ERR
 READ_MEMORY_ERR
 WRITE_MEMORY_ERR
*/

//TODO: transition this back to the ReadMemoryQuick and WriteMemoryQuick. 
STATUS_T WINAPI MSP430_Memory(LONG address, CHAR* buffer, LONG count, LONG rw) {
    WORD doneCount = 0;
    WORD memValue;
    BOOL adjustLast = FALSE;
    WORD i;
    if (rw) {   //read
        MSP430_Log(1, "MSP430mspgcc: MSP430_MemoryRead...\n");
        if (address < WORD_REG_START_ADDR) {    // Process all byte addresses first.
            doneCount = WORD_REG_START_ADDR - (WORD) address;
            if (count < doneCount) {
                doneCount = (WORD) count;
            }
            for (i=0; i<doneCount; i++) {
                buffer[i] = ReadMem(F_BYTE, (WORD)(address + i));
            }
        } else if (address & 1) {               // Otherwise force word alignment if not.
            memValue = ReadMem(F_WORD, (WORD)(address + count));
            *buffer = (memValue >> 8) & 0xFF;
            doneCount = 1;
        }
        // And now the word memory.   
        if ((count - doneCount) > 0) {
            if ((address + count) & 1) {        // The last address has to be aligned.
                adjustLast = TRUE;
                count--;
            }
	    //RS: ReadMemQuick is much faster over the USB, because we do not
	    //incur USB latency on every word.  As a result, I believe that is
	    //actually may be more reliable than the read every word approach
	    //appropriate for for FET 
            ReadMemQuick((WORD) (address + doneCount),
                         (WORD) ((count - doneCount) / 2),
                         (WORD*) (buffer + doneCount)
             );
#if 0
            //slow but reliable upload, instead of ReadMemQuick
            //but this is 3 times or so slower....
            for (i=0; i<(count - doneCount)/2; i++) {
                ((WORD*)(&buffer[doneCount]))[i] = ReadMem(F_WORD, (WORD)(address + doneCount + i*2));
            }
#endif
            if (adjustLast) {
                memValue = ReadMem(F_WORD, (WORD)(address + count));
                *(buffer + count) = memValue & 0xFF;
            }
        }
    } else {    //write
        MSP430_Log(1, "MSP430mspgcc: MSP430_MemoryWrite...\n");
        if (address < WORD_REG_START_ADDR) {    // Process all byte addresses first.
            doneCount = WORD_REG_START_ADDR - (WORD) address;
            if (count < doneCount)
                doneCount = (WORD) count;
            for (i=0; i<doneCount; i++) {
                WriteMem(F_BYTE, (WORD)(address + i), buffer[i]);
            }
        } else if (address & 1) {               // Otherwise force word alignment if not.
            memValue = 0x00FF | ((*buffer) << 8);
            WriteMem(F_WORD, (WORD)(address + count), memValue);
            doneCount = 1;
        }
        // And now the word memory.   
        if (address < FLASH_START_ADDR) {       // Write in io/ram.
            if ((count - doneCount) > 0) {
                if ((address + count) & 1) {    // The last address has to be aligned.
                    adjustLast = TRUE;
                    count--;
                }
                WriteMemQuick((WORD) (address + doneCount),
                             (WORD) ((count - doneCount) / 2),
                             (WORD*) (buffer + doneCount)
                );
                if (adjustLast) {
                    memValue = *(buffer + count) | 0xFF00;
                    WriteMem(F_WORD, (WORD) (address + count), memValue);
                }
            }
        } else {                                // Write in flash
            if ((address >= FLASH_START_ADDR) && ((address + count - 1) <= FLASH_END_ADDR)) { // Write in flash.
                CHAR* prgBuffer = buffer;
                BOOL mallocedBuffer = FALSE;
                STATUS_T result;
                
                // The flash only supports writing words on word boundaries. Force alignment
                // if odd address and/or odd count.
                // Even address and odd length: pad last, count + 1.
                if (!(address & 1) && (count & 1)) {
                    prgBuffer = malloc(count + 1); mallocedBuffer = TRUE;
                    memcpy(prgBuffer, buffer, count);
                    prgBuffer[count++] = (CHAR)0xff;
                } else if ((address & 1) && !(count & 1)) {
                    // Odd address and even length: pad first and last, count + 2, address--.
                    prgBuffer = malloc(count + 2); mallocedBuffer = TRUE;
                    memcpy(prgBuffer + 1, buffer, count++);
                    prgBuffer[0] = prgBuffer[count++ + 1] = (CHAR)0xff;
                    address--;
                } else if ((address & 1) && (count & 1)) {
                    // Odd address and odd length: pad first, count + 1, address--.
                    prgBuffer = malloc(count + 1); mallocedBuffer = TRUE;
                    memcpy(prgBuffer + 1, buffer, count++);
                    prgBuffer[0] = (CHAR)0xff;
                    address--;
                }
                
                // Program the flash (assuming that it is erased).
                result = programFlash((WORD)address, prgBuffer, (WORD)count);
                
                if (mallocedBuffer) {
                    free(prgBuffer);
                    mallocedBuffer = FALSE;
                }
                if (result != STATUS_OK) {
                    RET_ERR(WRITE_MEMORY_ERR);
                }
            } else {    // Write in flash.
                RET_ERR(WRITE_MEMORY_ERR); // Write starts and/or ends outside of valid memory.
            }
        }
    }
    RET_OK;
}

/* ----------------------------------------------------------------------------
Read Register.

Parameter:
 RegNum:      Register number 0-15.
 Value:       [OUT] the 16 bit value of the register.

Returns:
 STATUS_OK:    Success.
 STATUS_ERROR: Failure, Register num out of range.

Error codes:
 PARAMETER_ERR
*/
STATUS_T WINAPI MSP430_ReadRegister(LONG RegNum, LONG *Value) {
    WORD temp;
    MSP430_Log(1, "MSP430mspgcc: MSP430_ReadRegsiter...\n");
    if (GetReg(RegNum, &temp) != STATUS_OK) {
        RET_ERR(PARAMETER_ERR);
    }
    *Value = temp & 0xffff;
    RET_OK;
}

/* ----------------------------------------------------------------------------
Write Register.

Parameter:
 RegNum:      Register number 0-15.
 Value:       The 16 bit value to be written to the register.

Returns:
 STATUS_OK:    Success.
 STATUS_ERROR: Failure, Register num out of range.

Error codes:
 PARAMETER_ERR
*/
STATUS_T WINAPI MSP430_WriteRegister(LONG RegNum, LONG Value) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_ReadRegsiter...\n");
    if (SetReg(RegNum, Value) != STATUS_OK) {
        RET_ERR(PARAMETER_ERR);
    }
    RET_OK;
}

/* ----------------------------------------------------------------------------
Compare the MSP430 memory and the specified data. This function computes a
checksum for the specified memory region, and then computes a checksum for the
data, and finally compares the two checksums.

Parameter:
 StartAddr:    Start address of memory to be compared (must be even).
 Length:       Number of bytes to be compared (must be even).
 *DataArray:   Pointer to data array.

Returns:
 STATUS_OK:    The device memory and data compare.
 STATUS_ERROR: The device memory and data do not compare.

Error codes:
 PARAMETER_ERR
 VERIFY_ERR
*/
STATUS_T WINAPI MSP430_VerifyMem(LONG StartAddr, LONG Length, CHAR *DataArray) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_VerifyMem...\n");
    return (VerifyPSA(StartAddr, Length/2, (WORD *)&DataArray[0]));
}

/* ----------------------------------------------------------------------------
Verify that the specified memory range is erased. MSP430_VerifyMem is
used to check the memory.

Parameter:
 StartAddr:    Start address of memory to be verified (must be even).
 Length:       Number of BYTEs to be verified (must be even).

Returns:
 STATUS_OK:    The device memory in the specified range is erased.
 STATUS_ERROR: The device memory in the specified range is not erased.

Error codes:
 PARAMETER_ERR
 VERIFY_ERR
*/
STATUS_T WINAPI MSP430_EraseCheck(LONG StartAddr, LONG Length) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_EraseCheck...\n");
    return (VerifyPSA(StartAddr, Length/2, 0));
}

// Error handling functions ---------------------------------------------------

/* ----------------------------------------------------------------------------
Determine the number of the error when an MSP430_xxx() function returns STATUS_ERROR.
The error number is reset (to NO_ERR) after the error number is returned.

Returns:
 The number of the last error.
*/
LONG WINAPI MSP430_Error_Number(void) {
    int tempErrorNumber = errorNumber;
    MSP430_Log(1, "MSP430mspgcc: MSP430_Error_Number...\n");
    errorNumber = NO_ERR;
    return (tempErrorNumber);
}

/* ----------------------------------------------------------------------------
Determine the string associated with errorNumber.

Parameter:
 errorNumber: Error number.

Returns:
 The string associated with errorNumber.
*/
const CHAR* WINAPI MSP430_Error_String(LONG errorNumber) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_Error_String...\n");
    if ((errorNumber < 0) || (errorNumber >= INVALID_ERR)) {
        errorNumber = INVALID_ERR;
    }
    return (errorStrings[errorNumber]);
}

/* ----------------------------------------------------------------------------
Execute the 'funclet' provided in code.

A funclet has the download address, start of main address and the end address as the
first 6 bytes. Between these 3 words and the starting address a range of memory
can be used to pass data to the funclet.
*/
STATUS_T WINAPI MSP430_Funclet(CHAR* code, LONG sizeCode, BOOL verify, BOOL wait) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_Funclet...\n");
    return executeCode((WORD *)code, sizeCode/sizeof(WORD), verify, wait);
}

/* ----------------------------------------------------------------------------
Check if the CPU is stuck on an address. This can be because it's executing a
"jmp $" or it's in the lowpower mode. Use at your own risk, may not work in any
case!?
*/
int WINAPI MSP430_isHalted(void) {
    MSP430_Log(1, "MSP430mspgcc: MSP430_isHalted...\n");
    return isHalted();
}

/* ----------------------------------------------------------------------------
Output debug messages

There messages are dumped if they are smaller than the given debug level.
The level can be set at runtime.
*/
STATUS_T WINAPI MSP430_Log(unsigned int level, const char *format, ...) {
    if (debug_level > level) {
        va_list args;
        va_start(args, format);
        vfprintf(stderr, format, args);
        va_end(args);
    }
    return STATUS_OK;
}
