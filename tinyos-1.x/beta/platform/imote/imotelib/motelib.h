#ifndef IMOTE_LIB_H
#define IMOTE_LIB_H

/*
 * This file contains the function declarations for the motelib library.
 */

#ifdef ADS_COMPILER
#define C_ROUTINE
#else
#define C_ROUTINE __attribute__ ((C, spontaneous))
#endif

#include "LMU_CMD_HCBC.h"
#include "Common.h"
#include "TargetManager.h"
#include "LMU.h"
#include "LinkManager.h"
#include "Signals.h"
#include "BlueOS.h"
#include "Config.h"

/*
 * TOSBufferVar contains the Buffer Memory map for TinyOS.  This structure can
 * be expanded to accomodate more sophisticated memory management schemes.  The
 * UART and BT radio require that send and receive data sit in the Buffer RAM.
 * This initial buffer size of 32 char is arbitrary.
 */

#define MAX_TOS_BUFFER_SIZE 32
//#define MAX_APP_MEMORY 0x2D00
// reduce app memory by 1.5K to free up space for flash write buffers
#define MAX_APP_MEMORY 0x2700


typedef struct tTOSBufferVar {
  char UARTTxBuffer[MAX_TOS_BUFFER_SIZE];
  char UARTRxBuffer[MAX_TOS_BUFFER_SIZE];
  char AppMemory[MAX_APP_MEMORY];
} tTOSBufferVar;

void trace(long long mode, const char *format, ...);
void trace_unset();
void trace_set(long long mode);

extern tTOSBufferVar *TOSBuffer;

void HardwareInitialize ();
//UART initialization functions
int InitializeMainUart(uint8 baudrate);
int InitializeDebugUart(uint8 baudrate);
int InitializedMainUartDMA();

//UART cleanup functions
void DisableMainUart();

//UART receive funtions for DMA
void SetupMainUartDMAReceive(uint8 *newRxBuffer, uint16 newRxSize);

//UART transmission functions
void MainUartDMATransmit(uint8 *data, uint16 bytes);
void MainUartTransmit(uint8 data);
void DebugUartTransmit(uint8 data);
void DebugPrintf(char *buf, char *formatstr, ...);

//the following functions are used by the original TimerM implementation
void StartRTOSClock() ;
void StopRTOSClock() ;
void SetRTOSClockRate(uint32 rate) ;
uint32 GetRTOSClockValue();

//the following functions are used by the new TimerM implementation.  Do NOT
//mix and match functions
void InitRTOSTimer();
void SetRTOSInterval(uint32 val);

void InitializeGPIOInterrupt() ;
void EnableGPIOInterrupt() ;
void DisableGPIOInterrupt() ;
void SetGPIOState(uint8 regs) ;
uint8 GetGPIOState() ;
void SetGPIOInput(uint8 reg) ;
void SetGPIOOutput(uint8 reg) ;

extern void LM_RegisterUpperModuleId (tBP_ModuleId ID) ;

extern void UL_LMU_Init () C_ROUTINE;

extern void UL_ACL_Init () C_ROUTINE;

extern void LM_RegisterUpperLayerCallBacks(
                tUpperSendAclAckFunc UpperSendAclAck,
                tUpperSendAclNakFunc UpperSendAclNak,
                tUpperRecAclAvailable UpperRecAclAvailable,
                tUpperHostCmdTokenAvailable UpperHostCmdTokenAvailable
                ) C_ROUTINE;

extern void LMU_RegisterEventCallbacks(tLMU_EventCallbacks *pLMU_EventCallbacks) C_ROUTINE;

extern void LM_SendAcl(tTransac Transac, tHandleId HandleId, tDataPtr DataPtr,
                tDataSize DataSize, tDataFlags DataFlags) C_ROUTINE;

extern void LM_GetRecAcl(tTransac *pTransac, tHandleId *pHandleId,
                uint8 **pDataPtr, uint16 *pDataSize, tDataFlags *pDataFlags,
                bool Dequeue) C_ROUTINE ;

extern void LM_RecAclAck(tTransac Transac) C_ROUTINE;

extern void LM_ReadBdAddr(tBdAddr *pBdAddr, tBdAddrType BdAddrType) C_ROUTINE;

extern void LMU_Inquiry(uint8 Transac, const uint8 Lap[3], uint8 InquiryLength,
                uint8 NumResponses) C_ROUTINE;

extern void LMU_InquiryCancel(uint8 Transac) C_ROUTINE;

extern void LMU_PeriodicInqMode(uint8 Transac, uint16 MaxPeriodLength,
                                uint16 MinPeriodLength, const uint8 Lap[3],
                                uint8 InquiryLength, uint8 NumResponses)
                                C_ROUTINE;

extern void LMU_CreateConn(uint8 Transac, tBdAddr *pDest, uint16 PacketTypes,
                uint8 PageScanRepMode, uint8 PageScanMode, uint16 ClockOffset,
                uint8 AllowRoleSwitch)  C_ROUTINE;

extern void LMU_Disconnect (uint8 Transac, tHandleId Connection_Handle, uint8 Reason) C_ROUTINE;

extern void LMU_AcceptConn (uint8 Transac, tBdAddr *pDest, uint8 Role) C_ROUTINE;

extern void LMU_RejectConn (uint8 Transac, tBdAddr *pDest,
                uint8 Reason) C_ROUTINE;

extern void LMU_WriteScanEnable (uint8 Transac, uint8 Flag) C_ROUTINE;

extern void LMU_ChangeName (uint8 Transac, tBdName *Name) C_ROUTINE;

extern void LMU_SetEventFilter (uint8 Transac, uint8 FilterType, uint8 FilterCondType, uint8 *FilterCondition, uint8 FilterCondLen) C_ROUTINE;

extern void LMU_HoldMode(uint8 Transac, uint16 Handle, uint16 HoldModeMaxInterval, uint16 HoldModeMinInterval) C_ROUTINE;

extern void LMU_WriteHoldModeActivity(uint8 Transac, uint8 Flags) C_ROUTINE;

extern void LMU_SniffMode(uint8 Transac, uint16 Handle, uint16 Sniff_Max_Interval, uint16 Sniff_Min_Interval, uint16 Sniff_Attempt, uint16 Sniff_Timeout) C_ROUTINE;

extern void LMU_ExitSniffMode(uint8 Transac, uint16 Handle) C_ROUTINE;

extern void LMU_ParkMode(uint8 Transac, uint16 Handle, uint16 Beacon_Max_Interval, uint16 Beacon_Min_Interval) C_ROUTINE;

extern void LMU_ExitParkMode(uint8 Transac, uint16 Handle) C_ROUTINE;

extern void LMU_SwitchRole(uint8 Transac, tBdAddr *pBdAddr, uint8 Role) C_ROUTINE;

extern void LMU_WriteAutoFlushTimeout(uint8 Transac, uint16 Handle, uint16 Timeout) C_ROUTINE;

extern void LMU_RoleDiscovery(uint8 Transac, uint16 Handle) C_ROUTINE;

extern void LMU_ReadRSSI (uint8 Transac, uint16 Handle) C_ROUTINE;

extern void LMU_ReadAbsoluteRSSI (uint8 Transac, uint16 Handle) C_ROUTINE;

extern void LMU_WriteInqScanActivity (uint8 Transac, uint16 Interval, uint16 Window) C_ROUTINE;

extern void LMU_WritePageScanActivity (uint8 Transac, uint16 Interval, uint16 Window) C_ROUTINE;

/*
 * This file should be moved to the tos/platform directory before the initial
 * release.
 */


#endif //IMOTE_LIB_H



