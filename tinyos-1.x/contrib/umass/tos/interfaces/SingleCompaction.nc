
includes app_header;
includes SingleStream;

interface SingleCompaction
{
    command result_t compact(stream_t *stream_ptr, uint8_t agingHint);

    event void compactionDone(stream_t *stream_ptr, result_t res);
}
