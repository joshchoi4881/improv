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

void render(Note* notes, int size, int key[], int tempo){
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


void TestScale(void)
{
MIDI_FILE *mf;

	if ((mf = midiFileCreate("test3.mid", TRUE)))
		{
		int i;
    int cmaj[] = {MIDI_OCTAVE_5, MIDI_OCTAVE_5+MIDI_NOTE_D, MIDI_OCTAVE_5+MIDI_NOTE_E, 
                  MIDI_OCTAVE_5+MIDI_NOTE_G, MIDI_OCTAVE_5+MIDI_NOTE_A,}; 

    /*
    int scale[] = {MIDI_OCTAVE_3, MIDI_OCTAVE_3+MIDI_NOTE_D, 
			MIDI_OCTAVE_3+MIDI_NOTE_E, MIDI_OCTAVE_3+MIDI_NOTE_F, MIDI_OCTAVE_3+MIDI_NOTE_G, 
			MIDI_OCTAVE_3+MIDI_NOTE_A, MIDI_OCTAVE_3+MIDI_NOTE_B, MIDI_OCTAVE_4+MIDI_NOTE_C,}; */

    midiSongAddKeySig(mf, 1, keyCFlatMin);

		/* Write tempo information out to track 1. Tracks actually start from zero
		** (this helps differentiate between channels, and ease understanding)
		** although, I'll use '1', by convention.
		*/
		midiSongAddTempo(mf, 1, 120);

		/* All data is written out to _tracks_ not channels. We therefore
		** set the current channel before writing data out. Channel assignments
		** can change any number of times during the file, and affect all
		** tracks messages until it is changed. */
		midiFileSetTracksDefaultChannel(mf, 1, MIDI_CHANNEL_1);

		midiTrackAddProgramChange(mf, 1, MIDI_PATCH_ELECTRIC_GUITAR_JAZZ);

		/* common time: 4 crochet beats, per bar */
		midiSongAddSimpleTimeSig(mf, 1, 4, MIDI_NOTE_CROCHET);

		for(i=0;i<8;i++)
			{
			/* midiTrackAddText(mf, 1, textLyric, sing[i]); */
			midiTrackAddNote(mf, 1, cmaj[i], MIDI_NOTE_CROCHET, MIDI_VOL_HALF, TRUE, FALSE);
			}
		midiFileClose(mf);
		}
}

void TestEventList(const char *pFilename)
{
MIDI_FILE *mf = midiFileOpen(pFilename);

	if (mf)
		{
		MIDI_MSG msg;
		int i, iNum;
		unsigned int j;

		midiReadInitMessage(&msg);
		iNum = midiReadGetNumTracks(mf);
		for(i=0;i<iNum;i++)
			{
			printf("# Track %d\n", i);
			while(midiReadGetNextMessage(mf, i, &msg))
				{
				printf("\t");
				for(j=0;j<msg.iMsgSize;j++)
					printf("%.2x ", msg.data[j]);
				printf("\n");
				}
			}

		midiReadFreeMessage(&msg);
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
