//$Id: Prometheus.nc,v 1.4 2005/07/22 02:28:19 jaein Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Interface for Prometheus. <p>
 *
 * @modified 6/6/05
 *
 * @author Jaein Jeong
 */

interface Prometheus {
  /**
   * Initializes Prometheus state.
   *
   * @return SUCCESS if the initialization is successfully done.
   */
  command result_t Init();
  /**
   * Selects the ADC source between Prometheus and external source.
   *
   * @param high If true selects Prometheus capacitor and battery voltage.
   * If false, selects external source.
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t selectADCSource(bool high);
  /**
   * Requests a read for ADC source.
   *
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t getADCSource();
  /**
   * Requests a read for Prometheus battery voltage.
   *
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t getBattVol();
  /**
   * Requests a read for Prometheus capacitor voltage.
   *
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t getCapVol();
  /**
   * Selects whether Prometheus charging and battery source are set
   * automatically or manually.
   *
   * @param high If true, sets Prometheus charging and battery source
   * automatically. If false, sets Prometheus charging and battery source
   * manually.
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t setAutomatic(bool high);
  /**
   * Requests a read for whether Prometheus charging and battery
   * source are set automatically.
   *
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t getAutomatic();
  /**
   * Sets the power source for Prometheus.
   *
   * @param high If true, sets the power source for battery.
   * If false, sets the power source for capacitor.
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t setPowerSource(bool high);
  /**
   * Requests a read for the power source for Prometheus.
   *
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t getPowerSource();
  /**
   * Sets whether Prometheus battery is to be charged.
   *
   * @param high If true, no charging (reverse logic).
   * If false, charging.
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t setCharging(bool high);
  /**
   * Requests a read for the battery charging status.
   *
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t getCharging();
  /**
   * An event for <code>selectADCSource()</code> command.
   *
   * @param high If true, ADC reading is from Prometheus capacitor 
   * and battery voltage. If false, ADC reading is from external source.
   */
  event void getADCSourceDone(bool high, result_t success);
  /**
   * An event for <code>setAutomatic()</code> command.
   *
   * @param high If true, charging and battery source are automatically
   * set. If false, Prometheus charging and battery source are set
   * manually.
   * @param success If true, the operation is done successfully.
   */
  event void getAutomaticDone(bool high, result_t success);
  /**
   * An event for <code>getBattVol()</code> command.
   *
   * @param _volBatt Battery voltage in mV.
   * @param success If true, the operation is done successfully.
   */
  event void getBattVolDone(uint16_t _volBatt, result_t success);
  /**
   * An event for <code>getCapVol()</code> command.
   *
   * @param _volCap Capacitor voltage in mV.
   * @param success If true, the operation is done successfully.
   */
  event void getCapVolDone(uint16_t _volCap, result_t success);
  /**
   * An event for <code>getPowerSource()</code> command.
   *
   * @param high If true, the power comes from the battery.
   * If false, the power comes from the capacitor.
   * @param success If true, the operation is done successfully.
   */
  event void getPowerSourceDone(bool high, result_t success);
  /**
   * An event for <code>getChargingDone()</code> command.
   *
   * @param high If true, the battery is not being charged.
   * If false, the battery is being charged.
   * @param success If true, the operation is done successfully.
   */
  event void getChargingDone(bool high, result_t success);
  /**
   * An event for each iteration of the <code>setAutomatic()</code> command.
   *
   * @param runningOnBattery If true, the battery is being used.
   * If false, the capacitors are being used.
   * @param chargingBattery If true, the battery is being charged.
   * If false, the battery is not being charged.
   * @param batteryVoltage the voltage of the battery in mV
   * @param capacitorVoltage the voltage of the capacitors in mV
   */
  event void automaticUpdate( bool runningOnBattery, bool chargingBattery, uint16_t batteryVoltage, uint16_t capVoltage );
}

