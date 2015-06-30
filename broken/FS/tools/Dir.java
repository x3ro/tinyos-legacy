package tools;

import java.util.*;

class Dir {
    Comm comm;

    Dir() {
	comm = new Comm();
	comm.start();
    }

    public static void main(String[] argv) {
	boolean free = false;

	if (argv.length >= 1 && argv[0].equals("-f"))
	    free = true;

	new Dir().readDirectory(free);
	System.exit(0);
    }

    static long getSize(FSReplyMsg msg) {
	return
	    msg.getElement_data(0) |
	    msg.getElement_data(1) << 8 |
	    msg.getElement_data(2) << 16 |
	    msg.getElement_data(3) << 24L;
    }

    void readDirectory(boolean showFree) {
	Vector files = new Vector();

	comm.checkedSend(new Op(FS.FSOP_DIR_START));

	for (;;) {
	    FSReplyMsg reply = comm.send(new Op(FS.FSOP_DIR_READNEXT));

	    switch (reply.get_result()) {
	    case FS.FS_NO_MORE_FILES:
		printFiles(files, showFree);
		if (showFree) {
		    FSReplyMsg free = comm.checkedSend(new Op(FS.FSOP_FREE_SPACE));

		    System.out.println("" + getSize(free) + " bytes free");
		}

		return;
	    case FS.FS_OK:
		files.add(reply.getString_data());
		break;
	    default:
		comm.check(reply);
		break;
	    }
	}
    }

    void printFiles(Vector files, boolean showSize) {
	Enumeration elems = files.elements();

	while (elems.hasMoreElements()) {
	    String fname = (String)elems.nextElement();

	    System.out.print(fname);
	    if (showSize) {
		comm.checkedSend(new Op(FS.FSOP_READ_OPEN).argString(fname));
		FSReplyMsg size = comm.checkedSend(new Op(FS.FSOP_READ_REMAINING));
		System.out.print(" " + getSize(size));
		comm.checkedSend(new Op(FS.FSOP_READ_CLOSE));
	    }
	    System.out.println();
	}
    }
}
