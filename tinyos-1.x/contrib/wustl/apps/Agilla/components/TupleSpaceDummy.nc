// $Id: TupleSpaceDummy.nc,v 1.2 2006/05/18 19:58:40 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2006, Washington University in Saint Louis 
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
includes TupleSpace;
includes AgillaOpcodes;

/**
 * A dummy implementation of the tuple space
 *
 * @author Chien-Liang Fok
 */
module TupleSpaceDummy {
  provides {
    interface TupleSpaceI as TS;
    interface StdControl;
  }
}

implementation {
 
  command result_t StdControl.init() {       
    return SUCCESS;
  }

  command result_t StdControl.start() {             
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }


  /**
   * Places a tuple into the tuple space.
   *
   * @param tuple The tuple to insert.
   * @return SUCCESS if the operation was completed, FAIL if the tuple space
   * is full.
   */
  command result_t TS.out(AgillaTuple* tuple) 
  {        
    return SUCCESS;
  }
  
  /**
   * Remove a tuple from the tuple space matching the specified template.
   * Return FAIL if no matching tuple was found.  If a match is found, return
   * SUCCESS and store it within the template.  
   *
   * @param template The template.
   * @return SUCCESS if a match was found, FAIL if no match was found.
   */
  command result_t TS.hinp(AgillaTuple* template) {   
    return  FAIL;
  }

  /**
   * Find a tuple matching the specified template.
   * Return FAIL if no matching tuple was found.
   * Return SUCCESS If a match is found, and store the results in the template
   *
   * @param template The template.
   * @return SUCCESS if a match was found, FAIL if no match was found, or RETRY
   * if the tuple space is busy.
   */
  command result_t TS.rdp(AgillaTuple* template) {
    return FAIL;
  }

  command result_t TS.count(AgillaAgentContext* context, AgillaTuple* template) {         
    return FAIL;
  }
  
  /**
   * Fetches the next tuple matching the specified template starting 
   * at the specified index. Saves the resulting tuple in the supplied 
   * tuple pointer.  If the resulting tuple's size is 0, no tuple is found
   * and the return value is the free index within the tuple space.
   *
   * @param start The starting address of the tuple
   * @param tuple A pointer to where the results should be stored.
   * @return The index at which to start next time.
   */
  command uint16_t TS.getMatchingTuple(uint16_t start, AgillaTuple* template,
    AgillaTuple* tuple) 
  {
    return FAIL;
  }

  /**
   * Prints the contents of the tuplespace.  This is only used while
   * debugging in TOSSIM.
   */  
  command result_t TS.toString() {   
    return SUCCESS;
  }
  
  
  command result_t TS.reset() {   
    return SUCCESS;
  }
}
