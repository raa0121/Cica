#!/usr/bin/env python2
# vim:fileencoding=utf-8:noet

import argparse
import sys
import re
import os.path

from itertools import chain

try:
	import fontforge
	import psMat
except ImportError:
	sys.stderr.write('The required FontForge modules could not be loaded.\n\n')
	sys.stderr.write('You need FontForge with Python bindings for this script to work.\n')
	sys.exit(1)


def get_argparser(ArgumentParser=argparse.ArgumentParser):
	parser = ArgumentParser(
		description=('Font patcher for Powerline. '
		             'Requires FontForge with Python bindings. '
		             'Stores the patched font as a new, renamed font file by default.')
	)
	parser.add_argument('target_fonts', help='font files to patch', metavar='font',
	                    nargs='+', type=argparse.FileType('rb'))
	return parser


FONT_NAME_RE = re.compile(r'^([^-]*)(?:(-.*))?$')


def patch_one_font(target_font):
	target_font.upos = 45

	# Generate patched font
	extension = os.path.splitext(target_font.path)[1]
	if extension.lower() not in ['.ttf', '.otf']:
		# Default to OpenType if input is not TrueType/OpenType
		extension = '.otf'
	target_font.generate('{0}{1}'.format(target_font.fullname, extension))


def patch_fonts(target_files):
	for target_file in target_files:
		target_font = fontforge.open(target_file.name)
		try:
			patch_one_font(target_font)
		finally:
			target_font.close()
	return 0


def main(argv):
	args = get_argparser().parse_args(argv)
	return patch_fonts(args.target_fonts)


raise SystemExit(main(sys.argv[1:]))
