/*
 * Snapshot.java
 *
 * Created on 7. November 2005, 16:56
 */

package de.tub.eyes.apps.demonstrator;

import java.util.*;
import java.io.*;

import javax.swing.*;

/**
 *
 * @author Till Wimmer
 */
public class Snapshot {
    public final static int SNAPSHOT_NORMAL = 0;    
    public final static int SNAPSHOT_EMERGENCY = 1;
    public String registrar;
    
    private static Map data = new TreeMap();
    private static Vector handlers = new Vector();
    private static String snapshotFile = Demonstrator.getProps().getProperty("snapshotFile", "./demonstrator.snapshot");
    private static String lockFile = Demonstrator.getProps().getProperty("lockFile", "./demonstrator.lock");
    private static boolean regularlyStarted = false;
    
    /** Creates a new instance of Snapshot */
    public Snapshot() {
    }    
    
    public static void addSnapshotHandler(SnapshotHandler handler) {
        handlers.addElement(handler);
    }
    
    public static void fireSnapshot(int level) {
        // Dont overwrite an existing snapshot when GUI crashes in the very beginning
        if (!regularlyStarted)
            return;
        
        switch (level) {
            case SNAPSHOT_NORMAL:
                collectData();
                saveData();
                break;
            case SNAPSHOT_EMERGENCY:
                collectData();
                saveData();
                saveLock();
                break;
            default:
        }        
    }
    
    public static void fireRestore() {
        restoreData();
        pushSnapshot();
    }
    
    private static void collectData() {
        data.clear();
        
        for (Iterator it=handlers.iterator(); it.hasNext();) {
            SnapshotHandler handler = (SnapshotHandler)it.next();
            
            data.put(new Integer(handlers.indexOf(handler)), handler.getSnapshot());
        }
    }
    
    private static void saveData() {
        try {
            // Write to disk with FileOutputStream
            FileOutputStream f_out = new FileOutputStream(snapshotFile);
   
            // Write object with ObjectOutputStream
            ObjectOutputStream obj_out = new ObjectOutputStream (f_out);
        
            // Write object out to disk
            obj_out.writeObject ( data );
            
            obj_out.close();
        } catch (Exception  e) {
            System.err.println("saveData(): " + e.getLocalizedMessage()); 
            e.printStackTrace();
        }
    }
    
    private static void restoreData() {
        FileInputStream f_in = null;
        ObjectInputStream obj_in = null;
        try {             
            // Read from disk using FileInputStream
            f_in = new FileInputStream(snapshotFile);
        } catch (Exception  e) {
            System.err.println("restoreData:FileInputStream(): " + e.getLocalizedMessage());            
        }        
        try {
            
            // Read object using ObjectInputStream
            obj_in = new ObjectInputStream (f_in);
        } catch (Exception  e) {
            System.err.println("restoreData:ObjectInputStream(): " + e.getLocalizedMessage());
        }
        
        try {            
            // Read an object
            Object obj = obj_in.readObject();
            System.out.println("CLASS =" + obj.getClass().getName());
            if (obj instanceof TreeMap) {        
                // Cast object to a Vector
                data = (TreeMap) obj;
            }
        } catch (Exception  e) {
            System.err.println("restoreData:readObject(): " + e.getLocalizedMessage());            
        }
        
        try {
            f_in.close();
        } catch (Exception e) {
            System.err.println("restoreData:close(): " + e.getLocalizedMessage());                        
        }
    }
                    
    private static void saveLock() {
        //TODO: Write lock file
        File lock = new File(lockFile);
        
        if ( lock.exists() )
            return;
        
        try {
            lock.createNewFile();
        } catch (Exception e) {
            System.err.println("saveLock:create(): " + e.getLocalizedMessage());
            System.exit(3);
        }
        //lock.deleteOnExit();
    }
    
    private static void pushSnapshot() {
        for (Iterator it=handlers.iterator(); it.hasNext();) {

            SnapshotHandler handler = (SnapshotHandler)it.next();
            //System.out.println("pushSnapshot: " + handler);            
            TreeMap map = (TreeMap)data.get(new Integer(handlers.indexOf(handler)));
            
            if (map != null)
                handler.restoreSnapshot(map);
        }        
    }
    
    public static void checkIfLocked() {
        File lock = new File(lockFile);
        
        if ( lock.exists() ) {
            System.err.println("Lock file exists!");
            int ret = JOptionPane.showConfirmDialog(null,"An old lockfile was found. Should I try to restore a snapshot?",
                    "Lockfile found", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
                    
            if (ret == JOptionPane.OK_OPTION)
                fireRestore();
            
            lock.delete();
        }
        regularlyStarted = true;
    }
}
