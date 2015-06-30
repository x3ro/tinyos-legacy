/** QueryListeners are notified whenever a query
    is started or stopped.
*/
package net.tinyos.tinydb;

public interface QueryListener {
    void addQuery(TinyDBQuery q);
    void removeQuery(TinyDBQuery q);
}
