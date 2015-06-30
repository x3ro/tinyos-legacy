/*
 * Copyright (c) 2006, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Steve Ayer
 *          August 2006
 */

includes DMA;
includes Message;
includes NVTParse;
includes MMA7260_Accel;
includes msp430baudrates;

module GyroAccelAppM {
  provides{
    interface StdControl;
    interface ParamView;
  }
  uses {
    interface DMA as DMA0;
    interface DMA as DMA1;
    interface DMA as DMA2;

    /* telnet stuff */
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface StdControl as ClientStdControl;

    interface StdControl as AccelStdControl;

    interface MMA7260_Accel as Accel;

    interface Telnet as TelnetRun;

    interface UIP;
    interface Client; 
    interface TCPClient;

    /* end telnet stuff */
    interface Leds;

    interface Timer as yTimer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

#define MAX_SIZE 512
#define PACKET_PAYLOAD 128
#define MESSAGE_MAX_LENGTH 128

  uint8_t myreason = 0, enable_shipping = 0, enable_gyros = 0, adcregnum;
  uint16_t inbuf0[128], inbuf1[128], inbuf2[128], *curr0, *curr1, *curr2;
  uint16_t abuf[6], gbuf[3];
  norace uint16_t dma_transfers;
  uint8_t msgbuf[128];

  uint16_t adcifg_count = 0;

  void setupDMA() {
    call DMA0.init();
    call DMA1.init();
    call DMA2.init();

    atomic {
      call DMA0.setDestinationAddress(&abuf[0]);
      call DMA1.setDestinationAddress(&abuf[1]);
      call DMA2.setDestinationAddress(&abuf[2]);

      SET_FLAG(DMA0CTL, DMADSTINCR_0);   // hold the destination address still
      SET_FLAG(DMA1CTL, DMADSTINCR_0);
      SET_FLAG(DMA2CTL, DMADSTINCR_0);

      call DMA0.setBlockSize(1);
      call DMA1.setBlockSize(1);
      call DMA2.setBlockSize(1);

      SET_FLAG(DMACTL1, ROUNDROBIN);  // round-robin
    }
  }
	
  void sampleADC() {
    call DMA0.ADCinit();   // this doesn't really need to be parameterized

    atomic{
      CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
      SET_FLAG(ADC12CTL1, ADC12SSEL_1);         // clk from aclk
      
      SET_FLAG(ADC12CTL1, ADC12DIV_0);         // divide clk by 8
      // sample and hold time four adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   

      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }


    SET_FLAG(ADC12MCTL0, INCH_5);  // x accel
    SET_FLAG(ADC12MCTL1, INCH_4);  // y accel
    SET_FLAG(ADC12MCTL2, INCH_3);  // z accel
    SET_FLAG(ADC12MCTL3, INCH_1);  // x accel
    SET_FLAG(ADC12MCTL4, INCH_6);  // y accel
    SET_FLAG(ADC12MCTL5, INCH_2);  // z accel
    SET_FLAG(ADC12MCTL5, EOS);       // sez "this is the last reg" 

    //    SET_FLAG(ADC12MCTL5, EOS);       //sez "this is the last reg" 

    SET_FLAG(ADC12MCTL3, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL4, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL5, SREF_1);             // Vref = Vref+ and Vr-
    
    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_3);      // repeat sequence of channels
    /*
    SET_FLAG(ADC12MCTL6, INCH_11);       // (avcc - avss)/2
    SET_FLAG(ADC12MCTL6, SREF_1);        //  ref = vref+ and vr- = avss
    SET_FLAG(ADC12MCTL6, EOS);       // sez "this is the last reg" 
    */

    setupDMA();

    call DMA0.beginTransfer();
    call DMA1.beginTransfer();
    call DMA2.beginTransfer();


    call DMA0.ADCbeginConversion();
	
    *curr0 = ADC12MEM0;
    *curr0 = 0;
    *curr1 = ADC12MEM1;
    *curr1 = 0;
    *curr2 = ADC12MEM2;
    *curr2 = 0;
    *curr0 = ADC12MEM3;
    *curr0 = 0;
    *curr1 = ADC12MEM4;
    *curr1 = 0;
    *curr2 = ADC12MEM5;
    *curr2 = 0;

  }

  task void ship_contents() {
    if(enable_shipping)
      call TCPClient.write((uint8_t *)abuf, 12);
  }

  task void adc3Results() { 
    atomic gbuf[0] = ADC12MEM3;
    SET_FLAG(ADC12IE, 0x0038);
  } 

  task void adc4Results() { 
    atomic gbuf[1] = ADC12MEM4;
    SET_FLAG(ADC12IE, 0x0038);
  } 

  task void adc5Results() { 
  } 

  task void dma0Results() { 
  }	 
    
  task void dma1Results() { 
  }	 
    
  task void dma2Results() { 
    /*
      atomic{
      abuf[0] = inbuf0[dma_transfers];
      abuf[1] = inbuf1[dma_transfers];
      abuf[2] = inbuf2[dma_transfers];
    }

    dma_transfers++;

    if(dma_transfers == 128){
      call DMA0.ADCstopConversion();

      dma_transfers = 0;
      
      DMA0DA = (uint16_t)inbuf0;
      DMA1DA = (uint16_t)inbuf1;
      DMA2DA = (uint16_t)inbuf2;

      call DMA0.ADCbeginConversion();
    }
    */
    SET_FLAG(ADC12IE, 0x0008);
  }	
    
  command result_t StdControl.init() {
    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    call AccelStdControl.init();

    dma_transfers = 0;
    
    // pins for gyro, gyro enable
    TOSH_MAKE_ADC_1_INPUT();   // x
    TOSH_MAKE_ADC_2_INPUT();   // z
    TOSH_MAKE_ADC_6_INPUT();   // y

    TOSH_SEL_ADC_1_MODFUNC();
    TOSH_SEL_ADC_2_MODFUNC();
    TOSH_SEL_ADC_6_MODFUNC();

    TOSH_MAKE_PROG_OUT_OUTPUT();
    TOSH_SEL_PROG_OUT_IOFUNC();

    memset(inbuf0, 0, sizeof(inbuf0));
    curr0 = inbuf0;
    memset(inbuf1, 0, sizeof(inbuf1));
    curr1 = inbuf1;
    memset(inbuf2, 0, sizeof(inbuf2));
    curr2 = inbuf2;
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    call AccelStdControl.start();

    call Accel.setSensitivity(RANGE_4_0G);

    sampleADC();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  char * do_id(char * in, char * out, char * outmax) { 
  }
  char * do_gyros(char * in, char * out, char * outmax) { 
    if(!enable_gyros){
      TOSH_CLR_PROG_OUT_PIN();   // turn on, logical false
      enable_gyros = 1;
    }
    else{
      TOSH_SET_PROG_OUT_PIN();
      enable_gyros = 0;
    }
    return out;
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

  char * do_sends(char * in, char * out, char * outmax) { 
    uint8_t a1, a2, a3, a4;

    if(!enable_shipping){
      if(parse_address(in, &a1, &a2, &a3, &a4) == FAIL){
	a1 = 63;
	a2 = 118;
	a3 = 194;
	a4 = 100;
      }
      sprintf(msgbuf, "requested connection to %d %d %d %d", a1, a2, a3, a4);

      call Leds.yellowOn();
      call TCPClient.connect(a1, a2, a3, a4, 5067);
    }
    else{
      enable_shipping = 0;
      call TCPClient.close();
      call Leds.yellowOff();
      call Leds.greenOff();
      sprintf(msgbuf, "requested connection closed");
    }

    return out;
  }
  
  event void TCPClient.connectionMade(uint8_t status) {
    call Leds.greenOn();
    call Leds.yellowOff();

    enable_shipping = 1;
  }  

  event void TCPClient.writeDone() {
  }

  event    void     TCPClient.dataAvailable(uint8_t *buf, uint16_t len) {}

  event    void     TCPClient.connectionFailed(uint8_t reason) { 
    myreason = reason;
  }

  event result_t yTimer.fired() {
    return SUCCESS;
  }

  async event void DMA0.transferComplete() {
    //    atomic DMA0DA += 2;
  }

  async event void DMA1.transferComplete() {
    //    atomic DMA1DA += 2;
  }

  async event void DMA2.transferComplete() {
    //    atomic DMA2DA += 2;

    SET_FLAG(ADC12IE, 0x0008);
    //    call Leds.redToggle();
    //    post dma2Results();
  }

  async event void DMA0.ADCInterrupt(uint8_t regnum) {
    atomic  abuf[3] = ADC12MEM3;
    ADC12IE = 0x0010;
  } 
  async event void DMA1.ADCInterrupt(uint8_t regnum) {
    atomic abuf[4] = ADC12MEM4;
    ADC12IE = 0x0020;
  }
  async event void DMA2.ADCInterrupt(uint8_t regnum) {
    atomic abuf[5] = ADC12MEM5;
    ADC12IE = 0;
    //    call Leds.greenToggle();
    post ship_contents();
  }

  event void Client.connected( bool isConnected ) {}

  const struct Param s_ADCRegs[] = {
    { "ivregnum",     PARAM_TYPE_HEX8,  (uint8_t *)&adcregnum },
    { "adcctl0",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12CTL0 },
    { "adcctl1",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12CTL1 },
    { "adcmem3",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM3},
    { "adcmem4",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM4},
    { "adcmem5",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM5},
    { "adc<-battery",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM6},
    { "adcmemctl3",    PARAM_TYPE_HEX8, (uint8_t *)&ADC12MCTL3},
    { "adcmemctl4",    PARAM_TYPE_HEX8, (uint8_t *)&ADC12MCTL4},
    { "adcmemctl5",    PARAM_TYPE_HEX8, (uint8_t *)&ADC12MCTL5},
    { "adciv",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12IV},
    { "adcifg",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12IFG},
    { "adcie",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12IE},
    { "adcifgcount",    PARAM_TYPE_HEX16, (uint16_t *)&adcifg_count},
    { NULL, 0, NULL }
  };

  const struct Param s_DMA0Output[] = {
    { "dma transfers",   PARAM_TYPE_UINT8, &dma_transfers },
    { "error_reason",   PARAM_TYPE_UINT8, &myreason },
    { "a0",    PARAM_TYPE_UINT16, (uint16_t *)&abuf[0] },
    { "a1",    PARAM_TYPE_UINT16, (uint16_t *)&abuf[1] },
    { "a2",    PARAM_TYPE_UINT16, (uint16_t *)&abuf[2] },
    { "g0",    PARAM_TYPE_UINT16, (uint16_t *)&abuf[3] },
    { "g1",    PARAM_TYPE_UINT16, (uint16_t *)&abuf[4] },
    { "g2",    PARAM_TYPE_UINT16, (uint16_t *)&abuf[5] },
    { NULL, 0, NULL }
  };
  struct ParamList g_DMA0OutList = { "output0", &s_DMA0Output[0] };
  struct ParamList g_ADCRegsList = { "adcregs", &s_ADCRegs[0] };

  const struct Param s_msg[] = {
    { "msg",    PARAM_TYPE_STRING, &msgbuf[0] },
    { NULL, 0, NULL }
  };
  struct ParamList msgList = { "msgs", &s_msg[0] };

  command result_t ParamView.init(){
    signal ParamView.add( &msgList );
    signal ParamView.add( &g_DMA0OutList );
    signal ParamView.add( &g_ADCRegsList );
    return SUCCESS;
  }
  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand operations[] = {
    { "ship", &do_sends },
    { "gyro", &do_gyros },
    { 0, NULL }
  };
 
  event const char * TelnetRun.token() { return "run"; }
  event const char * TelnetRun.help() { return "Run network operations\r\n"; }
    
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
