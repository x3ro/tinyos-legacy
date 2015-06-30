//$Id: BitVectorC.nc,v 1.1.1.1 2007/11/05 19:11:30 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Utilities for manipulating a vector of bits.
 * <p>
 * Instantiate this generic component with the number of bits required
 * for the BitVector.  Ie:
 * <p>
 * <tt>new BitVectorC(16);</tt>
 * <p>
 * for a 16-bit vector.  Be sure to initialize by using the Init interface.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic module BitVectorC( uint16_t max_bits )
{
  provides interface Init;
  provides interface BitVector;
}
implementation
{
  typedef uint8_t int_type;

  enum
  {
    ELEMENT_SIZE = 8*sizeof(int_type),
    ARRAY_SIZE = (max_bits + ELEMENT_SIZE-1) / ELEMENT_SIZE,
  };

  int_type m_bits[ ARRAY_SIZE ];

  uint16_t getIndex( uint16_t bitnum )
  {
    return bitnum / ELEMENT_SIZE;
  }

  uint16_t getMask( uint16_t bitnum )
  {
    return 1 << (bitnum % ELEMENT_SIZE);
  }

  command result_t Init.init()
  {
    call BitVector.clearAll();
    return SUCCESS;
  }

  async command void BitVector.clearAll()
  {
    atomic memset( m_bits, 0, sizeof(m_bits) );
  }

  async command void BitVector.setAll()
  {
    atomic memset( m_bits, 255, sizeof(m_bits) );
  }

  async command bool BitVector.get( uint16_t bitnum )
  {
    atomic return (m_bits[getIndex(bitnum)] & getMask(bitnum)) ? TRUE : FALSE;
  }

  async command void BitVector.set( uint16_t bitnum )
  {
    atomic m_bits[getIndex(bitnum)] |= getMask(bitnum);
  }

  async command void BitVector.clear( uint16_t bitnum )
  {
    atomic m_bits[getIndex(bitnum)] &= ~getMask(bitnum);
  }

  async command void BitVector.toggle( uint16_t bitnum )
  {
    atomic m_bits[getIndex(bitnum)] ^= getMask(bitnum);
  }

  async command void BitVector.assign( uint16_t bitnum, bool value )
  {
    if( value )
      call BitVector.set( bitnum );
    else
      call BitVector.clear( bitnum );
  }

  async command uint16_t BitVector.size()
  {
    return max_bits;
  }
}

