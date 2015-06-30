/*
 * Copyright (c) 2006, Intel Corporation
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
 *     * Neither the name of Intel Corporation nor the names of its
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
 * App for trying out SD module
 *
 * Authors:  Steve Ayer
 *           May 2006
 */
includes NVTParse;
includes msp430baudrates;
includes SD;
includes TosTime;

module SDAppM {
  provides {
    interface StdControl;
    interface ParamView;
  }

  uses {
    interface StdControl as IPStdControl;

    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface Telnet as TelnetRun;

    interface UIP;
    interface Client;
    interface Leds;
    interface SD;
    interface StdControl as SDStdControl;

    interface TCPServer;
    //    interface NTPClient;
    //    interface Timer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

#define MY_SERVER_PORT 5666

#define MAX_SIZE 512
#define PACKET_PAYLOAD 128

#define NTP_TO_UNIX_EPOCH_SECONDS 2208988800ul

  void * server_token;

  uint8_t timebuf[MAX_SIZE];
  uint8_t cardbuf[MAX_SIZE];
  uint8_t sbuf[MAX_SIZE];
  uint8_t msgbuf[128];

  uint32_t time_sec, time_frac, cardsize;

  void init_writebuf(uint8_t start) {
    register uint16_t i = 0;
    uint16_t j;
    for(i = 0; i < MAX_SIZE; ){
      for(j = start; j < 93; j++, i++)
	sbuf[i] = j + 33;
    }
  }

  command result_t StdControl.init() {
    memset(msgbuf, 0, 128);
    memset(cardbuf, 0, 512);

    init_writebuf(12);
    memset(timebuf, ' ', MAX_SIZE);

    TOSH_CLR_UTXD0_PIN();  

    call Leds.init();

    //    call Leds.greenOn();
    //call Leds.yellowOn();
    //    call Leds.redOn();

    call PVStdControl.init();
    call IPStdControl.init();

    call TelnetStdControl.init();
    call SDStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();
    call SDStdControl.start();

    call TCPServer.listen(MY_SERVER_PORT);

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

    /*
  event void NTPClient.timestampReceived( uint32_t *seconds, uint32_t *fraction ) {
    static uint8_t timebytes;
    static uint16_t curr_sector = 100;

    atomic time_frac = *fraction;
    atomic time_sec = *seconds;// + NTP_TO_UNIX_EPOCH_SECONDS;

    call Leds.redToggle();

    //    timebytes += sprintf(timebuf + timebytes, "ntp %llu %llu sys %llu %llu\n", time_sec, time_frac, tt.high32, tt.low32);      // & 0x0000ffffU));
    //    if((timebytes + 52) >= MAX_SIZE){
      timebytes = 0;
      call SD.writeSector(curr_sector++, timebuf);
      memset(timebuf, ' ', MAX_SIZE);
      //    }
  }
      */

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
      sector = 10000;
   }
    else{
      sector = atol(in);
      sprintf(msgbuf, "write to SECTOR %lu.", sector);
    }

    //    for(i = 0; i < 10; i++){
      rval = call SD.writeBlock(sector, sbuf);

      if(rval)
	sprintf(msgbuf, "bad write, error=%d", rval);
      //    }
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

    rval = call SD.readBlock(sector++, cardbuf);

    if(rval)
      sprintf(msgbuf, "bad read, error=%d", rval);


    return out;
  }

  async event void SD.available(){
  }

  async event void SD.unavailable(){
  }

  /* this returns zero on sdio-only cards; unsupported there */
  char * get_size(char * in, char * out, char * outmax) { 
    cardsize = call SD.readCardSize();

    sprintf(msgbuf, "card size is %ld", cardsize);

    return out;
  }

  void ship_sdcontents(){
    static uint16_t bytes_sent, bytes_left = MAX_SIZE;
    uint8_t send_buf[PACKET_PAYLOAD], this_send;

    if(bytes_sent < MAX_SIZE){
      if(bytes_left > PACKET_PAYLOAD){
	this_send = PACKET_PAYLOAD;
	memcpy(send_buf, cardbuf + bytes_sent, this_send);
	bytes_sent += PACKET_PAYLOAD;
      }
      else{
	this_send = bytes_left;
	memcpy(send_buf, cardbuf + bytes_sent, this_send);
	bytes_sent += bytes_left;
      }

      bytes_left -= bytes_sent;
      call TCPServer.write(server_token, send_buf, this_send);
    }
    else{
      bytes_left = MAX_SIZE;
      bytes_sent = 0;
      call TCPServer.close(server_token);
      server_token = NULL;
    }
  }

  event void TCPServer.connectionMade( void *token ) {
    server_token = token;
    msgbuf[0] = NULL;
    ship_sdcontents();
  }


  event    void     TCPServer.dataAvailable( void *token, uint8_t *buf, uint16_t len ) {
  }
  event    void     TCPServer.connectionFailed( void *token, uint8_t reason ) { 
  }
  event    void     TCPServer.writeDone( void *token ) {
    strcat(msgbuf, " ...write completed");
    ship_sdcontents();
  }




  /*****************************************
   *  Client interface
   *****************************************/

  event void Client.connected( bool isConnected ) 
  {
    if (isConnected)
      call Leds.greenOff();
    else
      call Leds.greenOff();
  }
  const struct Param s_readback[] = {
    { "",    PARAM_TYPE_HEX8, &cardbuf[0] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[1] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[2] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[3] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[4] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[5] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[6] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[7] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[8] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[9] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[10] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[11] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[12] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[13] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[14] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[15] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[16] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[17] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[18] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[19] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[20] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[21] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[22] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[23] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[24] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[25] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[26] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[27] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[28] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[29] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[30] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[31] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[32] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[33] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[34] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[35] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[36] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[37] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[38] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[39] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[40] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[41] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[42] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[43] },
    { "",    PARAM_TYPE_HEX8, &cardbuf[44] },
    { NULL, 0, NULL }
  };
  
  struct ParamList sdList = { "sdcontents", &s_readback[0] };

  const struct Param s_sdsize[] = {
    { "size",    PARAM_TYPE_UINT32, &cardsize },
    { NULL, 0, NULL }
  };
  struct ParamList sizeList = { "sdsize", &s_sdsize[0] };

  const struct Param s_msg[] = {
    { "msg",    PARAM_TYPE_STRING, &msgbuf[0] },
    { NULL, 0, NULL }
  };
  struct ParamList msgList = { "msgs", &s_msg[0] };

  command result_t ParamView.init(){
    signal ParamView.add(&sdList);
    signal ParamView.add(&sizeList);
    signal ParamView.add(&msgList);
    return SUCCESS;
  }
  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand sd_operations[] = {
    { "write", &do_write },
    { "read", &do_read },
    { "sdinit", &do_init },
    { "size", &get_size },
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
