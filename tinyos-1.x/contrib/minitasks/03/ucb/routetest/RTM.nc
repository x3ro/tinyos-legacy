/*									tab:4
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * AUTHOR: nks
 * DATE:   6/19/03
 */


module RTM {
  provides interface StdControl;
  uses interface ERoute as TreeRoute;
  uses interface Timer;
}
implementation {

  uint8_t buf[8] __attribute__((C)) = {0x1, 0x4, 0x9, 0x16,
                                       0x25, 0x36, 0x49, 0x64};
  uint8_t buf2[8] __attribute__((C)) = {0x1, 0x1, 0x2, 0x3,
                                       0x5, 0x8, 0x13, 0x21};  
  
  command result_t StdControl.init ()
    {
      return SUCCESS;
    }

  command result_t StdControl.start()
    {
      if (TOS_LOCAL_ADDRESS == 7) {
        dbg (DBG_USR1, "RTM: start() called from TOS addr %d\n",
             TOS_LOCAL_ADDRESS);
        call Timer.start (TIMER_ONE_SHOT, 5000);
      }
      if (TOS_LOCAL_ADDRESS == 6) {
        call Timer.start(TIMER_ONE_SHOT, 7000);
      }
      if (TOS_LOCAL_ADDRESS == 0) {
        call Timer.start(TIMER_ONE_SHOT, 10000);
      }
      if (TOS_LOCAL_ADDRESS == 2) {
        call Timer.start(TIMER_ONE_SHOT, 15000);        
      }
      if (TOS_LOCAL_ADDRESS == 3) {
        call Timer.start(TIMER_REPEAT, 20000);        
      }
      if (TOS_LOCAL_ADDRESS == 4) {
        call Timer.start(TIMER_ONE_SHOT, 25000);        
      }
      
      return SUCCESS;
    }

  command result_t StdControl.stop()
    {
      return SUCCESS;
    }

  task void buildTree()
    {
      dbg(DBG_USR1, "RTM: building landmark tree \n"); 
      call TreeRoute.build(TREE_LANDMARK);
    }

  task void buildTree2()
    {
      dbg(DBG_USR1, "RTM: building basestation tree \n"); 
      call TreeRoute.build(TREE_BASESTATION);
    }  

  task void sendMessage()
    {
      dbg(DBG_USR1, "RTM: sending message to landmark\n");
      call TreeRoute.send (TREE_LANDMARK, 8, buf);
    }

  task void buildCrumb()
    {
      dbg(DBG_USR1, "RTM: building a crumb trail as mobile agent 1\n");
      call TreeRoute.buildTrail (MA_PURSUER1, TREE_LANDMARK, 100);
    }

  task void buildCrumb2()
    {
      dbg(DBG_USR1, "RTM: building a crumb trail as mobile agent 2\n");      
      call TreeRoute.buildTrail (MA_PURSUER2, TREE_LANDMARK, 101);
    }
  
  task void sendToMobile()
    {
      dbg(DBG_USR1, "RTM: sending message to all mobile agents\n");      
      call TreeRoute.send(MA_ALL, 8, buf2);
    }
  
  event result_t Timer.fired()
    {
      if (TOS_LOCAL_ADDRESS == 0)
        post sendMessage();
      if (TOS_LOCAL_ADDRESS == 7) 
        post buildTree();
      if (TOS_LOCAL_ADDRESS == 6)
        ;//        post buildTree2();
      if (TOS_LOCAL_ADDRESS == 2)
        post buildCrumb();
      if (TOS_LOCAL_ADDRESS == 3)
        post sendToMobile();
      if (TOS_LOCAL_ADDRESS == 4)
        post buildCrumb2();
      return SUCCESS;
    }

  event result_t TreeRoute.sendDone (EREndpoint dest, uint8_t * data)
    {
      return SUCCESS;
    }

  event result_t TreeRoute.receive (EREndpoint dest, uint8_t dataLen,
                                    uint8_t * data)
    {
      dbg(DBG_USR1, "***RTM:receive msg %d bytes [%x %x %x %x %x %x %x %x]\n",
          dataLen, data[0], data[1], data[2], data[3], data[4], data[5],
          data[6], data[7]);
      
      return SUCCESS;
    }
}

