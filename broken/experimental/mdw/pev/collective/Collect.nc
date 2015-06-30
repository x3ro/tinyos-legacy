interface Collect {

  command void*[] collect_neighbor_data(mote_reading my_reading, 
      mote_reading *collected, int *collected_length);

}
