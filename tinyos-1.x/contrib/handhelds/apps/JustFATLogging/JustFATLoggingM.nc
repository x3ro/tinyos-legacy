/*
 * Copyright (c) 2009, Shimmer Research, Ltd.
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
 * Authors: Steve Ayer
 *          September, 2009
 */

includes DMA;
includes msp430baudrates;
includes MMA_Accel;
includes PowerSupplyMonitor;

module JustFATLoggingM {
  provides{
    interface StdControl;
  }
  uses {
    interface FatFs;
    interface DMA as DMA0;

    interface IDChip;

    interface StdControl as PSMStdControl;
    interface PowerSupplyMonitor;

    interface StdControl as AccelStdControl;
    interface MMA_Accel as Accel;

    interface Time;
    interface Leds;

    interface Timer as sampleTimer;
    interface Timer as warningTimer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  void do_stores();

  uint8_t stop_storage = 0, stop_threshold = TWO_9V, longAddress[8], directory_set, bad_opendir, bad_mkdir;
  norace uint8_t current_buffer = 0, dma_blocks = 0;
  uint16_t sbuf0[512], sbuf1[512], sequence_number = 0, sample_period, dir_counter;
  uint8_t dirname[128], filename[128], dir_hour = 0, idname[13];

  FATFS gfs;
  FIL gfp;
  DIR gdp;

  struct tm g_tm;

  void setupDMA() {
    call DMA0.init();

    call DMA0.setSourceAddress((uint16_t)ADC12MEM0_);

    call DMA0.setDestinationAddress((uint16_t)&sbuf0[0]);

    /*
     *  we'll transfer from three sequential adcmem registers 
     * to three sequential addresses in a buffer
     */
    call DMA0.setBlockSize(3);

    // we want block transfer, single
    DMA0CTL = DMADT_1 + DMADSTINCR_3 + DMASRCINCR_3;
  }
	
  void sampleADC() {
    call DMA0.ADCinit();   // this doesn't really need to be parameterized

    atomic{
      CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
      SET_FLAG(ADC12CTL1, ADC12SSEL_3);        
      
      SET_FLAG(ADC12CTL1, ADC12DIV_7);         
      // sample and hold time four adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   
      
      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }

    SET_FLAG(ADC12MCTL0, INCH_5);  // accel x 
    SET_FLAG(ADC12MCTL1, INCH_4);  // accel y 
    SET_FLAG(ADC12MCTL2, INCH_3);  // accel z 
    SET_FLAG(ADC12MCTL2, EOS);       //sez "this is the last reg" 

    /*
     *  ref off, using avcc (3.0v regulator)
     */
    CLR_FLAG(ADC12CTL0, REFON);
    CLR_FLAG(ADC12MCTL0, SREF_7);             // VR+ = AVCC and VR- = AVSS
    CLR_FLAG(ADC12MCTL1, SREF_7);             // VR+ = AVCC and VR- = AVSS
    CLR_FLAG(ADC12MCTL2, SREF_7);             // VR+ = AVCC and VR- = AVSS
    /*
     * ref on, ref to internal 2.5v
    SET_FLAG(ADC12MCTL0, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL1, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL2, SREF_1);             // Vref = Vref+ and Vr-
    */
    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_1);      // single sequence of channels
    
    setupDMA();

    call DMA0.beginTransfer();
  }

  /*
   * to avoid overwriting old data files, each time the app starts (device reset)
   * this will establish a base directory consisting of 12-character mac address
   * from the cc2420 radio, and a three digit counter, beginning with the last-seen value
   * on the card plus one.
   * e.g. 0000112be777_0000/
   * files will be written to this directory until reset in numerical order
   */
  result_t set_basedir() { 
    FILINFO gfi;
    result_t res;
    uint16_t tmp_counter = 0;
    char lfn[_MAX_LFN + 1], * fname, * scout, dirnum[8];

    // first we'll make the shimmer mac address into a string
    /*
     * substitute for biosensics
     */ sprintf(idname, "ID%02x%02x", 
	    longAddress[4], longAddress[5]);
    /*
    sprintf(idname, "%02x%02x%02x%02x%02x%02x", 
	    longAddress[0], longAddress[1], longAddress[2], longAddress[3], longAddress[4], longAddress[5]);
    */
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
     * dir format is 
     * 000102030405   shimmer 12 hex-digit cc2420 mac address
     * _              separator
     * 000            a 3-digit sequential run number
     *
     * we want to create a new directory with a sequential run number each time for each shimmer
     */
    while(call FatFs.readdir(&gdp, &gfi) == FR_OK){
      if(*gfi.fname == 0)
	break;
      else if(gfi.fattrib & AM_DIR){      
	fname = (*gfi.lfname) ? gfi.lfname : gfi.fname;
	/*
	 * substitute this line for biosensics
	 */
	if(!strncmp(fname, idname, 6)){      // their id prefix has just six chars
	/*
	if(!strncmp(fname, idname, 12)){      // it's this shimmer's dir
	*/
	  /*
	   * substitute these for next two lines for biosensics
	   */	
	  if((scout = strchr(fname, '-'))){   // if not, something is seriously wrong!
	    scout += 2;                      // we have to skip the 'M' before the counter
	   /*
	  if((scout = strchr(fname, '_'))){   // if not, something is seriously wrong!
	    scout++;
	   */
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

  result_t make_basedir() { 
    /*
     * substitute for biosensics
     */ sprintf(dirname, "/data/%s-M%03d", idname, dir_counter);
     /*
    sprintf(dirname, "/data/%s_%03d", idname, dir_counter);
     */
    if(call FatFs.mkdir(dirname))
      return FAIL;
    
    return SUCCESS;
  }

  task void store_contents() {
    uint bytesWritten;

    TOSH_MAKE_DOCK_N_OUTPUT();
    TOSH_SET_DOCK_N_PIN();

    if(gfp.fptr > 1080000){                     // @ 50hz * three channels, one hour
      call Leds.yellowToggle();
      call FatFs.fclose(&gfp);                             // close this file
      do_stores();

      TOSH_MAKE_DOCK_N_OUTPUT();                // we need these because do_stores has its own output/input transition
      TOSH_SET_DOCK_N_PIN();
    }

    call Leds.greenOn();

    if(current_buffer == 1){
      call FatFs.fwrite(&gfp, (uint8_t *)sbuf0, 1020, &bytesWritten);
    }
    else{
      call FatFs.fwrite(&gfp, (uint8_t *)sbuf1, 1020, &bytesWritten);    
    }
    call Leds.greenOff();

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
      
      call Leds.yellowOn();
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
  
  command result_t StdControl.init() {
    /* 
     * set up 8mhz clock to max out 
     * msp430 throughput 
     */
    register uint8_t i;

    atomic CLR_FLAG(BCSCTL1, XT2OFF);

    call Leds.init();

    call Leds.redOn();
    do{
      CLR_FLAG(IFG1, OFIFG);
      for(i = 0; i < 0xff; i++);
    }
    while(READ_FLAG(IFG1, OFIFG));

    call Leds.redOff();

    call Leds.yellowOn();
    TOSH_uwait(50000U);

    atomic{
      BCSCTL2 = 0;
      SET_FLAG(BCSCTL2, SELM_2);
    }
    
    call Leds.yellowOff();

    atomic{
      SET_FLAG(BCSCTL2, SELS);  // smclk from xt2
      SET_FLAG(BCSCTL2, DIVS_1);  // divide it by 2; smclk will run at 8 mhz / 2; spi bus will run at 4mhz / 2
    }
    /* 
     * end clock set up 
     */
    call AccelStdControl.init();

    call PSMStdControl.init();

    sample_period = 20;   // 50 hz

    // just a flag so we only do this once
    directory_set = 0;

    dma_blocks = 0;

    // we'll use this to id which shimmer wrote the files
    call IDChip.read(longAddress);

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call AccelStdControl.start();

    call Accel.setSensitivity(RANGE_2_0G);

    call Leds.greenOn();  // this just tells some users that it's on
    call FatFs.mount(&gfs);

    sampleADC();

    /*
     * this level will catch it just before it falls off the regulator, at about 3.07v
     * default monitor interval is 15 minutes
     */
    call PowerSupplyMonitor.setVoltageThreshold(THREE_05V);
    call PSMStdControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    // this will kill writes after the current one finishes
    atomic stop_storage = 1;

    call sampleTimer.stop();

    call DMA0.ADCdisable();
    
    call Leds.set(0);
    call warningTimer.start(TIMER_ONE_SHOT, 5000);

    call FatFs.fclose(&gfp);         // last chance to close the file if it's open
    call FatFs.disable();

    return SUCCESS;
  }

  event void Time.tick() {}

  void do_stores(){
    uint8_t r;

    /*
     * for biosensics
     */    sprintf(filename, "%s/%03d.pam", dirname, sequence_number++);
     /*
    sprintf(filename, "%s/%03d", dirname, sequence_number++);
     */
    TOSH_MAKE_DOCK_N_OUTPUT();
    TOSH_SET_DOCK_N_PIN();

    r = call FatFs.fopen(&gfp, filename, (FA_OPEN_ALWAYS | FA_WRITE | FA_READ));

    TOSH_MAKE_DOCK_N_INPUT();

    if(r)
      call Leds.set(7);
    else
      call Leds.set(0);
  }
  
  event result_t sampleTimer.fired() {
    call DMA0.beginTransfer();
    call DMA0.ADCbeginConversion();
    return SUCCESS;
  }

  event result_t PowerSupplyMonitor.voltageThresholdReached(uint8_t t) {
    /*
     * we're at the point where the fs will break;  shutdown stuff
     * and start a short blink
     */
    if(t == stop_threshold){   // this is about 2.93v
      call StdControl.stop();
    }
    else{
      // we're getting low, watch every two minutes now
      call PowerSupplyMonitor.setVoltageThreshold(stop_threshold);
      call PowerSupplyMonitor.clearLowVoltageCondition();
      call PowerSupplyMonitor.setMonitorInterval(120000);
      call PSMStdControl.start();
    }
    return SUCCESS;
  }
  
  event result_t warningTimer.fired() {
    static bool on;
    
    call Leds.redToggle();
    if(!on){
      on = TRUE;
      call warningTimer.start(TIMER_ONE_SHOT, 500);      
    }
    else{
      on = FALSE;
      call warningTimer.start(TIMER_ONE_SHOT, 5000);      
    }
    return SUCCESS;
  }

  async event void DMA0.transferComplete() {
    dma_blocks++;
    atomic DMA0DA += 6;
    if(dma_blocks == 170){
      dma_blocks = 0;

      if(current_buffer == 0){
	atomic DMA0DA = (uint16_t)&sbuf1[0];

	current_buffer = 1;
      }
      else { 
	atomic DMA0DA = (uint16_t)&sbuf0[0];

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
 
    call sampleTimer.start(TIMER_REPEAT, sample_period);
  }

  task void dock_check() {
    /*
     * this is only set by stdcontrol.stop, which is only called when we've
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
    call Leds.yellowOff();

    post rollTheBall();
  }
  
  async event void FatFs.mediaUnavailable() {
    post dock_check();

    call Leds.yellowOn();
  }

  async event void DMA0.ADCInterrupt(uint8_t regnum) {
    // we should *not* see this, as the adc interrupts are eaten by the dma controller!
  } 
}
