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
// $Id: EstimationCommM.nc,v 1.4 2003/01/31 21:10:53 cssharp Exp $

//!! Config 24 { uint16_t EstimationCommM_camera_address = 0x300; }


includes common_structs;
includes Routing;

module EstimationCommM
{
  provides
  {
    interface EstimationComm;
    interface StdControl;
  }
  uses
  {
    interface RoutingSendByLocation as SendEstimation;
    interface RoutingReceive as ReceiveEstimation;
    interface RoutingSendByAddress as SendCameraPointer;
    interface TimedLeds;
  }
}
implementation
{
  TOS_Msg m_msgdata;
  TOS_MsgPtr m_msg;
  bool m_is_forwarding;

  Estimation_t m_est;

  TOS_Msg m_estmsg;
  bool m_is_est_sending;


  command result_t StdControl.init()
  {
    m_msg = &m_msgdata;
    m_is_forwarding = FALSE;
    m_is_est_sending = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }


  task void forwarder()
  {
    CameraPointer_t* head = (CameraPointer_t*)initRoutingMsg( m_msg, sizeof(CameraPointer_t) );
    const float dd = 256;

    head->x = m_est.x / dd;
    head->y = m_est.y / dd;
    head->z = m_est.z / dd;

    if( call SendCameraPointer.send( G_Config.EstimationCommM_camera_address, m_msg ) == FAIL )
      m_is_forwarding = FALSE;
  }


  event result_t SendCameraPointer.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if( msg == m_msg )
      m_is_forwarding = FALSE;
    return SUCCESS;
  }


  event TOS_MsgPtr ReceiveEstimation.receive( TOS_MsgPtr msg )
  {
    if( m_is_forwarding == FALSE )
    {
      TOS_MsgPtr tmp = m_msg;
      Estimation_t* esthead = (Estimation_t*)popFromRoutingMsg( msg, sizeof(Estimation_t) );
      if( esthead == 0 ) return msg;
      m_is_forwarding = TRUE;
      m_est = *esthead;
      m_msg = msg;
      post forwarder();
      return tmp;
    }
    return msg;
  }



  command result_t EstimationComm.sendEstimation( const Estimation_t* est )
  {
    if( m_is_est_sending == FALSE )
    {
      Estimation_t* msgbody = (Estimation_t*)initRoutingMsg( 
	&m_estmsg, sizeof(Estimation_t) );
      RoutingLocation_t dest = { pos:{x:0, y:0, z:0}, radius:{x:0, y:0, z:0} };
      if( msgbody == 0 ) return FAIL;

      *msgbody = *est;

      if( call SendEstimation.send( &dest, &m_estmsg ) == SUCCESS )
      {
	m_is_est_sending = TRUE;
	call TimedLeds.yellowOn( 667 );
	return SUCCESS;
      }
    }

    return FAIL;
  }


  event result_t SendEstimation.sendDone( TOS_MsgPtr msg, result_t success )
  {
    if( msg == &m_estmsg )
      m_is_est_sending = FALSE;
    return SUCCESS;
  }
}

