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

import java.util.*;
import java.io.*;
import java.text.SimpleDateFormat;


class Logger
{
    public static void writeln(String str, String fileName, boolean append)
    {
        write(str + "\n", fileName, append);
    }

    public static void write(String str, String fileName, boolean append)
    {
        // (1) - Create the FileWriter
        FileWriter fileWriter = null;
        try {
            File file = new File(fileName);
            File fileDir = new File(file.getParent());
            fileDir.mkdirs();
            fileWriter = new FileWriter(file, append);
        } catch (IOException ioe) {
            System.err.println("Can't create file!" + ioe);
        }
        try {
            fileWriter.write(str);
            fileWriter.close();
        } catch (IOException ioe) {
            System.err.println("Can't write to the file!" + ioe);
        }
    }
}

class FetchLogger
{
    // ======================= Data members =============================
    private SpauldingApp spauldingApp;
    protected Node node;
    protected int type;
    protected Date date;
    protected String logDirStr = null;

    private FileWriter rawBlockFile;
    private FileWriter dataBlockFile;
    private FileWriter samplesBlockFile;

    // Constants
    //static public final boolean USE_GMT_DATE = false;
    static public final int ERUPTION_FETCH = 0;
    static public final int MANUAL_FETCH = 1;
    //public static final int STATE_WAITING_FETCH = 2;

    // ======================= Methods =================================
    FetchLogger(final SpauldingApp spauldingApp, Node node, int type, Date date, String logDirStr)
    {
        assert (spauldingApp != null && node != null && date != null);
        this.spauldingApp = spauldingApp;
        this.node = node;
        this.type = type;
        this.date = date;
        this.logDirStr = logDirStr;
    }

    public void open()
    {
        try {
            // (1) - Create the log directory
            File logDir = null;

            if (logDirStr != null)
                logDir = new File(logDirStr);
            else
                logDir = new File(spauldingApp.SESSIONS_DIR_STR + File.separator +
                                  SpauldingApp.dateToString(date, SpauldingApp.USE_GMT_DATE));

            logDir.mkdirs();

            // (2) - Create the log file
            // if a file already exists with this name, then add an index
            // to the name
            String rawBlockFileStr = logDir + File.separator + "node-" + node.getNodeID() + ".raw";
            String dataBlockFileStr = logDir + File.separator + "node-" + node.getNodeID() + ".data";
            String samplesBlockFileStr = logDir + File.separator + "node-" + node.getNodeID() + ".samples";
            File rbFile = new File(rawBlockFileStr);
            for (int i = 1; ; ++i) {
                if (rbFile.exists())
                    rbFile = new File(rawBlockFileStr + "_" + i);
                else
                    break;
            }
            File dbFile = new File(dataBlockFileStr);
            for (int i = 1; ; ++i) {
                if (dbFile.exists())
                    dbFile = new File(dataBlockFileStr + "_" + i);
                else
                    break;
            }
            File sbFile = new File(samplesBlockFileStr);
            for (int i = 1; ; ++i) {
                if (sbFile.exists())
                    sbFile = new File(samplesBlockFileStr + "_" + i);
                else
                    break;
            }


            // (3) - Open a FileWriter for this file
            rawBlockFile = new FileWriter(rbFile);
            dataBlockFile = new FileWriter(dbFile);
            samplesBlockFile = new FileWriter(sbFile);

            String ds = spauldingApp.currDateToString(SpauldingApp.USE_GMT_DATE);
            rawBlockFile.write("# Raw block file for node " + node.getNodeID() + " created " + ds + "\n");
            rawBlockFile.write("# <curTimeMillis> <nodeID> <blockID> <data...>\n");

            dataBlockFile.write("# Data block file for node " + node.getNodeID() + " created " + ds + "\n");

            samplesBlockFile.write("# Samples block file for node " + node.getNodeID() + " created " + ds + "\n");

        } catch (IOException e) {
            spauldingApp.println("\nCan't open file!" + e);
            //System.exit(1);
        }
    }

    public void logBlock(Block block)
    {
        try {
            rawBlockFile.write(block.toStringRaw() + "\n");
            dataBlockFile.write(block.toStringData() + "\n");
            samplesBlockFile.write(block.toStringSamples() + "\n");

            rawBlockFile.flush();
            dataBlockFile.flush();
            samplesBlockFile.flush();
        } catch (IOException ioe) {
            spauldingApp.println("Can't write to the block log!" + ioe);
        }
    }

//    public void logComment(String comment)
//    {
//        try {
//            sampleDataFile.write("# " + comment + "\n");
//            sampleDataFile.flush();
//        } catch (IOException ioe) {
//            spauldingApp.println("Can't write comment!" + ioe);
//        }
//    }

//    public void logSummary(String summary)
//    {
//        try {
//            sampleDataFile.write("# Fetch summary follows\n");
//            sampleDataFile.write("# " + summary + "\n");
//            sampleDataFile.flush();
//        } catch (IOException ioe) {
//            spauldingApp.println("Can't write summary!" + ioe);
//        }
//    }

    public void close()
    {
        try {
            rawBlockFile.close();
            dataBlockFile.close();
            samplesBlockFile.close();
        } catch (IOException e) {
            spauldingApp.println("Can't close block log!" + e);
        }
    }
}

class MarkerLogger
{
    // ======================= Data members =============================
    private SpauldingApp spauldingApp;
    protected Date date;

    private FileWriter markerFile;


    // ======================= Methods =================================
    MarkerLogger(final SpauldingApp spauldingApp, Date date)
    {
        assert (spauldingApp != null && date != null);
        this.spauldingApp = spauldingApp;
        this.date = date;
    }

    public void open()
    {
        try {
            // (1) - Create the log directory
            String strLogFileDir = "." + File.separator + "markers";
            File logDir = new File(strLogFileDir);
            logDir.mkdirs();

            // (2) - Create the log file
            // if a file already exists with this name, then add an index to the name
            String markerFileStr = logDir + File.separator + SpauldingApp.dateToString(date, SpauldingApp.USE_GMT_DATE) + ".marker";
            File file = new File(markerFileStr);
            for (int i = 1; ; ++i) {
                if (file.exists())
                    file = new File(markerFileStr + "_" + i);
                else
                    break;
            }


            // (3) - Open a FileWriter for this file
            markerFile = new FileWriter(file);

            String ds = spauldingApp.currDateToString(SpauldingApp.USE_GMT_DATE);
            markerFile.write("# Markers created " + ds + "\n");

        } catch (IOException e) {
            spauldingApp.println("\nCan't open file!" + e);
            //System.exit(1);
        }
    }

    public void logMarker(String str)
    {
        try {
            markerFile.write(str + "\n");
            markerFile.flush();
        } catch (IOException ioe) {
            spauldingApp.println("Can't write to the marker log!" + ioe);
        }
    }


    public void close()
    {
        try {
            markerFile.close();
        } catch (IOException e) {
            spauldingApp.println("Can't close marker log!" + e);
        }
    }
}
