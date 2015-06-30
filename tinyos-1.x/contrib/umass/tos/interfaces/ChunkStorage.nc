
/*
 * file:        ChunkStorage.nc
 *
 */
includes chunk_header;
includes PageNAND;

interface ChunkStorage {
    /* Initialize NAND flash memory */
    
    /* 
     * Writes a record into Flash
     */
    command result_t write(void *data1, datalen_t len1,
                           void *data2, datalen_t len2, 
                           bool computeEcc, flashptr_t *save_ptr);
    event void writeDone(result_t res);

    /* 
     * Reads a page from flash
     */
    command result_t read(flashptr_t *ptr, 
                          void *data1, datalen_t len1, 
                          void *data2, datalen_t *len2, 
                          bool checkEcc, bool *ecc);
    event void readDone(result_t res);
    
    /* 
     * Flush current write buffer to flash
     */
    command result_t flush();
    event void flushDone(result_t res);

    command uint8_t percentagefull();

    /* NOTE : There is no erase supported on this interface */
}
