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
// $Id: ADCAttributeM.perl.nc,v 1.2 2003/05/07 01:07:37 kaminw Exp $


/*
  This type of attribute can be set using the update() command, and the attribute
  will automatically read its own value from the ADC.
  
   This version must be used with a uint16_t or compatible type.

   you need to give it the parameter:
   ${ADC_channel} = channel to read from on the ADC
*/


module ${Attribute}M
{
  provides interface ${Attribute};
  provides interface StdControl;
  uses interface ADC;
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

  command void ${Attribute}.update( )
  {
	  dbg(DBG_USR1,"ADC ATTR: readings from channel ${ADC_channel}");
	  call ADC.getData();
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

  event ADC.dataReady(uint16_t val)
  {
	  call ${Attribute}.set(val);
  }
}

