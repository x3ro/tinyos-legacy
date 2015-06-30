/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: heap.h
 * AUTHOR: pal
 *   DESC: Simple tree-based priority heap for discrete event simulation.
 *
 *  NOTE: TOSSIM currently does not use this heap structure. It uses an
 *  array-based heap for performance reasons.
 */

#ifndef HEAP_H_INCLUDED
#define HEAP_H_INCLUDED

typedef struct {
  void* top;
  void* last;
  void* free;
  int size;
} heap_t;

void init_heap(heap_t* heap);
int heap_size(heap_t* heap);
int heap_is_empty(heap_t* heap);

long long heap_get_min_key(heap_t* heap);
void* heap_peek_min_data(heap_t* heap);
void* heap_pop_min_data(heap_t* heap, long long* key);
void heap_insert(heap_t * heap, void* data, long long key);


#endif // HEAP_H_INCLUDED
