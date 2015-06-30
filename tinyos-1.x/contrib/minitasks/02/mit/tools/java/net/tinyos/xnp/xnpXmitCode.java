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
* xnpXmitCode:
* Download all code capsules to the motes either bcast or just one mote
*---------------------------------------------------------------------------- */
package net.tinyos.xnp;

import net.tinyos.util.*;
class  xnpXmitCode implements  Runnable{
 private xnpUtil m_xnpMote;
 private xnp     m_xnp;
 private short   m_MoteId;
 private static final int TOS_BROADCAST_ADDR = 0xffff;  //broadcast address
 private static final int sleep_long = 20;
 private static final int sleep_short = 50;
 static final int MAX_CAPSULES_RETRY = 5;
 static final int
  CAPSULE_RCVD = 0,
  CAPSULE_BAD = 1,
  CAPSULE_NOT_RCVD = 2;

 public xnpXmitCode(xnp xnp1, xnpUtil xnpMote1, short wMoteId) {
        m_xnp = xnp1;
        m_MoteId = wMoteId;
        m_xnpMote = xnpMote1;
    }

 public xnpXmitCode(xnpUtil xnpMote1) {
        m_xnpMote = xnpMote1;
       }
//------------------------------------------------------------------------------
// Xmt code capsule and chk response from Mote after xmitting code capsule
// Try multiple times
// If motes_id is bcast then just delay and return
//------------------------------------------------------------------------------
   public int XmitCapsule(int iCapsuleNmb, short wMoteId){
   int iReTries = 0;
//if bcast address just return
   if (wMoteId == (short)TOS_BROADCAST_ADDR){
      m_xnpMote.CmdsendCapsule((short)TOS_BROADCAST_ADDR ,(short)0, iCapsuleNmb,
                               false, 1, sleep_long);
      return(CAPSULE_RCVD);
   }
//single mote
   boolean bRet = m_xnpMote.CmdsendCapsule(wMoteId ,wMoteId, iCapsuleNmb,
                            true, MAX_CAPSULES_RETRY, sleep_short);

   if (bRet && (m_xnpMote.m_NmbCodeCapsulesRcvd == iCapsuleNmb+1))
           return(CAPSULE_RCVD);
   else return(CAPSULE_NOT_RCVD);
}
//------------------------------------------------------------------------------
// Chk response from Mote after downloading all code capsules
// If motes_id is bcast then do nothing
//------------------------------------------------------------------------------
   public void ChkEndDwnload(){

   if (m_MoteId != (short)TOS_BROADCAST_ADDR){
     boolean bRet = m_xnpMote.CmdGetLoadStatus(m_MoteId,true, 3, 30 );
     if (bRet){
       m_xnp.SetStatusTxt("No response from Mote after requesting # of capsules rcvd");
       return;
     }
   }
   m_xnp.SetStatusTxt("Done-number of code capsules sent: " +
                     Long.toString(m_xnpMote.m_NmbCodeCapsulesRcvd));
}
//------------------------------------------------------------------------------
// Download code capsules to Mote
//------------------------------------------------------------------------------
   public void run() {
      m_xnpMote.m_NmbCodeCapsulesXmitted = 0;       //zero the # of code capsules xmitted
      m_xnpMote.m_bCodeDwnloadDone = false;         //code download not complete
      int iCapsuleNmb = 0;                        //code capsule number to xmit
      int iNmbCapsules = m_xnpMote.m_NmbCodeCapsules;;
      iCapsuleNmb = 0;

      while (iCapsuleNmb < iNmbCapsules){
         int iRet = XmitCapsule(iCapsuleNmb,m_MoteId);
         if (iRet == CAPSULE_RCVD){
              m_xnp.SetStatusTxt("Downloaded capsule#: " +
                               Long.toString(m_xnpMote.m_NmbCodeCapsulesXmitted));

              m_xnpMote.m_NmbCodeCapsulesXmitted++;	     //inc # of code capsules xmitted;
              iCapsuleNmb++;
         }
          else{
            m_xnp.SetStatusTxt("Exceeded maximum retries for capsule: " +
                Long.toString(m_xnpMote.m_NmbCodeCapsulesXmitted));
            m_xnp.EndDownLoad();
            return;
        }
      }
//Xmit msg to see how many code capsules where rcvd by mote
      ChkEndDwnload();

    m_xnp.SetStatusTxt("Download complete");
    m_xnp.EndDownLoad();
  }
}
