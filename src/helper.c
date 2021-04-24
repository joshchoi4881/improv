#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Note{
  int tone;
  char rhythm[2];
} Note;

// note array ?
typedef struct Note_Arr {
    int len;
    Note *arr;
} Note_Arr;


void printbig(int c) {
  int index = 0;
  int col, data;
  if (c >= '0' && c <= '9') index = 8 + (c - '0') * 8;
  else if (c >= 'A' && c <= 'Z') index = 88 + (c - 'A') * 8;
  do {
    data = font[index++];
    for (col = 0 ; col < 8 ; data <<= 1, col++) {
      char d = data & 0x80 ? 'X' : ' ';
      putchar(d); putchar(d);
    }
    putchar('\n');
  } while (index & 0x7); 
}


int * concat_array(int* a, int* b){

}

// bbind note array

int main(){

}




void printbig(int c)
{
  int index = 0;
  int col, data;
  if (c >= '0' && c <= '9') index = 8 + (c - '0') * 8;
  else if (c >= 'A' && c <= 'Z') index = 88 + (c - 'A') * 8;
  do {
    data = font[index++];
    for (col = 0 ; col < 8 ; data <<= 1, col++) {
      char d = data & 0x80 ? 'X' : ' ';
      putchar(d); putchar(d);
    }
    putchar('\n');
  } while (index & 0x7); 
}

char char_lower(char c)
{
  return tolower(c);
}

char strget(char* c, int x)
{
  return *(c + x);
}

int is_stop_word(char * c){
  char word[100];
  char whitespace[100];

  FILE *file = fopen("stopwords.txt", "r");

  while(!feof(file)) {
      fscanf(file,"%[^ \n\t\r]s",word); 
      if(strcmp(c, word) == 0){
        fclose(file);
        return 1;
      }
      fscanf(file,"%[ \n\t\r]s",whitespace); 
  }

  fclose(file);
  return 0;

}

int word_count(char * str){
  int count = 0;
  int curr = 0;
  while(*str != '\0'){
    if (*str == ' ') {
      if (curr == 1){
        count = count + 1;
        curr = 0;
      }
    }
      
      if(*str != ' '){
        curr = 1;
      }
     str++;
  }

  if (curr == 1){
    count = count + 1;
  }

  return count;
}

char * string_at(char* str, int i, int size, int len){
  char char_string[2] = {str[i] , '\0'};
  char * buf = calloc(size, len);
  buf = strcpy(buf, char_string);
  return buf;
}

#ifdef BUILD_TEST
int main()
{
  char s[] = "HELLO WORLD09AZ";
  char *c;
  for ( c = s ; *c ; c++) printbig(*c);
}
#endif
