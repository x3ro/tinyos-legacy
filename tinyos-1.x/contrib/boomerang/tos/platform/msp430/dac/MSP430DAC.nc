// $Id: MSP430DAC.nc,v 1.1.1.1 2007/11/05 19:11:32 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "MSP430DAC12.h"

/**
 * HAL Interface for using the DAC on MSP430 microcontrollers.
 * <p>
 * <b>Typical procedure of operation:</b>
 * <p>
 * Intended process for single output:
 * <ol>
 * <li> bind, specifically ref volt
 * <li> enable
 * <li> wait for enableDone
 * <li> enableOutput
 * <li> set
 * <li> <em> do whatever </em>
 * <li> disable
 * </ol>
 *
 * Intended process for multiple sequential outputs:
 * <ol>
 * <li> bind, specifically ref volt -- load select bits ignored (reset later)
 * <li> enable
 * <li> wait for enableDone
 * <li> enableOutput
 * <li> setSequence / Repeat -- use the DMA and TimerA
 * <li> <em> do whatever </em>
 * <li> disable
 * </ol>
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com
 */
interface MSP430DAC {

  /**
   * Bind settings to the DAC.  See MSP430DAC12.h for a full description
   * of possible settings for each of the parameters.
   */
  command result_t bind(dac12ref_t reference, 
			dac12res_t resolution, 
			dac12load_t loadselect, 
			dac12fsout_t fsout, 
			dac12amp_t amp, 
			dac12df_t dataformat,
			dac12group_t group); 

  /**
   * Enable/Turn on the DAC.  Starts the process of acquiring the
   * correct reference voltage and calibrating the DAC output if
   * necessary.
   *
   * @return SUCCESS if the DAC can start now.
   */
  async command result_t enable();
  /**
   * Notification that the DAC has been enabled with the resulting status.
   */
  event void enableDone(result_t success);

  /**
   * Disable/Turn off the DAC port.  The release is dependent on the
   * reference voltage. 
   *
   * @return SUCCESS if possible to disable at this time.
   */
  async command result_t disable();
  /**
   * Notification that the DAC has been disabled with the result code.
   */
  event void disableDone(result_t success);

  /**
   * Disable DAC output.
   */
  async command result_t enableOutput();
  /**
   * Enable DAC output.
   */
  async command result_t disableOutput();
  
  /**
   * Set the value, fails if sequence or repeat in progress.
   */
  async command result_t set(uint16_t dacunits);

}
