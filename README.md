# ATExt

Table of contents:
 1. Overview
 2. Usage
 3. Implementation Details
 4. Acknowledgements
 5. Future

## 1. Overview

Synchronized text-editor project by ATE.

Lightweight program to do Google Docs-like real-time synchronized file editing with multiple collaborators right in the command prompt, without the need for a browser.

### 1.1. Developers

Planned, designed, implemented by the members of ATE, Albert Zhang, Timothy Ng, Eyal Sela. Developed as final project for CS 3110: Functional Programming and Data Structures at Cornell University.

### 1.2. Features

- Basic file editing, creating, saving. Inserting, moving, deleting, returning.
- GUI with colored cursors, scrolling.
- Multiple simultaneous collaborators. Changes appear in real time on all collaborators' screens.

## 2. Usage

Currently, usage instructions are for users with the CS 3110 virtual machine running OCaml 4.02 or later. Compilation using Ocamlbuild is also possible, but not described below.

### 2.1. Short Version

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

### 2.2. Details and Connecting Over Internet

#### 2.2.1. Setting Up Virtual Machine

If you are running this inside the CS 3110 virtual machine, you need to set up port forwarding in order to be connected to. For the machine that will act as the host, go to the settings of the virtual machine, and go to Network and click Port Forwarding. Add a new row with any name and the port number, 8484 for example, to both the Host Port and Guest Port fields.

#### 2.2.2. Initializing the Host

Any machine can be the host. Any instance of the program can host. The host and the guest are different modes bundled into the program; it just depends on the arguments given to the program. Note that both host and guest may edit the file.

To run as host, use:
```
cs3110 run writer.ml -- host 8484 helloworld.txt
```
You may replace `8484` with any number you chose in the previous step for the port number. You may replace `helloworld.txt` with any file name. If the file does not exist, it will be created with path `myfiles/helloworld.txt`.

After the host has initialized, you are ready! Type something into the empty file (or a non-empty file, if you chose a file name matching a non-empty file).

#### 2.2.3. Initializing the Guest

First, determine the IP of the host. This IP on OS X is listed under `en0:` and next to `inet`. I don't know much about this part, either, so you may have to try different addresses. Say, for now, this number is `10.130.130.70`. (If you have a DNS address, lookup is automatic.)

To connect to the host, use:
```
cs3110 run writer.ml -- guest 10.130.130.70 8484
```
Again, note that the numbers need to be changed.

You may connect from a different computer or from the same computer. If connecting from the same computer, you may use `localhost` instead of the IP address. In our trials there was no need to disable the host computer's firewall.

At this point, you are ready.

#### 2.2.4. Editing, Leaving, Saving

Observe a collaborative feature reminiscient to Google Docs, but for files on your computer, taking place right in your command line.

To exit client, simply press Esc. Your copy of the file will automatically be saved as `myfiles/helloworld.txt` (or any name the host gave it). You may join again using the above instructions.

To exit host, also press Esc. Your copy of the file will automatically be saved as `myfiles/helloworld.txt` (or any name that you gave it). Note that when the host leaves, all of the guests are forced to leave. The transfer of host has not been implemented due to the time limit on developing this final project.

## 3. Implementation Details

The GUI is the command line window. We use OCaml Curses for the GUI. It only supports 6 colors. The maximum number of simultaneous collaborators is 99, but by default we limit seven collaborators. This can be changed in `writer.ml`. When there are more than seven collaborators, some will have the same color cursor. Your own cursor is always white, and no other cursor is white.

We don't support text selection via holding down the Shift key. However, your command line will support manual selection using the mouse pointer. Use this for copying and pasting.

Scrolling left, right, up, down is automatic.

Simultaneously text entry at the same location should not be problematic. If connecting over LAN, there should be no problems. If connected over the Internet, normal usage should also not cause problems. If your connection is very slow and you spam by holding down a key or keyboard mashing in attempt to break the asynchronous instruction handling, there could occasionally be misplaced characters.

## 4. Acknowledgements

We'd like to thank CS 3110 TAs Shiyu Wang and Jonathan Chan for listening to and answering our early questions.

We'd like to thank CS 3110 TA Patrick Cao for reading our design proposal and giving us detailed feedback as well as offering his available support.

We'd like to thank everyone who made OCaml and its modules, Async, Curses, Yojson, possible.

We'd like to thank CS 3110 Professor Michael Clarkson for the motivation of this project, for the guidance on approaching it, and for being a brilliantly knowledgeable and infinitely enthusiastic professor. We learned immensely about functional programming these four months.

## 5. Future

These features are not supported but are considered for future extensions:

 - Text selection and deleting selected text
 - Transfer of host status
 - Automatic detection of hosts in local area network
 - Encryption and password protection
 - Folder background synchronization
 - Change log (already implemented for debug; needs polishing for general use)
 - Syntax highlighting
