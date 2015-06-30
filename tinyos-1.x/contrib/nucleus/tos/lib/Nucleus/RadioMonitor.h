#ifndef __RADIOMONITOR_H__
#define __RADIOMONITOR_H__

enum {
  MA_RadioMonitor_InPackets_ATTR = 10,
  MA_RadioMonitor_InBytes_ATTR = 11,
  MA_RadioMonitor_InErrors_ATTR = 12,
  MA_RadioMonitor_OutPackets_ATTR = 20,
  MA_RadioMonitor_OutBytes_ATTR = 21,
  MA_RadioMonitor_OutErrors_ATTR = 22,
};

enum {
  MA_RadioMonitor_InPackets_LEN = 4,
  MA_RadioMonitor_InBytes_LEN = 4,
  MA_RadioMonitor_InErrors_LEN = 4,
  MA_RadioMonitor_OutPackets_LEN = 4,
  MA_RadioMonitor_OutBytes_LEN = 4,
  MA_RadioMonitor_OutErrors_LEN = 4,
};

#endif // __IDENT_H__
