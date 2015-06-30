/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.util.*;
import java.text.*;
import java.io.*;

/**
 * This is the Serial port (UART) receiver for the centralized MoteTrack.
 * <code>MTReceiver</code> forwards the received beacon messages over the
 * serial port which should be received by this class.  Set MOTECOM to
 * the location where meassages are comming from, e.g. MOTECOM=serial@COM1:mica2!
 *
 * @author Konrad Lorincz
 * @version 1.1, October 12, 2004
 */
public class ErrorToLedsReceiver implements MessageListener
{
    private static DecimalFormat dbFormat = new DecimalFormat("#.###");
    private ErrorLogger logger = new ErrorLogger();


    public static void main(String args[])
    {
        ErrorToLedsReceiver myapp = new ErrorToLedsReceiver();
    }

    ErrorToLedsReceiver()
    {
        MoteIF mote = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
        mote.registerListener(new ErrorToLedsMsg(), this);
    }

    public void messageReceived(int dstaddr, Message msg)
    {
        if (msg instanceof ErrorToLedsMsg) {
            ErrorToLedsMsg eMsg = (ErrorToLedsMsg) msg;
            System.err.println("ErrorToLedsReceiver.messageReceived() - " + eMsg);
            logger.writeErrorToLedsMsg(eMsg);
        }
    }
}


class ErrorLogger
{
    // =========================== Data members ================================
    private FileWriter logger;
    private final static int FLUSH_THRESHOLD = 1;
    private final static long MAX_EVENTS_PER_FILE = 1000000;
    private int nbrEventsLoggedInCurrFile = 0;
    private String strLogFileDir = ".";

    // =========================== Methods =====================================
    ErrorLogger()
    {
        try {
            // (1) - Create the log directory
            File logDir = new File(strLogFileDir);
            logDir.mkdirs();

            // (2) - Open the first file
            openNewFile();

        } catch (Exception e) {
            System.err.println("\nCan't make directory " + strLogFileDir + e);
            e.printStackTrace();
            System.exit(1);
        }
    }

    synchronized private void openNewFile()
    {
        try {
            // (1) - Create the log file
            // if a file already exists with this name, then add an index to the name
            String strLogFile = strLogFileDir + File.separator + "errors.log";
            File logFile = new File(strLogFile);

//            for (int i = 1; ; ++i) {
//                if (logFile.exists())
//                    logFile = new File(strLogFile + "_" + i);
//                else
//                    break;
//            }

            // (2) - Open a FileWriter for this file
            logger = new FileWriter(logFile, true);
            logger.write("# Started on: " + dateToString(new Date(), false) + "\n");
            logger.write("# <timeStamp>, <TYPE>, <data...>\n");
        } catch (IOException e) {
            System.err.println("\nCan't open file!" + e);
            e.printStackTrace();
            System.exit(1);
        }
    }


    synchronized private void write(String str)
    {
        try {
            logger.write(dateToString(new Date(), false) + "  " + str + "\n");
            if (nbrEventsLoggedInCurrFile % FLUSH_THRESHOLD == 0) {
                logger.flush();
            }
        } catch (IOException e) {
            System.err.println("Can't write to the block log!" + e);
        }

        // If the file is getting too large, then create a new one
        nbrEventsLoggedInCurrFile++;
        if (nbrEventsLoggedInCurrFile >= MAX_EVENTS_PER_FILE) {
            this.closeCurrentFile();
            this.openNewFile();
            nbrEventsLoggedInCurrFile = 0;
        }
    }

    public void writeErrorToLedsMsg(ErrorToLedsMsg eMsg)
    {
        String str = "ERRORTOLEDS_MSG " +
                     " srcAddr " + eMsg.get_sourceAddr() +
                     " errorCode " + eMsg.get_errorCode();
        write(str);
    }

    synchronized private void closeCurrentFile()
    {
        try {
            logger.close();
        }
        catch (IOException e) {
            System.err.println("Can't close event log!" + e);
        }
    }

    static public String dateToString(Date date, boolean toGMT)
    {
        DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd_HH:mm:ss.SSS_Z");
        if (toGMT)
            dateFormat.setTimeZone(TimeZone.getTimeZone("GMT"));
        return dateFormat.format(date);
    }
}

