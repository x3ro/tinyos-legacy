package net.tinyos.pingpong;

import java.io.*;
import java.util.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

class PingPong implements MessageListener {

  private MoteIF mote = new MoteIF(PrintStreamMessenger.err); {
    mote.registerListener(new PpReplyMsg(), this);
  }
  private PpCmdMsg cmdMsg = new PpCmdMsg();
  private boolean msgArrvd;
  private int maxRTT = 500;

  private int dest;
  private int type;



  private int easyWait(int dur) {
    synchronized (this) {
      try {
        wait(dur);
      } catch (InterruptedException e) {
        System.out.println("EXCEPTION: PingPong.easyWait");
      }
    }
    return 0;
  }

  private int sendMsg() {
    cmdMsg.set_cmd(type);
    try {
      mote.send(dest, cmdMsg);
    } catch (IOException e) {
      System.out.println("EXCEPTION: PingPong.sendMsg");
    }
    return 0;
  } 

  private boolean sendMsgGetReply() {
    msgArrvd = false;
    sendMsg();
    easyWait(maxRTT);
    return msgArrvd;
  }



  public int ping(int dest, int type) {
    this.dest = dest;
    this.type = type;
    
    sendMsgGetReply();
    String resultReport = "node " + dest + " ";
    if (msgArrvd) {
      resultReport += "reply ";
    } else {
      resultReport += "doesn't respond ";
    }
    
    switch (type) {
      case PpConsts.PP_IMMEDIATE:
        resultReport += "IMMEDIATE";
        break;
      case PpConsts.PP_TASK:
        resultReport += "TASK";
        break;
      default:
        break;
    }

    System.out.println(resultReport);
    return 0;
  }

  public void messageReceived(int src_node, Message msg) {
    PpReplyMsg replyMsg = new PpReplyMsg(msg, 0);

    switch (replyMsg.get_reply()) {
      case PpConsts.PP_IMMEDIATE:
        break;
      case PpConsts.PP_TASK:
        break;
      default:
        break;
    }

    msgArrvd = true;
    synchronized (this) {
      notifyAll();
    }
  }



  public int execute(String[] args) {
    int in_dest = Integer.parseInt(args[0]);
    int in_type = Integer.parseInt(args[1]);
    for (int i = 0; i < 10000; i++) {
      System.out.print("seq: " + i);
      Date date = new Date();
      System.out.print("   " + date + "   ");
      ping(in_dest, in_type);
      easyWait(5000);
    }
    return 0;
  }

  public static void main(String[] args) {
    PingPong pp = new PingPong();
    System.exit(pp.execute(args));
  }
};

