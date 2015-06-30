


module BufferManagementDispatchM{
  provides{
    interface BufferManagement as InsideBufferManagement;
  }
  uses{
    interface BufferManagement as OutsideBufferManagement;
  }
}
implementation{
  command uint8_t *InsideBufferManagement.AllocBuffer(uint32_t numBytes){
    return call OutsideBufferManagement.AllocBuffer(numBytes);
  }		
  
  /**
   * Release Buffer
   * @param buffer Previously allocated buffer
   * @return SUCCESS/FAIL 
   */
  command result_t InsideBufferManagement.ReleaseBuffer(uint8_t *buffer){
    return call OutsideBufferManagement.ReleaseBuffer(buffer);
  }		
}
