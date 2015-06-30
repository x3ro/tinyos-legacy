// $Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/GpsMote/GpsMoteM.nc,v 1.4 2004/05/27 19:31:34 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Radu Stoleru
// Date: 3/26/2004


includes gps;

module GpsMoteM {
  provides interface StdControl;
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Leds;
    interface Timer;
    interface CC1000Control;

    interface LoggerRead;
    interface LoggerWrite;
  }
}

implementation {
  TOS_Msg      outBuffer;
  LocalizationStatus status;

  // we keep the reference point in NMEA format
  GpsCoord     referencePoint;
  NMEAGpsCoord nmeaReferencePoint;

  // current point in NMEA format
  NMEAGpsCoord nmeaCurrPoint;

  LocalCoord   x;
  LocalCoord   y;
  uint8_t     sendingPower;
  uint16_t    sendingPeriod;
  bool        pending;
  uint8_t     maxSendPerGps;

  // buffer to store the line from flash;
  uint8_t flashBuffer[16];

  void convertReferencePointRSCCToNMEA();
  void resetStateVariables();

  //****************************************************
  command result_t StdControl.init() {
    result_t ok1, ok2, ok3;

    // initialize the state
    resetStateVariables();

    // initialize the components below
    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();
    
    return rcombine3(ok1, ok2, ok3);
  }

  //****************************************************
  command result_t StdControl.start() {
    result_t ok1, ok2, ok3;
    
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();
    ok3 = call LoggerRead.read(FLASH_NUM_LINE_FOR_LOCALIZATION,
			       flashBuffer);

    return rcombine3(ok1, ok2, ok3);
  }

  //****************************************************
  command result_t StdControl.stop() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine(ok1, ok2);
  }

  //****************************************************
  void convertReferencePointRSCCToNMEA() {

    int32_t lat; 
    int32_t lon; 
    int32_t deg; 
    int32_t decMin; 
    int32_t sec;

    if(referencePoint.latitude < 0)
      lat = - referencePoint.latitude;
    else
      lat = referencePoint.latitude;

    if(referencePoint.longitude < 0)
      lon = - referencePoint.longitude;
    else
      lon = referencePoint.longitude;

    // latitude
    deg = floor(lat/3600000.0);
    decMin = floor((lat - 3600000.0*deg)/60000.0);
    sec = floor(lat - 3600000*deg - decMin*6000*10);

    nmeaReferencePoint.latDegree = deg;
    nmeaReferencePoint.latMinute = decMin + sec/(1000.0*60.0);

    // longitude
    deg = floor(lon/3600000.0);
    decMin = floor((lon - 3600000.0*deg)/60000.0);
    sec = floor(lon - 3600000*deg - decMin*6000*10);

    nmeaReferencePoint.lonDegree = deg;
    nmeaReferencePoint.lonMinute = decMin + sec/(1000.0*60.0);

    if(referencePoint.latitude > 0) nmeaReferencePoint.NSEWind |= 0x10;
    if(referencePoint.longitude > 0) nmeaReferencePoint.NSEWind |= 0x01;

    return;
  }
   
  //****************************************************
  task void computeLocalCoord() {    
    double latRef, lonRef, latCurr, lonCurr, flon, flat, avgLat, compl;
    double PI = 3.141592654;
    float a = 6378137;
    float b = 6356752.3142;
   
    latRef = nmeaReferencePoint.latDegree + nmeaReferencePoint.latMinute/60.0;
    lonRef = nmeaReferencePoint.lonDegree + nmeaReferencePoint.lonMinute/60.0;
    latCurr = nmeaCurrPoint.latDegree + nmeaCurrPoint.latMinute/60.0;
    lonCurr = nmeaCurrPoint.lonDegree + nmeaCurrPoint.lonMinute/60.0;

    if(!(nmeaReferencePoint.NSEWind & 0x10)) latRef = -latRef;
    if(!(nmeaReferencePoint.NSEWind & 0x01)) lonRef = -lonRef;
    if(!(nmeaCurrPoint.NSEWind & 0x10)) latCurr = -latCurr;
    if(!(nmeaCurrPoint.NSEWind & 0x01)) lonCurr = -lonCurr;
    
    avgLat = abs(latRef + latCurr)/2;
    
    compl = a*a*(cos(avgLat*PI/180)*cos(avgLat*PI/180))+
      b*b*(sin(avgLat*PI/180)*sin(avgLat*PI/180));
    
    flon = (a*a/sqrt(compl) + 200) * cos(avgLat*PI/180) * PI/180;    
    flat = (a*a*b*b/(compl*sqrt(compl)) + 200) * PI/180;

    y = flat * (latCurr - latRef);
    x = flon * (lonCurr - lonRef);
    
    maxSendPerGps = MAX_NUM_REPORTS_PER_GPS;

    return;
  }

  //****************************************************
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr msg) {
    GpsPacket *pack = (GpsPacket *) msg->data;

    if(msg->group != TOS_AM_GROUP || msg->type != AM_GPS_CHANNEL)
      return msg;

    if(pack->type == RESET) {
      call Timer.stop();

      resetStateVariables();

      call Leds.greenOff();
      call Leds.yellowOn();

      memset(flashBuffer, 0x00, 16);
      call LoggerWrite.write(FLASH_NUM_LINE_FOR_LOCALIZATION, flashBuffer);


    } else if(pack->type == INIT_GPS) {
      InitGpsPacket *payload = (InitGpsPacket *) pack->payload;
           
      call Leds.yellowOff();
      call Leds.greenOn();
      
      status = INITIALIZED;      
      memcpy(&referencePoint, &(payload->referencePoint), sizeof(GpsCoord));
      sendingPower = payload->sendingPower;
      sendingPeriod = payload->sendingPeriod*100;

      convertReferencePointRSCCToNMEA();

      memset(flashBuffer, 0x00, 16);
      flashBuffer[0] = 0xAB;
      flashBuffer[1] = 0xCD;
      memcpy((GpsCoord *) &(flashBuffer[2]), &referencePoint, 
	     sizeof(GpsCoord));
      flashBuffer[10] = (uint8_t) sendingPower;
      memcpy((uint16_t *) &(flashBuffer[11]), &sendingPeriod, 
	     sizeof(uint16_t));

      call LoggerWrite.write(FLASH_NUM_LINE_FOR_LOCALIZATION, flashBuffer);

      call CC1000Control.SetRFPower(sendingPower);
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, sendingPeriod);

    } else if(pack->type == DUMP_STATE) {

      GpsPacket *outPack = (GpsPacket *) outBuffer.data;
      InitGpsPacket *payload = (InitGpsPacket *) outPack->payload;

      // fill-in the mac header
      outBuffer.addr   = TOS_BCAST_ADDR;
      outBuffer.type   = AM_GPS_CHANNEL;
      outBuffer.group  = TOS_AM_GROUP;
      outBuffer.length = 18;

      // fill-in the payload
      outPack->sender = TOS_LOCAL_ADDRESS;
      outPack->type   = DUMP_STATE_REP;
      memcpy(&(payload->referencePoint), &referencePoint, sizeof(GpsCoord));
      payload->sendingPower = sendingPower;
      payload->sendingPeriod = sendingPeriod;

      call Leds.redToggle();

      if(!pending && call RadioSend.send(&outBuffer)) 
	pending = TRUE;
    } 
    
    return msg;
  }

  //****************************************************
  event result_t Timer.fired() {

    if(status == INITIALIZED &&  // make sure we have a reference point 
       maxSendPerGps > 0) {      // and received a GPS reading recently

      GpsPacket *pack = (GpsPacket *) outBuffer.data;
      InitLocalizationPacket *payload = 
	(InitLocalizationPacket *) pack->payload;

      // fill-in the mac header
      outBuffer.addr   = TOS_BCAST_ADDR;
      outBuffer.type   = AM_GPS_CHANNEL;
      outBuffer.group  = TOS_AM_GROUP;
      outBuffer.length = 18;

      // fill-in the payload
      pack->sender = TOS_LOCAL_ADDRESS;
      pack->type   = INIT_LOCALIZATION;
      memcpy(&(payload->referencePoint), &referencePoint, sizeof(GpsCoord));
      payload->x    = x;
      payload->y    = y;

      maxSendPerGps--;

#ifdef DEBUG
      maxSendPerGps++;
      x++;
#endif

      if(!pending && call RadioSend.send(&outBuffer)) 
	  pending = TRUE;
    }
    
    return SUCCESS;
  }

  //****************************************************
  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr msg) {
    NMEAGpsCoord *coordPtr = (NMEAGpsCoord *) msg->data;

    memcpy(&nmeaCurrPoint, coordPtr, sizeof(NMEAGpsCoord));

    post computeLocalCoord();    

    return msg;
  }
  
  //****************************************************
  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  
  //****************************************************
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    pending = FALSE;

    call Leds.redToggle();

    return SUCCESS;
  }

  //****************************************************
  event result_t LoggerRead.readDone(uint8_t *buffer, result_t res) {

    if(res == SUCCESS) {
      if(buffer[0] == 0xAB && buffer[1] == 0xCD) {
	memcpy(&referencePoint, (GpsCoord *) &(flashBuffer[2]), 
	       sizeof(GpsCoord));
	sendingPower = flashBuffer[10];
	memcpy(&sendingPeriod, (uint16_t *) &(flashBuffer[11]), 
	       sizeof(uint16_t));
	call Leds.greenOn();
	status = INITIALIZED;

	convertReferencePointRSCCToNMEA();

	call Timer.stop();
	call Timer.start(TIMER_REPEAT, sendingPeriod);

      }
      else
	call Leds.yellowOn();
    }

    return SUCCESS;
  }

  //****************************************************
  event result_t LoggerWrite.writeDone(result_t res) {
    return SUCCESS;
  }

  //****************************************************
  void resetStateVariables() {
    status = UNINITIALIZED;
    memset(&referencePoint, 0x00, sizeof(GpsCoord));
    memset(&nmeaReferencePoint, 0x00, sizeof(NMEAGpsCoord));
    memset(&nmeaCurrPoint, 0x00, sizeof(NMEAGpsCoord));
    x = 0;
    y = 0;
    sendingPower = 0x00;
    pending = FALSE;
    maxSendPerGps = 0;

#ifdef DEBUG
    maxSendPerGps = 1;
#endif

  }

}  
