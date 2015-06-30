
includes PageNAND;
interface PageNAND {
    command nandpage_t numPages();

    command result_t init();
    event result_t initDone(result_t r);
    
    command result_t write(nandpage_t page, nandoffset_t offset,
                           void *data, nandoffset_t len);
    event result_t writeDone(result_t r);

    command result_t read(nandpage_t page, nandoffset_t offset,
                          void *buffer, nandoffset_t len);
    event result_t readDone(result_t r);

    command result_t falRead(nandpage_t page, nandoffset_t offset,
                          void *header, void *app_buff, nandoffset_t len, void *data_buff);
    event result_t falReadDone(result_t r);


    command result_t erase(nandpage_t page);
    event result_t eraseDone(result_t result);

    command result_t generateECC(void *data, nandoffset_t len, uint8_t *ecc);
    command result_t checkECC(void *data, nandoffset_t len, uint8_t *ecc);
    command result_t id(uint8_t *id);
}
