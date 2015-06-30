
includes common_header;

interface GenericFlash 
{
    command result_t init();
    event result_t initDone(result_t r);

    command pageptr_t numPages();
    
    command result_t write(pageptr_t page, offsetptr_t offset,
                           void *data, datalen_t len);
    event result_t writeDone(result_t r);

    command result_t falRead(pageptr_t page, offsetptr_t offset,
                             void *header, 
                             void *app_buff, datalen_t app_len, 
                             void *data_buff);
    event result_t falReadDone(result_t r);

    command result_t read(pageptr_t page, offsetptr_t offset,
                          void *app_buff, datalen_t app_len);
    event result_t readDone(result_t r);

    command result_t erase(pageptr_t page);
    event result_t eraseDone(result_t result);
}
