/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: CompComm.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/**
 * Communication Interface between the Core Computational Component
 * and the rest of the application (typically the main application)
 * for passing data.
 * 
 * @author Phoebus Chen
 * @modified 9/13/2004 First Implementation
 */

includes MagAggTypes;

interface CompComm {
  /** This is a command instead of an event because we want to preserve the
   *  "tree structure" of the components.  So the main application
   *  component sends commands (actually, just passes reports) to the core
   *  computation component.
   */
  command result_t passReports(uint16_t sourceMoteID, Mag_t magReport,
			       location_t loc);

  /** Signalled by the Computing Component to the main application component.
   */
  event result_t aggDataReady(MagWeightPos_t aggReport);
}
