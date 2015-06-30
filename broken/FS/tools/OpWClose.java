package tools;

import java.io.*;

class OpWClose {
    public static void main(String[] argv) {
	Comm comm = new Comm();
	comm.checkedSend(new Op(FS.FSOP_WRITE_CLOSE));
	System.exit(0);
    }
}
