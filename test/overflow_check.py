#!/usr/bin/env python
# -*- coding: utf-8 -*-

import fontforge

def check_overflow(ttfpath):
    f = fontforge.open(ttfpath)
    for g in f.glyphs():
        if g.isWorthOutputting():
            bb = g.boundingBox()
            overflowX = bb[2] - bb[0]
            overflowY = bb[3] - bb[1]
            if overflowX > 1024 or overflowY > 1024:
                print(g)

check_overflow('./dist/Cica-Regular.ttf')
check_overflow('./dist/Cica-RegularItalic.ttf')
check_overflow('./dist/Cica-Bold.ttf')
check_overflow('./dist/Cica-BoldItalic.ttf')
