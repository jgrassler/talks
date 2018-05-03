# Magnum Debugging 101

This repository contains the *Magnum Debugging 101* presentation in two versions:

* A condensed 10 minute lightning talk version. Henceforth referred to as
  'short version'.

* An extended 40 minute regular version. Henceforth referred to as regular
  version.

Both versions are built using
[odpdown](https://github.com/thorstenb/odpdown). You can rebuild them by
running `make`. Building requires `make`, `pandoc`, `odpdown`, `M4` and `dia`.
Both presentations come with transcripts. To build them, install all
prerequisites and run `make`. You should then find the rendered presentation in
the magnum-debugging-101/ directory.

# FILES

* `lightning-{4-3,16-9}.{pdf,odp,md}: short version in various
  formats and aspect rations. Please do not edit any of these files! Edit their
  Markdown sources instead - see below for details.

* `lightning-transcript.{html,md}` transcript for the short version in
  HTML and Markdown format. For reading we recommend the HTML version since
  that integrates any figures shown in the slide.

* `full-{4-3,16-9}.{pdf,odp,md}: regular version in various
  formats and aspect rations. Please do not edit any of these files! Edit their
  Markdown sources instead - see below for details.

* `full-transcript.{html,md}` transcript for the regular version in
  HTML and Markdown format. For reading we recommend the HTML version since
  that integrates any figures shown in the slide.

* `full/`: raw markdown sources for regular version. The entry
  point is main.md. This file is processed by M4, so feel free to use M4 macros
  (`include(<filename>)` is probably the most useful.

* `lightning/`: raw markdown sources for short version. The entry
  point is main.md. This file is processed by M4, so feel free to use M4 macros
  (`include(<filename>)` is probably the most useful.

* `common/`: raw markdown sources for slides common to both versions.
  The files in this directory are processed by M4, so feel free to use M4 macros
  (`include(<filename>)` is probably the most useful.

* `img/` shared images for use in both presentations. Use paths relative to the
  repository's root directory to reference them. *.dia will automatically
  converted to *.PNG by the Makefile (use a `.png` extension for PNG files that
  do not need conversion).

* `cmd/` as they appear on slides.

* `output/` sample output from various commands as it appears on slides.
