
/*
 * The RootDirectory object
 */
includes app_header;

interface RootDirectory
{
    event void initDone(result_t result);

    command result_t setRoot(uint8_t id, flashptr_t *save);

    event void setRootDone(result_t result);

    command result_t getRoot(uint8_t id, flashptr_t *ptr);

    event void getRootDone(result_t res);

    /* 
       This event is triggered when the root dir discovers a crash has
       occurred -> it restores the state of the checkpoint component. 
       (The checkpoint component in turn is supposed to restore the state
        of the storage objects linked to it...)
     */
    event void restore(flashptr_t *restore_ptr);
}
