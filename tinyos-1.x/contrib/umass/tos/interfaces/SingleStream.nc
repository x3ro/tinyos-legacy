
/*
 * The stream storage object
 */
includes app_header;
includes SingleStream;

interface SingleStream
{
    command result_t init(stream_t *stream_ptr, bool ecc);

    /* Write more data to the stream */
    command result_t append(stream_t *stream_ptr, void *data, datalen_t len, flashptr_t *save_ptr);

    event void appendDone(stream_t *stream_ptr, result_t res);

    /* Start traversal at most recently written chunk */
    command result_t start_traversal(stream_t *stream_ptr, flashptr_t *start_ptr);

    /* Get previous stream chunk */
    command result_t next(stream_t *stream_ptr, void *data, datalen_t *len);

    event void nextDone(stream_t *stream_ptr, result_t res);
}
