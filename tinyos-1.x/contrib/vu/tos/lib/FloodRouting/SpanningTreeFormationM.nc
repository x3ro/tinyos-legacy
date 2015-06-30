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
 * Author: Vijayaraghavan Kalyanapasupathy, Janos Sallai
 * Date last modified: 05/20/2004
 */
module SpanningTreeFormationM {

    provides {
        interface StdControl;
        interface SpanningTreeParameters;
    }
    uses {
        interface FloodRouting;
        interface Leds;
    }
}

implementation
{
/* tree related information packet */
    typedef struct SpanningTreeFormationMessage
    {
        uint8_t   seqnum;
        uint16_t  nodeid;
        uint16_t  parent;
        uint16_t  gparent;
        uint16_t  ggparent;
        uint8_t   hopcount;    
    } SpanningTreeFormationMessage ;

    uint16_t    parent,gparent,ggparent,gggparent;
    uint8_t     lastseqnum,hopcount;
    result_t    isintree;

    SpanningTreeFormationMessage   formMsg;

 /* StdControl interface commands */
 
    uint8_t routingBuffer[130];

    command result_t StdControl.init(){
        call Leds.init();
        isintree = FALSE;
        hopcount = 0xFF;
        lastseqnum    =    0x00;
        gparent = ggparent = gggparent = 0xFFFE;
        parent = 0xFFFF;
        return SUCCESS;
    }

    command result_t StdControl.stop(){
        return SUCCESS;
    }
    
    command result_t StdControl.start(){
        return call FloodRouting.init(10,3,routingBuffer,sizeof(routingBuffer));
    }

 /* SpanningTree interface commands */

 /* Generic broadcast command - creates a packet from the data in this node and broadcasts it */

    task void broadcast(){
        formMsg.seqnum   = lastseqnum;
        formMsg.nodeid   = TOS_LOCAL_ADDRESS;
        formMsg.parent   = parent;
        formMsg.gparent  = gparent;
        formMsg.ggparent = ggparent;
        formMsg.hopcount = hopcount;
        if(call FloodRouting.send(&formMsg) != SUCCESS) {
            call Leds.redOn(); // indicates message send failure
        }
        call Leds.yellowOff();  // indicates message send processing end
    }

    command uint16_t SpanningTreeParameters.setRoot(){
        isintree = TRUE;
        call Leds.yellowOn(); // switched on whenever message has been scheduled to be sent
        hopcount = 0x00;
        gparent = ggparent = gggparent = 0xFFFE;
        parent = 0xFFFF;
        ++lastseqnum;
        post broadcast();    // broadcast spanning tree formation seed packet
        return TOS_LOCAL_ADDRESS;
    }

    command uint16_t SpanningTreeParameters.getParent(){
        return parent;
    }
    
    command uint16_t SpanningTreeParameters.getGParent(){
        return gparent;
    }
    
    command uint16_t SpanningTreeParameters.getGGParent(){
        return ggparent;
    }
    
    command uint16_t SpanningTreeParameters.getGGGParent(){
        return gggparent;
    }
    
    command uint16_t SpanningTreeParameters.getLastSequenceNumber(){
        return lastseqnum;
    }
    
    command uint8_t SpanningTreeParameters.getHopCount(){
        return hopcount;
    }
    
    command uint16_t SpanningTreeParameters.setParent(uint16_t p){
        return parent = p;
    }
    
    command uint16_t SpanningTreeParameters.setGParent(uint16_t gp){
        return gparent = gp;
    }
    
    command uint16_t SpanningTreeParameters.setGGParent(uint16_t ggp){
        return ggparent = ggp;
    }
    
    command uint16_t SpanningTreeParameters.setGGGParent(uint16_t gggp){
        return gggparent = gggp;
    }
    
    command uint8_t SpanningTreeParameters.setHopCount(uint8_t hc){
        return hopcount = hc;
    }
    
    command void    SpanningTreeParameters.setIsInTree(){
    	call Leds.yellowToggle();
    	call Leds.yellowToggle();
    	isintree = TRUE;
    }
    
    command result_t SpanningTreeParameters.isInTree(){
        return isintree;
    }
    
    command void SpanningTreeParameters.clearParameters(){
        hopcount = 0x00;
        gparent = ggparent = gggparent = 0xFFFE;
        parent = 0xFFFF;
        isintree = FALSE;
    }
    
    command result_t SpanningTreeParameters.isRoot(){
        if(gparent == (uint16_t) 0xFFFE){
            return TRUE;
        }
        return FALSE;
    }
            
    event result_t FloodRouting.receive(void *data){
        SpanningTreeFormationMessage *msg=(SpanningTreeFormationMessage *) data;
        call Leds.yellowOn();
        if(msg->seqnum != lastseqnum) {
            isintree = TRUE;
            lastseqnum  = msg -> seqnum;
            parent      = msg -> nodeid;
            gparent     = msg -> parent;
            ggparent    = msg -> gparent;
            gggparent   = msg -> ggparent;
            hopcount    = ((msg->hopcount) + 1);
            post broadcast(); // do generic send -- the retranmission of the recvd message
        }
        call Leds.greenOn();      // indicates that this node is now part of the tree
        return FAIL;
    }
}
