package net.tinyos.drain;

import java.net.*;

import net.tinyos.message.*;
import net.tinyos.util.*;

public class DrainLib {

  public static int setSPAddr() {
    String moteid = Env.getenv("MOTEID");
    int spAddr;
    
    if (moteid != null) {
      spAddr = Integer.parseInt(moteid);
    } else {
      try {
	byte[] localAddr = InetAddress.getLocalHost().getAddress();
	spAddr = localAddr[2];
	spAddr <<= 8;
	spAddr += localAddr[3];
      } catch (Exception e) {
	spAddr = 0xFFFE;
      }
    }
    
    return spAddr;
  }

  public static MoteIF startMoteIF() {
    MoteIF moteif = null;
    try {
      moteif = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }  
    return moteif;
  }
}
