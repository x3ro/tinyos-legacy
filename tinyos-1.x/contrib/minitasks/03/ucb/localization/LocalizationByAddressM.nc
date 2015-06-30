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

// Authors: Kamin Whitehouse

includes common_structs;
includes Localization;
includes Routing;
includes ClosestLocationNeighbors;

//!! AnchorHood = CreateNeighborhood( 2, ClosestLocationNeighbors, GenericCommBackend, 150 );
//!! LocationAttr = CreateAttribute( location_t = { pos:{x:0, y:0}, stdv:{x:32767, y:32767} } );
//!! LocationRefl = CreateReflection( AnchorHood, LocationAttr, FALSE, 200, 201 );




module LocalizationByAddressM
{
  provides
  {
    interface StdControl;
    interface Localization;
  }
  uses
  {
    interface LocationAttr;
    interface LocationAttrReflection as LocationRefl;
    interface LocationAttrReflectionSnoop as LocationReflSnoop;
    interface Neighborhood as AnchorHood;

    interface StdControl as LocationAttrControl;
    interface StdControl as AnchorHoodControl;

    interface Leds;
  }
}
implementation
{
  command result_t StdControl.init()
  {
    call LocationAttrControl.init();
    call AnchorHoodControl.init();
    return SUCCESS;
  }

  task void bootstrap()
  {
    TOSH_uwait(TOS_LOCAL_ADDRESS*30000);
    dbg(DBG_USR1, "LOC_BY_ADDRESS: bootstrapping by location\n");
    call AnchorHood.bootstrap();
  }

  command result_t StdControl.start()
  {
    call LocationAttrControl.start();
    call AnchorHoodControl.start();
    call Localization.estimateLocation();
    post bootstrap();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call LocationAttrControl.stop();
    call AnchorHoodControl.stop();
    return SUCCESS;
  }

//  event void LocationAttr.updated(location_t newLocation ){}
  event void LocationAttr.updated( ){}

  event void LocationRefl.updated(uint16_t address, location_t newLocation )
  { //set leds to his node id
    dbg(DBG_USR1, "LOC_BY_ADDRESS: got location from neighbor %d: x= %d, y= %d\n", address, newLocation.pos.x, newLocation.pos.y);
    if(address&1) call Leds.redOn(); else call Leds.redOff();
    if(address&2) call Leds.greenOn(); else call Leds.greenOff();
    if(address&4) call Leds.yellowOn(); else call Leds.yellowOff();
  }

  event void LocationReflSnoop.updatedNAN( RoutingDestination_t address, location_t newLocation ){
    dbg(DBG_USR1, "LOC_BY_ADDRESS: got location from NAN %d: x= %d, y= %d\n", address, newLocation.pos.x, newLocation.pos.y);
}

  event void AnchorHood.removingNeighbor( nodeID_t id ){
    location_t location = call LocationRefl.get(id);
//    dbg(DBG_USR1, "LOC_BY_ADDRESS: %d removed from nbhd: x= %d, y= %d\n", id, location.pos.x, location.pos.y);
}
  event void AnchorHood.addedNeighbor( nodeID_t id ){
    location_t location = call LocationRefl.get(id);
//    dbg(DBG_USR1, "LOC_BY_ADDRESS: %d added to nbhd: x= %d, y= %d\n", id, location.pos.x, location.pos.y);
}

  command void Localization.estimateLocation(){
    location_t my_location;
    my_location.pos.x = (TOS_LOCAL_ADDRESS >> 4) & 0x0f;
    my_location.pos.y = (TOS_LOCAL_ADDRESS     ) & 0x0f;
    my_location.stdv.x =0;
    my_location.stdv.y =0;
    //my_location.coordinate_system = (TOS_LOCAL_ADDRESS >> 8) & 0xff;
    dbg(DBG_USR1, "LOC_BY_ADDRESS: my location estimate: x= %d, y= %d\n", my_location.pos.x, my_location.pos.y);
    call LocationAttr.set(my_location);
  } 	
}

