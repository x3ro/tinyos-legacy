#pragma once

class CDynArray
{
private:
	int iSize;
	int iCapacity;
	int *ppvArray;
	void Grow();
public:
	CDynArray();
	~CDynArray();
	void Add(int i);
	int Get(int line);
	int GetSize();
	void Clear();
	void Pop();
};
