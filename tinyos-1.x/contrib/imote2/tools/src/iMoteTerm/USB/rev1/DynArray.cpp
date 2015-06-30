#include "stdafx.h"
#include ".\dynarray.h"

CDynArray::CDynArray()
{
	iSize = 0;
	iCapacity = 2;
	ppvArray = (int *)malloc(sizeof(int) * iCapacity);
}

CDynArray::~CDynArray()
{
	free(ppvArray);
}

void CDynArray::Grow(){
	iCapacity *= 2;
	ppvArray = (int *)realloc(ppvArray, sizeof(int) * iCapacity);
}
void CDynArray::Add(int i){
	if(iSize >= iCapacity)
		Grow();
	ppvArray[iSize] = i;
	iSize++;
}
int CDynArray::Get(int line){
	if(line < iSize)
		return ppvArray[line];
	return -1;
}
int CDynArray::GetSize(){
	return iSize;
}
void CDynArray::Clear(){
	free(ppvArray);
	iSize = 0;
	iCapacity = 2;
	ppvArray = (int *)malloc(sizeof(int) * iCapacity);
}
void CDynArray::Pop(){
	if(iSize > 0)
		iSize--;
}