/**
 * Copyright (c) 2004,2005 Hewlett-Packard Company
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
 * Verify we can register with a service and see the patient view
 *
 * @author Andrew Christian
 * 24 November 2004
 */



module TestPatientViewM {
  provides {
    interface StdControl;
    interface ParamView;
  }
  uses {
    interface Timer;
    interface Leds;
    
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;
    interface UIP;
    interface Client;

    interface Telnet;

    interface PatientView;
    interface ServiceQuery;

  }
}
implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

#define TIMER_INTERVAL 5000
#define TIMER_FAST_INTERVAL 1000

 char PatientName[64] = "Baby Girl Soliman";
 char PatientID[64] = "123456789";
  
  struct ServiceQuery g_service_info;

  command result_t StdControl.init() {

    call Leds.init();
    call PVStdControl.init();
    call IPStdControl.init();
    call TelnetStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {

    call IPStdControl.start();
    call TelnetStdControl.start();

    call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);

    return SUCCESS;
    
  }
  
  command result_t StdControl.stop() {
    call Timer.stop();
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  event result_t Timer.fired() {

    return SUCCESS;
  }

  
  /*****************************************
   *  Client interface
   *****************************************/
  event void Client.connected( bool isConnected )
  {
    if (isConnected){
      //call Leds.redOn();
      call ServiceQuery.startQuery("ekg", NULL, NULL, NULL, 60);
    }
  }

  /*****************************************
   *  ServiceQuery
   *****************************************/
  event void ServiceQuery.serviceFound(struct ServiceQuery *sq)
  {
    memcpy(&g_service_info, sq, sizeof(g_service_info));
  }

  /*****************************************
   *  Telnet interface
   *****************************************/

  event const char * Telnet.token() { return "query"; }
  event const char * Telnet.help() { return "Service query\r\n"; }

  event char * Telnet.process( char *in, char *out, char *outmax )
  {
    out += snprintf(out, outmax - out, "This doesn't do anything\r\n");
    return out;
  }

  /*****************************************
   *  PatientView interface
   *****************************************/

  event void PatientView.changed() {
    const struct Patient *patientInfo = call PatientView.getPatientInfo();
    // copy bits where we need them
  }


  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_Test[] = {
    { "sname", PARAM_TYPE_STRING, &g_service_info.sname[0] },
    { "stype", PARAM_TYPE_STRING, &g_service_info.stype[0] },
    { "status", PARAM_TYPE_STRING, &g_service_info.status[0] },
    { "ipaddr", PARAM_TYPE_STRING, &g_service_info.ipaddr[0] },
    { "port", PARAM_TYPE_UINT16, &g_service_info.port },
    { "deviceid", PARAM_TYPE_STRING, &g_service_info.deviceid[0] },
    { NULL, 0, NULL }
  };

  struct ParamList g_TestList = { "test", &s_Test[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_TestList );
    return SUCCESS;
  }

}




