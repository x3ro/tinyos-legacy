/**
 * Compass - Copyright (c) 2003 ISIS
 *
 * Author: Peter Volgyesi, based on UCB work (Cory Sharp)
 **/

includes SmartMag;

interface SmartMag {
  command result_t read();
  command result_t calibrate(uint16_t bias_center, uint16_t bias_scale);
  event result_t readDone( MagValue* values );
}
