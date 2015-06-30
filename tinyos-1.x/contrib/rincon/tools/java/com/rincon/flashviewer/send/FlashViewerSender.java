package com.rincon.flashviewer.send;

import java.io.IOException;

import net.tinyos.message.Message;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

import com.rincon.flashviewer.ViewerCommands;
import com.rincon.flashviewer.messages.ViewerMsg;

public class FlashViewerSender implements FlashViewerCommands {
	
	/** Communication with the mote */
	/** Communication with the mote */
	private MoteIF comm = new MoteIF((Messenger) null);
	
	/** Command to send */
	private ViewerMsg command = new ViewerMsg();
	
	/**
	 * Send a message
	 * @param dest
	 * @param m
	 */
	private void send(int dest, Message m) {
		try {
			comm.send(dest, m);
		} catch (IOException e) {
			System.err.println("Couldn't contact the mote");
		}
	}
	
	
	public void read(long address, int length, int moteID) {
		command.set_addr(address);
		command.set_len(length);
		command.set_cmd(ViewerCommands.CMD_READ);
		send(moteID, command);
	}

	public void write(long address, short[] buffer, int length, int moteID) {
		command.set_addr(address);
		command.set_len(length);
		command.set_data(buffer);
		command.set_cmd(ViewerCommands.CMD_WRITE);
		send(moteID, command);
		
	}

	public void erase(int moteID) {
		command.set_cmd(ViewerCommands.CMD_ERASE);
		send(moteID, command);
		
	}

	public void mount(short id, int moteID) {
		command.set_id(id);
		command.set_cmd(ViewerCommands.CMD_MOUNT);
		send(moteID, command);
		
	}

	public void commit(int moteID) {
		command.set_cmd(ViewerCommands.CMD_COMMIT);
		send(moteID, command);
	}
	
	public void ping(int moteID) {
		command.set_cmd(ViewerCommands.CMD_PING);
		send(moteID, command);
	}
}
