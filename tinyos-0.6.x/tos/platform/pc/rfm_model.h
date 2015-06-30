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
 *   FILE: rfm_model.h
 * AUTHOR: pal
 *   DESC: Model for RF connectivity.
 *
 *   This file declares the interface used by TOSSIM for radio simulation.
 *   There are currently three implementations of this interface:
 *   simple, static, and space. Simple and static are defined in rfm_model.c,
 *   while space is defined in its own file.
 *
 *   A data pointer is provided so that large structures can be
 *   dynamically allocated. Otherwise, the simulation has to allocate
 *   the regions of memory for every model, even though only one is in use.
 */

#ifndef RFM_MODEL_H_INCLUDED
#define RFM_MODEL_H_INCLUDED

typedef struct {
  void(*init)();
  void(*transmit)(int, char);   // int moteID, char bit
  void(*stop_transmit)(int);    // int moteID
  char(*hears)(int);            // char bit,   int moteID
  void* data;                
} rfm_model;

// In the simple model, all motes are in a single cell
rfm_model* create_simple_model();

// In the static model, the connectivity graph is determined at simulator
// boot and never changes.
rfm_model* create_static_model();


#endif // HEAP_H_INCLUDED
