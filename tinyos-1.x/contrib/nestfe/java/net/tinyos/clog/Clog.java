package net.tinyos.clog;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.drip.*;
import net.tinyos.drain.*;

import org.apache.log4j.*;

import java.io.*; 
import java.text.*;
import java.util.*;
import java.net.*;

public class Clog implements MessageListener {

  private Map bridgeTypes = new HashMap();
  private Map groups = new HashMap();
  private Timer groupTimer = new Timer();
  private Logger log = Logger.getLogger(Clog.class.getName());

  public Clog(String args[]) {
    log.info("start");
    DrainConnector dc = new DrainConnector();
    dc.registerListener(DrainGroupRegisterMsg.AM_TYPE, new DrainGroupListener());
    dc.registerListener(DrainConnector.BCAST_ID, this);
  }

  synchronized public void messageReceived(int to, Message m) {
    DrainMsg drainMsg = (DrainMsg) m;

    if (drainMsg.get_dest() >= 0xFE00 && 
	drainMsg.get_dest() <= 0xFEFF) {
      
      log.info("received msg: type=" + drainMsg.get_type() +
	       " source=" + drainMsg.get_source() + 
	       " finalDest=" + drainMsg.get_dest());
      
      Drip drip = (Drip) bridgeTypes.get(new Integer(drainMsg.get_type()));
      if (drip == null) {
	drip = new Drip(drainMsg.get_type());
	bridgeTypes.put(new Integer(drainMsg.get_type()), drip);
      }

      Object remover = groups.get(new Integer(drainMsg.get_dest()));
      if (remover == null) {
	log.debug("dropping message: nobody registered for group " + drainMsg.get_dest());
	return;
      }

      int msgSize = drainMsg.dataLength() - DrainMsg.DEFAULT_MESSAGE_SIZE;
      byte[] msgData = drainMsg.dataGet();

      AddressMsg addrMsg = new AddressMsg(AddressMsg.DEFAULT_MESSAGE_SIZE + msgSize);
      
      addrMsg.dataSet(msgData, drainMsg.offset_data(0), 
		      addrMsg.offset_data(0), msgSize);
      
      addrMsg.set_dest(drainMsg.get_dest());
      addrMsg.set_source(drainMsg.get_source());
      
      drip.sendUnreliable(addrMsg, msgSize + AddressMsg.DEFAULT_MESSAGE_SIZE);
    }
  }

  private class DrainGroupListener implements MessageListener {

    synchronized public void messageReceived(int to, Message m) {
      DrainMsg drainMsg = (DrainMsg) m;
      DrainGroupRegisterMsg registerMsg = 
	new DrainGroupRegisterMsg(drainMsg, drainMsg.offset_data(0),
				  drainMsg.dataLength() - drainMsg.offset_data(0));
      log.info("Joined Drain Group: node=" + drainMsg.get_source() +
	       " group=" + registerMsg.get_group() +
	       " timeout=" + registerMsg.get_timeout());

      DrainGroupRemover remover = (DrainGroupRemover) groups.get(new Integer(registerMsg.get_group()));

      if (remover != null) {
	remover.cancel();
      }

      remover = new DrainGroupRemover(registerMsg.get_group());
      groups.put(new Integer(registerMsg.get_group()), remover);
      groupTimer.schedule(remover, registerMsg.get_timeout()*1024);
    }
  }

  private class DrainGroupRemover extends TimerTask {
    int group;

    public DrainGroupRemover(int group) {
      this.group = group;
    }

    public void run() {
      log.info("Left Drain Group: group=" + group);
      groups.remove(new Integer(group));
    }
  }

  public static void main(String args[]) {
    PropertyConfigurator.configureAndWatch("log4j.properties", 1000);
    new Clog(args);
  }
}
