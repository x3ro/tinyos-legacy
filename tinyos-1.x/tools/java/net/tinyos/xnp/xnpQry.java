/*
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF CROSSBOW
 * TECHNOLOGY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * CROSSBOW TECHNOLOGY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND CROSSBOW TECHNOLOGY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
*/
/*-----------------------------------------------------------------------------
* xnpQry:
* Called after bcast of code capsules:
* - 1. Query motes to respond with missing capsules
* - 2. Then bcast missing capsules to all motes
* - 3. Repeat 1-2 until no more missing capsules
*---------------------------------------------------------------------------- */
package net.tinyos.xnp;

import net.tinyos.util.*;

class  xnpQry implements  Runnable{
 private xnpUtil m_xnpMote;
 private xnp     m_xnp;
 private short   m_MoteId;
 private static final int TOS_BROADCAST_ADDR = 0xffff;  //broadcast address
 private static final int sleep_long = 100;
 static final int MAX_CAPSULES_RETRY = 5;
 private int     radixID = 10;

 static final int
  CAPSULE_RCVD = 0,
  CAPSULE_BAD = 1,
  CAPSULE_NOT_RCVD = 2;

 public xnpQry(xnp xnp1, xnpUtil xnpMote1, short wMoteId, int radix) {
        m_xnp = xnp1;
        m_MoteId = wMoteId;
        m_xnpMote = xnpMote1;
        radixID = radix;
  }
//------------------------------------------------------------------------------
// -Bcast a missing code capsule.
// -All motes that get this msg write the code capsule
// -Only mote with wMoteId responds
// -Try multiple times
//------------------------------------------------------------------------------
   public int XmitCapsule(int iCapsuleNmb, short wMoteId){

   boolean bRet = m_xnpMote.CmdsendCapsule((short)TOS_BROADCAST_ADDR,wMoteId,
                            iCapsuleNmb, true, MAX_CAPSULES_RETRY, sleep_long);
   if (bRet && (m_xnpMote.m_NmbCodeCapsulesRcvd == iCapsuleNmb + 1)){
           return(CAPSULE_RCVD);
   }
   return(CAPSULE_NOT_RCVD);
}
//------------------------------------------------------------------------------
// Query for missing capsules
//------------------------------------------------------------------------------
   public void run() {
     int iReTries = 0;                           //# of retries to query
     int MAX_CAPSULES_RETRY = 10;		// modified from 5
     int iRet = 1;
     int iCapsuleNmb;
     short wMoteId;
     // short wMoteIdQry = 0;                          //mote id to query
     m_xnpMote.m_MoteIdQry = 0;     
     boolean bQry = true;
     int timeout = m_xnpMote.m_NmbCodeCapsules / 10; // timeout in 10ms

//request all motes to respond with missing capsules #
   while (bQry){
     iReTries = 0;
     while (iReTries < MAX_CAPSULES_RETRY){
 //       m_xnp.SetStatusTxt("Requesting missing capsules, retry# :" + Integer.toString(iReTries+1));
        // boolean bRet = m_xnpMote.CmdQryCapsules((short)TOS_BROADCAST_ADDR, wMoteIdQry, true, 1, timeout);  // MODIFIED FOR TIMEOUT from 100.
        boolean bRet = m_xnpMote.CmdQryCapsules((short)TOS_BROADCAST_ADDR,
        (short)m_xnpMote.m_MoteIdQry, true, 1, timeout);
        if (bRet){
          iCapsuleNmb =  m_xnpMote.m_NmbCodeCapsulesRcvd;
          wMoteId =(short) m_xnpMote.m_mote_id_rcvd;            //id of mote that responded

          // check if the mote has received all the packets.
          // mote reply with the capsule number greather than
          // the largest possible capsules.
          if (iCapsuleNmb > m_xnpMote.m_NmbCodeCapsules) {
            String sMote = Integer.toString(wMoteId & 0xff, radixID);
            String sCN = Integer.toString(iCapsuleNmb);
            m_xnp.SetStatusTxt("Mote: "  + sMote + " has received all the capsules");
            // wMoteIdQry = 0;
            m_xnpMote.m_MoteIdQry = 0;
            iReTries = 0;
          }
          else {
            String sMote = Integer.toString(wMoteId & 0xff, radixID);
            String sCN = Integer.toString(iCapsuleNmb);
            m_xnp.SetStatusTxt("Mote: "  + sMote + " missing capsule #: " + sCN);
            iRet =  XmitCapsule(iCapsuleNmb, wMoteId);     //xmit code capsule to all
            // if (iRet == CAPSULE_RCVD) wMoteIdQry = wMoteId;
            // else                      wMoteIdQry = 0;

            m_xnpMote.m_MoteIdQry = wMoteId;

            iReTries = 0;
          }

        }
        else iReTries++;
     }
     // if (wMoteIdQry != 0) wMoteIdQry = 0;
     if (m_xnpMote.m_MoteIdQry != 0) m_xnpMote.m_MoteIdQry = 0;
     else   bQry = false;
   }
     m_xnp.SetStatusTxt("No responses on missing capsules query");
     m_xnp.EndBcastDownLoad();
     return;
   }
}

