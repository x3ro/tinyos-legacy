
package net.tinyos.sim.script.reflect;

import net.tinyos.sim.Plugin;
import net.tinyos.sim.PluginManager;
import net.tinyos.sim.SimDriver;
import net.tinyos.sim.event.DebugMsgEvent;
import net.tinyos.sim.event.SimEvent;
import net.tinyos.sim.script.ScriptInterpreter;

import java.io.*;
import java.util.StringTokenizer;


public class Sim extends SimReflect {
  public SimDriver __driver;
  
  public int argc = 0;
  public String[] argv = null;
  
  private DBGDumpPlugin plugin = null;
  
  public Sim(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);

    __driver = driver; // back door

    // set up argv
    if (driver.getScriptArgs() != null) {
      StringTokenizer t = new StringTokenizer(driver.getScriptArgs());
      argc = t.countTokens();
      argv = new String[argc];
      for (int i = 0; i < argc; ++i) {
        argv[i] = t.nextToken();
      }
    }
  }

  public void pause()  { driver.pause(); }
  public void resume() { driver.resume(); }
  public void stop()   { driver.stop(); }

  public long getTossimTime() {
    return driver.getTossimTime();
  }

  public void exit(int errcode) {
    driver.exit(errcode);
  }
    
  public void setSimDelay(long delay_ms) {
    driver.setSimDelay(delay_ms);
  }

  public void dumpDBG(String filename) throws IOException {
    if (plugin != null) {
      throw new IOException("Already dumping DBG output.");
    }
    
    File file = new File(filename);
    if (file.exists()) {
      throw new IOException("File " + filename + " already exists.");
    }
    FileWriter writer = new FileWriter(file);
    plugin = new DBGDumpPlugin(writer);
    driver.getPluginManager().register(plugin);
  }

  public void stopDBGDump() throws IOException {
    if (plugin == null) {throw new IOException("Not dumping debug output.");}
    else {
      driver.getPluginManager().deregister(plugin);
      plugin.finish();
      plugin = null;
    }
  }
  
  private class DBGDumpPlugin extends Plugin {
    private Writer writer;

    public DBGDumpPlugin(Writer writer) {
      this.writer = writer;
    }

    public void handleEvent(SimEvent e) {
      if (e instanceof DebugMsgEvent) {
	try {
	  DebugMsgEvent dme = (DebugMsgEvent)e;
	  writer.write(dme.getMessage() + "\n");
	}
	catch (Exception exception){
	  System.err.println(exception);
	}
      }
    }

    public void finish() {
      try {
	writer.close();
      }
      catch (IOException e) {}
    }
  }
}
