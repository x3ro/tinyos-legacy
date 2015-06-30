/*
 * PSSubscription.java
 *
 * Created on 29. Juli 2005, 13:32
 */

package de.tub.eyes.apps.PS;

import java.util.*;
import net.tinyos.message.*;
import net.tinyos.surge.BcastMsg;
import net.tinyos.drip.*;

import de.tub.eyes.comm.MoteComm;
import de.tub.eyes.apps.*;
import de.tub.eyes.ps.*;
import de.tub.eyes.apps.demonstrator.Demonstrator;
import de.tub.eyes.components.ConfigComponent;

import org.nfunk.jep.*;


/**
 *
 * @author Till Wimmer
 */
public class PSSubscription implements java.io.Serializable {

    public static final int TYPE_UINT16 = 0;    
    public static final int TYPE_UINT32 = 1;
    public static final int TYPE_TEXT = 2;
    public static final int TYPE_UNIT16_ARR = 3;    
    public static final int TYPE_UINT32_ARR = 4;
    
    public static final int ENDIANNESS_LITTLE = 0;
    public static final int ENDIANNESS_BIG = 1;
    
    public static final int FLAG_SUBSCRIBE = 0;
    public static final int FLAG_UNSUBSCRIBE = 1;    
        
    public static final String [] types = new String[6];
    { 
        types[TYPE_UINT16] = "uint16";
        types[TYPE_UINT32] = "uint32";
        types[TYPE_TEXT] = "text";
        types[TYPE_UNIT16_ARR] = "uint16[]";
        types[TYPE_UINT32_ARR] = "uint32[]";        
     }
    
    public static final String [] endiannesses = new String[2];
    {
        endiannesses[ENDIANNESS_LITTLE] = "little";
        endiannesses[ENDIANNESS_BIG] = "big";
    }
    
    private int subscriberID;
    private int modificationCounter = -1;
    private Vector constraints = new Vector();
    private Vector avpairs = new Vector();
    private int ID;
    private boolean deleted=false;
    private int bcastSeqNo = 0;
    private int flag = -1;

    private final int resendCnt = 2;
    private final int resendIntervall = 10000;
    private final int AM_TYPE = 156;
    private final boolean reliable = false; //needs new TOSbase version
    //private final int dripMessageID = 0;
    
    private static AttributeWrapper aw = null;
    private static int [] avIds = null;
    private static int [] constrIds = null;
    
    static {            
        aw = new AttributeWrapper(Demonstrator.getProps().getProperty("attributesXML"), 
                Demonstrator.getProps().getProperty("attributesMainNode"));
        
        Map attribs = aw.getAttributesMap();
        
        Vector avIdVector = new Vector();
        Vector constrIdVector = new Vector();
        
        for (Iterator it=attribs.keySet().iterator(); it.hasNext();) {        
            Integer id = (Integer)it.next();
            Attribute attrib = (Attribute)attribs.get(id);
            
            if (attrib.getOperations() == null) {            
                avIdVector.addElement(id);
            }
            else {            
                constrIdVector.addElement(id);
            }                    
        }
                
        avIds = new int[avIdVector.size()];
        constrIds = new int[constrIdVector.size()];
        
        int cnt = 0;
        for (Iterator it=avIdVector.iterator(); it.hasNext(); ) {        
            avIds[cnt++] = ((Integer)it.next()).intValue();
        }
                
        cnt = 0;
        for (Iterator it=constrIdVector.iterator(); it.hasNext(); ) {        
            constrIds[cnt++] = ((Integer)it.next()).intValue();
        }        
    }

    public PSSubscription() { }
    
    public PSSubscription(int ID, int subscriberID) {
        this.ID = ID;
        this.subscriberID = subscriberID;
    }
            
    public void setID(int ID) {
        this.ID = ID;
    }
         
    public int getID() {
        return this.ID;
    }
     
    public void setFlag(int flag) {
        this.flag = flag;
    }
         
    public int getFlag() {
        return this.flag;
    }
    
    public void setSubscriberID(int subscriberID) {
        this.subscriberID = subscriberID;
    }
          
    public int getSubscriberID() {
        return this.subscriberID;
    }
        
    public void addConstraint(Constraint constraint) {
        constraints.addElement(constraint);
    }
            
    public void addAvpair(Avpair avpair) {
        avpairs.addElement(avpair);
    }
            
    public void removeConstraint(Constraint constraint) {
        constraints.remove(constraint);
    }
            
    public void removeAvpair(Avpair avpair) {    
        avpairs.remove(avpair);
    }
            
    public int incModificationCounter() {
        return this.modificationCounter +=1;
    }
    
    public int getModificationCounter() {
        return this.modificationCounter;
    }
    
    public int cntConstraints() {
        return constraints.size();
    }
    
    public int cntAvpairs() {
        return avpairs.size();
    }
    
    public Iterator getConstraintsIterator() {
        return constraints.iterator();
    }
    
    public Iterator getAvpairsIterator() {
        return avpairs.iterator();
    }
    
    public void clear() {
        avpairs.clear();
        constraints.clear();
    }
    
    public String toString() {
        String out = new String("PSSubscription{ ");
        out += "ID = " + ID + "\n";
        out += "flag = " + flag + "\n";
        out += "subscriberID = " + subscriberID + "\n";
        out += "modificationCounter = " + modificationCounter + "\n";
        for (Iterator it = avpairs.iterator(); it.hasNext(); ) {
            Avpair avpair = (Avpair)it.next();
            out += ( avpair.toString() + "\n");
        }
        for (Iterator it = constraints.iterator(); it.hasNext(); ) {
            Constraint constraint = (Constraint)it.next();
            out += ( constraint.toString() + "\n");
        }
        
        return out + " }";
    }
    
    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }
    
    public boolean getDeleted() {
        return deleted;
    }
    
    public void send() {
        sendDrip();
    }
    
     private void sendDrip() {
            
        //Drip drip = new Drip(dripMessageID);
        Drip drip = new Drip(ID, Demonstrator.getMoteComm().getMoteIF()); // DripMessageID == SubscriptionID
        PSSubscriptionMsg msg = new PSSubscriptionMsg();
        
        msg.set_subscriberID((short) subscriberID);
        msg.set_subscriptionID((short) ID);
        msg.set_modificationCounter((short) modificationCounter);
        msg.set_flags((short) flag);
        
        for (Iterator it = avpairs.iterator(); it.hasNext(); ) {             
            Avpair avpair = (Avpair)it.next();
            if (avpair == null)
                continue;
            
            Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(avpair.attributeID));            
            if (attrib == null)
                continue;
                                                    
            short [] value = longToShortArray(avpair.value, avpair.attributeID);
            if (!msg.addAVPair(avpair.attributeID, 
                    value)) {                                        
                System.err.println("Error: Too many avpair/instructions !");
                //System.exit(1);
            }
        }
        
        for (Iterator it = constraints.iterator(); it.hasNext(); ) {             
            Constraint constraint = (Constraint)it.next();
            if (constraint == null)
                continue;
                  
            Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(constraint.attributeID));            
            if (attrib == null)
                continue;
                                                    
            short [] value = longToShortArray(constraint.value, constraint.attributeID);     
            if (!msg.addConstraint(constraint.attributeID,
                    (short)constraint.operationID,
                    value)) {                            
                System.err.println("Error: Too many constraints/instructions !");
                //System.exit(1);
            }
        }
  
        System.out.println("Sending ...");
        //if (reliable)
        //    drip.send(msg, msg.getTotalMessageSizeBytes());
        //else
            drip.sendUnreliable(msg, msg.getTotalMessageSizeBytes());
    }
    
    private void sendBcast(MoteComm mc, int flag) {
            
        PSSubscriptionMsg msg = new PSSubscriptionMsg();
        
        msg.set_subscriberID((short) subscriberID);
        msg.set_subscriptionID((short) ID);
        msg.set_modificationCounter((short) modificationCounter);
        msg.set_flags((short) flag);
        
        for (Iterator it = avpairs.iterator(); it.hasNext(); ) {             
            Avpair avpair = (Avpair)it.next();
            short [] value = {0, (short)avpair.value};
            if (!msg.addAVPair(avpair.attributeID, 
                    value)) {                                        
                System.err.println("Error: Too many avpair/instructions !");
                //System.exit(1);
            }
        }
        
        for (Iterator it = constraints.iterator(); it.hasNext(); ) {             
            Constraint constraint = (Constraint)it.next();
            short [] value = {0, (short)constraint.value};            
            if (!msg.addConstraint(constraint.attributeID,
                    (short)constraint.operationID,
                    value)) {                            
                System.err.println("Error: Too many constraints/instructions !");
                //System.exit(1);
            }
        }
    
        System.out.println("Sending ...");
        BcastMsg bMsg = new BcastMsg(msg.dataLength()+msg.baseOffset());
        ((Message)bMsg).amTypeSet(AM_TYPE);
        bMsg.dataSet(msg,2);
        bMsg.set_seqno((short)bcastSeqNo);
        bcastSeqNo++;
        mc.send(bMsg, 65535);
        //d.mc.send(msg, Integer.parseInt(Demonstrator.getConfig().getProperty("bcastAddr", "65535")))
    }
    
    public static int [] getAVPairIDs() {
        return avIds;
    }
    
    public static int [] getConstraintIDs() {
        return constrIds;
    }
    
    public static String getAttribName(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));
        
        if (attrib == null)
            return null;
        else
            return attrib.getName();
    }
    
    public static String getAttribDescription(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));        

        if (attrib == null)
            return null;
        else
            return attrib.getDescription();        
    }
    
    public static long getAttribMin(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));        
          
        if (attrib == null)
            return -1;
        else
            return attrib.getMin();      
    }
    
    public static long getAttribMax(int id) {    
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));
        
        if (attrib == null)
            return -1;
        else
            return attrib.getMax();              
    }
    
    public static int [] getOperationIDs(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));
        if (attrib == null)
            return null;
        
        Map opMap = attrib.getOperations();
        if (opMap == null)
            return null;
        
        Vector opIdVector = new Vector();
            
        for (Iterator it=opMap.keySet().iterator(); it.hasNext();) {
                
            Integer opId = (Integer)it.next();
            opIdVector.addElement(opId);
        }
                
        int [] opIds = new int[opIdVector.size()];
        
        int cnt = 0;
        for (Iterator it=opIdVector.iterator(); it.hasNext(); ) {                
            opIds[cnt++] = ((Integer)it.next()).intValue();
        }
        
        return opIds;
    }
    
    public static String getOperationName(int attrId, int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(attrId));        

        if (attrib == null)
            return null;
        
        Map operations = attrib.getOperations();
        Operation op = (Operation)operations.get(new Integer(id));
        
        if (op == null)
            return null;
        else
            return op.getName();
    }
    
    public static String getPreferrredVisualization(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));
        
        if (attrib == null)
            return null;
        else
            return attrib.getPreferredVisualization();        
    }
            
    public static String getMetricConversion(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));
        
        if (attrib == null)
            return null;
        else
            return attrib.getMetricConversion();        
    }
    
    short [] toShortArr(long in, int dim, int endianness) {      
        short [] ret = new short[dim];
        for (int i=0; i<dim; i++) {
            switch (endianness) {
                case ENDIANNESS_BIG:
                    ret[dim-1-i] = (short)(in % 256);
                    break;
                case ENDIANNESS_LITTLE:
                    ret[i] = (short)(in % 256);
                    break;
                default:
                    System.err.println("Endianness #" + endianness + " unknown!");
                    return null;
            }

            in /= 256;
        }
        return ret;
    }
    
    short [] longToShortArray(long value, int attrID) {            
        int dim=0;
        int typeID=getType(attrID);
        int endiannessID = getEndianness(attrID);
        
        switch (typeID) {        
            case TYPE_UINT16:
                dim = 2;
                break;
            case TYPE_UINT32:
                dim = 4;
                break;
            default:
                System.err.println("Value type #" + typeID + " unknown!");
                return null;                    
        }
        
        return toShortArr(value, dim, endiannessID);        
    }
    
    public static int getType(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));
        
        if (attrib != null) {
            String type = attrib.getType();
            
            for (int index=0; index<types.length; index++) {
                if (types[index].equalsIgnoreCase(type))
                    return index;
            }
        } 
        return -1;
    }
    
   public static Object arrayToObject(Short [] value, int attrID) {
        int size = value.length;
        
        switch (getType(attrID)) {
            case TYPE_UINT16:
            case TYPE_UINT32:
                long res = 0;
                double dRes = 0;
                JEP jep = null;
                for (int j=0; j<size; j++) {
                    res += value[size-j-1].shortValue() << j*8;
                }
                if ((jep=ConfigComponent.getJepObject(attrID)) != null) {
                    dRes = res;
                    jep.addVariable("x", dRes);
                    double resConv = jep.getValue();
                    
                    if (!jep.hasError())
                        return new Double(resConv);
                    else
                        System.err.println("JEP.getValue() Error !");
                }
                
                return new Long(res);
                
            case TYPE_TEXT:
                char [] charArr = new char[size];
                for (int j=0; j<size; j++) {
                    charArr[j] = (char)value[j].shortValue();
                }
                return String.valueOf(charArr);
                
            default:
                return null;                
        }        
    }
   
   public static int getEndianness(int id) {
        Attribute attrib = (Attribute)aw.getAttributesMap().get(new Integer(id));
        
        if (attrib != null) {
            String endianness = attrib.getEndianness();
            
            for (int index=0; index<types.length; index++) {
                if (endiannesses[index].equalsIgnoreCase(endianness))
                    return index;
            }
        } 
        return -1;       
   }   
}
