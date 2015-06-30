module DebugRangingSensorM
{
  provides 
  {
    interface StdControl;
    interface AcousticRangingSensor;
  }
  uses
  {
    interface ReceiveMsg;
    interface Leds;
  }
}

implementation
{

  command result_t StdControl.init()
  {
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
  
  int16_t getDistance(uint16_t id) {
    switch(TOS_LOCAL_ADDRESS) {

    case 1:
      if(id == 2)
	return 60;
      else if(id == 3)
	return 84;
      else if(id == 4)
	return 60;
      else if(id == 5)
	return 42;
      else
	return -1;
      
    case 2:
      if(id == 1)
	return 60;
      else if(id == 3)
	return 60;
      else if(id == 4)
	return 84;
      else if(id == 5)
	return 42;
      else
	return -1;
      
    case 3:
      if(id == 1)
	return 84;
      else if(id == 2)
	return 60;
      else if(id == 4)
	return 60;
      else if(id == 5)
	return 42;
      else
	return -1;

    case 4:
      if(id == 1)
	return 60;
      if(id == 3)
	return 60;
      else if(id == 2)
	return 84;
      else if(id == 5)
	return 42;
      else
	return -1;
      
    case 5:
      if(id == 1)
	return 42;
      else if(id == 3)
	return 42;
      else if(id == 4)
	return 42;
      else if(id == 2)
	return 42;
      else
	return -1;
      
/*      case 1: */
/*        if(id == 2) */
/*  	return 60; */
/*        else if(id == 3) */
/*  	return 84; */
/*        else if(id == 4) */
/*  	return 60; */
/*        else if(id == 5) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */

/*      case 2: */
/*        if(id == 1) */
/*  	return 60; */
/*        else if(id == 3) */
/*  	return 60; */
/*        else if(id == 6) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */

/*      case 3: */
/*        if(id == 2) */
/*  	return 60; */
/*        else if(id == 4) */
/*  	return 60; */
/*        else if(id == 7) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */

/*      case 4: */
/*        if(id == 1) */
/*  	return 60; */
/*        else if(id == 3) */
/*  	return 60; */
/*        else if(id == 8) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */

/*      case 5: */
/*        if(id == 1) */
/*  	return 28; */
/*        else if(id == 6) */
/*  	return 20; */
/*        else if(id == 8) */
/*  	return 20; */
/*        else if(id == 7) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */

/*      case 6: */
/*        if(id == 2) */
/*  	return 28; */
/*        else if(id == 5) */
/*  	return 20; */
/*        else if(id == 7) */
/*  	return 20; */
/*        else if(id == 8) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */

/*      case 7: */
/*        if(id == 3) */
/*  	return 28; */
/*        else if(id == 6) */
/*  	return 20; */
/*        else if(id == 8) */
/*  	return 20; */
/*        else if(id == 5) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */

/*      case 8: */
/*        if(id == 4) */
/*  	return 28; */
/*        else if(id == 5) */
/*  	return 20; */
/*        else if(id == 7) */
/*  	return 20; */
/*        else if(id == 6) */
/*  	return 28; */
/*        else */
/*  	return -1; */
/*        break; */
      
    default:
      break;
    }
    return 0;
  }
  
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p) {
    AcousticBeaconMsg *msg = (AcousticBeaconMsg*)&p->data;
    int16_t distance;
    
    signal AcousticRangingSensor.receive(msg->nodeId);
    distance = getDistance(msg->nodeId);
    signal AcousticRangingSensor.receiveDone(msg->nodeId,distance);
    return p;
  }


}
