/*
    BTBech - measures throughput and other charactaristics of the 
    BT interface
    Copyright (C) 2003 Martin Leopold <leopold@diku.dk>

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

includes hci;
includes bluetooth;
includes btpackets;
includes TosTime;

// Remember to define array of buffers
// Unsyncronized!! This can break in numerous ways if two try it simultaniously
//
// Make sure that you don't exeed the the ammount of available memory. Check
// .data and .bss segments of your executable with avr-objdump. To enable
// external memory on the BTNodes define EXTERNAL_MEM below.

#undef EXTERNAL_MEM
#define NO_BUFFERS 2
#define DLEN MAX_DLEN

// Send PACKET packets before meassuring bandwidth
#define PACKETS 500 

// Packet types for master/slave
//HCI_DH5 | HCI_DM5 | HCI_DH3 | HCI_DM3 | HCI_DH1 | HCI_DM1
// 0x8000 |  0x4000 |  0x0800 |  0x0400 |  0x0010 |  0x0008

#define PTYPEM 0x0008
#define PTYPES 0x0008

//#define MASTER_SEND
//#define SLAVE_SEND
#undef WITH_LEDS

// Max number of slaves
#define noSlaves 3
// Last slave to connect to.. (max = noSlaves-1, we count from 0)
#define connSlaves 1


/**
 * BTBench program - benchmark various Bluetooth operations */
module BTBenchM { 
  provides {
    interface StdControl;
  }
  uses {
    interface Bluetooth;
    interface StdOut;
    interface IntOutput;
    interface Clock;
  }
}

implementation {
  bdaddr_t mylocalAddr;
  bdaddr_t martinMote;
  uint8_t flag, err_code, robinHood;
  uint16_t count2, err_parm, dlen;
  uint32_t count;
  uint32_t ticks, start_ticks, duration_ticks, uart_duration_ticks,
       uart_start, uart_count;

  gen_pkt *free_pkts[NO_BUFFERS];
  gen_pkt real_pkts[NO_BUFFERS];

  inq_resp_pkt        *inq_buffer;
  conn_complete_pkt   *conn_buffer;
  conn_request_pkt    *conn_req;
  hci_acl_data_pkt    *recv_buffer;

  typedef struct {
       uint16_t handle;
       uint32_t packets; // uint16_t might be enough...
  } __attribute__ ((packed)) sent_packets_t;
  
  /* Throughput meassuring stuff */
  uint8_t connected, foundRemote;
  sent_packets_t sent_packets[connSlaves];
  sent_packets_t sent_packets_copy[connSlaves];
  bdaddr_t slaves[noSlaves];
  inquiry_info remote_parms[connSlaves];

  hci_command_hdr *hdrp;

  write_inq_activity_pkt* inq;

  //evt_mode_change mode_change_parms;
     

 /***************************************************************************
  *                             Prototypes                                  *
  ***************************************************************************/

  void panic(uint8_t err);
  result_t send_pkt(uint8_t handle);
  uint32_t ticks_to_s (uint32_t t);
  uint32_t ticks_to_ms (uint32_t t);
  task void set_link_ptype_tsk();
  task void link_policy_tsk();
  task void mode_change_tsk();
  task void throughput(); 
  task void sniff_mode_tsk();
  task void accept_conn_tsk();
  task void connector_tsk();
  task void sender_receiver();
  task void sender_receiver2();
  task void skod();
  task void inq_start_tsk();
  task void inq_complete_tsk();
  task void inq_res_tsk(); 
  task void set_discoverable_tsk();
  task void set_not_discoverable_tsk();
  task void idle_tsk();
  task void set_inq_interval();
  gen_pkt* free_buf(gen_pkt *free_ar[], gen_pkt* keep);

 /***************************************************************************
  *                               Gemüse                                    *
  ***************************************************************************/

  async event result_t Clock.fire() {
       ticks++;
       return SUCCESS;
  }

  task void print_err() {
       switch(err_code){
       case EVENT_PKT_TOO_LONG:
       case ACL_PKT_TOO_LONG:
            call StdOut.print("ACL packet too long: ");
            call StdOut.printHexword(err_parm);
            call StdOut.print("\n\r");
            panic(3);
            break;
       case UNKNOWN_PTYPE:
            call StdOut.print("Unknown ptype ");
            call StdOut.printHexword(err_parm);
            call StdOut.print("\n\r");
            break;
       case UNKNOWN_EVENT:
/*            if (err_parm != 0x00FF) {
                 call StdOut.print("Unknown eventcode (");
                 call StdOut.printHexword(err_parm);
                 call StdOut.print(")\n\r");
                 }*/
            break;
       case UART_UNABLE_TO_HANDLE_EVENTS:
            call StdOut.print("U");//nable to handle events (");
            call StdOut.printHexword(err_parm);
            call StdOut.print(")\n\r");
            break;
       case HW_ERROR:
            switch(err_parm) {
            case 0x20: 
                 call StdOut.print("HW error: UART transport synchronisation error\n\r");
                 break;
            case 0x21: 
                 call StdOut.print("HW error: Flash CRC error\n\r");
                 break;
            case 0x23: 
                 call StdOut.print("HW error: RX buffer full\n\r");
                 break;
            case 0x24: 
                 call StdOut.print("HW error: RX buffer is full\n\r");
                 break;
            default: 
                 call StdOut.print("HW error: RX (tx?) buffer is empty\n\r");
                 break;
            }
            break;
       default:
            call StdOut.print("ERR! ");
            call StdOut.printHex(err_code);
            call StdOut.print(" ");
            call StdOut.printHexword(err_parm);
            call StdOut.print("\n\r");
            break;
       }
  }

  async event void Bluetooth.error(errcode e, uint16_t parm) {
       err_code = e;
       err_parm = parm;
       post print_err();
       return;
  }

  task void idle_tsk() {
       long j;
       for (j=0 ; j<=135600 ; j++) {//app 10 ms at 7 Mhz
            asm volatile ("nop"::);
       }
       call StdOut.print("Idle");
       post idle_tsk();
  }

  async event result_t StdOut.get(uint8_t data) {
    dbg(DBG_USR1, "Got %i - putting it\n", data);
    return SUCCESS;
  }
       
  async event void Bluetooth.postComplete(gen_pkt* pkt) {
       //call StdOut.print("pC\n\r");

       if (flag){
            uart_count += pkt->end - pkt->start;
            uart_duration_ticks += ticks - uart_start;
            post throughput();
       }
       free_buf(free_pkts, pkt);
  }

  event result_t IntOutput.outputComplete(result_t succes) {
    return SUCCESS;
  }
  
   void panic(uint8_t err) {
       long j;
       uint8_t led=15;
       // 0 means all lit, 15 all off
       while(1) {
            call IntOutput.output(led);
            for (j=0 ; j<=1356648 ; j++) {//app 1 s at 7 Mhz
                 asm volatile ("nop"::);
            }
            led = led==15 ? 15-err : 15;
       }
  }

  
  // Inspired by getMs and getSeconds
  uint32_t tos_time_to_ms (tos_time_t *ttime) {
       uint16_t t, temp;
       uint32_t ms, s;

       /* The ms - part of the lower bits */
       // Deviding by 1024 - not good
       //ms = (ttime.low32+0x200) >>10; //+0x200 => at least 1 ms
       ms = ttime->low32 / 1000;

       /* the s part of the high order bits */
       // Deviding by 2^20 = 1 048 576 - hey!!
       //temp = (uint16_t)(ttime.high32 & 0x000F) <<12 | ttime.low32 >>20
       s = (uint32_t) ((ttime->high32 / 1000) * (1<<32 / 1000)) +
            ms;

       return ms;
  }

  // Give the s - part of a ticks value
  uint32_t ticks_to_s (uint32_t t) {
       return t>>10;
  }

  // There's 1024=2^10 tics to a second
  uint32_t ticks_to_ms (uint32_t t) {
       return (uint32_t) ((double) t * 1000/1024);
  }

  // Stores the buffer in the array of free buffers
  // Returns the buffer on success or 0 for failure
  gen_pkt* free_buf(gen_pkt *free_ar[], gen_pkt* keep) {
       gen_pkt **ar;
       ar = free_ar;

       while(ar < free_ar + NO_BUFFERS) {
            if(!(*ar)) {
                 *ar = keep;
                 return keep;
            }
            ar++;
       }
       return((gen_pkt*) NULL);
  }

  // Finds a free buffer in the buffer array and returns a pointer or 0 
  // if none exists
  gen_pkt* get_buf(gen_pkt *free_ar[]) {
       gen_pkt *res;
       gen_pkt **ar = free_ar;

       while(ar < free_ar + NO_BUFFERS) {
            if(*ar) {
                 res = *ar;
                 *ar = (gen_pkt*) NULL;
                 return res;
            }
            ar++;
       }
       //panic(2);
       return((gen_pkt*) NULL);
  }

  /***************************************************************************
   *                          Startup and bootstrap                          *
   ***************************************************************************/

  command result_t StdControl.init() {
       result_t res;
       uint8_t i;
       gen_pkt *buf;

       connected=0;
       flag = 0;
       ticks = 0;

       //recv_bytes = 0;
       //sent_bytes = 0;


       // From avr128_init.c, l. 46 (smart-its)
       // enable and initialize external memory interfce
       // enable the external memory interface
       //
       // This is only reqired if you use large buffers (i.e. set
       // HCIPACKET_BUF_SIZE or BUFFERS large)
#ifdef EXTERNAL_MEM
#warning File polluted with assembly
       sbi( MCUCR, SRE ); 
#endif

       // no wait states configured: our SRAM is fast enough  
       // no wait-state sectors: have a single SRAM chip
       // no external memory bus keeper (what is it good for anyway?)
       // no external memory high mask: we need the complete address space

       // Initialize the array of free buffers and reset the buffers
       for(i=0 ; i < NO_BUFFERS; i++) {
            rst_pkt(&(real_pkts[i]));
            free_pkts[i] = &(real_pkts[i]);
       }
       count2=0;
       uart_count=0;
       robinHood = 0;

       inq_buffer = (inq_resp_pkt*) 0;

       // Initialize other modules
       res = call StdOut.init();
       buf = get_buf(free_pkts);

       TOSH_CLR_EXTRA_LED_PIN();
       call IntOutput.output(7); // all off

       if (buf){
	 call StdOut.print("Ini\n\r");
	 res = res && call Bluetooth.init(buf);
       } else {
            res = FAIL; 
       }
       if (res != SUCCESS) { 
            panic(1);
            call StdOut.print("Init failed\n\r");            
       }
       /*
       martinMote.b[0] = 0xBD;
       martinMote.b[1] = 0x4E;
       martinMote.b[2] = 0x17;
       martinMote.b[3] = 0x37;
       martinMote.b[4] = 0x80;
       martinMote.b[5] = 0x00;

       slaves[0].b[0] = 0xBE;
       slaves[0].b[1] = 0x4E;
       slaves[0].b[2] = 0x17;
       slaves[0].b[3] = 0x37;
       slaves[0].b[4] = 0x80;
       slaves[0].b[5] = 0x00;

       slaves[1].b[0] = 0xBF;
       slaves[1].b[1] = 0x4E;
       slaves[1].b[2] = 0x17;
       slaves[1].b[3] = 0x37;
       slaves[1].b[4] = 0x80;
       slaves[1].b[5] = 0x00;

       slaves[2].b[0] = 0xBC;
       slaves[2].b[1] = 0x4E;
       slaves[2].b[2] = 0x17;
       slaves[2].b[3] = 0x37;
       slaves[2].b[4] = 0x80;
       slaves[2].b[5] = 0x00;
*/
       return res;
  }

  event void Bluetooth.ready() {
       gen_pkt *buf;
       call StdOut.print("ready\n\r");

       buf = get_buf(free_pkts);
       if (buf==NULL)  panic(2);

       call Bluetooth.postReadBufSize(buf);

       //post set_inq_interval();
       //post ttime();
       //post inq_start_tsk();
  }

  command result_t StdControl.start() {
#ifdef WITH_LEDS
       call IntOutput.output(0); // All on
#endif
       
       // 1000 clock.fire() events/s
       //call Clock.setIntervalAndScale(0,TOS_S1000PS);

       // 1024 clock.fire() events/s
       call Clock.setIntervalAndScale(TOS_I1024PS, TOS_S1024PS);

       return SUCCESS;
  }

  command result_t StdControl.stop() {
       return SUCCESS;
  }

  event gen_pkt* Bluetooth.readBufSizeComplete(read_buf_size_pkt* pkt) {
       call StdOut.print("ACL mtu: ");
       call StdOut.printHexword(pkt->start->acl_mtu);
       call StdOut.print(", sco mtu: ");
       call StdOut.printHexword(pkt->start->sco_mtu);
       call StdOut.print(", ACL no bufs: ");
       call StdOut.printHexword(pkt->start->acl_max_pkt);
       call StdOut.print(", SCO no bufs: ");
       call StdOut.printHexword(pkt->start->sco_max_pkt);
       call StdOut.print("\n\r");

       post sender_receiver();
       return (gen_pkt*) pkt;

  }

  /***************************************************************************
   *                          Am I suppose to connect?                       *
   ***************************************************************************/

  task void sender_receiver() {
       gen_pkt *buf = get_buf(free_pkts);
       if (buf==NULL)  panic(2);

       call Bluetooth.postReadBDAddr(buf);
  }

  event gen_pkt* Bluetooth.readBDAddrComplete(read_bd_addr_pkt* pkt) {
       memcpy(&mylocalAddr,
              &pkt->start->bdaddr.b,
              sizeof(bdaddr_t)
            );
       post sender_receiver2();
       return ((gen_pkt*) pkt);
  }

  task void sender_receiver2() {
       call StdOut.print("BD_ADDR: 0x");
       call StdOut.dumpHex((uint8_t*) 
                           &mylocalAddr, sizeof(bdaddr_t)," 0x");
       call StdOut.print("\n\r");

       // The connector node connects to the others
       if (0 == memcmp(&martinMote.b,
                       &mylocalAddr,
                       sizeof(bdaddr_t))) {
            post inq_start_tsk();
       } else {
            post set_discoverable_tsk();
       }
       //post set_inq_interval();
  }

  /***************************************************************************
   *                          Inquiry handling                               *
   ***************************************************************************/

  task void inq_start_tsk() {
       gen_pkt *tmp = get_buf(free_pkts);
       if (tmp==NULL) panic(3);

       call StdOut.print("Inq default\n\r");
       foundRemote=0;
       call Bluetooth.postInquiryDefault(tmp);
  }

  task void set_discoverable_tsk(){
       gen_pkt *tmp=get_buf(free_pkts);
       if (tmp==NULL) panic(2);

       rst_send_pkt(tmp);
       tmp->start = tmp->start - 1;
       *tmp->start = 0x03;

       call StdOut.print("Write scan enble\r\n");
       if (! (call Bluetooth.postWriteScanEnable(tmp))){
            call StdOut.print("Elvis has left the building!\n\r");
       }
  }

  event gen_pkt* Bluetooth.writeInqActivityComplete(gen_pkt* pkt) {
       post set_discoverable_tsk();
       return (gen_pkt*) pkt;
  }

  event gen_pkt* Bluetooth.inquiryResult(inq_resp_pkt *resp) {
       gen_pkt *buf=get_buf(free_pkts);
       if (buf==NULL) panic(3);

       inq_buffer=resp;

       post inq_res_tsk();

       return(buf);
  }

  task void inq_res_tsk() {
       uint8_t j;
       gen_pkt *tmp;

       call StdOut.print("Res 0x");
       call StdOut.dumpHex((uint8_t*) 
                           &inq_buffer->start->infos[0].bdaddr, 6," 0x");

       // Copy inq parms
       for (j=0 ; j < connSlaves ; j++) {
            if (0 == memcmp(&slaves[j].b,
                            &inq_buffer->start->infos[0].bdaddr.b,
                            sizeof(bdaddr_t))) {
                 foundRemote++;
                 memcpy(&remote_parms[j],
                        inq_buffer->start->infos,
                        sizeof(inquiry_info)
                      );
                 call StdOut.print(" - that's a node!");
                 break;
            }
       }
       // Waste of time - reuse the buffer =]
       free_buf(free_pkts, (gen_pkt*) inq_buffer);
       call StdOut.print("\n\r");

       // We have everyBody - let's not waste any more time
       if (foundRemote == connSlaves) {
            tmp = get_buf(free_pkts);
            if (tmp==NULL) panic(2);
            call Bluetooth.postInquiryCancel(tmp);
       }
  }

  // The connecting 
  event void Bluetooth.inquiryComplete() {
       call StdOut.print("Inqiry complete, found: ");
       call StdOut.printHex(foundRemote);
       call StdOut.print("\n\r");
       if (foundRemote << connSlaves)
            post inq_start_tsk();
   }

  event gen_pkt* Bluetooth.writeScanEnableComplete(status_pkt* pkt) {
       // Slaves need to have their packet type set
/*
       if (connected)
            post set_link_ptype_tsk();
*/
       return (gen_pkt*) pkt;
  }

  task void set_inq_interval () {
       inq = (write_inq_activity_pkt*) get_buf(free_pkts);
       if (inq==NULL) panic(2);

       rst_send_pkt((gen_pkt*) inq); // Reset ->end

       inq->cp.interval = 2048;
       inq->cp.window = 18;
       inq->start = inq->end-sizeof(write_inq_activity_cp);

       call StdOut.print("Write inq activity\r\n");
       if (! (call Bluetooth.postWriteInqActivity(inq))){
            call StdOut.print("Elvis has left the building!\n\r");
       }
  }

  task void inq_complete_tsk() {
       call StdOut.print("Inq complete\n\r");
  }

  // We cancel the inquiry when we've found everyone...
  event gen_pkt* Bluetooth.inquiryCancelComplete(status_pkt* p){
       post connector_tsk();
       return (gen_pkt*) p;
  }

  /***************************************************************************
   *                          Connection setup                               *
   ***************************************************************************/

  // One of the nodes is dedicate to become master - connect to everybody
  // connected counts how far we've gotten (actually it's the index+1 but
  // this task is posted _before_ the connection is made
  task void connector_tsk() {
       create_conn_pkt *conn_create = (create_conn_pkt *) get_buf(free_pkts);
       if (conn_create==NULL) panic(2);

       rst_send_pkt((gen_pkt*) conn_create);

       memcpy(&(conn_create->cp.bdaddr),
              &remote_parms[connected].bdaddr,
              sizeof(bdaddr_t));
                        
       conn_create->cp.pkt_type = 0x8; // Packet type: DM1
       conn_create->cp.role_switch = 0x01; //Role switch capable
       conn_create->cp.pscan_rep_mode = remote_parms[connected].pscan_rep_mode;
       conn_create->cp.pscan_mode = remote_parms[connected].pscan_mode;
       conn_create->cp.clock_offset = remote_parms[connected].clock_offset;
       conn_create->start = &conn_create->cp;

       call StdOut.print("Connecting dlen: ");
       call StdOut.printHexword(DLEN);
       call StdOut.print(" ptype ");
       call StdOut.printHexword(PTYPEM);
       call StdOut.print(" ");
       call StdOut.printHex(conn_create->cp.bdaddr.b[0]);
       call StdOut.print("\n\r");

       if(!call Bluetooth.postCreateConn(conn_create))
            panic(4);
  }

  event gen_pkt* Bluetooth.disconnComplete(disconn_complete_pkt* pkt){
       return ((gen_pkt*) pkt);
  }

  event gen_pkt* Bluetooth.connRequest(conn_request_pkt* pkt) { 
       gen_pkt *tmp;

       conn_req = pkt;
       post accept_conn_tsk();

       tmp = get_buf(free_pkts);
       if (tmp==NULL) panic(2);

       return (gen_pkt*) tmp;
  }
  
  task void accept_conn_tsk() {
       accept_conn_req_pkt *accept_conn;
       accept_conn = (accept_conn_req_pkt*) get_buf(free_pkts);
       if (accept_conn==NULL) panic(2);

       rst_send_pkt((gen_pkt*) accept_conn);
       accept_conn->start = &(accept_conn->cp);
       
       memcpy(&accept_conn->cp.bdaddr,
              &conn_req->start->bdaddr,
              sizeof(bdaddr_t));
       free_buf(free_pkts, (gen_pkt*) conn_req);

       accept_conn->cp.role = 0x1; // Master/slave switch

       call StdOut.print("Conn req accepted\n\r");
       if (!call Bluetooth.postAcceptConnReq(accept_conn))
            panic(4);
  }
    
  // Both master and slave end up here...
  event gen_pkt* Bluetooth.connComplete(conn_complete_pkt* pkt) {
       if (pkt->start->status == 0){ // Conn OK!
            sent_packets[connected].handle = pkt->start->handle;
            connected++;

            if(foundRemote && connected < connSlaves) {
                 // Still more slaves to go
                 post connector_tsk();
            } else if(foundRemote && connected == connSlaves) { 
                 // All slaves found - party ON!
                 call StdOut.print("All done.. Let's go!\n\r");
#ifdef MASTER_SEND
                 for(i=0 ; i < connSlaves ; i++) {
                      sent_packets[i].packets = 0;
                 }
                 count=0;
                 start_ticks = ticks;
                 post throughput();
#endif
                 //Sniff-mode stuff
                 //post link_policy_tsk();
            } else { // Doesn't really matter but let's turn scans of anyway
                 // Master sets ptype with connection -
                 //set the ptype for the slave
#ifdef WITH_LEDS
                 call IntOutput.output(5);
#endif
                 post set_link_ptype_tsk();
                 //post link_policy_tsk();
                 //post set_not_discoverable_tsk();
            }
       } else {
            call StdOut.print("CONN failed ");
            call StdOut.printHex(pkt->start->status);
            call StdOut.print("\n\r");
            post inq_start_tsk();
       }
       return (gen_pkt*) pkt;
  }

  // There's no need to set the ptype on the master - so this is the slave
  task void set_link_ptype_tsk() {
       set_conn_ptype_pkt *pkt =
            (set_conn_ptype_pkt*) get_buf(free_pkts);
       rst_send_pkt((gen_pkt*) pkt);
       pkt->start = &pkt->cp;

       call StdOut.print("Set link ptype ");
       call StdOut.printHexword(PTYPES);
       call StdOut.print("\n\r");

       pkt->start->handle = sent_packets[0].handle;//conn_handle[0];
       pkt->start->pkt_type = PTYPES;

       if (FAIL == call Bluetooth.postChgConnPType(pkt))
            panic(4);
  }

  // Slave
  event void Bluetooth.connPTypeChange(evt_conn_ptype_changed_pkt* pkt){
       if (pkt->start->status)
            panic(5);
#ifdef SLAVE_SEND
       if (!foundRemote) {
            start_ticks = ticks;
            post throughput();
       }
#endif
  }

  // Both master and slave can end up here
  // FIXME: Master only set's policy for the first connection
    task void link_policy_tsk(){
    }
//         write_link_policy_pkt *pkt = 
//              (write_link_policy_pkt*) get_buf(free_pkts);
//         if (pkt==NULL) panic(2);
       
//         call StdOut.print("Write link policy\n\r");

//         rst_send_pkt((gen_pkt*) pkt);
//         pkt->start = &pkt->cp;
       
//         pkt->start->handle = sent_packets[0].handle;//conn_handle[0];
//         pkt->start->policy = 0xF;

//         call Bluetooth.postWriteLinkPolicy(pkt);
//    }

  event void Bluetooth.writeLinkPolicyComplete(write_link_policy_complete_pkt*
                                               pkt) {
       if(foundRemote) {
            post sniff_mode_tsk();
       } else {// Slave
            //post set_not_discoverable_tsk();
       }
       return;
  }

    task void sniff_mode_tsk() {
    }
//         sniff_mode_pkt *pkt = (sniff_mode_pkt*) get_buf(free_pkts);
//         if (pkt==NULL) panic(2);

//         call StdOut.print("Let's try that sniffmode ");
//         call StdOut.printHexword(sent_packets[0].handle);//conn_handle[0]);
//         call StdOut.print("\n\r");
       
//         rst_send_pkt((gen_pkt*) pkt);
//         pkt->start = &pkt->cp;

//         pkt->start->handle = sent_packets[0].handle;//conn_handle[0];
//         pkt->start->max_interval = 0xFFFF;
//         pkt->start->min_interval= 0xFFFF;
//         pkt->start->attempt = 5;
//         pkt->start->timeout = 5;
       
//         call Bluetooth.postSniffMode(pkt);
//    }
 
  event void Bluetooth.modeChange(evt_mode_change_pkt* p) {
    //       memcpy(&mode_change_parms,
    //              p->start,
    //           sizeof(evt_mode_change));
    //   post mode_change_tsk();
       return;
  }

  // Master
  //task void mode_change_tsk(){
  //}
//         if (mode_change_parms.status != 0) {
//  /*
//              call StdOut.print("A mode change error occurred: ");
//              call StdOut.printHex(mode_change_parms.status);
//              call StdOut.print("\n\r");
//  */
//              panic(4);
//         } else {
//              call StdOut.print("Mode change OK, mode: ");
//              call StdOut.printHex(mode_change_parms.cur_mode);
//              call StdOut.print(", interval: ");
//              call StdOut.printHexword(mode_change_parms.interval);
//  #ifdef MASTER_SEND
//              for(i=0 ; i < connSlaves ; i++) {
//                   sent_packets[i].packets = 0;
//              }
            
//              count=0;
//              start_ticks = ticks;
//              post throughput();
//  #endif
//              call StdOut.print("\n\r");
//         }
//    }

    task void set_not_discoverable_tsk(){
    }
//         gen_pkt *tmp=get_buf(free_pkts);
//         if (tmp==NULL)  panic(2);

//         rst_send_pkt(tmp);
//         tmp->start = tmp->start - 1;
//         *tmp->start = 0x0;
//         call StdOut.print("Write scan disable\r\n");
//         call Bluetooth.postWriteScanEnable(tmp);
//    }

  event void Bluetooth.roleChange(evt_role_change_pkt* p){
       return;
  }

  /***************************************************************************
   *                          Data transmission                              *
   ***************************************************************************/

  task void throughput_printer() {
    uint8_t i;
    call StdOut.print("Sent ");
    call StdOut.printHexlong((uint32_t) PACKETS*DLEN);
    call StdOut.print(" B in ");
    call StdOut.printHexlong(ticks_to_ms(duration_ticks));
    call StdOut.print(" ms uart ");
    call StdOut.printHexlong(uart_count);
    call StdOut.print(" in ");
    call StdOut.printHexlong(ticks_to_ms(uart_duration_ticks));
    call StdOut.print(" ms");
    for(i=0 ; i < connSlaves ; i++){
      call StdOut.print(" ");
      call StdOut.printHexlong(sent_packets_copy[i].packets*DLEN);
    }
    call StdOut.print("\n\r");
  }

  event gen_pkt* Bluetooth.noCompletedPkts(num_comp_pkts_pkt* pkt){
       uint8_t noHndl, i, j;
       uint16_t pkts, hndl, *wordarr;
       noHndl = ((num_comp_pkts_pkt*) pkt)->start->num_hndl;
       wordarr = (uint16_t*) (((uint8_t*) (pkt->start))+1);
       //call StdOut.print("noComp\n\r");

/*         post throughput();
       return (gen_pkt*) pkt;
*/
       // The esr device doesn't use the chance to reduce events by sending
       // more than one handle in each noComp - sigh. This doesn't make
       // event processing any faster
       for (i=0; i<noHndl ; i++) {
            hndl = wordarr[0];//wordarr[(i<<1)];
            pkts = wordarr[1];//wordarr[(i<<1) + 1];
            count += pkts;
            for(j=0 ; j < connSlaves ; j++) {
                 if (sent_packets[j].handle == hndl) {
                      sent_packets[j].packets += pkts;
                 }
                 //if (sent_packets[j].handle == wordarr[1])
                 //     sent_packets[j].packets += wordarr[(i<<1) + 1];
            }
       }

       //uint16_t *hest;
       // Assume a single connection handle
       //hest = (uint16_t*) (((uint8_t*) (pkt->start))+1);
       //count += hest[1];
       //count2 += hest[1];

       // I wonder if this takes too loong
#ifdef WITH_LEDS
       if (count%100 == 0)
              call IntOutput.output(count % 7);
#endif

         // 1000 sent packets with payload DLEN
         if (count >= PACKETS) {
              // I'm starting to grow a serious dislike to this:
              // copying arrays was NOT what I had in mind!
              memcpy(sent_packets_copy,
                     sent_packets,
                     connSlaves*sizeof(sent_packets_t));
              for(j=0 ; j < connSlaves ; j++)
                   sent_packets[j].packets = 0;
              count=0;
              duration_ticks = ticks-start_ticks;
              start_ticks = ticks;
              post throughput_printer();
         }

         post throughput();
	 
       return (gen_pkt*) pkt;
  }

  task void throughput() {
       //call StdOut.print("Through ");
       if (send_pkt(robinHood) == SUCCESS) {
            //call StdOut.print("a\n\r");
            // Let's do round robin on the connections
            robinHood = (++robinHood) % connSlaves;
            flag++; // Make postComplete post throughput again
       } else {
            //call StdOut.print("b\n\r");
            //call StdOut.printHex(flag);
            //call StdOut.print(" Gnooorf!\n\r");
            flag = 0; // Otherwise wait for noCompletedPkts
       }
  }

  result_t send_pkt(uint8_t handle) {
       hci_acl_data_pkt *acl_buffer;
       result_t res;

       // Since postComplete hands buffers back there should be
       // plenty of buffers even though we have filled up the buffer on
       // the BT device
       acl_buffer = (hci_acl_data_pkt*) get_buf(free_pkts);
       if (acl_buffer==NULL) panic(6);

       rst_send_pkt((gen_pkt*) acl_buffer);
              acl_buffer->start = (hci_acl_hdr*) (acl_buffer->end - DLEN);

       // Let's put something in the packets
/*
       t = 1;
       while (acl_buffer->end-t >= (uint8_t*) acl_buffer->start) {
            *(acl_buffer->end-t) = t;
            t--;
       }
*/
       acl_buffer->start = (hci_acl_hdr*)( 
            ((uint8_t*) acl_buffer->start) - 
            sizeof(hci_acl_hdr));

       acl_buffer->start->handle = sent_packets[handle].handle & 0x0fff;
       //conn_handle[handle] & 0x0fff;
       // 1 continuation, 2 first packet
       acl_buffer->start->pb = 2; 
       acl_buffer->start->bc = 0;
       acl_buffer->start->dlen = DLEN;

       //call StdOut.print("Ready to send, hndl: ");
       //call StdOut.printHexword(acl_buffer->start->handle);
       //call StdOut.print("\n\r");
       uart_start = ticks;
       res = call Bluetooth.postAcl(acl_buffer);
       if (res==FAIL) free_buf(free_pkts, (gen_pkt*) acl_buffer);
       return res;
  }

  task void throughput_recv_tsk() {
         call StdOut.print("Recv ");
  //       call StdOut.printHexlong(recv_bytes2);
         call StdOut.print(" bytes in ");
         call StdOut.printHexlong(ticks_to_ms(duration_ticks));
         call StdOut.print(" ");
         //call StdOut.printHexword(recv_buffer->end-
         //                         (uint8_t*) recv_buffer->start);
         call StdOut.printHexword(count);
         call StdOut.print("\n\r");

       // Let's see if we got what we expected
       //for (t=1 ; t<recv_buffer->start->dlen ; t--) 
       //     if (*(recv_buffer->end-t) != t) panic(6);
  }

  async event gen_pkt* Bluetooth.recvAcl(hci_acl_data_pkt* pkt) {
       count++;
#ifdef WITH_LEDS
       if (count%10 == 0)
            call IntOutput.output(count % 7);
#endif
/*

       count++;

       duration_ticks = ticks - start_ticks;

       recv_bytes += pkt->start->dlen;
       if (recv_bytes >= 200000) {
            recv_bytes2=recv_bytes;
            recv_bytes=0x0;
            post throughput_recv_tsk();
            start_ticks = ticks;
       }
       
       //recv_buffer=pkt;
       //tmp = get_buf(free_pkts);
       //if (tmp==NULL) panic(4);
       //return tmp;
*/
       return (gen_pkt*) pkt;
  }

}
