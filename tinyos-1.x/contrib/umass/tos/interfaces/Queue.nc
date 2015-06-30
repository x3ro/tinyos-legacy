/*
 * The queue storage object
 */
includes app_header;

interface Queue 
{
    command result_t init(bool ecc);

    /* Push an object at the end */
    command result_t enqueue(void *data, datalen_t len, flashptr_t *save_ptr);

    event void enqueueDone(result_t res);

    /* Remove first object */
    command result_t dequeue(void *data, datalen_t *len);

    event void dequeueDone(result_t res);

    /* Retrieve front-most object, but do not remove it from the queue */
    command result_t front(void *data, datalen_t *len);

    event void frontDone(result_t res);
}
