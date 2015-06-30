package net.tinyos.tosser;

import java.io.File;

public class TOSComponent {
    private File file;
    private boolean isCompound;
    
    public TOSComponent(File file) {
	this.file = file;
	this.isCompound = file.getName().endsWith(".desc");
    }

    public String getName() {
	String name = file.getName();
	return name.substring(0, name.length() - 5);
    }

    public boolean isCompound() {
	return isCompound;
    }

    public File getFile() {
	return file;
    }
}
