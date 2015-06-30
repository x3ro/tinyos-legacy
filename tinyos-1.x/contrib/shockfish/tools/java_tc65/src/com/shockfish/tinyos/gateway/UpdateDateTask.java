package com.shockfish.tinyos.gateway;

/**
 * @author Karl Baumgartner, HEIG-VD
 */

import com.shockfish.tinyos.tools.*;
import java.util.Vector;
import java.util.TimerTask;

public class UpdateDateTask extends TimerTask {

	private Tc65Manager manager;

	public UpdateDateTask(Tc65Manager manager) {
		super();
		this.manager = manager;
	}

	public void run() {
		UpdateDate updateDate = new UpdateDate(manager);
		updateDate.start();
	}

}