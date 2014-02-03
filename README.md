Reactor
=======

This is a multi-language-output element studio for The Powder Toy. You can
create your elements inside TPT, live-test them and then let it export
equivalent Lua and C++ code.

Features
--------

* Graphic and update code generator
* Easy reaction creation
* Live testing

Installation
------------

1. Download the archive
2. Copy the folder 'reactor' from within this archive into your TPT folder
   (that's where your Powder.exe/.app/.whatever is)
3. If you already have a file called "autorun.lua" in there, open that with
   a text editor (not Word or WordPad but something like Editor)
4. Else, create a new empty file inside the folder and name it "autorun.lua".
   Be sure that you haven't named it "autorun.lua.txt" or something.
5. Prepend this line to the file:
       dofile "reactor/reactor.lua"
6. Save the file.

Usage
-----

When you start The Powder Toy after that, you'll see a new icon appearing in the
upper-right menu of the game screen (the little 'R'). Click it
and Reactor will appear on your screen.