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
  printf("<%d, %s>\n", note->tone, rhythm_map[note->rhythm]);
}

/* print arrays? */
void printa(){
}

void render(Note_Arr* noteArr, int key, int tempo){
  render_backend(noteArr->arr, noteArr->len, getKey(key), tempo);
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
  
  if ((mf = midiFileCreate("testpentatonic.mid", TRUE))){
		midiSongAddTempo(mf, 1, tempo);
		midiFileSetTracksDefaultChannel(mf, 1, MIDI_CHANNEL_1);
		midiTrackAddProgramChange(mf, 1, MIDI_PATCH_ELECTRIC_GUITAR_JAZZ);
		midiSongAddSimpleTimeSig(mf, 1, 4, MIDI_NOTE_CROCHET);

    for(i = 0; i < size; i++, notes++){
      /*
      printf("tone: %d, rhythm: %d\n", notes->tone, notes->rhythm); */
      midiTrackAddNote(mf, 1, key[notes->tone], rhythms[notes->rhythm], MIDI_VOL_HALF, TRUE, FALSE);
    }

		midiFileClose(mf);
		}
}

#ifdef BUILD_TEST
int main()
{
  int i;
  int len = 5;

  Note notes[len];
  notes[0].tone = 1;
  notes[0].rhythm = 1;
  notes[1].tone = 2;
  notes[1].rhythm = 2;
  notes[2].tone = 3;
  notes[2].rhythm = 3;
  notes[3].tone = 4;
  notes[3].rhythm = 4;
  notes[4].tone = 5;
  notes[4].rhythm = 5;

  for(i = 0; i < 5; i++){
    printf("tone: %d, rhythm: %d\n", notes[i].tone, notes[i].rhythm);
  }
  Note* ptr = notes;

  render(ptr, len, fminor, 96);

	return 0;
}
#endif
