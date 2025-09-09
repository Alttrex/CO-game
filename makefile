game: game.s
	mkdir bin 2> /dev/null;	gcc -no-pie -o bin/game game.s -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 

run: game
	./bin/game

debug:
	mkdir bin 2> /dev/null;	gcc -no-pie -o bin/game game.s -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -g
	gdb ./bin/game