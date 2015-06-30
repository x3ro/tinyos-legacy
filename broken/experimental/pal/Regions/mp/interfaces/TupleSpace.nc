includes TupleSpace;

interface TupleSpace {

  command result_t get(ts_key_t key, uint16_t nodeaddr, void *buf);
  event void getDone(ts_key_t key, uint16_t nodeaddr, void *buf, 
      int buflen, result_t success);
  command result_t put(ts_key_t key, void *buf, int buflen);



}

