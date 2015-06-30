includes CompressedSet;

interface Roster {

  /**
   * Obtain the roster of nodes within the network
   *
   * @returns The set representation of live nodes
   **/
  command Set *getRoster();

}
