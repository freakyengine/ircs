# Instrument Remote Control Suite (IRCS)

This repository is intended to be a collection of simple software libraries to access remote-controllable electronic instruments. It basicly provides a generic instrument connector, which handles the different interfaces and related functionality.
The instrument itself is accessed via the SCPI commands. As those are almost uniqe for each instrumentation device, each device should have its own set of high-level functions. Those high-level functions are not in the scope of this repository.

## Matlab

The scripts provided require object orientation and, therefore, newer versions of Matlab. Currently, it is capable of native GPIB, TCPIP and [GPIBoE](https://github.com/freakyengine/GPIBoE-Gateway).
