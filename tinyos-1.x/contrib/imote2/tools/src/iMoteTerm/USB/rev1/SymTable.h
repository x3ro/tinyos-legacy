#ifndef __CSYMTABLE_H
#define __CSYMTABLE_H

typedef struct Binding *Binding_T;

class CSymTable{
public:
	CSymTable();
	~CSymTable();
	int getLength();
	bool put(const char *pcKey, const void *pvValue);
	bool remove(const char *pcKey);
	bool contains(const char *pcKey);
	void *get(const char *pcKey);
	void map(void (*pfApply)(const char *pcKey, void *pvValue, void *pvExtra), const void *pvExtra);
private:
	int iSize;
	int iBuckets;
	Binding_T *pbList;
	unsigned int hash(const char *pcKey);
	int incBuckets(int iPrevBuckets);
	void expand();
};


#endif
