import java.io.*;
import net.tinyos.util.*;

class Spawn extends Thread {
    public static void main(String[] args) {
	Spawn s = new Spawn(PrintStreamMessenger.out);

	s.startMotlle();
	for (int i = 0; i < args.length; i++)
	    s.exec(args[i]);
	s.mwait();
	System.exit(0);
    }

    Process motlle;
    Messenger output;

    Spawn(Messenger m) {
	output = m;
    }

    void startMotlle() {
	try {
	    motlle = Runtime.getRuntime().exec("./motlle");
	    start();
	}
	catch (IOException e) {
	    fail("Couldn't start motlle");
	}
    }

    void fail(String cause) {
	System.err.println(cause);
	System.exit(2);
    }

    void mwait() {
	try {
	    motlle.waitFor();
	}
	catch (InterruptedException e) { }
    }

    public void run() {
	InputStream motlleOutput = motlle.getInputStream();

	try {
	    for (;;) {
		int count = motlleOutput.available();

		if (count < 1)
		    count = 1;
		// efficiency? what efficiency?
		byte[] out = new byte[count];
		int actual = motlleOutput.read(out);

		if (actual > 0) {
		    output.message(new String(out, 0, actual));
		}
	    }
	}
	catch (IOException e) {
	    fail("Error reading motlle output");
	}
    }

    void exec(String s) {
	DataOutputStream motlleInput = new DataOutputStream(motlle.getOutputStream());

	try {
	    output.message(s + "\n");
	    motlleInput.writeBytes(s);
	    motlleInput.writeBytes("\n");
	    motlleInput.flush();
	}
	catch (IOException e) {
	    fail("Error sending commands to motlle");
	}
    }
}
