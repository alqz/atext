# atext
For synchronized text-editor project by ATE.

## About the Developer
Planned, designed, implemented by the members of ATE, Albert Zhang, Timothy Ng, Eyal Sela. Developed for Cornell University CS 3110 final project.

## Usage
In order to compile:
```
$ opam pin add utop https://github.com/cs3110/utop.git
$ opam update utop
$ opam upgrade utop
$ opam install curses
$ cs3110 compile writer.ml
```

To run:
```
cs3110 run writer.ml -- filename.extension
```

Replace `filename.extension` with whatever you desire. If the file does not exist, it will be created. After running, your command line display may not display as it usually does, due to the GUI changing the settings of the display. Use this to make it normal again:
```
stty sane
```
