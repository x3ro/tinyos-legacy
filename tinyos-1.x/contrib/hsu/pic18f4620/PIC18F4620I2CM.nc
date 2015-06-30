// $Id: PIC18F4620I2CM.nc,v 1.2 2005/06/01 14:27:46 hjkoerber Exp $

/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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

/*
 * @author Joe Polastre
 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * $Date: 2005/06/01 14:27:46 $
 * $Revision: 1.2 $
 * 
 * Primitives for accessing the hardware I2C module on PIC18F4620 microcontrollers.
 * This module assumes that the bus is available and reserved prior to the
 * commands in this module being invoked. Most applications will use the
 * readPacket and writePacket interfaces as they provide the master-mode
 * read and write operations from/to a slave device.  At current just I2C master
 * mode is implemented for the PIC18F4620.
 */

includes pic18f4620mssp;

module PIC18F4620I2CM
{
  provides {
    interface StdControl;
    interface PIC18F4620I2C;
    interface I2CPacket;
  }
  uses {
    interface HPLMSSPControl as MSSPControl;
    interface HPLI2CInterrupt;
  }
}
implementation
{


  // init() command causes nesC to complain about a race condition
  // other variables protected by only being modified when the stateI2C
  // variable allows modification (ie stateI2C != IDLE)

  norace uint8_t stateI2C;
  norace uint8_t packetStateI2C;
  uint8_t addr;
  uint8_t length;
  uint8_t ptr;
  norace result_t result;
  uint8_t *data;
  pic18f4620_msspmode_t mssp_mode;

 /* state of the i2c request  */
  enum {
        OFF=1,
        IDLE=2,
	I2C_PACKET_WRITE=3,
	I2C_PACKET_READ=4,
	I2C_SEND_ADDRESS=5,
        I2C_SEND_DATA=6,
        I2C_RECEIVE_ENABLE=7,
	I2C_INITIATE_STOP_CONDITION=8,
	I2C_STOP_CONDITION_COMPLETE=9,
	I2C_GET_DATA,
	I2C_SEND_ACK,
  };

  task void readDone() {
    // variables protected from change by the stateI2C state machine
    result_t _result;
    uint8_t _length;
    uint8_t* _data;
    uint16_t _addr;

    _result = result;
    _length = length;
    _data = data;
    _addr = addr;

    signal I2CPacket.readPacketDone(_addr, _length, _data, _result);
  }

  task void writeDone() {
    // variables protected from change by the stateI2C state machine
    result_t _result;
    uint8_t _length;
    uint8_t* _data;
    uint16_t _addr;

    _result = result;
    _length = length;
    _data = data;
    _addr = addr;

    signal I2CPacket.writePacketDone(_addr, _length, _data, _result);
  }

  command result_t StdControl.init() {
    // init does not apply to "non-atomic access to shared variable"
    stateI2C = OFF; 
    packetStateI2C= OFF;
    result = FAIL;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    uint8_t _state = 0;
    
    atomic {
      _state = stateI2C;
      if (_state == OFF){                               
	stateI2C = IDLE;                                 // inititate I2C state machine
	packetStateI2C = IDLE;
      }
    }

    if (_state == OFF) {
      mssp_mode = call MSSPControl.getMode();            // test if MSSP is in I2C mode, else configure MSSP for I2C mode
      if (mssp_mode != MSSP_I2C){
	call MSSPControl.setModeI2C();
      }
      return SUCCESS;
    }
    else if (_state == IDLE)
      return SUCCESS;

    return FAIL;
  }

  command result_t StdControl.stop() {
    atomic {
      stateI2C = OFF;
      call PIC18F4620I2C.disable();
    }
    call MSSPControl.setMode(mssp_mode);
    return SUCCESS;
  }

  async command result_t PIC18F4620I2C.enable() {
    result_t _res = FAIL;
    atomic {
      if (call MSSPControl.isI2C()) {
	_res = SUCCESS;
      }
      else {
	call MSSPControl.setModeI2C();
	_res = SUCCESS;
     }
    }
    return _res;
  }

  async command result_t PIC18F4620I2C.disable() {
    result_t _res = FAIL;
    atomic {
      if (call MSSPControl.isI2C()) {
	SSPCON1bits_SSPEN = 0x0;                     // Disables serial port and configures these pins as I/O port pins
	_res = SUCCESS;
      }
    }
    return _res;
  }

 async command result_t PIC18F4620I2C.setModeMaster() {
    bool _res = FAIL;
    atomic {
      if (call MSSPControl.isI2C()) {
	SSPCON1bits_SSPM3 = 0x1;		     //i2c master mode, 7-bit addr,clock = FOSC/(4 * (SSPADD + 1))
	SSPCON1bits_SSPM2 = 0x0;	        
	SSPCON1bits_SSPM1 = 0x0;
	SSPCON1bits_SSPM0 = 0x0;  
	_res = SUCCESS;
      }
    }
    return _res;
  }
 
// only valid in master mode
 async command result_t PIC18F4620I2C.setRx() {      // sets the receive enable bit
   atomic SSPCON2bits_RCEN = 0x1;
   return SUCCESS;
 } 

 // only valid in master mode                       
 async command result_t PIC18F4620I2C.setTx() {
    atomic SSPCON2bits_RCEN = 0x0;                   // master is per default in transmit mode, so we have to do nothing
    return SUCCESS;                                 
  }


 void I2C_sendStart(){                               // generate start condition
   atomic {
     SSPCON2bits_SEN = 0x1;
     stateI2C = I2C_SEND_ADDRESS; 
   }
   return;
 }

 result_t I2C_setData(uint8_t value) {               // writes address or data into the SSPBUF register
    bool _res = FAIL;

    if (call MSSPControl.isI2C()) {
      if(stateI2C == I2C_SEND_ADDRESS && packetStateI2C == I2C_PACKET_WRITE ){
	SSPBUF_register = (value << 1) & 0xfe;       // if address with r/w-bit cleared should be sent then shift value left add write bit (0) and write into SSPBUF
	stateI2C= I2C_SEND_DATA;
      }
      else if(stateI2C == I2C_SEND_ADDRESS && packetStateI2C == I2C_PACKET_READ ){
	SSPBUF_register = (value << 1) | 0x01;       // if address with r/w-bit set should be sent then shift value left add read bit (1) and write into SSPBUF
	stateI2C= I2C_RECEIVE_ENABLE;
      } 
      else if(stateI2C == I2C_SEND_DATA){
	SSPBUF_register =  value;                    // if data is to be send write value directly into SSPBUF
      }
    }
    _res = SUCCESS;
     return _res;
 }

 void I2C_receiveEnable(){                           // set receive enable bit
   SSPCON2bits_RCEN = 0x1; 
   atomic{
     stateI2C = I2C_SEND_ACK; 
   }
   return;
 }


 void I2C_getData(uint8_t *_data) {                  // reads data from the SSPBUF register a
    if (call MSSPControl.isI2C()) {
      *_data = SSPBUF_register;
   }
 }


 void I2C_sendEnd(){                                 // generate stop condition
   atomic { 
 
     SSPCON2bits_PEN = 0x1;
     stateI2C = I2C_STOP_CONDITION_COMPLETE;
   }
   return;
 }
 

  command result_t I2CPacket.readPacket(uint16_t _addr, uint8_t _length, uint8_t *_data) {
    uint8_t _state;

    atomic {
      _state = packetStateI2C;
      if (_state == IDLE) {
	packetStateI2C = I2C_PACKET_READ;	
      }
    }
    if (_state == IDLE) {
      atomic {	
	addr = (uint8_t) _addr;
	length = _length;
	data = _data;
	ptr = 0;
      }
      I2C_sendStart(); // initiate start condition
      return SUCCESS;
    }
    return FAIL;
  }
 

  // handle the interrupt within this component
  void localRxData() {

    switch(stateI2C){                                  // this is the I2C state machine for sending some data 
    case I2C_SEND_ADDRESS:
      I2C_setData(addr);
      break;
     case I2C_RECEIVE_ENABLE:
      I2C_receiveEnable();
      break;
    
    case I2C_SEND_ACK:
      I2C_getData(data+ptr);
      ptr++;
      if (ptr == length) {
	SSPCON2bits_ACKDT=1;                                // send no acknowledge
	stateI2C = I2C_INITIATE_STOP_CONDITION; 
      }
      else {
	SSPCON2bits_ACKDT=0;                                // send acknowledge
 	stateI2C= I2C_RECEIVE_ENABLE;                   // get ready for reveiving  the next data
      }
	SSPCON2bits_ACKEN=1;
     break;
    case I2C_INITIATE_STOP_CONDITION:
      I2C_sendEnd();  
      stateI2C = I2C_STOP_CONDITION_COMPLETE;
      break;
    case I2C_STOP_CONDITION_COMPLETE:
      stateI2C= IDLE;
      packetStateI2C = IDLE;
      result = SUCCESS;
      post readDone();
      break;

    default:
      break;
    }
    return;

  }

  

  command result_t I2CPacket.writePacket(uint16_t _addr, uint8_t _length, uint8_t* _data) {
    uint8_t _state;
    atomic {      
      _state = packetStateI2C;
      if (_state == IDLE) {
	packetStateI2C = I2C_PACKET_WRITE;
      }
    }     
      if (_state == IDLE) {
	atomic{
	  addr = (uint8_t) _addr;	
	  length = _length;
	  data = _data;
	  ptr = 0;
	}
	I2C_sendStart();                           // initiate start condition
	return SUCCESS;    
      }
    return FAIL;
}

  
  // handle the interrupt within this component
  void localTxData() {
    if (packetStateI2C != I2C_PACKET_WRITE)
      return;
   
    switch(stateI2C){                               // this is the I2C state machine for sending some data 
    case I2C_SEND_ADDRESS:
      I2C_setData(addr);
      break;
    case I2C_SEND_DATA:
      I2C_setData(*(data+ptr));
      ptr++;

      if (ptr == length) {
	stateI2C = I2C_INITIATE_STOP_CONDITION; 
      }
      break;
    case I2C_INITIATE_STOP_CONDITION:
      I2C_sendEnd();  
      break;
    case I2C_STOP_CONDITION_COMPLETE:
      stateI2C= IDLE;
      packetStateI2C = IDLE;
      result =SUCCESS;
      post writeDone();
      break;

    default:
      break;
    }
    return;
  }


  async event void HPLI2CInterrupt.fired() {
    switch (packetStateI2C) {
    case I2C_PACKET_WRITE:
      localTxData();
      break;
    case I2C_PACKET_READ:
      localRxData();
      break;
    default:
      break;
    }
    return;
 }

  default event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { }
  default event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { }

}
