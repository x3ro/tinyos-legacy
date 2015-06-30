module MigDummyM {
       provides {
              interface StdControl;
       }      
       implementation {
		      command result_t StdControl.init() {
			}

		      command result_t StdControl.start() {
		        EventMsg m;
			
			 return m.
		      }

		      command result_t StdControl.stop() {
			}
       }
}
