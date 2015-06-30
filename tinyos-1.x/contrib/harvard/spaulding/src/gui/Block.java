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
/**
 * @author Konrad Lorincz
 */

import java.util.*;
import java.awt.*;
import net.tinyos.message.*;
import net.tinyos.util.*;
import java.text.DecimalFormat;

/**
 * Format for blocks received from the data store.
 */
public class Block
{
    // ======================= Data members =============================
    // Set to 'true' if datastore uses packed samples
    private static final boolean SAMPLE_CHUNK_PACKED = false;
    private static final boolean PRINT_SAMPLES_VERBOSE = false;
    private static final DecimalFormat dbFormat = new DecimalFormat("#.0000");

    private Node node;
    private long blockID;
    private short[] blockBytes = new short[FetchMsgs.FETCH_BLOCK_SIZE];

    // Part of SampleChunk
    private long localTime = 11;
    private long globalTime = 12;
    private int samplingRate = 1;
    private int timeSynched = 0;
    private int nbrSamples;
    private int channelIDs[] = new int[MultiChanSampling.MCS_MAX_NBR_CHANNELS_SAMPLED];
    private long samples[][];

    // other
    private int nbrChannels;
    private boolean wasParsed = false;

    // ======================= Methods =============================
    Block(Node node, long blockID)
    {
        assert (node != null && blockID >= 0);
        this.node = node;
        this.blockID = blockID;
    }

    public long getBlockID()  {return blockID;}

    public synchronized void setBlockBytes(int offset, short[] bytes)
    {
        for (int i = 0; i < bytes.length; ++i)
            blockBytes[offset + i] = bytes[i];
    }

    /** Return a string representing the raw bytes in the block */
    public String toStringRaw()
    {
        String str = "pcTime= " + SpauldingApp.currDateToString(SpauldingApp.USE_GMT_DATE) +
                     " nodeID= " + node.getNodeID() +
                     " blockID= " + blockID +
                     " rawData: ";

        for (int i = 0; i < blockBytes.length; ++i)
           str += " 0x" + Integer.toHexString(blockBytes[i] & 0xff);

       return str;
   }


    /** Return a human-readable string representing the block contents
     */
    public String toStringData()
    {
        parseBlock();
        String str = "nodeID= " + node.getNodeID() +
                     " blockID= " + blockID +
                     " localTime= " + localTime +
                     " globalTime= " + globalTime +
                     " timeSynched= " + timeSynched +
                     " channelMap [";
        for (int i = 0; i < nbrChannels; i++) {
            str += channelIDs[i];
            if (i != nbrChannels - 1)
                str += " ";
        }
        str += "]" +
                " nbrSamples= " + nbrSamples +
                " samples: ";

        for (int sampleIndex = 0; sampleIndex < samples[0].length; sampleIndex++) {
            for (int chan = 0; chan < nbrChannels; chan++) {
                if (PRINT_SAMPLES_VERBOSE) {
                    //str += "chan "+chan+" sample "+sampleIndex+" "+Long.toHexString(samples[chan][sampleIndex])+"\n";
                    str += "chan " + chan + " sample " + sampleIndex + " " + samples[chan][sampleIndex] + "\n";
                }
                else {
                    //str += Long.toHexString(samples[chan][sampleIndex])+" ";
                    str += samples[chan][sampleIndex] + " ";
                }
            }
        }
        return str;
    }

    private double blockTimeRawToMS(long rawTime)
    {
        return (double)rawTime/(double)SpauldingApp.LOCAL_TIME_RATE_HZ;
    }

    public String toStringSamples()
    {
        parseBlock();

        String str = "# nodeID= " + node.getNodeID() +
                     " blockID= " + blockID +
                     " localTime= " + localTime +
                     " globalTime= " + globalTime +
                     " samplingRate= " + samplingRate +
                     " timeSynched= " + timeSynched +
                     " localTimeMS= " + dbFormat.format(blockTimeRawToMS(localTime)) +
                     " globalTimeMS= " + dbFormat.format(blockTimeRawToMS(globalTime));

        for (int samp = 0; samp < samples[0].length; ++samp) {
            double timeMS = blockTimeRawToMS(globalTime) +
                            ((double)samp/(double)this.samplingRate);

            str += "\n" + dbFormat.format(timeMS) + " ";
            for (int chan = 0; chan < samples.length; ++chan) {
                str += " " + samples[chan][samp];
            }
        }

        return str;
    }


    /**
     * Once the entire blockBytes array has been filled in,
     * parse out the fields in the block header as well as the
     * sample data contained therein.
     * NOTE! If the format of Block or SampleChunk changes, this
     * code will need to be updated as well.
     */
    private synchronized void parseBlock()
    {
        if (wasParsed)
            return;
        else
            wasParsed = true;  // will get parsed

        // (1) - The Block part
        long seqno = bytesToUint32(0);
        if (seqno != blockID)
            System.err.println("ERROR: Block ID " + blockID + " does not match header sequence number " + seqno);

        // (2) - The SampleChunk part
        localTime = bytesToUint32(4);
        globalTime = bytesToUint32(8);
        samplingRate = bytesToUint16(12);
        timeSynched = bytesToUint16(14);
        nbrSamples = bytesToUint16(16);
        nbrChannels = 0;  // MUST be set to Zero, else if parseBlock() runs multiple times, it will get incremented!
        for (int chan = 0; chan < MultiChanSampling.MCS_MAX_NBR_CHANNELS_SAMPLED; chan++) {
            channelIDs[chan] = (int) (blockBytes[18 + chan] & 0xff);
            if (channelIDs[chan] != MultiChanSampling.CHAN_INVALID)
                nbrChannels++;
        }
        samples = new long[nbrChannels][];
        for (int chan = 0; chan < nbrChannels; chan++) {
            samples[chan] = new long[(nbrSamples / nbrChannels)];
        }

        // Start of sample data
        final int NBR_BYTES_PER_SAMPLE = 2;
        int offset = 24;
        int curChan = 0;
        int sampleIndex = 0;
        for (int samplenum = 0; samplenum < nbrSamples; samplenum++) {
            if (SAMPLE_CHUNK_PACKED) {
                samples[curChan][sampleIndex] = bytesToUint24(offset);
                offset += 3;
            }
            else {
                try {
                    samples[curChan][sampleIndex] = bytesToUint16(offset);
                    offset += NBR_BYTES_PER_SAMPLE;
                }
                catch (ArrayIndexOutOfBoundsException e) {
                    System.err.printf("\noffset= %d, curChan= %d, sampleIndex= %d, samplingRate= %d, nbrSamples= %d",
                            offset, curChan, sampleIndex, samplingRate, nbrSamples);
                    e.printStackTrace();
                    System.out.println("About to exit");
                    //System.exit(1);
                }
            }
            curChan++;
            if (curChan == nbrChannels) {
                sampleIndex++;
                curChan = 0;
            }
        }
    }



    /* Construct a uint16_t from 2 bytes in blockBytes[offset]. Assume
     * little-endian.
     */
    private int bytesToUint16(int offset)
    {
        int curVal = 0;
        for (int i = 0; i < 2; i++) {
            int orval = (int) (blockBytes[offset + i] & 0xff);
            for (int n = 0; n < i; n++)
                orval <<= 8;
            curVal |= orval;
        }
        return curVal;
    }

    /* Construct a uint24_t from 3 bytes in blockBytes[offset]. Assume
     * little-endian.
     */
    private long bytesToUint24(int offset)
    {
        long curVal = 0;
        for (int i = 0; i < 3; i++) {
            long orval = (long) (blockBytes[offset + i] & 0xff);
            for (int n = 0; n < i; n++)
                orval <<= 8;
            curVal |= orval;
        }
        return curVal;
    }

    /* Construct a uint32_t from 4 bytes in blockBytes[offset]. Assume
     * little-endian.
     */
    private long bytesToUint32(int offset)
    {
        long curVal = 0;
        for (int i = 0; i < 4; i++) {
            long orval = (long) (blockBytes[offset + i] & 0xff);
            for (int n = 0; n < i; n++)
                orval <<= 8;
            curVal |= orval;
        }
        return curVal;
    }


}


