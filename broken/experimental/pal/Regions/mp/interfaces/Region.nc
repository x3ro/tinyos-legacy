
interface Region {

  command result_t getRegion();
  event void getDone(result_t success);

  command int numNodes();
  command int getNodes(uint16_t **node_list_ptr);

}

