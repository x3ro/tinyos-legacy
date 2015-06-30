/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/
 /** @author Miklos Maroti
 *   @author Brano Kusy, kusy@isis.vanderbilt.edu
 *   @modified Jan05 doc fix
 */

/**
 * Interface allows to initialize the gradient policy in the network, also
 * allows to set the root, and initilize the gradinet values at other
 * nodes
 */

interface GradientPolicy
{
	/**
	 * Declare this node to be the root. This will initiate the
	 * sending of radio messages and the hopcount information
	 * to be updated in all nodes of the network.
	 */
	command void setRoot();

	/**
	 * Returns the node ID of current root of the network.
	 * @return <code>0xFFFF</code> if no root was detected.
	 */
	command uint16_t getRoot();

	/**
	 * Returns the averaged hopcount from this node to the root.
	 * @return 4 times the averaged hopcount over several trials.
	 */
	command uint16_t getHopCount();
	
	/**
	 * For download of hop count field.
	 */
	command uint16_t setHopCount(uint16_t hc);
	
	/**
	 * For download of root field
	 */
	command uint16_t setRootAs(uint16_t r);
}
