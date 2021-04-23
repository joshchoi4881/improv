#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Note{
  int tone;
  int rhythm;
} Note;

typedef struct Note_Arr {
    int len;
    Note *arr;
} Note_Arr;
