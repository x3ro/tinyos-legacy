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
 *   FILE: adc_model.h
 * AUTHOR: pal
 *   DESC: Model for ADC values.
 *
 *   This file declares the interface used by TOSSIM for adc (sensor)
 *   simulation.
 *
 *   A data pointer is provided so that large structures can be
 *   dynamically allocated. Otherwise, the simulation has to allocate
 *   the regions of memory for every model, even though only one is in use.
 */

#ifndef ADC_MODEL_H_INCLUDED
#define ADC_MODEL_H_INCLUDED

typedef struct {
  void(*init)();
  short (*read)(int, char, long long);  // int mote, char port, long long time
  void* data;                
} adc_model;

// In the simple model, all ports always return 0
adc_model* create_simple_adc_model();

#endif // ADC_MODEL_H_INCLUDED
