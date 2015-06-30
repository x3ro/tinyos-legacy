
/*
 * The stack storage object
 */
includes app_header;

interface Stack 
{
    command result_t init(bool ecc);

    /* Push an object onto the flash */
    command result_t push(void *data, datalen_t len, flashptr_t *save_ptr);

    event void pushDone(result_t res);

    /* Pop and object from the flash */
    command result_t pop(void *data, datalen_t *len);

    event void popDone(result_t res);

    /* Retrieve top-most object from the flash, but dont pop it*/
    command result_t top(void *data, datalen_t *len);

    event void topDone(result_t res);
}
