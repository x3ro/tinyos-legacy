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
 */
// $Id: MovAvgDetect_DiffRptM.nc,v 1.2 2005/04/15 20:10:07 phoebusc Exp $
/**
 * MovAvgDetect_DiffRptM is meant to be used with magnetometers, which
 * tend to have a problem with a drifting bias value (memory effect).
 * 
 * Peforms two functions:
 * <OL>
 *  <LI> Maintains a moving average to serve as an estimate of the
 *       drifting bias value.</LI>
 *  <LI> Reports a sensor reading/update only when it detects a sudden
 *       change in sensing value (from the moving average).  The
 *       reported value is the absolute value of the difference
 *       between the sensor reading and the moving average. </LI>
 * </OL>
 * 
 * @author Phoebus Chen (based off of MagMovingAvgM.nc, by Cory Sharp)
 * @modified 9/30/2004 Changed File Name
 * @modified 9/13/2004 First Implementation
 */

includes MovAvgDetect_DiffRptM; //header file for constants
includes MagSensorTypes;
includes moving_average;
includes common_math;

module MovAvgDetect_DiffRptM {
  provides {
    interface StdControl;
    interface ConfigTrigger;
    interface ConfigMagProcessing;
    interface SenseUpdate;
  }

  uses {
    interface StdControl as MagControl;
    interface MagSensor;
    interface MagAxesSpecific;

    interface Timer as SenseTimer;
  }
}


implementation {

  uint8_t windowSize;
  uint16_t reportThresh;
  uint16_t readFireInterval;

  Mag_t mag;
  //  MagVal_t m_magPrev; //necessary for Cory's hack

  //data structures from moving_average.h used for computations
  ma_data_t movavg_data_x[MAX_SAMPLES];
  ma_data_t movavg_data_y[MAX_SAMPLES];
  moving_average_t movavg_x; //bookkeeping struct for arrays
  moving_average_t movavg_y; //bookkeeping struct for arrays



  /** Function call to initialize the data structures used for
   *  calculating the moving average (this uses library functions for
   *  the actual computations).  Note that we need this done
   *  immediately, hence a task is not appropriate.
   */
  void initMovAvg( uint16_t numSamp ) {
    if( numSamp > MAX_SAMPLES ) { //safety check
      numSamp = MAX_SAMPLES;
    }
    //call included library functions
    init_moving_average( &movavg_x, movavg_data_x, movavg_data_x+numSamp );
    init_moving_average( &movavg_y, movavg_data_y, movavg_data_y+numSamp );
  }



  /** Updates the moving average with this reading and processes the
   *  sensor reading to determine whether it is a significant
   *  disturbance that needs to be reported.  If this is a significant
   *  reading, it signals <CODE> senseUpdate.senseFired(...)
   *  </CODE> with the processed sensor reading. <P>
   *
   *  The processed sensor reading contains the absolute value of the
   *  difference between the X value and the moving average of the X
   *  value, and similarly for the Y value. <P>
   *
   *  This task is assumed to be processed before the next magnetometer
   *  reading is fired.
   */
  task void processReading() {
    Mag_t magProcessed;

    //Cory's hack to get rid of oscillations in readings
/*     MagVal_t magCurr = { */
/*       x: m_mag.val.x/2 + m_magPrev.x/2, */
/*       y: m_mag.val.y/2 + m_magPrev.y/2, */
/*     }; */

/*     m_magPrev = m_mag.val; */

    magProcessed.val.x = absdiff_u16(
      add_moving_average( &movavg_x, mag.val.x ),
      mag.val.x
    );

    magProcessed.val.y = absdiff_u16(
      add_moving_average( &movavg_y, mag.val.y ),
      mag.val.y
    );

    magProcessed.bias = mag.bias; //let's assume fairly constant
    
    if (magProcessed.val.x > reportThresh || magProcessed.val.y > reportThresh) {
      signal SenseUpdate.senseFired(magProcessed);
    }
  } //task processReading()


  /** Restarts the SenseTimer to fire at <CODE> readFireInterval
   *  </CODE>.  Posted when a reconfiguration message is sent.
   */
  task void resetTimer() {
    if (call SenseTimer.stop()) {
      call SenseTimer.start(TIMER_REPEAT, readFireInterval);
    }
  } //task resetTimer()


  
  command result_t StdControl.init() {
    MagAxes_t axes = { x:TRUE, y:TRUE };

    reportThresh = DEFAULT_REPORT_THRESH;
    readFireInterval = DEFAULT_READ_FIRE_INTERVAL;
    windowSize = DEFAULT_WINDOW_SIZE;
    call MagControl.init();
    call MagAxesSpecific.enableAxes(axes); //return type void
    return SUCCESS;
  }


  command result_t StdControl.start() {
    initMovAvg(windowSize); //want this to reinitialize each time we restart
    return rcombine(call MagControl.start(),
		    call SenseTimer.start(TIMER_REPEAT, readFireInterval));
  }


  command result_t StdControl.stop() {
    return rcombine(call MagControl.stop(), call SenseTimer.stop());
  }


  command result_t ConfigTrigger.setReportThresh(uint16_t newReportThresh) {
    reportThresh = newReportThresh;
    return SUCCESS;
  }


  command result_t ConfigTrigger.setReadFireInterval(uint16_t newReadFireInterval) {
    readFireInterval = newReadFireInterval;
    post resetTimer();
    return SUCCESS;
  }


  command uint16_t ConfigTrigger.getReadFireInterval() {
    return readFireInterval;
  }


  command uint16_t ConfigTrigger.getReportThresh() {
    return reportThresh;
  }


  // safety check that (newNumSamples <= MAX_SAMPLES) is done in initMovAvg
  command result_t ConfigMagProcessing.setMovAvgWindowSize(uint8_t newWindowSize) {
    windowSize = newWindowSize;
    initMovAvg(windowSize);
    return SUCCESS;
  }


  command uint8_t ConfigMagProcessing.getMovAvgWindowSize() {
    return windowSize;
  }



  event result_t SenseTimer.fired() {
    return call MagSensor.read();
  }


  event result_t MagSensor.readDone(Mag_t readMag) {
    mag = readMag;
    post processReading();
    return SUCCESS;
  }

} //implementation

