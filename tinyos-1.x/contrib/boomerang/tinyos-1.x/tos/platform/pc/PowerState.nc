/**
 * Interface for the PowerState functions.
 *
 * Authors: Victor Shnayder, Bor-rong Chen
 *
 */

interface PowerState {
     async command double get_mote_cycles(int mote);

     /*
      * profile=1 if doing profiling, 0 else
      */
     async command result_t init(int profile, int cpu_prof);

     /* Do any necessary finalization.  In particular, dump out
      * details to a file if necessary. */
     async command result_t stop();

     /* Used by the main event loop to notify us to record/process the
      * current CPU Cycle Count */
     async command void CPUCycleCheckpoint();



     /************ ADC functions **********/
     /* The current mote (at the current time) is accessing
      * the specified port */
     async command void ADCsample(uint8_t port);
     async command void ADCdataReady();
     async command void ADCon();
     async command void ADCoff();

     /************ LED functions **********/

     async command void redOn();
     async command void redOff();
     async command void greenOn();
     async command void greenOff();
     async command void yellowOn();
     async command void yellowOff();

     /************ RADIO functions **********/     

     async command void radioTxMode();
     async command void radioRxMode();
     async command void radioRFPower(uint8_t power_level);
     async command void radioStart();
     async command void radioStop();

     /************ CPU state funtions *******/
     async command void cpuState(uint8_t sm);

     /************ SENSOR functions *********/
     async command void sensorPhotoOn(); 
     async command void sensorPhotoOff();
     async command void sensorTempOn();
     async command void sensorTempOff();
     async command void sensorAccelOn();
     async command void sensorAccelOff();

     /************ EEPROM functions ********/
     async command void eepromReadStart();
     async command void eepromReadStop();
     async command void eepromWriteStart();
     async command void eepromWriteStop();


     /************ SNOOZE functions *********/
     async command void snoozeStart();
     async command void snoozeWakeup();
}
