package net.tinyos.wakeup;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.drip.*;

public class Wakeup {
  public static void usage() {
    System.err.println("java net.tinyos.wakeup.Wakeup {both,bat,cap} <timeout in seconds>");
    System.exit(1);
  }

  public static void main(String args[]) {

    if (args.length < 2) {
      usage();
    }
    
    WakeupMsg wakeupMsg = new WakeupMsg();

    DripDaemon dd = new DripDaemon(WakeupMsg.AM_TYPE);

    String source = args[0];
    if (source.equals("both")) {
      wakeupMsg.set_source(WakeupConsts.WAKEUP_SOURCE_BOTH);
    }
    if (source.equals("bat")) {
      wakeupMsg.set_source(WakeupConsts.WAKEUP_SOURCE_BAT);
    }
    if (source.equals("cap")) {
      wakeupMsg.set_source(WakeupConsts.WAKEUP_SOURCE_CAP);
    }

    int wakeupPeriod = Integer.parseInt(args[1]);
    System.out.println("Wakeup period = " + (wakeupPeriod) + " secs");
    System.out.println("Source = " + source + " (" + wakeupMsg.get_source() + ")");

    wakeupMsg.set_wakeupPeriod(wakeupPeriod * 100);

    while(true) {
      System.out.println("Renewing lease for " + (wakeupPeriod) + " secs");
      dd.storeForever(wakeupMsg, WakeupMsg.DEFAULT_MESSAGE_SIZE);
      try { 
	if (wakeupPeriod < 1) {
	  Thread.sleep(1000 / 2); 
	} else {
	  Thread.sleep(wakeupPeriod * 1000 / 2);
	}
      } catch (InterruptedException e) {}
    }
  }
}
