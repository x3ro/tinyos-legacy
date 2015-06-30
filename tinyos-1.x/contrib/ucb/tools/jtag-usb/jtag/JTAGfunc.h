/*now part of mspgcc, modified file from TI:
- added symbolic names for bits and MSP430 instructios: JMP_$, MOV_IMM_PC
- added SLOWFUSECHECK_BUG, FUSECHECK_DELAY, DEFAULT_VCC, N_REGS
- removed comments, having them in the c file is sufficent.

chris

original TI notes:
*/
/*==========================================================================*\
|                                                                            |
| JTAGfunc.h                                                                 |
|                                                                            |
| JTAG Function Prototypes and Definitions                                   |
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
| 1.1 06/02 ALB2        Formatting changes, added comments.                  |
| 1.2 08/02 ALB2        Initial code release with Lit# SLAA149.              |
|----------------------------------------------------------------------------|
| Designed 2002 by Texas Instruments Germany                                 |
\*==========================================================================*/

#include "Basic_Types.h"

/****************************************************************************/
/* Define section for constants                                             */
/****************************************************************************/

// Constants for the JTAG instruction register (IR, requires LSB first). 
// The MSB has been interchanged with LSB due to use of the same shifting 
// function as used for the JTAG data register (DR, requires MSB first).

// Instructions for the JTAG control signal register
#define IR_CNTRL_SIG_16BIT      0x13
#define IR_CNTRL_SIG_CAPTURE    0x14
#define IR_CNTRL_SIG_RELEASE    0x15
// Instructions for the JTAG Fuse
#define IR_PREPARE_BLOW	        0x22
#define IR_EX_BLOW              0x24 
// Instructions for the JTAG data register
#define IR_DATA_16BIT           0x41
#define IR_DATA_CAPTURE         0x42
#define IR_DATA_QUICK           0x43
// Instructions for the JTAG PSA mode
#define IR_DATA_PSA             0x44
#define IR_SHIFT_OUT_PSA        0x46
// Instructions for the JTAG address register
#define IR_ADDR_16BIT           0x83
#define IR_ADDR_CAPTURE         0x84
#define IR_DATA_TO_ADDR         0x85
// Bypass instruction
#define IR_BYPASS               0xFF

// JTAG identification value for all existing Flash-based MSP430 devices
#define JTAG_ID                 0x89

// Bits of the control signal register
#define CNTRL_SIG_READ          0x0001
#define CNTRL_SIG_CPU_HALT      0x0002
#define CNTRL_SIG_HALT_JTAG     0x0008
#define CNTRL_SIG_BYTE          0x0010
#define CNTRL_SIG_CPU_OFF       0x0020
#define CNTRL_SIG_INSTRLOAD     0x0080
#define CNTRL_SIG_TCE           0x0200
#define CNTRL_SIG_TCE1          0x0400
#define CNTRL_SIG_PUC           0x0800
#define CNTRL_SIG_CPU           0x1000
#define CNTRL_SIG_TAGFUNCSAT    0x2000
#define CNTRL_SIG_SWITCH        0x4000

// Constants for data formats, dedicated addresses
#define F_BYTE                  8
#define F_WORD                  16
#define V_RESET                 0xFFFE

#define SLOWFUSECHECK_BUG
#define FUSECHECK_DELAY     50
#define DEFAULT_VCC         3000    // Default Vcc to 3V (3000mV).
#define N_REGS              16

//Insns
#define JMP_$                           0x3fff  // JMP $
#define MOV_IMM_PC                      0x4030  // MOV #<val>,PC
#define MOV_IMM_RX                      0x4030  // MOV #<val>,PC
#define MOV_RX_MEM                      0x4082  // MOV #<val>,PC
#define SAVE_ADDRESS                    0x01fe  // Pointing to nowhere

/****************************************************************************/
/* Function prototypes                                                      */
/****************************************************************************/

// Low level JTAG functions
void ResetTAP(void);
WORD ExecutePUC(void);
WORD SetInstrFetch(void);
WORD SetPC(WORD Addr);
WORD SetReg(BYTE Regnum, WORD Value);
WORD GetReg(BYTE Regnum, WORD *Value);
void HaltCPU(void);
void ReleaseCPU(void);
WORD VerifyPSA(WORD StartAddr, WORD Length, WORD *DataArray);

// High level JTAG functions
WORD GetDevice(void);
void ReleaseDevice(WORD Addr);
void WriteMem(WORD Format, WORD Addr, WORD Data);
void WriteMemQuick(WORD StartAddr, WORD Length, const WORD *DataArray);
WORD ReadMem(WORD Format, WORD Addr);
void ReadMemQuick(WORD StartAddr, WORD Length, WORD *DataArray);
WORD EraseCheck(WORD StartAddr, WORD Length);
WORD VerifyMem(WORD StartAddr, WORD Length, WORD *DataArray);
WORD IsFuseBlown(void);
