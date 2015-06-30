struct Queue_t {
	uint8_t currentIndex;
	uint8_t queueSize;
	uint8_t maxSize;
	void **items;
};
typedef struct Queue_t *QueuePtr;

