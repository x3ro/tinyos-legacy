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
// $Id: MagMHopRptConst.h,v 1.2 2005/04/15 20:10:06 phoebusc Exp $
/**  
 * MagMHopRptConst contains the constants used by the MagMHopRpt
 * application.  This is so the ncg, the NesC Constant Generator, will
 * properly extract the constants and dump it in a java file.
 *
 * @author Phoebus Chen
 * @modified 12/7/2004 File created
 */

//constants are used in MagMHopRptM.nc
enum {
  DEFAULT_REPORT_THRESH = 200, //40000,
  DEFAULT_REPORT_INTERVAL = 100, // Song's addition
  DEFAULT_NUM_FADE_INTERVALS = 2,
  DEFAULT_READ_FIRE_INTERVAL = 50,
  DEFAULT_FADE_FIRE_INTERVAL = 500,
  DEFAULT_WINDOW_SIZE = 5,
  MAX_WINDOW_SIZE = 10
};
