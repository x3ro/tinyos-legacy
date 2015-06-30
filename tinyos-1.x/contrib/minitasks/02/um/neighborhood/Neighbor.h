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
// $Id: Neighbor.h,v 1.1 2003/06/02 12:34:17 dlkiskis Exp $

#ifndef _H_Neighbor_h
#define _H_Neighbor_h

#include <NeighborExt.h>

typedef Neighbor_t* NeighborPtr_t;

typedef struct {
  uint16_t address;
  uint8_t tupletype;
} TupleMsgHeader_t;

typedef struct{
  const Neighbor_t* tuple;
} TupleIterator_t;

enum {
  MAX_NEIGHBORS = 9,
};

// Temporary for piecewise testing
NeighborPtr_t G_Neighbors;
NeighborPtr_t G_NeighborsBegin;
NeighborPtr_t G_NeighborsEnd;

void init_neighbors()
{
  NeighborPtr_t ii = G_NeighborsBegin;
  while( ii != G_NeighborsEnd )
    *ii++ = G_DefaultNeighbor;
}

#endif // _H_Neighbor_h

