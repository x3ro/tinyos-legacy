// $Id: adjacency_list.h,v 1.3 2003/10/07 21:46:32 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors: Nelson Lee
 *
 */
/*
 *
 *   FILE: adjacency_list.h
 * AUTHOR: nalee
 *   DESC: adjacency list abstraction for radio models
 *
 * Adjacency lists represent connectivity of network graphs simulated in Nido
 * An abstraction for allocating and de-allocating adjacency list chains is provided
 * so that smart memory allocation techniques can be implemented.
 *
 * radio models using adjacency lists must first call adjacency_list_init before calling
 * either allocate_link or deallocate_link
 */

/**
 * @author Nelson Lee
 * @author nalee
 */


#ifndef ADJACENCY_LIST_H_INCLUDED
#define ADJACENCY_LIST_H_INCLUDED

enum {
  NUM_NODES_ALLOC = 200
  
};

typedef struct link {
  int mote;
  double data;
  char bit;
  struct link* next_link;  
} link_t;


link_t* free_list;
int num_free_links;

link_t* allocate_link(int mote);
int deallocate_link(link_t* fLink);
int adjacency_list_init();


#endif // ADJACENCY_LIST_H_INCLUDED



