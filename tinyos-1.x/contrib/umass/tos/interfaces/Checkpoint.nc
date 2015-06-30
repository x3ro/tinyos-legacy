/*
 * The checkpointing component
 */
includes app_header;

interface Checkpoint 
{
    command result_t init(uint8_t id);

    command result_t checkpoint();

    command result_t rollback();

    event void checkpointDone(result_t result);

    event void rollbackDone(result_t result);
}
