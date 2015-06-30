/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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

// Authors: Cory Sharp
// $Id: TinyVizLocationAttributeM.perl.nc,v 1.1 2003/10/09 05:49:44 fredjiang Exp $

/*
  This type of attribute can be set using the NeighborhoodAttribute plugin for
TinyViz, which checks for the dbg messages and sets the appropriate adc value.

   This particular version must be used with a localization/Location_t type.

   you need to give it the parameters:
   ${X_pos_ADC_channel} = channel for x coordinate
   ${Y_pos_ADC_channel} = channel for y coordinate
   ${X_stdv_ADC_channel} = channel for x std dev
   ${Y_stdv_ADC_channel} = channel for y std dev
*/


module ${Attribute}M
{
  provides interface ${Attribute};
  provides interface StdControl;
  provides command void readFromTinyViz();
}
implementation
{
  ${Type} m_value;

  command void readFromTinyViz(){ //!!!!Change name later
    m_value.pos.x = G_Config.LocationInfo.realLocation.pos.x;
    m_value.pos.y = G_Config.LocationInfo.realLocation.pos.y;
    m_value.stdv.x = 0;
    m_value.stdv.y = 0; 
  }
  
  command result_t StdControl.init()
  {
    const ${Type} init = ${Init};
    m_value = init;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  command ${Type} ${Attribute}.get()
  {
	return m_value;
  }

  command void ${Attribute}.set( ${Type} value )
  {
    m_value = value;
    signal ${Attribute}.updated();
  }

  default event void ${Attribute}.updated()
  {
  }

}


