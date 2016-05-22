# Ray Marching Sandbox

A simple project showing how to integrate a signed distance field (SDF) based
ray marcher into Unity's deferred shading pipeline.

![Screenshot](http://i.imgur.com/g25vLbp.png)

Our implementation fills in the necessary information garnered from the virtual
scene's SDF into Unity's G-buffer, into which Unity further writes, throughout
the G-buffer construction part of its deferred shading pipeline.

The result is a seamless composition of our virtual scene and the actual scene
in Unity.

## License

The author(s) of this software hate viral software licenses (hi, GPL) and
really annoying stuff like software patents. That's why this entire thing is
wholly public domain, yo!

Any being (not just humans) is free to copy, modify, publish, use, compile,
sell or distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any means.

## Contributors

Here's a list of great apes that pressed a few keys on this weird thing called
a keyboard, or gave some feedback about why shit is going bonkers, and made
stuff happen on the screen:

* Goksel Goktas (author)
* Jens Holm (author)
* ~~Sly~~ Tim Cooper
* Kasper Engelstoft
