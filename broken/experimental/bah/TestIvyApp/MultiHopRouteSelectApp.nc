/*			
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
/*
 *	MultiHopRouteSelect
 *	    - dummy code		
 *
 * Author:	Barbara Hohlt	
 * Project:	Ivy
 *
 *
 */

module MultiHopRouteSelectApp {
  
  provides {
    command bool bestCandidate(TOS_MsgPtr msg);

    interface StdControl as Control;
  }

  uses {
    interface Random; 
  }
}

implementation {

  uint16_t pickParent();
  bool pickRandProbability();

  command result_t Control.init() {

    call Random.init();

    return SUCCESS;
  }
  command result_t Control.start() {
    return SUCCESS;
  }
  command result_t Control.stop() {
    return SUCCESS;
  }

 /*
  * Determine whether this is the best candidate
  * so far. 
  *
  * When using the DOT3 hardware, signal strength 
  * information in TOS_Msg.strength may be used to
  * determine the nearest parent.
  *
  * The MICA does not have signal strength information.
  * Decide at random. Used on 4th Floor Cory Mica Testbed. 
  * 
  */
  command bool bestCandidate(TOS_MsgPtr msg) {
    
    return (pickRandProbability());
    
  }

#if 0
 /* 
  *  Pick a parent randomly 
  *  
  */
  command bool bestCandidateRand(TOS_MsgPtr msg) {
    
    return (pickRandProbability());

  }

 /* 
  *  Pick a parent statically.
  *  Used for testing only. 
  *
  */
  command bool bestCandidateTest(TOS_MsgPtr msg) {
    uint16_t candidate ;
    IvyNet *message = (IvyNet *) msg->data;
   
    candidate = pickParent(); 
    
    return (message->mote_id == candidate) ;
  }
#endif

  bool pickRandProbability() {
    uint16_t randProb, theRand;

    /* pick a number between zero and 99 */

    theRand  = 1 + ((call Random.rand() >> 6) & 0x7F);
    randProb = theRand % 100;


    dbg(DBG_USR2,"Random[%u]: p%up\n",theRand,randProb );

    return (randProb < 50);

  }

  uint16_t pickParent() {
    uint16_t local_parent;
    switch(TOS_LOCAL_ADDRESS)
    {
        case 6:
        case 7:
                local_parent = 3;
                break;
        case 8:
                local_parent = 4;
                break;
        case 9:
        case 10:
                local_parent = 5;
                break;
        default:
                local_parent = 4;

    }
    return local_parent;
  }
  
}
