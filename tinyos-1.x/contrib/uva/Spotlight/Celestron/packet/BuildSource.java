// $Id: BuildSource.java,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package packet;

import net.tinyos.util.*;
import net.tinyos.packet.*;

/**
 * This class is where packet-sources are created. It also provides 
 * convenient shortcuts for building PhoenixSources on packet-sources.
 *
 * See PacketSource and PhoenixSource for details on the source behaviours.
 *
 * Most applications will probably use net.tinyos.message.MoteIF with
 * the default source, but those that don't must use BuildSource to obtain
 * a PacketSource.
 *
 * The default source is specified by the MOTECOM environment variable
 * (note that the JNI code for net.tinyos.util.Env must be installed for
 * this to work - see net/tinyos/util/Env.INSTALL for details). When
 * MOTECOM is undefined (or the JNI code for Env.java cannot be found), the
 * packet source is "sf@localhost:9001" (new serial-forwarder, on localhost
 * port 9001).
 *
 * Packet sources can either be specified by strings (when calling
 * <code>makePacketSource</code>, or by calling a specific makeXXX method
 * (e.g., <code>makeSF</code>, <code>makeSerial</code>). There are also
 * makeArgsXXX methods which make a source from its source-args (see below).
 *
 * Packet source strings have the format: <source-name>[@<source-args>],
 * where source-args have reasonable defaults for most sources.
 * The <code>sourceHelp</code> method prints an up-to-date description
 * of known sources and their arguments.
 */
public class BuildSource {

    /**
     * Make the default packet source
     * @return The packet source, or null if it could not be made
     */
    SerialByteSource  SBS = null;
    
    public  PacketSource makePacketSource() {
	return makePacketSource(Env.getenv("MOTECOM"));
    }

    /**
     * Make the specified packet source
     * @param name Name of the packet source, or null for "sf@localhost:9001"
     * @return The packet source, or null if it could not be made
     */
    public  PacketSource makePacketSource(String name) {
	if (name == null)
	    name = "sf@localhost:9001"; // default source

		ParseArgs parser = new ParseArgs(name, "@");
		String source = parser.next();
		String args = parser.next();

	   if (source.equals("serial"))
	    return makeArgsSerial(args);
	    
		return null;
    }


    private static int decodeBaudrate(String rate) {
	if (rate == null)
	    return 19200;
	if (rate.equals("rene"))
	    return 19200;
	if (rate.equals("mica"))
	    return 19200;
	if (rate.equals("mica2"))
	    return 57600;
	if (rate.equals("mica2dot"))
	    return 19200;
	return Integer.parseInt(rate);
    }

    /**
     * Make a serial-port packet source. Serial packet sources report
     * missing acknowledgements via a false result to writePacket.
     * @param args "COMn[:baudrate]" ("COM1" if args is null)
     *   baudrate is an integer or mote name (rene, mica, mica2, mica2dot).
     *   The default baudrate is 19200.
     * @return The new packet source, or null if the arguments are invalid
     */
    public PacketSource makeArgsSerial(String args) {
	if (args == null)
	    args = "COM1";

	ParseArgs parser = new ParseArgs(args, ":");
	String port = parser.next();
	int baudrate = decodeBaudrate(parser.next());

	return makeSerial(port, baudrate);
    }

    /**
     * Make a serial-port packet source. Serial packet sources report
     * missing acknowledgements via a false result to writePacket.
     * @param port javax.comm serial port name ("COMn:")
     * @param baudrate requested baudrate
     * @return The new packet source
     */ 
   public PacketSource makeSerial(String port, int baudrate) {
   	System.out.println("MakeSerial Now)");
   	SBS = new packet.SerialByteSource(port, baudrate);
		return new packet.Packetizer("serial@" + port + ":" + baudrate,
			      SBS);
    }
    
    public packet.SerialByteSource getSerialByteSource(){
    	return SBS;
    }
    
    /**
     * Parse a string into tokens based on a sequence of delimiters
     * Given delimiters (single characters) d1, d2, ..., dn, this
     * class recognises strings of the form s0[d1s1][d2s2]...[dnsn],
     * where s<i-1> does not contain character di
     * This is unambiguous if all di are distinct. If not, strings
     * are attributed to the earliest possible si (so if the delimiters
     * are : and :, and the input string is foo:bar, then s0 is foo,
     * s1 is bar and s2 is null
     */
    static class ParseArgs {
	String tokens[];
	int tokenIndex;

	ParseArgs(String s, String delimiterSequence) {
	    int count = delimiterSequence.length();
	    tokens = new String[count + 1];
	    tokenIndex = 0;

	    // Fill in the tokens
	    int i = 0, lastMatch = 0;
	    while (i < count) {
		int pos = s.indexOf(delimiterSequence.charAt(i++));

		if (pos >= 0) {
		    // When we finally find a delimiter, we know where
		    // the last token ended
		    tokens[lastMatch] = s.substring(0, pos);
		    lastMatch = i;
		    s = s.substring(pos + 1);
		}
	    }
	    tokens[lastMatch] = s;
	}

	String next() {
	    return tokens[tokenIndex++];
	}
    }

    public static void main(String[] args) {
    }
}
