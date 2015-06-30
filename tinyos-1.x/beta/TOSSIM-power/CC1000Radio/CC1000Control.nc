// $Id: CC1000Control.nc,v 1.1 2004/04/22 20:05:04 shnayder Exp $

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
 * Authors:		Philip Buonadonna, Jaein Jeong
 * Date last modified:  $Revision: 1.1 $
 *
 * Interface for CC1000 specific controls and signals
 */

/**
 * CC1000 Radio Control interface.
 * @author Philip Buonadonna
 * @author Jaein Jeong
 */
interface CC1000Control
{
  /**
   * Tune the radio to one of the frequencies available in the CC1K_Params table.
   * Calling Tune will allso reset the rfpower and LockVal selections to the table 
   * values. 
   * 
   * @param freq The index into the CC1K_Params table that holds the desired preset
   * frequency parameters.
   * 
   * @return Status of the Tune operation.
   */

  command result_t TunePreset(uint8_t freq); 

  /**
   * Tune the radio to a given frequency. Since the CC1000 uses a digital
   * frequency synthesizer, it cannot tune to just an arbitrary frequency.
   * This routine will determine the closest achievable channel, compute 
   * the necessary parameters and tune the radio.
   * 
   * @param The desired channel frequency, in Hz.
   * 
   * @return The actual computed channel frequency, in Hz.  A return value
   * of '0' indicates that no frequency was computed and the radio was not
   * tuned.
   */

  command uint32_t TuneManual(uint32_t DesiredFreq);

  /**
   * Shift the CC1000 Radio into transmit mode.
   *
   * @return SUCCESS if the radio was successfully switched to TX mode.
   */

  async command result_t TxMode();

  /**
   * Shift the CC1000 Radio in receive mode.
   *
   * @return SUCCESS if the radio was successfully switched to RX mode.
   */

  async command result_t RxMode();

  /**
   * Turn off the BIAS power on the CC1000 radio, but leave the core 
   * and crystal oscillator powered.  This will result in approximately
   * a 750 uA power savings. 
   *
   * @return SUCCESS when the BIAS powered is shutdown.
   */

  command result_t BIASOff();			

  /**
   * Turn the BIAS power on. This function must be followed by a call
   * to either RxMode() or TxMode() to place the radio in a recieve/transmit
   * state respectively. There is approximately a 200us delay when restoring
   * BIAS power.
   *
   * @return SUCCESS when BIAS power has been restored.
   */

  command result_t BIASOn();			

  /**
   * Set the transmit RF power value.  The input value is simply an arbitrary
   * index that is programmed into the CC1000 registers.  Consult the CC1000
   * datasheet for the resulting power output/current consumption values.
   *
   * @param power A power index between 1 and 255.
   * 
   * @return SUCCESS if the radio power was adequately set.
   *
   */

  command result_t SetRFPower(uint8_t power);	

  /**
   * Get the present RF power index.
   *
   * @return The power index value.
   */

  command uint8_t  GetRFPower();		

  /** 
   * Select the signal to monitor at the CHP_OUT pin of the CC1000.  See the
   * CC1000 data sheet for the available signals.
   * 
   * @param LockVal The index of the signal to monitor at the CHP_OUT pin
   * 
   * @return SUCCESS if the selected signal was programmed into the CC1000
   *
   */

  command result_t SelectLock(uint8_t LockVal); 

  /**
   * Get the binary value from the CHP_OUT pin.  Analog signals cannot be read using
   * function.
   *
   * @return 1 - Pin is high or 0 - Pin is low
   *
   */

  command uint8_t  GetLock();

  /**
   * Returns whether the present frequency set is using high-side LO
   * injection or not.  This information is used to determine if the
   * data from the CC1000 needs to be inverted or not.
   *
   * @return TRUE if high-side LO injection is being used (i.e. data
   * does NOT need to be inverted at the receiver.
   */
  command bool	   GetLOStatus();		// Query if frequency set LO side. High side LO = TRUE
}
