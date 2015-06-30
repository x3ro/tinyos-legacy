
/*
 * The stream storage object
 */
includes app_header;
includes sizes;

interface StreamIndex
{
    command result_t init(bool ecc);

    event void initDone(result_t res);

    /* Write more data to the stream */
    command result_t add(void *data, datalen_t len);

    event void addDone(result_t res);

    /* Tag the chunk just stored */
    command result_t setTag();

    event void setTagDone(result_t res, uint16_t tag);

    /* Start traversal at most recently written chunk */
    command result_t start_traversal(flashptr_t *start_ptr);

    /* Get previous stream chunk */
    command result_t next(void *data, datalen_t *len);

    event void nextDone(result_t res);

    /* Get data associated with the tag */
    command result_t getTag(uint16_t tag, void *data, datalen_t *len);

    event void getTagDone(result_t res);
}
