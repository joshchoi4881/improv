/* 

Author: Emily Li

Helper functions for improv
Using MidiLib from https://github.com/MarquisdeGeek/midilib

*/



/*
 * miditest.c - Test suite for Steev's MIDI Library 
 * Version 1.4
 *
 *  AUTHOR: Steven Goodwin (StevenGoodwin@gmail.com)
 *			Copyright 2010, Steven Goodwin.
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License as
 *  published by the Free Software Foundation; either version 2 of
 *  the License,or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef  __APPLE__
#include <malloc.h>
#endif
#include "midifile.h"
#include "improv.h"

/* write another function to call render with same arguments as our language, pass in Note_Arr */

void render(Note_Arr* noteArr, int key, int tempo){
  render_backend(noteArr->arr, noteArr->len, )

}

int* getKey(int key){
  switch(key){
    case CMAJ:
      return cmaj;
    case CSHARPMAJ:
      return csharpmaj;
    case DMAJ:
      
  } 
}



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
      printf("tone: %d, rhythm: %d\n", notes->tone, notes->rhythm);

      midiTrackAddNote(mf, 1, key[notes->tone], rhythms[notes->rhythm], MIDI_VOL_HALF, TRUE, FALSE);
    }

		midiFileClose(mf);
		}
  

}


int main(int argc, char* argv[])
{
  int i;
  int len = 5;

  /* need to pass in array of notes */

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
