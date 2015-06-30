
package net.tinyos.xnp;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import java.io.*;

public class MoteMsgIF extends MoteIF implements PhoenixError {

    public MoteMsgIF(PhoenixSource source) {
        super(source);
        source.setPacketErrorHandler(this);
    }

    public MoteMsgIF(PhoenixSource source, int gid) {
        super(source, gid);
        source.setPacketErrorHandler(this);
    }

    public MoteMsgIF(Messenger messages) {
        super(messages);
        source.setPacketErrorHandler(this);
    }

    public MoteMsgIF(Messenger messages, int gid) {
        super(messages, gid);
        source.setPacketErrorHandler(this);
    }

    public void error(java.io.IOException e) {
        System.err.println(e + " " + 
                           source.getPacketSource().getName() + "\n" +
                           "Check the source " + 
                           source.getPacketSource().getName() + " " +
                           "or try a different source by setting " +
                           "MOTECOM environment variable.");
        System.exit(1);
    }
}

