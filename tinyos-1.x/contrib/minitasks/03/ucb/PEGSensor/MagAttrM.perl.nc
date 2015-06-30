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
// $Id: MagAttrM.perl.nc,v 1.2 2003/06/22 00:44:05 cssharp Exp $


module ${Attribute}M
{
  provides interface ${Attribute};
  provides interface MagReadingAttr;
  provides interface MagPositionAttr;
  provides interface Valid as DataValid;
  provides interface Valid as ReadingValid;
  provides interface Valid as PositionValid;
  provides interface StdControl;
}
implementation
{
  enum
  {
    VALID_MAG_VAL = 0x01,
    VALID_MAG_POS = 0x02,
    VALID_ALL = (VALID_MAG_VAL | VALID_MAG_POS),
    VALID_NONE = 0,
  };

  ${Type} m_value;
  uint8_t m_valid;

  command result_t StdControl.init()
  {
    const ${Type} init = ${Init};
    m_value = init;
    m_valid = VALID_NONE;
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

  command MagReading_t MagReadingAttr.get()
  {
    return m_value.reading;
  }

  command MagPosition_t MagPositionAttr.get()
  {
    return m_value.position;
  }

  command void ${Attribute}.set( ${Type} value )
  {
    m_value = value;
    signal ${Attribute}.updated();
    signal MagReadingAttr.updated();
    signal MagPositionAttr.updated();
  }

  command void MagReadingAttr.set( MagReading_t value )
  {
    m_value.reading = value;
    signal ${Attribute}.updated();
    signal MagReadingAttr.updated();
  }

  command void MagPositionAttr.set( MagPosition_t value )
  {
    m_value.position = value;
    signal ${Attribute}.updated();
    signal MagPositionAttr.updated();
  }

  default event void ${Attribute}.updated()
  {
  }

  default event void MagReadingAttr.updated()
  {
  }

  default event void MagPositionAttr.updated()
  {
  }

  
  command void DataValid.set( bool valid )
  {
    m_valid = (valid == TRUE) ? VALID_ALL : VALID_NONE;
  }

  command bool DataValid.get()
  {
    return m_valid == VALID_ALL;
  }

  command void ReadingValid.set( bool valid )
  {
    if( valid == TRUE )
      m_valid |= VALID_MAG_VAL;
    else
      m_valid &= ~VALID_MAG_VAL;
  }

  command bool ReadingValid.get()
  {
    return (m_valid & VALID_MAG_VAL) != 0;
  }

  command void PositionValid.set( bool valid )
  {
    if( valid == TRUE )
      m_valid |= VALID_MAG_POS;
    else
      m_valid &= ~VALID_MAG_POS;
  }

  command bool PositionValid.get()
  {
    return (m_valid & VALID_MAG_POS) != 0;
  }
}

