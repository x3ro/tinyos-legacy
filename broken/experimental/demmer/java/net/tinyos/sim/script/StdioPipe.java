
package net.tinyos.sim.script;

import java.io.*;

public class StdioPipe implements Runnable {
  Thread thread;
  InputStream in;
  OutputStream out;
  
  public StdioPipe(InputStream in, OutputStream out) {
    in  = new BufferedInputStream(in);
    out = new BufferedOutputStream(out);
    
    thread = new Thread(this, "StdioPipeThread");
    thread.run();
  }

  public void run() {
    System.err.println("pipe running");

    int c;
  }
}
