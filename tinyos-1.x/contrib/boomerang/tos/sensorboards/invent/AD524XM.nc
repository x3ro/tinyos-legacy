// $Id: AD524XM.nc,v 1.1.1.1 2007/11/05 19:11:35 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
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
 *
 */

#include "circularQueue.h"
#include "AD524X.h"

/**
 * Implementation of the potentiometer drivers for the AD524X chips.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
module AD524XM
{
  provides {
    interface StdControl;
    interface AD524X;
  }
  uses {
    interface StdControl as LowerControl;
    interface MSP430I2CPacket as I2CPacket;
    interface ResourceCmd as CmdIO;
  }
}

implementation
{
  enum {
    AD524X_RDAC   = 1 << 7,
    AD524X_RS     = 1 << 6,
    AD524X_SD     = 1 << 5,
    AD524X_3_8_SD = 1 << 6, /* the AD5243 and AD5248 use a different bit */
    AD524X_O1     = 1 << 4,
    AD524X_O2     = 1 << 3
  };

  enum {
    IDLE = 0,
    AD524X_START,
    AD524X_STOP,
    AD524X_OUTPUT ,
    AD524X_RPOT,
    AD524X_WPOT,

    IOCMD_NONE = 0,
    IOCMD_READ = 1,
    IOCMD_WRITE = 2,

    QUEUE_SIZE = 4,
  };

  typedef struct {
    uint8_t iocmd;
    uint8_t addr;
    uint8_t length;
    uint8_t data[2];
    uint8_t state;
    bool rdac;
    uint8_t type;
    // total: 8 bytes, nice
  } Packet_t;

  CircularQueue_t queue;
  Packet_t commands[ QUEUE_SIZE ];

  uint8_t device[4];
  int8_t usercount;

  event void CmdIO.granted( uint8_t rh ) {
    uint8_t iocmd = IOCMD_NONE;
    uint8_t addr = 0;
    uint8_t length = 0;
    uint8_t* data = 0;
    int8_t result = -1;  //initialize resource to neither FAIL nor SUCCESS

    atomic {
      if( !cqueue_isEmpty(&queue) ) {
        Packet_t* p = &commands[queue.front];
        iocmd = p->iocmd;
        addr = (p->addr & 0x03) | 0x2C;
        length = p->length;
        data = p->data;
      }
    }

    if( iocmd != IOCMD_NONE ) {

      if( iocmd == IOCMD_READ ) {
        result = call I2CPacket.readPacket( rh, addr, length, data );
      }
      else if( iocmd == IOCMD_WRITE ) {
        result = call I2CPacket.writePacket( rh, addr, length, data );
      }

      // Queue up a resource request for later if the I2C operation failed;
      // that is, if result is exactly FAIL and not -1 nor SUCCESS.
      if( result == FAIL )
        call CmdIO.deferRequest();
    }

    // Release the resource if we're not waiting for a Done event; that is, if
    // result isn't exactly SUCCESS.
    if( result != SUCCESS )
      call CmdIO.release();
  }

  result_t startCommand( bool _iocmd, uint8_t _addr, uint8_t _length, uint16_t _data, uint8_t _newstate, bool _rdac, ad524x_type_t _type ) {
    result_t result;
    atomic {
      if( cqueue_pushBack(&queue) ) {
        Packet_t* p = &commands[queue.back];
        p->iocmd = _iocmd;
        p->addr = _addr;
        p->length = _length;
        p->data[0] = _data & 0xff;
        p->data[1] = (_data >> 8) & 0xff;
        p->state = _newstate;
        p->rdac = _rdac;
        p->type = _type;
        result = SUCCESS;
      }
      else {
        result = FAIL;
      }
    }

    if( result == SUCCESS )
      call CmdIO.deferRequest();

    return result;
  }

  command result_t StdControl.init() {
    atomic {
      usercount = 0;
      cqueue_init( &queue, QUEUE_SIZE );
    }
    return call LowerControl.init();
  }

  command result_t StdControl.start() {
    int8_t _localcount;
    atomic {
      if (usercount <= 0) {
	TOSH_MAKE_AD524X_SD_OUTPUT();
	TOSH_SET_AD524X_SD_PIN();
	usercount = 0;
      }
      _localcount = usercount;
      usercount++;
    }
    if (_localcount == 0)
      return call LowerControl.start();
    else
      return SUCCESS;
  }

  command result_t StdControl.stop() {
    int8_t _localcount;
    atomic {
      usercount--;
      if (usercount <= 0) {
	TOSH_CLR_AD524X_SD_PIN();
	TOSH_MAKE_AD524X_SD_INPUT();
	usercount = 0;
      }
      _localcount = usercount;
    }
    if (_localcount == 0)
      return call LowerControl.stop();
    else
      return SUCCESS;
  }

  command result_t AD524X.start(uint8_t addr, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242) || (_type == TYPE_AD5245)) {
      atomic device[(int)(addr & 0x03)] &= ~AD524X_SD;
      return startCommand(IOCMD_WRITE, addr, 1, device[(int)(addr & 0x03)], AD524X_START, 0, _type);
    }
    else if ((_type == TYPE_AD5243) || (_type == TYPE_AD5248)) {
      atomic device[(int)(addr & 0x03)] &= ~AD524X_3_8_SD;
      return startCommand(IOCMD_WRITE, addr, 1, device[(int)(addr & 0x03)], AD524X_START, 0, _type);
    }
    return FAIL;
  }

  command result_t AD524X.stop(uint8_t addr, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242) || (_type == TYPE_AD5245)) {
      atomic device[(int)(addr & 0x03)] |= AD524X_SD;
      return startCommand(IOCMD_WRITE, addr, 1, device[(int)(addr & 0x03)], AD524X_STOP, 0, _type);
    }
    else if ((_type == TYPE_AD5243) || (_type == TYPE_AD5248)) {
      atomic device[(int)(addr & 0x03)] |= AD524X_3_8_SD;
      return startCommand(IOCMD_WRITE, addr, 1, device[(int)(addr & 0x03)], AD524X_STOP, 0, _type);
    }
    return FAIL;
  }

  command result_t AD524X.setOutput(uint8_t addr, bool output, bool high, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242)) {
      atomic {
	if (!output)
	  if (high)
	    device[(int)(addr & 0x03)] |= AD524X_O1;
	  else
	    device[(int)(addr & 0x03)] &= ~AD524X_O1;
	else
	  if (high)
	    device[(int)(addr & 0x03)] |= AD524X_O2;
	  else
	    device[(int)(addr & 0x03)] &= ~AD524X_O2;
      }
      return startCommand(IOCMD_WRITE, addr, 1, device[(int)addr & 0x03], AD524X_OUTPUT, output, _type);
    }
    return FAIL;
  }

  command bool AD524X.getOutput(uint8_t addr, bool output, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242)) {
      bool _high;
      if (!output)
	atomic _high = (device[(int)(addr & 0x03)] & AD524X_O1) ? TRUE : FALSE;
      else
	atomic _high = (device[(int)(addr & 0x03)] & AD524X_O2) ? TRUE : FALSE;
      return _high;
    }
    return FALSE;
  }
  
  command result_t AD524X.setPot(uint8_t addr, bool _rdac, 
				 uint8_t value, ad524x_type_t _type) {
    uint16_t _temp;
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242)) {
      atomic _temp = (device[(int)addr & 0x03] & ~AD524X_RDAC) | (value << 8);
      if ((_type == TYPE_AD5242) && (_rdac)) {
	_temp |= AD524X_RDAC;
      }
      return startCommand(IOCMD_WRITE, addr, 2, _temp, AD524X_WPOT, _rdac, _type);
    }
    else {
      value = value >> 1; // turn 256-pos value to 128-pos value
      return startCommand(IOCMD_WRITE, addr, 1, value, AD524X_WPOT, 0, _type);
    } 
  }

  command result_t AD524X.getPot(uint8_t addr, bool _rdac, 
				 ad524x_type_t _type) {
    uint8_t _temp;
    if (_type == TYPE_AD5242) {
      atomic _temp = (device[(int)addr & 0x03] & ~AD524X_RDAC);
      return startCommand(IOCMD_WRITE, addr, 1, _temp, AD524X_RPOT, _rdac, _type);
    }
    else {
      return startCommand(IOCMD_READ, addr, 1, 0, AD524X_RPOT, 0, _type);
    }
  }


  bool ioDoneBegin( Packet_t* p, uint8_t* _data ) {
    atomic {
      // abort if the buffer is not ours
      if( cqueue_isEmpty(&queue) || (commands[queue.front].data != _data) )
        return FALSE;
      *p = commands[queue.front];
      cqueue_popFront(&queue);
    }

    call CmdIO.release();
    return TRUE;
  }


  void ioDoneEnd() {
    atomic {
      if( cqueue_isEmpty(&queue) )
        return;
    }
    call CmdIO.deferRequest();
  }


  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    Packet_t p;

    if( ioDoneBegin(&p,_data) ) {
      switch (p.state) {
      case AD524X_RPOT:
        signal AD524X.getPotDone(p.addr, p.rdac, p.data[0], _success, p.type);
        break;
      }
    }

    ioDoneEnd();
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    Packet_t p;

    if( ioDoneBegin(&p,_data) ) {
      switch (p.state) {
      case AD524X_START:
        signal AD524X.startDone(p.addr, _success, p.type);
        break;
      case AD524X_STOP:
        signal AD524X.stopDone(p.addr, _success, p.type);
        break;
      case AD524X_OUTPUT:
        signal AD524X.setOutputDone(p.addr, p.rdac, _success, p.type);
        break;
      case AD524X_WPOT:
        if (_length == 1)
          signal AD524X.setPotDone(p.addr, 0, _success, p.type);
        else
          signal AD524X.setPotDone(p.addr, p.rdac, _success, p.type);
        break;
      case AD524X_RPOT:
        startCommand(IOCMD_READ, p.addr, 1, 0, AD524X_RPOT, p.rdac, p.type);
        break;
      }
    }

    ioDoneEnd();
  }

}

