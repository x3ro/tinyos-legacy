package test.pause;

import java.io.*;
import java.net.*;

import net.tinyos.packet.*;
import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.sim.*;
import net.tinyos.sim.msg.*;
import net.tinyos.sim.event.*;

public class RateApp {


    public static void main(String[] args) throws IOException {
	Socket cmdSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_COMMAND_PORT);
	Socket eventSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_EVENT_PORT);
	
	SimProtocol cmdProtocol = new SimProtocol(cmdSocket.getInputStream(),
						  cmdSocket.getOutputStream());
	SimProtocol eventProtocol = new SimProtocol(eventSocket.getInputStream(),
						    eventSocket.getOutputStream(),
						    true);


	net.tinyos.sim.msg.SetRateCommand msg;
	msg = new net.tinyos.sim.msg.SetRateCommand();
	System.out.println(msg);
	
	net.tinyos.sim.event.SetRateCommand cmd;
	cmd = new net.tinyos.sim.event.SetRateCommand(250);
	System.out.println(cmd);

	cmdProtocol.writeCommand(cmd);

	try {
	    while (true) {
		System.out.println(eventProtocol.readEvent(0));
	    }
	}
	catch(IOException exception) {}

	System.out.println("> Done. Quitting.");
	//cmdSocket.flush();
	cmdSocket.close();
	//eventSocket.flush();
	eventSocket.close();
    }








}
