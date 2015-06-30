/**
 * Global definitions for Crossbow conversions.
 *
 * @file      xconvert.h
 * @author    Martin Turon
 * @version   2004/8/8    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xconvert.h,v 1.8 2004/09/14 18:45:52 jdprabhu Exp $
 */

#ifndef __XCONVERT_H__
#define __XCONVERT_H__

#ifdef __arm__
#include <sys/types.h>
#endif

#include "xsensors.h"

/** Structure to describe sensirion data for XConvert. */
typedef struct XSensorSensirion 
{
    uint16_t humidity;
    uint16_t thermistor;
} __attribute__ ((packed)) XSensorSensirion;

/** Structure to describe intersema data for XConvert. */
typedef struct XSensorIntersema
{
    uint16_t temp;
    uint16_t pressure;
} __attribute__ ((packed)) XSensorIntersema;

uint16_t xconvert_battery_mica2   (uint16_t vref);
uint16_t xconvert_battery_dot     (uint16_t vref); 

float    xconvert_accel           (uint16_t accel_raw);

uint32_t xconvert_adc_single      (uint16_t adc_sing); 
int32_t  xconvert_adc_precision   (uint16_t adc_prec);

// Sensirion conversions
float xconvert_sensirion_temp     (XSensorSensirion *data);
float xconvert_sensirion_humidity (XSensorSensirion *data);

// Intersema conversions
float xconvert_intersema_temp     (XSensorIntersema *data, uint16_t *calib);
float xconvert_intersema_pressure (XSensorIntersema *data, uint16_t *calib);

uint16_t xconvert_thermistor_resistance  (uint16_t thermistor);
float    xconvert_thermistor_temperature (uint16_t thermistor);

float    xconvert_spectrum_soiltemp  (uint16_t data);
float    xconvert_echo10  (uint16_t data);
float    xconvert_echo20  (uint16_t data);

#endif  /* __CONVERT_H__ */



