/*
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
 * @author Steve Ayer
 * @date   May, 2010
 *
 * this samples the voltage monitor muxes to determine the voltage drop across 
 * a calibrated diode inline with the battery supply to determine a) current battery 
 * voltage, and b) momentary current draw by applying the diode's spec for 
 * voltage drop vs. current flow.
 */

includes DMA;
includes Message;
includes NVTParse;
//includes msp430baudrates;

module TestVoltageMonitorM {
  provides{
    interface StdControl;
    interface ParamView;
  }
  uses {
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
  uint16_t sbuf0[42], sbuf1[42], dmadain, sample_period = 5;
  uint8_t msgbuf[128];
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
    call DMA0.setBlockSize(2);

    // we want block transfer, single
    DMA0CTL = DMADT_1 + DMADSTINCR_3 + DMASRCINCR_3;
  }
	
  void sampleADC() {
    call DMA0.ADCinit();   // this doesn't really need to be parameterized

    atomic{
      CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
      SET_FLAG(ADC12CTL1, ADC12SSEL_3);        
      
      SET_FLAG(ADC12CTL1, ADC12DIV_0);         
      // sample and hold time four adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   
      
      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }
    
    SET_FLAG(ADC12MCTL0, INCH_7);  // battery voltage
    SET_FLAG(ADC12MCTL1, INCH_0);  // post-diode regulator voltage
    SET_FLAG(ADC12MCTL1, EOS);       //sez "this is the last reg" 

    // we'll use avcc as a reference
    CLR_FLAG(ADC12CTL0, REFON);               // turn internal ref off
    CLR_FLAG(ADC12MCTL0, SREF_7);             // VR+ = AVCC and VR- = AVSS
    CLR_FLAG(ADC12MCTL1, SREF_7);             // VR+ = AVCC and VR- = AVSS
    
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
	else
	  call UDPClient.send((uint8_t *)sbuf1, 84);
      }
    }
  }
  
  command result_t StdControl.init() {
    /* 
     * set up 8mhz clock to max out 
     * msp430 throughput 
     *
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
    * 
     * end clock set up 
     */

    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    TOSH_MAKE_ADC_7_INPUT();   // battery
    TOSH_MAKE_ADC_0_INPUT();   // regulator

    TOSH_SEL_ADC_7_MODFUNC();
    TOSH_SEL_ADC_0_MODFUNC();

    call Leds.init();

    assembleRunHelp();

    dma_blocks = 0;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    TOSH_SET_PWRMUX_SEL_PIN();   // switches adc7 and 0 to sense battery/regulator diodes

    sampleADC();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
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

  char * do_leds(char * in, char * out, char * outmax) { 
    uint8_t which;

    which = atoi(in);

    sprintf(msgbuf, "turning on leds %d", which);

    call Leds.set(which);

    return out;
  }

  char * kill_leds(char * in, char * out, char * outmax) { 
    sprintf(msgbuf, "turning off leds");

    call Leds.set(0);

    return out;
  }

  char * do_conv(char * in, char * out, char * outmax) { 
    //    atomic dmadain = (uint16_t)DMA0DA;

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
  
  event void UDPClient.sendDone() {
    //    enable_shipping = 1;
  }

  event    void     UDPClient.receive(const struct udp_address *addr, uint8_t *buf, uint16_t len) {}

  event result_t sampleTimer.fired() {
    call DMA0.beginTransfer();
    call DMA0.ADCbeginConversion();
    return SUCCESS;
  }

  async event void DMA0.transferComplete() {
    dma_blocks++;
    atomic DMA0DA += 4;
    if(dma_blocks == 21){
      dma_blocks = 0;

      if(current_buffer == 0){
	atomic DMA0DA = (uint16_t)&sbuf1[0];

	current_buffer = 1;
      }
      else { 
	atomic DMA0DA = (uint16_t)&sbuf0[0];

	current_buffer = 0;
      }
      post ship_contents();
    }
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

  const struct Param s_DMA0Output[] = {
    { "dma transfers",   PARAM_TYPE_UINT8, &dma_blocks },
    { "0",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[0] },
    { "1",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[1] },
    { "2",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[2] },
    { "3",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[3] },
    { "4",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[4] },
    { "5",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[5] },
    { "6",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[6] },
    { "7",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[7] },
    { "8",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[8] },
    { "9",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[9] },
    { "10",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[10] },
    { "11",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[11] },
    { "12",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[12] },
    { "13",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[13] },
    { "14",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[14] },
    { "15",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[15] },
    { "16",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[16] },
    { "17",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[17] },
    { NULL, 0, NULL }
  };

  const struct Param s_DMA0Output1[] = {
    { "18",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[18] },
    { "19",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[19] },
    { "20",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[20] },
    { "21",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[21] },
    { "22",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[22] },
    { "23",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[23] },
    { "24",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[24] },
    { "25",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[25] },
    { "26",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[26] },
    { "27",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[27] },
    { "28",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[28] },
    { "29",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[29] },
    { "30",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[30] },
    { "31",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[31] },
    { "32",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[32] },
    { "33",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[33] },
    { "34",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[34] },
    { "35",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf0[35] },
    { NULL, 0, NULL }
  };
  struct ParamList g_DMA0OutList = { "output", &s_DMA0Output[0] };
  struct ParamList g_DMA0Out1List = { "output1", &s_DMA0Output1[0] };

  const struct Param s_DMA0Output2[] = {
    { "dma transfers",   PARAM_TYPE_UINT8, &dma_blocks },
    { "0",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[0] },
    { "1",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[1] },
    { "2",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[2] },
    { "3",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[3] },
    { "4",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[4] },
    { "5",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[5] },
    { "6",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[6] },
    { "7",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[7] },
    { "8",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[8] },
    { "9",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[9] },
    { "10",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[10] },
    { "11",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[11] },
    { "12",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[12] },
    { "13",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[13] },
    { "14",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[14] },
    { "15",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[15] },
    { "16",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[16] },
    { "17",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[17] },
    { NULL, 0, NULL }
  };

  const struct Param s_DMA0Output3[] = {
    { "18",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[18] },
    { "19",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[19] },
    { "20",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[20] },
    { "21",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[21] },
    { "22",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[22] },
    { "23",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[23] },
    { "24",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[24] },
    { "25",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[25] },
    { "26",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[26] },
    { "27",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[27] },
    { "28",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[28] },
    { "29",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[29] },
    { "30",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[30] },
    { "31",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[31] },
    { "32",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[32] },
    { "33",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[33] },
    { "34",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[34] },
    { "35",    PARAM_TYPE_HEX16, (uint16_t *)&sbuf1[35] },
    { NULL, 0, NULL }
  };
  struct ParamList g_DMA0Out2List = { "output2", &s_DMA0Output2[0] };
  struct ParamList g_DMA0Out3List = { "output3", &s_DMA0Output3[0] };

  const struct Param s_DMARegs[] = {
    { "dmadaIN",      PARAM_TYPE_HEX16, (uint16_t *)&dmadain},
    { "dma0daOUT",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0DA},
    { "adc12mem0",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM0},
    { "adc12mem1",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM1},
    { "adc12mem2",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM2},
    { "adc12mem3",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM3},
    { "adc12mem4",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM4},
    { "adc12mem5",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM5},
    { NULL, 0, NULL }
  };
  struct ParamList g_DMARegsList = { "dmaregs", &s_DMARegs[0] };

  const struct Param s_msg[] = {
    { "msg",    PARAM_TYPE_STRING, &msgbuf[0] },
    { NULL, 0, NULL }
  };
  struct ParamList msgList = { "msgs", &s_msg[0] };
  command result_t ParamView.init(){
    signal ParamView.add( &msgList );
    signal ParamView.add( &g_DMA0OutList );
    signal ParamView.add( &g_DMA0Out1List );
    signal ParamView.add( &g_DMA0Out2List );
    signal ParamView.add( &g_DMA0Out3List );
    signal ParamView.add( &g_DMARegsList );

    return SUCCESS;
  }

  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand operations[] = {
    { "ship", &do_sends },
    { "stop", &do_stop },
    { "conv", &do_conv },
    { "stopconv", &no_conv },
    { "leds", &do_leds },
    { "noleds", &kill_leds },
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
