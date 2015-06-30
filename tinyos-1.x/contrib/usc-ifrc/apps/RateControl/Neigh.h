/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

#ifndef NEIGH_H
#define NEIGH_H

/* It need to be noted that the parent,
 * the children and all the other 
 * interfering node are neighbour 
 * thus their information is stored in 
 * the neighbour table.
 */

/* used for  neighInfo.type */
enum { 
    PARENT = 0, 
    CHILD = 1,
    NEIGH = 2,    	
    NEIGHCHILD = 3,
    INVALID = 4,
};

typedef struct _neighInfo {

    uint16_t neighId; 
    uint32_t neighRLocal;
    uint32_t neighRThresh;
    uint8_t  neighMode; 
    uint32_t neighSSThresh; 

    uint16_t neighCongChildId; 
    uint32_t neighCongChildRLocal;
    uint32_t neighCongChildRThresh;
    uint8_t  neighCongChildMode; 

    /* Inferred Parameters */
    /* Is the neighbour a PARENT, CHILD, 
       NEIGH(interfering node) or INVALID
       (entry is not valid)
     */
    uint8_t type;
    uint8_t age;

    uint8_t neighTransition;
    uint8_t neighCongChildTransition;

#ifdef LOG_LINKLOSS
    uint16_t lastFwdSeq; 
    uint16_t packLoss;
    uint16_t packCount;
#endif 


} neighInfo;


#endif 
