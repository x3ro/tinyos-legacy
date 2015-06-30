#ifndef __BASIC_SENSORBOARD_H__
#define __BASIC_SENSORBOARD_H__

/*
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 */
#include "config.h"
#include "channelParams.h"
#include "sensorTypes.h"

const char mySensorboardName[] = "BasicSensorboard";

#define MAX_SAMPLING_RATE (100000)

/*
 * Supported sensor types
 */

#define SENSORTYPE1 ANALOG_SENSOR(SENSOR_ANALOG_ACCOUPLED | SENSOR_ANALOG_DCCOUPLED, \
SENSOR_ANALOG_VOLTAGE, \
SENSOR_ANALOG_SINGLEENDED | SENSOR_ANALOG_DIFFERENTIAL, \
SENSOR_ANALOG_RANGE_PLUS5V)

#define SENSORTYPE2 ANALOG_SENSOR(SENSOR_ANALOG_DCCOUPLED, \
SENSOR_ANALOG_CURRENT, \
SENSOR_ANALOG_DIFFERENTIAL, \
SENSOR_ANALOG_RANGE_PLUS5V)

#define SENSORTYPE3 DIGITAL_SENSOR(SENSOR_DIGITAL_3AXISACCEL)

//THE FIRST NUMBER MUST MATCH THE TOTAL NUMBER OF ELEMENTS IN THE SECOND INITIALIZER FOR ALL ELEMENTS TO BE RECOGNIZED!
//first element in the comondFeatureList for a sensor is the PhysicalChannel that it maps to
const supportedCommonFeatureList32_t channel0Sensors = {1,0,{0}};

const supportedCommonFeatureList32_t channel1Sensors = {1,1,{SENSORTYPE3}};
const supportedFeatureList8_t channel1Widths = {1,{48}};

const supportedCommonFeatureList32_t channel2Sensors = {2,2,{SENSORTYPE1,SENSORTYPE2}};
const supportedFeatureList32_t channel2Rates = {4,{100, 200, 400, 800}};
const supportedFeatureList8_t channel2Widths = {1,{16}};

const supportedFeatureList8_t simulChannelGroup0 = {1,{0}};
const supportedFeatureList8_t simulChannelGroup1 = {1,{1}};
const supportedFeatureList8_t simulChannelGroup2 = {1,{2}};

/*****************************
 * Channel Capabilities Table
 ****************************/
const channelParam_t channelCapabilitiesTable[TOTAL_CHANNELS] = {
  {MAX_SAMPLING_RATE, &channel0Sensors, NULL, NULL},
  {MAX_SAMPLING_RATE, &channel1Sensors, NULL, &channel1Widths},
  {MAX_SAMPLING_RATE, &channel2Sensors, &channel2Rates, &channel2Widths}};


/*****************************
 * Data Channel Capabilities Table
 ****************************/
const dataChannelParam_t dataChannelCapabilitiesTable[TOTAL_DATA_CHANNELS] = {
  {&simulChannelGroup0},
  {&simulChannelGroup1},
  {&simulChannelGroup2}};

#endif //__SENSORBOARD_H__
