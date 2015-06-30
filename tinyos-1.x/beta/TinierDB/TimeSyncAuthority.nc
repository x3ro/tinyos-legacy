/**
 *
 * Determines whether a time synchronization
 * beacon from a node is authoritative.
 *
 * @author Stan Rost
 *
 **/
interface TimeSyncAuthority {

  command bool isAuthoritative(uint16_t addr);

}
