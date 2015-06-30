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

includes msp430baudrates;

module FGPMMOPA6B_M {
  provides {
    interface StdControl;
    interface GPS;
  }
  uses { 
    interface HPLUSARTControl as UARTControl;
    interface HPLUSARTFeedback as UARTData;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

  char databuf0[256], databuf1[256], * scout, cmdstring[128];
  uint8_t current_buffer, br_ndx, toSend, charsSent; 
  bool transmissionComplete;
  uint32_t newBaudrate;

  task void send_command();

  task void setupUART() {
    uint16_t ratestrings[][2] = 
      { { UBR_SMCLK_4800, UMCTL_SMCLK_4800 },
	{ UBR_SMCLK_9600, UMCTL_SMCLK_9600 },
	{ UBR_SMCLK_19200, UMCTL_SMCLK_19200 },
	{ UBR_SMCLK_38400, UMCTL_SMCLK_38400 },
	{ UBR_SMCLK_57600, UMCTL_SMCLK_57600 },
	{ UBR_SMCLK_115200, UMCTL_SMCLK_115200 }
	//	{ 0x0008, 0x00ee }
      };
    if(newBaudrate == 4800)
      br_ndx = 0;
    else if(newBaudrate == 9600)
      br_ndx = 1;
    else if(newBaudrate == 19200)
      br_ndx = 2;
    else if(newBaudrate == 38400)
      br_ndx = 3;
    else if(newBaudrate == 57600)
      br_ndx = 4;
    else if(newBaudrate == 115200)
      br_ndx = 5;
    
    call UARTControl.setClockSource(SSEL_SMCLK);
    call UARTControl.setClockRate(ratestrings[br_ndx][0], ratestrings[br_ndx][1]);
    call UARTControl.setModeUART();
    call UARTControl.enableTxIntr();
    call UARTControl.enableRxIntr();
  }

  command result_t StdControl.init() {
    TOSH_SET_PROG_OUT_PIN();

    TOSH_MAKE_ADC_6_INPUT();

    transmissionComplete = FALSE;

    /*
     * hw module's default baudrate -- 115200 -- should be here; see uart strings above
     * WARNING:  setNewBaudrate feature on this chipset does not work.  the code was 
     * validated as sending the nmea command string correctly, but no dice.
     */
    newBaudrate = 115200;
    br_ndx = 5;   

    post setupUART();
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call GPS.enable();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call GPS.disable();
    call UARTControl.disableUART();

    return SUCCESS;
  }

  command void GPS.enable() {
    scout = databuf0;
    current_buffer = 0;

    TOSH_CLR_PROG_OUT_PIN();
  }

  command void GPS.disable() {
    TOSH_SET_PROG_OUT_PIN();
  }

  command void GPS.disableBus(){
    call UARTControl.disableUART();
  }

  command void GPS.enableBus(){
    post setupUART();
  }

  uint8_t byteCRC(char * str) 
  {
    register uint8_t i;
    uint8_t sum = 0, len;
    
    len = strlen(str);

    for(i = 0; i < len; i++)
      sum = sum ^ *(str + i);
    
    return sum;
  }

  task void baudrate_change() { 
    uint8_t crc;
    char cmd[128];

    sprintf(cmd, "$PMTK251,%ld", newBaudrate);
    crc = byteCRC(cmd + 1);
    sprintf(cmdstring, "%s*%02X\r\n", cmd, crc);

    post send_command();
    
    call UARTControl.disableUART();
    post setupUART();
  }

  /****
   * WARNING:  
   * this just does not work; the code works, but the 
   * command string falls on deaf ears?
   *  command char * GPS.setNewBaudrate(uint32_t br) {
   ****/
  command void GPS.setNewBaudrate(uint32_t br) {
    newBaudrate = br;

    post baudrate_change();
//    return cmdstring;
  }

  /*
   * string of boolean on/off switches for sentences, in order
   * 0 NMEA_SEN_GLL, // GPGLL interval - Geographic Position - Latitude longitude
   * 1 NMEA_SEN_RMC, // GPRMC interval - Recomended Minimum Specific GNSS
   *   Sentence
   * 2 NMEA_SEN_VTG, // GPVTG interval - Course Over Ground and Ground Speed
   * 3 NMEA_SEN_GGA, // GPGGA interval - GPS Fix Data
   * 4 NMEA_SEN_GSA, // GPGSA interval - GNSS DOPS and Active Satellites
   * 5 NMEA_SEN_GSV, // GPGSV interval - GNSS Satellites in View
   * 18 NMEA_SEN_MCHN, // PMTKCHN interval \u2013 GPS channel status
   */
  command void GPS.restrictNMEASentences() {
    uint8_t crc;
    char cmd[128];

    sprintf(cmd, "$PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");

    crc = byteCRC(cmd + 1);
    sprintf(cmdstring, "%s*%02X\r\n", cmd, crc);
    
    post send_command();
  }

  command void GPS.resetNMEASentences() {
    sprintf(cmdstring, "$PMTK314,-1*04\r\n");

    post send_command();
  }

  /*
   * range is 0/ 0.2/ 0.4/ 0.6/ 0.8/ 1.0/1.5/2.0 (m/s) 
   * e.g.
   * $PMTK397,0.20*<checksum><CR><LF>
   * $PMTK397,0*<checksum><CR><LF>
   */
  command void GPS.setNavThreshold() {
    uint8_t crc;
    char cmd[128];

    sprintf(cmd, "$PMTK397,0");
    crc = byteCRC(cmd + 1);
    sprintf(cmdstring, "%s*%02X\r\n", cmd, crc);

    post send_command();
  }

  command void GPS.getNavThreshold() {
    sprintf(cmdstring, "$PMTK447*35\r\n");

    post send_command();
  }

  // tell it to come up in hot start mode
  command void GPS.setHotStart() {
    sprintf(cmdstring, "$PMTK101*32\r\n");

    post send_command();
  }

  // datarate in milliseconds, min 100
  command void GPS.setDatarate(uint16_t datarate) { 
    uint8_t crc;
    char cmd[128];

    sprintf(cmd, "$PMTK300,%d,0,0,0,0", datarate);
    crc = byteCRC(cmd + 1);
    sprintf(cmdstring, "%s*%02X\r\n", cmd, crc);

    post send_command();
  }

  task void sendOneChar() {
    if(charsSent < toSend)
      call UARTControl.tx(cmdstring[charsSent++]);
    else{
      transmissionComplete = TRUE;
    }
  }

  task void send_command() {
    toSend = strlen(cmdstring) + 1;
    charsSent = 0;
    transmissionComplete = FALSE;
    post sendOneChar();
  }
 
  async event result_t UARTData.txDone() {
    if(!transmissionComplete) {
      post sendOneChar();
    }
    return SUCCESS;
  }

  task void sendit() {
    if(current_buffer == 0)
      signal GPS.NMEADataAvailable(databuf1);
    else
      signal GPS.NMEADataAvailable(databuf0);
  }

  async event result_t UARTData.rxDone(uint8_t data) {        
    *scout = data;
    scout++;

    if(*(scout - 1) == '\n'){
      *(scout - 2) = '\0';

      if(current_buffer == 0){
	scout = databuf1;
	current_buffer = 1;
      }
      else{
	scout = databuf0;
	current_buffer = 0;
      }

      post sendit();
    }
    
    return SUCCESS;
  }

}
