/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */
 // @author Brano Kusy: kusy@isis.vanderbilt.edu
 
package isis.nest.localization.rips;

import isis.nest.geneticoptimizer.Genotype;
import isis.nest.geneticoptimizer.Optimizer;

import java.io.BufferedReader;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.StringTokenizer;
import java.util.TreeMap;

public class LocalizationData implements isis.nest.geneticoptimizer.Problem
{
    private int minimumFreqScore = 2; //TODO = 3; 
    private int maxFreqError = 3;
    private int minimumChanScore = 9;

	static class Sensor
    {
        protected int id;
        protected int msgId;
        protected Point pos;
        protected boolean anchor;
        protected boolean sender;

        public Sensor (int id){
        	this.id = id;
        	msgId = 0;
        	pos = new Point(0,0,0);
        	anchor = false;
        	sender = false;
        }
        
        public Sensor(int id, int msgId, double x, double y, double z, boolean anchor, boolean sender)
        {
            this.id = id;
            this.msgId = msgId;
            pos = new Point(x, y, z);
            this.anchor = anchor;
            this.sender = sender;
        }

        public int getId(){
        	return id;
        }
        
        public void setId(int id){
        	this.id = id;
        }

        public int getMsgId(){
        	return msgId;
        }
        
        public void setMsgId(int msgId){
        	this.msgId = msgId;
        }
        
        public Point getPos(){
        	return new Point(pos.x,pos.y,pos.z);
        }
        
        public boolean isSender(){
        	return sender;
        }
        
        public void setSender(boolean sender){
        	this.sender = sender;
        }

        public boolean isAnchor(){
        	return anchor;
        }
        
        public void setAnchor(boolean anchor){
        	this.anchor = anchor;
        }

        public void setX(double i){
        	pos.x = i;
        }
        
        public void setY(double i){
        	pos.y = i;
        }
        
        public void setZ(double i){
        	pos.z = i;
        }
        
        
        public String toString()
        {
            return id + "\t" + pos.x + "\t" + pos.y + "\t" + pos.z + "\t";
        }
    }

    static class ChannelEntry
    {
        protected int channel;
        protected double frequency = 0.0;
        protected double phase = 0.0;
        protected int   minRSSI = 0;
        protected boolean valid = true;
    }

    static class SlaveEntry
    {
        protected int slaveID;
        protected boolean valid = true;
        protected ChannelEntry[] channels;
    }

    static class MeasurementEntry
    {
        protected String time;
        protected int masterID;
        protected int assistantID;
        protected int seqNumber;
        protected TreeMap slaves = new TreeMap();
    }

    protected TreeMap measurements = new TreeMap();
    protected TreeMap sensors = new TreeMap();
    protected int default_channels[] = {-61,60,-54,41,40,31,23,17,15,3,2,-60,59,-53,-42,-33,-25,-19,-17,-5,-2,-1};
    protected int channels[] = {-61,60,-54,41,40,31,23,17,15,3,2,-60,59,-53,-42,-33,-25,-19,-17,-5,-2,-1};
    protected ArrayList abcd_measurements = new ArrayList();

    // localization search space 
    protected double x_max = 100;
    protected double y_max = 100;
    protected double z_max = 0;

    private void readSensors(String fileName) throws Exception
    {
        BufferedReader r = new BufferedReader(new FileReader(fileName));
        sensors = new TreeMap();
        String line = r.readLine();
        while (line != null)
        {
            if(line.length() > 0 && line.charAt(0) != '#'){
	            StringTokenizer t = new StringTokenizer(line);
	            int id = Integer.parseInt(t.nextToken()); 
	            sensors.put(new Integer(id),
	                new Sensor(id,
						0,
	                    Double.parseDouble(t.nextToken()),
	                    Double.parseDouble(t.nextToken()),
	                    Double.parseDouble(t.nextToken()),
	                    Integer.parseInt(t.nextToken()) == 1,
						false));
            }
            line = r.readLine();
        }
    }

    private void readSettings(String fileName) throws Exception
    {
        ArrayList ch = new ArrayList();
        BufferedReader r = new BufferedReader(new FileReader(fileName));

        int section = 1;
        String line = r.readLine();
        while (line != null)
        {
            line = line.trim();
            if (line.length() > 0 && line.charAt(0) != '#')
            {
                if (section == 1)
                {
                    // channels
                    StringTokenizer t = new StringTokenizer(line, ",");
                    while (t.hasMoreTokens())
                        ch.add(new Integer(Integer.parseInt(t.nextToken())));
                    channels = new int[ch.size()];
                    for (int i = 0; i < channels.length; ++i)
                        channels[i] = ((Integer)ch.get(i)).intValue();

                }
                else if (section == 2)
                {
                    // search space
                    StringTokenizer t = new StringTokenizer(line, ",");
                    x_max = Double.parseDouble(t.nextToken());
                    y_max = Double.parseDouble(t.nextToken());
                    z_max = Double.parseDouble(t.nextToken());
                    try{
                        Constants.MAX_ABCD_RANGE = Double.parseDouble(t.nextToken());
                    }
                    catch (Exception e){
                        Constants.MAX_ABCD_RANGE = 100.0;
                    }
                }
                section++;
            }
            line = r.readLine();
        }
    }

    static public Integer getMeasurementKey(int masterID, int seqNumber)
    {
        return new Integer(masterID << 16 | seqNumber);
    }

    public void processRangeLine(String line)
    {
        StringTokenizer t = new StringTokenizer(line);
        
        int A = Integer.parseInt(t.nextToken());
        int B = Integer.parseInt(t.nextToken());
        int C = Integer.parseInt(t.nextToken());
        int D = Integer.parseInt(t.nextToken());
        
        int offsets = Integer.parseInt(t.nextToken());
        
        double calcDist = Double.parseDouble(t.nextToken());
        double distDev = Double.parseDouble(t.nextToken());
        double realDist = Double.parseDouble(t.nextToken());
        double error = Double.parseDouble(t.nextToken());
        

        ABCDMeasurement abcd = new ABCDMeasurement();
        abcd.sensor_A = A;
        abcd.sensor_B = B;
        abcd.sensor_C = C;
        abcd.sensor_D = D;
        
        abcd.goodOffsetMeasurements = offsets;
        
        abcd.calc_dist = calcDist;
        abcd.dist_dev = distDev;
        abcd.real_dist = realDist;
        abcd.error = error;

        abcd.sensor_A_ind = getSensorInd(abcd.sensor_A);
        abcd.sensor_B_ind = getSensorInd(abcd.sensor_B);
        abcd.sensor_C_ind = getSensorInd(abcd.sensor_C);
        abcd.sensor_D_ind = getSensorInd(abcd.sensor_D);
        
        abcd_measurements.add(abcd);
    }
    
    private void processLine(String line, boolean freq)
    {
        int i;
        StringTokenizer t = new StringTokenizer(line);
        String time = t.nextToken();
        int seqNumber = Integer.parseInt(t.nextToken());
        int masterID = Integer.parseInt(t.nextToken());
        int assistantID = Integer.parseInt(t.nextToken());
        int slave = Integer.parseInt(t.nextToken());
        String vals[] = new String[channels.length];
        for (i = 0; i < channels.length; ++i)
            vals[i] = t.nextToken();

        Integer key = getMeasurementKey(masterID, seqNumber);
        MeasurementEntry m = (MeasurementEntry)measurements.get(key);
        if (m == null)
        {
            m = new MeasurementEntry();
            m.masterID = masterID;
            m.assistantID = assistantID;
            m.seqNumber = seqNumber;
            m.time = time;
            measurements.put(key, m);
        }

        Integer slaveKey = new Integer(slave);
        SlaveEntry s = (SlaveEntry)m.slaves.get(slaveKey);
        if (s == null)
        {
            s = new SlaveEntry();
            s.slaveID = slave;
            s.valid = true;
            s.channels = new ChannelEntry[channels.length];
            for (i = 0; i < channels.length; ++i)
            {
                s.channels[i] = new ChannelEntry();
                s.channels[i].channel = channels[i];
                s.channels[i].valid = true;

            }
            m.slaves.put(slaveKey, s);
        }

        for (i = 0; i < channels.length; ++i)
        {
            double v = 0;
            if (vals[i].equalsIgnoreCase("null"))
                s.channels[i].valid = false;
            else
                v = Double.parseDouble((vals[i]));
            if (freq)
                s.channels[i].frequency = v;
            else
                s.channels[i].phase = v;
        }
    }

    private void readRanges(String fileName) throws Exception
    {
        BufferedReader r = new BufferedReader(new FileReader(fileName));
        String line = r.readLine();
        while(line != null)
        {
            line = line.trim();
            if(line.length() > 0 && line.charAt(0) != '#')
                processRangeLine(line);
            line = r.readLine();
        }
    }

    private void readFreqOrPhase(String fileName, boolean freq) throws Exception
    {
        BufferedReader r = new BufferedReader(new FileReader(fileName));
        String line = r.readLine();
        while (line != null)
        {
            line = line.trim();
            if (line.length() > 0 && line.charAt(0) != '#')
                processLine(line, freq);
            line = r.readLine();
        }
        if (freq){
        	validateFrequencies();
        	filterMeasurementsWithFreqency();
        }
    }

    private String getSettingsFileName(String fileNameBase)
    {
        String ret = new String(fileNameBase);
        ret = ret.concat(".set");
        return ret;
    }

    private String getPosFileName(String fileNameBase)
    {
        String ret = new String(fileNameBase);
        ret = ret.concat(".pos");
        return ret;
    }

    private String getRangeFileName(String fileNameBase)
    {
        String ret = new String(fileNameBase);
        ret = ret.concat(".ranges");
        return ret;
    }

    private String getFreqFileName(String fileNameBase)
    {
        String ret = new String(fileNameBase);
        ret = ret.concat(".freq");
        return ret;
    }

    private String getPhaseFileName(String fileNameBase)
    {
        String ret = new String(fileNameBase);
        ret = ret.concat(".phase");
        return ret;
    }

    private String getRSSIFileName(String fileNameBase)
    {
        String ret = new String(fileNameBase);
        ret = ret.concat(".rssi");
        return ret;
    }
    public void readRangeFile(String fileNameBase) throws Exception{
        // read settings
        readSettings(getSettingsFileName(fileNameBase));

        // read sensors
        try
        {
            readSensors(getPosFileName(fileNameBase));
        }
        catch(Exception e)
        {
            System.out.println("reading position file failed");
        }
        try
        {
            // read ranges
            readRanges(getRangeFileName(fileNameBase));
        }
        catch(Exception e)
        {
            System.out.println("reading ranges file failed");
        }
    }
    

    public void read(String fileNameBase) throws Exception
    {
        // read settings
        readSettings(getSettingsFileName(fileNameBase));

        // read sensors
        try
        {
            readSensors(getPosFileName(fileNameBase));
        }
        catch (Exception e)
        {
            System.out.println("reading position file failed");
        }

        // read freq
        readFreqOrPhase(getFreqFileName(fileNameBase), true);

        // read phase
        readFreqOrPhase(getPhaseFileName(fileNameBase), false);
    }

    public void write(String fileNameBase) throws Exception
    {
        int i;

        // write settings
        OutputStreamWriter writer1 =
            new OutputStreamWriter(new FileOutputStream(getSettingsFileName(fileNameBase)));
        writer1.write("#channels\n");
        writer1.write(Integer.toString(channels[0]));
        for (i = 1; i < channels.length; ++i)
            writer1.write("," + channels[i]);
        writer1.write("\n#search space (xmax,ymax,zmax,MAX_ABCD_RANGE)\n");
        writer1.write(x_max + "," + y_max + "," + z_max+ "," + Constants.MAX_ABCD_RANGE);
        writer1.close();

        // write positions
        if (sensors.size() > 0)
        {
            OutputStreamWriter writer2 =
                new OutputStreamWriter(new FileOutputStream(getPosFileName(fileNameBase)));
            Iterator it = sensors.values().iterator();
            while (it.hasNext())
            {
                Sensor s = (Sensor)it.next();
                writer2.write(s.id + "\t" + s.pos.x + "\t" + s.pos.y + "\t" + s.pos.z + "\t");
                if (s.anchor)
                    writer2.write("1");
                else
                    writer2.write("0");
                writer2.write("\n");
            }
            writer2.close();
        }

        // write freqs and phases
        OutputStreamWriter writer3 =
            new OutputStreamWriter(new FileOutputStream(getFreqFileName(fileNameBase)));
        OutputStreamWriter writer4 =
            new OutputStreamWriter(new FileOutputStream(getPhaseFileName(fileNameBase)));
        OutputStreamWriter writer5 =
            new OutputStreamWriter(new FileOutputStream(getRSSIFileName(fileNameBase)));
        Iterator it = measurements.values().iterator();
        while (it.hasNext())
        {
            MeasurementEntry m = (MeasurementEntry)it.next();
            Iterator it2 = m.slaves.values().iterator();
            while (it2.hasNext())
            {
                SlaveEntry s = (SlaveEntry)it2.next();
                String common =
                    new String(
                        m.time
                            + "\t"
                            + m.seqNumber
                            + "\t"
                            + m.masterID
                            + "\t"
                            + m.assistantID
                            + "\t"
                            + s.slaveID
                            + "\t");
                writer3.write(common);
                writer4.write(common);
                writer5.write(common);
                for (i = 0; i < channels.length; ++i)
                {
                    if (i > 0)
                    {
                        writer3.write("\t");
                        writer4.write("\t");
                        writer5.write("\t");
                    }
                    if (!s.channels[i].valid)
                    {
                        writer3.write("null");
                        writer4.write("null");
                        writer5.write("null");
                    }
                    else
                    {
                        writer3.write(Double.toString(s.channels[i].frequency));
                        writer4.write(Double.toString(s.channels[i].phase));
                        writer5.write(Double.toString(s.channels[i].minRSSI));
                    }
                }
                writer3.write("\n");
                writer4.write("\n");
                writer5.write("\n");
            }
        }
        writer3.close();
        writer4.close();
        writer5.close();
    }

    public void validateFrequencies(MeasurementEntry m){
        for (int i = 0; i < channels.length; ++i)
        {
            double channel_freq = 0;
            ArrayList freqs = new ArrayList();
            Iterator it2 = m.slaves.values().iterator();
            while (it2.hasNext())
            {
                SlaveEntry s = (SlaveEntry)it2.next();
                if (s.channels[i]!=null && s.channels[i].valid)
                    freqs.add(new Double(s.channels[i].frequency));
            }
            double freqs2[] = new double[freqs.size()];
            for (int j = 0; j < freqs2.length; ++j)
            {
                freqs2[j] = ((Double)freqs.get(j)).doubleValue();
                //System.out.println(freqs2[j]);                    
            }
            double med[] = Utils.simpleClustering(freqs2, maxFreqError);
            double min_cutoff = MoteParams.getInstance().interferenceFreq - 1.5*65;
            double max_cutoff = min_cutoff + 3*65;
            
            if (med[1] >= minimumFreqScore && med[0] > min_cutoff && med[0] < max_cutoff) //in tuning we trust && reject aliased tunings
                channel_freq = med[0];
            else
                channel_freq = 0;
            // invalidate measurements
            it2 = m.slaves.values().iterator();
            while (it2.hasNext())
            {
                SlaveEntry s = (SlaveEntry)it2.next();
                if (s.channels[i] == null){
                	s.channels[i] = new ChannelEntry();
                	s.channels[i].valid = false;
                }
                else if (channel_freq == 0 || Math.abs(channel_freq - s.channels[i].frequency) > maxFreqError)
                    s.channels[i].valid = false;
            }
        }
    }
 
    public void validateFrequencies()
    {
        Iterator it = measurements.values().iterator();
        while (it.hasNext())
        {
            validateFrequencies((MeasurementEntry)it.next());
        }
    }

    public void printMeasurementStat()
    {
        int n = 0;
        Iterator it = measurements.values().iterator();
        while (it.hasNext())
        {
            MeasurementEntry m = (MeasurementEntry)it.next();
            n += m.slaves.size();
        }
        System.out.println("number of measurements=\t" + n);
    }

    public void filterMeasurementsWithFreqency()
    {
        Iterator it = measurements.values().iterator();
        while (it.hasNext())
        {
            MeasurementEntry m = (MeasurementEntry)it.next();
            Iterator it2 = m.slaves.values().iterator();
            while (it2.hasNext())
            {
                SlaveEntry s = (SlaveEntry)it2.next();

                // count valid frequencies
                int good_freq = 0;
                for (int i = 0; i < channels.length; ++i)
                    if (s.channels[i].valid)
                        good_freq++;
                //invalidate slave
                if (good_freq < minimumChanScore)
                    s.valid = false;
                	//it2.remove();
            }
        }
    }

    public Sensor getSensorById(int id)
    {
        return (Sensor)sensors.get(new Integer(id));
    }

    public int getSensorInd(int id){
    	Object[] sensorsArray = sensors.values().toArray();
        for (int i = 0; i < sensors.size(); ++i)
        {
            Sensor sensor = (Sensor)sensorsArray[i];
            if (sensor.id == id)
                return i;
        }
        return -1;
    }

    public void addABCDMeasurements(MeasurementEntry m){
        Object[] current_measurements = m.slaves.values().toArray();

        // generate an ABCDMeasurement for each ordered pair in current_measurements
        for (int i = 0; i < current_measurements.length - 1; ++i)
        {
            SlaveEntry s1 = (SlaveEntry)current_measurements[i];
            for (int j = i + 1; j < current_measurements.length; ++j)
            {
                SlaveEntry s2 = (SlaveEntry)current_measurements[j];

                all_abcd_measurements++;
                
                ABCDMeasurement abcd = new ABCDMeasurement();
                ABCDMeasurement.PhaseOffset po;

                int good_freq = 0;
                for (int ch = 0; ch < channels.length; ch++)
                    if (s1.channels[ch].valid &&  s2.channels[ch].valid){
                        good_freq++;
                        
                    	abcd.goodOffsetMeasurements++;
                        double freq = Constants.BASE_FREQ + channels[ch] * Constants.CHANNEL_HOP;
                        double phase_offset = s1.channels[ch].phase - s2.channels[ch].phase;
                        if (phase_offset < 0)
                            phase_offset += 2 * Math.PI;
                        if (phase_offset > 2 * Math.PI)
                            phase_offset -= 2 * Math.PI;
                        po = new ABCDMeasurement.PhaseOffset(freq, phase_offset, 100, true);
/*new*/                 abcd.phaseOffsetMeasurments.add(po);
                    }
                	//                    else
                	//DO WE NEED THIS? if not, kill goodOffsetMeasurements
//                        po = new ABCDMeasurement.PhaseOffset(0, 0, 0, false);
//                    abcd.phaseOffsetMeasurments.add(po);

                //invalidate slaves
                if (good_freq < minimumChanScore){
                    s1.valid = false;
                    s2.valid = false;
                }
                else{
                	good_abcd_measurements++;
	
	                abcd.sensor_A = m.masterID;
	                abcd.sensor_B = m.assistantID;
	                abcd.sensor_C = s1.slaveID;
	                abcd.sensor_D = s2.slaveID;
	
	                abcd.sensor_A_ind = getSensorInd(abcd.sensor_A);
	                abcd.sensor_B_ind = getSensorInd(abcd.sensor_B);
	                abcd.sensor_C_ind = getSensorInd(abcd.sensor_C);
	                abcd.sensor_D_ind = getSensorInd(abcd.sensor_D);
	
	                abcd_measurements.add(abcd);
                }
            }
        }
    }
    
    public void addABCDMeasurements(int master, int sequenceNumber){
    	addABCDMeasurements((MeasurementEntry)measurements.get(LocalizationData.getMeasurementKey(master, sequenceNumber)));
    }
    
    int all_abcd_measurements = 0, good_abcd_measurements = 0;
    public void createABCDMeasurements()
    {
        abcd_measurements.clear();
        all_abcd_measurements = 0;
        good_abcd_measurements = 0;

        Iterator it = measurements.values().iterator();
        while (it.hasNext())
        {
            MeasurementEntry m = (MeasurementEntry)it.next();
            addABCDMeasurements(m);
        }
        System.out.println("max range:" + Constants.MAX_ABCD_RANGE+", all abcd measurements:" + all_abcd_measurements+", good measurements:" + good_abcd_measurements);
    }

    public void printABCDMeasurements(OutputStream out)
    {
        PrintStream out2 = new PrintStream(out);
        Iterator it = abcd_measurements.iterator();
        while (it.hasNext())
        {
            ABCDMeasurement m = (ABCDMeasurement)it.next();
            out2.println(m);
        }
    }

    protected double getABCDDist(int a, int b, int c, int d)
    {
        Sensor sensorA = getSensorById(a);
        Sensor sensorB = getSensorById(b);
        Sensor sensorC = getSensorById(c);
        Sensor sensorD = getSensorById(d);

        if (sensorA != null && sensorB != null && sensorC != null && sensorD != null)
        {
            double ac = sensorA.pos.distance(sensorC.pos);
            double bc = sensorB.pos.distance(sensorC.pos);
            double bd = sensorB.pos.distance(sensorD.pos);
            double ad = sensorA.pos.distance(sensorD.pos);
            //return ac - bc + bd - ad;
            return ad - bd + bc - ac;
        }
        else
        {
            return Double.MAX_VALUE;
        }
    }

    public void computeRange(ABCDMeasurement m){
        m.real_dist = getABCDDist(m.sensor_A, m.sensor_B, m.sensor_C, m.sensor_D);
        m.computeDistFast(null);
        m.error = Math.abs(m.real_dist - m.calc_dist);
    }
    
    public void computeRanges()
    {
        int i = 0;
        Iterator it = abcd_measurements.iterator();
        while (it.hasNext())
        {
            ABCDMeasurement m = (ABCDMeasurement)it.next();
            computeRange(m);
            
            if (!m.valid)
                it.remove();
        }
    }
    public void cheatFilter()
    {
        int i = 0;
        Iterator it = abcd_measurements.iterator();
        while (it.hasNext())
        {
            ABCDMeasurement m = (ABCDMeasurement)it.next();
            if (m.error > .5)
                it.remove();
        }
    }


/*    protected void findPositionsWithGA() throws Exception
    {
        GALocDisplay disp = new GALocDisplay();
        disp.show();
        Optimizer opt = new Optimizer(this, 100, 10);
        LocalizationSolution best = (LocalizationSolution)opt.getBestSolution();
        disp.update(best);
        for (int i = 0; i < 10; ++i)
        {
            opt.run(1000, 0);
            best = (LocalizationSolution)opt.getBestSolution();
            double good_bad[] = best.calcWeightStat(0.2);
            System.out.println( best.fitness + "\t" + best.locError() + "\t" + best.measurement_weight_avg
                    + "\t" + good_bad[0] + "\t" + good_bad[1] + "\t" + good_bad[2]);
            //best.printUsedStatistcs();
            //best.printLocError();
            //best.printSensorCoordinates();

            disp.update(best);

            //for( int j=0; j<best.measurement_errors.length; ++j)
            //  System.out.println(best.measurement_errors[j]);                       
        }
    }*/
    public void printRangeStat()
    {
        double all = 0;
        int under30 = 0;
        int under100 = 0;
        Iterator it = abcd_measurements.iterator();
        while (it.hasNext())
        {
            ABCDMeasurement m = (ABCDMeasurement)it.next();
            all++;
            if(m.error < 1)
            {
                under100++;
                if(m.error < 0.3)
                    under30++;                
            }
        }
        System.out.println("range stat");        
        System.out.println("under30="+100.0*under30/all+"% under100="+100*under100/all+"%");
    }        

    public Genotype createRandomSolution()
    {
        return new LocalizationSolution (this);
    }

    public double evaluteSolution(Genotype sol)
    {
        return ((LocalizationSolution )sol).evaluate();
    }

    public static void main(String[] args) throws Exception
    {
        LocalizationData loc = new LocalizationData();
        loc.read("c:\\tmp\\Rips\\data\\05-187-16-36-11");

        loc.printMeasurementStat();
        loc.validateFrequencies();
        loc.filterMeasurementsWithFreqency();
        loc.printMeasurementStat();
        loc.createABCDMeasurements();
        loc.computeRanges();
        
        //loc.findPositionsWithGA();

        //loc.write("c:\\temp\\Rips\\2");
    }
}
