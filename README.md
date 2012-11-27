===============================
MAC UPLINK CAPACITY SIMULATION
==============================

While working on estimating uplink capacity at MAC level for VANETS, NS2 was selected as the simulator to be used and installed. Two versions were coded to formulate the required scenario.

SCENARIO:
========
Cars going from left to right with AP positioned 39 meters away from the path of vehicles.

VERSION 1:
=========
Cars will be generated with intervehicular distance distributed exponentially. They were made to loop around a fixed path where AP was placed. The number of cars generated was dependent on loop size.

PROBLEMS FACED:
==============
1. ARP was the most important problem that hindered developments in simulationo side for a long time.
2. The system required some time to stabilise (to reach post-ARP stage) and this was quite costly both in terms of speed and trace file size. This was the primary motivation to switch to version 2 of the scenario.
3. Randomness was not enough and hence results were not matching closely.

VERSION 2:
=========
Cars will be generated at different times which are distributed exponentially eventually leading to exponential distribution of interevehicular distance. AP position was maintained but the loops where removed and instead vehicles were moved back to starting point with high speed since NS does not detect node collisions. For the ARP problem vehicles were allowed to move one by one to complete ARP first and then since same vehicles are reused(ARP does nt expire in NS2) ARP wont be occuring.

ADVANTAGES:
1. Small trace file
2. ARP problem solved
3. Randomness increased

VERSION 1 – FILES
=================
There are two folders
1. scenario -> contains the scenario generation tcl file
2. scripts -> contains the trace file processing scripts

VERSION 2 – FILES
================
There are two folders
1. scenario -> contains the scenario generation tcl file
2. scripts -> contains the trace file processing scripts

NOTE:
The paths specified in scenario files have to be changed and corresponding files
have to placed at respective paths to execute successfully
