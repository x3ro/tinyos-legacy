package com.shockfish.tinyos.gateway;

/**
 * @author Karl Baumgartner, HEIG-VD
 */

import java.io.*;
import com.shockfish.tinyos.tools.*;
import java.util.Vector;
import java.util.TimerTask;

public class SenderTask extends TimerTask {

	private Tc65Manager manager;

	private TOSBuffer tosbuffer;

	private SenderTimerControl senderTimerControl;

	
	public SenderTask(Tc65Manager manager, TOSBuffer tosbuffer,
			SenderTimerControl senderTimerControl) {
		super();
		this.manager = manager;
		this.tosbuffer = tosbuffer;
		this.senderTimerControl = senderTimerControl;
	}

	public void run() {

		Vector vector;
		SenderMessage senderMessage = new SenderMessage(manager, tosbuffer,
				senderTimerControl);
		senderMessage.start();

	}

}