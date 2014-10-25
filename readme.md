# The Terrapin OS/API Collection


## What is Terrapin ?

Terrapin started as a smart movement api for turtles. It provided some safer
digging functions, movement functions and some extra basic inventory management
functions.

Over time it has grown into a full-blown turtle OS. It is mainly geared to
mining and farming tasks. It doesn't try to do any of the usual OS stuff like
user management, password locks, those don't make much sense in the context of a
turtle OS.


## Getting Started with Terrapin

To install terrapin download the bootstrap script
`terrapin/terrapin/programs/bootstrap.lua` to one of your turtles or computers.
It will download 2 files : the actual installer and a confguration file that
tells it what to download. It will then run the installer and install
everything.

The whole packages is about 400kb is size most of which is due to the inclusion
of [lua penlight](http://stevedonovan.github.io/Penlight/api/) library. Penlight
is a set of Lua modules that provide many useful methods. Most notably the
[tablex](http://stevedonovan.github.io/Penlight/api/modules/pl.tablex.html),
[stringx](http://stevedonovan.github.io/Penlight/api/modules/pl.stringx.html),
[class](http://stevedonovan.github.io/Penlight/api/modules/pl.class.html) and
[lapp](http://stevedonovan.github.io/Penlight/api/modules/pl.lapp.html#)
modules.

Future releases of penlight will tackle the task of removing some of the less
used parts of penlight but this is not a big priority at the moment.

Terrapin is not compatible with other computercraft operting systems. This is
because APIs are not loaded with `OS.LoadAPI` but with the `require` method. For
the system to work the method needs to be injected into the shell during the
startup.

Once you have installed it head over to the
[documentation](http://www.comkieffer.com/terrapin/doc/) to get started.

Check out the scripts section to see what you can do with the API, check out the
API documentation to learn how to use it.

## The Automatic checkin Functionality.

One of the more unusual features of Terrapin is the checkin functionality. The
turtle will automatically send messages to a remote server to keep it updated of
its status. This allows you to know what turtles are currently on, what they are
doing and where they are.

By default turtles will ping the server every minute. The message wil contain
the position of the turtle and its current position. You can also send messages
to the server manually. This allows you to send progress reports for tasks for
example.

Check out the documentation for the checkin module for more information on the
client-side aspect.

To actually use the checkin API you need to have the checkin server running.
Setting up will require Virtualbox and Vagrant.

	-- TODO : Installation instructions --

When the VM is up it should start the server automatically. The server is
implemented in Python on top of Flask + Tornado using Nginx as a reverse Proxy.

If there is enough demand I might take the time to set up a proper hosted
instance somewhere and open it up to anybody who asks.

