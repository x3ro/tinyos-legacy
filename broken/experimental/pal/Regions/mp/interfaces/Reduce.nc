includes Reduce;
includes TupleSpace;

interface Reduce {

  /**
   * Reduce using the specified operator 'op' on 'value_key' of type
   * 'type' to 'root_addr'. The result will be stored in 'result_key' on 
   * the originating node.
   * 
   * @return SUCCESS if the reduction could be initiated; FAIL otherwise
   *   (for example, if another reduction is in progress).
   */
  command result_t reduceToOne(operator_t op, 
      ts_key_t value_key, ts_key_t result_key);

  /**
   * Reduce using the specified operator 'op' on 'value_key' of type
   * 'type'. The result will be stored in 'result_key' on all nodes
   * participating in the reduction. 
   * 
   * @return SUCCESS if the reduction could be initiated; FAIL otherwise
   *   (for example, if another reduction is in progress).
   */
  command result_t reduceToAll(operator_t op, ts_key_t value_key, 
      ts_key_t result_key);

  event void reduceDone(ts_key_t result_key, result_t success, float quality);

}

