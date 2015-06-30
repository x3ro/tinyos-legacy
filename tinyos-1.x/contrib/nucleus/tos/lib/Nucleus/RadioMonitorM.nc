//$Id: RadioMonitorM.nc,v 1.2 2005/06/14 18:10:10 gtolle Exp $

module RadioMonitorM {
  provides interface StdControl;
    
  uses {
    interface AttrServer as MA_InPackets;
    interface AttrServer as MA_InBytes;
    interface AttrServer as MA_InErrors;
    interface AttrServer as MA_OutPackets;
    interface AttrServer as MA_OutBytes;
    interface AttrServer as MA_OutErrors;

    interface MessageStats as SendStats;
    interface MessageStats as ReceiveStats;
  }
}

implementation {

  uint32_t InPackets;
  uint32_t InBytes;
  uint32_t InErrors;

  uint32_t OutPackets;
  uint32_t OutBytes;
  uint32_t OutErrors;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  async event result_t SendStats.pass(uint16_t bytes) {
    atomic {
      OutPackets++;
      OutBytes += bytes;
    }
    return SUCCESS;
  }

  async event result_t SendStats.fail(uint8_t error) {
    atomic OutErrors++;
    return SUCCESS;
  }

  async event result_t ReceiveStats.pass(uint16_t bytes) {
    atomic {
      InPackets++;
      InBytes += bytes;
    }
    return SUCCESS;
  }

  async event result_t ReceiveStats.fail(uint8_t error) {
    atomic InErrors++;
    return SUCCESS;
  }

  event uint8_t MA_InPackets.length() { return MA_RadioMonitor_InPackets_LEN; }
  event uint8_t MA_InBytes.length() { return MA_RadioMonitor_InBytes_LEN; }
  event uint8_t MA_InErrors.length() { return MA_RadioMonitor_InErrors_LEN; }
  event uint8_t MA_OutPackets.length() { return MA_RadioMonitor_OutPackets_LEN; }
  event uint8_t MA_OutBytes.length() { return MA_RadioMonitor_OutBytes_LEN; }
  event uint8_t MA_OutErrors.length() { return MA_RadioMonitor_OutErrors_LEN; }

  event uint8_t MA_InPackets.get(void *buf) {
    memcpy(buf, &InPackets, sizeof(InPackets));
    return SUCCESS;
  }

  event uint8_t MA_InBytes.get(void *buf) {
    memcpy(buf, &InBytes, sizeof(InBytes));
    return SUCCESS;
  }

  event uint8_t MA_InErrors.get(void *buf) {
    memcpy(buf, &InErrors, sizeof(InErrors));
    return SUCCESS;
  }

  event uint8_t MA_OutPackets.get(void *buf) {
    memcpy(buf, &OutPackets, sizeof(OutPackets));
    return SUCCESS;
  }

  event uint8_t MA_OutBytes.get(void *buf) {
    memcpy(buf, &OutBytes, sizeof(OutBytes));
    return SUCCESS;
  }

  event uint8_t MA_OutErrors.get(void *buf) {
    memcpy(buf, &OutErrors, sizeof(OutErrors));
    return SUCCESS;
  }
}
