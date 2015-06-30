package com.shockfish.tinyos.gateway;

/**
 * @author Karl Baumgartner, HEIG-VD
 */

import java.io.IOException;
import com.shockfish.tinyos.gateway.SenderTimerControl;
import com.shockfish.tinyos.gateway.CldcDataSender;
import com.shockfish.tinyos.tools.Tc65Manager;
import com.shockfish.tinyos.tools.CldcLogger;
import com.shockfish.tinyos.gateway.TOSBuffer;

public class SenderMessage extends Thread {

	private SenderTimerControl senderTimerControl;

	private Tc65Manager manager;

	private TOSBuffer tosbuffer;

	private int NumberOfRecordToSend;

	private CldcDataSender cldsDataSender;

	private int maxNumberOfTry = 1;

	private final String DEFAULT_IP_DATA_SERVER = "10.192.168.10";

	private final String DEFAULT_PORT_DATA_SERVER = "1000";

	private final String FILE_IP_DATA_SERVER = "IP_DATA_SERVER";

	private final String FILE_PORT_DATA_SERVER = "PORT_DATA_SERVER";

	private final String FILE_ID_BASESTATION = "BASESTATION_ID";

	private final String DEFAULT_ID_BASESTATION = "NO_BASESTATION_ID";

	public SenderMessage(Tc65Manager manager, TOSBuffer tosbuffer,
			SenderTimerControl senderTimerControl) {
		super();
		this.senderTimerControl = senderTimerControl;
		this.manager = manager;
		this.tosbuffer = tosbuffer;

		String address = manager.readProp(FILE_IP_DATA_SERVER);
		String port = manager.readProp(FILE_PORT_DATA_SERVER);

		if (address == null)
			address = DEFAULT_IP_DATA_SERVER;
		if (port == null)
			port = DEFAULT_PORT_DATA_SERVER;

		cldsDataSender = new CldcDataSender(address, Integer.parseInt(port),
				manager.getGprsConf());
	}

	public void run() {
		NumberOfRecordToSend = tosbuffer.size();
		
		// do not start the connection if nothing to send
		CldcLogger.devDebug(CldcLogger.SRC_8, "SenderMessage started ("
				+ Thread.currentThread() + ")");

		if (NumberOfRecordToSend <= 0) {
			CldcLogger.info("Buffer empty, do not send anything");
			senderTimerControl.startSenderTimer();
			return;
		}

		String id_basestation = manager.readProp(FILE_ID_BASESTATION);

		if (id_basestation == null)
			id_basestation = DEFAULT_ID_BASESTATION;

		long startTime = System.currentTimeMillis();
		int numberOfTry = 0;
		boolean isConnected = false;

		// try to reconnect a certain number of times
		while ((numberOfTry <= maxNumberOfTry) && (!isConnected)) {
			try {
				cldsDataSender.connect();
				isConnected = true;
			} catch (IOException e) {
				CldcLogger
						.severe("Connection to server failed: "
								+ e);
				numberOfTry++;
			}
		}

		boolean isSent = false;
		int NumSendedRecord = 0;
		try {
			if (!isConnected) {
				senderTimerControl.startSenderTimer();
				return;
			}

			cldsDataSender.sendInit(id_basestation, Tc65Manager.getDate());

			for (int i = 0; i < NumberOfRecordToSend; i++) {
				cldsDataSender.sendRecord(tosbuffer.getElement(i));
				NumSendedRecord++;
			}

			cldsDataSender.sendEnd();
			isSent = true;

		} catch (IOException e) {
			CldcLogger.severe("SenderMessage error: "
					+ e.toString());
		}

		try {
			cldsDataSender.close();
		} catch (IOException e) {
			CldcLogger.severe("SenderMessage closing error: "
					+ e.toString());
		}

		if (isSent) {
			for (int i = 0; i < NumberOfRecordToSend; i++) {
				tosbuffer.deleteRecord(0);
			}
		}

		senderTimerControl.startSenderTimer();
	}
}