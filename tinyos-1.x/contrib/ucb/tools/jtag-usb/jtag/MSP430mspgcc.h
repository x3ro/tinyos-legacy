#ifndef MSP430_H
#define MSP430_H

// #includes. -----------------------------------------------------------------

#include <stddef.h>
#include <stdarg.h>
#include "Basic_Types.h"


enum
{
    WRITE,
    READ,
};

// Device reset methods.
enum
{
    PUC_RESET = 1 << 0, // Power up clear (i.e., a "soft") reset.
    RST_RESET = 1 << 1, // RST/NMI (i.e., "hard") reset.
    VCC_RESET = 1 << 2, // Cycle Vcc (i.e., a "power on") reset.
};

#define ALL_RESETS (PUC_RESET + RST_RESET + VCC_RESET)

// FLASH erase type.
enum
{
    ERASE_SEGMENT,  // Erase a segment.
    ERASE_MAIN,     // Erase all MAIN memory.
    ERASE_ALL,      // Erase all MAIN and INFORMATION memory.
};

// Configurations.
enum
{
    VERIFICATION_MODE,  // Verify data downloaded to FLASH memories.
    RAMSIZE_OPTION,     // Change RAM used to download and programm flash blocks.
    DEBUG_OPTION,       // Set debug level. Enables debug outputs.
    FLASH_CALLBACK,     // Set a callback for progress report during flash write void f(WORD count, WORD total)
    LAST_CONFIGURATION, // This must be the last element in the enumeration.
};

// Error codes.
enum
{
    NO_ERR,                 // No error. *** must be first entry ***
    INITIALIZE_ERR,         // Could not initialize device interface.
    CLOSE_ERR,              // Could not close device interface.
    PARAMETER_ERR,          // Invalid parameter(s).
    NO_DEVICE_ERR,          // Could not find device (or device not supported).
    DEVICE_UNKNOWN_ERR,     // Unknown device.
    READ_MEMORY_ERR,        // Could not read device memory.
    WRITE_MEMORY_ERR,       // Could not write device memory.
    VCC_ERR,                // Could not set device Vcc.
    RESET_ERR,              // Could not reset device.
    FREQUENCY_ERR,          // Could not set device operating frequency.
    ERASE_ERR,              // Could not erase device memory.
    RUN_ERR,                // Could not run device.
    VERIFY_ERR,             // Verification error.
    INVALID_ERR,            // Invalid error number. *** must be last entry ***
};

#define RET_ERR(ERROR_NUMBER) { errorNumber = ERROR_NUMBER; return (STATUS_ERROR); }
#define RET_OK { errorNumber = NO_ERR; return (STATUS_OK); }

#define BYTE_REG_START_ADDR             0x0000
#define WORD_REG_START_ADDR             0x0100
#define LAST_PERIPHERAL_ADDR            0x01ff
#define DATA_START_ADDR                 0x0200
#define ROM_ADDR                        0x0c04
#define FLASH_START_ADDR                0x1000
#define FLASH_END_ADDR                  0xffff
#define CCR0_ADDR                       0x0172

#define MAIN_SEGMENT_SIZE               512     // Segments are normally 512 bytes in size.
#define FIRST_60K_SEGMENT_SIZE          256     // However, the first segment of 60K devices is 256 bytes in size.
#define INFO_SEGMENT_SIZE               128     // And Information segments are 128 bytes in size.

#ifdef __cplusplus
extern "C" {
#endif

// Functions. -----------------------------------------------------------------

STATUS_T WINAPI MSP430_Initialize(CHAR const * port, LONG* version);
STATUS_T WINAPI MSP430_Open(void);
STATUS_T WINAPI MSP430_Close(LONG vccOff);
STATUS_T WINAPI MSP430_Configure(LONG mode, LONG value);
STATUS_T WINAPI MSP430_VCC(LONG voltage);
STATUS_T WINAPI MSP430_Reset(LONG method, LONG execute, LONG releaseJTAG);
STATUS_T WINAPI MSP430_Erase(LONG type, LONG address, LONG length);
STATUS_T WINAPI MSP430_Memory(LONG address, CHAR* buffer, LONG count, LONG rw);
STATUS_T WINAPI MSP430_ReadRegister(LONG RegNum, LONG *Value);
STATUS_T WINAPI MSP430_WriteRegister(LONG RegNum, LONG Value);

#define MSP430_Read_Memory(ADDRESS, BUFFER, COUNT) MSP430_Memory(ADDRESS, BUFFER, COUNT, READ)
#define MSP430_Write_Memory(ADDRESS, BUFFER, COUNT) MSP430_Memory(ADDRESS, BUFFER, COUNT, WRITE)
STATUS_T WINAPI MSP430_VerifyMem(LONG StartAddr, LONG Length, CHAR *DataArray);
STATUS_T WINAPI MSP430_EraseCheck(LONG StartAddr, LONG Length);
LONG WINAPI MSP430_Error_Number(void);
const CHAR* WINAPI MSP430_Error_String(LONG errorNumber);

STATUS_T WINAPI MSP430_Funclet(CHAR* code, LONG sizeCode, BOOL verify, BOOL wait);
int WINAPI MSP430_isHalted(void);

STATUS_T WINAPI MSP430_Log(unsigned int level, const char *format, ...);
#ifdef __cplusplus
}
#endif

#endif //MSP430_H
