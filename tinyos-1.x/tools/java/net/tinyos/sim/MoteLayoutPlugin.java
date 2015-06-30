// $Id: MoteLayoutPlugin.java,v 1.5 2004/06/11 21:30:14 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Michael Demmer
 * Date:        January 9, 2004
 * Desc:        Mote Layout plugin 
 *              Handles position management of motes independant of the GUI
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.io.*;

import net.tinyos.sim.event.*;

public class MoteLayoutPlugin extends Plugin implements SimConst {
  private SimDebug dbg = SimDebug.get("layout");
  
  private static final double GRID_RANDOM_DEVIATION = 5;

  public static final int LAYOUT_RANDOM = 0;
  public static final int LAYOUT_GRID = 1;
  public static final int LAYOUT_GRID_RANDOM = 2;
  public static final int LAYOUT_FILE = 3;
  private int layout = LAYOUT_RANDOM;

  private SimState state;
  private Random rand;
  private SpatialReader spatialReader;

  public void initialize(SimDriver driver) {
    super.initialize(driver);
    this.state = driver.getSimState();
    this.rand = driver.getSimRandom().getRandom();
  }

  public void register() {
  }

  public void deregister() {
  }

  public void createMote(int id) {
    // check to make sure the mote doesn't already exist since this
    // gets called on each TossimEvent
    if (state.getMoteSimObject(id) != null) {
      dbg.out.println("layout: mote " + id + " already exists");
      return;
    }
    
    dbg.out.println("layout: creating mote "+id);
    
    double x = rand.nextDouble()*(MOTE_SCALE_WIDTH * 0.8);
    double y = rand.nextDouble()*(MOTE_SCALE_WIDTH * 0.8);
    x += (MOTE_SCALE_WIDTH * 0.1);
    y += (MOTE_SCALE_WIDTH * 0.1);

    MoteSimObject m = new MoteSimObject(driver, x, y, id);
    state.addSimObject(m);
  }

  public void handleEvent (SimEvent event) {
    if (event instanceof OptionSetEvent) {
      OptionSetEvent ose = (OptionSetEvent)event;
      if (!ose.name.equals("layout")) return;
      
      if (ose.value.equals("grid")) {
	this.layout = LAYOUT_GRID;
      } else if (ose.value.equals("random")) {
	this.layout = LAYOUT_RANDOM;
      } else if (ose.value.equals("gridrandom")) {
	this.layout = LAYOUT_GRID_RANDOM;
      } else if (ose.value.startsWith("file ")) {
        try {
          loadLocationFile(new File(ose.value.substring(5)));
        } catch (Exception e) {
	  System.err.println("Can't load location file '" +
                             ose.value.substring(5)+"': "+e);
	}
      } else {
	System.err.println("Bad value for layout option: "+ose.value);
      }
      
      doLayout();
      driver.refreshMotePanel();

    } else if (event instanceof SimObjectEvent) {
      SimObjectEvent soEvent = (SimObjectEvent)event;
      SimObject simObject = soEvent.getSimObject();
      switch (soEvent.getType()) {
	case (SimObjectEvent.OBJECT_ADDED):
	  if (simObject instanceof MoteSimObject) {
	    // XXX MDW: Assume motes aren't added on the fly
	    //if (layout == LAYOUT_GRID || layout == LAYOUT_GRID_RANDOM) 
	    //  doLayout();
            driver.refreshMotePanel();
	  }
	  break;
	case (SimObjectEvent.OBJECT_REMOVED):
	  if (simObject instanceof MoteSimObject) {
	    if (layout == LAYOUT_GRID || layout == LAYOUT_GRID_RANDOM) 
	      doLayout();
            driver.refreshMotePanel();
	  }
	  break;
      }
    } else if (event instanceof TossimInitEvent) {
        /*
         * Note: this is the only hook by which MoteSimObject's are
         * created. In previous versions, each TossimEvent would check
         * for a corresponding MoteSimObject and if it wasn't there,
         * would create it.
         */
	TossimInitEvent tiEvent = (TossimInitEvent)event;
	int numMotes = tiEvent.get_numMotes();
	for (int i = 0; i < numMotes; i++) {
          createMote(i);
	}
	if (layout != LAYOUT_RANDOM) doLayout();
        driver.refreshMotePanel();
    }
  }
  public String toString() {
    return "MoteLayoutPlugin";
  }

  public void loadLocationFile(File locfile) throws IOException {
    dbg.out.println("layout: Loading location file "+locfile);
    int oldlayout = layout;
    layout = LAYOUT_FILE;
    try {
      spatialReader = new SpatialReader(locfile);
      Iterator it = state.getMoteSimObjects().iterator();
      while (it.hasNext()) {
        MoteSimObject mote = (MoteSimObject)it.next();
        SpatialReader.SREntry sEntry = spatialReader.getEntry(mote.getID());
        if (sEntry != null) {
          dbg.out.println("layout: Setting "+mote+" location to "+
                          sEntry.getX()+","+sEntry.getY());
          mote.moveSimObjectTo(sEntry.getX(), sEntry.getY());
        }
      }
    } catch (IOException e) {
      layout = oldlayout;
      throw(e);
    }
  }

  public void saveLocationFile(File locfile) throws IOException {
    SpatialWriter sWriter = new SpatialWriter(locfile);
    Iterator it = state.getMoteSimObjects().iterator();
    while (it.hasNext()) {
      MoteSimObject mote = (MoteSimObject)it.next();
      CoordinateAttribute coordAttrib = mote.getCoordinate();
      sWriter.writeEntry(mote.getID(), coordAttrib.getX(), coordAttrib.getY());
    }
    sWriter.done();
  }
    
  private void doLayout() {
    int nummotes = state.getMoteSimObjects().size();
    dbg.out.println("layout: doing layout of "+nummotes+" motes");
    //if (nummotes == 0) return;

    if (layout == LAYOUT_FILE) {
      if (spatialReader == null) return;
      Iterator it = state.getMoteSimObjects().iterator();
      while (it.hasNext()) {
	MoteSimObject mote = (MoteSimObject)it.next();
	SpatialReader.SREntry sEntry = spatialReader.getEntry(mote.getID());
	if (sEntry != null) {
          mote.moveSimObjectTo(sEntry.getX(), sEntry.getY());
	}
      }
      return;
    }

    int num_rows = 1, num_columns = 1;
    double xspacing = 0, yspacing = 0;

    int MAX_SPACING = 4*SimConst.MOTE_OBJECT_SIZE;
    double realwidth = MOTE_SCALE_WIDTH * 0.9;
    double realheight = MOTE_SCALE_HEIGHT * 0.9;
    double xbase = 0.0, ybase = 0.0;

    if (layout == LAYOUT_GRID || layout == LAYOUT_GRID_RANDOM) {
      int side = (int)(Math.ceil(Math.sqrt(nummotes * 1.0)));
      num_rows = side;
      num_columns = side;
      xspacing = realwidth / num_columns;
      yspacing = realheight / num_rows;
      if (xspacing > MAX_SPACING) xspacing = MAX_SPACING;
      if (yspacing > MAX_SPACING) yspacing = MAX_SPACING;
      if (nummotes > 2) {
	xbase = 50.0 - xspacing  * ((side-1) / 2.0);
	ybase = 50.0 - yspacing  * ((side-1) / 2.0);
      } else {
	xbase = 50.0 - xspacing  * ((side-1) / 2.0);
	ybase = 50.0;
      }
    }

    Iterator it = state.getMoteSimObjects().iterator();
    while (it.hasNext()) {
      MoteSimObject mote = (MoteSimObject)it.next();
      if (layout == LAYOUT_RANDOM) {	
        double x = rand.nextDouble()*(MOTE_SCALE_WIDTH * 0.8);
        double y = rand.nextDouble()*(MOTE_SCALE_HEIGHT * 0.8);
        x += (MOTE_SCALE_WIDTH * 0.1);
        y += (MOTE_SCALE_HEIGHT * 0.1);
        mote.moveSimObjectTo(x, y);
        
      } else if (layout == LAYOUT_GRID || layout == LAYOUT_GRID_RANDOM) {
	int rownum = mote.getID() / num_columns;
	int colnum = mote.getID() % num_columns;
	double x = (xspacing * colnum) + xbase;
	double y = (yspacing * rownum) + ybase;
	if (layout == LAYOUT_GRID_RANDOM) {
	  x += ((rand.nextDouble() * GRID_RANDOM_DEVIATION*2.0) -
                GRID_RANDOM_DEVIATION);
	  y += ((rand.nextDouble() * GRID_RANDOM_DEVIATION*2.0) -
                GRID_RANDOM_DEVIATION);
	}
	mote.moveSimObjectTo(x, y);
      }
    }
  }
    
  public void setLayout(int thelayout) {
    if (thelayout != LAYOUT_GRID &&
	thelayout != LAYOUT_RANDOM &&
	thelayout != LAYOUT_GRID_RANDOM &&
	thelayout != LAYOUT_FILE) {
      throw new IllegalArgumentException("Invalid setting for layout: "+
                                         layout);
    }
    this.layout = thelayout;
    doLayout();
  }
}

