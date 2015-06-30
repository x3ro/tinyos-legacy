/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors: Philip Levis, Nelson Lee
 *
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

/*
 * The simple RFM model simulates every mote being in a single cell
 * (they can all hear one another). Bit transmission is
 * error-free. Simulation is achieved by using a radio_active variable
 * for each mote, which starts at 0.  Every time a mote transmits, it
 * increments the radio_active value for every other mote. When a mote
 * listens, it hears a bit if the radio_active value is one or
 * greater. When a mote finishes transmitting, it decrements the
 * radio_active value of every other mote. Although very simple, this
 * simulation mechanism allows for extremeley accurate network timing
 * simulation.
 *
 * The static model is very similar to the simple model except that
 * the motes form an undirected connectivity graph. This graph is
 * specified by the file "cells.txt" and its format is documented in
 * the NIDO manual.
 */


int isTransmitting[TOSNODES];
int transmitting[TOSNODES];
int radio_active[TOSNODES];
char radio_connectivity[TOSNODES][TOSNODES]; // Connectivity graph

bool simple_connected(int moteID1, int moteID2) {
  return TRUE;
}

void simple_init() {
  int i;
  static_one_cell_init();
  for (i = 0; i < tos_state.num_nodes; i++) {
    radio_active[i] = 0;
  }
}

void simple_transmit(int moteID, char bit) {
  int i;
  
  transmitting[moteID] = bit;
  writeOutRadioBit(tos_state.tos_time, (short)moteID, bit);
  
  for (i = 0; i < tos_state.num_nodes; i++) {
    radio_active[i] += bit;
  }
}

void simple_stops_transmit(int moteID) {
  int i;
  
  if (transmitting[moteID]) {
    transmitting[moteID] = 0;
    for (i = 0; i < tos_state.num_nodes; i++) {
      radio_active[i]--;
    }
  }
}

char simple_hears(int moteID) {
  // Uncomment these lines to add erroneus 1s. The probability
  // can be adjusted by changing the constants.
  //int rand = random();
  //if ((rand & (int)0xf) == 0xf) {
  //  return 1;
  //}
  //else {
    return (radio_active[moteID] > 0)? 1:0;
  //}
}

rfm_model* create_simple_model() {
  rfm_model* model = (rfm_model*)malloc(sizeof(rfm_model));
  model->init = simple_init;
  model->transmit = simple_transmit;
  model->stop_transmit = simple_stops_transmit;
  model->hears = simple_hears;
  model->connected = simple_connected;
  return model;
}

int read_entry(FILE* file, int* mote_one, int* mote_two) {
  char buf[128];
  int findex = 0;
  int ch;

  // Read in first number
  while(1) {
    ch = getc(file);
    if (ch == EOF) {return 0;}
    else if (ch >= '0' && ch <= '9') {
      buf[findex] = (char)ch;
      findex++;
    }
    else if (ch == ':') {
      buf[findex] = 0;
      break;
    }
    else if (ch == '\n' || ch == ' ' || ch == '\t') {
      if (findex > 0) {return 0;}
    }
    else {
      return 0;
    }
  }

  *mote_one = atoi(buf);
  findex = 0;
  // Read in second number
  while(1) {
    ch = getc(file);
    if (ch == EOF) {return 0;}
    else if (ch >= '0' && ch <= '9') {
      buf[findex] = (char)ch;
      findex++;
    }
    else if (ch == '\n' || ch == ' ' || ch == '\t') {
      if (findex == 0) {return 0;}
      else {
	buf[findex] = 0;
	break;
      }
    }
    else {
      return 0;
    }
  }

  *mote_two = atoi(buf);
  return 1;
}

void static_one_cell_init() {
  int i,j;
  
  for (i = 0; i < TOSNODES; i++) {
    for (j = 0; j < TOSNODES; j++) {
      radio_connectivity[i][j] = 1;
    }
  }
}

void static_init() {
  int sfd = open("cells.txt", O_RDONLY);
  FILE* file = fdopen(sfd, "r");
  
  if (sfd < 0) {
    dbg(DBG_ERROR, ("No cells.txt found for static rfm model. Defaulting to one cell.\n"));
    static_one_cell_init();
    return;
  }


  while(1) {
    int mote_one;
    int mote_two;
    if (read_entry(file, &mote_one, &mote_two)) {
      radio_connectivity[mote_one][mote_two] = 1;
      radio_connectivity[mote_two][mote_one] = 1;
    }
    else {
      break;
    }
  }
  dbg(DBG_BOOT, ("RFM connectivity graph constructed.\n"));
}

bool static_connected(int moteID1, int moteID2) {
  if (radio_connectivity[moteID1][moteID2])
    return TRUE;
  else
    return FALSE;
}
  
void static_transmit(int moteID, char bit) {
  int i;
  
  transmitting[moteID] = bit;
  writeOutRadioBit(tos_state.tos_time, (short)moteID, bit);
  
  for (i = 0; i < tos_state.num_nodes; i++) {
    if (radio_connectivity[moteID][i]) {
      radio_active[i] += bit;
    }
  }
}

void static_stops_transmit(int moteID) {
  int i;
  
  if (transmitting[moteID]) {
    transmitting[moteID] = 0;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (radio_connectivity[moteID][i]) {
	radio_active[i]--;
      }
    }
  }
}

char static_hears(int moteID) {
  return (radio_active[moteID] > 0)? 1:0;
}


rfm_model* create_static_model() {
  rfm_model* model = (rfm_model*)malloc(sizeof(rfm_model));
  model->init = static_init;
  model->transmit = static_transmit;
  model->stop_transmit = static_stops_transmit;
  model->hears = static_hears;
  model->connected = static_connected;
  return model;
}




