// $Id: rfm_model.h,v 1.7 2003/10/07 21:46:35 idgay Exp $

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
 *
 * Authors:             Philip Levis, Nelson Lee
 *
 */

/*
 *   FILE: rfm_model.h
 * AUTHOR: pal
 *   DESC: Model for RF connectivity.
 *
 *   This file declares the interface used by NIDO for radio simulation.
 *   There are currently three implementations of this interface:
 *   simple, static, and space. Simple and static are defined in rfm_model.c,
 *   while space is defined in its own file.
 *
 *   A data pointer is provided so that large structures can be
 *   dynamically allocated. Otherwise, the simulation has to allocate
 *   the regions of memory for every model, even though only one is in use.
 */

/**
 * @author Philip Levis
 * @author Nelson Lee
 * @author pal
 */


#ifndef RFM_MODEL_H_INCLUDED
#define RFM_MODEL_H_INCLUDED

typedef struct {
  void(*init)();
  void(*transmit)(int, char);   // int moteID, char bit
  void(*stop_transmit)(int);    // int moteID
  char(*hears)(int);            // char bit,   int moteID
  bool(*connected)(int,int);    // int moteID1, int moteID2
  link_t*(*neighbors)(int);      // int moteID
} rfm_model;

// In the simple model, all motes are in a single cell
rfm_model* create_simple_model();

// In the lossy model, the connectivity graph is determined at
// simulator boot and can be changed over the control channel;
// each link as a bit error rate. If file is NULL, default file
// name is used
rfm_model* create_lossy_model(char* file);

void static_one_cell_init();

// these functions are used to expose the probabilities of the lossy model
double get_link_prob_value(uint16_t moteID1, uint16_t moteID2);
void set_link_prob_value(uint16_t moteID1, uint16_t moteID2, double prob);
double get_noise_prob_value();
void set_noise_prob_value(double prob);

extern link_t* radio_connectivity[TOSNODES];

#endif // HEAP_H_INCLUDED
