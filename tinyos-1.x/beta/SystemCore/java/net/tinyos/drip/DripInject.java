package net.tinyos.drip;

import java.io.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class DripInject {

  private MoteIF moteIF;
  private int key;
  private int value;

  public DripInject() {
    moteIF = new MoteIF(PrintStreamMessenger.err);
  }

  public void inject(int id, int value) {

    DripMsg msg = new DripMsg();

    this.key = id;
    msg.set_metadata_id((short)key);
    msg.set_metadata_seqno((byte)0);
    this.value = value;

    for(int i = 0; i < 4; i++) {
      msg.setElement_data(i, (short)((value & (0xff << 8*i)) >> 8*i));
    }
    System.out.println(msg);
    
    send(msg);
  }

  public synchronized void send(Message m) {
    try {
      moteIF.send(MoteIF.TOS_BCAST_ADDR, m);
    } catch (IOException e) {
      e.printStackTrace();
      System.out.println("ERROR: Can't send message");
      System.exit(1);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public static void usage() {
    System.err.println("Usage: java net.tinyos.tools.DripInject"+
		       " <channel> <value> ");
  }

  public static void main(String[] argv) throws IOException {

    DripInject ij = new DripInject();

    if (argv.length < 2) {
      usage();
      System.exit(-1);
    }
    
    int channel = Integer.parseInt(argv[0]);
    int value = Integer.parseInt(argv[1], 16);

    ij.inject(channel, value);
  }
}




