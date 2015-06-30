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
 *          May, 2009
 */

includes DMA;
includes Message;
includes NVTParse;
includes msp430baudrates;
includes MMA7260_Accel;

module TestFATLoggingM {
  provides{
    interface StdControl;
  }
  uses {
    interface FatFs;
    interface DMA as DMA0;

    /* telnet stuff */
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    //    interface StdControl as PVStdControl;

    interface StdControl as AccelStdControl;
    interface MMA7260_Accel as Accel;

    interface Telnet as TelnetRun;

    interface UIP;
    interface Client; 

    interface NTPClient;
    interface Time;

    /* end telnet stuff */
    interface Leds;

    interface Timer as sampleTimer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  char * do_stores(char * in, char * out, char * outmax);
  void set_fat_time_now(FILINFO * fi, char * fname);

  void assembleRunHelp();

  uint8_t enable_storage = 0, stop_called = 0;
  norace uint8_t current_buffer = 0, dma_blocks = 0;
  uint16_t sbuf0[512], sbuf1[512], sequence_number = 0, sample_period = 5, current_hour = 99;
  uint8_t msgbuf[128], dirname[128], dir_basename[128], filename[128], dir_hour = 0;
  char helpmsg[128];

  FATFS gfs;
  FIL gfp;
  DIR gdp;

  struct tm g_tm;
  /*
   * seed this puppy with '%x' % (int(time.mktime((2009, 5, 22, 13, 26, 0, 1, 1, 0))))
   * for fun
   */

  time_t g_timer = 0x4a16ee38;

  void setupDMA() {
    call DMA0.init();

    call DMA0.setSourceAddress((uint16_t)ADC12MEM0_);

    call DMA0.setDestinationAddress((uint16_t)&sbuf0[0]);

    /*
     *  we'll transfer from six sequential adcmem registers 
     * to six sequential addresses in a buffer
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

    SET_FLAG(ADC12MCTL0, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL1, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL2, SREF_1);             // Vref = Vref+ and Vr-
    
    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_1);      // single sequence of channels
    
    setupDMA();

    call DMA0.beginTransfer();
  }

  task void store_contents() {
    uint bytesWritten;

    if(enable_storage){
      call Leds.redOn();

      //      if(gfp.fptr > 71500){                                 // @ 20hz, about 10 minutes of data
      if(gfp.fptr > 7140){                                 // @ 20hz, about 10 minutes of data

	call Leds.greenToggle();

	call FatFs.fclose(&gfp);                             // close this file
        do_stores(NULL, NULL, NULL);                        // open the next one
      }
      if(current_buffer == 1){
	call FatFs.fwrite(&gfp, (uint8_t *)sbuf0, 1020, &bytesWritten);
	//	call FatFs.fseek(&gfp, gfp.fptr - 4);                           // we only have 510 bytes of data
      }
      else{
	call FatFs.fwrite(&gfp, (uint8_t *)sbuf1, 1020, &bytesWritten);    
	//	call FatFs.fseek(&gfp, gfp.fptr - 4);
      }

      call Leds.redOff();
    }
    if(stop_called){
      call FatFs.fclose(&gfp);                             // close this file
      stop_called = 0;
    }
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
    TOSH_uwait(50000UL);

    atomic{
      BCSCTL2 = 0;
      SET_FLAG(BCSCTL2, SELM_2);
    }
    
    call Leds.yellowOff();

    atomic{
      SET_FLAG(BCSCTL2, SELS);  // smclk from xt2
      SET_FLAG(BCSCTL2, DIVS_1);  // divide it by 8
    }
    /* 
     * end clock set up 
     */

    //    call PVStdControl.init();
    call IPStdControl.init();
    call TelnetStdControl.init();

    call AccelStdControl.init();


    assembleRunHelp();

    dma_blocks = 0;
    *dir_basename = '\0';

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    call AccelStdControl.start();

    call Accel.setSensitivity(RANGE_2_0G);

    call FatFs.mount(&gfs);

    sampleADC();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void Time.tick() {}

  void get_time_now(struct tm * tm){
    time_t time_now;

    call Time.time(&time_now);
    call Time.localtime(&time_now, tm);
  }
    
  void fat_time(struct tm * tm, FILINFO * fi) { 
    uint8_t fyear;
    
    fyear = tm->tm_year - 1980;
    
    fi->fdate = (fyear << 9) | ((tm->tm_mon + 1) << 5) | tm->tm_mday;
    fi->ftime = (tm->tm_hour << 11) | (tm->tm_min << 5) | tm->tm_sec;
  }

  void set_fat_time_now(FILINFO * fi, char * fname){
    get_time_now(&g_tm);
    fat_time(&g_tm, fi);

    call FatFs.f_utime(fname, fi);
  }

  char * do_time(char * in, char * out, char * outmax) { 
    time_t time_now;
    char g_timestring[128];
    struct tm tm;

    call Time.time(&time_now);
    call Time.localtime(&time_now, &tm);
    call Time.asctime(&tm, g_timestring, sizeof(g_timestring));

    //    call FatFs.asc_fattime(g_timestring);

    sprintf(msgbuf, "time now is %s", g_timestring);

    return out;
  }

  char * do_conv(char * in, char * out, char * outmax) { 
    sample_period = atoi(in);

    sprintf(msgbuf, "requested sample period %d ms (%d hz)", sample_period, 1000/sample_period);

    call sampleTimer.start(TIMER_REPEAT, sample_period);

    return out;
  }

  char * no_conv(char * in, char * out, char * outmax) { 
    sprintf(msgbuf, "sampling at %d hz stopped", 1000/sample_period);

    call sampleTimer.stop();

    return out;
  }

  void fat_ascdate(FILINFO * fi, char * timestring) {
    uint16_t fyear;
    uint8_t fmon, fday, fhour, fmin;
    
    fyear = (fi->fdate >> 9) + 1980;
    fmon = (fi->fdate >> 5) & 0x000f;
    fday = fi->fdate & 0x001f;

    fhour = fi->ftime >> 11;
    fmin = (fi->ftime >> 5) & 0x003f;

    sprintf(timestring, "%04d-%02d-%02d %02d:%02d", fyear, fmon, fday, fhour, fmin);
  }

    
  char * do_stores(char * in, char * out, char * outmax) { 
    uint8_t res, new_basedir = 0;
    struct tm tm;
    time_t time_now;
    char * dir_b, * next;

    if(in){    // we're parsing a command line
      if(!(dir_b = next_token(in, &next, ' '))){
	sprintf(msgbuf, "please provide a base dirname (e.g. foo == /data/foo_<hournum>/)");
	return out;
      }
      else if(strcmp(dir_basename, dir_b)){
	strcpy(dir_basename, dir_b);
	new_basedir = 1;
      }
    }

    enable_storage = 1;

    call Time.time(&time_now);
    call Time.localtime(&time_now, &tm);

    if((current_hour != tm.tm_hour) || new_basedir){
      current_hour = tm.tm_hour;
      if(new_basedir)
	dir_hour = 0;
      sprintf(dirname, "/data/%s_%03d", dir_basename, dir_hour++);
      
      if((res = call FatFs.mkdir(dirname)) == 5){   // path not found, let's make /data first
	if((res = call FatFs.mkdir("/data"))){
	  sprintf(msgbuf, "mkdir failed for /data (%d = %s)", res, call FatFs.ff_strerror(res));
	  return out;
	}
	else if((res = call FatFs.mkdir(dirname))){ 
	  sprintf(msgbuf, "mkdir failed for dir %s (%d = %s)", dirname, res, call FatFs.ff_strerror(res));
	  return out;
	}
      }
    }
    sprintf(filename, "%s/%04d", dirname, sequence_number++);
    res = call FatFs.fopen(&gfp, filename, (FA_OPEN_ALWAYS | FA_WRITE | FA_READ));

    sprintf(msgbuf, "data storage begun to file %s (%d = %s)", filename, res, call FatFs.ff_strerror(res));

    return out;
  }
  
  char * do_stop(char * in, char * out, char * outmax) {
    enable_storage = 0;
    stop_called = 1;

    sprintf(msgbuf, "data storage stopped");
    
    return out;
  }
  
  event result_t sampleTimer.fired() {
    call DMA0.beginTransfer();
    call DMA0.ADCbeginConversion();
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

  async event void FatFs.mediaAvailable() {
    call Leds.yellowOff();
  }

  async event void FatFs.mediaUnavailable() {
    call Leds.yellowOn();
  }

  async event void DMA0.ADCInterrupt(uint8_t regnum) {
    // we should *not* see this, as the adc interrupts are eaten by the dma controller!
  } 

  event void Client.connected( bool isConnected ) {
    /*
    if(isConnected)
     call Leds.greenOn();
    else
      call Leds.greenOff();
    */
  }

  event void NTPClient.timestampReceived( uint32_t *seconds, uint32_t *fraction ) {
    //    call Leds.yellowToggle();

    g_timer = *seconds;
    call Time.localtime(&g_timer, &g_tm);
  }

  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand operations[] = {
    { "store", &do_stores },
    { "stop", &do_stop },
    { "conv", &do_conv },
    { "stopconv", &no_conv },
    { "time", &do_time },
    { 0, NULL }
  };

  event const char * TelnetRun.token() { return "run"; }
  event const char * TelnetRun.help() { return helpmsg; }

  void assembleRunHelp() {
    const struct TelnetCommand *c = operations;
    
    sprintf(helpmsg, "Run commands: ");
    
    for ( ;c->name; c++) {
      strcat(helpmsg, c->name);
      strcat(helpmsg, " ");
    }
    strcat(helpmsg, "\n");
  }

  event char * TelnetRun.process( char * in, char * out, char * outmax ) {
    char * next, * extrastuff;
    char * cmd = next_token(in, &next, ' ');

    if(cmd) {
      const struct TelnetCommand *c = operations;
      
      for ( ;c->name; c++) {
	if (strcmp(cmd, c->name) == 0) {
	  extrastuff = (*c->func)( next, out, outmax );
	  //this is a hack to prevent hanging telnet.process if nothing is returned from service function
	  if(extrastuff)
	    out += snprintf(out, outmax - out, "%s\r\n", msgbuf);
	  else
	    out += snprintf(out, outmax - out, "%s\r\n", "dummy");
	  break;
	}
      }
    }
    else
      out += snprintf(out, outmax - out, "must provide command with 'run'\r\n");
	    
    return out;
  }
}
