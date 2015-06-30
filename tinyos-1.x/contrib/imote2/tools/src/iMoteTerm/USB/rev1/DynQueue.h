#pragma once

/* A DynQueue is an fifo queue whose length can expand dynamically. */
class CDynQueue
{
public:
	CDynQueue(void);
	~CDynQueue(void);
	int getLength();
	void *dequeue();
	void enqueue(const void *pvItem);
	void push(const void *pvItem); //puts an item at the head of the queue
	void *peek();
private:
	unsigned int iLength;
	unsigned int iPhysLength;
	unsigned int index;
	const void **ppvQueue;
	void shiftgrow();
};
