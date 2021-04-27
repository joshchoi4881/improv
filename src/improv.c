#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef  __APPLE__
#include <malloc.h>
#endif
#include "midifile.h"
#include "improv.h"

/* print note literal */
void printn(Note note){
  char *rhythm_map[6] ={"wh", "hf", "qr", "ei", "sx"};
  printf("<%d, %s>\n", note.tone, rhythm_map[atoi(note.rhythm)]);
}

void printa(int len, int *arr){
  int i;
  printf("[");
  for(i = 0; i < len; i++, arr++){
    if(i == len-1){
      printf("%d", *arr);
    } else{
      printf("%d, ", *arr);
    }
  }
  printf("]\n");
}

int* getKey(int key){
  switch(key){
    case CMAJ:
      return cmaj;
    case CSHARPMAJ:
      return csharpmaj;
    case DMAJ:
      return dmaj;
    case DSHARPMAJ:
      return dsharpmaj;
    case EMAJ:
      return emaj;
    case FMAJ:
      return fmaj;
    case FSHARPMAJ:
      return fsharpmaj;
    case GMAJ:
      return gmaj;
    case GSHARPMAJ:
      return gsharpmaj;
    case AMAJ:
      return amaj;
    case ASHARPMAJ:
      return asharpmaj;
    case BMAJ:
      return bmaj;
    case CMIN:
      return cmin;
    case CSHARPMIN:
      return csharpmin;
    case DMIN:
      return dmin;
    case DSHARPMIN:
      return dsharpmin;
    case EMIN:
      return emin;
    case FMIN:
      return fminor;
    case FSHARPMIN:
      return fsharpmin;
    case GMIN:
      return gmin;
    case GSHARPMIN:
      return gsharpmin;
    case AMIN:
      return amin;
    case ASHARPMIN:
      return asharpmin;
    case BMIN:
      return bmin;
  } 
}

/* create midi file */
void render_backend(Note* notes, int size, char* filename, int key[], int tempo){
  MIDI_FILE *mf;
  int i;

  int rhythms[] = {MIDI_NOTE_BREVE, MIDI_NOTE_MINIM, MIDI_NOTE_CROCHET, MIDI_NOTE_QUAVER, MIDI_NOTE_SEMIQUAVER}; 
  
  if ((mf = midiFileCreate(filename, TRUE))){
		midiSongAddTempo(mf, 1, tempo);
		midiFileSetTracksDefaultChannel(mf, 1, MIDI_CHANNEL_1);
		midiTrackAddProgramChange(mf, 1, MIDI_PATCH_ELECTRIC_GUITAR_JAZZ);
		midiSongAddSimpleTimeSig(mf, 1, 4, MIDI_NOTE_CROCHET);

    for(i = 0; i < size; i++, notes++){
      /* printn(*notes); */
      midiTrackAddNote(mf, 1, key[notes->tone], rhythms[atoi(notes->rhythm)], MIDI_VOL_HALF, TRUE, FALSE);
    }

		midiFileClose(mf);
    printf("finished creating %s!\n", filename);
	}
}

void render(Note_Arr noteArr, char* filename, int key, int tempo){
  int *keyNotes = getKey(key);
  render_backend(noteArr.arr, noteArr.len, filename, keyNotes, tempo);
}

void printmidi(char* filename){
  TestEventList(filename);
}

void printnInternal(Note note){
  char *rhythm_map[6] ={"wh", "hf", "qr", "ei", "sx"};
  printf("<%d, %s>", note.tone, rhythm_map[atoi(note.rhythm)]);
}

void printNoteArr(Note_Arr a){
  int i;
  printf("[");
  for(i = 0; i < a.len; i++, a.arr++){
    if(i == a.len-1){
      printnInternal(*a.arr); 
    } else{
      printnInternal(*a.arr); 
      printf(", ");
    }
  }
  printf("]\n");
}

Note_Arr append(Note_Arr a1, Note_Arr a2){
  int i;
  Note_Arr result;
  result.len = a1.len + a2.len;
  result.arr = malloc(result.len * sizeof(Note));
  void *ptr = result.arr;

  int sizeofa1 = (a1.len)*sizeof(Note);
  int sizeofa2 = (a2.len)*sizeof(Note);

  memcpy(ptr, a1.arr, sizeofa1);
  memcpy(ptr+sizeofa1, a2.arr, sizeofa2);

  return result;
}