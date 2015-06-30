includes app_header;

interface Compaction
{
    command result_t compact(uint8_t agingHint);

    event void compactionDone(result_t res);
}
