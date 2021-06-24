#include<stdio.h>
#include<stdlib.h>
#include<stdbool.h>
#include<string.h>
#include<ctype.h>

#define WORDLIST_FILE "wordlist.txt"
#define WORDRAND_FILE "wordrand.txt"

#define LINE_MAX 256



typedef struct Array Array;

struct Array {
	void **data;
	size_t size;
};

Array *Array_New() {
	Array *array=malloc(sizeof(*array));
	if(array) {
		array->data=NULL;
		array->size=0;
	}
	return array;
}

void Array_Add(Array **a,void *data) {
	(*a)->data=realloc((*a)->data,sizeof(*((*a)->data))*(((*a)->size)+1));
	if((*a)->data) {
		((*a)->data)[((*a)->size)++]=data;
	}
}

void Array_Print(Array *a,void Array_PrintData(void *data)) {
	for(size_t i=0;i<a->size;i++) {
		Array_PrintData(a->data[i]);
		printf("\n");
	}
	printf("\n");
}

void Array_Free(Array *a,void Array_FreeData(void *data)) {
	for(size_t i=0;i<a->size;i++) {
		Array_FreeData(a->data[i]);
	}
	free(a->data);
	a->data=NULL;
	a->size=0;
}

void Array_PrintWord(void *data) {
	printf("%s",(char*)data);
}

void Array_FreeWord(void *data) {
	free(data);
}

char *trim(char *str)
{
    size_t len = 0;
    char *frontp = str;
    char *endp = NULL;

    if( str == NULL ) { return NULL; }
    if( str[0] == '\0' ) { return str; }

    len = strlen(str);
    endp = str + len;

    /* Move the front and back pointers to address the first non-whitespace
     * characters from each end.
     */
    while( isspace((unsigned char) *frontp) ) { ++frontp; }
    if( endp != frontp )
    {
        while( isspace((unsigned char) *(--endp)) && endp != frontp ) {}
    }

    if( frontp != str && endp == frontp )
            *str = '\0';
    else if( str + len - 1 != endp )
            *(endp + 1) = '\0';

    /* Shift the string so that it starts at str so that if it's dynamically
     * allocated, we can still free it on the returned pointer.  Note the reuse
     * of endp to mean the front of the string buffer now.
     */
    endp = str;
    if( frontp != str )
    {
            while( *frontp ) { *endp++ = *frontp++; }
            *endp = '\0';
    }

    return str;
}



Array *loadWords(char *filename,int min ,int max) {
	Array *a=Array_New();
	FILE *fin=NULL;
	char line[LINE_MAX];
	int n=0;

	if((fin=fopen(filename,"r"))==NULL) {
		printf("Error: cannot open file %s",filename);
		exit(1);
	}

	while(fgets(line,LINE_MAX-1,fin)) {
		trim(line);
		n=strlen(line);
		if(n>=min && n<=max) Array_Add(&a,strdup(line));
	}

	fclose(fin);

	return a;
}


void saveWords(char *filename,Array *a) {
	FILE *fout=NULL;
	fout=fopen(filename,"w");
	for(size_t i=0;i<a->size;i++) {
		fprintf(fout,"%s\n",(char*)a->data[i]);
	}
	fclose(fout);
}


bool isZero(int *f) {
	for(int i=0;i<26;i++) {
		if(f[i]) return false;
	}
	return true;
}


int *freq(char *w) {
	int *f=calloc(26,sizeof(*f));
	for(size_t i=0;i<strlen(w);i++) {
		unsigned int ch=toupper(w[i]);
		if(isalpha(ch)) {
			f[ch-'A']++;
		}
	}
	return f;
}

bool isAnagram(char *w1,char *w2) {
	int *f1=freq(w1);
	int *f2=freq(w2);
	bool rv=true;
	if(isZero(f1) || isZero(f2)) rv=false;
	for(int i=0;i<26;i++) {
		if(f1[i]<f2[i]) {
			rv=false;
			break;
		}
	}
	free(f1);
	free(f2);
	return rv;
}

Array *getAnagrams(char *w1,Array *aw) {
	Array *an=Array_New();
	for(size_t i=0;i<aw->size;i++) {
		if(isAnagram(w1,aw->data[i])) {
			Array_Add(&an,strdup(aw->data[i]));
			if(an->size>=31) {
				break;
			}
		}
	}
	return an;
}



int main(void) {

	Array *aw = Array_New();
	Array *ar1 = Array_New();
	Array *ar2 = Array_New();
	Array *an = Array_New();

	aw=loadWords(WORDLIST_FILE,1,8);
	ar1=loadWords(WORDLIST_FILE,6,8);

	for(size_t i=0;i<ar1->size;i++) {
		printf("%s\n",(char*)ar1->data[i]);
		an=getAnagrams(ar1->data[i],aw);
		if(an->size>=10 && an->size<=30) {
			Array_Add(&ar2,strdup(ar1->data[i]));
		}
		Array_Free(an,Array_FreeWord);
	}

	saveWords(WORDRAND_FILE,ar2);

	return 0;
}

