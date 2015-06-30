/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: RssiReflectionM.perl.nc,v 1.8 2003/07/02 05:04:22 ckarlof Exp $

/*
  This type of reflection will grab calibration coefficients and anything
  else that is useful for RSSI ranging so that a distance estimate can be
  gotten by simply pulling or pushing this attribute.  Usually, this attribute
  is empty so it is NOT actually pulled/pushed.  The rssi value of the incoming
  packet is added to the moving average, the new mean is used with the calibration
  coefficients to generate a new distance estimate which is stored in the Distance
  attribute.

   This particular version must be used with a Ranging/ewma_t type. The
   calibration coefficients are of type Ranging/polynomialD1_t and the distance
   attribute must be of type Ranging/distance_t, and you might have a problem
   if these are different.

   you need to give it the parameters:
   ${TxrCalibCoeffsAttr} = name of Txr Calibration coefficients attribute
   ${TxrCalibCoeffsType} = type of Txr Calibration coefficients attribute
   ${TxrCalibCoeffsRefl} = name of reflection of Txr Calibration coefficients
   ${DistanceAttr} = name of distance attribute
   ${DistanceType} = name of distance reflection
   ${DistanceRefl} = name of distance reflection
//   ${RssiRanging} = name of Rssi ranging component //(not needed anymore)
   ${Rssi_ADC_channel} = channel to read rssi data from if using TinyViz
*/

includes ${Neighborhood};

module ${Reflection}M
{
  provides interface ${Attribute}Reflection;
  provides interface ${Attribute}ReflectionSnoop;
  provides interface StdControl;
  uses interface ${Attribute};
  uses interface NeighborhoodComm as DataComm;
  uses interface NeighborhoodComm as PullComm;
  uses interface ${Neighborhood}_private;
  uses interface ${TxrCalibCoeffsAttr};
  uses interface ${TxrCalibCoeffsAttr}Reflection;
  uses interface ${DistanceAttr}Reflection;
  uses interface Rssi;
}
implementation
{
  bool m_pushTask_pending;
  nodeID_t m_pull_id;

  command result_t StdControl.init()
  {
    m_pushTask_pending = FALSE;
    m_pull_id = 0;
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

  command ${Type} ${Attribute}Reflection.get( nodeID_t id )
  {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    return node ? node->data_${Reflection} : G_default_node_${Neighborhood}.data_${Reflection};
  }

  task void push()
  {
    TOS_MsgPtr msg = call ${Neighborhood}_private.lockMsgBuffer();
    m_pushTask_pending = FALSE;
    if( msg != 0 )
    {
		//push space for the calib coeffs 
      ${TxrCalibCoeffsType}* data = (${TxrCalibCoeffsType}*)pushToRoutingMsg( msg, sizeof(${TxrCalibCoeffsType}) );
      if( data != 0 )
      {
		  *data = call ${TxrCalibCoeffsAttr}.get();//transmit the calib coeffs
		  if( call DataComm.send( POTENTIAL_CONEIGHBORS, msg ) == SUCCESS )
			  return;
      }
      call ${Neighborhood}_private.unlockMsgBuffer( msg );
    }
  }

  command result_t ${Attribute}Reflection.push()
  {
    return post push() ? SUCCESS : FAIL;
  }

  void postPushTask()
  {
    if( m_pushTask_pending == FALSE )
    {
      m_pushTask_pending = TRUE;
      post push();
    }
  }

  event result_t DataComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call ${Neighborhood}_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr DataComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    ${TxrCalibCoeffsType}* data = (${TxrCalibCoeffsType}*)popFromRoutingMsg( msg, sizeof(${TxrCalibCoeffsType}) );
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( src );
    if( node != 0 )
    {
	  uint16_t rssi;
	  call ${TxrCalibCoeffsAttr}Reflection.scribble(src,*data);

	  //add the rssi value to the rssi reflection

#ifdef MAKEPC

      dbg(DBG_USR1, "RSSI MSG: transmitter %d\n", src);                  //uncomment for simulation
	  rssi=generic_adc_read(TOS_LOCAL_ADDRESS,${Rssi_ADC_channel},0);//uncomment for simulation

#else

      rssi=msg->strength;                                   //uncomment for deployment

#endif
      if(rssi==0) return msg;//this means an invalid value was read
	  dbg(DBG_USR1, "RSSI: value = %d\n", rssi);                  //uncomment for simulation
	  addToEWMA((float)rssi, &(node->data_${Reflection}));
	  //estimate the distance and set the distance reflection
//	  call ${DistanceAttr}Reflection.scribble(src, call Rssi.estimateDistance(node->data_${Reflection}, (polynomial_t*)data));
      signal ${Attribute}Reflection.updated( src, node->data_${Reflection} );
    }
    return msg;
  }

  event TOS_MsgPtr DataComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
//    ${Type}* data = (${Type}*)popFromRoutingMsg( msg, sizeof(${Type}) );
//    signal ${Attribute}ReflectionSnoop.updatedNAN( src, *data );
    return msg;
  }

  default event void ${Attribute}ReflectionSnoop.updatedNAN( RoutingDestination_t src, ${Type} value ){}

  task void pull()
  {
    TOS_MsgPtr msg = call ${Neighborhood}_private.lockMsgBuffer();
    if( msg != 0 )
    {
      if( call PullComm.send( m_pull_id, msg ) == SUCCESS )
	return;
      call ${Neighborhood}_private.unlockMsgBuffer( msg );
    }
  }

  command result_t ${Attribute}Reflection.pull( nodeID_t id )
  {
    m_pull_id = id;
    return post pull() ? SUCCESS : FAIL;
  }

  event result_t PullComm.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call ${Neighborhood}_private.unlockMsgBuffer( msg );
    return SUCCESS;
  }

  event TOS_MsgPtr PullComm.receive( nodeID_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }

  event TOS_MsgPtr PullComm.receiveNAN( RoutingDestination_t src, TOS_MsgPtr msg )
  {
    postPushTask();
    return msg;
  }



  command void ${Attribute}Reflection.scribble( nodeID_t id, ${Type} value )
  {
    ${Neighborhood}_t* node = call ${Neighborhood}_private.getID( id );
    if( node != 0 )
      node->data_${Reflection} = value;
  }

  event void ${Attribute}.updated()
  {
    if( ${AutoPush} )
      postPushTask();
  }

  event void RssiTxrCoeffsAttr.updated( ){
  }

  event void RssiTxrCoeffsAttrReflection.updated( nodeID_t id, ${TxrCalibCoeffsType} value ){
  }

  event void DistanceAttrReflection.updated( nodeID_t id, distance_t value ){
  }

}


