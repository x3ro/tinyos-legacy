module TraceRouteSoIM {
   provides {
      interface StdControl as Control;
   }
   uses {
      interface StdControl as TRControl;
      interface StdControl as TimerControl;
      interface StdControl as SettingsControl;
   }
}

implementation {
   command result_t Control.init() {
      call TimerControl.init();
      call TRControl.init();
      call SettingsControl.init();
      return SUCCESS;
   }

   command result_t Control.start() {
      call TimerControl.start();
      call TRControl.start();
      call SettingsControl.start();
      return SUCCESS;
   }

   command result_t Control.stop() {
      call TimerControl.stop();
      call TRControl.stop();
      call SettingsControl.stop();
      return SUCCESS;
   }
}
