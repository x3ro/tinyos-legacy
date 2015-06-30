package net.tinyos.tosser;

import java.util.*;

class Tosser {
    private static Properties properties = new Properties();

    private static void setupDefaults() {
        properties.setProperty("editor", "gvim -f");
        properties.setProperty("tosdir", "/root/src/nest");
    }

    public static Properties getProperties() {
        return properties;
    }
    
    public static void main(String args[]) {
        setupDefaults();
        MainWindow window = new MainWindow("Tosser");
        window.setVisible(true);
    }
}
