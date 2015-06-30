package net.tinyos.task.awtfield;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import net.tinyos.message.*;

abstract public class SimpleCommand implements MessageListener, Cloneable {
    Tool parent;
    Output output;
    byte[] cmdData; // the arguments to the command

    public SimpleCommand(Tool parent, String name) {
	this.parent = parent;
	cmdData = null;
	cmdString(name);
    }

    // These command (argument) functions are inefficient.

    private int extendCmd(int by) {
	if (cmdData == null) {
	    cmdData = new byte[by];
	    return 0;
	}

	int old = cmdData.length;
	byte[] newData = new byte[old + by];
	System.arraycopy(cmdData, 0, newData, 0, old);
	cmdData = newData;

	return old;
    }

    public void cmdString(String s) {
	int len = s.length();
	int start = extendCmd(len + 1);
	for (int i = 0; i < len; i++)
	    cmdData[start + i] = (byte)s.charAt(i);
	cmdData[start + len] = 0;
    }

    public void cmd8(int n) {
	int s = extendCmd(1);
	cmdData[s] = (byte)n;
    }

    public void cmd16(int n) {
	int s = extendCmd(2);
	cmdData[s] = (byte)n;
	cmdData[s + 1] = (byte)(n >> 8);
    }

    public void cmd32(int n) {
	int s = extendCmd(4);
	cmdData[s] = (byte)n;
	cmdData[s + 1] = (byte)(n >> 8);
	cmdData[s + 2] = (byte)(n >> 16);
	cmdData[s + 3] = (byte)(n >> 24);
    }

    public Object clone() {
	SimpleCommand copy = null;
	try {
	    copy = (SimpleCommand)super.clone();
	    copy.cmdData = (byte[])cmdData.clone();
	}
	catch (CloneNotSupportedException e) { System.exit(2); }
	return copy;
    }

    public String result(FieldReplyMsg reply) {
	return "done";
    }

    FieldMsg cmd() {
	FieldMsg msg = new FieldMsg(FieldMsg.offset_cmd(0) + cmdData.length);
	msg.set_cmd(cmdData);
	return msg;
    }

    void run(int dest, Output output) {
	this.output = output;
	parent.executer.sendCommand(dest, cmd(), this);
    }

    public void messageReceived(int to, Message m) {
	FieldReplyMsg msg = (FieldReplyMsg)m;

	if (msg.get_errorNo() == Tool.SCHEMA_ERROR)
	    output.add(msg.get_sender(), "error");
	else
	    output.add(msg.get_sender(), result(msg));
    }
}
