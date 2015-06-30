// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRStateCommand.nc,v 1.1.1.1 2005/06/19 04:34:38 rfonseca76 Exp $
                                    
/*                                                                      
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
 * Authors:  Rodrigo Fonseca        
 * Date Last Modified: 2005/05/26
 */


includes AM;
includes BVR;

interface BVRStateCommand {
    /* Set this node's coordinates do the value pointed to by coords
     * The coordinates should be copied, coords must not be assumed safe,
     * and may be changed.
     */
    command result_t setCoordinates(Coordinates * coords);

    /* Get this node's coordinates. coords is made to point to this nodes
     * coords, so that the caller should not change the value pointed to
     * by coords.
     */
    command result_t getCoordinates(Coordinates ** coords);

    /**/
    command result_t startRootBeacon();
    command result_t stopRootBeacon();
    command result_t setRootBeacon(uint8_t n);
    command result_t isRootBeacon(bool *value);

    command result_t getRootInfo(uint8_t n , BVRRootBeacon **r);
    command result_t getNumNeighbors(uint8_t *n);

}
