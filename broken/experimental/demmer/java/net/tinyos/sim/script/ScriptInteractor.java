  
package net.tinyos.sim.script;

import net.tinyos.sim.*;

import java.io.*;
import java.net.*;
import java.util.*;

import org.python.util.PythonInterpreter;
import org.python.core.*;

public class ScriptInteractor implements SimConst {
  protected SimDebug debug = SimDebug.get("script");

  protected SimDriver driver;

  protected ServerSocket serverSock;
  protected AcceptThread acceptThread = new AcceptThread();
  protected Vector sessions = new Vector();

  public ScriptInteractor(SimDriver driver) {
    this.driver = driver;
  }
  
  public void startConsole(InputStream input, OutputStream output) {
    Session session = new Session(input, output);
    addSession(session);
    session.start();
  }
  
  public void startListenSocket(int port) {
    try {
      serverSock = new ServerSocket(port);
      
    } catch (IOException e) {
      System.err.println("Error binding listen socket to " + port);
      return;
    }
    acceptThread.start();
  }

  class AcceptThread extends Thread {

    public AcceptThread() {
      super("ScriptInteractor::AcceptThread");
    }


    public void run() {
      debug.err.println("SCRIPT: Starting accept thread...");
      while (true) {
        Socket socket = null;
        try {
          socket = serverSock.accept();

          Session session = new Session(socket);
          addSession(session);
          session.start();
          
        } catch (IOException e) {
          System.err.println("error creating session socket " + e);
        }
      }
    }
  }

  protected synchronized void addSession(Session session) {
    debug.err.println("SCRIPT: adding session ("+session+")"); 
   sessions.add(session);
  }

  protected synchronized void removeSession(Session session) {
    debug.err.println("SCRIPT: removing session ("+session+")");
    sessions.remove(session);
  }

  class Session extends Thread {
    protected Socket socket;
    protected BufferedReader input;
    protected PrintWriter output;
    protected ScriptInterpreter interp;

    Session(InputStream inputStream, OutputStream outputStream) {
      super("ScriptInterpreter::Session");
      this.interp = new ScriptInterpreter(driver);
      interp.setOut(outputStream);
      interp.setErr(outputStream);
      this.input = new BufferedReader(new InputStreamReader(inputStream));
      this.output = new PrintWriter(outputStream);
    }
    
    Session(Socket socket) throws IOException {
      this(socket.getInputStream(), socket.getOutputStream());
      this.socket = socket;
    }

    protected String ps1 = new String(">>> ");
    protected String ps2 = new String("... ");

    public void run() {
      try {
        StringBuffer buffer = new StringBuffer();
        
        String line;
        String script;
        boolean more = false;

        output.write("\n\nWelcome to Tython. Type 'quit' to exit.\n" +
                     "ESC on a line by itself will pause/resume the simulator.\n\n");
        
        while (true) {
          String prompt = more ? ps2 : ps1;
          
          output.write(prompt);
          output.flush();

          line = input.readLine();
          if (line == null) {
            removeSession(this);
            return; // eof
          }

          if (buffer.length() > 0)
            buffer.append("\n");
          buffer.append(line);

          script = buffer.toString();

          // Special case the "quit" line
          if (script.compareTo("quit") == 0) {
            break;
          }

          if (script.length() == 1 && (int)script.charAt(0) == 27) {
            if (! driver.isPaused()) {
              output.write("Pausing due to ESC character\n");
              driver.pause();
            } else {
              output.write("Resuming due to ESC character\n");
              driver.resume();
            }
            buffer.setLength(0);
            continue;
          }
          
          more = interp.runsource(script);
          if (!more)
            buffer.setLength(0);
        }
        
        output.write("Session ended.\n");
        output.flush();

      } catch (IOException e) {
        // Don't know what happened, but just bail
      }

      if (socket != null) {
        try {
          socket.close();
        } catch (IOException e) {}
      }
      
      removeSession(this);
    }

    public String toString() {
      if (socket == null) {
        return "console";
      }
      
      return "" + socket.getInetAddress() + ":" + socket.getPort();
    }
  }
}
