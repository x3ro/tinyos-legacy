package net.tinyos.tosser;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;

public class TOS {
    private static String platform = "pc";
    
    public static final FileFilter compFilter = 
        new ExtensionFilter(new String[] {"comp"}, "TOS Component File", false);
    public static final FileFilter descFilter = 
        new ExtensionFilter(new String[] {"desc"}, "TOS Description File", false);
    public static final 
        javax.swing.filechooser.FileFilter fileChooserCompFilter = 
        new FileChooserExtensionFilter(new String[] {"comp"}, 
                                       "TOS Component File", true);
    public static final 
        javax.swing.filechooser.FileFilter fileChooserAppFilter = 
        new FileChooserExtensionFilter(new String[] {"desc"}, 
                                       "TOS Application", true);
    public static final FileFilter dirFilter =
        new ExtensionFilter(null, "Directories", true);
    
    public static final String TOSDirs[] = new String[] {
        "platform",
        "shared",
        "system"
    };

    public static boolean isValidTOSDir(File dir) {
        Vector necessaryDirs = new Vector(Arrays.asList(TOSDirs));
        String files[] = dir.list();

        for (int i = 0; i < files.length; i++) {
            if (necessaryDirs.size() == 0)
                break;

            Iterator iter = necessaryDirs.iterator();
            while (iter.hasNext()) {
                String necessaryDir = (String)iter.next();
                if (necessaryDir.equalsIgnoreCase(files[i])) {
                    necessaryDirs.remove(necessaryDir);
                    break;
                }
            }
        }

        if (necessaryDirs.size() == 0)
            return true;

        return false;
    }

    public static JMenu generateTOSSystemComponentMenu(File TOSDir) {
        JMenuItem menuItem;
        JMenu subMenu = new JMenu("Add System Component");
        if (isValidTOSDir(TOSDir)) {
            for (int i = 0; i < TOSDirs.length; i++) {
                JMenu subSubMenu = new JMenu(TOSDirs[i]);
                subMenu.add(subSubMenu);
                File dir = new File(TOSDir + File.separator + TOSDirs[i]);

                if (TOSDirs[i].equalsIgnoreCase("platform")) {
                    File platforms[] = dir.listFiles(dirFilter);
                    for (int j = 0; j < platforms.length; j++) {
                        JMenu subSubSubMenu = new JMenu(platforms[j].getName());
                        subSubMenu.add(subSubSubMenu);

                        File comps[] = platforms[j].listFiles(compFilter);
                        if (comps.length == 0) {
                            menuItem = new JMenuItem("(None)");
                            menuItem.setEnabled(false);
                            subSubSubMenu.add(menuItem);
                        } else {
                            for (int k = 0; k < comps.length; k++) {
                                menuItem = new JMenuItem(
                                        getFilenameWithoutExtension(comps[k]));
                                subSubSubMenu.add(menuItem);
                            }
                        }
                    }
                } else {
                    File comps[] = dir.listFiles(compFilter);
                    if (comps.length == 0) {
                        menuItem = new JMenuItem("(None)");
                        menuItem.setEnabled(false);
                        subSubMenu.add(menuItem);
                    } else {
                        for (int j = 0; j < comps.length; j++) {
                            menuItem = new JMenuItem(
                                    getFilenameWithoutExtension(comps[j]));
                            subSubMenu.add(menuItem);
                        }
                    }
                }
            }
        } else {
            subMenu.setEnabled(false);
        }

        return subMenu;
    }

    public static File findTOSSystemModule(File TOSDir, String compName) {
        if (isValidTOSDir(TOSDir)) {
            for (int i = 0; i < TOSDirs.length; i++) {
                File dir = new File(TOSDir + File.separator + TOSDirs[i]);

                if (TOSDirs[i].equalsIgnoreCase("platform")) {
                    File platform = new File(TOSDir + File.separator +
                                             TOSDirs[i] + File.separator +
                                             TOS.platform);
                    File comps[] = platform.listFiles(compFilter);
                    for (int j = 0; j < comps.length; j++) {
                        if (compName.equalsIgnoreCase(
                                getFilenameWithoutExtension(comps[j])))
                            return comps[j];
                    }
                } else {
                    File comps[] = dir.listFiles(compFilter);
                    for (int j = 0; j < comps.length; j++) {
                        if (compName.equalsIgnoreCase(
                                getFilenameWithoutExtension(comps[j])))
                            return comps[j];
                    }
                }
            }
        } 

        return null;
    }

    public static File findDescFile(File dotcomp) {
        String compName = getFilenameWithoutExtension(dotcomp);
        File dir = dotcomp.getParentFile();
        File descs[] = dir.listFiles(TOS.descFilter);
        for (int i = 0; i < descs.length; i++) {
            String name = getFilenameWithoutExtension(descs[i]);            
            if (compName.equalsIgnoreCase(name))
                return descs[i];
        }

        return null;
    }


    public static void setPlatform(String platform) {
        TOS.platform = platform;
    }

    private static String getFilenameWithoutExtension(File f) {
        String filename = f.getName();
        int i = filename.lastIndexOf('.');
        if (i > 0 && i < filename.length() - 1)
            return filename.substring(0, i);
        return filename;
    }
}
