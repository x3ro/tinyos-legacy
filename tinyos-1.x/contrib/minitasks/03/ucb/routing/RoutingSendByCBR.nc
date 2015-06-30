/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: RoutingSendByCBR.nc,v 1.1 2003/05/04 03:26:07 cssharp Exp $

includes Routing;

interface RoutingSendByCBR {
    /**
    Send a message out to a remote motes satisfying a set of constraints
    while choosing a route that is optimal and satisfying route constraints <p>
    @param type one or all
    @param dest destination constraints
    @param rout route constraints
    @param objs objectives
    @param length message length
    @param msg array of bytes need to send out
    @return SUCCESS if successful
    */
    command result_t send(
	RoutingCBR_t* cbr,
	TOS_MsgPtr msg
    );
    /**
    Send message done signal <p>
    @param msg The message just sent out
    @param success If the send is done successfully
    */
    event result_t sendDone(
        TOS_MsgPtr msg,
        result_t success 
    );
}

