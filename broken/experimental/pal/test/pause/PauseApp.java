package test.pause;

import java.io.*;
import java.net.*;

import net.tinyos.packet.*;
import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.sim.*;
import net.tinyos.sim.msg.*;
import net.tinyos.sim.event.*;

public class PauseApp {


    public static void main(String[] args) throws IOException {
	Socket cmdSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_COMMAND_PORT);
	Socket eventSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_EVENT_PORT);
	
	SimProtocol cmdProtocol = new SimProtocol(cmdSocket.getInputStream(),
						  cmdSocket.getOutputStream());
	SimProtocol eventProtocol = new SimProtocol(eventSocket.getInputStream(),
						    eventSocket.getOutputStream(),
						    false);


	net.tinyos.sim.msg.SimulationPauseCommand msg;
	msg = new net.tinyos.sim.msg.SimulationPauseCommand();
	msg.set_id(31337);
	System.out.println(msg);
	
	net.tinyos.sim.event.SimulationPauseCommand cmd;
	cmd = new net.tinyos.sim.event.SimulationPauseCommand((short)0, (long)10 * 4000000, msg.dataGet());
	System.out.println(cmd);

	cmdProtocol.writeCommand(cmd);

	TossimEvent e = null;
	while (e == null ||
	       !(e instanceof net.tinyos.sim.event.SimulationPausedEvent)) {
	    System.out.println("Reading event:");
	    e = eventProtocol.readEvent(0);
	    System.out.println(e);
	    if (!(e instanceof net.tinyos.sim.event.SimulationPausedEvent)) {
		eventProtocol.ackEventRead();
	    }
	}
	
	
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
