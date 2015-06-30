
/*
 * The stream storage object
 */
includes app_header;

interface Stream
{
    command result_t init(bool ecc);

    /* Write more data to the stream */
    command result_t append(void *data, datalen_t len, flashptr_t *save_ptr);

    event void appendDone(result_t res);

    /* Start traversal at most recently written chunk */
    command result_t start_traversal(flashptr_t *start_ptr);

    /* Get previous stream chunk */
    command result_t next(void *data, datalen_t *len);

    event void nextDone(result_t res);
}
