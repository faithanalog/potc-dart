# Prelude of the Chambered in Dart

Play it [here](http://potc.artemis.sh/).

Based on this java code by an asshole: [https://github.com/skeeto/Prelude-of-the-Chambered](https://github.com/skeeto/Prelude-of-the-Chambered)

This project is a port of Prelude of the Chambered to Dart that I did many
years ago. I wrote it get better at dart, and test out the game library I was
working on at the time called [DTMark](https://github.com/faithanalog/DTMark).

DTMark is unmaintained, and it turns out the author of the original game is a
fascist, but I'm still proud of this regardless. I had to re-implement the
entire graphics engine in WebGL from scratch, since the original was a
raycasting software renderer, and doing that in javascript was not feasible at
any reasonable framerate. [I wrote more about that process at the time on my
blog](https://artemis.sh/2014/11/18/prelude-of-the-chambered-in-dart.html)

Since then I've lost interest in Dart and don't plan to update this project to
dart 2.x. It still builds with older darts though:

- grab dart 1.8.5 from [the archive](https://dart.dev/get-dart/archive).
- run `pub get` in this repo to grab dependencies
- run `pub build` to build the project. server the `build/web` directory as the root directory from a web server.

For the sake of archival I'm also pushing the `build` directory up so if I lose
the build again I don't have to go through the process of rebuilding it from
source.
