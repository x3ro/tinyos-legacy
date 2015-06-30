// $Id: rfm_model.c,v 1.1 2004/04/22 01:17:06 shnayder Exp $

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
 * Authors: Philip Levis, Nelson Lee
 *
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <pthread.h>

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
 */


//char isTransmitting[TOSNODES];
char transmitting[TOSNODES];
int radio_active[TOSNODES];
link_t* radio_connectivity[TOSNODES]; // adjacency lists
pthread_mutex_t radioConnectivityLock;

char sendProb[TOSNODES];
char receiveProb[TOSNODES];

// buffer for idle detection over network
short radio_heard[TOSNODES];
// state indicating whether channel is idle
bool radio_idle_state[TOSNODES];
double noise_prob = 0;

short IDLE_STATE_MASK = 0xffff;
char* lossyFileName = "lossy.nss";

bool simple_connected(int moteID1, int moteID2) {
  return TRUE;
}

void simple_init() {
  int i;
  pthread_mutex_init(&radioConnectivityLock, NULL);
  adjacency_list_init();
  static_one_cell_init();
  for (i = 0; i < tos_state.num_nodes; i++) {
    radio_active[i] = 0;
  }
}

void simple_transmit(int moteID, char bit) {
  int i;
  
  transmitting[moteID] = bit;
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

link_t* simple_neighbors(int moteID) {
  link_t *thelink;
  pthread_mutex_lock(&radioConnectivityLock);
  thelink = radio_connectivity[moteID];
  pthread_mutex_unlock(&radioConnectivityLock);
  return thelink;
}

rfm_model* create_simple_model() {
  rfm_model* model = (rfm_model*)malloc(sizeof(rfm_model));
  model->init = simple_init;
  model->transmit = simple_transmit;
  model->stop_transmit = simple_stops_transmit;
  model->hears = simple_hears;
  model->connected = simple_connected;
  model->neighbors = simple_neighbors;
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
  int i, j;
  link_t* new_link;

  pthread_mutex_init(&radioConnectivityLock, NULL);
  radio_connectivity[0] = NULL;
  
  for (i = 0; i < tos_state.num_nodes; i++) {
    for (j = 0; j < tos_state.num_nodes; j++) {
      if (i != j) {
  	new_link = allocate_link(j);
        new_link->data = 0.0; // bit error rate set to zero
 	// so can be reused by lossy
        new_link->next_link = radio_connectivity[i];
  	radio_connectivity[i] = new_link;
    }
   }
  }
}

void static_init() {
  int sfd = open("cells.txt", O_RDONLY);
  int i;
  FILE* file = fdopen(sfd, "r");
  link_t* new_link;
  
  pthread_mutex_init(&radioConnectivityLock, NULL);
  adjacency_list_init();
  if (sfd < 0) {
    dbg(DBG_ERROR, ("No cells.txt found for static rfm model. Defaulting to one cell.\n"));
    
    static_one_cell_init();
    return;
  }
  
  for (i = 0; i < TOSNODES; i++) {
    radio_connectivity[i] = NULL;
  }
  while(1) {
    int mote_one;
    int mote_two;
    if (read_entry(file, &mote_one, &mote_two)) {
      new_link = allocate_link(mote_two);
      new_link->next_link = radio_connectivity[mote_one];
      radio_connectivity[mote_one] = new_link;
      new_link = allocate_link(mote_one);
      new_link->next_link = radio_connectivity[mote_two];
      radio_connectivity[mote_two] = new_link;
      
    }
    else {
      break;
    }
  }
  dbg(DBG_BOOT, ("RFM connectivity graph constructed.\n"));
}

bool static_connected(int moteID1, int moteID2) {
  // this method is rather slow, and runs on the order of the number
  // of links attached moteID1 because it traverses moteID1's
  // adjacency list to make this a constant time operation, add a
  // hashtable to the adjacency list implementation
  link_t* current_link;
  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID1];
  while (current_link) {
    if (current_link->mote == moteID2) {
      pthread_mutex_unlock(&radioConnectivityLock);
      return TRUE;
    }
    current_link = current_link->next_link;
  }
  pthread_mutex_unlock(&radioConnectivityLock);
  return FALSE;
}

void static_transmit(int moteID, char bit) {
  link_t* current_link;
  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID];
  transmitting[moteID] = bit;
  while (current_link) {
    radio_active[current_link->mote] += bit;
    current_link = current_link->next_link;
  }
  pthread_mutex_unlock(&radioConnectivityLock);
}

void static_stops_transmit(int moteID) {
  link_t* current_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID];
  if (transmitting[moteID]) {
    transmitting[moteID] = 0;
    while (current_link) {
      radio_active[current_link->mote]--;
      current_link = current_link->next_link;
    }      
  }
  pthread_mutex_unlock(&radioConnectivityLock);
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
  model->neighbors = simple_neighbors;
  return model;
}


bool lossy_connected(int moteID1, int moteID2) {
  // this method is rather slow, and runs on the order of the number
  // of links attached moteID1 because it traverses moteID1's
  // adjacency list to make this a constant time operation, add a
  // hashtable to the adjacency list implementation
  link_t* current_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID1];
  dbg(DBG_TEMP, "connections for %i\n", moteID1);
  while (current_link) {
    if ((current_link->mote == moteID2) &&
	(current_link->data < 1.0)) {
      dbg(DBG_TEMP, "connected to %i\n", moteID2);
      pthread_mutex_unlock(&radioConnectivityLock);
      return TRUE;
    }
    current_link = current_link->next_link;
  }
  pthread_mutex_unlock(&radioConnectivityLock);
  return FALSE;
}

void lossy_transmit(int moteID, char bit) {
  link_t* current_link; 
  
  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID];
  transmitting[moteID] = bit;
  while (current_link) {
    int r = rand() % 100000;
    double prob = ((double)r) / 100000.0;
    int tmp_bit = bit;
    if (prob < current_link->data) { // bit error, reverse the bit
      tmp_bit = (tmp_bit)? 0:1;
    }
    radio_active[current_link->mote] += tmp_bit;
    radio_idle_state[current_link->mote] = 0;
    current_link->bit = tmp_bit;
    current_link = current_link->next_link;
  }
  pthread_mutex_unlock(&radioConnectivityLock);
}

void lossy_stop_transmit(int moteID) {
  link_t* current_link;
  
  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID];
  transmitting[moteID] = 0;
  while (current_link) {
    radio_active[current_link->mote] -= current_link->bit;
    current_link->bit = 0;
    current_link = current_link->next_link;
  }      
  pthread_mutex_unlock(&radioConnectivityLock);
}

char lossy_hears(int moteID) {
  char bit_heard = (radio_active[moteID] > 0)? 1:0;
  if (radio_idle_state[moteID]) {
      int r = rand() % 100000;
      double prob = ((double)r) / 100000.0;
      if (prob < noise_prob) { // noise has caused this bit to be reversed
	bit_heard = (bit_heard)? 0:1;
      }
  }
  else {
      short temp_heard = radio_heard[moteID];
      temp_heard <<= 1;
      temp_heard |= bit_heard;
      radio_heard[moteID] = temp_heard;
      if ((radio_heard[moteID] & IDLE_STATE_MASK) == 0) {
	  radio_idle_state[moteID] = 1;
      }
  }
  return bit_heard;
}

int read_lossy_entry(FILE* file, int* mote_one, int* mote_two, double* loss) {
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
    else if (ch == ':') {
      buf[findex] = 0;
      break;
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

  findex = 0;
  // Read in loss rate number
  while(1) {
    ch = getc(file);
    if (ch == EOF) {return 0;}
    else if ((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == 'E'
             || ch == 'e') {
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
  *loss = atof(buf);

  return 1;
}

void lossy_init() {
  int sfd = open(lossyFileName, O_RDONLY);
  int i;
  FILE* file = fdopen(sfd, "r");
  link_t* new_link;

  dbg_clear(DBG_SIM, "Initializing lossy model from %s.\n", lossyFileName);
  pthread_mutex_init(&radioConnectivityLock, NULL);
  adjacency_list_init();

  if (sfd < 0) {
    dbg(DBG_SIM, "Cannot open %s - assuming single radio cell\n", lossyFileName);
    static_one_cell_init();
    return;
  }

  for (i = 0; i < TOSNODES; i++) {
    radio_connectivity[i] = NULL;
    radio_idle_state[i] = 0;
    radio_heard[i] = 0;
  }
  while(1) {
    int mote_one;
    int mote_two;
    double loss;
    if (read_lossy_entry(file, &mote_one, &mote_two, &loss)) {
      if (mote_one != mote_two) {
	new_link = allocate_link(mote_two);
	new_link->data = loss;
	new_link->next_link = radio_connectivity[mote_one];
	radio_connectivity[mote_one] = new_link;
      }
    }
    else {
      break;
    }
  }
  dbg(DBG_BOOT, ("RFM connectivity graph constructed.\n"));
}


link_t* lossy_neighbors(int moteID) {
  link_t *thelink;
  pthread_mutex_lock(&radioConnectivityLock);
  thelink = radio_connectivity[moteID];
  pthread_mutex_unlock(&radioConnectivityLock);
  return thelink;
}

rfm_model* create_lossy_model(char* file) {
  rfm_model* model = (rfm_model*)malloc(sizeof(rfm_model));
  if (file != NULL) {
    lossyFileName = file;
  }
  model->init = lossy_init;
  model->transmit = lossy_transmit;
  model->stop_transmit = lossy_stop_transmit;
  model->hears = lossy_hears;
  model->connected = lossy_connected;
  model->neighbors = lossy_neighbors;
  return model;
}

double get_link_prob_value(uint16_t moteID1, uint16_t moteID2) {
  link_t *current_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID1];
  while (current_link) {
    if (current_link->mote == moteID2) {
      pthread_mutex_unlock(&radioConnectivityLock);
      return current_link->data;
    }
    current_link = current_link->next_link;
  }
  pthread_mutex_unlock(&radioConnectivityLock);
  return 1;  
}

void set_link_prob_value(uint16_t moteID1, uint16_t moteID2, double prob) {
  link_t* current_link;
  link_t* new_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID1];
  dbg(DBG_SIM, "RFM: MDW: Setting loss prob %d->%d to %0.3f\n", moteID1, moteID2, prob);
  while (current_link) {
    if (current_link->mote == moteID2) {
      current_link->data = prob;
      pthread_mutex_unlock(&radioConnectivityLock);
      return;      
    }
    current_link = current_link->next_link;
  }
  new_link = allocate_link(moteID2);
  new_link->next_link = radio_connectivity[moteID1];
  new_link->data = prob;
  radio_connectivity[moteID1] = new_link;
  pthread_mutex_unlock(&radioConnectivityLock);
}

double get_noise_prob_value() {
  return noise_prob;
  
}

void set_noise_prob_value(double prob) {
  noise_prob = prob;
}

char get_wait_length_before_idle() {
  short temp = IDLE_STATE_MASK;
  char count = 0;
  while (temp) {
    count++;
    temp = temp >> 1;
    temp &= 0x7fff;
  }
  return count;
}

void set_wait_length_before_idle(int count) {
  short temp = 0;
  while (count) {
    temp = temp << 1;
    temp |= 1;
    count--;
  }
  IDLE_STATE_MASK = temp;
}



