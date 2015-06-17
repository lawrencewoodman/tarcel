tarcel
======
A Tcl packaging tool

Tarcel allows you to combine a number of files together to create a single tarcel file that can ben run by tclsh, wish, or can be sourced into another tcl script.  This makes it easy to distribute your applications as a single file.  In addition it allows you to easily create Tcl modules made-up of several files including shared libraries, and then take advantage of the extra benefits that Tcl modules provide such as faster loading time.

Requirements
------------
*  Tcl 8.6
*  [configurator](https://github.com/LawrenceWoodman/configurator_tcl) module

Definition of Terms
-------------------
<dl>
  <dt>tarcel</dt>
  <dd>A file that has been packaged with the tarcel script.  This is pronounced to rhyme with parcel.</dd>
  <dt>.tarcel</dt>
  <dd>The file that describes how to create the <em>tarcel</em> file.  Pronounced 'dot tarcel'.</dd>
  <dt>tarcel.tcl</dt>
  <dd>The packaging tool script.</dd>
</dl>

Usage
-----
Tarcel is quite easy to use and implements just enough functionality to work for the tasks it has been put to so far.

### Creating a package ###
To create a <em>tarcel</em> file you begin by creating a <em>.tarcel</em> file to describe how to package the <em>tarcel</em> file.  See below for what to put in this file.  You then use the <em>wrap</em> command of <em>tarcel.tcl</em> to create the package.

To create a <em>tarcel</em> called <em>t.tcl</em> out of <em>tarcel.tcl</em> and its associated files using <em>tarcel.tarcel</em> run:

    $ tclsh tarcel.tcl wrap -o t.tcl tarcel.tarcel

The <em>.tarcel</em> file may specifiy the output filename, in which case you don't need to supply `-o outputFilename`.

### Getting Information About a Package ###
To find out some information about a package use the <em>info</em> command of <em>tarcel.tcl</em>.  For the example above, to look at <em>t.tcl</em> run:

    $ tclsh tarcel.tcl info t.tcl

### Defining a .tarcel File ###
To begin with it is worth looking at the <em>tarcel.tarcel</em> file supplied in the repo.  This <em>.tarcel</em> file is used to wrap <em>tarcel.tcl</em>.

Contributions
-------------
If you want to improve this program make a pull request to the [repo](https://github.com/LawrenceWoodman/tarcel) on github.  Please put any pull requests in a separate branch to ease integration and add a test to prove that it works.

Licence
-------
Copyright (C) 2015, Lawrence Woodman <lwoodman@vlifesystems.com>

This software is licensed under an MIT Licence.  Please see the file, LICENCE.md, for details.
