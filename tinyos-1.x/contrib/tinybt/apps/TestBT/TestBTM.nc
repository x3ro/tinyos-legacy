/*
  Test BT program. Used to test very basic functionality.

  Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* These macros give rise to a number of warnings. */
#define INT_START { bool interruptOn;
#define INT_STOP }  

#define INT_DISABLE interruptOn = call Interrupt.disable();
/* At least for INT_ENABLE it does not matter - it is only called if interrupts are off 
   So, all read accesses to interruptOn are OK. */
#define INT_ENABLE if (interruptOn) call Interrupt.enable();

#include "debug.h"

#define MY_DEBUG
#ifndef MY_DEBUG
#define debug(a)
#else
#define debug(a) call Debug.debug(a)
#endif

/** 
 * Test BT program.
 * 
 * <p>This program initializes the BT program and then performs a
 * query.</p> */

module TestBTM {
  provides {
    interface StdControl;
  }
  uses {
    interface Bluetooth;
    interface Interrupt;
    interface LedDebugI as Debug;
    /* Shouldn't be using the Clock, I know, but hey... */
    interface Clock;
  }
}

implementation {
  /* Buffer handling - taken from AssemblyM.nc component. May want to 
     think about putting this into its own component. */
#define NUM_BUFFERS 6
#define NUM_BUFFERPS (NUM_BUFFERS + 2)
  /** Buffers to store packets in, managed by buffer_put and buffer_get.*/
  static gen_pkt buffers[NUM_BUFFERS];
  /** Pointers to the buffers, managed by buffer_put and buffer_get. */
  static gen_pkt * bufferps[NUM_BUFFERPS];
  

  /* **********************************************************************
   * Buffer memory management
   * *********************************************************************/
  /**
   * Initialize the buffer manager.
   * 
   * <p>Initialize all the buffers to point at something, or NULL.</p> */
  static void buffers_init() {
    int i;
    dbg(DBG_USR2, "buffers_init()\n");
    for (i = 0; i < NUM_BUFFERPS; i++) {
      if (i < NUM_BUFFERS) {
	bufferps[i] = &(buffers[i]);
      } else {
	bufferps[i] = NULL;
      }
    }
  }

  /**
   * Get a buffer.
   *
   * <p>Get a free buffer from the buffer pool.</p>
   * @return A pointer to a free buffer, or NULL if no free was found */
  static gen_pkt * buffer_get() {
    gen_pkt * res;
    int i;
    dbg(DBG_USR2, "buffers_get()\n");
    INT_START
    INT_DISABLE;
    for (i = 0; i < NUM_BUFFERPS; i++) {
      if (bufferps[i] != NULL) {
	res = bufferps[i];
	bufferps[i] = NULL;
	INT_ENABLE;
	return res;
      }
    }
    INT_STOP
    FAIL2(FAIL_BUFFER, FAIL_BUFFER_GET);
    // INT_ENABLE;
    return NULL;
  }

  /**
   * Free a buffer.
   *
   * <p>Free a buffer and put it back into the buffer pool.</p>
   *
   * @return NULL if OK, else buf */
  static gen_pkt * buffer_put(gen_pkt * buf) {
    int i;
    dbg(DBG_USR2, "buffers_put()\n");
    INT_START
    INT_DISABLE;
    for (i = 0; i < NUM_BUFFERPS; i++) {
      if (bufferps[i] == NULL) {
	bufferps[i] = buf;
	INT_ENABLE;
	return NULL;
      } else { /* Checking for "double-freeing" */
	if (bufferps[i] == buf) {
	  FAIL2(FAIL_BUFFER, FAIL_BUFFER_PUTDUPLICATE);
	}
      }
    }
    INT_STOP
    FAIL2(FAIL_BUFFER, FAIL_BUFFER_PUT);
    // INT_ENABLE;
    return buf;
  }


  /** Pointer to our local bdaddr */
  bdaddr_t address;

  /* Clean up this mess */

  /** How many times we have tried to join a network. */
  uint8_t tryJoinCount;

  /** Mostly to keep sure that we are internally consistent. */
  uint8_t numConnections;

  /** Used to determine what query is ongoing. */
  char query;

  /** Used to keep track of the number of clock fire events left in the current query. */
  int clockFireEventsLeft;

  /** Used during a query phase. */
  uint8_t queryResult;

  /* Test */
  /** Used to store incoming connection information in. */
  hci_acl_data_pkt * incomingPkt;

  /** Initialize.  
   *
   * <p>Sets the tryJoinCount, numConnections and queryConnection
   * pointer, clears the incomingConnection and incomingPkt.</p> */
  command result_t StdControl.init() {
    tryJoinCount       = 3;
    numConnections     = 0;
    buffers_init();
    atomic { 
      incomingPkt        = NULL; 
    }
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }

  /** Start inits the Bluetooth layer.
   *
   * <p>Perhaps this should really take place in init? No..</p> */
  command result_t StdControl.start() {
    gen_pkt * p = buffer_get();
    call Bluetooth.init(p);
    return SUCCESS;
  }

  /** Empty stop. */
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /* **********************************************************************
   * Clock handling
   * *********************************************************************/
  async event result_t Clock.fire() {
    dbg(DBG_USR3, "Juhu, Clock fired\n");
    return SUCCESS;
  }

  /* **********************************************************************
   * Bluetooth handling
   * *********************************************************************/

  /**
   * postComplete callback - important for memory handling.
   *
   * <p>The packet returned is reinserted into the queue of free
   * packets.</p> */
  async event void Bluetooth.postComplete(gen_pkt * p) {
    dbg(DBG_USR1, "Bluetooth.postComplete\n");
    buffer_put(p);
  }

  /**
   * Ready callback.
   *
   * <p>The Bluetooth layer issues this event when it is ready to
   * function. We post a command to get the local BD address.</p> */
  event void Bluetooth.ready() {
    dbg(DBG_USR1, "Bluetooth.ready: interface ready\n");
    if (SUCCESS != call Bluetooth.postReadBDAddr(buffer_get())) {
      FAIL();
    }
  }
  
  /**
   * Callback for when the Bluetooth layer have figured out the local
   * Bluetooth address.
   *
   * <p>Enables scanning and inq. able.</p>
   *
   * @param p The address of the bt device
   * @return An unused packet */
  event gen_pkt* Bluetooth.readBDAddrComplete(read_bd_addr_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.readBDAddrComplete signalled\n");
    if (pkt->start->status) {
      FAIL2(FAIL_GENERAL, FAIL_BT_READBDADDR);
    } else {
      memcpy(&address,
	     &pkt->start->bdaddr,
	     sizeof(bdaddr_t));
      dbg(DBG_USR1, "Bluetooth.readBDAddrComplete signalled - address is"
	  " %02x:%02x:%02x:%02x:%02x:%02x\n", 
	  address.b[0], address.b[1], address.b[2], address.b[3], address.b[4], address.b[5]);
      dbg(DBG_USR1, "Bluetooth.readBDAddrComplete signalled - requesting scanEnable\n");
      { /* Enable scan */
	gen_pkt * cmd_buffer = buffer_get();
	rst_send_pkt(cmd_buffer);
	cmd_buffer->start    = cmd_buffer->end - 1;
	/* 3 == inq and scan */
	(*(cmd_buffer->start)) = SCAN_INQUIRY | SCAN_PAGE;
	if (FAIL == (call Bluetooth.postWriteScanEnable(cmd_buffer))){
	  FAIL2(FAIL_POST, FAIL_POST_SCANCHANGE);
	}
      }
    }
    return (gen_pkt*) pkt;
  }
  

  /**
   * Asynchronously start an inquiry. */
  task void start_inquiry() {
    dbg(DBG_USR1, "start_inquiry - call Bluetooth.postInquiryDefault()\n");
    call Bluetooth.postInquiryDefault(buffer_get());
  }

  /**
   * Notify of the result of the scan enable command.
   *
   * @param pkt Whether changing the scan parameters succeed or not.
   * @return An unused packet. */
  event gen_pkt* Bluetooth.writeScanEnableComplete(status_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.writeScanEnableComplete called - post DefaultInq.\n");
    if (NODE_NUM == 1) {
      post start_inquiry();
    }
    return (gen_pkt *) pkt;
  }


  /**
   * Signal the result of an inquiry.
   
   * <p>May be triggered several times per inquiry. Note that the Bluetooth
   * standard specifies that several results can be contained in a single packet,
   * but this code have only been tested with hardware that limits the number of
   * results to one per packet. (TODO: Martin?).</p>
   *
   * <p>Posts a connection create command</p>
   *
   * @param pkt An inquiry result.
   * @return An unused packet. 
   
   TODO: It seems blueware calls here with a response packet of 0, instead
   of the inquiryComplete
   TODO: We want responses as they happen... or maybe not. */
  event gen_pkt* Bluetooth.inquiryResult(inq_resp_pkt* p) {
    char buf[128];
    printTime(buf, 128);
    dbg(DBG_USR1, "Bluetooth.inquiryResult called at %s\n", buf);
    dbg(DBG_USR1, "Bluetooth.inquiryResult: numresp = %d\n", p->start->numresp);
    assert(p->start->numresp >= 1);
    dbg(DBG_USR1, "Bluetooth.inquiryResult: resp: "
	"bdaddr = %02x:%02x:%02x:%02x:%02x:%02x, \n", 
	p->start->infos->bdaddr.b[0], 
	p->start->infos->bdaddr.b[1], 
	p->start->infos->bdaddr.b[2], 
	p->start->infos->bdaddr.b[3], 
	p->start->infos->bdaddr.b[4], 
	p->start->infos->bdaddr.b[5]);
    dbg(DBG_USR1, "Bluetooth.inquiryResult: resp: pscan_rep_mode = %hhu\n", 
	p->start->infos->pscan_rep_mode);
    dbg(DBG_USR1, "Bluetooth.inquiryResult: resp: pscan_mode = %hhu\n", 
	p->start->infos->pscan_mode);
    dbg(DBG_USR1, "Bluetooth.inquiryResult: resp: clock_offset = %d\n", 
	p->start->infos->clock_offset);
    {
      create_conn_pkt * conn_create = (create_conn_pkt *) buffer_get();
      conn_create->cp.pkt_type = HCI_DM1 | HCI_DH1;
    
      // conn_create->cp.pkt_type = 0x0008 | 0x0010;
      memcpy(&(conn_create->cp.bdaddr),
	     &(p->start->infos->bdaddr),
	     sizeof(bdaddr_t));
      
      // The child interface always wants to be the slave... 
      // check 4.5.5 in the HCI spec // Master(0x0)/slave(0x1) switch
      conn_create->cp.role_switch    = 0x01;
      conn_create->cp.pscan_rep_mode = p->start->infos->pscan_rep_mode;
      conn_create->cp.pscan_mode     = p->start->infos->pscan_mode;
      conn_create->cp.clock_offset   = p->start->infos->clock_offset;
    
      rst_send_pkt((gen_pkt *) conn_create);
      conn_create->start              = &conn_create->cp;
      
      if (FAIL != call Bluetooth.postCreateConn(conn_create)) {
	dbg(DBG_USR1, "Succesfully posted a CreateConn packet\n");
      } else {
	dbg(DBG_USR1, "Error posting a CreateConn packet\n");
	assert(0);
      }
    }
    return (gen_pkt*) p;
  }

  /** 
   * Called when the inquiry is complete.
   * 
   * <p>What to do depends on wheter or not we got inq. results. TODO:
   * Something meaningful.</p> */
  event void Bluetooth.inquiryComplete() {
    dbg(DBG_USR1, "Bluetooth.inquiryComplete called-TODO: Something meaningful\n");
    return;
  }


  /* **********************************************************************
   * Unused callback. I still do not understand why we need these - I can not 
   * make default events work...
   * *********************************************************************/
  async event void Bluetooth.error(errcode err, uint16_t param) {
    dbg(DBG_USR1, "Bluetooth.error called, err=%i, param=%i\n", err, param);
    assert(0);
  }
  event gen_pkt* Bluetooth.disconnComplete(disconn_complete_pkt *pkt) {
    dbg(DBG_USR1, "Bluetooth.disconnComplete called - unimplemented\n");
    assert(0);
    return (gen_pkt *) pkt;
  }
  event void Bluetooth.writeLinkPolicyComplete(write_link_policy_complete_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.writeLinkPolicyComplete called - unimplemented\n");
    assert(0);
  }
  async event gen_pkt* Bluetooth.recvAcl(hci_acl_data_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.recvAcl called - unimplemented\n");
    assert(0);
    return (gen_pkt *) pkt;
  }
  event gen_pkt* Bluetooth.connComplete(conn_complete_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.connComplete called - unimplemented\n");
    assert(0);
    return (gen_pkt *) pkt;
  }
  event gen_pkt* Bluetooth.connRequest(conn_request_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.connRequest called - unimplemented\n");
    assert(0);
    return (gen_pkt *) pkt;
  }
  event gen_pkt* Bluetooth.noCompletedPkts(num_comp_pkts_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.noCompletedPkts called - unimplemented\n");
    assert(0);
    return (gen_pkt *) pkt;
  }


  /** Default/dummy/unused event handler */
  event gen_pkt* Bluetooth.readBufSizeComplete(read_buf_size_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.readBufSizeComplete called - unimplemented\n");
    assert(0);
    return (gen_pkt *) pkt;
  }
  /** Default/dummy/unused event handler */
  event void Bluetooth.modeChange(evt_mode_change_pkt* p) {
    dbg(DBG_USR1, "Bluetooth.modeChange called - unimplemented\n");
    assert(0);
  }
  /** Default/dummy/unused event handler */
  event void Bluetooth.roleChange(evt_role_change_pkt * pkt) {
    dbg(DBG_USR1, "Bluetooth.roleChange called - unimplemented\n");
    assert(0);
  }
  /** Default/dummy/unused event handler */
  event gen_pkt * Bluetooth.writeInqActivityComplete(gen_pkt * p) {
    dbg(DBG_USR1, "Bluetooth.writeInqActivityComplete called - unimplemented\n");
    assert(0);
    return (gen_pkt*) p;
  }
  /** Default/dummy/unused event handler */
  event gen_pkt* Bluetooth.inquiryCancelComplete(status_pkt* pkt) {
    dbg(DBG_USR1, "Bluetooth.inquiryCancelComplete called - unimplemented\n");
    assert(0);
    return (gen_pkt*) pkt;
  }
  /** Default/dummy/unused event handler */
  event void Bluetooth.connPTypeChange(evt_conn_ptype_changed_pkt* p) {
    dbg(DBG_USR1, "Bluetooth.connPTypeChange called - unimplemented\n");
    assert(0);
  }

}



