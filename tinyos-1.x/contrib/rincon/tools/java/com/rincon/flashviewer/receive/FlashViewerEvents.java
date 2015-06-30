package com.rincon.flashviewer.receive;

public interface FlashViewerEvents {

	/**
	 * Read is complete
	 * @param address
	 * @param buffer
	 * @param length
	 * @param success
	 */
	public void readDone(long address, short[] buffer, int length, boolean success);
	
	/**
	 * Write is complete
	 * @param address
	 * @param buffer
	 * @param length
	 * @param success
	 */
	public void writeDone(long address, short[] buffer, int length, boolean success);
	
	/**
	 * Erase is complete
	 * @param success
	 */
	public void eraseDone(boolean success);
	
	/**
	 * Mount is complete
	 * @param id
	 * @param success
	 */
	public void mountDone(int id, boolean success);
	
	/**
	 * Commit is complete
	 * @param success
	 */
	public void commitDone(boolean success);
	
	/**
	 * Ping received a pong
	 *
	 */
	public void pong();
}
