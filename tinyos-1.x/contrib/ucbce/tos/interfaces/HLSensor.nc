/**
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

/** 
 */

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 * 
 * @author David. M. Doolin
 */


/**
 * A standard interface for Sensors driven by TinyOS 
 * programs.  Sensors come with a wide variety of 
 * capabilities, and this interface is designed to
 * allow the programmer to wire a sensor without
 * worrying about whether it needs UART, I2C, ADC
 * or whatever capabilities.
 * 
 * The interface reflects the mechanical operation 
 * of the sensor, thus powering on a sensor need not
 * result in immediate sampling. 
 *
 * @author David M. Doolin
 */

interface HLSensor {

  /**
   * Turn on the power, but do not collect data.  If the 
   * sensor provides data given power, this command should 
   * set a state where that data is only fired back through 
   * dataReady when the user is ready for it.  Any system
   * bus, I/O state, whatever should be left in a consistent 
   * state.  Implementation should be idempotent.
   *
   * @return Whether powering on was successful.
   */
  /* Note: All the calls for power handling mirror a future
   * PowerControl interface, when the details have been
   * worked out.  At that point all the power handling can
   * be removed from this interface.
   */
  command result_t powerOn(uint8_t power_level);

    /** 
     * Notify components that the component has been started 
     * and is ready to receive other commands.  Implementation
     * should be idempotent.
     */
    event result_t powerOnDone();

    /** init() might be used to send a default
     * programming string to the sensor.
     */
    command result_t init();

  /**
   * Stop the component cleanly, without leaving
   * the system in an inconsistent state.
   *
   * @return Whether stopping was successful.
   */
  command result_t powerOff();

    /**
     * Notify components that the component has been stopped. 
     */

    event result_t powerOffDone();

    command result_t setSamplingInterval(uint16_t sampling_rate);
    command result_t getSamplingInterval(uint16_t sampling_rate);


    /** startSampling puts the sensor into a state such that 
     * the dataReady event will fire when data is ready to 
     * to be collected from the sensor.
     */
    command result_t startSampling();

    /** Stop the sensor from sampling.
     */
    command result_t stopSampling();

    /** This is for collecting a single sample from 
     * sensor.  It should leave whatever state the sensor is
     * in unchanged.  It should not be used in conjunction 
     * with startSampling().
     */
    command result_t sampleOnce();

    /** dataReady is where the main action is;
     * the entire system exists to support what
     * happens here.
     */
    event result_t dataReady(void * userdata);    

    /** Some sensors, for example the Leadtek 9546 used on
     * the Crossbow MTS420CA, are programmable.  It isn't 
     * practical to define one interface to handle 
     * programming for arbitrary sensors, but any of the 
     * sensors that can be programmed should have the 
     * capability to read from some sort of I/O, which 
     * an implementation of this command should encapsulate.
     */
    command result_t loadProgram(uint8_t * program, uint8_t length);

    /** Error codes for individual sensors should go into the 
     * header file for that sensor.  16 bits should be enough 
     * to extract an upper 8 bits for errors and a lower 8
     * bits for other sensor dependent stuff, perhaps channel ID
     * something.  Extraction code could be written as macros in
     * the sensor header file.
     */
    async event result_t error(uint16_t error_code);
}
