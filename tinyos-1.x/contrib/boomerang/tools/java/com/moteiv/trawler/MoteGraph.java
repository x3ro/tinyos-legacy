/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package com.moteiv.trawler;

import edu.uci.ics.jung.graph.impl.*;
import java.util.Timer;

public class MoteGraph extends DirectedSparseGraph {

    public MoteGraph() {
	super(); 
	maintenanceTimer = new Timer(); 
    }

    Timer maintenanceTimer;

    /**
     * Get the MaintenanceTimer value.
     * @return the MaintenanceTimer value.
     */
    public Timer getMaintenanceTimer() {
	return maintenanceTimer;
    }

    /**
     * Set the MaintenanceTimer value.
     * @param newMaintenanceTimer The new MaintenanceTimer value.
     */
    public void setMaintenanceTimer(Timer newMaintenanceTimer) {
	this.maintenanceTimer = newMaintenanceTimer;
    }

    
}
