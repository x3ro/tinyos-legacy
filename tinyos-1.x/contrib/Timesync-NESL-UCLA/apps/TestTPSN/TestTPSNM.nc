/* -*-C-*- */
/**********************************************************************
Copyright ©2003 The Regents of the University of California (Regents).
All Rights Reserved.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose, without fee, and without written 
agreement is hereby granted, provided that the above copyright notice 
and the following three paragraphs appear in all copies and derivatives 
of this software.

IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE 
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF 
CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, 
ENHANCEMENTS, OR MODIFICATIONS.

This software was created by Ram Kumar {ram@ee.ucla.edu}, 
Saurabh Ganeriwal {saurabh@ee.ucla.edu} at the 
Networked & Embedded Systems Laboratory (http://nesl.ee.ucla.edu), 
University of California, Los Angeles. Any publications based on the 
use of this software or its derivatives must clearly acknowledge such 
use in the text of the publication.
**********************************************************************/
/*********************************************************************
 Description: The application synchronizes the node to a node higher
 up in the hierarchy periodically, with a period of 20 mticks.
 Please read the documentation prior to using the protocol.
**********************************************************************/
module TestTPSNM{
  provides{
    interface StdControl;
  }
  uses{
    interface StdControl as SubControl;
    interface TPSNsync;
  }
}

implementation{
  
  /*********** StdControl Interface *************/
  command result_t StdControl.init(){
    call SubControl.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start(){
    call SubControl.start();
    call TPSNsync.periodicSync(20); /* API call to the TPSN protocol requesting periodic synchronization. Period = 20 mTicks */
    return SUCCESS;
  }

  command result_t StdControl.stop(){
    return SUCCESS;
  }

  /*********** TPSNsync Interface ************/
  async event void TPSNsync.timerFire(){}

  async event void TPSNsync.alarmRing(){};

  async event result_t TPSNsync.syncDone(){return SUCCESS;}
}
