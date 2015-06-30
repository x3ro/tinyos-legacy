// $Id: LocationMgrM.nc,v 1.7 2006/09/27 04:20:32 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis 
 * By Chien-Liang Fok.
 * 
 * Washington University states that Agilla is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * Agilla is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.  
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using Agilla. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */

includes Agilla;
includes SpaceLocalizer;
includes LEDBlinker;

/**
 * Implements a virtual grid topology through which mote addresses may be
 * mapped to specific location and vice-versa.  Also interfaces with the
 * components that interact with the Cricket motes to obtain physical 
 * location data.
 *
 * @author Chien-Liang Fok
 */
module LocationMgrM {
  provides {
    interface StdControl;
    interface LocationMgrI;
  }
  uses {
    // The following interfaces allow the grid size to change.
    interface Timer as GridSizeTimer;
    interface ReceiveMsg as ReceiveGridSizeMsg;
    interface SendMsg as SendGridSizeMsg;
    
    // Interfaces with the Cricket 2 Motes.
    #if ENABLE_SPACE_LOCALIZER
    #ifdef TOSH_HARDWARE_MICA2
      interface SpaceLocalizerI;
      interface StdControl as RadioControl;
      interface CC1000Control;
      interface LEDBlinkerI;
      //interface Timer as MoveTimer;
    #endif
    #endif
    
    interface Leds;
  }
}
implementation {
  /**
   * This is the number of rows and columns.  It is initialized to
   * DEFAULT_NUM_COLUMNS as defined within Makefile.Agilla.
   * It can be changed by broadcasting an AgillaGridSizeMsg
   */
  uint16_t numColumns;

  /**
   * Keeps track of whether this mote is in the midst of changing
   * grid sizes.
   */
  bool changingGridSize;  
  
  /**
   * A buffer for sending grid update messages.
   */
  TOS_Msg msg;
  
  /**
   * The number of times the LEDs blinked after the mote changed spaces.
   */
  //uint8_t moveCount;
  
  command result_t StdControl.init() {    
    numColumns = DEFAULT_NUM_COLUMNS;
    changingGridSize = FALSE;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop()  {
    return SUCCESS;
  }  
  
  /**
   * Converts an address to a location.
   *
   * @param addr The address.
   * @param loc The location.
   */
  command result_t LocationMgrI.getLocation(uint16_t addr, AgillaLocation* loc) {
    if (addr == TOS_BCAST_ADDR) {
      loc->x = BCAST_X;
      loc->y = BCAST_Y;
    } 
    else if (addr == TOS_UART_ADDR) {
      loc->x = UART_X;
      loc->y = UART_Y;
    } 
    else {
      //loc->x = (addr-1) % numColumns + 1;
      //loc->y = (addr - loc->x)/numColumns + 1;   
      loc->x = (addr) % numColumns + 1;
      loc->y = (addr - loc->x + 1)/numColumns + 1;         
    }
    return SUCCESS;
  }
  
  /**
   * Converts a location to an address.
   *
   * @param loc The location to convert.
   * @return The address of the node at that location.
   */
  command uint16_t LocationMgrI.getAddress(AgillaLocation* loc) {
  
    // fs2:  Agent Group Comunication
    // check for device that are NOT base station, force_uart

    //if (loc->x == UART_X && loc->y == UART_Y)
    if ((loc->x == UART_X && loc->y == UART_Y) 
    	|| (loc->x == FORCE_UART_X && loc->y == FORCE_UART_Y))
      return TOS_UART_ADDR;      
    else if (loc->x == BCAST_X && loc->y == BCAST_Y)
      return TOS_BCAST_ADDR;
    else
     return loc->x + (loc->y - 1) * numColumns - 1;
  }    

  #if ENABLE_SPACE_LOCALIZER
  #ifdef TOSH_HARDWARE_MICA2
    /**
     * This event is generated whenever the closest
     * cricket beacon mote changes.  It passes the
     * name of the new closest space.
     */  
    event void SpaceLocalizerI.moved(char* spaceID) {
      uint32_t freq;
      call RadioControl.stop();
      if (strcmp("DOCK", spaceID) == 0) {
        freq = call CC1000Control.TuneManual(CC1000_CHANNEL_2);
         if (freq == CC1000_CHANNEL_2) {
           //moveCount = 0;
           //call MoveTimer.start(TIMER_REPEAT, 128);
           call LEDBlinkerI.blink(YELLOW | GREEN, 3, 128);
         }
      } else  {
        freq = call CC1000Control.TuneManual(CC1000_CHANNEL_4);
        if (freq == CC1000_CHANNEL_4) {
          //moveCount = 0;
          //call MoveTimer.start(TIMER_REPEAT, 128);
          call LEDBlinkerI.blink(YELLOW | GREEN, 3, 128);
        }
      }
      call RadioControl.start();   
    }

    /*event result_t MoveTimer.fired() {
      call Leds.yellowToggle();
      call Leds.greenToggle();
      if (++moveCount == 6)
        call MoveTimer.stop();
      return SUCCESS;
    }*/
    
    event result_t LEDBlinkerI.blinkDone() {
      return SUCCESS;
    }    
  #endif
  #endif

  // -----------------------------------------------------------------------------------------
  // The following methods allow the grid size to change.
  
  /**
   * Floods the grid size message.  Each mote only broadcasts once.   
   */
  event TOS_MsgPtr ReceiveGridSizeMsg.receive(TOS_MsgPtr m) {
    AgillaGridSizeMsg* gsmsg = (AgillaGridSizeMsg*)m->data;
           
    if (!changingGridSize) {  // only re-broadcast once (prevents recursive flooding)
      if (numColumns != gsmsg->numCol) {
        changingGridSize = TRUE;
        call Leds.redOn();
        call Leds.greenOn();
        call Leds.yellowOn();
        msg = *m;
        numColumns = gsmsg->numCol;
        call SendGridSizeMsg.send(TOS_BCAST_ADDR, sizeof(AgillaGridSizeMsg), &msg);
        call GridSizeTimer.start(TIMER_ONE_SHOT, 1024);  // wait for flooding to finish   
      }
    }         
    return m;
  }
  
  /**
   * Whenever the gridsize timer fires, turn off all LEDs and update the
   * new possible neighbors.
   */
  event result_t GridSizeTimer.fired() {
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();    
    changingGridSize = FALSE;    
    return SUCCESS;
  }  

  event result_t SendGridSizeMsg.sendDone(TOS_MsgPtr mesg, result_t success) {
    return SUCCESS;
  }    
}

