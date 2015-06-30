package test.pause;

import java.io.*;
import java.net.*;

import net.tinyos.packet.*;
import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.sim.*;
import net.tinyos.sim.msg.*;
import net.tinyos.sim.event.*;

public class ReadApp {


    public static void main(String[] args) throws IOException {
	Socket cmdSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_COMMAND_PORT);
	Socket eventSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_EVENT_PORT);
	
	SimProtocol cmdProtocol = new SimProtocol(cmdSocket.getInputStream(),
						  cmdSocket.getOutputStream());
	SimProtocol eventProtocol = new SimProtocol(eventSocket.getInputStream(),
						    eventSocket.getOutputStream(),
						    false);


	net.tinyos.sim.msg.VariableRequestCommand msg;
	msg = new net.tinyos.sim.msg.VariableRequestCommand();
	msg.set_addr(0x08105de0);
	msg.set_length((short)4);
	
	System.out.println(msg);
	
	net.tinyos.sim.event.VariableRequestCommand cmd;
	cmd = new net.tinyos.sim.event.VariableRequestCommand((short)0, (long)2 * 4000000, msg.dataGet());
	System.out.println(cmd);

	cmdProtocol.writeCommand(cmd);

	TossimEvent e = null;
	while (e == null ||
	       !(e instanceof net.tinyos.sim.event.VariableValueEvent)) {
	    e = eventProtocol.readEvent(0);
	    if (!(e instanceof net.tinyos.sim.event.VariableValueEvent)) {
		eventProtocol.ackEventRead();
	    }
	}
	
	System.out.println(e);
	
	InputStreamReader ir = new InputStreamReader(System.in);
	BufferedReader br = new BufferedReader(ir);

	while (true) {
	    System.out.print("> ");
	    String input = br.readLine();
	    if (input.equals("resume")) {
		break;
	    }
	}

	
	eventProtocol.ackEventRead();

	try {
	    while (true) {
		eventProtocol.readEvent(0);
		eventProtocol.ackEventRead();
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
