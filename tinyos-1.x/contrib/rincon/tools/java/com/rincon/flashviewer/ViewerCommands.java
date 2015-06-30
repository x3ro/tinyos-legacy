package com.rincon.flashviewer;

public class ViewerCommands {

	public static final short CMD_READ = 0;
	public static final short CMD_WRITE = 1; 
	public static final short CMD_ERASE = 2;
	public static final short CMD_MOUNT = 3;
	public static final short CMD_COMMIT = 4;
	public static final short CMD_PING = 5;
	
	public static final short REPLY_READ = 10;
	public static final short REPLY_WRITE = 11;
	public static final short REPLY_ERASE = 12;
	public static final short REPLY_MOUNT = 13;
	public static final short REPLY_COMMIT = 14;
	public static final short REPLY_PING = 15;
	
	public static final short REPLY_READ_CALL_FAILED = 20;
	public static final short REPLY_WRITE_CALL_FAILED = 21;
	public static final short REPLY_ERASE_CALL_FAILED = 22;
	public static final short REPLY_MOUNT_CALL_FAILED = 23;
	public static final short REPLY_COMMIT_CALL_FAILED = 24;

	public static final short REPLY_READ_FAILED = 30;
	public static final short REPLY_WRITE_FAILED = 31;
	public static final short REPLY_ERASE_FAILED = 32;
	public static final short REPLY_MOUNT_FAILED = 33;
	public static final short REPLY_COMMIT_FAILED = 34;
	
}