package net.tinyos.gdi;

import java.rmi.Remote;
import java.rmi.RemoteException;
import java.util.Vector;

public interface GDIquery extends Remote {
    public Vector sqlQuery(String sql) throws RemoteException;
}
