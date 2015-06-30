package com.shockfish.tinyos.gateway;

/**
 * @author Karl Baumgartner, HEIG-VD
 * @author Pierre Metrailler, Shockfish SA
 */

import com.shockfish.tinyos.packet.*;
import java.io.*;
import java.util.Date;
import com.shockfish.tinyos.tools.*;

import java.lang.String;
import com.shockfish.tinyos.net.CldcSntpClient;

public class UpdateDate extends Thread {
	
	private Tc65Manager manager;
		
	private final String DEFAULT_IP_DATE_SERVER = "swisstime.ethz.ch";
	
	private final String FILE_IP_DATE_SERVER = "IP_DATE_SERVER";
	
	private final static long DATE_UPDATE_PERIOD = 10000;
	
    private static String address;
	
	public UpdateDate(Tc65Manager manager) {
		
		this.manager = manager;
		
		address = manager.readProp(FILE_IP_DATE_SERVER);
		
		if (address == null)
			address = DEFAULT_IP_DATE_SERVER;

	}
	
	public void run() {
		CldcLogger.devDebug(CldcLogger.SRC_7,"Updating time...(UpdateDate: " + Thread.currentThread() + ")");
		
		boolean dateUpdated = false;
		while (!dateUpdated) {
			try {
				
				long offset = CldcSntpClient.getOffset(address, manager.getGprsConf());
				CldcLogger.devDebug(CldcLogger.SRC_7,"Setting offset :" + offset);
				manager.setOffsetCalendar(offset);
				CldcLogger.devDebug(CldcLogger.SRC_7,"Date after the update: " + manager.getDate());
				manager.setSyncedTime();
				dateUpdated = true;
				
			} catch (IOException e) { 
				CldcLogger.devDebug(CldcLogger.SRC_7,"Time update failed, probably due to communication error :" + e.toString());
				manager.resetSyncedTime();
			}
			
			try {
				Thread.sleep(DATE_UPDATE_PERIOD);
			} catch (InterruptedException e) {
				CldcLogger.devDebug(CldcLogger.SRC_7,"Interrupted sleep in UpdateDate: " + e.toString());
			}
		}
		
		CldcLogger.devDebug(CldcLogger.SRC_7, "UpdateDate done.");
	}
	
}