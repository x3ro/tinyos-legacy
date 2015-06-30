// $Id: Sensor.nc,v 1.1 2005/02/17 01:59:57 idgay Exp $

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
 * New (proposed) standard sensor interface.
 *
 * @author David Gay <dgay@intel-research.net>
 */
interface Sensor {
  /** Request sensor sample
   *  @return SUCCESS if request accepted, FAIL if it is refused
   *    dataReady or error will be signaled if SUCCESS is returned
   */
  command result_t getData();

  /** Return sensor value
   * @param data Sensor value
   * @return Ignored
   */
  event result_t dataReady(uint16_t data);

  /** Signal that the sensor failed to get data
   * @param info error information, sensor board specific
   * @return Ignored
   */
  event result_t error(uint16_t info);
}
