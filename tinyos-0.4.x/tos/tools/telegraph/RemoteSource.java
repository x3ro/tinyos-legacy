import java.io.*;
import java.net.*;
import java.util.*;


/**
   The RemoteSource class is used by clients of the telegraph server
   to add sources to telegraph. <p>
   <p>
   It basically provides a simple remote interface to the Telegraph Catalog.

   @author Sam Madden <a href="mailto:madden@cs.berkeley.edu"></a>
*/
public class RemoteSource {
    static final int COMMAND_ADD_SOURCE = 3;

    /**
	Add a source to a remote telegraph server
	@param server The address of the server to add the source to (assume the server is running on port SERVER_PORT
	@param timeout Time to wait before giving up on the server (0 == wait forever)
	@param fieldNames Vector of Strings; the names of the fields which are contained in the fields vector 
	       (fieldNames.size() must == fields.size())
	@param fields Vector of Strings; the values of the fields in the new source
	@param columns Vector of Vectors of Strings, each containing (name, type, description) triplets
	@throws IOException io server can't be contacted
	@throws ArrayIndexOutOfBoundsException If fieldNames.size() != fields.size(), or columns[i].size() != 3 forall i
    */
    public static void RemoteAddSource(InetAddress server, int timeout, Vector fieldNames, Vector fields, Vector columns) 
	throws IOException, ArrayIndexOutOfBoundsException 
    {
	Socket sock;
	final int SERVER_PORT=2005;
	String s;
	BufferedWriter outs;

	if (fieldNames.size() != fields.size()) {
	    throw new ArrayIndexOutOfBoundsException("fieldNames.size() != fields.size()");
	}

	sock = new Socket(server, SERVER_PORT);

	outs = new BufferedWriter(new OutputStreamWriter(sock.getOutputStream()));
    /*
      Command format according to Telegraph.java :
	COMMAND_ADD_SOURCE\n
	[table field name]:[table field value]\n
	...
	[table field name]:[table field value];\n
	[col 1 name],[col 1 type],[col 1 desc]\n
	...
	[col n name],[col n type],[col n desc]
    */
	//build the command
	s = COMMAND_ADD_SOURCE + "\n";
	//add each field
	for (int i = 0; i < fields.size(); i++) {
	    s += (String)fieldNames.elementAt(i) + ":" + fields.elementAt(i);
	    if (i == fields.size() - 1) s += ";";
	    s += "\n";
	}

	//add each column
	for (int i = 0; i < columns.size(); i++) {
	    Vector col = (Vector)columns.elementAt(i);
	    if (col.size() != 3) {
		throw new ArrayIndexOutOfBoundsException("col " + i + " size != 3");
	    }
	    s += (String)col.elementAt(0) + "," + (String)col.elementAt(1) + "," + (String)col.elementAt(2);
	    if (i != columns.size() - 1) 
		s += "\n";
	}
	//write the command
	System.out.println("writing command : " + s);
	outs.write(s);
	outs.flush();
	System.out.println("Add Sources.");

	outs.close();
    }


}
