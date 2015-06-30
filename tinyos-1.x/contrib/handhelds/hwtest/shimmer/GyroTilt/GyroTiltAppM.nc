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
//includes SD;
includes msp430baudrates;

module GyroTiltAppM {
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

    interface StdControl as SDStdControl;

    interface SD;

    interface Telnet as TelnetRun;

    interface UIP;
    interface Client; 
    interface TCPClient;
    interface UDPClient;

    interface LocalTime;
    

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

  uint8_t dma_transfers, myreason = 0, enable_shipping = 0, enable_gyros = 0, write_step;
  norace uint8_t current_buffer = 0;
  uint16_t sbuf0[36], sbuf1[36];
  uint8_t msgbuf[128], sectornum = 0, shipnum = 0;
  //  uint16_t cardbuf[256];
  //  norace uint32_t current_sector = 2222, shipping_sector;
  struct udp_address udpaddr;
  
  void setupDMA() {
    call DMA0.init();
    call DMA1.init();
    call DMA2.init();

    call DMA0.setDestinationAddress((uint16_t)&sbuf0[0]);
    call DMA1.setDestinationAddress((uint16_t)&sbuf0[12]);
    call DMA2.setDestinationAddress((uint16_t)&sbuf0[24]);

    call DMA0.setBlockSize(12);
    call DMA1.setBlockSize(12);
    call DMA2.setBlockSize(12);
    /*    
    CLR_FLAG(DMA0CTL, DMADSTINCR_3);    // clear increment (doesn't work?) for manual increment
    CLR_FLAG(DMA1CTL, DMADSTINCR_3);
    CLR_FLAG(DMA2CTL, DMADSTINCR_3);

    SET_FLAG(DMA0CTL, DMADSTINCR_0);    // non-increment for manual increment
    SET_FLAG(DMA1CTL, DMADSTINCR_0);
    SET_FLAG(DMA2CTL, DMADSTINCR_0);
    */
    SET_FLAG(DMACTL1, ROUNDROBIN);  // round-robin
  }
	
  void sampleADC() {
    call DMA0.ADCinit();   // this doesn't really need to be parameterized

    atomic{
      CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
      SET_FLAG(ADC12CTL1, ADC12SSEL_1);         // clk from aclk
      
      SET_FLAG(ADC12CTL1, ADC12DIV_0);         // with ekg, _3 is about 180hz, _2 ~= 210 hz, _1 ~= 320 hz, _0 ~= 640 hz
      // sample and hold time four adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   
      
      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }

    SET_FLAG(ADC12MCTL0, INCH_1);  // x 
    SET_FLAG(ADC12MCTL1, INCH_6);  // y 
    SET_FLAG(ADC12MCTL2, INCH_2);  // z 
    SET_FLAG(ADC12MCTL2, EOS);       //sez "this is the last reg" 

    SET_FLAG(ADC12MCTL0, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL1, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL2, SREF_1);             // Vref = Vref+ and Vr-
    
    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_3);      // repeat sequence of channels
    
    setupDMA();

    call DMA0.beginTransfer();
    call DMA1.beginTransfer();
    call DMA2.beginTransfer();

    call DMA0.ADCbeginConversion();
  }

  
  task void ship_contents() {
    if(enable_shipping){
      enable_shipping = 0;
      if(current_buffer == 1)
	call UDPClient.send((uint8_t *)sbuf0, 72);
      //	call TCPClient.write((uint8_t *)sbuf0, 72);
      else
	call UDPClient.send((uint8_t *)sbuf1, 72);
      //	call TCPClient.write((uint8_t *)sbuf1, 72);
    }
  }
  
  task void adcResults() { 
  } 

  task void dma0Results() { 
  }	 
    
  task void dma1Results() { 
  }	 
    
  task void dma2Results() { 
  }	

  command result_t StdControl.init() {
    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    //    call SDStdControl.init();

    dma_transfers = 0;
    
    // pins for gyro, gyro enable
    TOSH_MAKE_ADC_1_INPUT();   // x
    TOSH_MAKE_ADC_2_INPUT();   // z
    TOSH_MAKE_ADC_6_INPUT();   // y

    TOSH_SEL_ADC_1_MODFUNC();
    TOSH_SEL_ADC_2_MODFUNC();
    TOSH_SEL_ADC_6_MODFUNC();
    /*
    TOSH_MAKE_PROG_OUT_OUTPUT();
    TOSH_SEL_PROG_OUT_IOFUNC();

    // pins for tilt switches 
    TOSH_MAKE_SER0_CTS_INPUT();   // tiltzy_n:  when enabled, this means that this switch is upright
    TOSH_MAKE_SOMI0_INPUT();      // tiltxy_n:  ditto
    TOSH_MAKE_UTXD0_INPUT();      // tiltxy_ccw: when disabled (logical false), this switch is tilted "left"
    TOSH_MAKE_URXD0_INPUT();      // tiltzy_ccw: when disabled (logical false), this switch is tilted "left"

    TOSH_SEL_SER0_CTS_IOFUNC();
    TOSH_SEL_SOMI0_IOFUNC();
    TOSH_SEL_UTXD0_IOFUNC();
    TOSH_SEL_URXD0_IOFUNC();
    */
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    //    call SDStdControl.start();

    TOSH_CLR_PROG_OUT_PIN();   // this pin is gyro pwren, logical false

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

  char * do_sends(char * in, char * out, char * outmax) { 
    udpaddr.port = 5067;

    if(!enable_shipping){
      if(parse_address(in, 
		       &udpaddr.ip[0], 
		       &udpaddr.ip[1], 
		       &udpaddr.ip[2], 
		       &udpaddr.ip[3]) == FAIL){
	udpaddr.ip[0] = 63;
	udpaddr.ip[1] = 118;
	udpaddr.ip[2] = 194;
	udpaddr.ip[3] = 100;
      }
      sprintf(msgbuf, "requested connection to %d.%d.%d.%d", udpaddr.ip[0], udpaddr.ip[1], udpaddr.ip[2], udpaddr.ip[3]);

      //      call TCPClient.connect(udpaddr.ip[0], udpaddr.ip[1], udpaddr.ip[2], udpaddr.ip[3], udpaddr.port);
      enable_shipping = 1;
      call UDPClient.connect(&udpaddr);
    }
    else{
      enable_shipping = 0;
      sprintf(msgbuf, "requested connection closed");
      //      call TCPClient.close();
      call UDPClient.connect(NULL);
      call Leds.greenOff();
    }
    return out;
  }
  
  event void TCPClient.connectionMade(uint8_t status) {
    call Leds.greenOn();
    
    enable_shipping = 1;
    //    post ship_contents();
  }  

  event void UDPClient.sendDone() {
    enable_shipping = 1;
  }
  event void TCPClient.writeDone() {
  }

  event    void     TCPClient.dataAvailable(uint8_t *buf, uint16_t len) {}

  event    void     UDPClient.receive(const struct udp_address *addr, uint8_t *buf, uint16_t len) {}

  event    void     TCPClient.connectionFailed(uint8_t reason) { 
    myreason = reason;
  }

  event result_t yTimer.fired() {
    return SUCCESS;
  }

  async event void DMA0.transferComplete() {
  }

  async event void DMA1.transferComplete() {
  }

  async event void DMA2.transferComplete() {
    if(current_buffer == 0){
      atomic{
	DMA0DA = (uint16_t)&sbuf1[0];
	DMA1DA = (uint16_t)&sbuf1[12];
	DMA2DA = (uint16_t)&sbuf1[24];
      }
      current_buffer = 1;
    }
    else { 
      atomic{
	DMA0DA = (uint16_t)&sbuf0[0];
	DMA1DA = (uint16_t)&sbuf0[12];
	DMA2DA = (uint16_t)&sbuf0[24];
      }
      current_buffer = 1;
    }
    post ship_contents();
  }

  async event void DMA0.ADCInterrupt(uint8_t regnum) {
  } 
  async event void DMA1.ADCInterrupt(uint8_t regnum) {}
  async event void DMA2.ADCInterrupt(uint8_t regnum) {}

  event void Client.connected( bool isConnected ) {
  }
  const struct Param s_DMA0Output[] = {
    { "dma transfers",   PARAM_TYPE_UINT8, &dma_transfers },
    { "error_reason",   PARAM_TYPE_UINT8, &myreason },
  /*

    { "0",    PARAM_TYPE_UINT16, (uint16_t *)&sbuf0[0] },
    { "1",    PARAM_TYPE_UINT16, (uint16_t *)&sbuf0[1] },
    { "2",    PARAM_TYPE_UINT16, (uint16_t *)&sbuf0[2] },
    { "3",    PARAM_TYPE_UINT16, (uint16_t *)&sbuf0[3] },
*/
    { NULL, 0, NULL }
  };
  struct ParamList g_DMA0OutList = { "output0", &s_DMA0Output[0] };

  /*
    { "dmactl0",    PARAM_TYPE_HEX16, (uint16_t *)&DMACTL0 },
    { "dmactl1",    PARAM_TYPE_HEX16, (uint16_t *)&DMACTL1 },
    { "dma0ctl",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0CTL},
    { "dma1ctl",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1CTL},
    { "dma2ctl",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2CTL},
    { "dma0sa",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0SA},

    { "dma0sz",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0SZ},
    { "dma1sa",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1SA},
    { "dma1sz",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1SZ},
    { "dma2sa",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2SA},
    { "dma2sz",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2SZ},
  */
  const struct Param s_DMARegs[] = {
    { "dma0da",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0DA},
    { "dma1da",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1DA},
    { "dma2da",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2DA},
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
    signal ParamView.add( &g_DMARegsList );

    return SUCCESS;
  }

  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand operations[] = {
    { "ship", &do_sends },
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
