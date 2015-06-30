package net.tinyos.tosser;

import java.io.*;
import javax.swing.filechooser.*;

public class FileChooserExtensionFilter 
     extends javax.swing.filechooser.FileFilter {
    private String extensions[];
    private String description;
    private boolean allowDirectories;

    public FileChooserExtensionFilter() {
        extensions = null;
    }

    public FileChooserExtensionFilter(String extensions[], 
                                      String description, 
                                      boolean allowDirectories) {
        this.extensions = extensions;
        this.description = description;
        this.allowDirectories = allowDirectories;
    }

    public boolean accept(File f) {
        if (allowDirectories && f.isDirectory())
            return true;

        if (extensions == null)
            return true;

        for (int i = 0; i < extensions.length; i++) {
            if (extensions[i].equalsIgnoreCase(getExtension(f)))
                return true;
        }

        return false;
    }
    
    public String getDescription() {
        return description;
    }

    private String getExtension(File f) {
        if (f != null) {
            String filename = f.getName();
            int i = filename.lastIndexOf('.');
            if (i > 0 && i < filename.length() - 1)
                return filename.substring(i + 1);
        }
        return null;
    }
}
