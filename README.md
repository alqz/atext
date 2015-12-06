# atext
For synchronized text-editor project by ATE.

## About the Developer
Planned, designed, implemented by the members of ATE, Albert Zhang, Timothy Ng, Eyal Sela. Developed for Cornell University CS 3110 final project.

## Usage
Need to install OCaml Curses first.
```
$ opam install curses
```
Make sure your utop is up to date.
```
$ opam pin add utop https://github.com/cs3110/utop.git
$ opam update utop
$ opam upgrade utop
```
Then compile using:
```
$ cs3110 compile writer.ml
```

To run, use one of the following:
```
cs3110 run writer.ml -- [filename]
cs3110 run writer.ml -- host [port] [filename]
cs3110 run writer.ml -- guest [ip or dns address] [port]
```
The first one is offline mode. The second one is to host a document. The third one is to join another's hosted document.
