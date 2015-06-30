//  $Id: JTAGfunc.c,v 1.2 2004/12/15 04:06:33 szewczyk Exp $
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

  Added support for the latency hiding-operations over USB.  
  Merged functions from funclets.c
  The functions provided by this file have the same semantics as the functions
  in the original file -- every function ends up with the lfushed state.  

  @author Chris Liechti <cliechti@gmx.net>
 
  Part of mspgcc, modified file from TI. Please see
  LICENSE.txt in the current directory.  
- Removed flash writing code as this does not work over the parallel port
  under a non realtime OS.
- Also removed BlowFuse code as it's not supported by the FET kit.
- Fusecheck delay inserted.
- added some debug outputs, see def.h for activation.

chris

original TI notes:
*/
/*==========================================================================*\
|                                                                            |
| JTAGfunc.c                                                                 |
|                                                                            |
| JTAG Control Sequences for Erasing / Programming / Fuse Burning            |
|----------------------------------------------------------------------------|
| Project:              JTAG Functions                                       |
| Developed using:      IAR Embedded Workbench 2.31C                         |
|----------------------------------------------------------------------------|
| Author:               FRGR                                                 |
| Version:              1.2                                                  |
| Initial Version:      04-17-02                                             |
| Last Change:          08-29-02                                             |
|----------------------------------------------------------------------------|
| Version history:                                                           |
| 1.0 04/02 FRGR        Initial version.                                     |
| 1.1 04/02 ALB2        Formatting changes, added comments.                  |
| 1.2 08/02 ALB2        Initial code release with Lit# SLAA149.              |
|----------------------------------------------------------------------------|
| Designed 2002 by Texas Instruments Germany                                 |
\*==========================================================================*/


#include "defs.h"
#include "HIL.h"
#include "JTAGfunc.h"
#include "funclets.h"   //syncCPU
#include <windows.h>
WORD DEVICE = 0;

void ResetTAP(void) {
    int i;
    
    // Perform fuse check
    HIL_TMS(0);
    HIL_TMS(1);
    HIL_TMS(0);
    HIL_TMS(1);
    // Now fuse is checked, Reset JTAG FSM
    for (i = 6; i > 0; i--) {
        HIL_TCK(POS_EDGE);
    }
    // JTAG FSM is now in Test-Logic-Reset  
    ClrTCK();
    ClrTMS();
    SetTCK();
    HIL_Resync();
    HIL_Flush();
    // JTAG FSM is now in Run-Test/IDLE
}

WORD SetInstrFetch(void) {
    WORD i;
    
    HIL_JTAG_IR(IR_CNTRL_SIG_CAPTURE);
    
    // Wait until CPU is in instr. fetch state, timeout after limited attempts
    for (i = 50; i > 0; i--) {
        HIL_TCLK(POS_EDGE);
	HIL_JTAG_DR(0x0000, F_WORD);	
        if ( (getLastValue(F_WORD) & 0x0080) == 0x0080) {
	    fprintf(stderr, "Synced after %d attempts\n", 50-i);
            return(STATUS_OK);
        }
    }
    return(STATUS_ERROR); 
}

WORD SetPC(WORD Addr) {
    SetInstrFetch();                            // Set CPU into instruction fetch mode, TCLK=1
    
    // Load PC with address
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x3401, F_WORD);                // CPU has control of RW & BYTE.
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(MOV_IMM_PC, F_WORD);            // "mov #addr,PC" instruction
    HIL_TCLK(NEG_EDGE);
    HIL_JTAG_DR(Addr, F_WORD);                  // Send addr value
    HIL_TCLK(NEG_EDGE);
    HIL_TCLK(NEG_EDGE);                         // Now the PC should be on Addr
    HIL_JTAG_IR(IR_ADDR_CAPTURE);
    //    if (Addr != HIL_JTAG_DR(0, 16)) return STATUS_ERROR;//ERROR: SetPC failed!
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);                // 
						// 
						// JTAG has control of RW & BYTE.
    return checkMacro(3, F_WORD, Addr);
}

WORD SetReg(BYTE Regnum, WORD Value) {
    // Verify parameters
    if (Regnum > 15) {
        return STATUS_ERROR;
    }
    
    SetInstrFetch();                            // Set CPU into instruction fetch mode, TCLK=1
    
    // Load register with value
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x3401, F_WORD);                // CPU has control of RW & BYTE.
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(MOV_IMM_RX | Regnum, F_WORD); // "mov #addr, Rx" instruction
    HIL_TCLK(NEG_EDGE);                         // instr fetch
    HIL_JTAG_DR(Value, F_WORD);                 // Send addr value
    HIL_TCLK(NEG_EDGE);                         // data fetch
    HIL_TCLK(NEG_EDGE);                         // instr exec
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);                // JTAG has control of RW & BYTE.
    return checkMacro(2, F_BYTE, JTAG_ID);
}

WORD GetReg(BYTE Regnum, WORD *Value) {
    // Verify parameters
    int marker;
    if (Regnum > 15) {
        return STATUS_ERROR;
    }
    
    SetInstrFetch();                            // Set CPU into instruction fetch mode, TCLK=1
    
    // Load PC with address
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x3401, F_WORD);                // CPU has control of RW & BYTE.
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(MOV_RX_MEM | (Regnum << 8), F_WORD); //"mov Rx, &a"
    HIL_TCLK(NEG_EDGE);                         // instr fetch
    HIL_JTAG_DR(SAVE_ADDRESS, F_WORD);          // Dummy addr value
    HIL_TCLK(NEG_EDGE);                         // data fetch
    HIL_TCLK(NEG_EDGE);                         // instr exec
    HIL_TCLK(NEG_EDGE);                         // (writes need 2 clks)
    HIL_JTAG_IR(IR_DATA_CAPTURE);
    HIL_JTAG_DR(0, F_WORD);            // Read databus which contains the
				       // regsiters value
    marker = HIL_GetMarker();
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);                // JTAG has control of RW & BYTE.
    HIL_Resync();
    *Value = HIL_ReadMarker(marker, F_WORD);
    HIL_Flush();
    return STATUS_OK;
}


void HaltCPU(void) {
    SetInstrFetch();                            // Set CPU into instruction fetch mode
    
    ClrTCLK();                                  //lch
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(0x3FFF, F_WORD);                // Send JMP $ instruction
    HIL_TCLK(NEG_EDGE);
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2409, F_WORD);                // Set JTAG_HALT bit
    SetTCLK();
    HIL_Resync();
    HIL_Flush();
}

void ReleaseCPU(void) {
    ClrTCLK();
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);                // Clear the HALT_JTAG bit
    HIL_JTAG_IR(IR_ADDR_CAPTURE);
    SetTCLK();
    //    HIL_Resync();
    //    HIL_Flush();
}

void ReleaseDevice(WORD Addr) {
    if (Addr == V_RESET) {
        HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
        HIL_JTAG_DR(0x2C01, F_WORD);            // Perform a PUC reset
        HIL_JTAG_DR(0x2401, F_WORD);
    } else {
        SetPC(Addr);                            // Set target CPU's PC
    }
    HIL_JTAG_IR(IR_CNTRL_SIG_RELEASE);
    HIL_Resync();
    HIL_Flush();
}


WORD ReadMem(WORD Format, WORD Addr) {
    WORD TDOword;
    int mrk;
    HaltCPU();
    
    ClrTCLK();
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    if  (Format == F_WORD) {
        HIL_JTAG_DR(0x2409, F_WORD);            // Set word read
    } else {
        HIL_JTAG_DR(0x2419, F_WORD);            // Set byte read
    }
    HIL_JTAG_IR(IR_ADDR_16BIT);
    HIL_JTAG_DR(Addr, F_WORD);                  // Set address
    HIL_JTAG_IR(IR_DATA_TO_ADDR);
    SetTCLK();
    
    ClrTCLK();
    HIL_JTAG_DR(0x0000, F_WORD);      // Shift out 16 bits
    SetTCLK();
    mrk = HIL_GetMarker();
    ReleaseCPU();

    if (HIL_Resync() == STATUS_OK) {
	TDOword = HIL_ReadMarker(mrk, F_WORD);
    } 
    HIL_Flush();
    
    return(Format == F_WORD ? TDOword : TDOword & 0x00FF);
}

void WriteMem(WORD Format, WORD Addr, WORD Data) {
    HaltCPU();
    
    ClrTCLK();
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    if (Format == F_WORD) {
        HIL_JTAG_DR(0x2408, F_WORD);            // Set word write
    } else {
        HIL_JTAG_DR(0x2418, F_WORD);            // Set byte write
    }
    HIL_JTAG_IR(IR_ADDR_16BIT);
    HIL_JTAG_DR(Addr, F_WORD);                  // Set addr
    HIL_JTAG_IR(IR_DATA_TO_ADDR);
    HIL_JTAG_DR(Data, F_WORD);                  // Shift in 16 bits
    SetTCLK();
    
    ReleaseCPU();

    HIL_Resync();
    HIL_Flush();
}

void WriteMemQuick(WORD StartAddr, WORD Length, const WORD *DataArray) {
    WORD i;
    
    // Initialize writing:
    SetPC((WORD)(StartAddr-4));
    HaltCPU();
    
    ClrTCLK();
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2408, F_WORD);                // Set RW to write
    HIL_JTAG_IR(IR_DATA_QUICK);
    for (i = 0; i < Length; i++) {
        HIL_JTAG_DR(DataArray[i], F_WORD);      // Shift in the write data
        SetTCLK();
        ClrTCLK();                              // Increment PC by 2
    }
    SetTCLK();
    
    ReleaseCPU();
    HIL_Resync();
    HIL_Flush();
}
void ReadMemQuick(WORD StartAddr, WORD Length, WORD *DataArray) {
    WORD i;
    int marker;
    // Initialize reading:
    SetPC(StartAddr-4);         //XXX: is this correct or should it be -2
    HaltCPU();
    
    ClrTCLK();
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2409, F_WORD);                    // Set RW to read
    HIL_JTAG_IR(IR_DATA_QUICK);
    
    marker = HIL_GetMarker();
    for (i = 0; i < Length; i++) {
        SetTCLK();
        ClrTCLK();
        HIL_JTAG_DR(0x0000, F_WORD); // Shift out the data
                                                    // from the target.
    }
    SetTCLK();
    
    ReleaseCPU();
    HIL_Resync();
    for (i=0; i<Length; i++) {
	DataArray[i] = HIL_ReadMarker(marker+1+i,F_WORD);
    }
    HIL_Flush();
}

WORD VerifyPSA(WORD StartAddr, WORD Length, WORD *DataArray) {
    WORD TDOword, i;
    WORD POLY = 0x0805;                         // Polynom value for PSA calculation
    WORD PSA_CRC = StartAddr-2;                 // Start value for PSA calculation
    
    ExecutePUC();          
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);
    SetInstrFetch();
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(0x4030, F_WORD);
    HIL_TCLK(NEG_EDGE);
    HIL_JTAG_DR(StartAddr-2, F_WORD);
    HIL_TCLK(NEG_EDGE);
    HIL_TCLK(NEG_EDGE);
    HIL_TCLK(NEG_EDGE);
    HIL_JTAG_IR(IR_ADDR_CAPTURE);
    HIL_JTAG_DR(0x0000, F_WORD);
    HIL_JTAG_IR(IR_DATA_PSA);
    for (i = 0; i < Length; i++) {
        // Calculate the PSA (Pseudo Signature Analysis) value  
        if ((PSA_CRC & 0x8000) == 0x8000) {
            PSA_CRC ^= POLY;
            PSA_CRC <<= 1;
            PSA_CRC |= 0x0001;
        } else {
            PSA_CRC <<= 1;
        }
        // if pointer is 0 then use erase check mask, otherwise data  
        &DataArray[0] == 0 ? (PSA_CRC ^= 0xFFFF) : (PSA_CRC ^= DataArray[i]);
        
        // Clock through the PSA  
        SetTCLK();
        ClrTCK();
        SetTMS();
        SetTCK();                               // Select DR scan
        ClrTCK();
        ClrTMS();
        SetTCK();                               // Capture DR
        ClrTCK();
        SetTCK();                               // Shift DR
        ClrTCK();
        SetTMS();
        SetTCK();                               // Exit DR
        ClrTCK();
        SetTCK();
        ClrTMS();
        ClrTCK();
        SetTCK();
        ClrTCLK();
    }
    HIL_JTAG_IR(IR_SHIFT_OUT_PSA);
    HIL_JTAG_DR(0x0000, F_WORD);      // Read out the PSA value
    SetTCLK();
    TDOword = getLastValue(F_WORD);
    return((TDOword == PSA_CRC) ? STATUS_OK : STATUS_ERROR);
}  


WORD ExecutePUC(void) {
    WORD JTAGVERSION;

    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2C01, F_WORD);                        // Apply Reset
    HIL_JTAG_DR(0x2401, F_WORD);                        // Remove Reset
    HIL_TCLK(POS_EDGE);
    HIL_TCLK(POS_EDGE);
    ClrTCLK();
    HIL_JTAG_IR(IR_ADDR_CAPTURE);
    JTAGVERSION = getLastValue(F_BYTE);
    SetTCLK();
    fprintf(stderr, "Got here\n");
    WriteMem(F_WORD, 0x0120, 0x5A80);                   // Disable Watchdog on target device  
    
    if (JTAGVERSION != JTAG_ID) {
        fprintf(stderr, "JTAGfunc: JTAG ID wrong.\n");     //DEBUG
        return(STATUS_ERROR);
    }
    
    return(STATUS_OK);
}
WORD EraseCheck(WORD StartAddr, WORD Length) {
    return (VerifyPSA(StartAddr, Length, 0));
}

//----------------------------------------------------------------------------
/* This function performs a Verification over the given memory range
   Arguments: WORD StartAddr (Start address of memory to be verified)
              WORD Length (Number of words to be verified)
              WORD *DataArray (Pointer to array with the data)
   Result:    WORD (STATUS_OK if verification was successful, STATUS_ERROR otherwise)
*/
WORD VerifyMem(WORD StartAddr, WORD Length, WORD *DataArray) {
    return (VerifyPSA(StartAddr, Length, &DataArray[0]));
}


//------------------------------------------------------------------------
/* This function checks if the JTAG access security fuse is blown.
   Arguments: None
   Result:    WORD (1 if fuse is blown, 0 otherwise)
*/
WORD IsFuseBlown(void) {
    WORD i;
    WORD answer;
  
    for (i = 3; i > 0; i--) {                   // First trial could be wrong
        HIL_JTAG_IR(IR_CNTRL_SIG_CAPTURE);
	HIL_JTAG_DR(0xAAAA, F_WORD);
	if (getLastValue(F_WORD) == 0x5555) {
            MSP430_Log(1, "JTAGfunc: JTAG fuse burned\n"); //DEBUG
            return 1;                           // Fuse is blown
        }
    }
    //try to find out more details...
    HIL_JTAG_DR(0, F_WORD);
    answer = getLastValue(F_WORD);
    if ((answer != 0) && (answer != 0xffff)) {
        MSP430_Log(1, "JTAGfunc: JTAG fuse ok\n"); //DEBUG
    } else {
        MSP430_Log(1, "JTAGfunc: ERROR: possibly no device\n"); //DEBUG
    }
    return 0;                                   // fuse is not blown
}

WORD GetDevice(void) {
    WORD i;
    WORD ctrl;
    
    DEVICE = 0;                                         // Preset DEVICE with "not a device"
    ResetTAP();                                         // Reset JTAG state machine, check fuse HW
   
    if (IsFuseBlown()) {                                // Stop here if fuse is already blown
        return(STATUS_ERROR);
    }

    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);                        // Set device into
							// JTAG mode + read
    HIL_JTAG_IR(IR_CNTRL_SIG_CAPTURE);
    if (getLastValue(F_BYTE) != JTAG_ID) {
        MSP430_Log(1, "JTAGfunc: JTAG ID wrong\n");     //DEBUG
        return(STATUS_ERROR);
    }
    
    // Wait until CPU is synchronized, timeout after a limited # of attempts
    for (i = 50; i > 0; i--) {
        HIL_JTAG_DR(0x0000, F_WORD);
	ctrl = getLastValue(F_WORD);
        MSP430_Log(6, "JTAGfunc: JTAG CNTRL: %04x\n", ctrl);
        if (ctrl & CNTRL_SIG_TCE) {
            DEVICE = ReadMem(F_WORD, 0x0FF0);           // Get target device type 
                                                        //(bytes are interchanged)
            DEVICE = (DEVICE << 8) + (DEVICE >> 8);     // Set global DEVICE type 
            MSP430_Log(1, "JTAGfunc: Sync OK, device: 0x%04x\n", DEVICE);   //DEBUG
            break;
        } else if (i == 1) {
            MSP430_Log(1, "JTAGfunc: Sync failed\n");   //DEBUG
            return(STATUS_ERROR);                       // Timeout reached, return false
        }
    }
    if (ExecutePUC() != STATUS_OK) {                    // Perform PUC, Includes  
        MSP430_Log(1, "JTAGfunc: PUC failed\n");        //DEBUG
        return(STATUS_ERROR);                           // target Watchdog disable.
    }
    if (syncCPU() != STATUS_OK) {                       // verify state
        MSP430_Log(1, "JTAGfunc: syncCPU failed\n");        //DEBUG
        return(STATUS_ERROR);                           // target Watchdog disable.
    }
    
    return(STATUS_OK);
}
#include "eraseFlash.ci"                        //include the program to erase the flash

STATUS_T eraseFlash(WORD type, WORD address) {
    WORD fctl1;
    //select correct erase mode
    switch (type) {
        case ERASE_SEGMENT:     fctl1 = 0xA502; break;
        case ERASE_MAIN:        fctl1 = 0xA504; break;
        case ERASE_ALL:         fctl1 = 0xA506; break;
        default: return (STATUS_ERROR);
    }
    //fill in arguments
    funclet_eraseFlash[3] = 0;//srinit;         //TODO: need arg for DCO+?
    funclet_eraseFlash[4] = fctl1;              //set FCTL1 contents
    funclet_eraseFlash[5] = address;            //address within the segment to be erased
    //download erase prog and execute
    return executeCode(funclet_eraseFlash, sizeof(funclet_eraseFlash)/sizeof(WORD), 1, 1);
}


static WORD readMab(void) {
    HIL_JTAG_IR(IR_ADDR_CAPTURE);
    HIL_JTAG_DR(0, 16);
    return getLastValue(F_WORD);
}



STATUS_T syncCPU(void) {
    WORD cntrlSig;
    int i;
    
    HIL_JTAG_IR(IR_CNTRL_SIG_CAPTURE);
    HIL_JTAG_DR(0, F_WORD);
    
    HIL_TCLK(1);
    cntrlSig = getLastValue(F_WORD);
    if (!(cntrlSig & CNTRL_SIG_TCE)) {                  //check if sync is lost
        HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);                //Lch
        HIL_JTAG_DR(0x2401, F_WORD);                    // Set device into JTAG mode + read
        //~ //HIL_JTAG_DR(CNTRL_SIG_TCE1 | CNTRL_SIG_CPU | (cntrlSig & 0xff), F_WORD);
        
        for (i = 50; i > 0; i--) {
            HIL_JTAG_DR(0x0000, F_WORD);
	    cntrlSig = getLastValue(F_WORD);
	    
            MSP430_Log(6, "funclets: JTAG CNTRL: 0x%04x\n", cntrlSig);
            if (cntrlSig & CNTRL_SIG_TCE) {
                MSP430_Log(5, "funclets: Sync OK\n");   //DEBUG
                break;
            } else if (i == 1) {
                MSP430_Log(5, "funclets: Sync failed\n"); //DEBUG
                return(STATUS_ERROR);                   // Timeout reached, return false
            }
        }
    }
    
    if (cntrlSig & CNTRL_SIG_CPU_HALT) {
        HIL_TCLK(0);
        // Clear HALT. Read/Write is under JTAG control. As a precaution, disable interrupts.
        HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
        HIL_JTAG_DR(CNTRL_SIG_READ|CNTRL_SIG_TCE1|CNTRL_SIG_TAGFUNCSAT, 16);
        HIL_TCLK(1);
    } else {  
        // Read/Write is under JTAG control. As a precaution, disable interrupts.
        HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
        HIL_JTAG_DR(CNTRL_SIG_READ|CNTRL_SIG_TCE1|CNTRL_SIG_TAGFUNCSAT, 16);
    }

    // Advance to an instruction load boundary. Normal the device will be on an instruction load boundary
    // following the synchronization. However, a bug in the F413 can stop the CPU off of an instruction
    // load boundary. In that case, manually advance the CPU to an instruction load boundary. Unfortunately,
    // at this time the device type can be unknown. Consequently, advance to an instruction load boundary
    // for all devices.
    if (SetInstrFetch() != STATUS_OK) {
        MSP430_Log(1, "funclets: Not in Fetch\n"); //DEBUG
        return (STATUS_ERROR); // Synchronization failed!
    }
    
    // Execute a dummy instruction (MOV R3,R3) to work around a problem in the F12x that can sometimes cause
    // the first TCLK after synchronization to be lost.
    // Note: It's critical that the dummy instruction require only a single cycle.
    // Note: Since the state of the PC is not critical at this time, there is no need to restore/adjust it.
    // Note: It is known that at this time that interrupts are not possible (GIE is clear).
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(0x4303, F_WORD);
    HIL_TCLK(POS_EDGE);
    
    // (As in internal check) Must exit on an instruction load boundary.
    HIL_JTAG_IR(IR_CNTRL_SIG_CAPTURE);
    HIL_JTAG_DR(0, F_WORD);
    cntrlSig = getLastValue(F_WORD);
    if (!(cntrlSig & CNTRL_SIG_INSTRLOAD)) {
        MSP430_Log(1, "funclets: Not in Fetch %d \n",cntrlSig); //DEBUG
        return (STATUS_ERROR);
    } else {
        return (STATUS_OK);
    }
}

static STATUS_T setPCsave(WORD addr) {
    WORD ret;
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(MOV_IMM_PC, F_WORD);            // Force PC into non-RAM area.
    HIL_TCLK(NEG_EDGE);
    HIL_JTAG_DR(addr, F_WORD);
    HIL_TCLK(NEG_EDGE);
    HIL_TCLK(NEG_EDGE);
    HIL_JTAG_IR(IR_ADDR_CAPTURE);               // Verify the Program Counter.
    HIL_JTAG_DR(0, F_WORD);
    ret = getLastValue(F_WORD);
    if (ret != addr) {
	MSP430_Log(1, "JTAGfunc: setPCsave expected 0x%04x got 0x%04x\n", addr, ret);
        return (STATUS_ERROR);
    }
    return (STATUS_OK);
}

long long _t_execCode = 0L;
long long _t_program = 0L;
STATUS_T executeCode(const WORD* code, WORD sizeCode, BOOL verify, BOOL wait) {
    int i;
    int marker;
    LARGE_INTEGER _ts, _te, freq;
    long long t; 
    QueryPerformanceCounter(&_ts);
    if (sizeCode == 0) {
        return (STATUS_OK);
    }
    if (code[0] & 1) {                          // Address must be even.
        return (STATUS_ERROR);
    }
    if (SetInstrFetch() != STATUS_OK) {         //Must start on an instruction load boundary.
        return (STATUS_ERROR);
    }

    MSP430_Log(3, "funclets: download %d words...\n", sizeCode); //DEBUG
    SetPC(code[0] - 2);
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(JMP_$, F_WORD);                 // Load "jmp $" instruction for use while HALT'ed.
    HIL_TCLK(NEG_EDGE);

    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2408, F_WORD);                // Set JTAG_HALT bit
    HIL_JTAG_IR(IR_DATA_QUICK);
    for (i = 0; i < sizeCode; i++) {
        HIL_JTAG_DR(code[i], F_WORD);           // Write data to memory.
        HIL_TCLK(NEG_EDGE);
    }
    HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
    HIL_JTAG_DR(0x2401, F_WORD);                // Clear the HALT_JTAG bit (Release CPU)
    HIL_Resync();
    HIL_Flush();
    if (verify) {       // Verify the memory contents (without corrupting it!)
        WORD *Read = (WORD *) malloc(sizeCode*sizeof(WORD));
        MSP430_Log(5, "funclets: verify...\n"); //DEBUG
        if (setPCsave(code[0] - 2) != STATUS_OK) {
            free(Read);                         // Free read buffer
            MSP430_Log(1, "funclets: setPCsave failed\n"); //DEBUG
            return (STATUS_ERROR);
        }
        HIL_JTAG_IR(IR_DATA_16BIT);
        HIL_JTAG_DR(JMP_$, F_WORD);             // Load "jmp $" instruction for use while HALT'ed.
        HIL_TCLK(NEG_EDGE);

        HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
        HIL_JTAG_DR(0x2409, F_WORD);            // Set JTAG_HALT bit
        HIL_JTAG_IR(IR_DATA_QUICK);
	marker = HIL_GetMarker();
        for (i = 0; i < sizeCode; i++) {
            HIL_TCLK(NEG_EDGE);
            Read[i] = HIL_JTAG_DR(0, F_WORD);   // Read data from memory.
        }
        HIL_JTAG_IR(IR_CNTRL_SIG_16BIT);
        HIL_JTAG_DR(0x2401, F_WORD);            // Clear the HALT_JTAG bit
						// (Release CPU)
	HIL_Resync();
	for (i=0; i <sizeCode; i++) {
	    Read[i] = HIL_ReadMarker(marker+1+i, F_WORD);
	}
	
        for (i = 0; i < sizeCode; i++) {        // Verify the memory contents.
            if (Read[i] != code[i]) {
                free(Read);                     // Free read buffer
                MSP430_Log(1, "funclets: vfy error (word %d)\n", i);   //DEBUG
                return (STATUS_ERROR);
            }
        }
        MSP430_Log(5, "funclets: vfy ok\n");    //DEBUG
        free(Read);                             // Free read buffer
    } // if (verify)
    
    //this block is needed if device has JTAG bug, but it shouldn't hurt anyway
    MSP430_Log(5, "funclets: park PC...\n");    //DEBUG
    if (setPCsave(ROM_ADDR) != STATUS_OK) {
        return (STATUS_ERROR);
    }
    
    MSP430_Log(5, "funclets: set active...\n"); //DEBUG
    HIL_JTAG_IR(IR_DATA_16BIT);
    HIL_JTAG_DR(0x4032, 16);                    // Clear the Status Register (no low power modes, diable irqs).
    HIL_TCLK(NEG_EDGE);
    HIL_JTAG_DR(0, 16);
    HIL_TCLK(1);
    HIL_TCLK(POS_EDGE);

    MSP430_Log(5, "funclets: set PC\n");        //DEBUG
    if (setPCsave(code[1]) != STATUS_OK) {      // Load the Program Counter.
        return (STATUS_ERROR);
    }

    MSP430_Log(5, "funclets: run...\n");        //DEBUG
    HIL_JTAG_IR(IR_CNTRL_SIG_RELEASE);          // Release the CPU (but retain JTAG control signals).
    HIL_TCLK(1);

    if (wait) {
        // Limit the number of cycles for the code to execute.
        for (i = 0; i < 20000; i++) {
            // Poll the device until it is executing the final code instruction.
            if ((readMab() == code[2]) && (readMab() == code[2]) && (readMab() == code[2])) {
                // For F413P, F41xC, and F12x devices, the following step will likely corrupt RAM.
                // However, we don't care about this as the RAM contents will be reloaded in necessary.
                MSP430_Log(5, "funclets: wait OK\n"); //DEBUG
    QueryPerformanceCounter(&_te);
    QueryPerformanceFrequency(&freq);
    t = ((1000000*(_te.QuadPart - _ts.QuadPart)) / (freq.QuadPart));
    _t_execCode += t;
    MSP430_Log(2, "exec funclet: time %ld\n",t);
    MSP430_Log(2, "exec funclet: total time %ld\n",_t_execCode);
                return (syncCPU());             // Resume control of the CPU. Read/Write will be set.
            }
        }
        MSP430_Log(1, "funclets: wait failed\n"); //DEBUG
        return (STATUS_ERROR);
    }
    MSP430_Log(3, "funclets: exec OK\n");       //DEBUG
    QueryPerformanceCounter(&_te);
    QueryPerformanceFrequency(&freq);
    t = ((1000000*(_te.QuadPart - _ts.QuadPart)) / (freq.QuadPart));
    _t_execCode += t;
    MSP430_Log(2, "exec funclet: time %ld\n",t);
    MSP430_Log(2, "exec funclet: total time %ld\n",_t_execCode);
    
    return (STATUS_OK);
}


#include "progFlash.ci"         //include the flash program
#ifndef min
    #define min(a,b) (((a)<(b)) ? (a) : (b))
#endif

WORD ramsize = 256;             //TODO: get device memory size
void (*flash_callback)(WORD, WORD) = NULL;

STATUS_T programFlash(WORD address, const CHAR* buffer, WORD count) {
    STATUS_T res = STATUS_OK;
    WORD blocksize;
    WORD done = 0;
    WORD tries;
    WORD *code = malloc(ramsize);
    if (code == NULL)   return STATUS_ERROR;                            //Out of memory
        
    MSP430_Log(2, "funclets: Flash write...\n");
    memcpy(code, funclet_progFlash, sizeof(funclet_progFlash));         //copy program to working buffer
    while (done < count) {                                              //download in blocks
        blocksize = min(count-done, ramsize-sizeof(funclet_progFlash)); //calculate blocksize
        memcpy(&code[sizeof(funclet_progFlash)/sizeof(WORD)], &buffer[done], blocksize); //copy new data to be flashed
        //fill in arguments
        code[3] = 0;//srinit;                                           //TODO: need arg for DCO+?
        code[4] = address;                                              //starting address in flash
        code[5] = blocksize/2;                                          //number of words to write
        MSP430_Log(2, "funclets: Flash write at 0x%04x %d bytes\n", address, blocksize);
        //download data and start flash programing funclet in RAM
        for (tries=3; tries; tries--) {
            res =  executeCode(code, (sizeof(funclet_progFlash) + blocksize)/sizeof(WORD), 1, 1);
            if (res != STATUS_OK) {
                MSP430_Log(1, "funclets: Flash write retrying in block 0x%04x\n", address);
                GetDevice();
            } else {
		break;
	    }
        }
        if (res != STATUS_OK) break;
        if (ReadMem(F_WORD, CCR0_ADDR)) {                               //read CCR0, it's used as return value
            MSP430_Log(1, "funclets: Flash write error in block 0x%04x\n", address);
            res = STATUS_ERROR;
            break;
        }
        //~ MSP430_Log(2, "block 0x%04x OK\n", address);
        address += blocksize;                                           //adjust for next block
        done += blocksize;                                              //advance in source buffer
        if (flash_callback != NULL) {
            flash_callback(done, count);
        }
    }
    free(code);                                                         //clean up memory
    MSP430_Log(2, "funclets: Flash write finished\n");
    return res;
}
int isHalted(void)
{
    int i;
    WORD reference = readMab();
    HIL_JTAG_IR(IR_CNTRL_SIG_RELEASE);          // Release the CPU (but retain JTAG control signals).
    HIL_TCLK(1);
    for (i=0; i<10; i++)
    {
	// USB latency is already larger than 1 ms, don't bother.
	//        HIL_DelayMSec(1); //make sure that the target has the chance to execute some code
        if (readMab() != reference) {
            return 0;
        }
    }
    return 1;
}
