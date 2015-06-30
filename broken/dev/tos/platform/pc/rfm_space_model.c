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
 *
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: rfm_space_model.c
 * AUTHOR: pal
 *   DESC: Euclidean space model for RF connectivity
 */

#define MAX_X ((double) 500.0)
#define MAX_Y ((double) 500.0)

double pot_settings[] = {
  999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9,
  999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9,
  999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9,
  999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9,
  999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9,

  999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9,
  999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9, 999.9,
  800.0, 600.0, 400.0, 200.0, 100.0, 50.0, 10.0, 0.0, 0.0, 0.0, // 70-76
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,

  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
};

typedef struct {
  double x;
  double y;
} pointXY;

typedef void(*positionFunction)(int, long long);

int isTransmitting[TOSNODES]; // Whether the mote was transmitting
int had_transmitted[TOSNODES][TOSNODES]; // [i][j]: Whether i transmitted to j
int radio_active[TOSNODES];

pointXY positions[TOSNODES];
positionFunction functions[TOSNODES];

void seed_positions();
void compute_connectivity(int moteID);
void step(int moteID, long long ftime);

void rfm_space_init() {
  int i, j;
  for (i = 0; i < tos_state.num_nodes; i++) {
    isTransmitting[i] = 0;
    radio_active[i] = 0;
    functions[i] = step;;
    for (j = 0; j < tos_state.num_nodes; j++) {
      had_transmitted[i][j] = 0;
    }
  }
  seed_positions();
}

void rfm_space_transmit(int moteID, char bit) {
  int i;
  functions[moteID](moteID, tos_state.tos_time);
  isTransmitting[moteID] = bit;
  if (bit) {
    compute_connectivity(moteID);
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (had_transmitted[moteID][i]) {
	radio_active[i]++;
      }
    }
  }
}

void rfm_space_stop_transmit(int moteID) {
  if (isTransmitting[moteID]) {
    int i;
    isTransmitting[moteID] = 0;
    for (i = 0; i < tos_state.num_nodes; i++) {
      if (had_transmitted[moteID][i]) {
	radio_active[i]--;
      }
    }
  }
}

char rfm_space_hears(int moteID) {
  return (radio_active[moteID] > 0)? 1:0;
}

rfm_model* create_space_model() {
  rfm_model* model = (rfm_model*)malloc(sizeof(rfm_model));

  model->init = rfm_space_init;
  model->transmit = rfm_space_transmit;
  model->stop_transmit = rfm_space_stop_transmit;
  model->hears = rfm_space_hears;

  return model;
}

void seed_positions() {
  int i;
  for (i = 0; i < tos_state.num_nodes; i++) {
    double x = ((double)(rand() % 1000) / 1000.0) * MAX_X;
    double y = ((double)(rand() % 1000) / 1000.0) * MAX_Y;
    
    positions[i].x = x;
    positions[i].y = y;
  }
}



void step(int moteID, long long ftime) {
  double x = ((double)(rand() % 1000) / 1000.0);
  double y = ((double)(rand() % 1000) / 1000.0); 

  x /= 500.0;
  y /= 500.0;
  
  x += positions[moteID].x;
  y += positions[moteID].y;
    
  if (x < MAX_X && x > 0.0) {
    positions[moteID].x = x;
  }
  if (y < MAX_Y && y > 0.0) {
    positions[moteID].y = y;
  }
}

void compute_connectivity(int moteID) {
  int j;
  for (j = 0; j < tos_state.num_nodes; j++) {
    if (j != moteID) {
      double distance, x, y;
      x = positions[moteID].x - positions[j].x;
      x = x * x;

      y = positions[moteID].y - positions[j].y;
      y = y * y;
      
      distance = sqrt(x + y);

      if (distance < pot_settings[(int)tos_state.node_state[moteID].pot_setting]) {
	had_transmitted[moteID][j] = 1;
      }
      else {
	had_transmitted[moteID][j] = 0;
      }
    }
  }
}
