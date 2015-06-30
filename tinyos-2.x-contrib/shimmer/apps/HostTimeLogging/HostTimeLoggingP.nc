/* $Id: HostTimeLoggingP.nc,v 1.5 2012/07/12 19:04:16 ayer1 Exp $
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author  Steve Ayer
 * @date    May, 2010
 *
 * this version of HostTimeLogging requires a host app -- shimmer_timestamp.py -- 
 * that transmits a timestamp in unix seconds; it does not do anything else
 * until a buttonpress event triggers a transmission of 
 * the timestamp back to the host for validation
 */

#include <UserButton.h>
#include "Mma_Accel.h"
#include "msp430usart.h"
#include "PowerSupplyMonitor.h"

module HostTimeLoggingP {
  uses {
    interface Boot;
    interface FatFs;

    interface shimmerAnalogSetup;

    interface Msp430DmaChannel as DMA0;

    interface IDChip;

    interface StdControl as PSMStdControl;
    interface PowerSupplyMonitor;

    interface Init as AccelInit;
    interface Mma_Accel as Accel;

    interface Time;
    interface HostTime;
    interface Leds;

    interface Init as sampleTimerInit;
    interface Alarm<TMilli, uint16_t> as sampleTimer;
    interface Timer<TMilli> as warningTimer;

    interface HplMsp430Usart as UARTControl;
    interface HplMsp430UsartInterrupts as UARTData;

    interface Notify<button_state_t> as buttonNotify;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

#define ABBREVIATED_ID

  void do_stores();

  uint8_t stop_storage = 0, stop_threshold = TWO_9V, longAddress[8], directory_set, bad_opendir, bad_mkdir, NUM_ADC_CHANS;
  norace uint8_t current_buffer = 0, dma_blocks = 0;
  uint16_t sbuf0[512], sbuf1[512], sequence_number = 0, sample_period, dir_counter;
  uint8_t dirname[128], filename[128], dir_hour = 0, idname[13];

  struct tm g_tm;
  time_t g_host_time = 0;
  uint8_t toSend, charsSent;
  char timestring[128];
  bool transmissionComplete;

  FATFS gfs;
  FIL gfp;
  DIR gdp;


  /*
   * to avoid overwriting old data files, each time the app starts (device reset)
   * this will establish a base directory consisting of 12-character mac address
   * from the cc2420 radio, and a three digit counter, beginning with the last-seen value
   * on the card plus one.
   * e.g. 0000112be777-000/
   * we also use a less-geek abbreviated format using just the last four hex digits, this:
   * IDe777-000
   * files will be written to this directory until reset in numerical order
   */
  error_t set_basedir() { 
    FILINFO gfi;
    error_t res;
    uint16_t tmp_counter = 0;
    char lfn[_MAX_LFN + 1], * fname, * scout, dirnum[8];

    // first we'll make the shimmer mac address into a string

#ifdef ABBREVIATED_ID
    sprintf(idname, "ID%02x%02x", 
	    longAddress[4], longAddress[5]);
#else
    sprintf(idname, "%02x%02x%02x%02x%02x%02x", 
	    longAddress[0], longAddress[1], longAddress[2], longAddress[3], longAddress[4], longAddress[5]);
#endif

    gfi.lfname = lfn;
    gfi.lfsize = sizeof(lfn);

    if((res = call FatFs.opendir(&gdp, "/data"))){
      if(res == FR_NO_PATH)      // we'll have to make /data first
	res = call FatFs.mkdir("/data");
	
      if(res)         // in every case, we're toast
	return FAIL;

      // try one more time
      if((res = call FatFs.opendir(&gdp, "/data")))
	return FAIL;
    }

    dir_counter = 0;   // this might be the first log for this shimmer

    /*
     * full dir format is:
     * 000102030405   shimmer 12 hex-digit cc2420 mac address
     * -              separator
     * 000            a 3-digit sequential run number
     *
     * abbreviated format is:
     * ID             just a nmemonic
     * 05             last two of shimmer 12 hex-digit cc2420 mac address
     * -              separator
     * 000
     *
     * we want to create a new directory with a sequential run number each power-up/reset for each shimmer
     */
    while(call FatFs.readdir(&gdp, &gfi) == FR_OK){
      if(*gfi.fname == 0)
	break;
      else if(gfi.fattrib & AM_DIR){      
	fname = (*gfi.lfname) ? gfi.lfname : gfi.fname;
#ifdef ABBREVIATED_ID
	if(!strncmp(fname, idname, 6)){      // when id prefix has just six chars
#else
        if(!strncmp(fname, idname, 12)){      // it's this shimmer's dir
#endif
	  if((scout = strchr(fname, '-'))){   // if not, something is seriously wrong!
	    scout++;
	    
	    strcpy(dirnum, scout);
	    tmp_counter = atoi(dirnum);
	    if(tmp_counter >= dir_counter){
	      dir_counter = tmp_counter;
	      dir_counter++;                   // start with next in numerical sequence
	    }
	  }
	  else
	    return FAIL;
	}
      }
    }

    // at this point, we have the id string and the counter, so we can make a directory name
    return SUCCESS;
  }

  error_t make_basedir() { 
    sprintf(dirname, "/data/%s-%03d", idname, dir_counter);

    if(call FatFs.mkdir(dirname))
      return FAIL;
    
    return SUCCESS;
  }

  task void store_contents() {
    uint bytesWritten;

    TOSH_MAKE_DOCK_N_OUTPUT();
    TOSH_SET_DOCK_N_PIN();

    if(gfp.fptr > 1080000){                     // @ 50hz * three channels, one hour
      call Leds.led1Toggle();
      call FatFs.fclose(&gfp);                             // close this file
      do_stores();

      TOSH_MAKE_DOCK_N_OUTPUT();                // we need these because do_stores has its own output/input transition
      TOSH_SET_DOCK_N_PIN();
    }

    call Leds.led2On();

    if(current_buffer == 1){
      call FatFs.fwrite(&gfp, (uint8_t *)sbuf0, 1020, &bytesWritten);
    }
    else{
      call FatFs.fwrite(&gfp, (uint8_t *)sbuf1, 1020, &bytesWritten);    
    }
    call Leds.led2Off();

    call FatFs.fsync(&gfp);

    if(stop_storage){
      call FatFs.fclose(&gfp);                             // close this file
      stop_storage = 0;
    }
    
    /*
     * ugly way to poll dock, since we disabled driver's ability to get 
     * a hw interrupt.  better than blowing out the filesystem with a broken write
     * to disk.
     */
    TOSH_MAKE_DOCK_N_INPUT();
    atomic if(!TOSH_READ_DOCK_N_PIN()){
      call sampleTimer.stop();

      //      call FatFs.fclose(&gfp);
      
      call Leds.led1On();
      /*
       * the next thing the apps sees should be 
       * an fatfs.available event.  unmount
       * will call diskiostdcontrol.init, which will
       * powercycle the card, put it in sd mode for the dock,
       * and re-initialize the interrupt
       */
      call FatFs.unmount();      
    }
  }

  task void initialize_directories() {
    atomic directory_set = 1;

    bad_opendir = bad_mkdir = 0;

    TOSH_MAKE_DOCK_N_OUTPUT();
    TOSH_SET_DOCK_N_PIN();

    if(set_basedir() != SUCCESS)
      bad_opendir = 1;

    if(make_basedir() != SUCCESS)
      bad_mkdir = 1;

    TOSH_MAKE_DOCK_N_INPUT();
  }
  
  task void fireUpSystem(){
    call buttonNotify.disable();

    call UARTControl.disableUart();

    call AccelInit.init();

    call sampleTimerInit.init();
    sample_period = 100;   // 10 hz

    // just a flag so we only do this once
    directory_set = 0;

    dma_blocks = 0;

    // we'll use this to id which shimmer wrote the files
    call IDChip.read(longAddress);

    call Accel.setSensitivity(RANGE_4_0G);

    call shimmerAnalogSetup.addAccelInputs();
    call shimmerAnalogSetup.finishADCSetup(sbuf0);

    /*
     * this level will catch it just before it falls off the regulator, at about 3.07v
     * default monitor interval is 15 minutes
     */
    call PowerSupplyMonitor.setVoltageThreshold(THREE_05V);
    call PSMStdControl.start();

    NUM_ADC_CHANS = call shimmerAnalogSetup.getNumberOfChannels();

    call FatFs.mount(&gfs);
  }

  event void Boot.booted() {
    transmissionComplete = FALSE;

    call buttonNotify.enable();
  }

  task void stopEverything() {
    // this will kill writes after the current one finishes
    atomic stop_storage = 1;

    call sampleTimer.stop();

    call shimmerAnalogSetup.stopConversion();  //DMA0.ADCdisable();
    
    call Leds.set(0);
    call warningTimer.startPeriodic(5000);

    call FatFs.fclose(&gfp);         // last chance to close the file if it's open
    call FatFs.disable();
  }

  task void sendOneChar() {
    if(charsSent < toSend)
      call UARTControl.tx(timestring[charsSent++]);
    else{
      transmissionComplete = TRUE;
      post fireUpSystem();
    }
  }

  task void return_timestring() {
    toSend = strlen(timestring);
    charsSent = 0;
    transmissionComplete = FALSE;
    post sendOneChar();
  }

  async event void UARTData.rxDone(uint8_t data) { }

  async event void UARTData.txDone() {
    if(!transmissionComplete) {
      post sendOneChar();
    }
  }

  event void buttonNotify.notify( button_state_t val){
    post return_timestring();
  }

  event void Time.tick() {}
  
  event void HostTime.timeAndZoneSet(char * g_timestring){
    call Time.time(&g_host_time);
    call Time.localtime(&g_host_time, &g_tm);
    call Time.asctime(&g_tm, timestring, 128);
  }

  void do_stores(){
    uint8_t r;

    sprintf(filename, "%s/%03d", dirname, sequence_number++);

    TOSH_MAKE_DOCK_N_OUTPUT();
    TOSH_SET_DOCK_N_PIN();

    r = call FatFs.fopen(&gfp, filename, (FA_OPEN_ALWAYS | FA_WRITE | FA_READ));

    TOSH_MAKE_DOCK_N_INPUT();

    if(r)
      call Leds.set(7);
    else
      call Leds.set(0);
  }
  
  async event void sampleTimer.fired() {
    call shimmerAnalogSetup.triggerConversion();
    call sampleTimer.start(sample_period);
  }

  event void PowerSupplyMonitor.voltageThresholdReached(uint8_t t) {
    /*
     * we're at the point where the fs will break;  shutdown stuff
     * and start a short blink
     */
    if(t == stop_threshold){   // this is about 2.93v
      post stopEverything();
    }
    else{
      // we're getting low, watch every two minutes now
      call PowerSupplyMonitor.setVoltageThreshold(stop_threshold);
      call PowerSupplyMonitor.clearLowVoltageCondition();
      call PowerSupplyMonitor.setMonitorInterval(120000);
      call PSMStdControl.start();
    }
  }
  
  event void warningTimer.fired() {
    static bool on;
    
    //    call Leds.led0Toggle();
    if(!on){
      on = TRUE;
      call warningTimer.startOneShot(500);      
    }
    else{
      on = FALSE;
      call warningTimer.startOneShot(5000);      
    }
  }

  async event void DMA0.transferDone(error_t success) {
    //    call Leds.led0Toggle();
    dma_blocks++;
    atomic DMA0DA += 6;
    if(dma_blocks == 170){
      dma_blocks = 0;

      if(current_buffer == 0){
	call DMA0.repeatTransfer((void *)ADC12MEM0_, (void *)sbuf1, NUM_ADC_CHANS);
	current_buffer = 1;
      }
      else { 
	call DMA0.repeatTransfer((void *)ADC12MEM0_, (void *)sbuf0, NUM_ADC_CHANS);
	current_buffer = 0;
      }

      post store_contents();
    }
  }

  task void rollTheBall() {
    uint16_t i;

    for(i = 0; i < 500; i++)
      TOSH_uwait(1000);

    do_stores();
 
    call sampleTimer.start(sample_period);
  }

  task void dock_check() {
    /*
     * this is only set by stopEverything, which is only called when we've
     * reached the low power threshold.  so,
     * if we're docked -- charging -- let's stop the blinking 
     * and reset the powermonitor.  but no more logging.
     */
    if(stop_storage){
      call warningTimer.stop();
      call Leds.set(0);
      call PowerSupplyMonitor.clearLowVoltageCondition();
    }
    else
      call sampleTimer.stop();
  }

  async event void FatFs.mediaAvailable() {
    /*
     * prevent loss of control of card if the user 
     * puts us back on the dock
     */
    
    if(!stop_storage && !directory_set){
      post initialize_directories();
      if(bad_opendir || bad_mkdir){
	call Leds.set(7);
	return;
      }
    }
    call Leds.led1Off();

    post rollTheBall();
  }
  
  async event void FatFs.mediaUnavailable() {
    post dock_check();

    call Leds.led1On();
  }

}
