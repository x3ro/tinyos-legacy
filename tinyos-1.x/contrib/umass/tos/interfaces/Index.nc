/*
 * The array storage object
 */
includes app_header;

/* 
 * Note this array structure does not span multiple blocks - this assumes that the
 * entire array fits in one chunk.
 */
interface Index 
{
    command result_t load(bool ecc);
    event void loadDone(result_t res);

    command result_t save(flashptr_t *save_ptr);
    event void saveDone(result_t res);

    /* Set an array index */
    command result_t set(unsigned int arr_index, void *data, 
                         datalen_t len, flashptr_t *save_ptr);
    event void setDone(result_t res);

    /* Get an object from the flash */
    command result_t get(unsigned int arr_index, void *data, datalen_t *len);
    event void getDone(result_t res);

    command result_t delete(unsigned int arr_index);
	event void deleteDone(result_t res);
}
