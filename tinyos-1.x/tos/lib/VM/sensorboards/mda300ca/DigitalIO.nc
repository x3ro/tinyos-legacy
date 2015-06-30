// $Id: DigitalIO.nc,v 1.2 2005/02/17 02:38:27 idgay Exp $

/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * An interface for the digital I/O facilities of the PCF8574APWR used
 * on the mda300ca board. See the PCF8574APWR datasheet for more details
 * (in a nutshell, pins can be written to 0 or 1; any pin which has been
 * set to 1 can also be read).
 *
 * @author David Gay <dgay@intel-research.net>
 */
interface DigitalIO {
  /**
   * Read the state of the PCF8574APWR pins.
   * @return SUCCESS if the get request is accepted; getDone will be signaled.
   *   FAIL if the component is busy.
   */
  command result_t get();

  /**
   * Signaled when a get operation completes.
   * @param port State of the PCF8574APWR pins if ok != FAIL
   * @param ok SUCCESS is the get was successful, FAIL if some error occured
   * @return Ignored.
   */
  event result_t getDone(uint8_t port, result_t ok);

  /**
   * Set the state of the PCF8574APWR pins.
   * Note: the PCF8574APWR does not get reset at reboot time. It is best
   * to call set(0xff) to ensure a consistent initial state.
   * @param port New pin state.
   * @return SUCCESS if the set request is accepted; setDone will be signaled.
   *   FAIL if the component is busy.
   */
  command result_t set(uint8_t port);

  /**
   * Signaled when a set operation completes.
   * @param ok SUCCESS is the set was successful, FAIL if some error occured
   * @return Ignored.
   */
  event result_t setDone(result_t ok);

  /**
   * Enable or disable the 'change' event, which is signaled when the state
   * of PCF8574APWR input pins change.
   * @param detectChange TRUE to enable change events, FALSE to disable them.
   * @return SUCCESS.
   */
  command result_t enable(bool detectChange);

  /**
   * Signaled when the state of any PCF8574APWR input pin changes. Clients
   * should read the state of the pins (see get) after a change event (see
   * the PCF8574APWR datasheet for more details).
   *
   * Note that multiple changes on the input pins may produce only one
   * change event.
   * @return Ignored.
   */
  event result_t change();
}
