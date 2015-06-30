includes WSN;

module TraceRouteTestM {
   provides {
      interface StdControl as Control;
   }
   uses {
      interface StdControl as TRControl;
      interface StdControl as TimerControl;
   }
}

implementation {
   command result_t Control.init() {
      call TimerControl.init();
      call TRControl.init();

      return SUCCESS;
   }

   command result_t Control.start() {
      call TimerControl.start();
      call TRControl.start();

      return SUCCESS;
   }

   command result_t Control.stop() {
      call TimerControl.stop();
      call TRControl.stop();
      return SUCCESS;
   }
}
