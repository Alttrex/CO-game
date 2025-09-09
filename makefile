game: game.s
	mkdir bin;	gcc -no-pie -o bin/game game.s -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 

run: game
	./bin/game

debug: game
	gdb ./bin/game