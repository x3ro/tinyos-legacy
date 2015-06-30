/*
 * Copyright (c) 2004, Vanderbilt University
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
 *
 * Author: Vijayaraghavan Kalyanapasupathy
 * Date last modified: 05/20/2004
 */
 
/* Interface to extract information about the constructed spanning tree */

interface SpanningTreeParameters {

    /*
     * Start tree formation, which is done by using a seed packet
     */

    command uint16_t    setRoot();
    
    /*
     * Commands for querying tree parameters
     */
    
    command uint16_t    getParent();
    command uint16_t    getGParent();
    command uint16_t    getGGParent();
    command uint16_t    getGGGParent();
    command uint8_t		getHopCount();
    command void        clearParameters();
    command result_t    isRoot();
    
    /* 
     * Get the sequence number of the last spanning tree formation message sent out.
     * Included in case dynamic tree re-formation is included later on. Currently, 
     * everytime a "setRoot" is invoked on the SpanningTreeFormationModule, the sequence
     * is one greater than the last time setroot was called. This information is synchronized 
     * across all nodes; hence calling setRoot on a different node will ensure that the sequence 
     * number is still different
     */
    
    command uint16_t    getLastSequenceNumber();
    
    /*
     * Downloadable configuration of tree: Commands to do just that.
     */
     
	command uint16_t   setParent(uint16_t p);
	command uint16_t   setGParent(uint16_t gp);
	command uint16_t   setGGParent(uint16_t ggp);
	command uint16_t   setGGGParent(uint16_t gggp);
	command uint8_t    setHopCount(uint8_t hc);
	command void       setIsInTree();
	command result_t   isInTree();
}
