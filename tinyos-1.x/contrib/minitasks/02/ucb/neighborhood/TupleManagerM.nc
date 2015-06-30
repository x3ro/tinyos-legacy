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
// $Id: TupleManagerM.nc,v 1.6 2003/01/27 21:37:36 cssharp Exp $


module TupleManagerM
{
  provides interface StdControl;
  provides interface TupleManager;
  uses interface TupleStore;
}
implementation
{
  Neighbor_t m_emptyTuple;

  command result_t StdControl.init()
  {
    m_emptyTuple = G_DefaultNeighbor;
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

  command NeighborPtr_t TupleManager.getByAddress(uint16_t address)
  {
     // if the given address exists in the tuple store, return it
     NeighborPtr_t tuple = call TupleStore.privateGetByAddress(address);
     if( tuple != 0 )
       return tuple;
     // otherwise return the empty rule
     m_emptyTuple = G_DefaultNeighbor;
     m_emptyTuple.address = address;
     return &m_emptyTuple;
  }

  //this implementation of the TupleManager fills the neighbor table
  //and never changes it.
  command void TupleManager.setTuple(NeighborPtr_t newTuple)
  {
     // first try to replace the tuple with the existing address.
     // otherwise, look for an empty tuple.
     NeighborPtr_t tuple = call TupleStore.privateGetByAddress( newTuple->address );
     if( tuple == 0 )
      tuple = call TupleStore.privateGetByAddress(0);
     if(tuple!=0)
	*tuple = *newTuple;
  }

}

