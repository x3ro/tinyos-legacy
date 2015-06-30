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
// $Id: TinyVizAttributeM.perl.nc,v 1.2 2003/05/07 01:07:38 kaminw Exp $

/*
  This type of attribute can be set using the NeighborhoodAttribute plugin for
TinyViz, which checks for the dbg messages and sets the appropriate adc value.

   This particular version can be used with any uint16_t type.  See the
   TinyVizAttributes in /localization and /ranging for examples of how
   to extend this to other data types.

   you need to give it the parameters:
   ${ADC_channel} = channel for new attribute value
*/



module ${Attribute}M
{
  provides interface ${Attribute};
  provides interface StdControl;
}
implementation
{
  ${Type} m_value;

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
    dbg(DBG_USR1,"ADC ATTR: readings from channel ${ADC_channel}");
    return generic_adc_read(TOS_LOCAL_ADDRESS,${ADC_channel},0);
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

