// $Id: Completion.nc,v 1.1 2005/02/17 01:59:57 idgay Exp $

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
 * A standard interface for reporting completion of requests. Typically
 * used by clients who want to retry requests rejected by busy components.
 *
 * @author David Gay <dgay@intel-research.net>
 */
interface Completion
{
  /**
   * An outstanding operation has completed, and the service is now
   * ready to accept a new request.
   * @return Ignored.
   */
  event result_t done();
}
