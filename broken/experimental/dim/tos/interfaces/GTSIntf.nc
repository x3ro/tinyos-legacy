/*-*- Mode:C++; -*-*/
interface GTS {
  /*
   * Command GTS.create() creates an empty data file named after 
   * *indexname.d*. It does not fill in the in-memory metadata, 
   * which is done by the command caller.
   * @param indexname The name of the index that calls the command
   */
  command result_t create(const char *indexname);

  /*
   * Event GTS.createDone() is triggered when command 
   * GTS.create() stops.
   * @param result Either GTS_OK or GTS_ERROR.
   */
  event result_t createDone(GTSresult_t result);

  /*
   * Command GTS.drop() removes both the data file and the metadata
   * file given *indexname*. The in-memory metadata should be removed
   * AFTER this command has been accomplished. 
   * @param indexname The name of the index that calls the command
   */
  command result_t drop(const char *indexname);

  /*
   * Event GTS.dropDone() is triggered when command 
   * GTS.drop() stops.
   * @param result Either GTS_OK or GTS_ERROR.
   */
  event result_t dropDone(GTSresult_t result);

  /*
   * Command GTS.open() reads in the metadata from the metadata file
   * given *indexname*. It does not touch the data file. This command
   * should be called AFTER the in-memory metadata has been created.
   * @param indexname The name of the index that calls the command
   * @param gp The in-memory metadata pointer
   */
  command result_t open(const char *indexname, GTSDescPtr gp);

  /*
   * Event GTS.openDone() is triggered when command 
   * GTS.open() stops.
   * @param result Either GTS_OK or GTS_ERROR.
   */
  event result_t openDone(GTSresult_t result);

  /*
   * Command GTS.close() uses the in-memory metadata to overwrite the 
   * metadata file given *indexname*. The in-memory metadata should 
   * be released AFTER this command has been accomplished.
   * @param indexname The name of the index that calls the command
   * @param gp The in-memory metadata pointer
   */
  command result_t close(const char *indexname, GTSDescPtr gp);

  /*
   * Event GTS.closeDone() is triggered when command 
   * GTS.close() stops.
   * @param result Either GTS_OK or GTS_ERROR.
   */
  event result_t closeDone(GTSresult_t result);

  /*
   * Command GTS.store() appends a tuple as given by *buffer* to the
   * end of the datafile *indexname.d*. For now it does not check 
   * duplicity and quota. But it will shortly.
   * @param indexname The name of the index that calls the command
   * @param gp The in-memory metadata pointer
   * @param buffer the in-memory tuple pointer
   */
  command result_t store(const char *indexname, GTSDescPtr gp, void *buffer);

  /*
   * Event GTS.storeDone() is triggered when command
   * GTS.store() stops.
   * @param result Either GTS_OK or GTS_ERROR
   */
  event result_t storeDone(GTSresult_t result);
}
	
