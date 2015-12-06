# ATExt

## Overview

Synchronized text-editor project by ATE.

Lightweight program to do Google Docs-like synchronized file editing with your collaborators right in your command prompt, without the need for a browser.

### About the Developer

Planned, designed, implemented by the members of ATE, Albert Zhang, Timothy Ng, Eyal Sela. Developed as final project for CS 3110: Functional Programming and Data Structures at Cornell University.

### Features

Basic file editing, creating, saving. Inserting, moving, deleting, returning.

GUI with colored cursors, scrolling.

Multiple simultaneous collaborators. Changes appear in real time on all collaborators' screens.

## Usage

### Short Version

Need to install OCaml Curses first.
```
opam install curses
```
Make sure your utop is up to date.
```
opam pin add utop https://github.com/cs3110/utop.git
opam update utop
opam upgrade utop
```
Then compile using:
```
cs3110 compile writer.ml
```
To run, use one of the following:
```
cs3110 run writer.ml -- [filename]
cs3110 run writer.ml -- host [port] [filename]
cs3110 run writer.ml -- guest [ip or dns address] [port]
```
The first one is offline mode. The second one is to host a document. The third one is to join another's hosted document.

### Details and Connecting Over Internet

#### Setting Up Virtual Machine

If you are running this inside the CS 3110 virtual machine, you need to set up port forwarding in order to be connected to. For the machine that will act as the host, go to the settings of the virtual machine, and go to Network and click Port Forwarding. Add a new row with any name and the port number, 8484 for example, to both the Host Port and Guest Port fields.

#### Initializing the Host

Any machine can be the host. Any instance of the program can host. The host and the guest are different modes bundled into the program; it just depends on the arguments given to the program. Note that both host and guest may edit the file.

To run as host, use:
```
cs3110 run writer.ml -- host 8484 helloworld.txt
```
You may replace `8484` with any number you chose in the previous step for the port number. You may replace `helloworld.txt` with any file name. If the file does not exist, it will be created with path `myfiles/helloworld.txt`.

After the host has initialized, you are ready! Type something into the empty file (or a non-empty file, if you chose a file name matching a non-empty file).

#### Initializing the Guest

First, determine the IP of the host. This IP on OS X is listed under `en0:` and next to `inet`. I don't know much about this part, either. Say this number is `10.130.130.70`.

To connect to the host, use:
```
cs3110 run writer.ml -- guest 10.130.130.70 8484
```
Again, note that the numbers need to be changed.

At this point, you are ready.

#### Leaving, Saving, and Usage

Observe a collaborative feature very similar to Google Docs, but for files right in your command line.

To exit client, simply press Esc. Your copy of the file will automatically be saved as `myfiles/helloworld.txt`. You may join again using the above instructions.

To exit host, also press Esc. Your copy of the file will automatically be saved as `myfiles/helloworld.txt`. Note that when the host leaves, all of the guests are forced to leave. The transfer of host has not been implemented due to the time limit on developing this final project.
