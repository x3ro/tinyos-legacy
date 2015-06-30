includes FifoQueue;
interface FifoQueue {
	command QueuePtr initQueue(uint8_t emptyint[], uint8_t size);
	command uint8_t availableSpace(QueuePtr queue);
	command result_t enqueue(QueuePtr queue, void *item);
	command void *dequeue(QueuePtr queue);
	command void *getFirst(QueuePtr queue);
	command uint8_t isEmpty(QueuePtr queue);
	command uint8_t isFull(QueuePtr queue);
	command void print(QueuePtr queue);
}

