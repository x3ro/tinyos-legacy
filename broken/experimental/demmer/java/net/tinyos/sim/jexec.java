
package net.tinyos.sim;

import java.io.*;
import java.lang.*;

class PipeThread extends Thread implements Runnable {
  InputStream in = null;
  OutputStream out = null;    
    
  PipeThread(InputStream in, OutputStream out) {
    super("PipeThread");
    this.in = in;
    this.out = out;
  }
      
  public void run() {
    byte[] buf = new byte[512];
    int cnt;

    try { 
      for(;;) {
	cnt = in.read(buf);
	if (cnt == -1) { return; }
	out.write(buf, 0, cnt);
      }
    } catch (Exception e) {
      // ignore??
      e.printStackTrace();
    }
  }
}

public class jexec {
  public static void main(String[] args) {
    try {
      Runtime rt = Runtime.getRuntime();
      Process process = rt.exec(args);
      PipeThread t = new PipeThread(process.getInputStream(), System.out);
      t.start();
      process.waitFor();

    } catch (Exception e) {
      // ignore?
      e.printStackTrace();
    }
  }
}
