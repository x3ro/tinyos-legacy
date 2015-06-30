/** ResultListener is an interface to delivery query results to the
    various UI panels that are a part of the TinyDB java tools.
    
    Implementers of this class register themselves with TinyDBNetwork.java,
    which will notify them when a result for the appropirate query arrives.
*/
package net.tinyos.tinydb;

public interface ResultListener {
    void addResult(QueryResult qr);
}
