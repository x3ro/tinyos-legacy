
/**
 * Internal dictionary commands
 * @author David Moss (dmm@rincon.com)
 */
 
interface InternalDictionary {

  /**
   * Internal method of checking to see whether a file is a dictionary file
   * @param focusedFile - the file to check
   * @return SUCCESS if the check will be made
   */
  command result_t isFileDictionary(file *focusedFile);
  
}

