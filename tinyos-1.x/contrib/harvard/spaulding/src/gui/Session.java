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
import java.io.Serializable;

interface SessionListener
{
    /**
     * This method is called to signal that the state changed.
     * @param state - the new (i.e. current) state
     */
    public void stateChanged(Session.State state);
    public void statePercentCompletedChanged(double percent);
    public void stateElapsedTimeChanged(long timeMS);
}


/**
 * Encapsulates a Sampling Session.
 * @author Konrad Lorincz
 * @version 1.0
 */
public class Session implements Serializable, Runnable, Comparable<Session>, RequestListener
{
    // =========================== Data Members ================================
    transient private SpauldingApp spauldingApp;
    transient private List<SessionListener> sessionListeners = new Vector<SessionListener>();
    transient private Thread thread;

    // --- Session State ---
    private Date date = null;            // serves as the session ID
    private String sessionName = "DefaultSessionName"; // the session name
    private int subjectID = 0;
    private Map<Node, Long> nodesDownloadStartBlockID = Collections.synchronizedMap(new HashMap<Node, Long>());
    private Map<Node, Long> nodesDownloadEndBlockID = Collections.synchronizedMap(new HashMap<Node, Long>());
    // ---------------------

    private double percDownloaded = 0.0;
    private final static String FILE_INFO_STR = "sessionInfo.txt";

    private static final long EXTRA_SAMPLING_DURATION = 2000;  // fudge factor which also flushes old samples in currBlock on mote
    private long samplingStartTime = 0;
    private long samplingDuration = 0;
    private SortedSet<Node> participatingNodes = Collections.synchronizedSortedSet(new TreeSet<Node>());

    transient private Command currCommand = Command.NONE;
    private State currState = State.READY_TO_SAMPLE;
    transient private Set<Request> currStateRequests = Collections.synchronizedSet(new HashSet<Request>());

    public enum State {
        READY_TO_SAMPLE,
        PREPARING_TO_SAMPLE,
        SAMPLING,
        PREPARING_TO_DOWNLOAD,
        DOWNLOADING,
        DONE,
        FAILED
    }

    public enum Command {
        NONE,
        START_SAMPLING,
        STOP_SAMPLING,
        DOWNLOAD
    }


    // =========================== Methods ================================
    public Session(SpauldingApp spauldingApp, SortedSet<Node> participatingNodes, Date date, String name, int subjectID)
    {
        assert (spauldingApp != null && participatingNodes != null);
        assert (date != null && name != null);
        assert (participatingNodes.size() > 0);
        this.spauldingApp = spauldingApp;
        for (Node node: participatingNodes)
            this.participatingNodes.add(node);

        this.date = date;
        this.sessionName = name;
        this.subjectID = subjectID;

        setState(State.READY_TO_SAMPLE);

        currCommand = Command.NONE;
        startThread();

        // Create SessionInfo.txt
        String info = "sessionDate= " + SpauldingApp.dateToString(date, SpauldingApp.USE_GMT_DATE) +
                      " sessionName= " + name +
                      " subjectID= " + subjectID;
        Logger.writeln(info, getFileInfoStr(), true);
    }

    private void startThread()
    {
        thread = new Thread(this);
        thread.start();
    }

    public void setSpauldingApp(SpauldingApp sa)
    {
        assert(sa != null);
        this.spauldingApp = sa;
    }

    private void writeObject(java.io.ObjectOutputStream out) throws IOException
    {
        out.defaultWriteObject();
    }

    private void readObject(java.io.ObjectInputStream in) throws IOException, ClassNotFoundException
    {

        in.defaultReadObject();
        // now we are a "live" object again, so let's run rebuild and start

        currStateRequests = Collections.synchronizedSet(new HashSet<Request>()); // not sure if this is needed
        sessionListeners = new Vector<SessionListener>();

        startThread();
    }

    public String getSessionDir()
    {
        return SpauldingApp.SESSIONS_DIR_STR + File.separator +
                "subj-" + this.subjectID + "_" +
                this.sessionName + "_" +
                SpauldingApp.dateToString(date, SpauldingApp.USE_GMT_DATE);
    }

    private String getFileInfoStr()
    {
        return getSessionDir() + File.separator + FILE_INFO_STR;
    }

    public Date getDate() {return date;}
    public String getSessionName() {return sessionName;}
    public int getSubjectID() {return subjectID;}
    public long getDuration() {return samplingDuration;}
    public double getPercentDownloaded() {return this.percDownloaded;}
    public static State getInitialState() {return State.READY_TO_SAMPLE;}

    public boolean isSampling()
    {
        if (currState == State.SAMPLING)
            return true;
        else
            return false;
    }

    /**
     * The comparaTo method for the <code>Comparable</code> interface.
     * @param otherObj  the other signature to compare with.
     * @return  <code>-1 if (this.id < other.id), 0 if they are the same, and 1 if (this.id > other.id)</code>
     */
    public int compareTo(Session other)
    {
        assert (other != null);
        Date thisDate = this.getDate();
        Date otherDate = other.getDate();

        if (thisDate.before(otherDate))
            return -1;
        else if (thisDate.equals(otherDate))
            return 0;
        else
            return 1;
    }


    synchronized public void registerListener(SessionListener listener)
    {
        assert (listener != null);
        sessionListeners.add(listener);
    }

    synchronized private void signalStateChanged()
    {
        for (SessionListener ssl: sessionListeners)
            ssl.stateChanged(currState);
    }

    private void signalPercentCompletedChanged(double percent)
    {
        for (SessionListener ssl: sessionListeners)
            ssl.statePercentCompletedChanged(percent);
    }

    private void signalElapsedTimeChanged(long timeMS)
    {
        for (SessionListener ssl: sessionListeners)
            ssl.stateElapsedTimeChanged(timeMS);
    }

    synchronized public void requestDone(Request request, boolean isSuccessful)
    {
        if (!currStateRequests.contains(request)) {
            // bogus request, just drop it
            System.err.println("\n\n ************ Session.requestDone() - BOGUS REQUEST!!!! **********\n\n\n");
            Thread.dumpStack();
            System.exit(1);
        }
        else {
            if (isSuccessful) {
                currStateRequests.remove(request);
                if (currStateRequests.isEmpty())
                    this.notify();
            }
            else {
                System.err.println("\n\n ************ Session.requestDone() - WARNING, request failed!!! *********\n\n\n");
                Thread.dumpStack();
                //System.exit(1);
            }
        }
    }
    synchronized public void percentCompletedChanged(Request request, double percentCompleted)
    {
        double percCompletedNodes =  100.0 *(double)(participatingNodes.size() - currStateRequests.size()) /
                                     (double) participatingNodes.size();
        double percCurrNode = percentCompleted;
        double percTotal = percCompletedNodes + percCurrNode/(double)participatingNodes.size();
        if (currState == State.DOWNLOADING)
            this.percDownloaded = percTotal;
        this.signalPercentCompletedChanged(percTotal);
    }


    private void setState(State newState)
    {
        this.currState = newState;
        signalStateChanged();
    }

    synchronized public void startSampling()
    {
        this.currCommand = Command.START_SAMPLING;
        this.notify();
    }

    synchronized public void stopSampling()
    {
        this.currCommand = Command.STOP_SAMPLING;
        this.notify();
    }

    synchronized public void download()
    {
        this.currCommand = Command.DOWNLOAD;
        this.notify();
    }

    synchronized private void waitForNotify(Long timeMS)
    {
        try {
            if (timeMS == null)
                this.wait();
            else
                this.wait(timeMS);
        }
        catch (InterruptedException ie) {
            System.err.println("Session.run.thread.wait() - error" + ie);
        }
    }

    public void run()
    {
        synchronized (this) {
            while (true) {
                System.err.println("\n*********** Session.run() - currCommand= " + this.currCommand + " ***************\n");
                // (1) - Start Sampling
                if (this.currCommand == Command.START_SAMPLING) {
                    // (a) Stop sampling
                    System.out.println("=====>>>>> Session.run() - part 0");
                    setState(State.PREPARING_TO_SAMPLE);
                    this.stopSamplingPrivate();
                    while (currStateRequests.size() > 0)
                        waitForNotify(null);

                    // (b) Start sampling all nodes
                    System.out.println("=====>>>>> Session.run() - part 1");
                    for (Node node: this.participatingNodes)
                        this.nodesDownloadStartBlockID.put(node, node.getHeadBlockID()+1);
                    setState(State.SAMPLING);
                    this.startSamplingPrivate();
                    while (currStateRequests.size() > 0)
                        waitForNotify(null);

                    // (c) Wait for signal to stop sampling
                    System.out.println("=====>>>>> Session.run() - part 2");
                    this.samplingStartTime = System.currentTimeMillis();

                    // wake up every "updatePeriod" to update the gui
                    long updatePeriod = 1000;
                    while (this.currCommand != Command.STOP_SAMPLING) {
                        this.samplingDuration = System.currentTimeMillis() - this.samplingStartTime;
                        this.signalElapsedTimeChanged(samplingDuration);
                        waitForNotify(updatePeriod);
                    }
                }

                // (2) - Stop sampling
                else if (this.currCommand == Command.STOP_SAMPLING) {
                    System.out.println("=====>>>>> Session.run() - part 3");
                    setState(State.PREPARING_TO_DOWNLOAD);
                    this.stopSamplingPrivate();
                    while (currStateRequests.size() > 0)
                        waitForNotify(null);
                    // Record the tailBlockID for each node.  This will be used when we download data for this session
                    String infoLog = "samplingDurationMS= " + this.samplingDuration +
                                     ", <nodeID,startBlockID,endBlockID>=";
                    for (Node node: this.participatingNodes) {
                        long startBlockID = nodesDownloadStartBlockID.get(node);
                        long endBlockID = node.getHeadBlockID();
                        if (endBlockID < startBlockID)
                            endBlockID = startBlockID;

                        nodesDownloadEndBlockID.put(node, endBlockID);
                        infoLog += " <" + node.getNodeID() + "," + startBlockID + "," + endBlockID + ">";
                    }
                    Logger.writeln(infoLog, getFileInfoStr(), true);
                    this.currCommand = Command.NONE;
                }



                // (3) - Download
                else if (this.currCommand == Command.DOWNLOAD) {
                    System.out.println("=====>>>>> Session.run() - part 4");
                    setState(State.DOWNLOADING);
                    this.downloadSamples();
                    while (currStateRequests.size() > 0)
                        waitForNotify(null);
                    this.currCommand = Command.NONE;

                    System.out.println("=====>>>>> Session.run() - DONE DONE DONE DONE!!!");
                    setState(State.DONE);
                }

                // (4) - Put the threat to sleep until we get a command that requires work
                else
                    waitForNotify(null);

                // (5) - Save the sessions
                if (spauldingApp != null)
                    spauldingApp.saveSessions();
            }
        }
    }


    private void stopSamplingPrivate()
    {
        assert (currStateRequests.size() == 0);

        // (1) - Construct requests for nodes that need to be stopped
        for (Node node: this.participatingNodes) {
            if (node.getCurrState().equals("SAMPLING")) {
                System.out.println("Session - scheduling Stop Sampling for nodeID= " + node.getNodeID());

                AckRequest ackRequest = new AckRequest(spauldingApp, node, DriverMsgs.REQUESTMSG_TYPE_STOPSAMPLING);
                currStateRequests.add(ackRequest);
                ackRequest.registerListener(this);
                spauldingApp.scheduleRequest(ackRequest);
            }
        }
    }

    private void startSamplingPrivate()
    {
        assert (currStateRequests.size() == 0);

        // (1) - Construct requests for nodes that need to be started
        for (Node node: this.participatingNodes) {
            if (node.getCurrState().equals("READY_TO_SAMPLE")) {
                System.out.println("Session - scheduling Start Sampling for nodeID= " + node.getNodeID());

                AckRequest ackRequest = new AckRequest(spauldingApp, node, DriverMsgs.REQUESTMSG_TYPE_STARTSAMPLING);
                currStateRequests.add(ackRequest);
                ackRequest.registerListener(this);
                spauldingApp.scheduleRequest(ackRequest);
            }
        }
    }

//    private int nbrBlocksToDownload(int nodeID)
//    {
//
//        return (int) Math.round(Block.nbrBlocksPerSamplingTimeMS(samplingDuration));
//    }

    private void downloadSamples()
    {
        assert (currStateRequests.size() == 0);

        // (1) - Construct requests for nodes that need to be stopped
        for (Node node: this.participatingNodes) {
            System.out.println("Session - scheduling Download Blocks for nodeID= " + node.getNodeID());
            //FetchLogger fetchLogger = new FetchLogger(spauldingApp, node, FetchLogger.MANUAL_FETCH, spauldingApp.getUTCDate());
            //FetchRequest fetchRequest = new FetchRequest(spauldingApp, node, fetchLogger, -1, nbrBlockToDownload);

            long startBlockID = nodesDownloadStartBlockID.get(node);
            int nbrBlockToDownload = (int)(nodesDownloadEndBlockID.get(node) - startBlockID);

            FetchLogger fetchLogger = new FetchLogger(spauldingApp, node, FetchLogger.MANUAL_FETCH, getDate(), getSessionDir());
            FetchRequest fetchRequest = new FetchRequest(spauldingApp, node, startBlockID, nbrBlockToDownload, fetchLogger);
            currStateRequests.add(fetchRequest);
            fetchRequest.registerListener(this);
            spauldingApp.scheduleRequest(fetchRequest);
        }
    }

}
