/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package com.moteiv.trawler;

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;
import java.util.*;

public class UartDetect implements MessageListener,Runnable {

    public static byte group_id = -1;
    MoteIF mote;
    boolean connected = false;
    int baseAddress = -1;
    public UartDetect() {
	this(new MoteIF(PrintStreamMessenger.err, UartDetect.group_id));
    }

    public UartDetect(MoteIF mif) {
	try {
	    mote = mif;
	    mote.registerListener(new UartDetectMsg(), this);
	}
	catch (Exception e) {
	    System.err.println("Unable to connect to Mote interface");
	    System.exit(-1);
	}
    }

    public void messageReceived(int dest_addr, Message msg) {
        if (msg instanceof UartDetectMsg) {
            msgReceived( dest_addr, (UartDetectMsg)msg);
        } else {
            throw new RuntimeException("messageReceived: Got bad message type: "+msg);
        }
    }

    public void msgReceived(int dest_addr, UartDetectMsg umsg) {
	if (umsg.get_cmd() == UartDetectConsts.UARTDETECT_REQUEST) {
	    baseAddress = umsg.get_addr();
	    //	    System.out.println("[Request] addr = " + umsg.get_addr());
	    UartDetectMsg numsg = new UartDetectMsg();
	    numsg.set_addr(0x007e);
	    numsg.set_cmd(UartDetectConsts.UARTDETECT_RESPONSE);
	    numsg.set_timeout(0x1800);
	    connected = true;
	    sendResponse(numsg);
	    //	    System.out.println("[Response] time = " + numsg.get_timeout());
	}
    }

    public static void main(String[] args) throws IOException {
        if (args.length == 1) {
          group_id = (byte) Integer.parseInt(args[0]);
	}
	UartDetect runclass = new UartDetect();
	Thread th = new Thread(runclass);
        th.start();
    }

    private void sendResponse(UartDetectMsg umsg) {
        try {
	    // inject packet
	    mote.send(MoteIF.TOS_BCAST_ADDR, umsg);
	}
	catch (IOException ioe) {
	    System.err.println("Unable to sent message to mote: "+ ioe);
	    ioe.printStackTrace();
	    connected = false;
	}
    }
    
    public int getBaseAddress() {
	if (connected) {
	    return baseAddress;
	} else {
	    return -1;
	}
    }

    public void run() {
        UartDetectMsg umsg = new UartDetectMsg();
	umsg.set_addr(0x007e);
	umsg.set_timeout(0x1800);

	while(true) {
	    try {
		Thread.sleep(2000);
	    }
	    catch (Exception e) { }
	    umsg.set_cmd(UartDetectConsts.UARTDETECT_KEEPALIVE);
	    sendResponse(umsg);
	    //	    System.out.println("[KeepAlive] time = " + umsg.get_timeout());
	}

    }

}
