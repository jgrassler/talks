# Monasca - Project Onboarding

This repository contains the *Monasca - Project Onboarding* presentation.

It is built using [odpdown](https://github.com/thorstenb/odpdown). You can
rebuild them by running `make`. Building requires `make`, `pandoc`, `odpdown`,
`M4` and `dia`. Both presentations come with transcripts. To build them,
install all prerequisites and run `make`. Run `make monasca-onboarding.tar.bz2`
to create a distributable tarball.

# FILES


* `presentation-{4-3,16-9}.{odp,pdf}`: presentation in
  various formats and aspect ratios. Please do not edit any of these files!
  Edit their Markdown sources instead - see below for details.

* `transcript.{html,md}` transcript for the presentation in
  HTML and Markdown format. For reading we recommend the HTML version
  since that integrates any figures shown in the slide.

* `src/`: raw markdown sources for presentation. The entry
  point is main.md. This file is processed by M4, so feel free to use M4
  macros (`include(<filename>)` is probably the most useful.

* `img/` shared images for use in both presentations. Use paths relative to the
  repository's root directory to reference them. `*.dia` will be automatically
  converted to `*.PNG` by the Makefile (use a `.png` extension for PNG files that
  do not need conversion).

* `cmd/` commands as they appear on slides.

* `output/` sample output from various commands as it appears on slides.
