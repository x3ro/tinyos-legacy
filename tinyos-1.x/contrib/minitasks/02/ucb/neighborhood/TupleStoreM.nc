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

// Authors: Cory Sharp
// $Id: TupleStoreM.nc,v 1.6 2003/01/27 21:37:54 cssharp Exp $

includes Neighbor;

module TupleStoreM
{
  provides interface TupleStore;
  provides interface StdControl;
}
implementation
{
  Neighbor_t m_tuples[MAX_NEIGHBORS];

  command result_t StdControl.init()
  {
    // CSS: guarantee that a tuple is reserved for TOS_LOCAL_ADDRESS
    m_tuples[0].address = TOS_LOCAL_ADDRESS;
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

  NeighborPtr_t getByAddress(uint16_t address)
  {
    uint8_t tuple;
    for(tuple=0;tuple<MAX_NEIGHBORS;tuple++ ){
      if(m_tuples[tuple].address == address ){
	return m_tuples + tuple;
      }
    }
    return 0;
  }

  command NeighborPtr_t TupleStore.getByAddress(uint16_t address)
  {
    return getByAddress(address);
  }

  command NeighborPtr_t TupleStore.privateGetByAddress(uint16_t address)
  {
    return getByAddress(address);
  }

  command TupleIterator_t TupleStore.initIterator()
  {
    TupleIterator_t iterator = { tuple:0 };
    return iterator;
  }

  command bool TupleStore.getNext(TupleIterator_t* iterator)
  {
    NeighborPtr_t tuple_end = m_tuples + MAX_NEIGHBORS;

    if( iterator->tuple != tuple_end )
    {
      if( iterator->tuple == 0 )
	iterator->tuple = m_tuples;
      else
	iterator->tuple++;

      while( iterator->tuple != tuple_end )
      {
	if( iterator->tuple->address != 0 )
	  return TRUE;
        iterator->tuple++;
      }
    }

    return FALSE;
  }
}

