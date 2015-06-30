/*
 * Copyright (c) 2005 Hewlett-Packard Company
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
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
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
 * Test reading a serial number from the Dallas Semiconductor DS2411
 * chip.
 *
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         14 March 2005
 *
 * This code is strongly based on the OscilloscopeM code from MoteIV.
 */

module HumidityTempM {
  provides {
    interface StdControl;
  }
  uses {
    interface SplitControl as HumidityControl;

    interface UIP;
    interface Client;
    interface Telnet as TelnetHT;
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;

    interface Timer;

    interface ADC as Humidity;
    interface ADC as Temperature;
    interface ADCError as HumidityError;
    interface ADCError as TemperatureError;

    interface Leds;
  }
}
implementation {
  extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));
  
  norace uint16_t g_humidity, g_temperature;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call TelnetStdControl.init();
    call HumidityControl.init();

    return call IPStdControl.init();
  }

  event result_t HumidityControl.initDone() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call HumidityControl.start();
    call TelnetStdControl.start();
    return SUCCESS;
  }

  event result_t HumidityControl.startDone() {
    call HumidityError.enable();
    call TemperatureError.enable();
    call Timer.start( TIMER_REPEAT, 5000 );  // Readings about every five seconds
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    call HumidityControl.stop();
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  event result_t HumidityControl.stopDone() {
    call HumidityError.disable();
    call TemperatureError.disable();
    return SUCCESS;
  }

  /*****************************************
   *  Temperature/Humidity callbacks
   *****************************************/

  task void startTemp()
  {
    call Temperature.getData();
  }

  async event result_t Humidity.dataReady(uint16_t data) {
    g_humidity = data;
    post startTemp();
    return SUCCESS;
  }

  event result_t HumidityError.error(uint8_t token) {
    g_humidity = 0;
    post startTemp();
    return SUCCESS;
  }

  async event result_t Temperature.dataReady(uint16_t data) {
    g_temperature = data;
    return SUCCESS;
  }

  event result_t TemperatureError.error(uint8_t token) {
    g_temperature = 0;
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call Humidity.getData();
    return SUCCESS;
  }

  /*****************************************
   *  Telnet
   *****************************************/

  event const char * TelnetHT.token() { return "ht"; }
  event const char * TelnetHT.help() { return "HT Commands\r\n"; }

  event char * TelnetHT.process( char *in, char *out, char *outmax )
  {
    uint16_t t, h;
    out += snprintf(out, outmax - out, "Temp %d", g_temperature);
    t = g_temperature - 3960;
    out += snprintf(out, outmax - out, "= %d.%02d C\r\n", t / 100, t % 100);
    out += snprintf(out, outmax - out, "Hum  %04x = ", g_humidity);
    h = -4 + 0.0405 * g_humidity - 2.8E-06 * g_humidity * g_humidity;
    out += snprintf(out, outmax - out, " %d (raw)", h );
    h += (t - 2500) * ( 0.01 + 0.00008 * g_humidity) * 0.01;
    out += snprintf(out, outmax - out, " %d (corrected)\r\n", h );
    
    return out;
  }
  
  event void Client.connected( bool isConnected )
  {
    if ( isConnected )
      call Leds.greenOn();
    else
      call Leds.greenOff();
  }
}


