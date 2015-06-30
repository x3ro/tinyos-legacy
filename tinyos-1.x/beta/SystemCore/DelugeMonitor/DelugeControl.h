#ifndef __DELUGECONTROL_H__
#define __DELUGECONTROL_H__

enum {
  AM_NETPROGCMDMSG = 3,
};

#ifndef DELUGE_REBOOT_DELAY
#define DELUGE_REBOOT_DELAY 65535U
#endif

typedef struct NetProgCmdMsg {
  bool rebootNode:1;
  bool runningImgNumChanged:1;
  bool pad:6;

  uint8_t runningImgNum;
  uint16_t rebootDelay;
} NetProgCmdMsg;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)

#define IFLASH_CMDSEQNO_ADDR      0xFC2

#elif defined(PLATFORM_TELOS)

#define IFLASH_CMDSEQNO_ADDR      0x52

#endif

#endif



