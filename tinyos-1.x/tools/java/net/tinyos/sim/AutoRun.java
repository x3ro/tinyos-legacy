// $Id: AutoRun.java,v 1.17 2004/06/11 21:30:14 mikedemmer Exp $

/*									tab:2
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 */

package net.tinyos.sim;

import java.util.*;
import java.io.*;
import net.tinyos.sim.event.*;

public class AutoRun implements SimConst {

  private SimDriver driver;
  private Thread runThread;
  private AutoRunThread arThread;
  private LoggingPlugin loggingPlugin;
  private AutoRunConfig cur_arc;
  private int stopstringall_count = 0;
  boolean visible_flag = true;

  private static final int STOPMODE_EXIT = 0;
  private static final int STOPMODE_PAUSE = 1;

  private Vector configs = new Vector(1);

  class AutoRunConfig {
    String executable;
    int numMotes;
    String logfile;
    String dbgflags;
    long numsec;
    String screenshot;
    String stopstring;
    boolean stopstringall;
    int stopmode;
    boolean pauseatstart;
    Vector plugins;
    Hashtable options;
    String precmd;
    String postcmd;
    String args;
    int niceval;

    AutoRunConfig() {
      this.executable = null;
      this.numMotes = 0;
      this.logfile = null;
      this.dbgflags = null;
      this.numsec = 0;
      this.screenshot = null;
      this.stopstring = null;
      this.stopstringall = false;
      this.stopmode = STOPMODE_EXIT;
      this.pauseatstart = false;
      this.precmd = null;
      this.postcmd = null;
      this.args = null;
      this.options = new Hashtable();
      this.plugins = new Vector(1);
      this.niceval = 0;
    }

    AutoRunConfig(AutoRunConfig parent) {
      this.executable = parent.executable;
      this.numMotes = parent.numMotes;
      this.logfile = parent.logfile;
      this.dbgflags = parent.dbgflags;
      this.numsec = parent.numsec;
      this.screenshot = parent.screenshot;
      this.stopstring = parent.stopstring;
      this.stopstringall = parent.stopstringall;
      this.stopmode = parent.stopmode;
      this.pauseatstart = parent.pauseatstart;
      this.precmd = parent.precmd;
      this.postcmd = parent.postcmd;
      this.niceval = parent.niceval;
      try {
	this.options = (Hashtable)parent.options.clone();
	this.plugins = (Vector)parent.plugins.clone();
      } catch (Exception e) {
	this.options = parent.options;
	this.plugins = parent.plugins;
      }
    }
  }

  public AutoRun(SimDriver driver, String configFile) throws IOException {
    this.driver = driver;
    if (configFile != null) parseConfig(configFile);
  }

  public AutoRun(SimDriver driver, String executable, int numMotes, String args) {
    this.driver = driver;
    AutoRunConfig arc = new AutoRunConfig();
    arc.executable = executable;
    arc.numMotes = numMotes;
    arc.args = args;
    addConfig(arc);
  }

  private void addConfig(AutoRunConfig arc) {
    configs.addElement(arc);
  }

  private void parseConfig(String configFile) throws IOException {
    FileReader fr = new FileReader(configFile);
    LineNumberReader lnr = new LineNumberReader(fr);
    String line;
    AutoRunConfig arc = new AutoRunConfig();
    boolean seenkey = false;

    try {

      while ((line = lnr.readLine()) != null) {
	if (line.indexOf('#') == 0) continue;
	if (line.equals("")) {
	  if (seenkey) {
	    addConfig(arc);
	    arc = new AutoRunConfig(arc);
	    seenkey = false;
	  }
	  continue;
	}

	StringTokenizer st = new StringTokenizer(line);
	String key = st.nextToken();
	String value = st.nextToken("").substring(1);

	seenkey = true;
	if (key.equals("executable")) {
	  arc.executable = value;
	} else if (key.equals("nummotes")) {
	  arc.numMotes = Integer.parseInt(value);
	} else if (key.equals("logfile")) {
	  arc.logfile = value;
	} else if (key.equals("dbg")) {
	  arc.dbgflags = value;
	} else if (key.equals("numsec")) {
	  arc.numsec = Long.parseLong(value);
	} else if (key.equals("screenshot")) {
	  arc.screenshot = value;
	} else if (key.equals("precmd")) {
	  arc.precmd = value;
	} else if (key.equals("postcmd")) {
	  arc.postcmd = value;
	} else if (key.equals("stopstring")) {
	  arc.stopstring = value;
	} else if (key.equals("stopmode")) {
	  if (value.equals("pause")) arc.stopmode = STOPMODE_PAUSE;
	  else if (value.equals("exit")) arc.stopmode = STOPMODE_EXIT;
	  else throw new IOException("Bad value for stopmode option: "+value);
	} else if (key.equals("stopstringall")) {
	  if (value.equals("true")) arc.stopstringall = true;
	  else if (value.equals("false")) arc.stopstringall = false;
	  else throw new IOException("Bad value for stopstringall option: "+value);
	} else if (key.equals("pause")) {
	  if (value.equals("true")) arc.pauseatstart = true;
	  else if (value.equals("false")) arc.pauseatstart = false;
	  else throw new IOException("Bad value for pause option: "+value);
	} else if (key.equals("visible")) {
	  if (value.equals("true")) visible_flag = true;
	  else if (value.equals("false")) visible_flag = false;
	  else throw new IOException("Bad value for visible option: "+value);
	} else if (key.equals("plugin")) {
	  arc.plugins.addElement(value);
	} else if (key.equals("niceval")) {
	  arc.niceval = Integer.parseInt(value);
	} else {
	  arc.options.put(key, value);
	}
      }
      if (seenkey) {
	addConfig(arc);
	arc = new AutoRunConfig(arc);
      }

    } catch (Exception e) {
      e.printStackTrace();
      throw new IOException("Cannot parse configuration file: "+e);
    }
  }

  public void run() {
    arThread = new AutoRunThread();
    runThread = new Thread(arThread, "AutoRunThread");
    synchronized (runThread) {
      runThread.start();
      try {
	runThread.wait();
      } catch (InterruptedException e) {
	// Ignore
      }
    }
  }

  public void stop() {
    System.err.println("AUTORUN: Stopping simulation.");
    if (arThread != null) {
      arThread.stopProcess = true;
      try {
	runThread.interrupt();
      } catch (Exception e) {
	System.err.println("Cannot interrupt runThread: "+e);
      }
    }
  }

  public void log(String msg) {
    if (loggingPlugin != null) loggingPlugin.log(msg);
  }

  class AutoRunThread implements Runnable {
    Process simProcess;
    boolean stopProcess = false;
    boolean exited = false;

    public void run() {

      loggingPlugin = new LoggingPlugin();
      driver.getPluginManager().addPlugin(loggingPlugin);
      driver.getPluginManager().register(loggingPlugin);

      Enumeration e = configs.elements();
      while (e.hasMoreElements() /* && !timeToQuit */) {

	System.err.println("AUTORUN: Initializing simulation.");
	cur_arc = (AutoRunConfig)e.nextElement();

	/* Register all plugins that match name */
	Plugin parr[] = driver.getPluginManager().plugins();
	Enumeration pe = cur_arc.plugins.elements();
	while (pe.hasMoreElements()) {
	  String pname = (String)pe.nextElement();
	  for (int n = 0; n < parr.length; n++) {
	    if (parr[n].getClass().getName().indexOf(pname) != -1) {
	      driver.getPluginManager().register(parr[n]);
	    }
	  }
	}

        /*
         * If we're running with a GUI, need to make sure the
         * pluginpanel is up-to-date with the registrations
         */
        driver.refreshPluginRegistrations();
	
	/* Set options */
	Enumeration oe = cur_arc.options.keys();
	while (oe.hasMoreElements()) {
	  String option = (String)oe.nextElement();
	  driver.setOption(option, (String)cur_arc.options.get(option));
	}
	/* Wait for options to be processed */
	try {
	  driver.getEventBus().processAll();
	} catch (InterruptedException ie) {
	  // Ignore
	}

	/* Set up logging */
	if (cur_arc.logfile != null) {
	  try {
	    loggingPlugin.openLogfile();
	  } catch (IOException ioe) {
	    System.err.println("AUTORUN: Unable to open logfile: "+ioe);
	    return;
	  }
	}

	/* Run precmd */
	if (cur_arc.precmd != null) {
	  try {
	    System.err.println("AUTORUN: Running precmd: "+cur_arc.precmd);
	    Process precmd = Runtime.getRuntime().exec(cur_arc.precmd);
	    precmd.waitFor();
	  } catch (InterruptedException ie) {
	    // Ignore
	  } catch (Exception ex) {
	    System.err.println("AUTORUN: Unable to run precmd: "+ex);
	    return;
	  }
	}

	/* Set up command and run it */
	String cmdLine;
	if (cur_arc.niceval != 0) {
	  cmdLine = "nice -n "+cur_arc.niceval+" "+cur_arc.executable+" -gui";
	} else {
	  cmdLine = cur_arc.executable+" -gui";
	}

	if (cur_arc.numsec > 0) {
	  cmdLine += " -t="+cur_arc.numsec;
	}
	cmdLine += " -r=lossy";

        cmdLine += " -seed=" + driver.getSimRandom().getSeed();
        
        /* Sun JDK1.4.2 does not redirect or close stdout on forked
         * processes, which would cause TOSSIM to hang waiting to
         * write to stdout if we don't read from it. As such, we
         * pass the -nodbgout option to cause it to not write
         * anything to stdout.
         */
        cmdLine += " -nodbgout";
        if (cur_arc.args != null) 
          cmdLine += " "+cur_arc.args;
	cmdLine += " "+cur_arc.numMotes;
        

	String env[] = null;
	if (cur_arc.dbgflags != null) {
	  env = new String[1];
	  env[0] = "DBG="+cur_arc.dbgflags;
	}
	System.err.println("AUTORUN: Running simulation: "+cmdLine);
        
	try {
	  driver.reset();
	  simProcess = Runtime.getRuntime().exec(cmdLine, env);
	  while (driver.getSimComm().isStopped() && !stopProcess) {
	    System.err.println("AUTORUN: Connecting...");
	    Thread.currentThread().sleep(500);
	    if (driver.getSimComm().isStopped()) driver.getSimComm().start();
	    driver.getSimComm().waitUntilInit();
	  }
	  if (cur_arc.pauseatstart) {
	    System.err.println("AUTORUN: Click play to start simulation.");
	    driver.getSimComm().pause();
	  }
	} catch (Exception ex) {
	  System.err.println("AUTORUN: Unable to run simulation: "+ex);
          ex.printStackTrace();
	  return;
	}
	System.err.println("AUTORUN: Simulation running.");

	while (!stopProcess) {
	  try {
	    exited = false;
	    simProcess.waitFor();
	    System.err.println("AUTORUN: Process exited.");
	    exited = true;
	    break;
	  } catch (InterruptedException ie) {
	    continue;
	  }
	}

	System.err.println("AUTORUN: Done with run.");
	// Done running simulation
	driver.pause();
	try {
	  driver.getEventBus().processAll();
	} catch (InterruptedException ie) {
	  // Ignore
	}
	driver.refreshAndWait();

	// Capture screenshot
	if (cur_arc.screenshot != null) {
	  System.err.println("AUTORUN: Capturing screenshot to "+cur_arc.screenshot+"...");
	  try {
	    Thread.currentThread().sleep(1000);
	  } catch (InterruptedException ie) {
	    // Ignore
	  }
	  java.awt.Robot robot = null;
	  try {
	    robot = new java.awt.Robot();
	    OutputStream f = new FileOutputStream(cur_arc.screenshot);
	    java.awt.image.BufferedImage bi = robot.createScreenCapture(new java.awt.Rectangle(java.awt.Toolkit.getDefaultToolkit().getScreenSize()));
	    PngEncoder pnge = new PngEncoder(bi);
	    byte imgbytes[] = pnge.pngEncode();
	    f.write(imgbytes);
	    f.close();
	  } catch(Exception exp) {
	    System.err.println("AUTORUN: Can't capture screenshot: "+exp);
	  }
	}

	/* Run post cmd */
	if (cur_arc.postcmd != null) {
	  try {
	    System.err.println("AUTORUN: Running postcmd: "+cur_arc.postcmd);
	    Process postcmd = Runtime.getRuntime().exec(cur_arc.postcmd, env);
	    postcmd.waitFor();
	  } catch (InterruptedException ie) {
	    // Ignore
	  } catch (Exception ex) {
	    System.err.println("AUTORUN: Unable to run postcmd: "+ex);
	    return;
	  }
	}

	if (cur_arc.stopmode == STOPMODE_PAUSE && !exited) {
	  // Wait until user resumes
	  try {
	    synchronized(driver) {
	      while (driver.isPaused()) {
		driver.wait();
	      }
	    }
	  } catch (InterruptedException ie) {
	    // Just keep going
	  }
	} 

	// Sleeps are in here to give process enough time to exit and
	// SimComm enough time to reset. Probably could use better
	// synchronization.
	driver.getSimComm().stop();
	try {
	  Thread.currentThread().sleep(2000);
	} catch (InterruptedException ie) {
	  // Ignore
	}
	simProcess.destroy();
	System.err.println("AUTORUN: Destroyed process.");
	stopProcess = false;
	try {
	  Thread.currentThread().sleep(500);
	} catch (InterruptedException ie) {
	  // Ignore
	}

	try {
	  loggingPlugin.closeLogfile();
	} catch (IOException ioe) {
	  // Ignore
	}
      }

      synchronized (this) {
	this.notifyAll();
	return;
      }
    }
  }

  class LoggingPlugin extends Plugin {
    private Writer logfw = null;
    private long time_start;

    void closeLogfile() throws IOException {
      double totalsec = (System.currentTimeMillis() - time_start) / 1000.0;
      int min = (int)(totalsec / 60);
      int sec = (int)(totalsec % 60);
      if (logfw != null) {
	logfw.write("# Run ended, time elapsed: "+min+":"+sec+" min:sec\n");
	logfw.flush();
	logfw.close();
	logfw = null;
      }
    }

    void openLogfile() throws IOException {
      logfw = new BufferedWriter(new FileWriter(cur_arc.logfile));
      logfw.write("# AutoRun logfile\n");
      logfw.write("# Executable: "+cur_arc.executable+"\n");
      logfw.write("# Num motes: "+cur_arc.numMotes+"\n");
      logfw.write("# DBG flags: "+cur_arc.dbgflags+"\n");
      logfw.write("# Total sec: "+cur_arc.numsec+"\n");
      logfw.write("# Stop string: "+cur_arc.stopstring+"\n");
      Enumeration e = cur_arc.options.keys();
      while (e.hasMoreElements()) {
	String key = (String)e.nextElement();
	logfw.write("# Option "+key+": "+cur_arc.options.get(e)+"\n");
      }
      e = cur_arc.plugins.elements();
      while (e.hasMoreElements()) {
	String plugin = (String)e.nextElement();
	logfw.write("# Plugin: "+plugin+"\n");
      }
      logfw.write("#\n");
      logfw.write("# Format: <mote> <time> <data>\n");
      time_start = System.currentTimeMillis();
    }

    public void register() {}
    public void deregister() {}
    public void reset() {}

    public String toString() {
      return "AutoRun logger (do not disable)";
    }

    private synchronized void log(String msg) {
      if (logfw == null) return;
      String logs = "NONE NONE "+msg.replace('\n', ' ')+"\n";
      try {
	logfw.write(logs);
      } catch (IOException ioe) {
	System.err.println("AUTORUN: Cannot log message");
      }
      if (cur_arc.stopstring != null && 
	msg.indexOf(cur_arc.stopstring) != -1) {
	if (!cur_arc.stopstringall ||
	    ++stopstringall_count == cur_arc.numMotes) {
	  try {
	    logfw.write("# Stopping due to match of stopstring: " +
                        cur_arc.stopstring+"\n");
	  } catch (IOException ioe2) {
	    // Ignore
	  }
	  stopstringall_count = 0;
	  stop();
	}
      }
    }

    private synchronized void log(SimEvent event) {
      if (logfw == null) return;
      String logs;
      if (event instanceof TossimEvent) {
	TossimEvent tev = (TossimEvent)event;
	logs = tev.getMoteID()+" "+tev.getTime();
	logs = logs+" "+event.toString().replace('\n', ' ')+"\n";
      } else {
	logs = "NONE NONE "+event.toString().replace('\n', ' ')+"\n";
      }
      try {
	logfw.write(logs);
      } catch (IOException ioe) {
	System.err.println("AUTORUN: Cannot log message");
      }
      if (cur_arc.stopstring != null && 
	event.toString().indexOf(cur_arc.stopstring) != -1) {
	if (!cur_arc.stopstringall ||
	    ++stopstringall_count == cur_arc.numMotes) {
	  try {
	    logfw.write("# Stopping due to match of stopstring: " +
                        cur_arc.stopstring+"\n");
	  } catch (IOException ioe2) {
	    // Ignore
	  }
	  stopstringall_count = 0;
	  stop();
	}
      }
    }

    public void handleEvent(SimEvent event) {
      log(event);
    }
  }
}
