// Hardware Interface Layer (HIL).
// based on TI's HIL.dll/HIL.h
// This library capsulates the hardware access of MSP430.dll/so

#ifndef HIL_H
#define HIL_H

// #includes. -----------------------------------------------------------------

#include "Basic_Types.h"

// #defines. ------------------------------------------------------------------

enum
{
    POS_EDGE = 2,
    NEG_EDGE,
};

#ifdef __cplusplus
extern "C" {
#endif

// Functions. -----------------------------------------------------------------
//Note: WINAPI is removed by a #define if compiled on non Windows (see Basic_Types.h)

STATUS_T WINAPI HIL_Initialize(CHAR const * port);
STATUS_T WINAPI HIL_Open(void);
STATUS_T WINAPI HIL_Connect(void);
STATUS_T WINAPI HIL_Release(void);
STATUS_T WINAPI HIL_Close(LONG vccOff);
LONG WINAPI HIL_JTAG_IR(LONG instruction);
LONG WINAPI HIL_TEST_VPP(LONG mode);
LONG WINAPI HIL_JTAG_DR(LONG data, LONG bits);
STATUS_T WINAPI HIL_VCC(LONG voltage);
void WINAPI HIL_TST(LONG state);
void WINAPI HIL_TCK(LONG state);
void WINAPI HIL_TMS(LONG state);
void WINAPI HIL_TDI(LONG state);
void WINAPI HIL_TDO(LONG state);
void WINAPI HIL_TCLK(LONG state);
void WINAPI HIL_RST(LONG state);
STATUS_T WINAPI HIL_VPP(LONG voltage);
void WINAPI HIL_DelayMSec(LONG mSeconds);
void WINAPI HIL_StartTimer(void);
ULONG WINAPI HIL_ReadTimer(void);
void WINAPI HIL_StopTimer(void);
LONG WINAPI HIL_ReadTDO(void);

    STATUS_T WINAPI HIL_Resync();
    LONG WINAPI HIL_ReadMarker(LONG marker, LONG bits);
    int WINAPI HIL_GetMarker();
    void WINAPI HIL_Flush();

    LONG WINAPI getLastValue(int bits);
    WORD WINAPI checkMacro(int stackPosition, int bits, int expected);

#define SetTMS()        HIL_TMS(1)
#define ClrTMS()        HIL_TMS(0)
#define SetTCK()        HIL_TCK(1)
#define ClrTCK()        HIL_TCK(0)
#define SetTDI()        HIL_TDI(1)
#define ClrTDI()        HIL_TDI(0)
#define SetTDO()        HIL_TDO(1)
#define ClrTDO()        HIL_TDO(0)
#define SetTCLK()       HIL_TCLK(1)
#define ClrTCLK()       HIL_TCLK(0)

#ifdef __cplusplus
}
#endif

#endif // HIL_H
