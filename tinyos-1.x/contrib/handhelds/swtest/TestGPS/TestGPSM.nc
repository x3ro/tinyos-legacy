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
 * @date   September, 2010
 */

includes NVTParse;
includes msp430baudrates;
includes Message;

module TestGPSM {
  provides{
    interface StdControl;
    interface ParamView;
  }
  uses {
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface GPS;
    interface StdControl as GPSStdControl;
    interface PressureSensor;
    interface StdControl as PSStdControl;

    interface UIP;
    interface Client;
    interface UDPClient;
    interface Telnet as TelnetRun;

    interface Leds;
    interface Timer;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

  task void sendit();
  task void runGPS();

  struct udp_address udpaddr;
  uint8_t msgbuf[128], gpsbuff[128];
  uint16_t sbuf0[128], sample_period;
  uint8_t enable_shipping = 0, bytesToSend, sample_count;
  // calibration vars
  //  int16_t AC1, AC2, AC3, B1, B2, MB, MC, MD;
  //  uint16_t AC4, AC5, AC6;
  
  // calculation vars
  //  int32_t x1, x2, x3, b3, b5, b6, press;
  int32_t press;
  //  uint32_t b4, b7, up, ut;
  int16_t temp;

  command result_t StdControl.init() {
    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    call Leds.init();

    sample_period = 100;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();

    call GPSStdControl.init();
    call GPSStdControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call GPSStdControl.stop();

    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  task void runGPS(){
    sample_count = 0;
    call Timer.stop();

    call PressureSensor.disableBus();

    call GPS.enableBus();
  }    

  event result_t Timer.fired() {
    call PressureSensor.readTemperature();

    return SUCCESS;
  }

  char * do_conv(char * in, char * out, char * outmax) { 
    sample_period = atoi(in);

    call PSStdControl.init();
    call PSStdControl.start();

    sprintf(msgbuf, "requested sample period %d ms (%d hz)", sample_period, 1000/sample_period);
    sample_count = 0;

    call Timer.start(TIMER_REPEAT, sample_period);

    return out;
  }

  char * do_noconv(char * in, char * out, char * outmax) { 
    sprintf(msgbuf, "sampling stopped");

    call Timer.stop();

    return out;
  }

  event void PressureSensor.tempAvailable(int16_t * data){
    call PressureSensor.readPressure();
    temp = *data;
  }

  event void PressureSensor.pressAvailable(int32_t * data){
    press = *data;

    memcpy(gpsbuff, &temp, 2);
    memcpy(gpsbuff + 2, &press, 4);

    bytesToSend = 6;

    post sendit();
    
    post runGPS();
  }

  task void enableSocks(){
    udpaddr.ip[0] = 173;
    udpaddr.ip[1] = 9;
    udpaddr.ip[2] = 95;
    udpaddr.ip[3] = 161;
    udpaddr.port = 5067;
    
    call UDPClient.connect(&udpaddr);

    enable_shipping = 1;
  }

  event void Client.connected( bool isConnected ) {
  }

  task void sendit() {
    if(enable_shipping)
      call UDPClient.send(gpsbuff, bytesToSend);
  }

  task void runPressure() {
    sample_count = 0;

    call GPS.disableBus();
    
    call PressureSensor.enableBus();
    
    call Timer.start(TIMER_REPEAT, sample_period);
  }
  
  async event void GPS.NMEADataAvailable(char * data) {
    if(!strncmp("$GPGGA", data, 6)){
      strcpy(gpsbuff, data);
      bytesToSend = strlen(gpsbuff);
      
      post sendit();
      
      post runPressure();
    }
  }

  event void UDPClient.sendDone() {}

  event    void     UDPClient.receive(const struct udp_address *addr, uint8_t *buf, uint16_t len) {}
  struct TelnetCommand {
    char *name;
    char * (*func)( char *, char *, char * );
  };

  char * do_sends(char * in, char * out, char * outmax) { 
    post enableSocks();

    sprintf(msgbuf, "requested connection to %d.%d.%d.%d", udpaddr.ip[0], udpaddr.ip[1], udpaddr.ip[2], udpaddr.ip[3]);
    return out;
  }

  char * do_enable(char * in, char * out, char * outmax) {
    call GPS.enable();

    sprintf(msgbuf, "gps enabled");
    
    return out;
  }

  char * do_disable(char * in, char * out, char * outmax) {
    call GPS.disable();

    sprintf(msgbuf, "gps disabled");
    
    return out;
  }

  char * do_hot(char * in, char * out, char * outmax) {
    call GPS.setHotStart();

    sprintf(msgbuf, "gps hot start");
    
    return out;
  }

  char * do_stop(char * in, char * out, char * outmax) {
    enable_shipping = 0;
    call UDPClient.connect(NULL);
    sprintf(msgbuf, "requested connection closed");
    
    return out;
  }

  char * do_datarate(char * in, char * out, char * outmax) { 
    uint32_t data;
    char * next, * tok, * dummy;
    
    tok = next_token(in, &next, ' ');
    data = strtoul(tok, &dummy, 10);

    call GPS.setDatarate(data);
    sprintf(msgbuf, "new datarate is %ld", data);

    return out;
  }

  // this does not work, chipset ignores command
  char * do_baudrate(char * in, char * out, char * outmax) { 
    uint32_t data;
    char * next, * tok, * dummy;
    
    tok = next_token(in, &next, ' ');
    data = strtoul(tok, &dummy, 10);

    call GPS.setNewBaudrate(data);
    sprintf(msgbuf, "new baudrate sent br %ld", data);

    return out;
  }

  char * do_mode(char * in, char * out, char * outmax) { 
    uint8_t data;
    char * next, * tok;
    
    tok = next_token(in, &next, ' ');
    data = atoi(tok);

    call PressureSensor.setSensingMode(data);
    sprintf(msgbuf, "sensing mode set to %d", data);

    return out;
  }

  char * do_presspower(char * in, char * out, char * outmax) {
    uint8_t on;
    char * next, * tok;

    tok = next_token(in, &next, ' ');
    on = atoi(tok);
    
    if(on)
      call PressureSensor.powerUp();
    else
      call PressureSensor.powerDown();

    sprintf(msgbuf, "pressure power %s", (on ? "on" : "off"));

    return out;
  }

  char * do_temp(char * in, char * out, char * outmax) {
    call PressureSensor.readTemperature();
    
    sprintf(msgbuf, "temp sampling started");

    return out;
  }

  const struct TelnetCommand operations[] = {
    { "ship", &do_sends },
    { "stop", &do_stop },
    { "enable", &do_enable },
    { "disable", &do_disable },
    { "hot", &do_hot },
    { "baud", &do_baudrate },
    { "rate", &do_datarate },
    { "power", &do_presspower }, 
    { "temp", &do_temp },
    { "ship", &do_sends },
    { "stop", &do_stop },
    { "conv", &do_conv },
    { "stopconv", &do_noconv },
    { "mode", &do_mode }, 
    { 0, NULL }
  };
 
  command result_t ParamView.init(){
    return SUCCESS;
  }

  event const char * TelnetRun.token() { return "run"; }
  event const char * TelnetRun.help() { return "Run SDApp operations\r\n"; }
    
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
