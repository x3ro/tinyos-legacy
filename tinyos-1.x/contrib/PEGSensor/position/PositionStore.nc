/*									tab:4
 *
 *
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * Description: Simple data store component for July demo.
 * History:   July 9, 2003         Inception.
 *
 */


//!! Config 107 { LocationInfo_t EvaderInfo = { isAnchor:FALSE, realLocation:{ pos:{x:65535u, y:65535u }, stdv:{x:65535u, y:65535u}}, localizedLocation:{pos:{x:65535u, y:65535u }, stdv:{x:65535u, y:65535u}}}; }


//!! Config 108 {bool useWhichPosition = POSITION_HARDCODED;}

//!! Config 109 {bool useEstimatedEvader = FALSE;}

includes LocalizationConfig;
includes Config;

module PositionStore {
  provides interface StdControl;
  provides interface EvaderDemoStore;
}

implementation {

  LocationInfo_t HardcodedInfo =  { isAnchor:FALSE, realLocation:{ pos:{x:65535u, y:65535u }, stdv:{x:65535u, y:65535u}}, localizedLocation:{pos:{x:65535u, y:65535u }, stdv:{x:65535u, y:65535u}}};

  command result_t StdControl.init() {return SUCCESS;}
  command result_t StdControl.start() {return SUCCESS;}
  command result_t StdControl.stop() {return SUCCESS;}

  command uint16_t EvaderDemoStore.getPositionX() {
    switch(G_Config.useWhichPosition) {
    case POSITION_LOCALIZED:
      return call EvaderDemoStore.getLocalizedPositionX();
    case POSITION_WORD:
      return call EvaderDemoStore.getRealPositionX();
    case POSITION_HARDCODED:
      return call EvaderDemoStore.getHardcodedPositionX();
    default:
      return 65535u;
    }
  }
  
  command uint16_t EvaderDemoStore.getPositionY() {
    switch(G_Config.useWhichPosition) {
    case POSITION_LOCALIZED:
      return call EvaderDemoStore.getLocalizedPositionY();
    case POSITION_WORD:
      return call EvaderDemoStore.getRealPositionY();
    case POSITION_HARDCODED:
      return call EvaderDemoStore.getHardcodedPositionY();
    default:
      return 65535u;
    }
  }
 
  command location_t EvaderDemoStore.getPosition() {
    switch(G_Config.useWhichPosition) {
    case POSITION_LOCALIZED:
      return call EvaderDemoStore.getLocalizedPosition();
    case POSITION_WORD:
      return call EvaderDemoStore.getRealPosition();
    case POSITION_HARDCODED:
      return call EvaderDemoStore.getHardcodedPosition();
    default:
      return call EvaderDemoStore.getHardcodedPosition();
    }
  }
  
  command void EvaderDemoStore.useWhichPosition(PositionType type) {
    G_Config.useWhichPosition = type;
  }
  command void EvaderDemoStore.setIsAnchor(bool isAnchor) {
    G_Config.LocationInfo.isAnchor = isAnchor;
  }
  command bool EvaderDemoStore.getIsAnchor() {
    return G_Config.LocationInfo.isAnchor;
  }
  command void EvaderDemoStore.setPosition(LocationInfo_t pos) {
    G_Config.LocationInfo = pos;
  }

  command uint16_t EvaderDemoStore.getLocalizedPositionX() {
    return G_Config.LocationInfo.localizedLocation.pos.x;
  }
  command uint16_t EvaderDemoStore.getLocalizedPositionY() {
    return G_Config.LocationInfo.localizedLocation.pos.y;
  }
  command location_t EvaderDemoStore.getLocalizedPosition() {
    return G_Config.LocationInfo.localizedLocation;
  }
  command void EvaderDemoStore.setLocalizedPosition(uint16_t x, uint16_t y) {
    G_Config.LocationInfo.localizedLocation.pos.x = x;
    G_Config.LocationInfo.localizedLocation.pos.y = y;
  }
  command void EvaderDemoStore.setLocalizedLoc(location_t loc) {
    G_Config.LocationInfo.localizedLocation = loc;
  }

  command uint16_t EvaderDemoStore.getRealPositionX() {
    return G_Config.LocationInfo.realLocation.pos.x;
  }
  command uint16_t EvaderDemoStore.getRealPositionY() {
    return G_Config.LocationInfo.realLocation.pos.y;
  }
  command location_t EvaderDemoStore.getRealPosition() {
    return G_Config.LocationInfo.realLocation;
  }
  command void EvaderDemoStore.setRealPosition(uint16_t x, uint16_t y) {
    G_Config.LocationInfo.realLocation.pos.x = x;
    G_Config.LocationInfo.realLocation.pos.y = y;
  }
  command void EvaderDemoStore.setRealLoc(location_t loc) {
    G_Config.LocationInfo.realLocation = loc;
  }
  
  command uint16_t EvaderDemoStore.getHardcodedPositionX() {
    return HardcodedInfo.realLocation.pos.x;
  }
  command uint16_t EvaderDemoStore.getHardcodedPositionY() {
    return HardcodedInfo.realLocation.pos.y;
  }
  command location_t EvaderDemoStore.getHardcodedPosition() {
    return HardcodedInfo.realLocation;
  }
  command void EvaderDemoStore.setHardcodedPosition(uint16_t x, uint16_t y) {
    HardcodedInfo.realLocation.pos.x = x;
    HardcodedInfo.realLocation.pos.y = y;
  }
  command void EvaderDemoStore.setHardcodedLoc(location_t loc) {
    HardcodedInfo.realLocation = loc;
  }
  
  command uint16_t EvaderDemoStore.getEvaderX() {
    if (G_Config.useEstimatedEvader) {
      return call EvaderDemoStore.getEstimatedEvaderX();
    }
    else {
      return call EvaderDemoStore.getRealEvaderX();
    }
  }
  command uint16_t EvaderDemoStore.getEvaderY(){
    if (G_Config.useEstimatedEvader) {
      return call EvaderDemoStore.getEstimatedEvaderY();
    }
    else {
      return call EvaderDemoStore.getRealEvaderY();
    }
  }
  command location_t EvaderDemoStore.getEvader(){
    if (G_Config.useEstimatedEvader) {
      return call EvaderDemoStore.getEstimatedEvader();
    }
    else {
      return call EvaderDemoStore.getRealEvader();
    }
  }
 
  command void EvaderDemoStore.setEvader(LocationInfo_t pos) {
    G_Config.EvaderInfo = pos;
  }
  command void EvaderDemoStore.useEstimatedEvader(bool use) {
    G_Config.useEstimatedEvader = use;
  }
  
  command uint16_t EvaderDemoStore.getEstimatedEvaderX() {
    return G_Config.EvaderInfo.localizedLocation.pos.x;
  }
  command uint16_t EvaderDemoStore.getEstimatedEvaderY() {
    return G_Config.EvaderInfo.localizedLocation.pos.y;
  }
  command location_t EvaderDemoStore.getEstimatedEvader() {
    return G_Config.EvaderInfo.localizedLocation;
  }
  command void EvaderDemoStore.setEstimatedEvader(uint16_t x, uint16_t y) {
    G_Config.EvaderInfo.localizedLocation.pos.x = x;
    G_Config.EvaderInfo.localizedLocation.pos.y = y;
  }
  command void EvaderDemoStore.setEstimatedEvaderLoc(location_t loc) {
    G_Config.EvaderInfo.localizedLocation = loc;
  }

  command uint16_t EvaderDemoStore.getRealEvaderX() {
    return G_Config.EvaderInfo.realLocation.pos.x;
  }
  command uint16_t EvaderDemoStore.getRealEvaderY() {
    return G_Config.EvaderInfo.realLocation.pos.y;
  }
  command location_t EvaderDemoStore.getRealEvader() {
    return G_Config.EvaderInfo.realLocation;
  }
  command void EvaderDemoStore.setRealEvader(uint16_t x, uint16_t y) {
    G_Config.EvaderInfo.realLocation.pos.x = x;
    G_Config.EvaderInfo.realLocation.pos.y = y;
  }
  command void EvaderDemoStore.setRealEvaderLoc(location_t loc) {
    G_Config.EvaderInfo.realLocation = loc;
  }
}
