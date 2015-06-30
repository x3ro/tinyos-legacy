/**
 * This interface exposes the shared monitoring state
 *
 * Synchronization is provided by the shared structure
 * being accessed from task contexts.
 **/
includes DFDTypes;

interface MonitoringState {

  /**
   * Looks up a monitoring record for the node 
   * addr.
   * 
   * @param addr The address of the node
   * 
   * @return NULL if we are not monitoring this node,
   * pointer to the record if we are.
   **/
  command MonitorRec *lookup(uint16_t addr);

  /**
   *
   * Adds a monitoring record for this node,
   * sets up the data structures properly
   * 
   * @param addr Address of the node to add
   * 
   * @return NULL if there is no more space,
   * pointer to the record if we added successfully
   *
   **/
  command MonitorRec *add(uint16_t addr);
  event void added(uint16_t addr);

  /**
   * Delete a given node from list of monitored
   *
   * @param addr Address of the node
   *
   * @return SUCCESS if the node was located and deleted.
   **/
  command result_t del(uint16_t addr);
  event void deleted(uint16_t addr);

  /**
   * Check if I am monitoring a certain node
   * at this time
   *
   * @param addr Node address
   * 
   * @return TRUE if so.
   **/
  command bool amMonitoring(uint16_t addr);

  /**
   * Export the records and liveness opinions
   * about the nodes which we monitor.
   *
   * @param wl Pointer to the list of watched nodes
   * @param mask A bitmap where (bit at i == 1) => (node wl[i] is alive)
   **/
  command void exportWatched(NodeList *wl, uint32_t *mask);

  /**
   * Begins the iteration over the list of actively monitored
   * nodes
   *
   * @param mi Pointer to the iterator
   **/
  command void iterate(MonitorIterator *mi);

  /**
   * Iterates to the next actively monitored
   * node.  All iteration must happen within
   * the context of a single task to ensure
   * correctness of the semantics of this call.
   *
   * @param mi Pointer to the iterator
   *
   * @return Returns NULL when no more records
   * are available, or pointer to the next
   * monitoring record
   **/
  command MonitorRec *next(MonitorIterator *mi);
  
}
