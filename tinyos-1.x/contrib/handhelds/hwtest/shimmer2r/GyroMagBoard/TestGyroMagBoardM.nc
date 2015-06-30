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
 *  Author:  Steve Ayer
 *           August 2009
 *           gyromag version 
 *           March, 2010
 *           added actual -- braindead -- support for gyro to mag
 *           a real app should sample the two devices at different rates since
 *           the mag only supports low data rates (10 hz default, 50 max).  
 *           see driver for details
 *           July, 2010
 */ 

includes DMA;
includes Message;
includes NVTParse;
includes msp430baudrates;
includes math;

module TestGyroMagBoardM {
  provides{
    interface StdControl;
    interface ParamView;
  }
  uses {
    interface GyroMagBoard;
    interface StdControl as GyroMagStdControl;

    interface DMA as DMA0;

    /* telnet stuff */
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface Telnet as TelnetRun;

    interface UIP;
    interface Client; 
    interface UDPClient;

    /* end telnet stuff */
    interface Leds;

    interface Timer as sampleTimer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  void assembleRunHelp();

  uint8_t enable_shipping = 0;
  norace uint8_t current_buffer = 0, dma_blocks = 0;
  int16_t sbuf0[42], sbuf1[42], * current_dest, sample_period = 500;
  uint8_t msgbuf[128], readBuf[13], buffered;
  struct udp_address udpaddr;
  char helpmsg[128];

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

    SET_FLAG(ADC12MCTL0, INCH_1);  // x gyro
    SET_FLAG(ADC12MCTL1, INCH_6);  // y gyro
    SET_FLAG(ADC12MCTL2, INCH_2);  // z gyro
    SET_FLAG(ADC12MCTL2, EOS);       //sez "this is the last reg" 

    CLR_FLAG(ADC12CTL0, REFON);
    CLR_FLAG(ADC12MCTL0, SREF_7);             // Vref = Vref+ and Vr-
    CLR_FLAG(ADC12MCTL1, SREF_7);             // Vref = Vref+ and Vr-
    CLR_FLAG(ADC12MCTL2, SREF_7);             // Vref = Vref+ and Vr-
    
    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_1);      // single sequence of channels
    
    setupDMA();

    call DMA0.beginTransfer();
  }

  task void ship_contents() {
    if(enable_shipping){
      if(call Client.is_connected()){
	if(current_buffer == 1)
	  call UDPClient.send((uint8_t *)sbuf0, 84);
	//call UDPClient.send((uint8_t *)sbuf0, 42);  // more often
	else
	  call UDPClient.send((uint8_t *)sbuf1, 84);
	//call UDPClient.send((uint8_t *)sbuf1, 42);
      }
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
      SET_FLAG(BCSCTL2, DIVS_3);  // divide it by 8
    }
    /* 
     * end clock set up 
     */

    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    call Leds.init();

    assembleRunHelp();

    buffered = 0;

   call GyroMagStdControl.init();
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    call GyroMagStdControl.start();

    sampleADC();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call GyroMagStdControl.stop();

    call TelnetStdControl.stop();
    call IPStdControl.stop();
    return SUCCESS;
  }

  async event void GyroMagBoard.buttonPressed() {
    call GyroMagBoard.ledToggle();
  }

  result_t parse_address(char * address, 
			 uint8_t * a1,
			 uint8_t * a2,
			 uint8_t * a3,
			 uint8_t * a4) {
    char * scout, * period;
    char buffer[64];
    uint8_t offset;

    scout = address;
    if((period = strchr(scout, '.'))){
      offset = period - scout;
      memcpy(buffer, scout, offset);
      buffer[offset] = '\0';
      *a1 = atoi(buffer);
      scout += offset + 1;

      if((period = strchr(scout, '.'))){
	offset = period - scout;
	memcpy(buffer, scout, offset);
	buffer[offset] = '\0';
	*a2 = atoi(buffer);
	scout += offset + 1;
      }
      if((period = strchr(scout, '.'))){
	offset = period - scout;
	memcpy(buffer, scout, offset);
	buffer[offset] = '\0';
	*a3 = atoi(buffer);
	scout += offset + 1;
      }
      strcpy(buffer, scout);
      *a4 = atoi(buffer);
      
      return SUCCESS;
    }
    else
      return FAIL;
  }

  event void GyroMagBoard.magWriteDone(result_t success){
  }

  char * do_conv(char * in, char * out, char * outmax) { 
    call GyroMagBoard.magRunContinuousConversion();

    sample_period = atoi(in);

    if(sample_period < 100)  // this part takes at least 100ms to measure
      sample_period = 100; 

    sprintf(msgbuf, "requested sample period %d ms (%d hz)", sample_period, 1000/sample_period);

    if(current_buffer == 0)
      current_dest = sbuf0 + 3;
    else
      current_dest = sbuf1 + 3;

    call sampleTimer.start(TIMER_REPEAT, sample_period);

    return out;
  }

  char * do_led(char * in, char * out, char * outmax) { 
    call GyroMagBoard.ledToggle();
    return out;
  }
  char * do_noled(char * in, char * out, char * outmax) { 
    call GyroMagBoard.ledOff();
    return out;
  }

  char * no_conv(char * in, char * out, char * outmax) { 
    call GyroMagBoard.setMagIdle();
    sprintf(msgbuf, "sampling at %d hz stopped", 1000/sample_period);

    call sampleTimer.stop();

    return out;
  }

    
  char * do_sends(char * in, char * out, char * outmax) { 
    udpaddr.port = 5067;

    if(!enable_shipping){
      if(parse_address(in, 
		       &udpaddr.ip[0], 
		       &udpaddr.ip[1], 
		       &udpaddr.ip[2], 
		       &udpaddr.ip[3]) == FAIL){
	udpaddr.ip[0] = 173;
	udpaddr.ip[1] = 9;
	udpaddr.ip[2] = 95;
	udpaddr.ip[3] = 161;
      }
      sprintf(msgbuf, "requested connection to %d.%d.%d.%d", udpaddr.ip[0], udpaddr.ip[1], udpaddr.ip[2], udpaddr.ip[3]);

      enable_shipping = 1;
      call UDPClient.connect(&udpaddr);
    }

    return out;
  }
  
  char * do_stop(char * in, char * out, char * outmax) {
    enable_shipping = 0;
    call UDPClient.connect(NULL);
    sprintf(msgbuf, "requested connection closed");
    
    return out;
  }
  
  char * do_gyro(char * in, char * out, char * outmax) {
    call GyroMagStdControl.init();
    call GyroMagStdControl.start();

    return out;
  }
  
  char * do_nogyro(char * in, char * out, char * outmax) {
    call GyroMagStdControl.stop();

    return out;
  }
  
  event void UDPClient.sendDone() {
    //    enable_shipping = 1;
  }

  event    void     UDPClient.receive(const struct udp_address *addr, uint8_t *buf, uint16_t len) {}

  int16_t twos_comp_convert(uint8_t up, uint8_t low) 
  {
    int16_t out;
    uint16_t uout;
    
    uout = up;
    uout = uout << 8;
    uout |= low;

    out = (int16_t)uout;

    return out;
  }

  /*
   * note from honeywell app note:
   * Heading for 
   * for (Xh <0) = 180 - arcTan(Yh/Xh)
   * for (Xh >0, Yh <0) = - arcTan(Yh/Xh)
   * for (Xh >0, Yh >0) = 180 + arcTan(Yh/Xh)
   * for (Xh =0, Yh <0) = 90
   * for (Xh =0, Yh >0) = 270
   *
   * ABOVE IS WIKKID WRONG!
   *
   * here's the dope:
   * subtle line in data sheet shows axis orientation with normal pointing out
   * the BOTTOM of the chipset.  so, for readings to make sense, the sign of normal
   * has to be considered.  with shimmer upside down, z is positive; shimmer-side up
   * z < 0.  so the heading is:
   *
   * for (Xh = 0, Yh < 0) = 270
   * for (Xh = 0, Yh > 0) = 90
   * when z > 0 (shimmer upside down, chip bottom away from earth center)
   *  180 - arcTan(Yh/Xh)
   * when z < 0:
   *  180 - arcTan(Yh/-Xh)
   */

  uint16_t mag_to_heading(uint16_t x, uint16_t y, uint16_t z)
  {
    uint16_t heading;

    if(x == 0){
      if(y < 0)
	heading = 270;
      else
	heading = 90;
    }
    else if(z < 0)
      heading = (uint16_t)(180.0 - atanf((float)y/(float)-x));

    else
      heading = (uint16_t)(180.0 - atanf((float)y/(float)x));
    
    return heading;
  }

  task void collect_results() {
    int16_t realVals[3];
    uint16_t heading;

    call GyroMagBoard.convertMagRegistersToData(readBuf, realVals);
    heading = call GyroMagBoard.readMagHeading(readBuf);
    /*
     * this for shipping raw vals
     */
    memcpy(current_dest, realVals, 6);
    current_dest += 6;  // 16-bit pointer
    /*
     * substitute this for heading only 
     * *current_dest++ = heading;
     * if(buffered == 21){
    */
    buffered++;
    if(buffered == 7){
      buffered = 0;
      if(current_buffer == 0){
	current_dest = sbuf1 + 3;
	current_buffer = 1;
      }
      else{
	current_dest = sbuf0 + 3;
	current_buffer = 0;
      }
      post ship_contents();
    }
  }

  event void GyroMagBoard.magReadDone(uint8_t * data, result_t success){
    memcpy(readBuf, data, 7);
    post collect_results();
  }
  
  task void clockin_result(){
    call GyroMagBoard.readMagData();
  }

  event result_t sampleTimer.fired() {
    //    call DMA0.beginTransfer();
    //    call DMA0.ADCbeginConversion();

    post clockin_result();

    return SUCCESS;
  }

  async event void DMA0.transferComplete() {
    dma_blocks++;

    atomic DMA0DA += 12;
    if(dma_blocks == 7){
      dma_blocks = 0;

      if(current_buffer == 0){
	atomic DMA0DA = (uint16_t)&sbuf1[0];
	current_buffer = 1;
      }
      else { 
	atomic DMA0DA = (uint16_t)&sbuf0[0];
	current_buffer = 0;
      }
      post clockin_result();
      //      post ship_contents();
    }
  }

  async event void DMA0.ADCInterrupt(uint8_t regnum) {
    // we should *not* see this, as the adc interrupts are eaten by the dma controller!
  } 

  event void Client.connected( bool isConnected ) {
  }

  const struct Param s_i2cregOutput[] = {
    { "u0ctl",   PARAM_TYPE_HEX8, (uint8_t *)&U0CTL },
    { "i2ctctl", PARAM_TYPE_HEX8, (uint8_t *)&I2CTCTL },
    { "i2cdctl", PARAM_TYPE_HEX8, (uint8_t *)&I2CDCTL },
    { "i2cndat", PARAM_TYPE_HEX8, (uint8_t *)&I2CNDAT },
    { "i2cdr", PARAM_TYPE_HEX8, (uint8_t *)&I2CDR },
    { "i2csa", PARAM_TYPE_HEX8, (uint8_t *)&I2CSA },
    { "i2cie", PARAM_TYPE_HEX8, (uint8_t *)&I2CIE },
    { "i2cifg", PARAM_TYPE_HEX8, (uint8_t *)&I2CIFG },
    { "i2civ", PARAM_TYPE_HEX8, (uint8_t *)&I2CIV },
    { NULL, 0, NULL }
  };
  struct ParamList g_regOutList = { "registers", &s_i2cregOutput[0] };

  command result_t ParamView.init(){
    signal ParamView.add( &g_regOutList );

    return SUCCESS;
  }

  char * do_write(char * in, char * out, char * outmax) { 
    uint8_t addr, data;
    char * next, * tok, * dummy;

    tok = next_token(in, &next, ' ');
    addr = strtoul(tok, &dummy, 16);

    tok = next_token(next, &next, ' ');
    data = strtoul(tok, &dummy, 16);

    sprintf(msgbuf, "wrote %02x %02x to mag", addr, data);
    // no longer in interface...
    call GyroMagBoard.writeReg(addr, data);

    return out;
  }

  char * do_read(char * in, char * out, char * outmax) { 
    uint8_t size;  //we only have six reg values max
    char * next, * tok, * dummy;

    tok = next_token(in, &next, ' ');
    size = strtoul(tok, &dummy, 16);

    if(size > 8)
      size = 8;

    memset(readBuf, 0, 8);
    sprintf(msgbuf, "reading %d bytes", size);
    // no longer in interface
    //    call GyroMagBoard.readValues(size, readBuf);
    // but this does the same thing
    call GyroMagBoard.readMagData();

    return out;
  }

  char * do_readdone(char * in, char * out, char * outmax) { 
    register uint8_t i;
    uint8_t * src, * dest;
    int16_t realVals[3], x, y, z;
    uint16_t heading;

    src = readBuf;
    // this loop is just for the three 16-bit x,y,z values
    *msgbuf = 0;
    for(i = 0; i < 3; i++){
      dest = msgbuf + strlen(msgbuf);
      realVals[i] = twos_comp_convert(*src, *(src + 1));

      sprintf(dest, "%d ", realVals[i]);
      src += 2;
    }
    /*
    x = *realVals;
    y = *(realVals + 1);
    z = *(realVals + 2);
    heading = mag_to_heading(x, y, z);

    dest = msgbuf + strlen(msgbuf);
    sprintf(dest, "heading = %d ", heading);
    *
    //    howmany = 0;
    //    memset(readBuf, 0, 13);
    */
    return out;
  }

  
  char * do_testit(char * in, char * out, char * outmax) { 
    call GyroMagBoard.magSelfTest();
    return out;
  }

  char * do_poke(char * in, char * out, char * outmax) { 
    uint8_t data;
    char * next, * tok, * dummy;
    
    tok = next_token(in, &next, ' ');
    data = strtoul(tok, &dummy, 10);

    sprintf(msgbuf, "mode %d", data);

    if(data == 2)
      call GyroMagBoard.setMagIdle();
    else  if(data == 3)
      call GyroMagBoard.magGoToSleep();

    return out;
  }

  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand operations[] = {
    { "write", &do_write },
    { "testit", &do_testit },
    { "result", &do_readdone },
    { "poke", &do_poke },
    { "read", &do_read },
    { "ship", &do_sends },
    { "stop", &do_stop },
    { "gyro", &do_gyro },
    { "nogyro", &do_nogyro },
    { "stream", &do_conv },
    { "led", &do_led },
    { "noled", &do_noled },
    { "stopconv", &no_conv },
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
