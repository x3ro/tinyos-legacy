// $Id: Power.nc,v 1.1 2005/02/17 01:59:57 idgay Exp $

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
 * Turn a voltage on or off.
 *
 * @author David Gay <dgay@intel-research.net>
 */
interface Power {
  /**
   * Turn voltage on or off.
   * @param on TRUE to turn the voltage on, FALSE to turn it off.
   * @return SUCCESS if the set request is accepted; setDone will be signaled.
   *   FAIL if the component is busy.
   */
  command result_t set(bool on);

  /**
   * Signaled when a set operation completes.
   * @return Ignored.
   */
  event result_t setDone();
}
