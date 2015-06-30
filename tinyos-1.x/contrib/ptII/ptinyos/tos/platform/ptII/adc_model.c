// $Id: adc_model.c,v 1.4 2006/12/18 07:20:00 celaine Exp $

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
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: adc_model.c
 * AUTHOR: pal
 *   DESC: Model for ADC values.
 */

// Viptos: Replacing pthread objects with JNI objects.
//#include <pthread.h>
#include <sensorboard.h>

// Viptos: functions to create and enter and exit monitor.
extern void *ptII_createMonitorObject();
extern int ptII_MonitorEnter(void *monitorObject);
extern int ptII_MonitorExit(void *monitorObject);

/****************************************************************
 *********************** Simple ADC model ***********************
 ****************************************************************/
void random_adc_init() {}

uint16_t random_adc_read(int moteID, uint8_t port, long long ftime) {
  return (uint16_t)(rand() & 0x3ff);
}

adc_model* create_random_adc_model() {
  adc_model* model = (adc_model*)(malloc(sizeof(adc_model)));
  model->init = random_adc_init;
  model->read = random_adc_read;
  return model;
}

/****************************************************************
 ********************** Generic ADC model ***********************
 ****************************************************************/

enum {
  ADC_NUM_PORTS_PER_NODE = 256
};

uint16_t adcValues[TOSNODES][ADC_NUM_PORTS_PER_NODE];
// Viptos: Replacing pthread objects with JNI objects.
//pthread_mutex_t adcValuesLock;
void *adcValuesLock; // of type jobject

void generic_adc_init() {
  int i, j;
  for (i = 0; i < TOSNODES; i++) {
    for (j = 0; j < ADC_NUM_PORTS_PER_NODE; j++) {
      adcValues[i][j] = 0xffff;
    }
  }

  // Viptos: Set the lock object.
  adcValuesLock = ptII_createMonitorObject();
  //pthread_mutex_init(&adcValuesLock, NULL);
}

extern uint16_t ptII_get_adc_value(char *portname);

uint16_t generic_adc_read(int moteID, uint8_t port, long long ftime) {
  uint16_t value;

  // check parameters
  if ((moteID >= TOSNODES) || (moteID < 0)) {
    dbg(DBG_ERROR, "GENERIC_ADC_MODEL: trying to read value with invalid parameters: [moteID = %d] [port = %d]", moteID, port);
    return -1;
  }

  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(adcValuesLock);

  //pthread_mutex_lock(&adcValuesLock);
  value = adcValues[moteID][(int)port];
  //pthread_mutex_unlock(&adcValuesLock);

  ptII_MonitorExit(adcValuesLock);
  
  if (value == 0xffff) {
      char *portname = NULL;
      switch (port) {
      case TOS_ADC_PHOTO_PORT: portname = "photo";
          break;
      case TOS_ADC_TEMP_PORT: portname = "temperature";
          break;
      case TOS_ADC_MIC_PORT: portname = "microphone";
          break;
      case TOS_ADC_ACCEL_X_PORT: portname = "accelerometerX";
          break;
      case TOS_ADC_ACCEL_Y_PORT: portname = "accelerometerY";
          break;
      case TOS_ADC_MAG_X_PORT: portname = "magnetometerX";
          break;
      case TOS_ADC_MAG_Y_PORT: portname = "magnetometerY";
          break;
      default:
      }
      if (portname != NULL) {
          return ptII_get_adc_value(portname) & 0x3ff;
      } else {
          return (short)(rand() & 0x3ff);
      }
  } else
    return value;
}

adc_model* create_generic_adc_model() {
  adc_model* model = (adc_model*)(malloc(sizeof(adc_model)));
  model->init = generic_adc_init;
  model->read = generic_adc_read;
  return model;
}

void set_adc_value(int moteID, uint8_t port, uint16_t value) {
  if ((moteID >= TOSNODES) || (moteID < 0)) {
    dbg(DBG_ERROR, "GENERIC_ADC_MODEL: trying to set value with invalid parameters: [moteID = %d] [port = %d]", moteID, port);
    return;
  }

  // Viptos: Replacing pthread objects with JNI objects.
  ptII_MonitorEnter(adcValuesLock);

  //pthread_mutex_lock(&adcValuesLock);
  adcValues[moteID][(int)port] = value;
  //pthread_mutex_unlock(&adcValuesLock);

  ptII_MonitorExit(adcValuesLock);
}
