/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;
import java.util.*;

public class RemoteControl implements MessageListener,Runnable {

    MoteIF mote;
    Process p;
    PrintStream ps;

    public RemoteControl() {
        try {
            mote = new MoteIF(PrintStreamMessenger.err, -1);
            mote.registerListener(new RemoteControlMsg(), this);
	    p = Runtime.getRuntime().exec("cscript //NoLogo sendKeys.vbs");
	    ps = new PrintStream(p.getOutputStream());
        }
        catch (Exception e) {
            System.err.println("Unable to connect to sf@localhost:9001");
            System.exit(-1);
        }
    }

    public void messageReceived(int dest_addr, Message msg) {
        if (msg instanceof RemoteControlMsg) {
            remoteReceived( dest_addr, (RemoteControlMsg)msg );
        } else {
            throw new RuntimeException("messageReceived: Got bad message type: "
+msg);
        }
    }

    public void remoteReceived(int dest_addr, RemoteControlMsg rmsg) {
	if (rmsg.get_count() == 1) {
	    ps.println( "{PGDN}" );
	}
	else {
	    ps.println( "{PGUP}" ); 
	}
	ps.flush();
    }

    public static void main(String[] args) throws IOException {
	RemoteControl app = new RemoteControl();
	app.run();
    }

    public void run() {
	while(true) {
	    try {
		Thread.sleep(500);
	    }
	    catch (Exception e) { }
	}
    }
}
