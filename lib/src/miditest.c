/* 

Helper functions for improv
Using MidiLib from https://github.com/MarquisdeGeek/midilib

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef  __APPLE__
#include <malloc.h>
#endif
#include "midifile.h"
#include "improv.h"

/* print note literal */
void printn(Note* note){
  char *rhythm_map[6] ={"wh", "hf", "qr", "ei", "sx"};
  printf("<%d, %s>\n", note->tone, rhythm_map[atoi(note->rhythm)]);
}

/* print arrays? */
void printa(){
}

int* getKey(int key){
  switch(key){
    case CMAJ:
      return cmaj;
    case CSHARPMAJ:
      return csharpmaj;
    case DMAJ:
      return dmaj;
  } 
}

/* create midi file */
void render_backend(Note* notes, int size, int key[], int tempo){
  MIDI_FILE *mf;
  int i;

  int rhythms[] = {MIDI_NOTE_BREVE, MIDI_NOTE_MINIM, MIDI_NOTE_CROCHET, MIDI_NOTE_QUAVER, MIDI_NOTE_SEMIQUAVER}; 
  
  if ((mf = midiFileCreate("testRender.mid", TRUE))){
		midiSongAddTempo(mf, 1, tempo);
		midiFileSetTracksDefaultChannel(mf, 1, MIDI_CHANNEL_1);
		midiTrackAddProgramChange(mf, 1, MIDI_PATCH_ELECTRIC_GUITAR_JAZZ);
		midiSongAddSimpleTimeSig(mf, 1, 4, MIDI_NOTE_CROCHET);

    for(i = 0; i < size; i++, notes++){
      printn(notes);
      midiTrackAddNote(mf, 1, key[notes->tone], rhythms[atoi(notes->rhythm)], MIDI_VOL_HALF, TRUE, FALSE);
    }

		midiFileClose(mf);
		}
}

void render(Note_Arr* noteArr, int key, int tempo){
  int *keyNotes = getKey(key);
  render_backend(noteArr->arr, noteArr->len, keyNotes, tempo);
}

int main()
{
  int i;
  Note *ptr = (Note *) malloc(5 * sizeof(Note));
  char buffer[2];
  Note_Arr noteArr = {5, ptr};

  for(i = 0; i < noteArr.len; i++){
    (ptr+i)->tone = i;
    (ptr+i)->rhythm = "1";
  }

  Note_Arr *arrPtr = &noteArr;

  render(arrPtr, 3, 96);

	return 0;
}