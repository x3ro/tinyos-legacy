//Mohammad Rahimi
includes IB;
module SamplerTestM
{
  provides interface StdControl;
  uses {
    interface Leds;

    //Sampler Communication
    interface StdControl as SamplerControl;
    interface Sample;

    //RF communication
    interface StdControl as CommControl;
    interface SendMsg as SendMsg;
    interface ReceiveMsg as ReceiveMsg;

    //Timer
      interface Timer as TxManager;
  }
}
implementation
{

    enum {
        PENDING = 0,
        NO_MSG = 1
    };
    

    TOS_Msg msg1,msg2,msg3;		/* Message to be sent out */
    char msg1_status,msg2_status,msg3_status;

    command result_t StdControl.init() {
        call Leds.init();
        //call SensorControl.init();
        msg1.data[0] = TOS_LOCAL_ADDRESS; //record your id in the packet.
        msg2.data[0] = TOS_LOCAL_ADDRESS; //record your id in the packet.
        msg3.data[0] = TOS_LOCAL_ADDRESS; //record your id in the packet.
        msg1_status=NO_MSG;
        msg2_status=NO_MSG;
        msg3_status=NO_MSG;
        //        call TxManager.start(TIMER_REPEAT, 500);
        return rcombine(call SamplerControl.init(), call CommControl.init());
        return SUCCESS;
    }
    
    command result_t StdControl.start() {
        call SamplerControl.start();
        call CommControl.start();
        //start sampling three channels as examples
        call Sample.sample(0,ANALOG,1);
        //call Sample.sample(1,ANALOG,1);
        //call Sample.sample(2,ANALOG,1);
        //call Sample.sample(3,ANALOG,1);
        //call Sample.sample(4,ANALOG,1);
        //call Sample.sample(5,ANALOG,1);
        //call Sample.sample(6,ANALOG,1);
        //call Sample.sample(7,ANALOG,1);
        //call Sample.sample(8,ANALOG,1);
        //call Sample.sample(9,ANALOG,1);
        //call Sample.sample(10,ANALOG,1);
        //call Sample.sample(0,TEMPERATURE,1);
        //call Sample.sample(0,HUMIDITY,1);
        //call Sample.sample(0, BATTERY,1);
        //call Sample.sample(0,DIGITAL,1);
        //call Sample.sample(1,DIGITAL,1);
        //call Sample.sample(2,DIGITAL,1);
        //call Sample.sample(3,DIGITAL,1);
        //call Sample.sample(4,DIGITAL,1);
        //call Sample.sample(5,DIGITAL,1);
        //call Sample.sample(0, COUNTER,1);
        
     return SUCCESS;
    }

    command result_t StdControl.stop() {
        //call Sample.sample(2,ANALOG,0);
        //call Sample.sample(6,BATTERY,0);
        //call Sample.sample(2,DIGITAL,0);
        call SamplerControl.stop();
    return SUCCESS;
    }


  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
      if (&msg1 == sent) { msg1_status=NO_MSG; return SUCCESS; }
      if (&msg2 == sent) { msg2_status=NO_MSG; return SUCCESS; }
      if (&msg3 == sent) { msg3_status=NO_MSG; return SUCCESS; }
      else return FAIL;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr data) {
    return data;
  }


  event result_t Sample.dataReady(uint8_t channel,uint8_t channelType,uint16_t data)
      {
          //call Leds.redToggle();
      if(channelType==ANALOG) {
      msg1.data[0]=0x11;
      msg1.data[1]=0x11;
      msg1.data[2]=0x11;
      switch (channel) {
      case 0:
      msg1.data[3]=data & 0xff;
      msg1.data[4]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      break;
      case 1:
      msg1.data[5]=data & 0xff;
      msg1.data[6]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      break;
      case 2:
      msg1.data[7]=data & 0xff;
      msg1.data[8]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      break;
      case 3:
      msg1.data[9]=data & 0xff;
      msg1.data[10]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      break;
      case 4:
      msg1.data[11]=data & 0xff;
      msg1.data[12]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      break;
      case 5:
      msg1.data[13]=data & 0xff;
      msg1.data[14]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      break;
      case 6:
      msg1.data[15]=data & 0xff;
      msg1.data[16]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      break;
      case 7:
      msg1.data[17]=data & 0xff;
      msg1.data[18]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      return SUCCESS;
      break;
      case 8:
      msg1.data[19]=data & 0xff;
      msg1.data[20]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      return SUCCESS;
      break;
      case 9:
      msg1.data[21]=data & 0xff;
      msg1.data[22]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      return SUCCESS;
      break;
      case 10:
      msg1.data[23]=data & 0xff;
      msg1.data[24]=(data >> 8) & 0xff;
      msg1_status=PENDING;
      call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); 
      return SUCCESS;
      break;
      default:
      break;
      }
      }
          
      
      if(channelType== BATTERY) {
          msg2.data[0]=0x22;
          msg2.data[1]=0x22;
          msg2.data[2]=0x22;
          msg2.data[3]=data & 0xff;
          msg2.data[4]=(data >> 8) & 0xff;
          msg2_status=PENDING;
          call SendMsg.send(TOS_BCAST_ADDR, 29, &msg2); return SUCCESS;
      }

      if(channelType== HUMIDITY) {
          msg2.data[0]=0x77;
          msg2.data[1]=0x77;
          msg2.data[2]=0x77;
          msg2.data[3]=data & 0xff;
          msg2.data[4]=(data >> 8) & 0xff;
          msg2_status=PENDING;
          call SendMsg.send(TOS_BCAST_ADDR, 29, &msg2); return SUCCESS;
      }


      if(channelType== TEMPERATURE) {
          msg2.data[0]=0x55;
          msg2.data[1]=0x55;
          msg2.data[2]=0x55;
          msg2.data[3]=data & 0xff;
          msg2.data[4]=(data >> 8) & 0xff;
          msg2_status=PENDING;
          call SendMsg.send(TOS_BCAST_ADDR, 29, &msg2); return SUCCESS;
      }

      if(channelType== COUNTER) {
          msg2.data[0]=0x88;
          msg2.data[1]=0x88;
          msg2.data[2]=0x88;
          msg2.data[3]=data & 0xff;
          msg2.data[4]=(data >> 8) & 0xff;
          msg2_status=PENDING;
          call SendMsg.send(TOS_BCAST_ADDR, 29, &msg2); return SUCCESS;
      }
      

      
      if(channelType==DIGITAL) {
          msg3.data[0]=0x33;
          msg3.data[1]=0x33;
          msg3.data[2]=0x33;          
          switch (channel) {
          case 0:
              msg3.data[3]=data & 0xff;
              msg3.data[4]=(data >> 8) & 0xff;
              msg3_status=PENDING;
              call SendMsg.send(TOS_BCAST_ADDR, 29, &msg3); 
              break;
          case 1:
              msg3.data[5]=data & 0xff;
              msg3.data[6]=(data >> 8) & 0xff;
              msg3_status=PENDING;
              call SendMsg.send(TOS_BCAST_ADDR, 29, &msg3); 
              break;
          case 2:
              msg3.data[7]=data & 0xff;
              msg3.data[8]=(data >> 8) & 0xff;
              msg3_status=PENDING;
              call SendMsg.send(TOS_BCAST_ADDR, 29, &msg3); 
              break;
          case 3:
              msg3.data[9]=data & 0xff;
              msg3.data[10]=(data >> 8) & 0xff;
              msg3_status=PENDING;
              call SendMsg.send(TOS_BCAST_ADDR, 29, &msg3); 
              break;
          case 4:
              msg3.data[11]=data & 0xff;
              msg3.data[12]=(data >> 8) & 0xff;
              msg3_status=PENDING;
              call SendMsg.send(TOS_BCAST_ADDR, 29, &msg3); 
              break;
          case 5:
              msg3.data[13]=data & 0xff;
              msg3.data[14]=(data >> 8) & 0xff;
              msg3_status=PENDING;
              call SendMsg.send(TOS_BCAST_ADDR, 29, &msg3); 
              break;
          default:
              break;
          }
      }
      
      return SUCCESS;
  }

  event result_t TxManager.fired() {
      if(msg1_status==PENDING)  { call SendMsg.send(TOS_BCAST_ADDR, 29, &msg1); return SUCCESS;}
      if(msg2_status==PENDING)  { call SendMsg.send(TOS_BCAST_ADDR, 29, &msg2); return SUCCESS;}
      if(msg3_status==PENDING)  { call SendMsg.send(TOS_BCAST_ADDR, 29, &msg3); return SUCCESS;}
      return SUCCESS;
      }
  
}
