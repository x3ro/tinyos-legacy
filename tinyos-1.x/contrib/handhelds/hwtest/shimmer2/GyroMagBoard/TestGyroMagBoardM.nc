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
 */

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
  norace uint8_t current_buffer = 0;
  int16_t sbuf0[42], sbuf1[42], * current_dest, sample_period = 500;
  uint8_t msgbuf[128], readBuf[13], howmany, buffered;
  struct udp_address udpaddr;
  char helpmsg[128];
  bool result_ready;

  task void ship_contents() {
    if(enable_shipping){
      if(call Client.is_connected()){
	if(current_buffer == 1)
	  //	  call UDPClient.send((uint8_t *)sbuf0, 84);
	  call UDPClient.send((uint8_t *)sbuf0, 42);  // more often
	else
	  //	  call UDPClient.send((uint8_t *)sbuf1, 84);
	  call UDPClient.send((uint8_t *)sbuf1, 42);
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

    result_ready = FALSE;

    buffered = 0;

    call GyroMagStdControl.init();
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    call GyroMagStdControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call GyroMagStdControl.stop();

    call TelnetStdControl.stop();
    call IPStdControl.stop();
    return SUCCESS;
  }

  async event void GyroMagBoard.buttonPressed() {
    //    call GyroBoard.ledToggle();
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

  event void GyroMagBoard.writeDone(result_t success){
  }

  char * do_conv(char * in, char * out, char * outmax) { 
    call GyroMagBoard.writeRegValue(2, 0);  // tell it to continuously convert
    sample_period = atoi(in);

    if(sample_period < 100)  // this part takes at least 100ms to measure
      sample_period = 100; 

    sprintf(msgbuf, "requested sample period %d ms (%d hz)", sample_period, 1000/sample_period);

    if(current_buffer == 0)
      current_dest = sbuf0;
    else
      current_dest = sbuf1;

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
    call GyroMagBoard.writeRegValue(2, 2);  // tell it to become idle
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

  int16_t twos_comp_convert(uint8_t up, uint8_t low) 
  {
    int16_t out;
    uint16_t uout;
    
    uout = up;
    uout = uout << 8;
    uout |= low;
    /*    
    uout = ~uout;
    uout++;
    */
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
   * the BOTTOM of the chipset.  so, for readings to make sense, the chip bottom
   * has to be pointed away from earth (shimmer upside down).
   * then, these boundary conditions apply:
   *
   * when z > 0 (chip bottom away from earth center)
   * for (Xh = 0, Yh < 0) = 270
   * for (Xh = 0, Yh > 0) = 90
   * else 180 - arcTan(Yh/Xh)
   */

  uint16_t mag_to_heading(uint16_t x, uint16_t y)
  {
    uint16_t heading;

    if(x == 0){
      if(y < 0)
	heading = 90;
      else
	heading = 270;
    }
    else if(x < 0)
      heading = (uint16_t)(180.0 - atanf((float)y/(float)x));
    else{
      if(y < 0)
	heading = (uint16_t)-atanf((float)y/(float)x);
      else
	heading = (uint16_t)(360.0 - atanf((float)y/(float)x));
    }
    
    return heading;
  }

  task void collect_results() {
    int16_t realVals[3], x, y, z, heading;
    uint8_t * src;
    register uint8_t i;

    call GyroMagBoard.readValues(7, readBuf);

    call Leds.greenOn();
    
    while(!result_ready)
      TOSH_uwait(500);
    
    call Leds.greenOff();

    result_ready = FALSE;

    src = readBuf;

    // this loop is just for the three 16-bit x,y,z values
    for(i = 0; i < 3; i++){
      realVals[i] = twos_comp_convert(*src, *(src + 1));
      src += 2;
    }

    /*
     * this for shipping raw vals
     */
    memcpy(current_dest, realVals, 6);
    current_dest += 3;  // 16-bit pointer

    buffered++;
    //  for heading only    *current_dest++ = heading;
    // for heading only    if(buffered == 21){
    if(buffered == 7){
      buffered = 0;
      if(current_buffer == 0){
	current_dest = sbuf1;
	current_buffer = 1;
      }
      else{
	current_dest = sbuf0;
	current_buffer = 0;
      }
      post ship_contents();
    }
  }

  event void GyroMagBoard.readDone(uint8_t length, uint8_t * data, result_t success){
    howmany = length;

    memcpy(readBuf, data, length);
    call Leds.greenToggle();
    //    post collect_results();

    atomic result_ready = TRUE;
  }
  
  task void clockin_result(){
    call GyroMagBoard.readValues(7, readBuf);
  }

  event result_t sampleTimer.fired() {
    //    post clockin_result();
    post collect_results();
    return SUCCESS;
  }

  event void Client.connected( bool isConnected ) {
    /*
    if(isConnected)
      call Leds.greenOn();
    else
      call Leds.greenOff();
    */
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
    call GyroMagBoard.writeRegValue(addr, data);

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
    call GyroMagBoard.readValues(size, readBuf);

    return out;
  }

  char * do_readdone(char * in, char * out, char * outmax) { 
    register uint8_t i;
    uint8_t * src, * dest;
    int16_t realVals[3], x, y;
    uint16_t heading;

    sprintf(msgbuf, "readdone shows %d bytes ", howmany);
    src = readBuf;
    // this loop is just for the three 16-bit x,y,z values
    for(i = 0; i < 3; i++){
      dest = msgbuf + strlen(msgbuf);
      realVals[i] = twos_comp_convert(*src, *(src + 1));

      sprintf(dest, "%d ", realVals[i]);
      src += 2;
    }
    x = *realVals;
    y = *(realVals + 1);
    //    heading = mag_to_heading(x, y);

    dest = msgbuf + strlen(msgbuf);
    sprintf(dest, "heading = %d ", heading);
    howmany = 0;
    memset(readBuf, 0, 13);

    return out;
  }
    
  char * do_peek(char * in, char * out, char * outmax) { 
    uint8_t data;

    call GyroMagBoard.peek(&data);
    sprintf(msgbuf, "got back %02x", data);

    return out;
  }

  char * do_poke(char * in, char * out, char * outmax) { 
    uint8_t data;
    char * next, * tok, * dummy;

    tok = next_token(in, &next, ' ');
    data = strtoul(tok, &dummy, 16);

    sprintf(msgbuf, "wrote %02x", data);
    call GyroMagBoard.poke(data);

    return out;
  }

  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  const struct TelnetCommand operations[] = {
    { "write", &do_write },
    { "peek", &do_peek },
    { "result", &do_readdone },
    { "poke", &do_poke },
    { "read", &do_read },
    { "ship", &do_sends },
    { "stop", &do_stop },
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
