/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Cory Sharp and Kamin Whitehouse

includes common_structs;
includes Localization;
//!! SensorAttr = CreateAttribute( uint16_t = 0 );
//!! ObjectLocationAttr = CreateAttribute( location_t = { pos:{x:0, y:0, z:0}, stdv:{x:32767, y:32767, z:32767}, coordinate_system:0 } );
//!! SensorRefl = CreateReflection( AnchorHood, SensorAttr, TRUE, 202, 203 );

module ObjectTrackingM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Clock;
    interface ADC;
    interface Leds;

    interface SensorAttr;
    interface LocationAttr;
    interface ObjectLocationAttr;
    interface SensorAttrReflection as SensorRefl;
    interface LocationAttrReflection as LocationRefl;
    interface Neighborhood as AnchorHood;

    interface StdControl as SensorAttrControl;
    interface StdControl as ObjectLocationAttrControl;
    interface StdControl as AnchorHoodControl;
  }
}
implementation
{
  command result_t StdControl.init()
  {
    call SensorAttrControl.init();
    call ObjectLocationAttrControl.init();
    call AnchorHoodControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call SensorAttrControl.start();
    call ObjectLocationAttrControl.start();
    call AnchorHoodControl.start();
    return call Clock.setRate(TOS_I4PS, TOS_S4PS);
  }

  command result_t StdControl.stop()
  {
    call SensorAttrControl.stop();
    call ObjectLocationAttrControl.stop();
    call AnchorHoodControl.stop();
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }


  task void estimateObjectLocation();

  event result_t Clock.fire()
  {
    //call ADC.getData();
    dbg(DBG_USR3, "OBJ_TRAC: Clock event\n");
    call ADC.getData();
    post estimateObjectLocation();
    return SUCCESS;
  }


  event result_t ADC.dataReady( uint16_t val )
  {
    dbg(DBG_USR3, "OBJ_TRAC: ADC data ready event, value: %d\n", val);
    call SensorAttr.set(val);
    return SUCCESS;
  }


  task void estimateObjectLocation()
  {
    location_t neighborLocation, myLocation=call LocationAttr.get();
    uint16_t neighborSensor, sensorSum, mySensor=call SensorAttr.get();
    uint16_t x=0,y=0,xstdv=0,ystdv=0;
    nodeID_t ID;
    uint8_t i,numNeighbors = call AnchorHood.numNeighbors();

    dbg(DBG_USR3, "OBJ_TRAC: esimating object location\n");

    for(i=0;i<numNeighbors;i++){
	ID = call AnchorHood.getNeighbor(i);
	neighborLocation = call LocationRefl.get(ID);
	neighborSensor = call SensorRefl.get(ID);

	//leader election
	if( mySensor < neighborSensor )
	  return;
	
	//weighted center of mass
	x += neighborSensor * neighborLocation.pos.x;
	y += neighborSensor * neighborLocation.pos.y;
	xstdv += neighborSensor * neighborLocation.stdv.x;
	ystdv += neighborSensor * neighborLocation.stdv.y;
	sensorSum += neighborSensor;
    }

    x += mySensor * myLocation.pos.x;
    y += mySensor * myLocation.pos.y;
    xstdv += mySensor * myLocation.stdv.x;
    ystdv += mySensor * myLocation.stdv.y;
    sensorSum += mySensor;

    neighborLocation.pos.x= (x*256) / sensorSum;
    neighborLocation.pos.y= (y*256) / sensorSum;
    neighborLocation.pos.z= 0;
    neighborLocation.stdv.x= (xstdv*256) / sensorSum;
    neighborLocation.stdv.y= (ystdv*256) / sensorSum;
    neighborLocation.stdv.z= 0;
    neighborLocation.coordinate_system= myLocation.coordinate_system;
    dbg(DBG_USR3, "OBJ_TRAC: object location is x: %d, y: %d\n", neighborLocation.pos.x, neighborLocation.pos.y);
    call ObjectLocationAttr.set(neighborLocation);
  }

  event void ObjectLocationAttr.updated(){
    dbg(DBG_USR3, "OBJ_TRAC: object location estimate updated\n");
  }

  event void SensorAttr.updated( ){
  }

  event void LocationAttr.updated( ){
  }

  event void SensorRefl.updated( nodeID_t id, uint16_t value ){
    dbg(DBG_USR3, "OBJ_TRAC: saw neighbor %d sensor value %d\n", id, value);
  }

  event void LocationRefl.updated( nodeID_t id, location_t value ){}

  event void AnchorHood.removingNeighbor( nodeID_t id ){}
  event void AnchorHood.addedNeighbor( nodeID_t id ){}




}






