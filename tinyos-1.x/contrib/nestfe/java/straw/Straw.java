package straw;

import java.io.*;
import java.util.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

import net.tinyos.drain.*;

class Straw implements MessageListener {

  //  Straw.h  //
  private static final short STRAW_TYPE_SHIFT = 10;

  
  private static final short STRAW_NETWORK_INFO = 1;
  private static final short STRAW_TRANSFER_DATA = 6;
  private static final short STRAW_RANDOM_READ = 7;

  private static final short STRAWCMDMSG_LENGTH
    = StrawCmdMsg.DEFAULT_MESSAGE_SIZE;

  private static final short STRAWCMDMSG_HEADER_LENGTH = 2;
  private static final short STRAWCMDMSG_ARG_LENGTH
    = STRAWCMDMSG_LENGTH - STRAWCMDMSG_HEADER_LENGTH;
  private static final short MAX_RANDOM_READ_SEQNO_SIZE
    = STRAWCMDMSG_ARG_LENGTH / 2;


  private static final short STRAW_NETWORK_INFO_REPLY = 1;
  private static final short STRAW_DATA_REPLY = 8;
 
  private static final short STRAWREPLYMSG_LENGTH
    = StrawReplyMsg.DEFAULT_MESSAGE_SIZE;

  private static final short STRAWREPLYMSG_HEADER_LENGTH = 0;
  private static final short STRAWREPLYMSG_ARG_LENGTH
    = STRAWREPLYMSG_LENGTH - STRAWREPLYMSG_HEADER_LENGTH;
  private static final short MAX_DATA_REPLY_DATA_SIZE
    = STRAWREPLYMSG_ARG_LENGTH - 2;


  //  StrawM.nc  // 
  private static final short RADIUS_OF_INTERFERENCE = 3;
  private static short UART_ONLY_DELAY =
    ((STRAWREPLYMSG_LENGTH + 7) * 7 + 157) / 36;
  private static short UART_DELAY = ((STRAWREPLYMSG_LENGTH + 7) * 7 + 85) / 36;
  private static short RADIO_DELAY
    = ((STRAWREPLYMSG_LENGTH + 7) * 7 + 234) / 85;



  private static final short MAX_SEND_TRY = 10;
  private static final short UNCERTAINTY = 1;
  private static final short DIVERGE_HEADER_LENGTH = 2;
  private static final short CONVERGE_HEADER_LENGTH = 6;


  //  Arguments  //
  static final short TOS_BCAST_ADDR = (short)0xffff;

  private int dest;
  short toUART = 0; // You can directly access a mote
                    // (like through testbed)
  private long start;
  private long size;
  private byte[] bffr;
  private int seqSize;
 

  //  Communication  //
  private MoteIF mote;
  private DrainConnector drainCnct; 
  public StrawBcastMsg bcastMsg = new StrawBcastMsg(); // only for Bcast
  public StrawCmdMsg cmdMsg = new StrawCmdMsg(bcastMsg, DIVERGE_HEADER_LENGTH);
  Counter bcastSeqNo = new Counter("Straw_BcastSeqNo.txt"); // only for Bcast
  
  private boolean msgArrvd;
  private int maxRTT;
  private int pktIntrv;
  
  //  For checking missing packets  //
  private boolean rcvdSeqNo[];
  private int lastRcvdSeqNo;
  
  private int msngSeqNoIndex;
  private int rrSeqNo[] = new int[MAX_RANDOM_READ_SEQNO_SIZE];
  int sizeOfRrSeqNo;


  //  For statistics  //
  private long msgSent;
  private long msgRcvd;
  private Date timeOfMoment;
  private long endOfInit;
  private long endOfNi;
  private long endOfTd;
  private long endOfRr;
  private long successRate;
  

  public Straw() {
      this(new MoteIF(PrintStreamMessenger.err));
  }
  public Straw(MoteIF p_moteIF) {
      this(p_moteIF,  new DrainConnector()); 
  }
  public Straw(MoteIF p_moteIF, DrainConnector p_drain) {
      mote = p_moteIF;
      drainCnct = p_drain;
      drainCnct.registerListener(StrawReplyMsg.AM_TYPE, this);
      drainCnct.registerListener(StrawUARTMsg.AM_TYPE, this);
  }

  private int easyWait(int dur) {
    synchronized (this) {
      try {
        wait(dur);
      } catch (InterruptedException e) {
        System.out.println("EXCEPTION: Straw.easyWait");
      }
    }
    return 0;
  }


  private int sendMsg(short type) {
    cmdMsg.set_dest(dest);
    
    switch (type) {
    case STRAW_NETWORK_INFO:
      cmdMsg.set_arg_ni_type(type);
      cmdMsg.set_arg_ni_uartOnlyDelay(UART_ONLY_DELAY);
      cmdMsg.set_arg_ni_uartDelay(UART_DELAY);
      cmdMsg.set_arg_ni_radioDelay(RADIO_DELAY);
      cmdMsg.set_arg_ni_toUART(toUART);
      break;
    case STRAW_TRANSFER_DATA:
      cmdMsg.set_arg_td_type(type);
      cmdMsg.set_arg_td_start(start);
      cmdMsg.set_arg_td_size(size);
      cmdMsg.set_arg_td_toUART(toUART);
      break;
    case STRAW_RANDOM_READ:
      for (int i = 0; i < MAX_RANDOM_READ_SEQNO_SIZE; i++) {
        if (rrSeqNo[i] == 0xffff) {
          cmdMsg.setElement_arg_rr_seqNo(i, STRAW_RANDOM_READ);
	  break;
	}
        cmdMsg.setElement_arg_rr_seqNo(i, rrSeqNo[i] + STRAW_TYPE_SHIFT);
      }
      break;
    default:
      System.out.println("ERROR: Straw.sendMsg");
      break;
    }

    bcastMsg.set_seqno(bcastSeqNo.get());
    bcastSeqNo.incr();
    System.out.print("S");
    try {
      mote.send(TOS_BCAST_ADDR, bcastMsg);
      ++msgSent;
      synchronized(this){
	  try {
	      this.wait(1250);
	  } catch (InterruptedException e) {
	      System.out.println("EXCEPTION: Straw.sendMsg waiting");
	  }
      }
    } catch (IOException e) {
      System.out.println("EXCEPTION: Straw.sendMsg - mote.send failed");
    }
    return 0;
  }

  private boolean sendMsgGetReply(short type) {
    msgArrvd = false;
    sendMsg(type);
    easyWait(maxRTT);
    if (!msgArrvd)
      System.out.println("Node " + dest + " does not respond");
    return msgArrvd;
  }

  private boolean sendMsgGetReplyRlb(short type) {
    int i;
    for (i = 0; i < MAX_SEND_TRY; i++)
      if (sendMsgGetReply(type)) break;
    if (i == MAX_SEND_TRY) {
      System.out.println("[Rlb] Node " + dest + " does not respond");
      return false;
    } else {
      return true;
    }
  }


  public void messageReceived(int src_node, Message msg) {
    ++msgRcvd;
    StrawReplyMsg reply;
    reply = new StrawReplyMsg(msg, CONVERGE_HEADER_LENGTH);
    System.out.print("R");
    
    if (reply.get_arg_cdr_type() == STRAW_NETWORK_INFO_REPLY) {
      if (toUART != 0) {
        maxRTT = UART_ONLY_DELAY * (2 + UNCERTAINTY)
	  + RADIUS_OF_INTERFERENCE * RADIO_DELAY + 10;
	pktIntrv = UART_ONLY_DELAY;
      } else {
        int depth = reply.get_arg_nir_depth();
        maxRTT = (UART_DELAY + depth * RADIO_DELAY) * (2 + UNCERTAINTY)
	  + RADIUS_OF_INTERFERENCE * RADIO_DELAY + 10;
        pktIntrv = depth < RADIUS_OF_INTERFERENCE
	  ? UART_DELAY + depth * RADIO_DELAY
	  : RADIUS_OF_INTERFERENCE * RADIO_DELAY;
      }
	  
    } else if (reply.get_arg_cdr_type() >= STRAW_TYPE_SHIFT) {
      lastRcvdSeqNo = reply.get_arg_dr_seqNo() - STRAW_TYPE_SHIFT;
      int writingSize = (lastRcvdSeqNo + 1) * MAX_DATA_REPLY_DATA_SIZE > size
        ? (int)(size - lastRcvdSeqNo * MAX_DATA_REPLY_DATA_SIZE)
        : MAX_DATA_REPLY_DATA_SIZE;
      for (int i = 0; i < writingSize; i++)
        bffr[lastRcvdSeqNo * MAX_DATA_REPLY_DATA_SIZE + i]
	  = (byte)reply.getElement_arg_dr_data(i);
      rcvdSeqNo[lastRcvdSeqNo] = true;
      
    } else {
      System.out.println("ERROR: Straw.messageReceived - invalid type");
    }
    
    msgArrvd = true;
    synchronized (this) {
      notifyAll();
    }
  }



  public int read(int dest, long start, long size, byte[] bffr) {
    System.out.println("****  Straw  ****");
    if (size == 0) return 0;
    this.dest = dest;
    this.start = start;
    this.size = size;
    this.bffr = bffr;
    seqSize = (int)((size + MAX_DATA_REPLY_DATA_SIZE - 1)
      / MAX_DATA_REPLY_DATA_SIZE);
    maxRTT = (UART_DELAY + 3 * RADIO_DELAY) * (2 + UNCERTAINTY)
      + RADIUS_OF_INTERFERENCE * RADIO_DELAY + 10;
 
    rcvdSeqNo = new boolean[seqSize];
    for (int i = 0; i < seqSize; i++) rcvdSeqNo[i] = false;

    msgSent = 0;
    msgRcvd = 0;

    timeOfMoment = new Date();
    endOfInit = timeOfMoment.getTime();


    //  Get network info  //
    if (!sendMsgGetReplyRlb(STRAW_NETWORK_INFO)) return 1;
    timeOfMoment = new Date();
    endOfNi = timeOfMoment.getTime();
    successRate = msgRcvd;


    //  Ask transfer of data  //
    lastRcvdSeqNo = 0;
    
    if (!sendMsgGetReplyRlb(STRAW_TRANSFER_DATA)) return 2; // only for Bcast
    ////sendMsg(STRAW_TRANSFER_DATA) // only for Drip
    msgArrvd = true;
    while ((lastRcvdSeqNo < seqSize - 1) && msgArrvd) { // !last && !timeout
      msgArrvd = false;
      easyWait((seqSize - lastRcvdSeqNo - 1) * pktIntrv + pktIntrv / 2);
    }
    timeOfMoment = new Date();
    endOfTd = timeOfMoment.getTime();
    successRate = msgRcvd - successRate;


    //  Fill missing holes using random read //
    msngSeqNoIndex = 0;
    rrSeqNo[0] = 0xffff;
    
    ////int rrFailCnt = 0; // only for Drip
    while(hasMore()) {
      if(!sendMsgGetReplyRlb(STRAW_RANDOM_READ)) return 3; // only for Bcast
      ////sendMsg(STRAW_RANDOM_READ); // only for Drip
      int rrSeqNoIndex = 0;
      msgArrvd = true;
      while(!rcvdSeqNo[rrSeqNo[sizeOfRrSeqNo - 1]]
        && msgArrvd) { // !last && !timeout
        msgArrvd = false;
        easyWait((sizeOfRrSeqNo -  rrSeqNoIndex) * pktIntrv + pktIntrv / 2);
	if (msgArrvd)
      	  for (; rrSeqNoIndex < sizeOfRrSeqNo; rrSeqNoIndex++)
	    if (rrSeqNo[rrSeqNoIndex] == lastRcvdSeqNo) {
	      ++rrSeqNoIndex;
	      break;
	    }
	////rrFailCnt = msgArrvd ? 0 : rrFailCnt + 1; // only for Drip
	////if (rrFailCnt >= MAX_SEND_TRY) return 3; // only for Drip
      }
    }
    timeOfMoment = new Date();
    endOfRr = timeOfMoment.getTime();


    System.out.println("");
    System.out.println(getStatString());
    System.out.println(getPerfString());
    return 0;
  }



  private boolean hasMore() {
    
    //  Compact rrSeqNo  //
    sizeOfRrSeqNo = 0;
    for (int i = 0; i < MAX_RANDOM_READ_SEQNO_SIZE; i++) {
      if (rrSeqNo[i] == 0xffff) {
        break;
      } else if (!rcvdSeqNo[rrSeqNo[i]]) {
        rrSeqNo[sizeOfRrSeqNo] = rrSeqNo[i];
        ++sizeOfRrSeqNo;
      }
    }
    
    //  Fill rrSeqNo  //
    while (true) {
      if (sizeOfRrSeqNo == MAX_RANDOM_READ_SEQNO_SIZE) break; // full rrSeqNo
      
      //  Find a new hole  //
      for (; msngSeqNoIndex < seqSize; msngSeqNoIndex++)
        if (!rcvdSeqNo[msngSeqNoIndex]) break;
	
      if (msngSeqNoIndex == seqSize) { // no more new hole
        break;
      } else { // found a new hole
        rrSeqNo[sizeOfRrSeqNo] = msngSeqNoIndex;
        ++msngSeqNoIndex;
	++sizeOfRrSeqNo;
      }
    }

    //  Wrap up and return  //
    if (sizeOfRrSeqNo == 0) { // no missing hole
      return false;
    } else if (sizeOfRrSeqNo < MAX_RANDOM_READ_SEQNO_SIZE) { // Partial rrSeqNo
      rrSeqNo[sizeOfRrSeqNo] = 0xffff;
      return true;
    } else { // full rrSeqNo
      return true;
    }
  }

  private String getStatString() {
    return "msgSent = " + msgSent + ", msgRcvd = " + msgRcvd
      + ", routing successRate = " + ((double)successRate / (double)seqSize)
      + " (" + successRate + " / " + seqSize + ")" + "\n"
      
      + "Ni = " + (endOfNi - endOfInit)
      + ", Td = " + (endOfTd - endOfNi) + ", Rr = " + (endOfRr - endOfTd)
      + ", total = " + (endOfRr - endOfInit) + "\n";
  }
  
  private String getPerfString() {
    double latency = (double)(endOfRr - endOfInit) / 1000;
    double bandwidth = (double)size / latency;
    double chnlCpcty = ((double)seqSize / (double)(endOfTd - endOfNi)) * 1000
      * ((double)successRate / (double)seqSize)
      * StrawReplyMsg.DEFAULT_MESSAGE_SIZE;
    chnlCpcty = 106 * 22;
    return "Bandwidth = " + bandwidth + " (B/s)\n"
      + "Latency = " + latency + " (s)\n"
      + "Channel Utilization = " + (bandwidth * 100 / chnlCpcty) + " (%)\n";
  }


};

