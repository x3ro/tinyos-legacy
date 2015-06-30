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
 Description: The top level component for the TPSN middleware service.
**********************************************************************/

includes TPSNMsg;

configuration TPSNsyncC{
  provides{
    interface StdControl;
    interface TPSNsync;
  }
}

implementation{
  components TPSNsyncM, GenericComm as Comm, LedsC, SClockC, CC1000RadioC;

  StdControl = TPSNsyncM;
  TPSNsync = TPSNsyncM;

  TPSNsyncM.SubControl -> Comm;

  /*  TimeSync Message */
  TPSNsyncM.SendTSMsg -> Comm.SendMsg[AM_TSMSG];
  TPSNsyncM.ReceiveTSMsg -> Comm.ReceiveMsg[AM_TSMSG];

  /* TimeSync Acknowledgement Message */
  TPSNsyncM.SendTSACKMsg -> Comm.SendMsg[AM_TSACKMSG];
  TPSNsyncM.ReceiveTSACKMsg -> Comm.ReceiveMsg[AM_TSACKMSG];

  /* Level Discovery Message */
  TPSNsyncM.SendLDSMsg -> Comm.SendMsg[AM_LDSMSG];
  TPSNsyncM.ReceiveLDSMsg -> Comm.ReceiveMsg[AM_LDSMSG];

  /* Level Request Message */
  TPSNsyncM.SendLREQMsg -> Comm.SendMsg[AM_LREQMSG];
  TPSNsyncM.ReceiveLREQMsg -> Comm.ReceiveMsg[AM_LREQMSG];

  /* Time Stamp Event from Stack */
  //  TPSNsyncM.TimeStamp -> Comm;
  TPSNsyncM.RadioSendCoordinator -> CC1000RadioC.RadioSendCoordinator;
  TPSNsyncM.RadioReceiveCoordinator -> CC1000RadioC.RadioReceiveCoordinator;

  TPSNsyncM.Leds -> LedsC;

  TPSNsyncM.SClock -> SClockC; 
}
