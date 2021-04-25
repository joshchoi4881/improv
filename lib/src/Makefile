CC=gcc
LINK = $(CC)
CFLAGS = -O2 -ansi -Wall
LDFLAGS = -s

all:	miditest   # mozart  mididump 

miditest:   miditest.c   midifile.o	
	$(CC) $(CFLAGS) $(LFLAGS) midifile.o miditest.c -o miditest 

# mozart: mozmain.c   mozart.c   midifile.o	
# 	$(CC) $(CFLAGS) $(LFLAGS) midifile.o mozart.c mozmain.c -o mozart 

# mididump: mididump.c midiutil.o midifile.o
# 	$(CC) $(CFLAGS) $(LFLAGS) midifile.o midiutil.o mididump.c -o mididump 

midifile.o:	midifile.c	midifile.h
midiutil.o:	midiutil.c	midiutil.h


install:
	@echo Just copy the files somewhere useful!

clean:
	rm -f *.o 
	rm -f miditest mozart mididump

