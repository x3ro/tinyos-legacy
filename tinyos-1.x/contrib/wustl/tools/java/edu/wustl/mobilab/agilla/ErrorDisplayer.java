// $Id: ErrorDisplayer.java,v 1.5 2006/11/15 00:22:34 chien-liang Exp $
/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis
 * By Chien-Liang Fok.
 *
 * Washington University states that Agilla is free software;
 * you can redistribute it and/or modify it under the terms of
 * the current version of the GNU Lesser General Public License
 * as published by the Free Software Foundation.
 *
 * Agilla is distributed in the hope that it will be useful, but
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS",
 * OR OTHER HARMFUL CODE.
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to
 * indemnify, defend, and hold harmless WU, its employees, officers and
 * agents from any and all claims, costs, or liabilities, including
 * attorneys fees and court costs at both the trial and appellate levels
 * for any loss, damage, or injury caused by your actions or actions of
 * your officers, servants, agents or third parties acting on behalf or
 * under authorization from you, as a result of using Agilla.
 *
 * See the GNU Lesser General Public License for more details, which can
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */
package edu.wustl.mobilab.agilla;
import edu.wustl.mobilab.agilla.messages.*;

//import java.awt.Event;
import java.awt.event.*;
import java.util.*;

/**
 * AgillaErrorDisplayer.java
 *
 * @author Chien-Liang Fok
 */
public class ErrorDisplayer implements AgillaConstants, MessageListenerJ {
	
	/**
	 * The error codes.  Their array index must match the enum
	 * definition within Agilla.h.
	 */
	private static final String[] causes = new String[] {
		  "AGILLA_ERROR_TRIGGERED",
		  "AGILLA_ERROR_STACK_OVERFLOW",
		  "AGILLA_ERROR_STACK_UNDERFLOW",  
		  "AGILLA_ERROR_HEAP_INDEX_OUT_OF_BOUNDS",
		  "AGILLA_ERROR_CODE_INDEX_OUT_OF_BOUNDS",
		  "AGILLA_ERROR_INVALID_FIELD_TYPE",
		  "AGILLA_ERROR_CODE_OVERFLOW",
		  "AGILLA_ERROR_QUEUE_ENQUEUE", 
		  "AGILLA_ERROR_QUEUE_DEQUEUE",
		  "AGILLA_ERROR_QUEUE_REMOVE",
		  "AGILLA_ERROR_TYPE_CHECK",
		  "AGILLA_ERROR_INVALID_TYPE",
		  "AGILLA_ERROR_INVALID_INSTRUCTION",
		  "AGILLA_ERROR_INVALID_SENSOR",
		  "AGILLA_ERROR_INVALID_VALUE",  
		  "AGILLA_ERROR_ILLEGAL_CODE_BLOCK",
		  "AGILLA_ERROR_ILLEGAL_FIELD_TYPE",
		  "AGILLA_ERROR_INVALID_FIELD_COUNT",
		  "AGILLA_ERROR_TUPLE_SIZE",
		  "AGILLA_ERROR_SEND_BUFF_FULL",
		  "AGILLA_ERROR_RXN_NOT_FOUND",
		  "AGILLA_ERROR_GET_FREE_BLOCK",
		  "AGILLA_ERROR_ILLEGAL_RXN_OP",
	};	
	
    //private ErrorDialog dialog = null;
    /*private String agentID = "";
    private String cause = "";
	private String pc = "";
    private String instruction = "";
	private String sp = "";
    private String reason1 = "";
	private String reason2 = "";*/
	
	private Hashtable<Integer, String> errorTable = new Hashtable<Integer, String>();
	private Vector<ErrorDialog> errors = new Vector<ErrorDialog>();
	private static ErrorDisplayer displayer = new ErrorDisplayer();
	
	/**
	 * The constructor.  
	 */
	private ErrorDisplayer() {
		// Initialize the error table.
		for (int i = 0 ; i < causes.length; i++) {
			errorTable.put(new Integer(i), causes[i]);
		}
	}
	
	/**
	 * An accessor to the error displayer.
	 * 
	 * @return The error displayer.
	 */
	public static ErrorDisplayer getDisplayer() {
		return displayer;
	}
	
	/**
	 * Resets the errorDisplayer.  Closes all error dialogs and clears
	 * them from the database.
	 *
	 */
	public void reset() {
		for (int i = 0; i < errors.size(); i++) {
			errors.get(i).dispose();
		}
		errors.clear();
	}
	
	/**
	 * Updates the error dialog.  If a dialog already exists, dispose of it before displaying the 
	 * new one.
	 * 
	 * @param context
	 * @param cause
	 * @param pc
	 * @param instruction
	 * @param sp
	 * @param reason1
	 * @param reason2
	 */
	/*private void updateDialog(String context, String cause, String pc,
							  String instruction, String sp, String reason1, String reason2) {
		Point p = null;
		if (dialog != null) {
			p = dialog.getLocation();
			dialog.dispose();
		}
		
		dialog = DialogFactory.errorDialog(context, cause, pc, instruction, sp, reason1, reason2);
		if (p != null) {
			dialog.setLocation(p);
		}
		
		dialog.show();
	}*/
	
	
	private void displayErrorMsg(AgillaErrorMsgJ msg) {
		final Error error = new Error(
				msg.getID().toString(),
				getCause((int)msg.getCause()),
				String.valueOf(msg.getPC()),
				msg.getInstr(),
				String.valueOf(msg.getSP()),
				String.valueOf(msg.getReason1()),
				String.valueOf(msg.getReason2()));
		
		boolean duplicate = false;
		for (int i = 0; i < errors.size() && !duplicate; i++) {
			if (errors.get(i).getError().equals(error))
				duplicate = true;
		}
		
		if (!duplicate) {			
			final ErrorDialog dialog = DialogFactory.errorDialog(error);
			errors.add(dialog);
//		if ((!this.agentID.equals(agentID)) ||
//				(!this.pc.equals(pc)) ||
//				(!this.cause.equals(cause)) ||
//				(!this.instruction.equals(instruction)) ||
//				(!this.sp.equals(sp)) ||
//				(!this.reason1.equals(reason1))) {
//			this.agentID = agentID;
//			this.pc = pc;
//			this.cause = cause;
//			this.instruction = instruction;
//			this.sp = sp;
//			this.reason1 = reason1;
//			this.reason2 = reason2;
			/*((javax.swing.JDialog)dialog).addWindowStateListener(new java.awt.event.WindowAdapter() {
				public void windowClosed(java.awt.event.WindowEvent e) {
					Debugger.dbgErr("DebugDialog", "Received WindowEvent " + e, Debugger.DEBUG);
					if (e.getNewState() == java.awt.event.WindowEvent.WINDOW_CLOSED)
						errors.remove(error);
				}
			});*/
			((javax.swing.JDialog)dialog).addWindowListener(new WindowAdapter() {
				/*public void windowClosed(WindowEvent e) {
					Debugger.dbgErr("DebugDialog.windowClosed", "Received WindowEvent " + e, Debugger.DEBUG);
					if (e.getNewState() == java.awt.event.WindowEvent.WINDOW_CLOSED)
						errors.remove(error);
				}*/
				
				public void windowClosing(WindowEvent e) {
					//Debugger.dbgErr("DebugDialog.windowClosing", "Received WindowEvent " + e, Debugger.DEBUG);
					Debugger.dbgErr("DebugDialog.windowClosing", "Received WindowEvent, removing dialog from database.", Debugger.DEBUG);
					//if (e.getNewState() == java.awt.event.WindowEvent.WINDOW_CLOSED)					
					errors.remove(dialog);
				}
				
				/*public void windowStateChanged(WindowEvent e) {
					Debugger.dbgErr("DebugDialog.windowStateChanged", "Received WindowEvent " + e, Debugger.DEBUG);
				}*/
			});
			System.err.println("Error received:\n" + error);
//			updateDialog(agentID, cause, pc, instruction, sp, reason1, reason2);
		} else
			Debugger.dbgErr("ErrorDisplayer", "Received duplicate error.", Debugger.DEBUG);
	}
	
	/**
	 * Converts the integer error cause to the human readable
	 * string describing the cause.
	 * 
	 * @param cause The cause.
	 * @return The string representation of the cause.
	 */
	public String getCause(int cause) {
		Integer key = new Integer(cause);
		if (errorTable.containsKey(key))
			return errorTable.get(new Integer(cause));
		else
			return "UNKNOWN ERROR: " + cause;		
	}
	
	/**
	 * Called when an error message is received.
	 * 
	 */
	public void messageReceived(int to, MessageJ msg) {
		if (msg.getType() == AgillaErrorMsg.AM_TYPE)
			displayErrorMsg((AgillaErrorMsgJ)msg);
	}
	
	/**
	 *  Encapsulates an error.
	 *  
	 * @author Liang Fok	 
	 */
	public class Error {
		String id, cause, pc, instruction, sp, reason1, reason2; 
		
		public Error (String id, String cause, String pc,
				  short instruction, String sp, String reason1, String reason2) {
			this.id = id;
			this.cause = cause;
			this.pc = pc;
			
			this.instruction = Integer.toHexString(instruction & 0xff);
			if (this.instruction.length() == 1)
				this.instruction = "0" + this.instruction;
			String instr = AgillaAssembler.getAssembler().byte2String(instruction);
			if (instr == null) instr = "INVALID";
			this.instruction = "0x" + this.instruction + " (" + instr + ")";
			
			this.sp = sp;
			this.reason1 = reason1;
			this.reason2 = reason2;
		}
		
		public boolean equals(Object obj) {
			if (obj instanceof Error) {
				Error other = (Error)obj;
				return id.equals(other.id) &&
					cause.equals(other.cause) &&
					pc.equals(other.pc) &&
					instruction.equals(other.instruction) &&
					sp.equals(other.sp) &&
					reason1.equals(other.reason1) &&
					reason2.equals(other.reason2);
			} else
				return false;
		}
		
		public String toString() {
			String result = "";
			result += "  AgentID:         " + id + "\n";
			result += "  Cause:           " + cause + "\n";
			result += "  Program counter: " + pc + "\n";
			result += "  Instruction: " + instruction + "\n";
			result += "  Stack Pointer: " + sp + "\n";
			result += "  Reason1: " + reason1 + "\n";
			result += "  Reason2: " + reason2 + "\n";
			return result;
		}
	}
}

