# Chess 256

![Chess256 logo](https://raw.githubusercontent.com/alex65536/Chess256/master/Images/Icons/Icon72.png)

Welcome to the _Chess 256_ reposiory! :)

# Contents

* [About the program](#about-the-program)
* [Screenshots](#screenshots)
* [Features](#features)
* [Missing things](#missing-things)
* [History](#history)
* [Supported platforms and pre-requisites](#supported-platforms-and-pre-requisites)
* [Building _Chess 256_](#building-chess-256)
* [Third-party software used by _Chess 256_](#third-party-software-used-by-chess-256)
* [License info](#license-info)

# About the program

_Chess 256_ is a chess program for playing, editing and analysing chess games. This project was supposed to be a very powerful chess application, but many features are missing by now. Though, many basic things have been already implemented.

The project is in **ALPHA** state.

# Screenshots

![Screenshot](https://raw.githubusercontent.com/alex65536/Chess256/master/Screenshot.png)

# Features

* Support for standard chess formats (PGN for chess notation, FEN for positions and UCI chess protocol).

* Powerful PGN editor (support for comments, NAGs, variations...).

* Playing games between players, between engines and player vs engine.

* Also there is analysis mode, where you can add variations, comments, etc.

* Advanced time control options (you can define options like this: `2 hours per 40 moves, then 1 hour per following 20 moves and then 1 hour for the rest of the game`.

* Written on _Free Pascal_ using _Lazarus IDE_

# Missing things

* Game analysis.

* Charts showing position cost change in different moments of time.

* Notation nodes showing position cost and time stamp.

* Advanced notation features, such as diagrams.

* Games database.

* Support for a wider range of chess engines (WinBoard/XBoard, ...)

* Notation printing and exporting (to RTF, PDF, ...)

* Customization, custom icon sets, board pieces, etc.

Some missing things may also be found in [Todo.txt](https://github.com/alex65536/Chess256/blob/master/Todo.txt).

# History

I started this project in 2016. The purpose was to make a complete chess environment that has a wide range of features. I didn't know about _git_ and _GitHub_ at that moment of time, so previous version of _Chess 256_ were kept locally, without any version control system. In this period of time, the core of the project was developed: chessboard, clock, notation, engine subsystem and so on. But I abandoned the development.

In January 2018, I found this project and decided to release it under the GNU GPL. It took me some time to reformat all the sources and add GPL license headers for this.

I don't know if the development of _Chess 256_ will continue. But everyone is welcome to contribute to this repository and I will accept patches and, if there will be enough attention to my project, I will continue development :)

Many things has changed from 2016, especially in _Lazarus_ and _FPC_, many things were improved in them. So, there is some legacy code in _Chess 256_ to replace parts of _Lazarus_ that were unstable or missing in 2016 (e. g. imitation docked interface instead of using _AnchorDocking_ package). This parts will be removed.

# Supported platforms and pre-requisites

At first, it uses _FPC/Lazarus_ and, as _Lazarus_ states, "write once, compile anywhere". But, as it appears, _Chess 256_ doesn't work correctly with some widgetsets.

_Chess 256_ is tested to work correctly on _Windows_ and _GNU/Linux_. The best supported widgetset is _gtk2_. _win32_ widgetset also works pretty well, but the chessboard renders uglier.

Other widgetsets are not tested or unsupported:

* _qt_ (and _qt5_) has problems with rendering the notation.

* _fpgui_ and _customdrawn_ (checked on _GNU/Linux_) have problems with even lauching the program.

* _carbon_ and _cocoa_ are not tested.

_Chess 256_ successfully builds on _Lazarus 1.8_ with _FPC 3.0.4_, but with some fixes it can be easily built in _Lazarus 1.6.x_ with _FPC 3.0.x_. Older versions of _FPC_ and _Lazarus_ were not tested. 

[Stockfish](https://stockfishchess.org) is the default chess engine for _Chess 256_. You will need the _stockfish_ executables to run the program successfully. Now, the _stockfish_ binaries can be found in [`Binary/`](https://github.com/alex65536/Chess256/tree/master/Binary) directory, but it's planned to remove the executable from the repo and to add _stockfish_ as a git subproject with building it from sources.

# Building _Chess 256_

The building process should pass without any troubles. You can easily build the project from _Lazarus IDE_ or using command-line tools, such as `lazbuild`.

But first, you may need to install the _CmdBox_ package into the IDE (located at [`Packages/CmdBox`](https://github.com/alex65536/Chess256/tree/master/Packages/CmdBox)).

# Third-party software used by _Chess 256_

* [Stockfish](https://stockfishchess.org) chess engine

* CmdBox package which provides a command line component for the debug console. _**NOTE**_: _Chess 256_ uses the modified version of _CmdBox_, which adds some new methods to this component. The modified version can be found in this repo, [`Packages/CmdBox`](https://github.com/alex65536/Chess256/tree/master/Packages/CmdBox) directory.

# License info

**License:** GPL 3+.

_Chess 256_ is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License](https://www.gnu.org/licenses/gpl.html) as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

_Chess 256_ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU General Public License](https://www.gnu.org/licenses/gpl.html) for more details.

This repository also contains the _Stockfish_ chess engine binaries, which is also distributed under GNU GPL, version 3 or later. According to GPL, I must give a link where to obtain _Stockfish_ sources. [Here it is :)](https://github.com/official-stockfish/Stockfish)
