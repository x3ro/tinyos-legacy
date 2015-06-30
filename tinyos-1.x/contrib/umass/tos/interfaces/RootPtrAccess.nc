
/*
 * This provides access to the root ptr of an object
 */
includes common_header;

interface RootPtrAccess
{
    command void setPtr(flashptr_t *setPtr);

    command void getPtr(flashptr_t *getPtr);
}
