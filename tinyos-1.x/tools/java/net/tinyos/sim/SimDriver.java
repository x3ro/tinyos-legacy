// $Id: SimDriver.java,v 1.15 2004/06/11 21:30:14 mikedemmer Exp $

/*
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
 * Desc:        Main simulation driver
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim;

import net.tinyos.sim.event.*;
import net.tinyos.sim.script.*;
import net.tinyos.sim.plugins.*;
import java.io.*;
import java.util.*;
import java.net.URL;

public class SimDriver {
  protected SimDebug debug = SimDebug.get("driver");

  protected TinyViz tv;
  protected AutoRun autoRun;
  protected SimState simState;
  protected SimComm simComm;
  protected SimCommands simCommands;
  protected SimExec simExec;
  protected SimEventBus simEventBus;
  protected SimRandom simRandom;
  protected MoteVariables moteVariables;
  protected PluginManager pluginManager;
  protected ScriptInterpreter interp;
  protected ScriptInteractor interactor;
  protected RadioModelPlugin radioModel;
  protected MoteLayoutPlugin moteLayout;
  protected PacketLoggerPlugin packets;
  protected String scriptPath = null;
  protected String scriptArgs = null;
  protected int pauseCount = 0;
  protected long tossimTime = 0;
  protected Hashtable options = new Hashtable();
  protected long randomSeed;

  private void help(String error) {
    if (error != null) {
      System.err.println("Error parsing arguments: " + error + "\n");
    }
    System.err.println("SimDriver: Usage:");
    System.err.println("   java net.tinyos.sim.SimDriver [options] script");
    System.err.println("Options:");
    System.err.println("   -help\n\tPrint this help");
    System.err.println("   -gui\n\tRun the TinyViz GUI");
    System.err.println("   -noconsole\n\tDo not run a python interpreter console");
    System.err.println("   -listen <port>\n\t" +
                       "Listen for telnet connections and spawn an interpreter");
    System.err.println("   -run <executable> <nummotes>\n\tRun simulation");
    System.err.println("   -autorun <config>\n\tRun in batch mode");
    System.err.println("   -simargs <args>\n\tSimulator arguments");
    System.err.println("   -script <script file>\n\tRun Python Script");
    System.err.println("   -scriptargs <args>\n\tPython script arguments");
    System.err.println("   -nosf\n\tDo not start SerialForwarder");
    System.err.println("   -nopause\n\tDo not pause the simulator at init time");
    System.err.println("   -plugins [path]\n\tSpecify colon-delimited " +
                       "directories to search for plugin classes");
    System.err.println("   -scriptpath [path]\n\tDitto to search for scripts");
    System.err.println("   -nolaf\n\tUse default look and feel (ugly!)");
    System.err.println("   -echodbg\n\tPrint out TOSSIM debug messages"); 
    System.err.println("   -seed <seed>\n\tSet random number generator seed");
    System.err.println("   <name=value>\n\tSet name=value plugin options");
    System.err.println("");
    System.err.println("Known SIMDBG modes: " + SimDebug.listAllModes());
    System.exit(1);
  }

  public SimDriver(String initargs[]) {
    /* Parse options */
    boolean gui = false;
    boolean console = true;
    int listen_port = -1;
    String plugin_path = null;
    String autorun_exec = null;
    int autorun_nummotes = 1;
    String autorun_config = null;
    String autorun_args = null;
    String simargs = null;
    String script = null;
    boolean lookandfeel = true;
    boolean run_serial_forward = true;
    boolean pause_on_init = true;
    boolean echo_dbg = false;
    boolean seed_set = false;

    try {
      for (int n = 0; n < initargs.length; n++) {
	if (initargs[n].equals("-help") || initargs[n].equals("-h")) {
	  help(null);

        } else if (initargs[n].equals("-gui")) {
          gui = true;
        
        } else if (initargs[n].equals("-noconsole")) {
          console = false;
        
        } else if (initargs[n].equals("-listen")) {
          listen_port = Integer.parseInt(initargs[n+1]); n++;
        
	} else if (initargs[n].equals("-plugins")) {
	  plugin_path = initargs[n+1]; n++;

	} else if (initargs[n].equals("-scriptpath")) {
	  scriptPath = initargs[n+1]; n++;

	} else if (initargs[n].equals("-run")) {
	  autorun_exec = initargs[n+1];
	  autorun_nummotes = Integer.parseInt(initargs[n+2]);
	  n += 2;

	} else if (initargs[n].equals("-autorun")) {
	  autorun_config = initargs[n+1]; n++;
          
        } else if (initargs[n].equals("-simargs")) {
	  simargs = initargs[n + 1]; n++;
          
        } else if (initargs[n].equals("-script")) {
	  script = initargs[n + 1]; n++;

        } else if (initargs[n].equals("-scriptargs")) {
	  scriptArgs = initargs[n + 1]; n++;
          
	} else if (initargs[n].equals("-nolaf")) {
	  lookandfeel = false;

        } else if (initargs[n].equals("-nosf")) {
	  run_serial_forward = false;

        } else if (initargs[n].equals("-nopause")) {
	  pause_on_init = false;

        } else if (initargs[n].equals("-echodbg")) {
	  echo_dbg = true;

        } else if (initargs[n].equals("-seed")) {
	  seed_set = true;
          randomSeed = Integer.parseInt(initargs[n + 1]); n++;
          
	} else if (initargs[n].indexOf('-') != 0 && 
		   initargs[n].indexOf('=') != 0) {
	  StringTokenizer st = new StringTokenizer(initargs[n],"=");
	  String optionName = st.nextToken();
	  String optionValue = st.nextToken();
	  if (optionName == null || optionValue == null) {
	    help("invalid option syntax -- must specify both name and value");
	  }
	  setOption(optionName, optionValue);

	} else {
	  help("unrecognized option: "+initargs[n]);
	}
      }
    } catch (Exception e) {
      e.printStackTrace();
      help("got exception parsing arguments: " + e);
      return;
    }

    /* Do option validation */
    if (autorun_exec != null && autorun_config != null)
      help("cannot use -run and -autorun together");

    if (script != null && autorun_exec != null)
      help("cannot use -run and -script together");

    if (script != null && autorun_config != null)
      help("cannot use -autorun and -script together");
    
    if (gui == false && lookandfeel == false)
      help("-nolaf is meaningless without -gui");

    if (script != null) {
      try {
        FileInputStream file = new FileInputStream(script);
      } catch (FileNotFoundException e) {
        help("can't read script file " + script);
      }
    }

    /* First of all, seed and create the random number generator */
    if (!seed_set) {
      Random getSeed = new Random();
      randomSeed = getSeed.nextInt();
      if (randomSeed < 0)
        randomSeed = -randomSeed;
    }
    simRandom = new SimRandom(randomSeed);
    System.out.println("Simulation random seed " + randomSeed);

    /* Create the core sim driver objects */
    if (autorun_exec != null) {
      autoRun = new AutoRun(this, autorun_exec, autorun_nummotes, simargs);
      
    } else if (autorun_config != null) {
      try {
        autoRun = new AutoRun(this, autorun_config);
      } catch (IOException e) {
        System.err.println("Error parsing autorun config. Exiting");
        exit(1);
      }
    }

    System.out.println("Initializing simulator objects...");
    simEventBus = new SimEventBus(this);
    simState = new SimState(this);

    simComm = new SimComm(this, run_serial_forward, pause_on_init);
    simCommands = new SimCommands(this);
    simExec = new SimExec(this);
    moteVariables = new MoteVariables(this);
    
    /*
     * Handle plugins
     */
    System.out.println("Loading simulator plugins...");
    pluginManager = new PluginManager(this);
    pluginManager.loadPlugins(plugin_path);
    radioModel = (RadioModelPlugin)pluginManager.getPlugin("RadioModelPlugin");
    moteLayout = (MoteLayoutPlugin)pluginManager.getPlugin("MoteLayoutPlugin");
    packets = (PacketLoggerPlugin)pluginManager.getPlugin("PacketLoggerPlugin");

    pluginManager.register(radioModel);
    pluginManager.register(moteLayout);
    pluginManager.register(packets);

    /*
     * A plugin to keep track of the tossim time.
     */
    Plugin p;
    p = new TimeUpdatePlugin();
    pluginManager.addPlugin(p);
    pluginManager.register(p);
		
    /*
     * And one to echo debug message output, if requested.
     */
    if (echo_dbg) {
      p = new EchoDebugPlugin();
      pluginManager.addPlugin(p);
      pluginManager.register(p);
    }

    /* Now create the gui if requested */
    if (gui) {
      System.out.println("Creating TinyViz GUI...");
      tv = new TinyViz(this, lookandfeel);
    }

    /*
     * If the scriptPath wasn't specified, cons up a relatively useful
     * default and add on the builtin scripts and libraries.
     */
    if (scriptPath == null) {
      scriptPath = ".";
    }

    String pathsep = System.getProperty("path.separator");
    if (pathsep == null) pathsep = ":";
    
    String filesep = System.getProperty("file.separator");
    if (filesep == null) filesep = "/'";
    
    /*
     * Ugh -- go through pains to make sure this doesn't crash if it
     * can't find the directory. But if it can, try to add on the
     * pyscripts directory and the
     */
    URL builtinURL = getClass().getResource("pyscripts");
    if (builtinURL != null && builtinURL.getProtocol().equals("file")) {
      String builtinPath = builtinURL.getPath();
      String libPath = builtinPath + filesep + "Lib.jar";

      scriptPath += pathsep + builtinPath + pathsep + libPath;
    }

    /*
     * Always run the event bus.
     */
    simEventBus.start();
    
    /*
     * Try to connect to the simulator
     */
    simComm.start();
    if (gui) {
      tv.refreshPauseState();
    }

    /*
     * If there's a script, implicitly tack its directory onto the
     * scriptPath and create an interpreter for it.
     */
    if (script != null) {
      System.out.println("DRIVER: creating interpreter for script: "
                         + script + "...");
      
      int lastSlash = script.lastIndexOf(filesep);
      if (lastSlash != -1) {
        String scriptDir = script.substring(0, lastSlash);
        scriptPath = scriptPath + pathsep + scriptDir;
      }
      
      interp = new ScriptInterpreter(this, script);
    }

    /*
     * Create a console and/or a listen socket for interactive script
     * sessions.
     */
    if (console || listen_port > 0) {
      interactor = new ScriptInteractor(this);

      if (listen_port > 0) {
        interactor.startListenSocket(listen_port);
      }

      if (console) {
        interactor.startConsole(System.in, System.out);
      }
    }

    /*
     * Finally, run the simulator if we're using -run.
     */
    if (autoRun != null) {
      if (! simComm.isStopped()) {
        System.err.println("DRIVER: Can't use AutoRun when SimComm already connected");
        System.err.println("(check for stale main.exe processes)");
        System.exit(1);
      }
      autoRun.run();
      exit(0);
    }
  }

  public final AutoRun getAutoRun() {
    return autoRun;
  }
  
  public final SimComm getSimComm() {
    return simComm;
  }

  public final SimCommands getSimCommands() {
    return simCommands;
  }

  public final SimRandom getSimRandom() {
    return simRandom;
  }

  public final SimExec getSimExec() {
    return simExec;
  }

  public final SimState getSimState() {
    return simState;
  }

  public final SimEventBus getEventBus() {
    return simEventBus;
  }

  public final MoteVariables getVariables() {
    return moteVariables;
  }

  public final PluginManager getPluginManager() {
    return pluginManager;
  }

  public final RadioModelPlugin getRadioModel() {
    return radioModel;
  }

  public final MoteLayoutPlugin getMoteLayout() {
    return moteLayout;
  }

  public final PacketLoggerPlugin getPacketLogger() {
    return packets;
  }

  public final String getScriptPath() {
    return scriptPath;
  }
  
  public final String getScriptArgs() {
    return scriptArgs;
  }

  public final long getTossimTime() {
    return tossimTime;
  }
  
  public final synchronized void pause() {
    pauseCount++;
    debug.err.println("PAUSE: "+pauseCount);
    if (pauseCount == 1) {
      simComm.pause();
      refreshPauseState();
      this.notifyAll();
    }
  }

  public final synchronized void resume() {
    pauseCount--;
    debug.err.println("RESUME: "+pauseCount);
    if (pauseCount <= 0) {
      pauseCount = 0;
      simComm.resume();
      refreshPauseState();
      this.notifyAll();
    }
  }

  public synchronized void reset() {
    simComm.stop();
    refreshPauseState();
    simEventBus.pause();
    simEventBus.clear();
    simState.removeAllObjects();
    refreshAndWait();
    pluginManager.reset();
    simComm.start();
    refreshPauseState();
    simEventBus.resume();
    this.notifyAll();
  }

  public synchronized void stop() {
    if (autoRun != null) autoRun.stop();
    if (simExec != null) simExec.stop();
  }

  public final synchronized boolean isPaused() {
    return simComm.isPaused();
  }
  
  public final void setSimDelay(long delay_ms) {
    simComm.setSimDelay(delay_ms);
  }

  public final void connect() {
    while (simComm.isStopped() && simExec.processRunning()) {
      try {
        if (simComm.isStopped()) simComm.start();
        simComm.waitUntilInit();
        Thread.currentThread().sleep(500);
      } catch (InterruptedException ie) {
        continue;
      }
    }
  }

  public final void exit(int errcode) {
    System.err.println("Goodbye!");
    if (simComm != null) simComm.stop();
    if (autoRun != null) autoRun.stop();
    if (simExec != null) simExec.stop();
    System.exit(errcode);
  }

  public final String getOption(String optionName) {
    return (String)options.get(optionName);
  }
  
  public final void setOption(String optionName, String optionVal) {
    options.put(optionName, optionVal);
    if (simEventBus != null) 
      simEventBus.addEvent(
        new net.tinyos.sim.event.OptionSetEvent(optionName, optionVal));
  }

  public final Enumeration getOptions() {
    return options.keys();
  }

  // Callbacks to update to status changes
  public void refreshAndWait() {
    if (tv != null) tv.refreshAndWait();
  }
    
  public void refreshPauseState() {
    if (tv != null) tv.refreshPauseState();
  }
  
  public void setStatus(String s) {
    if (tv != null) tv.setStatus(s);
    else System.out.println("status: "+s);
  }
  
  public void refreshPluginRegistrations() {
    if (tv != null) tv.refreshPluginRegistrations();
  }

  public void refreshMotePanel() {
    if (tv != null) tv.getMotePanel().refresh();
  }
  
  public static void main(String[] args) throws IOException {
    System.err.println("Starting SimDriver... ");
    new SimDriver(args);
  }

  class EchoDebugPlugin extends Plugin {
    public void handleEvent(SimEvent event) {
      if (event instanceof DebugMsgEvent) {
        System.out.println(((DebugMsgEvent)event).getMessage());
      }
    }
  }

  class TimeUpdatePlugin extends Plugin {
    public void handleEvent(SimEvent event) {
      if (event instanceof TossimEvent) {
        TossimEvent te = (TossimEvent)event;
        tossimTime = te.getTime();
        
        if (tv != null) {
          String time= Double.toString(Math.round(tossimTime/4000.0)/1000.0);
          if(time.length()<2) time=time.concat(".");
          while (time.length()-time.indexOf(".")<4) time=time.concat("0");
          tv.timeUpdate(time);
        }
      }
    };
  }
}
