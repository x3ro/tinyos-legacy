#if defined(PLATFORM_MICA2) || defined(PLATFORM_XSM)
#include <HardwareId.h>
#else
enum {
  HARDWARE_ID_LEN = 8,
};
#endif

enum {
  AM_HELLOMSG = 1,
  AM_HELLOREQMSG = 2,
  AM_HELLOCMDMSG = 2,
};

typedef struct HelloMsg {
  uint32_t userHash;
  uint32_t unixTime;
  uint16_t sourceAddr;
  uint8_t  hardwareId[HARDWARE_ID_LEN];
  char     programName[IDENT_MAX_PROGRAM_NAME_LENGTH];
} HelloMsg;

typedef struct HelloReqMsg {
  uint16_t reqAddr;
  uint8_t reqId;
} HelloReqMsg;

typedef struct HelloCmdMsg {
  bool light:1;
  bool sound:1;
  bool local:1;
  bool tree:1;
  bool sticky:1;
} HelloCmdMsg;

enum {
  HELLO_FIRST_BOOT = 0xffff,
};

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)

#define IFLASH_HELLO_BOOTCOUNT_ADDR      0xFC0 // 2 bytes

#elif defined(PLATFORM_TELOS)

#define IFLASH_HELLO_BOOTCOUNT_ADDR      0x50  // 2 bytes

#endif

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)

#include <avr/bootloader.h>
#include <avr/bl_flash.h>

#elif defined(PLATFORM_TELOS)

#include <msp/bootloader.h>
#include <msp/bl_flash.h>

#endif



