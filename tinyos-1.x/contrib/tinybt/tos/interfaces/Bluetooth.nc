/*
  Bluetooth interface.

  Copyright (C) 2002 & 2003 Dennis Haney <davh@diku.dk> and 
  Martin Leopold <leopold@diku.dk>

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

includes btpackets;

/**Bluetooth interface.

   <p>Provides an interface to a number of common Bluetooth commands 
   and required events.</p>

   <p>The overall sematic is that commands (and associated data) are
   "posted", which means that the module takes over the data and feeds
   it to the Bluetooth module. At a later time, the interface user
   will get a postComplete event to be able to regain ownership of the
   data, and any other events that the command may give rise to.</p>

   <p>The order of the events are like this: First the command is
   posted. Sometime after this, a postComplete event will be issued
   (unless posting the command FAILs), and sometimes after this, any
   result from the command will be signalled through an event.</p>

   <p>Packets that are used for commands (ie not received in events)
   must be wellformed, and in general occupy the trailing part of the
   data area (to make room for headers).</p>

   <p>All commands that return result_t have in common that if a FAIL
   is returned no corresponding postComplete event is generated - this
   is important if some form of memory management is done: upon FAIL
   the packet must be freed somewhere else than the event handler of
   postComplete. For all operations returning FAIL, a packet supplied
   as parameter will appear unchanged, expect for postInqDefault and
   init. </p>
*/
interface Bluetooth {

     /* **********************************************************************
      * Basic stuff 
      * *********************************************************************/
  
     /**
      * Initialize Bluetooth interface.
      *
      * <p>This operation will signal ready when done.</p>
      *
      * @return SUCCESS, wait for ready event */
     command result_t init();

     command result_t initPowerOff();

     command result_t powerOn();

     async event gen_pkt* getBuffer();

     /**
      * Poweroff the Bluetooth interface.
      *
      * <p>This command will poweroff the bluetooth interface,
      * requiring it to be reinitialized by a call to init, before use.</p>
      *
      * @return SUCCESS, when the device is powered off.
      */
     command result_t powerOff();

     /**
      * Returns a buffer that was used to post either a command or data (ACL).
      *
      * <p>Note that this doesn't mean data has been sent or that the command was
      * understood, only that it was transmitted to the BT device and the buffer is
      * ready to be reused</p>
      *
      * @param pkt A packet not in use, that can be (re)used by the caller. */
     async event void postComplete(gen_pkt* pkt);

     /**
      * Notify that the Bluetooth module and stack is ready. 
      * 
      * <p>The stack can be used after this event.</p>
      */
     event void ready();

     /**
      * A Bluetooth related error has occured.
      *
      * @param err is the errorcode
      * @param param is any additional information associated with the error */
     async event void error(errcode err, uint16_t param);

     /**
      * Notify of the number of completed packets.
      *
      * <p>This event can be used, to figure out how much room
      * there is for packets on the Bluetooth node.</p>
      *
      * <p>TODO: Better description, Martin?</p>.
      * @param pkt Number of completed packets
      * @return An unused packet */
     event result_t noCompletedPkts(num_comp_pkts_pkt* pkt);

     /**
      * Post a HCI command. 
      *
      * <p>The resulting events are:
      *   <ul><li>postComplete for the buffer</li>
      *       <li>Optionally an "Complete" event for the command</li>
      *   </ul>
      * </p>
      *
      * @param pkt The packet with the HCI command. <code>p->start</code> must point
      *            to the beginning of a well-formed HCI request, including header.
      * @return SUCCESS (for now) */
     command result_t postCmd(gen_pkt* pkt);

     /**
      * Read the local Blutooth address.
      *
      * <p>If successful, will result in a readBDAddrComplete event.</p>
      *
      * @param pkt An empty buffer
      * @return Whether the packet could be accepted/queued or not */
     command result_t postReadBDAddr(gen_pkt* pkt);

     /**
      * Notify of the local Bluetooth address.
      *
      * @param pkt The address of the local Bluetooth device.
      * @return An unused packet. */
     event result_t readBDAddrComplete(read_bd_addr_pkt* pkt);


     /* **********************************************************************
      * Inquiry and page
      * *********************************************************************/

     /**
      * Set the inquiry scan parameters.
      *
      * <p>If successfull, this will result in a writeInqActivityComplete event.</p>
      * 
      * @param pkt A wellformed packet with the parameters for the inquiry scan.
      * @return An unused packet */
     command result_t postWriteInqActivity(write_inq_activity_pkt* pkt);

     /**
      * MARTIN: What does this do?
      * 
      * @param pkt Dunno
      * @return An unused packet. */
     event result_t writeInqActivityComplete(gen_pkt* pkt);

     /**
      * Enable or disable inquiry and page scanning.
      * 
      * <p>This call can be used to enable or disable inquiry scanning.</p>
      *
      * <p>If successful it will trigger a writeScanEnableComplete event.</p>
      * 
      * <p>Example (note this example uses a fictive function <code>buffer_get</code>
      * to allocate a new buffer):<br>
      * <code>
      * gen_pkt * cmd_buffer = buffer_get();<br>
      * rst_send_pkt(cmd_buffer);<br>
      * cmd_buffer->start    = cmd_buffer->end - 1;<br>
      * // Enable Inquiry and Page scan<br>
      * (*(cmd_buffer->start)) = SCAN_INQUIRY | SCAN_PAGE;<br>
      * call Bluetooth.postWriteScanEnable(cmd_buffer);</code></p>
      *
      * @param pkt The scan mode (spec p. 647) must be passed as the last byte in
      *            the buffer.. Scanmode is enabled by setting the following bits.
      *            Use the defines for readability:<br>
      *            0x0 SCAN_DISABLED - no scans<br>
      *            0x1 SCAN_INQUIRY  - inquiry scan enabled<br>
      *            0x2 SCAN_PAGE     - page scan enabled
      * @return Whether the command was accepted/queued or not */
     command result_t postWriteScanEnable(gen_pkt* pkt);
     
     /**
      * Notify of the result of the scan enable command.
      *
      * @param pkt Whether changing the scan parameters succeed or not.
      * @return An unused packet. */
     event result_t writeScanEnableComplete(status_pkt* pkt);

     /**
      * Start an inquiry with default parameters from GAP.
      *
      *  <p>Triggers a inquiryResult if we get any answers. Triggers a
      * inquiryComplete when done.</p>
      *
      * @param pkt An unused packet
      * @return SUCCESS (for now) */
     command result_t postInquiryDefault(gen_pkt* pkt);

     /**
      * Start an inquiry with custom parameters. 
      *
      * <p>The packet must contain all arguments at the end of the buffer to make
      * room for headers. Triggers a inquiryResult if we get any answers. Triggers a
      * inquiryComplete when done.</p>

      * @param pkt A wellformed inquiry packet
      * @return SUCCESS (for now) */
     command result_t postInquiry(inq_req_pkt* pkt);

     /**
      * Cancel a pending inquiry. 
      * 
      * <p>No inquiry complete event will be returned.</p>
      *
      * <p>TODO: Martin, return value?</p>
      * @param pkt An unused buffer.
      * @return inqiryCancelComplete has no return parameters */ 
     command result_t postInquiryCancel(gen_pkt* pkt);

     /** 
      * Notify of a cancelled inquiry.
      *
      * <p>This event will be triggered after issuing a postInquiryCancel
      * command. Note that the status will be != 0 if no inquiries are pending.</p>
      *
      * @param pkt Packet with the status code
      * @return An unused packet */
     event result_t inquiryCancelComplete(status_pkt* pkt);

     /**
      * Signal the result of an inquiry.

      * <p>May be triggered several times per inquiry. Note that the Bluetooth
      * standard specifies that several results can be contained in a single packet,
      * but this code have only been tested with hardware that limits the number of
      * results to one per packet. (TODO: Martin?).</p>
      *
      * @param pkt An inquiry result.
      * @return An unused packet. */
     event result_t inquiryResult(inq_resp_pkt* pkt);

     /**
      * Signal the end of an inquiry. 
      *
      * <p>This is signalled when the Bluetooth device does no longer perform any 
      * quieries.</p> */
     event void inquiryComplete();


     /* **********************************************************************
      * Connections
      * *********************************************************************/

     /**
      * Create an ACL connection.
      *
      * <p>Attempts to create a connection with the specified device. For faster
      * connection time fillout cp with values from inquiry otherwise fill in
      * 0's.</p>
      *
      * <p>Some time after calling this, connComplete will be signalled.</p>
      * 
      * @param pkt A wellformed connection create packet
      * @return Whether the command could be accepted or not */
     command result_t postCreateConn(create_conn_pkt* pkt);

     /**
      * Signals that the remote side is trying to connect.
      *
      * <p>When this event is received, the program should call
      * postAcceptConnReq as quickly as possibly if the connectin 
      * needs to be accepted.</p>
      * 
      * @param pkt A packet with the request from the remote side
      * @return An unused packet */
     event result_t connRequest(conn_request_pkt* pkt);

     /**
      * Post a connection accept reply.
      *
      * <p>Some time after calling this, connComplete will be
      * signalled. Wether the connection was successful or not can be
      * seen from the status in the conn_complete_pkt packet. 0x00
      * means successful connection.</p>
      *
      * @param pkt A wellformed accept package.
      * @return Whether the command could be accepted or not. */
     command result_t postAcceptConnReq(accept_conn_req_pkt* pkt);

     /**
      * Post connection reject reply.
      *
      * <p>Use this to deny a connection request. Once the reject is
      * processed, a failed (ie. status is non-zero) connComplete
      * event will be issued.</p>
      *
      * @param pkt A wellformed reject package.
      * @return Whether the command could be accepted or not. */
     /*     command result_t postRejectConnReq(reject_conn_req_pkt* pkt); */

     /**
      * Signals the reply from the remote side to a postCreateConn or
      * postAccectConnReq.
      * 
      * @param pkt A packet with the response from the remote side
      * @return An unused packet */
     event result_t connComplete(conn_complete_pkt* pkt);

     /**
      * Disconnect a given connection.
      *
      * @param pkt A wellformed packet with hhe handle and a reason (se spec p. 571)
      * @return Wheter the packet could be accepted to be queued or not */
     command result_t postDisconnect(disconnect_pkt* pkt);
     
     /**
      * Notify of a disconnection.
      *
      * @param pkt Information about which connection was disconnected
      * @return An unused packet */
     event result_t disconnComplete(disconn_complete_pkt *pkt);

     /**
      * Read the maximum allowed size for ACL databuffers.
      *
      * <p>Some time after calling this, readBufSize will be signalled.</p>
      *
      * @param pkt An empty buffer
      * @return Whether the command could be accepted or not. */
     command result_t postReadBufSize(gen_pkt* pkt);
     
     /**
      * Notify of the maximum allowed size for ACL databuffers.
      * 
      * param pkt The maximum allowed size for ACL databuffers
      * @return An unused packet */
     event result_t readBufSizeComplete(read_buf_size_pkt* pkt);

     /**
      * Post an ACL packet to be send over the air.
      *
      * <p>Results in a postComplete event which _doesn't_ mean that the data has
      * been sent over the air, but just to the Bluetooth device!</p>
      *
      * @param pkt A wellformed ACL packet. You need to fill in the header
      *            and place data right after the header
      * @return Wheter the packet could be accepted/queued or not */
     command result_t postAcl(hci_acl_data_pkt* pkt);

     /**
      *  Notify of ACL data received over the air.
      *
      *  <p>This event is triggered, when an ACL packet is received from the lower
      *  levels.</p>
      *
      *  @param pkt The data packet received
      *  @return An unused packet */
     event result_t recvAcl(hci_acl_data_pkt* pkt);

     
     /* **********************************************************************
      * Other stuff
      * *********************************************************************/

     /**
      * Request sniff-mode operation.
      *
      * @param pkt Requested sniff mode intervals
      * @return modeChange will inform about the mode, 
      *         selected intervals and errors. */
     command result_t postSniffMode(sniff_mode_pkt* pkt);

     /**
      * Notify of a modeChange.
      *
      * <p>TODO: Martin, is this neccessary?</p>
      * 
      * @param Information about the new/current mode */
     event void modeChange(evt_mode_change_pkt* pkt);

     /**
      * Write link - policy (allow M/S switch, hold/sniff/park mode).
      *
      * <p>Some time after calling this, writeLinkPolicyComplete will be triggered.</p>
      *
      * @param pkt Sets what to allow:<br>
      * 0x0 - Disable all<br>
      * 0x1 - Enable master/slave switch<br>
      * 0x2 - Enable Hold mode<br>
      * 0x4 - Enablse Sniff mode<br>
      * 0x8 - Enable Park mode
      *
      * @return modeChange will inform about the mode, 
      *         selected intervals and errors */
     command result_t postWriteLinkPolicy(write_link_policy_pkt* pkt);

     /**
      * Notify of link policy change.
      * 
      * @param pkt Information about the new/current link policy for 
      *            a specific connection */
     event void writeLinkPolicyComplete(write_link_policy_complete_pkt* pkt);

     /**
      * Set the role (master/slave) for a connection with another device.
      *
      * @param pkt The address of the remote device
      * @return Wheter the packet could be accepted to be queued or not */
     command result_t postSwitchRole(switch_role_pkt* pkt);

     /**
      * Notify of a roleChange.
      *
      * @param pkt Information about the new/current mode */
     event void roleChange(evt_role_change_pkt* pkt);

     /**
      * Change the allowed packet types for SENDING data.
      *
      * @param ptype - Bitstring showing allowed types */
     command result_t postChgConnPType(set_conn_ptype_pkt* pkt);
     /**
      * Notify of a roleChange.
      *
      * <p>Martin: TODO: Do we need this?</p>
      *
      * @param pkt Information about the new/current mode 
      * @return An unused packet */
     event void connPTypeChange(evt_conn_ptype_changed_pkt* pkt);
     // Once again: Do we really need one of those??
     // We just assume that everything works the way it should =]
     // If there's an error in the transmission we either get
     // nothing or some UART HW error event or something...
}
