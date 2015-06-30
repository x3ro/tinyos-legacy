package com.rincon.flashviewer.receive;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.rincon.flashviewer.ViewerCommands;
import com.rincon.flashviewer.messages.ViewerMsg;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.util.Messenger;

public class FlashViewerReceiver implements MessageListener {

	/** List of FileTransferEvents listeners */
	private static List listeners = new ArrayList();
	
	/** Communication with the mote */
	private static MoteIF comm = new MoteIF((Messenger) null);


	/**
	 * Constructor
	 *
	 */
	public FlashViewerReceiver() {
		comm.registerListener(new ViewerMsg(), this);
	}
	
	/**
	 * Add a FileTransferEvents listener
	 * @param listener
	 */
	public void addListener(FlashViewerEvents listener) {
		if(!listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	
	/**
	 * Remove a FileTransferEvents listener
	 * @param listener
	 */
	public void removeListener(FlashViewerEvents listener) {
		listeners.remove(listener);
	}
	
	
	/**
	 * Received a ViewerMsg from UART
	 */
	public void messageReceived(int to, Message m) {
		ViewerMsg inMsg = (ViewerMsg) m;
		
		switch(inMsg.get_cmd()) {
		case ViewerCommands.REPLY_COMMIT:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).commitDone(true);
			}
			break;
		
		case ViewerCommands.REPLY_COMMIT_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).commitDone(false);
			}
			break;
		
		case ViewerCommands.REPLY_COMMIT_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).commitDone(false);
			}
			break;
			
		case ViewerCommands.REPLY_ERASE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).eraseDone(true);
			}
			break;
			
		case ViewerCommands.REPLY_ERASE_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).eraseDone(false);
			}
			break;
		
		case ViewerCommands.REPLY_ERASE_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).eraseDone(false);
			}
			break;
			
		case ViewerCommands.REPLY_MOUNT:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).mountDone(inMsg.get_id(), true);
			}
			break;
			
		case ViewerCommands.REPLY_MOUNT_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).mountDone(inMsg.get_id(), false);
			}
			break;
			
			
		case ViewerCommands.REPLY_MOUNT_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).mountDone(inMsg.get_id(), false);
			}
			break;
		
		case ViewerCommands.REPLY_READ:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).readDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), true);
			}
			break;
			
		case ViewerCommands.REPLY_READ_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).readDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_READ_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).readDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_WRITE:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).writeDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), true);
			}
			break;
			
		case ViewerCommands.REPLY_WRITE_CALL_FAILED:
			System.err.println("Command immediately failed");
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).writeDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_WRITE_FAILED:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).writeDone(inMsg.get_addr(), inMsg.get_data(), inMsg.get_len(), false);
			}
			break;
			
		case ViewerCommands.REPLY_PING:
			for(Iterator it = listeners.iterator(); it.hasNext(); ) {
				((FlashViewerEvents) it.next()).pong();
			}
			break;
			
		default:
			System.err.println("Unrecognized FlashViewer message received (cmd " + inMsg.get_cmd() + ")");
			
		}
	}

}
