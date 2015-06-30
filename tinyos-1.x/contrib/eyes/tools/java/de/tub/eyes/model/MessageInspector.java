/*
 * Created on Sep 20, 2004 by Joachim PRaetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.model;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

import net.tinyos.message.Message;

/**
 * This class can be utilized to inspect  TinyOS {@link net.tinyos.message.Message Message} or subclasses
 * of it. It provides easy access to the Methods and Fields of the Message class with the
 * use of Reflection
 * 
 * @author Joachim Praetorius
 *  
 */
public class MessageInspector {

    private Field[] fields;
    private Method[] methods;

    /**
     * Initialize Method. The MessageInspector inspects the given class and stores all available
     * Fields and Methods 
     * @param m the message class to inspect
     */
    public void inspect(Message m) {
        Class clazz = m.getClass();
        fields = clazz.getDeclaredFields();
        methods = clazz.getDeclaredMethods();
    }

    /**
     * Returns all fields declared in the class as an Array of {@link Field Field} Objects
     * @return The declared fields of the class
     */
    public Field[] getFields() {
        return fields;
    }

    /**
     * Returns all methods declared in the class as an Array of {@link Method Method} Objects
     * @return the declared methods of the class
     */
    public Method[] getMethods() {
        return methods;
    }

}