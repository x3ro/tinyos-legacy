
#ifdef PLATFORM_EMSTAR
includes tos_emstar;
#endif

module SButtonM {
  provides {
    interface StdControl;
    interface SButton;
  }
}
implementation {

  command result_t StdControl.init() {
#ifdef PLATFORM_EMSTAR
    if (emtos_stargate_verify_button() == 0) {
      return FAIL;
    }
#endif
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command uint8_t SButton.getButton() {
#ifdef PLATFORM_EMSTAR
    return emtos_stargate_get_button();
#else
    return 0;
#endif
  }
}
