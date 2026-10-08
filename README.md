# Octave control package — Compatibility Update

This repository contains an **unofficial update of the GNU Octave `control` package**, with an updated version of the **Interactive Tool for Single Input Single Output (SISO) Linear Control System Design**.

The SISO interactive tool was originally developed in the [EriveltonGualter/octave-control](https://github.com/EriveltonGualter/octave-control) repository. The code in this repository includes updates to that tool to allow it to work with newer versions of GNU Octave.

This repository is **not the official repository for the GNU Octave `control` package** and is not maintained by or affiliated with the GNU Octave project.

The updated package was tested using **GNU Octave 11.3.0**.


## About

The **control** package is a collection of functions for control systems design and analysis.

This repository is based on the work in [EriveltonGualter/octave-control](https://github.com/EriveltonGualter/octave-control). The original project was based on an older version of the GNU Octave `control` package.

I made updates to the source code so that the package could be used with a newer version of GNU Octave. The updated package was tested using **GNU Octave 11.3.0**.

This repository can be used as a replacement for the **control package version 4.2.3**. It contains the complete source tree for the updated package, including the files and directories required to install the package.

The package archive `control-4.2.4.tar.gz` is also included in this repository and can be installed directly in GNU Octave.

## Installing the updated control package

The repository contains a ready-to-install package archive:

`control-4.2.4.tar.gz`

To install the package, first change to the directory containing this repository and the package archive.

Then, in GNU Octave, type

`pkg install control-4.2.4.tar.gz`<br>
`pkg load control`

The first command installs the package and the second command loads it into the current Octave session.

After loading the package, the `control` package functions should be available for use.

### Compatibility

The updated package was tested using:

* **GNU Octave 11.3.0**

The testing was performed using GNU Octave 11.3.0 to verify that the package could be installed, loaded, and used with this newer version of Octave.

Compatibility with other versions of GNU Octave has not necessarily been tested.

## Relationship to the official GNU Octave control package

This repository should not be confused with the official GNU Octave `control` package.

The official `control` package is maintained separately by the GNU Octave project and is available at the [official GNU Octave control repository](https://github.com/gnu-octave/pkg-control).

For the official package, current development, releases, and documentation, please refer to the official repository.

This repository is an **unofficial compatibility/update project** based on earlier `control` package source code.

## Original Source

The updates in this repository are based on the work available at [EriveltonGualter/octave-control](https://github.com/EriveltonGualter/octave-control).

The original project and its authors should be credited for the underlying work.

## Used Library SLICOT

The control package uses some routines from the [SLICOT-Reference library](https://github.com/SLICOT/SLICOT-Reference).

The SLICOT-related source files included in this repository are subject to the applicable SLICOT licensing terms.

The SLICOT files are available under the *BSD 3-Clause License*. The applicable license information is included with the source files.

## License

Please see the `COPYING` and other license files included in this repository for the licensing terms applicable to the source code.

## Disclaimer

This is an unofficial project. It is not an official release of the GNU Octave `control` package and is not affiliated with or endorsed by the GNU Octave project.

The package is provided as-is. Users should verify compatibility with the version of GNU Octave they are using.
