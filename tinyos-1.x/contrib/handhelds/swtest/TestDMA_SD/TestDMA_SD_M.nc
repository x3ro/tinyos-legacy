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
 *          July 2006
 */

includes DMA;
includes Message;
includes NVTParse;
includes SD;
includes MMA7260_Accel;
includes msp430baudrates;

module TestDMA_SD_M {
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
    interface StdControl as AccelStdControl;

    interface SD;

    interface MMA7260_Accel as Accel;

    interface Telnet as TelnetRun;

    interface UIP;
    interface Client; 
    interface TCPServer;
    /* end telnet stuff */
    interface Leds;
    //    interface NTPClient;
    interface Time;

    interface LocalTime;

    interface Timer as yTimer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

#define MY_SERVER_PORT 5666

#define MAX_SIZE 512
#define PACKET_PAYLOAD 128
#define MESSAGE_MAX_LENGTH 128

  void * server_token;

  uint8_t write_step, myreason = 0;
  uint16_t inbuf0[256], inbuf1[256], inbuf2[256], *curr0, *curr1, *curr2, shipping_sector;
  norace uint32_t current_sector = 52999;
  uint32_t howbig;
  uint16_t cardbuf[256];
  uint32_t sbuf[256];
  uint8_t msgbuf[128];

  time_t g_local_time; 
  
  uint16_t adcifg_count = 0;

  void setupDMA() {
    call DMA0.init();
    call DMA1.init();
    call DMA2.init();

    atomic {
      call DMA0.setDestinationAddress(inbuf0);
      call DMA1.setDestinationAddress(inbuf1);
      call DMA2.setDestinationAddress(inbuf2);

      call DMA0.setBlockSize(sizeof(inbuf0) >> 1);
      call DMA1.setBlockSize(sizeof(inbuf1) >> 1);
      call DMA2.setBlockSize(sizeof(inbuf2) >> 1);

      SET_FLAG(DMACTL1, ROUNDROBIN);  // round-robin
    }

  }
	
  void sampleADC() {
    call DMA0.ADCinit();   // this doesn't really need to be parameterized

    atomic{
      CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
      SET_FLAG(ADC12CTL1, ADC12SSEL_3);         // clk from aclk
      
      SET_FLAG(ADC12CTL1, ADC12DIV_4);         // divide clk by 8
      // sample and hold time four adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   

      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }
    // set input channel
    /*    call DMA0.ADCsetMemRegisterInputChannel(0, 3);  // memreg 0 <= channel 0
    call DMA0.ADCsetMemRegisterInputChannel(1, 4);  // memreg 1 <= channel 1
    call DMA0.ADCsetMemRegisterInputChannel(2, 5);  // memreg 2 <= channel 2
    */
    SET_FLAG(ADC12MCTL0, INCH_3);
    SET_FLAG(ADC12MCTL1, INCH_4);
    SET_FLAG(ADC12MCTL2, INCH_5);
    SET_FLAG(ADC12MCTL2, EOS);       //sez "this is the last reg" 

    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_3);      // repeat sequence of channels
    
    SET_FLAG(ADC12MCTL2, EOS);       // sez "this is the last reg" 

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

  }

  task void adcResults() { 
  } 

  task void dma0Results() { 
  }	 
    
  task void dma1Results() { 
  }	 
    
  task void dma2Results() { 
    uint8_t rval;

    call Leds.orangeToggle();

    call DMA0.ADCstopConversion();

    call Leds.yellowOn();

    if((rval = call SD.writeSector(current_sector++, (uint8_t *)inbuf0)))
      sprintf(msgbuf, "bad write, error=%d", rval);
    if((rval = call SD.writeSector(current_sector++, (uint8_t *)inbuf1)))
      sprintf(msgbuf, "bad write, error=%d", rval);
    if((rval = call SD.writeSector(current_sector++, (uint8_t *)inbuf2)))
      sprintf(msgbuf, "bad write, error=%d", rval);

    call Leds.yellowOff();

    call DMA0.ADCbeginConversion();
  }	
    
  command result_t StdControl.init() {
    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    call SDStdControl.init();
    
    call AccelStdControl.init();

    /*  put the roving radio bt module to sleep
    TOSH_SEL_GIO1_IOFUNC();
    TOSH_MAKE_GIO1_OUTPUT();
    TOSH_SET_GIO1_PIN();
    TOSH_CLR_BT_RESET_PIN();
    */
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

    call SDStdControl.start();

    call AccelStdControl.start();

    call Accel.setSensitivity(RANGE_2_0G);

    call TCPServer.listen(MY_SERVER_PORT);   // we'll listen for a client to pull a sector of data
    
    sampleADC();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  char * do_init(char * in, char * out, char * outmax) { 

    call SDStdControl.init();
    sprintf(msgbuf, "sd init...");
    call SDStdControl.start();
    strcat(msgbuf, "sd start.");

    return out;
  }

  char * do_write(char * in, char * out, char * outmax) { 
    uint8_t rval;
    uint32_t sector;

    if(!strcmp(in, "")){
      sprintf(msgbuf, "NO SECTOR PROVIDED.");
      out += snprintf(out, outmax - out, "%s\r\n", "no sector provided");
      sector = 10;
    }
    else{
      sector = atol(in);
      sprintf(msgbuf, "write to SECTOR %lu.", sector);
    }

    if((rval = call SD.writeSector(sector, (uint8_t *)sbuf)))
      sprintf(msgbuf, "bad write, error=%d", rval);

    return out;
  }

  char * do_read(char * in, char * out, char * outmax) { 
    uint32_t sector;
    uint8_t rval;

    if(!strcmp(in, "")){
      sprintf(msgbuf, "NO SECTOR PROVIDED:=>%s<=", in);
      sector = 10;
    }
    else{
      sector = atol(in);
      sprintf(msgbuf, "read from SECTOR %lu.", sector);
    }

    if((rval = call SD.readSector(sector, (uint8_t *)sbuf)))
      sprintf(msgbuf, "bad read, error=%d", rval);

    return out;
  }
  
  char * do_dma(char * in, char * out, char * outmax) { 
    uint16_t w;

    call Leds.redOn();
    atomic{
      SET_FLAG(ADC12IE, 0xff);
      CLR_FLAG(ADC12IFG, 0xff);
      CLR_FLAG(ADC12IE, 0xff);

      call DMA0.beginTransfer();
      call DMA1.beginTransfer();
      call DMA2.beginTransfer();
    }
    w = ADC12MEM0;
    w = ADC12MEM1;
    w = ADC12MEM2;

    return out;
  }

  char * do_size(char * in, char * out, char * outmax) { 
    howbig = call SD.readCardSize();
    
    return out;
  }
  
  task void ship_contents() {
    uint8_t rval;

    if((rval = call SD.readSector(shipping_sector, (uint8_t *)cardbuf)))
      sprintf(msgbuf, "bad read, error=%d", rval);

    call TCPServer.write(server_token, (uint8_t *)cardbuf, 128);
  }

  event void Time.tick() { 
    //call Leds.redToggle(); 
  }

  event void TCPServer.connectionMade( void *token ) {
    server_token = token;
    msgbuf[0] = NULL;

    write_step = 0;
    call Leds.redOff();
    myreason = 0;
    // wait until client sends us a sector number
  }  

  event void TCPServer.writeDone( void *token ) {
    write_step++;
    switch (write_step) {
    case 1:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 64), 128);
      break;
    case 2:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 128), 128);
      break;
    case 3:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 192), 128);
      break;
    case 4:
      shipping_sector++;

      post ship_contents();
      break;
    case 5:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 64), 128);
      break;
    case 6:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 128), 128);
      break;
    case 7:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 192), 128);
      break;
    case 8:
      shipping_sector++;

      post ship_contents();
      break;
    case 9:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 64), 128);
      break;
    case 10:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 128), 128);
      break;
    case 11:
      call TCPServer.write(server_token, (uint8_t *)(cardbuf + 192), 128);
      break;
    default:
      call TCPServer.close(server_token);

      write_step = 0;

      break;
    }
  }

  event    void     TCPServer.dataAvailable( void *token, uint8_t *buf, uint16_t len ) {
    uint8_t b[50];
    shipping_sector = *(uint32_t *)buf;
    sprintf(b, "looking at sector %d", shipping_sector);
    strcat(msgbuf, b);
    post ship_contents();
    
  }
  event    void     TCPServer.connectionFailed( void *token, uint8_t reason ) { 
    myreason = reason;
    call Leds.redOn();
  }

  event result_t yTimer.fired() {
    return SUCCESS;
  }

  async event void DMA0.transferComplete() {
    post dma0Results();
  }

  async event void DMA1.transferComplete() {
    post dma1Results();
  }

  async event void DMA2.transferComplete() {
    post dma2Results();
  }

  async event void DMA0.ADCInterrupt(uint8_t regnum) {
    call Leds.orangeOn();
    atomic {
      if(adcifg_count++ > 255){
	ADC12CTL0 = 0;
	ADC12IE = 0;
	post adcResults();
      }
    }	       
  } 
  async event void DMA1.ADCInterrupt(uint8_t regnum) {}
  async event void DMA2.ADCInterrupt(uint8_t regnum) {}

  event void Client.connected( bool isConnected ) {
  }

  const struct Param s_ADCRegs[] = {
    { "svsreg",     PARAM_TYPE_HEX8,  (uint8_t *)&SVSCTL },
    { "adcctl0",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12CTL0 },
    { "adcctl1",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12CTL1 },
    { "adcmem0",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM0},
    { "adcmem1",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM1},
    { "adcmem2",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12MEM2},
    { "adcmemctl0",    PARAM_TYPE_HEX8, (uint8_t *)&ADC12MCTL0},
    { "adcmemctl1",    PARAM_TYPE_HEX8, (uint8_t *)&ADC12MCTL1},
    { "adcmemctl2",    PARAM_TYPE_HEX8, (uint8_t *)&ADC12MCTL2},
    { "adciv",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12IV},
    { "adcifg",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12IFG},
    { "adcie",    PARAM_TYPE_HEX16, (uint16_t *)&ADC12IE},
    { "adcifgcount",    PARAM_TYPE_HEX16, (uint16_t *)&adcifg_count},
    { NULL, 0, NULL }
  };
  const struct Param s_DMARegs[] = {
    { "dmactl0",    PARAM_TYPE_HEX16, (uint16_t *)&DMACTL0 },
    { "dmactl1",    PARAM_TYPE_HEX16, (uint16_t *)&DMACTL1 },
    { "dma0ctl",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0CTL},
    { "dma1ctl",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1CTL},
    { "dma2ctl",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2CTL},
    { "dma0sa",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0SA},
    { "dma0da",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0DA},
    { "dma0sz",    PARAM_TYPE_HEX16, (uint16_t *)&DMA0SZ},
    { "dma1sa",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1SA},
    { "dma1da",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1DA},
    { "dma1sz",    PARAM_TYPE_HEX16, (uint16_t *)&DMA1SZ},
    { "dma2sa",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2SA},
    { "dma2da",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2DA},
    { "dma2sz",    PARAM_TYPE_HEX16, (uint16_t *)&DMA2SZ},
    { NULL, 0, NULL }
  };

  const struct Param s_DMA0Output[] = {
    { "current sector",   PARAM_TYPE_UINT32, &current_sector },
    { "error_reason",   PARAM_TYPE_UINT8, &myreason },
    { "card size",   PARAM_TYPE_UINT32, &howbig },
    { "0",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[0] },
    { "1",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[1] },
    { "2",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[2] },
    { "3",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[3] },
    { "4",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[4] },
    { "5",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[5] },
    { "6",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[6] },
    { "7",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[7] },
    { "8",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[8] },
    { "9",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[9] },
    { "10",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[10] },
    { "11",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[11] },
    { "12",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[12] },
    { "13",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[13] },
    { "14",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[14] },
    { "15",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[15] },
    { "16",    PARAM_TYPE_UINT32, (uint32_t *)&sbuf[16] },
    { NULL, 0, NULL }
  };
  struct ParamList g_ADCRegsList = { "adcregs", &s_ADCRegs[0] };
  struct ParamList g_DMA0OutList = { "z", &s_DMA0Output[0] };
  struct ParamList g_DMARegsList = { "dmaregs", &s_DMARegs[0] };

  const struct Param s_msg[] = {
    { "msg",    PARAM_TYPE_STRING, &msgbuf[0] },
    { NULL, 0, NULL }
  };
  struct ParamList msgList = { "msgs", &s_msg[0] };

  command result_t ParamView.init(){
    signal ParamView.add( &msgList );
    signal ParamView.add( &g_ADCRegsList );
    signal ParamView.add( &g_DMARegsList );
    signal ParamView.add( &g_DMA0OutList );
    //    signal ParamView.add( &g_DMA1OutList );
    //    signal ParamView.add( &g_DMA2OutList );
    return SUCCESS;
  }
  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand sd_operations[] = {
    { "write", &do_write },
    { "read", &do_read },
    { "size", &do_size },
    { "startdma", &do_dma },
    { "sdinit", &do_init },
    { 0, NULL }
  };
 
  event const char * TelnetRun.token() { return "run"; }
  event const char * TelnetRun.help() { return "Run SDApp operations\r\n"; }
    
  event char * TelnetRun.process( char * in, char * out, char * outmax ) {
    char * next, * extrastuff;
    char * cmd = next_token(in, &next, ' ');

    if(cmd) {
      const struct TelnetCommand *c = sd_operations;
      
      for ( ;c->name; c++) {
	if (strcmp(cmd, c->name) == 0) {
	  extrastuff = (*c->func)( next, out, outmax );
	  //this is a hack to prevent hanging telnet.process if nothing is returned from service function
	  if(extrastuff)
	    out += snprintf(out, outmax - out, "%s\r\n", extrastuff);
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
