packages:
	opam install yojson
	opam install async
	opam install curses

clean:
	corebuild -clean
	rm -f myfiles/example_host.txt

build:
	corebuild -pkgs yojson,async,curses writer.byte

rebuild:
	make clean
	make build

exhost:
	./writer.byte host 8000 example_host.txt

exguest:
	./writer.byte guest 10.128.136.196 8000