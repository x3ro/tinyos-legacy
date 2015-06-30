package tools;

import java.io.*;

class Rename {
    Comm comm;

    Rename() {
	comm = new Comm();
	comm.start();
    }

    public static void main(String[] argv) {
	if (argv.length != 2) {
	    System.err.println("usage: java tools.Rename from to");
	    System.err.println("  renames matchbox file named 'from' to 'to'");
	    System.exit(2);
	}
	new Rename().exec(argv[0], argv[1]);
	System.exit(0);
    }

    void exec(String from, String to) {
	comm.checkedSend(new Op(FS.FSOP_RENAME).
	    argString(from).argString(to));
    }
}
