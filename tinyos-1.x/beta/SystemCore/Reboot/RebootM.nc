module RebootM {
  provides {
    interface StdControl;
    interface RebootCheck;
  }

  uses {
    interface InternalFlash as IFlash;
    interface Leds;

    interface MgmtAttr as MA_PowerOnResets;
    interface MgmtAttr as MA_ExternalResets;
    interface MgmtAttr as MA_WatchdogResets;
    interface MgmtAttr as MA_BrownoutResets;
    interface MgmtAttr as MA_ProgrammingFailureResets;
    interface MgmtAttr as MA_NetProgResets;
    interface MgmtAttr as MA_ResetHistory;
  } 
}
implementation {

  command result_t StdControl.init() {
    call MA_PowerOnResets.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_ExternalResets.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_WatchdogResets.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_BrownoutResets.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_ProgrammingFailureResets.init(sizeof(uint16_t), MA_TYPE_UINT);
    call MA_ResetHistory.init(sizeof(uint16_t), MA_TYPE_BITSTRING);
    call MA_NetProgResets.init(sizeof(uint16_t), MA_TYPE_UINT);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command bool RebootCheck.isFactoryBoot() {
    uint16_t powerOn = 0, external = 0, watchdog = 0, netProg = 0;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_POWER_ON_RESET_COUNTER, &powerOn, sizeof(uint16_t));
    call IFlash.read((uint16_t*)BL_EXTERNAL_RESET_COUNTER, &external, sizeof(uint16_t));
    call IFlash.read((uint16_t*)BL_WDT_RESET_COUNTER, &watchdog, sizeof(uint16_t));
    call IFlash.read((uint16_t*)BL_NETPROG_RESET_COUNTER, &netProg, sizeof(uint16_t));
#endif
    return (powerOn == 0 && external == 0 && watchdog == 0 && netProg == 1);
  }

  command bool RebootCheck.isInitialBoot() {
    uint16_t powerOn = 0, external = 0, watchdog = 0, netProg = 0;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_POWER_ON_RESET_COUNTER, &powerOn, sizeof(uint16_t));
    call IFlash.read((uint16_t*)BL_EXTERNAL_RESET_COUNTER, &external, sizeof(uint16_t));
    call IFlash.read((uint16_t*)BL_WDT_RESET_COUNTER, &watchdog, sizeof(uint16_t));
    call IFlash.read((uint16_t*)BL_NETPROG_RESET_COUNTER, &netProg, sizeof(uint16_t));
#endif
    return (powerOn == 0 && external == 0 && watchdog == 0 && netProg == 2);
  }

  event result_t MA_PowerOnResets.getAttr(uint8_t *buf) {
    uint16_t counter;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_POWER_ON_RESET_COUNTER, &counter, sizeof(uint16_t));
#endif
    memcpy(buf, &counter, sizeof(uint16_t));
    call Leds.set(counter);
    return SUCCESS;
  }

  event result_t MA_ExternalResets.getAttr(uint8_t *buf) {
    uint16_t counter;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_EXTERNAL_RESET_COUNTER, &counter, sizeof(uint16_t));
#endif
    memcpy(buf, &counter, sizeof(uint16_t));
    return SUCCESS;
  }

  event result_t MA_WatchdogResets.getAttr(uint8_t *buf) {
    uint16_t counter;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_WDT_RESET_COUNTER, &counter, sizeof(uint16_t));
#endif
    memcpy(buf, &counter, sizeof(uint16_t));
    return SUCCESS;
  }

  event result_t MA_BrownoutResets.getAttr(uint8_t *buf) {
    uint16_t counter;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_BROWN_OUT_RESET_COUNTER, &counter, sizeof(uint16_t));
#endif
    memcpy(buf, &counter, sizeof(uint16_t));
    return SUCCESS;
  }

  event result_t MA_ProgrammingFailureResets.getAttr(uint8_t *buf) {
    uint16_t counter;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_PROGRAM_FAIL_COUNTER, &counter, sizeof(uint16_t));
#endif
    memcpy(buf, &counter, sizeof(uint16_t));
    return SUCCESS;
  }

  event result_t MA_NetProgResets.getAttr(uint8_t *buf) {
    uint16_t counter;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_NETPROG_RESET_COUNTER, &counter, sizeof(uint16_t));
#endif
    memcpy(buf, &counter, sizeof(uint16_t));
    return SUCCESS;
  }

  event result_t MA_ResetHistory.getAttr(uint8_t *buf) {
    uint16_t counter;
#ifndef PLATFORM_PC
    call IFlash.read((uint16_t*)BL_RESET_HISTORY, &counter, sizeof(uint16_t));
#endif
    buf[0] = ((uint8_t*)&counter)[1];
    buf[1] = ((uint8_t*)&counter)[0];
//    memcpy(buf, &counter, sizeof(uint16_t));
    return SUCCESS;
  }
}
