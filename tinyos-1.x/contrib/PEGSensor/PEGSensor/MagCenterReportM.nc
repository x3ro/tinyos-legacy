
includes MagCenter;

//!! Config 54 { uint8_t MagCenterSendMode = SEND_MAG_CENTER_BROADCAST; }
//!! Config 55 { uint16_t MagCenterClosestInjectDiameter = 0x0100; }

module MagCenterReportM
{
  provides interface MagCenterReport;

  uses interface RoutingSendByBroadcast as SendMagCenterBroadcast;
  uses interface ERoute as SendMagCenterCroute;
  uses interface MsgBuffers;
  uses interface RoutingReceive as ClosestInject;
  uses interface RoutingReceive as AlwaysInject;
  uses interface MagPositionAttr;
  uses interface Valid as MagPositionValid;
}
implementation
{
  void sendBroadcast( MagLeaderReport_t report )
  {
    TOS_MsgPtr msg = call MsgBuffers_alloc();
    if( msg != NULL )
    {
      MagLeaderReport_t* body = (MagLeaderReport_t*)initRoutingMsg( msg, sizeof(report) );
      if( body != NULL )
      {
	*body = report;
	if( call SendMagCenterBroadcast.send( 0, msg ) == SUCCESS )
	  return;
      }
      call MsgBuffers.free( msg );
    }
  }


  event result_t SendMagCenterBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free( msg );
    return SUCCESS;
  }

  event result_t SendMagCenterCroute.sendDone( EREndpoint dest, uint8_t* data )
  {
    return SUCCESS;
  }

  event result_t SendMagCenterCroute.receive( EREndpoint dest, uint8_t dataLen, uint8_t* data )
  {
    if( dataLen == sizeof(MagLeaderReport_t) )
      sendBroadcast( *(MagLeaderReport_t*)data );
    return SUCCESS;
  }


  event TOS_MsgPtr AlwaysInject.receive( TOS_MsgPtr msg )
  {
    if( msg->length == sizeof(MagLeaderReport_t) )
      call MagCenterReport.send( *(MagLeaderReport_t*)(msg->data) );
    return msg;
  }
  
  event TOS_MsgPtr ClosestInject.receive( TOS_MsgPtr msg )
  {
    if( (call MagPositionValid.get() == TRUE)
        && (msg->length == sizeof(MagLeaderReport_t) )
      )
    {
      MagLeaderReport_t* report = (MagLeaderReport_t*)(msg->data);
      MagPosition_t pos = call MagPositionAttr.get();
      int16_t dx = pos.x - report->x_sum / report->mag_sum;
      int16_t dy = pos.y - report->y_sum / report->mag_sum;
      int16_t d = G_Config.MagCenterClosestInjectDiameter;
      if( (0 <= dx) && (dx < d) && (0 <= dy) && (dy < d) )
	call MagCenterReport.send( *report );
    }

    return msg;
  }


  command void MagCenterReport.send( MagLeaderReport_t report )
  {
    switch( G_Config.MagCenterSendMode )
    {
      case SEND_MAG_CENTER_BROADCAST:
	sendBroadcast( report );
	break;

      case SEND_MAG_CENTER_CROUTE:
	call SendMagCenterCroute.send( MA_ALL, sizeof(report), (uint8_t*)(&report) );
	break;

      case SEND_MAG_CENTER_NEVER:
	break;
    }
  }

  event void MagPositionAttr.updated()
  {
  }
}

