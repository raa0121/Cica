#!/bin/bash

#
# Cica Generator
cica_version="0.9"
#
# Author: Yasunori Yusa <lastname at save.sys.t.u-tokyo.ac.jp>
#
# This script is to generate ``Cica'' font from UbuntuMono and Circle M+ 1M.
# It requires 2-5 minutes to generate Cica. Owing to SIL Open Font License
# Version 1.1 section 5, it is PROHIBITED to distribute the generated font.
# This script supports following versions of inputting fonts.
# * UbuntuMono Version 001.010
# * Circle M+ 1M     Version 20111002
#                       20120411
#                       20121030
#                       20130430
#                       20130617
#
# Usage:
# 1. Install FontForge
#    Debian/Ubuntu: # apt-get install fontforge
#    Fedora/CentOS: # yum install fontforge
#    OpenSUSE:      # zypper install fontforge
#    Other Linux:   Get from http://fontforge.sourceforge.net/
# 2. Get UbuntuMono-R.ttf
#    from http://levien.com/type/myfonts/inconsolata.html
# 3. Get circle-mplus-1m-regular/bold.ttf
#    from http://mix-mplus-ipa.sourceforge.jp/
# 4. Run this script
#        % sh cica_generator.sh auto
#    or
#        % sh cica_generator.sh UbuntuMono-R.ttf circle-mplus-1m-regular.ttf circle-mplus-1m-bold.ttf
# 5. Install Cica
#        % cp -f Cica*.ttf ~/.fonts/
#        % fc-cache -vf
#

# Set familyname
cica_familyname="Cica"
cica_familyname_suffix=""

# Set ascent and descent (line width parameters)
cica_ascent=830
cica_descent=170

# Set bold width of ASCII glyphs
ascii_regular_width=0
ascii_bold_width=30

# Set path to fontforge command
fontforge_command="fontforge"

# Set redirection of stderr
redirection_stderr="/dev/null"

# Set fonts directories used in auto flag
fonts_directories=". ${HOME}/.fonts /usr/local/share/fonts /usr/share/fonts ${HOME}/Library/Fonts /Library/Fonts /cygdrive/c/Windows/Fonts"

# Set zenkaku space glyph
zenkaku_space_glyph=""

# Set flags
leaving_tmp_flag="false"
fullwidth_ambiguous_flag="true"
scaling_down_flag="true"

# Set filenames
modified_ubuntumono_generator="modified_ubuntumono_generator.pe"
modified_ubuntumono_regu="Modified-UbuntuMono-Regular.sfd"
modified_ubuntumono_bold="Modified-UbuntuMono-Bold.sfd"
modified_circlemplus1m_generator="modified_circlemplus1m_generator.pe"
modified_circlemplus1m_regu="Modified-circle-mplus-1m-regular.sfd"
modified_circlemplus1m_bold="Modified-circle-mplus-1m-bold.sfd"
cica_generator="cica_generator.pe"

########################################
# Pre-process
########################################

# Print information message
cat << _EOT_
Cica Generator ${cica_version}

Author: Yasunori Yusa <lastname at save.sys.t.u-tokyo.ac.jp>

This script is to generate \`\`Cica'' font from UbuntuMono and Circle M+ 1M.
It requires 2-5 minutes to generate Cica. Owing to SIL Open Font License
Version 1.1 section 5, it is PROHIBITED to distribute the generated font.

_EOT_

# Define displaying help function
cica_generator_help()
{
    echo "Usage: cica_generator.sh [options] auto"
    echo "       cica_generator.sh [options] UbuntuMono-R.ttf circle-mplus-1m-regular.ttf circle-mplus-1m-bold.ttf"
    echo ""
    echo "Options:"
    echo "  -h                     Display this information"
    echo "  -V                     Display version number"
    echo "  -f /path/to/fontforge  Set path to fontforge command"
    echo "  -v                     Enable verbose mode (display fontforge's warnings)"
    echo "  -l                     Leave (NOT remove) temporary files"
    echo "  -n string              Set fontfamily suffix (\`\`Cica string'')"
    echo "  -w                     Widen line space"
    echo "  -W                     Widen line space extremely"
    echo "  -b                     Make bold-face ASCII glyphs more bold"
    echo "  -B                     Make regular-/bold-face ASCII glyphs more bold"
    echo "  -Z unicode             Set visible zenkaku space copied from another glyph"
    echo "  -z                     Disable visible zenkaku space"
    echo "  -a                     Disable fullwidth ambiguous charactors"
    echo "  -s                     Disable scaling down Circle M+ 1M"
    exit 0
}

# Get options
while getopts hVf:vln:wWbBZ:zas OPT
do
    case "$OPT" in
        "h" )
            cica_generator_help
            ;;
        "V" )
            exit 0
            ;;
        "f" )
            echo "Option: Set path to fontforge command: ${OPTARG}"
            fontforge_command="$OPTARG"
            ;;
        "v" )
            echo "Option: Enable verbose mode"
            redirection_stderr="/dev/stderr"
            ;;
        "l" )
            echo "Option: Leave (NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "n" )
            echo "Option: Set fontfamily suffix: ${OPTARG}"
            cica_familyname_suffix=`echo $OPTARG | tr -d ' '`
            ;;
        "w" )
            echo "Option: Widen line space"
            cica_ascent=`expr $cica_ascent + 128`
            cica_descent=`expr $cica_descent + 32`
            ;;
        "W" )
            echo "Option: Widen line space extremely"
            cica_ascent=`expr $cica_ascent + 256`
            cica_descent=`expr $cica_descent + 64`
            ;;
        "b" )
            echo "Option: Make bold-face ASCII glyphs more bold"
            ascii_bold_width=`expr $ascii_bold_width + 30`
            ;;
        "B" )
            echo "Option: Make regular-/bold-face ASCII glyphs more bold"
            ascii_regular_width=`expr $ascii_regular_width + 30`
            ascii_bold_width=`expr $ascii_bold_width + 30`
            ;;
        "Z" )
            echo "Option: Set visible zenkaku space copied from another glyph: ${OPTARG}"
            zenkaku_space_glyph="0u${OPTARG}"
            ;;
        "z" )
            echo "Option: Disable visible zenkaku space"
            zenkaku_space_glyph="0u3000"
            ;;
        "a" )
            echo "Option: Disable fullwidth ambiguous charactors"
            fullwidth_ambiguous_flag="false"
            ;;
        "s" )
            echo "Option: Disable scaling down Circle M+ 1M"
            scaling_down_flag="false"
            ;;
        * )
            exit 1
            ;;
    esac
done
shift `expr $OPTIND - 1`

# Check fontforge existance
if ! which $fontforge_command > /dev/null 2>&1
then
    echo "Error: ${fontforge_command} command not found" >&2
    exit 1
fi

# Get input fonts
if [ $# -eq 1 -a "$1" = "auto" ]
then
    # Check existance of directories
    tmp=""
    for i in $fonts_directories
    do
        [ -d "$i" ] && tmp="$tmp $i"
    done
    fonts_directories=$tmp
    # Search UbuntuMono
    input_ubuntumono=`find $fonts_directories -follow -name UbuntuMono-R.ttf | head -n 1`
    if [ -z "$input_ubuntumono" ]
    then
        echo "Error: UbuntuMono-R.ttf not found" >&2
        exit 1
    fi
    # Search Circle M+ 1M
    input_circlemplus1m_regu=`find $fonts_directories -follow -iname circle-mplus-1m-regular.ttf | head -n 1`
    input_circlemplus1m_bold=`find $fonts_directories -follow -iname circle-mplus-1m-bold.ttf    | head -n 1`
    if [ -z "$input_circlemplus1m_regu" -o -z "$input_circlemplus1m_bold" ]
    then
        echo "Error: circle-mplus-1m-regular.ttf and/or circle-mplus-1m-bold.ttf not found" >&2
        exit 1
    fi
elif [ $# -eq 3 ]
then
    # Get arguments
    input_ubuntumono=$1
    input_circlemplus1m_regu=$2
    input_circlemplus1m_bold=$3
    # Check existance of files
    if [ ! -r "$input_ubuntumono" ]
    then
        echo "Error: ${input_ubuntumono} not found" >&2
        exit 1
    elif [ ! -r "$input_circlemplus1m_regu" ]
    then
        echo "Error: ${input_circlemplus1m_regu} not found" >&2
        exit 1
    elif [ ! -r "$input_circlemplus1m_bold" ]
    then
        echo "Error: ${input_circlemplus1m_bold} not found" >&2
        exit 1
    fi
    # Check filename
    [ "$(basename $input_ubuntumono)" != "UbuntuMono-R.ttf" ] \
        && echo "Warning: ${input_ubuntumono} is really UbuntuMono?" >&2
    [ "$(basename $input_circlemplus1m_regu)" != "circle-mplus-1m-regular.ttf" ] \
        && echo "Warning: ${input_circlemplus1m_regu} is really Circle M+ 1M Regular?" >&2
    [ "$(basename $input_circlemplus1m_bold)" != "circle-mplus-1m-bold.ttf" ] \
        && echo "Warning: ${input_circlemplus1m_bold} is really Circle M+ 1M Bold?" >&2
else
    cica_generator_help
fi

# Make temporary directory
if [ -w "/tmp" -a "$leaving_tmp_flag" = "false" ]
then
    tmpdir=`mktemp -d /tmp/cica_generator_tmpdir.XXXXXX` || exit 2
else
    tmpdir=`mktemp -d ./cica_generator_tmpdir.XXXXXX`    || exit 2
fi

# Remove temporary directory by trapping
if [ "$leaving_tmp_flag" = "false" ]
then
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files.'; rm -rf $tmpdir; fi; echo 'Abnormally terminated.'; exit 3" HUP INT QUIT
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files.'; rm -rf $tmpdir; fi; echo 'Abnormally terminated.'" ERR
else
    trap "echo 'Abnormally terminated.'; exit 3" HUP INT QUIT
    trap "echo 'Abnormally terminated.'" ERR
fi

########################################
# Generate script for modified UbuntuMono
########################################

cat > ${tmpdir}/${modified_ubuntumono_generator} << _EOT_
#!$fontforge_command -script

# Print message
Print("Generate modified UbuntuMono.")

# Open UbuntuMono
Print("Find ${input_ubuntumono}.")
Open("${input_ubuntumono}")

# Scale to standard glyph size
ScaleToEm(860, 140)

# Remove ambiguous glyphs
if ("$fullwidth_ambiguous_flag" == "true")
    Select(0u00a4); Clear() # currency
    Select(0u00a7); Clear() # section
    Select(0u00a8); Clear() # dieresis
    Select(0u00ad); Clear() # soft hyphen
    Select(0u00b0); Clear() # degree
    Select(0u00b1); Clear() # plus-minus
    Select(0u00b4); Clear() # acute
    Select(0u00b6); Clear() # pilcrow
    Select(0u00d7); Clear() # multiply
    Select(0u00f7); Clear() # divide
    Select(0u2018); Clear() # left '
    Select(0u2019); Clear() # right '
    Select(0u201c); Clear() # left "
    Select(0u201d); Clear() # right "
    Select(0u2020); Clear() # dagger
    Select(0u2021); Clear() # double dagger
    Select(0u2026); Clear() # ...
    Select(0u2122); Clear() # TM
    Select(0u2191); Clear() # uparrow
    Select(0u2193); Clear() # downarrow
endif

# Pre-process for merging
SelectWorthOutputting()
ClearInstrs(); UnlinkReference()

# Save regular-face
Print("Save ${modified_ubuntumono_regu}.")
Save("${tmpdir}/${modified_ubuntumono_regu}")

# Make glyphs bold
Print("While making UbuntuMono bold, wait a little...")
SelectWorthOutputting()
ExpandStroke(${ascii_bold_width}, 0, 0, 0, 1)
Select(0u003e); Copy()           # >
Select(0u003c); Paste(); HFlip() # <
RoundToInt(); RemoveOverlap(); RoundToInt()

# Save bold-face
Print("Save ${modified_ubuntumono_bold}.")
Save("${tmpdir}/${modified_ubuntumono_bold}")
Close()

# Open regular-face and make it bold
if ($ascii_regular_width != 0)
    Open("${tmpdir}/${modified_ubuntumono_regu}")
    Print("While making regular-face UbuntuMono bold, wait a little...")
    SelectWorthOutputting()
    ExpandStroke(${ascii_regular_width}, 0, 0, 0, 1)
    Select(0u003e); Copy()           # >
    Select(0u003c); Paste(); HFlip() # <
    RoundToInt(); RemoveOverlap(); RoundToInt()
    Save("${tmpdir}/${modified_ubuntumono_regu}")
    Close()
endif

Quit()
_EOT_

########################################
# Generate script for modified Circle M+ 1M
########################################

cat > ${tmpdir}/${modified_circlemplus1m_generator} << _EOT_
#!$fontforge_command -script

# Print message
Print("Generate modified Circle M+ 1M.")

# Set parameters
input_list  = ["${input_circlemplus1m_regu}",    "${input_circlemplus1m_bold}"]
output_list = ["${modified_circlemplus1m_regu}", "${modified_circlemplus1m_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
    # Open Circle M+ 1M
    Print("Find " + input_list[i] + ".")
    Open(input_list[i])
    # Scale Circle M+ 1M to standard glyph size
    ScaleToEm(860, 140)
    SelectWorthOutputting()
    ClearInstrs(); UnlinkReference()
    if ("$scaling_down_flag" == "true")
        Print("While scaling " + input_list[i]:t + ", wait a little...")
        SetWidth(-1, 1); Scale(91, 91, 0, 0); SetWidth(110, 2); SetWidth(1, 1)
        Move(23, 0); SetWidth(-23, 1)
    endif
    RoundToInt(); RemoveOverlap(); RoundToInt()
    # Save modified Circle M+ 1M
    Save("${tmpdir}/" + output_list[i])
    Print("Save " + output_list[i] + ".")
    Close()
i += 1
endloop

Quit()
_EOT_

########################################
# Generate script for Cica
########################################

cat > ${tmpdir}/${cica_generator} << _EOT_
#!$fontforge_command -script

# Print message
Print("Generate Cica.")

# Set parameters
ubuntumono_list  = ["${tmpdir}/${modified_ubuntumono_regu}", \\
                     "${tmpdir}/${modified_ubuntumono_bold}"]
circlemplus1m_list       = ["${tmpdir}/${modified_circlemplus1m_regu}", \\
                     "${tmpdir}/${modified_circlemplus1m_bold}"]
fontfamily        = "$cica_familyname"
fontfamilysuffix  = "$cica_familyname_suffix"
fontstyle_list    = ["Regular", "Bold"]
fontweight_list   = [400,       700]
panoseweight_list = [5,         8]
copyright         = "Generated by : Takahiro Minami\n" \\
                  + "Ricty Generator Author: Yasunori Yusa\n" \\
                  + "Copyright 2011 Canonical Ltd.  Licensed under the Ubuntu Font Licence 1.0\n" \\
                  + "Copyright (c) 2013 itouhiro\n" \\
                  + "Copyright (c) 2013 M+ FONTS PROJECT"
version           = "${cica_version}"

# Begin loop of regular and bold
i = 0
while (i < SizeOf(fontstyle_list))
    # Merge fonts
    Print("While merging " + ubuntumono_list[i]:t \\
          + " with " + circlemplus1m_list[i]:t + ", wait a little...")
    Open(ubuntumono_list[i])
    SelectMore(0x21);SelectMore(0x22);SelectMore(0x23);SelectMore(0x24)
    SelectMore(0x25);SelectMore(0x26);SelectMore(0x27);SelectMore(0x28)
    SelectMore(0x29);SelectMore(0x2a);SelectMore(0x2b);SelectMore(0x2c)
    SelectMore(0x2d);SelectMore(0x2e);SelectMore(0x2f);SelectMore(0x30)
    SelectMore(0x31);SelectMore(0x32);SelectMore(0x33);SelectMore(0x34)
    SelectMore(0x35);SelectMore(0x36);SelectMore(0x37);SelectMore(0x38)
    SelectMore(0x39);SelectMore(0x3a);SelectMore(0x3b);SelectMore(0x3c)
    SelectMore(0x3d);SelectMore(0x3e);SelectMore(0x3f);SelectMore(0x40)
    SelectMore(0x41);SelectMore(0x42);SelectMore(0x43);SelectMore(0x44)
    SelectMore(0x45);SelectMore(0x46);SelectMore(0x47);SelectMore(0x48)
    SelectMore(0x49);SelectMore(0x4a);SelectMore(0x4b);SelectMore(0x4c)
    SelectMore(0x4d);SelectMore(0x4e);SelectMore(0x4f);SelectMore(0x50)
    SelectMore(0x51);SelectMore(0x52);SelectMore(0x53);SelectMore(0x54)
    SelectMore(0x55);SelectMore(0x56);SelectMore(0x57);SelectMore(0x58)
    SelectMore(0x59);SelectMore(0x5a);SelectMore(0x5b);SelectMore(0x5c)
    SelectMore(0x5d);SelectMore(0x5e);SelectMore(0x5f);SelectMore(0x60)
    SelectMore(0x61);SelectMore(0x62);SelectMore(0x63);SelectMore(0x64)
    SelectMore(0x65);SelectMore(0x66);SelectMore(0x67);SelectMore(0x68)
    SelectMore(0x69);SelectMore(0x6a);SelectMore(0x6b);SelectMore(0x6c)
    SelectMore(0x6d);SelectMore(0x6e);SelectMore(0x6f);SelectMore(0x70)
    SelectMore(0x71);SelectMore(0x72);SelectMore(0x73);SelectMore(0x74)
    SelectMore(0x75);SelectMore(0x76);SelectMore(0x77);SelectMore(0x78)
    SelectMore(0x79);SelectMore(0x7a);SelectMore(0x7b);SelectMore(0x7c)
    SelectMore(0x7d);SelectMore(0x7e);SelectMore(0x7f);SelectMore(0x80)
    SelectMore(0x81);SelectMore(0x82);SelectMore(0x83);SelectMore(0x84)
    SelectMore(0x85);SelectMore(0x86);SelectMore(0x87);SelectMore(0x88)
    SelectMore(0x89);SelectMore(0x8a);SelectMore(0x8b);SelectMore(0x8c)
    SelectMore(0x8d);SelectMore(0x8e);SelectMore(0x8f);SelectMore(0x90)
    SelectMore(0x91);SelectMore(0x92);SelectMore(0x93);SelectMore(0x94)
    SelectMore(0x95);SelectMore(0x96);SelectMore(0x97);SelectMore(0x98)
    SelectMore(0x99);SelectMore(0x9a);SelectMore(0x9b);SelectMore(0x9c)
    SelectMore(0x9d);SelectMore(0x9e);SelectMore(0x9f);SelectMore(0xa0)
    SelectMore(0xa1);SelectMore(0xa2);SelectMore(0xa3);SelectMore(0xa4)
    SelectMore(0xa5);SelectMore(0xa6);SelectMore(0xa7);SelectMore(0xa8)
    SelectMore(0xa9);SelectMore(0xaa);SelectMore(0xab);SelectMore(0xac)
    SelectMore(0xad);SelectMore(0xae);SelectMore(0xaf);SelectMore(0xb0)
    SelectMore(0xb1);SelectMore(0xb2);SelectMore(0xb3);SelectMore(0xb4)
    SelectMore(0xb5);SelectMore(0xb6);SelectMore(0xb7);SelectMore(0xb8)
    SelectMore(0xb9);SelectMore(0xba);SelectMore(0xbb);SelectMore(0xbc)
    SelectMore(0xbd);SelectMore(0xbe);SelectMore(0xbf);SelectMore(0xc0)
    SelectMore(0xc1);SelectMore(0xc2);SelectMore(0xc3);SelectMore(0xc4)
    SelectMore(0xc5);SelectMore(0xc6);SelectMore(0xc7);SelectMore(0xc8)
    SelectMore(0xc9);SelectMore(0xca);SelectMore(0xcb);SelectMore(0xcc)
    SelectMore(0xcd);SelectMore(0xce);SelectMore(0xcf);SelectMore(0xd0)
    SelectMore(0xd1);SelectMore(0xd2);SelectMore(0xd3);SelectMore(0xd4)
    SelectMore(0xd5);SelectMore(0xd6);SelectMore(0xd7);SelectMore(0xd8)
    SelectMore(0xd9);SelectMore(0xda);SelectMore(0xdb);SelectMore(0xdc)
    SelectMore(0xdd);SelectMore(0xde);SelectMore(0xdf);SelectMore(0xe0)
    SelectMore(0xe1);SelectMore(0xe2);SelectMore(0xe3);SelectMore(0xe4)
    SelectMore(0xe5);SelectMore(0xe6);SelectMore(0xe7);SelectMore(0xe8)
    SelectMore(0xe9);SelectMore(0xea);SelectMore(0xeb);SelectMore(0xec)
    SelectMore(0xed);SelectMore(0xee);SelectMore(0xef);SelectMore(0xf0)
    SelectMore(0xf1);SelectMore(0xf2);SelectMore(0xf3);SelectMore(0xf4)
    SelectMore(0xf5);SelectMore(0xf6);SelectMore(0xf7);SelectMore(0xf8)
    SelectMore(0xf9);SelectMore(0xfa);SelectMore(0xfb);SelectMore(0xfc)
    SelectMore(0xfd);SelectMore(0xfe);SelectMore(0xff);SelectMore(0x100)
    SelectMore(0x101);SelectMore(0x102);SelectMore(0x103);SelectMore(0x104)
    SelectMore(0x105);SelectMore(0x106);SelectMore(0x107);SelectMore(0x108)
    SelectMore(0x109);SelectMore(0x10a);SelectMore(0x10b);SelectMore(0x10c)
    SelectMore(0x10d);SelectMore(0x10e);SelectMore(0x10f);SelectMore(0x110)
    SelectMore(0x111);SelectMore(0x112);SelectMore(0x113);SelectMore(0x114)
    SelectMore(0x115);SelectMore(0x116);SelectMore(0x117);SelectMore(0x118)
    SelectMore(0x119);SelectMore(0x11a);SelectMore(0x11b);SelectMore(0x11c)
    SelectMore(0x11d);SelectMore(0x11e);SelectMore(0x11f);SelectMore(0x120)
    SelectMore(0x121);SelectMore(0x122);SelectMore(0x123);SelectMore(0x124)
    SelectMore(0x125);SelectMore(0x126);SelectMore(0x127);SelectMore(0x128)
    SelectMore(0x129);SelectMore(0x12a);SelectMore(0x12b);SelectMore(0x12c)
    SelectMore(0x12d);SelectMore(0x12e);SelectMore(0x12f);SelectMore(0x130)
    SelectMore(0x131);SelectMore(0x132);SelectMore(0x133);SelectMore(0x134)
    SelectMore(0x135);SelectMore(0x136);SelectMore(0x137);SelectMore(0x138)
    SelectMore(0x139);SelectMore(0x13a);SelectMore(0x13b);SelectMore(0x13c)
    SelectMore(0x13d);SelectMore(0x13e);SelectMore(0x13f);SelectMore(0x140)
    SelectMore(0x141);SelectMore(0x142);SelectMore(0x143);SelectMore(0x144)
    SelectMore(0x145);SelectMore(0x146);SelectMore(0x147);SelectMore(0x148)
    SelectMore(0x149);SelectMore(0x14a);SelectMore(0x14b);SelectMore(0x14c)
    SelectMore(0x14d);SelectMore(0x14e);SelectMore(0x14f);SelectMore(0x150)
    SelectMore(0x151);SelectMore(0x152);SelectMore(0x153);SelectMore(0x154)
    SelectMore(0x155);SelectMore(0x156);SelectMore(0x157);SelectMore(0x158)
    SelectMore(0x159);SelectMore(0x15a);SelectMore(0x15b);SelectMore(0x15c)
    SelectMore(0x15d);SelectMore(0x15e);SelectMore(0x15f);SelectMore(0x160)
    SelectMore(0x161);SelectMore(0x162);SelectMore(0x163);SelectMore(0x164)
    SelectMore(0x165);SelectMore(0x166);SelectMore(0x167);SelectMore(0x168)
    SelectMore(0x169);SelectMore(0x16a);SelectMore(0x16b);SelectMore(0x16c)
    SelectMore(0x16d);SelectMore(0x16e);SelectMore(0x16f);SelectMore(0x170)
    SelectMore(0x171);SelectMore(0x172);SelectMore(0x173);SelectMore(0x174)
    SelectMore(0x175);SelectMore(0x176);SelectMore(0x177);SelectMore(0x178)
    SelectMore(0x179);SelectMore(0x17a);SelectMore(0x17b);SelectMore(0x17c)
    SelectMore(0x17d);SelectMore(0x17e);SelectMore(0x17f);SelectMore(0x180)
    SelectMore(0x181);SelectMore(0x182);SelectMore(0x183);SelectMore(0x184)
    SelectMore(0x185);SelectMore(0x186);SelectMore(0x187);SelectMore(0x188)
    SelectMore(0x189);SelectMore(0x18a);SelectMore(0x18b);SelectMore(0x18c)
    SelectMore(0x18d);SelectMore(0x18e);SelectMore(0x18f);SelectMore(0x190)
    SelectMore(0x191);SelectMore(0x192);SelectMore(0x193);SelectMore(0x194)
    SelectMore(0x195);SelectMore(0x196);SelectMore(0x197);SelectMore(0x198)
    SelectMore(0x199);SelectMore(0x19a);SelectMore(0x19b);SelectMore(0x19c)
    SelectMore(0x19d);SelectMore(0x19e);SelectMore(0x19f);SelectMore(0x1a0)
    SelectMore(0x1a1);SelectMore(0x1a2);SelectMore(0x1a3);SelectMore(0x1a4)
    SelectMore(0x1a5);SelectMore(0x1a6);SelectMore(0x1a7);SelectMore(0x1a8)
    SelectMore(0x1a9);SelectMore(0x1aa);SelectMore(0x1ab);SelectMore(0x1ac)
    SelectMore(0x1ad);SelectMore(0x1ae);SelectMore(0x1af);SelectMore(0x1b0)
    SelectMore(0x1b1);SelectMore(0x1b2);SelectMore(0x1b3);SelectMore(0x1b4)
    SelectMore(0x1b5);SelectMore(0x1b6);SelectMore(0x1b7);SelectMore(0x1b8)
    SelectMore(0x1b9);SelectMore(0x1ba);SelectMore(0x1bb);SelectMore(0x1bc)
    SelectMore(0x1bd);SelectMore(0x1be);SelectMore(0x1bf);SelectMore(0x1c0)
    SelectMore(0x1c1);SelectMore(0x1c2);SelectMore(0x1c3);SelectMore(0x1c4)
    SelectMore(0x1c5);SelectMore(0x1c6);SelectMore(0x1c7);SelectMore(0x1c8)
    SelectMore(0x1c9);SelectMore(0x1ca);SelectMore(0x1cb);SelectMore(0x1cc)
    SelectMore(0x1cd);SelectMore(0x1ce);SelectMore(0x1cf);SelectMore(0x1d0)
    SelectMore(0x1d1);SelectMore(0x1d2);SelectMore(0x1d3);SelectMore(0x1d4)
    SelectMore(0x1d5);SelectMore(0x1d6);SelectMore(0x1d7);SelectMore(0x1d8)
    SelectMore(0x1d9);SelectMore(0x1da);SelectMore(0x1db);SelectMore(0x1dc)
    SelectMore(0x1dd);SelectMore(0x1de);SelectMore(0x1df);SelectMore(0x1e0)
    SelectMore(0x1e1);SelectMore(0x1e2);SelectMore(0x1e3);SelectMore(0x1e4)
    SelectMore(0x1e5);SelectMore(0x1e6);SelectMore(0x1e7);SelectMore(0x1e8)
    SelectMore(0x1e9);SelectMore(0x1ea);SelectMore(0x1eb);SelectMore(0x1ec)
    SelectMore(0x1ed);SelectMore(0x1ee);SelectMore(0x1ef);SelectMore(0x1f0)
    SelectMore(0x1f1);SelectMore(0x1f2);SelectMore(0x1f3);SelectMore(0x1f4)
    SelectMore(0x1f5);SelectMore(0x1f6);SelectMore(0x1f7);SelectMore(0x1f8)
    SelectMore(0x1f9);SelectMore(0x1fa);SelectMore(0x1fb);SelectMore(0x1fc)
    SelectMore(0x1fd);SelectMore(0x1fe);SelectMore(0x1ff);SelectMore(0x200)
    SelectMore(0x201);SelectMore(0x202);SelectMore(0x203);SelectMore(0x204)
    SelectMore(0x205);SelectMore(0x206);SelectMore(0x207);SelectMore(0x208)
    SelectMore(0x209);SelectMore(0x20a);SelectMore(0x20b);SelectMore(0x20c)
    SelectMore(0x20d);SelectMore(0x20e);SelectMore(0x20f);SelectMore(0x210)
    SelectMore(0x211);SelectMore(0x212);SelectMore(0x213);SelectMore(0x214)
    SelectMore(0x215);SelectMore(0x216);SelectMore(0x217);SelectMore(0x218)
    SelectMore(0x219);SelectMore(0x21a);SelectMore(0x21b);SelectMore(0x21c)
    SelectMore(0x21d);SelectMore(0x21e);SelectMore(0x21f);SelectMore(0x220)
    SelectMore(0x221);SelectMore(0x222);SelectMore(0x223);SelectMore(0x224)
    SelectMore(0x225);SelectMore(0x226);SelectMore(0x227);SelectMore(0x228)
    SelectMore(0x229);SelectMore(0x22a);SelectMore(0x22b);SelectMore(0x22c)
    SelectMore(0x22d);SelectMore(0x22e);SelectMore(0x22f);SelectMore(0x230)
    SelectMore(0x231);SelectMore(0x232);SelectMore(0x233);SelectMore(0x234)
    SelectMore(0x235);SelectMore(0x236);SelectMore(0x237);SelectMore(0x238)
    SelectMore(0x239);SelectMore(0x23a);SelectMore(0x23b);SelectMore(0x23c)
    SelectMore(0x23d);SelectMore(0x23e);SelectMore(0x23f);SelectMore(0x240)
    SelectMore(0x241);SelectMore(0x242);SelectMore(0x243);SelectMore(0x244)
    SelectMore(0x245);SelectMore(0x246);SelectMore(0x247);SelectMore(0x248)
    SelectMore(0x249);SelectMore(0x24a);SelectMore(0x24b);SelectMore(0x24c)
    SelectMore(0x24d);SelectMore(0x24e);SelectMore(0x24f);SelectMore(0x250)
    SelectMore(0x251);SelectMore(0x252);SelectMore(0x253);SelectMore(0x254)
    SelectMore(0x255);SelectMore(0x256);SelectMore(0x257);SelectMore(0x258)
    SelectMore(0x259);SelectMore(0x25a);SelectMore(0x25b);SelectMore(0x25c)
    SelectMore(0x25d);SelectMore(0x25e);SelectMore(0x25f);SelectMore(0x260)
    SelectMore(0x261);SelectMore(0x262);SelectMore(0x263);SelectMore(0x264)
    SelectMore(0x265);SelectMore(0x266);SelectMore(0x267);SelectMore(0x268)
    SelectMore(0x269);SelectMore(0x26a);SelectMore(0x26b);SelectMore(0x26c)
    SelectMore(0x26d);SelectMore(0x26e);SelectMore(0x26f);SelectMore(0x270)
    SelectMore(0x271);SelectMore(0x272);SelectMore(0x273);SelectMore(0x274)
    SelectMore(0x275);SelectMore(0x276);SelectMore(0x277);SelectMore(0x278)
    SelectMore(0x279);SelectMore(0x27a);SelectMore(0x27b);SelectMore(0x27c)
    SelectMore(0x27d);SelectMore(0x27e);SelectMore(0x27f);SelectMore(0x280)
    SelectMore(0x281);SelectMore(0x282);SelectMore(0x283);SelectMore(0x284)
    SelectMore(0x285);SelectMore(0x286);SelectMore(0x287);SelectMore(0x288)
    SelectMore(0x289);SelectMore(0x28a);SelectMore(0x28b);SelectMore(0x28c)
    SelectMore(0x28d);SelectMore(0x28e);SelectMore(0x28f);SelectMore(0x290)
    SelectMore(0x291);SelectMore(0x292);SelectMore(0x293);SelectMore(0x294)
    SelectMore(0x295);SelectMore(0x296);SelectMore(0x297);SelectMore(0x298)
    SelectMore(0x299);SelectMore(0x29a);SelectMore(0x29b);SelectMore(0x29c)
    SelectMore(0x29d);SelectMore(0x29e);SelectMore(0x29f);SelectMore(0x2a0)
    SelectMore(0x2a1);SelectMore(0x2a2);SelectMore(0x2a3);SelectMore(0x2a4)
    SelectMore(0x2a5);SelectMore(0x2a6);SelectMore(0x2a7);SelectMore(0x2a8)
    SelectMore(0x2a9);SelectMore(0x2aa);SelectMore(0x2ab);SelectMore(0x2ac)
    SelectMore(0x2ad);SelectMore(0x2ae);SelectMore(0x2af);SelectMore(0x2b0)
    SelectMore(0x2b1);SelectMore(0x2b2);SelectMore(0x2b3);SelectMore(0x2b4)
    SelectMore(0x2b5);SelectMore(0x2b6);SelectMore(0x2b7);SelectMore(0x2b8)
    SelectMore(0x2b9);SelectMore(0x2ba);SelectMore(0x2bb);SelectMore(0x2bc)
    SelectMore(0x2bd);SelectMore(0x2be);SelectMore(0x2bf);SelectMore(0x2c0)
    SelectMore(0x2c1);SelectMore(0x2c2);SelectMore(0x2c3);SelectMore(0x2c4)
    SelectMore(0x2c5);SelectMore(0x2c6);SelectMore(0x2c7);SelectMore(0x2c8)
    SelectMore(0x2c9);SelectMore(0x2ca);SelectMore(0x2cb);SelectMore(0x2cc)
    SelectMore(0x2cd);SelectMore(0x2ce);SelectMore(0x2cf);SelectMore(0x2d0)
    SelectMore(0x2d1);SelectMore(0x2d2);SelectMore(0x2d3);SelectMore(0x2d4)
    SelectMore(0x2d5);SelectMore(0x2d6);SelectMore(0x2d7);SelectMore(0x2d8)
    SelectMore(0x2d9);SelectMore(0x2da);SelectMore(0x2db);SelectMore(0x2dc)
    SelectMore(0x2dd);SelectMore(0x2de);SelectMore(0x2df);SelectMore(0x2e0)
    SelectMore(0x2e1);SelectMore(0x2e2);SelectMore(0x2e3);SelectMore(0x2e4)
    SelectMore(0x2e5);SelectMore(0x2e6);SelectMore(0x2e7);SelectMore(0x2e8)
    SelectMore(0x2e9);SelectMore(0x2ea);SelectMore(0x2eb);SelectMore(0x2ec)
    SelectMore(0x2ed);SelectMore(0x2ee);SelectMore(0x2ef);SelectMore(0x2f0)
    SelectMore(0x2f1);SelectMore(0x2f2);SelectMore(0x2f3);SelectMore(0x2f4)
    SelectMore(0x2f5);SelectMore(0x2f6);SelectMore(0x2f7);SelectMore(0x2f8)
    SelectMore(0x2f9);SelectMore(0x2fa);SelectMore(0x2fb);SelectMore(0x2fc)
    SelectMore(0x2fd);SelectMore(0x2fe);SelectMore(0x2ff);SelectMore(0x300)
    SelectMore(0x301);SelectMore(0x302);SelectMore(0x303);SelectMore(0x304)
    SelectMore(0x305);SelectMore(0x306);SelectMore(0x307);SelectMore(0x308)
    SelectMore(0x309);SelectMore(0x30a);SelectMore(0x30b);SelectMore(0x30c)
    SelectMore(0x30d);SelectMore(0x30e);SelectMore(0x30f);SelectMore(0x310)
    SelectMore(0x311);SelectMore(0x312);SelectMore(0x313);SelectMore(0x314)
    SelectMore(0x315);SelectMore(0x316);SelectMore(0x317);SelectMore(0x318)
    SelectMore(0x319);SelectMore(0x31a);SelectMore(0x31b);SelectMore(0x31c)
    SelectMore(0x31d);SelectMore(0x31e);SelectMore(0x31f);SelectMore(0x320)
    SelectMore(0x321);SelectMore(0x322);SelectMore(0x323);SelectMore(0x324)
    SelectMore(0x325);SelectMore(0x326);SelectMore(0x327);SelectMore(0x328)
    SelectMore(0x329);SelectMore(0x32a);SelectMore(0x32b);SelectMore(0x32c)
    SelectMore(0x32d);SelectMore(0x32e);SelectMore(0x32f);SelectMore(0x330)
    SelectMore(0x331);SelectMore(0x332);SelectMore(0x333);SelectMore(0x334)
    SelectMore(0x335);SelectMore(0x336);SelectMore(0x337);SelectMore(0x338)
    SelectMore(0x339);SelectMore(0x33a);SelectMore(0x33b);SelectMore(0x33c)
    SelectMore(0x33d);SelectMore(0x33e);SelectMore(0x33f);SelectMore(0x340)
    SelectMore(0x341);SelectMore(0x342);SelectMore(0x343);SelectMore(0x344)
    SelectMore(0x345);SelectMore(0x346);SelectMore(0x347);SelectMore(0x348)
    SelectMore(0x349);SelectMore(0x34a);SelectMore(0x34b);SelectMore(0x34c)
    SelectMore(0x34d);SelectMore(0x34e);SelectMore(0x34f);SelectMore(0x350)
    SelectMore(0x351);SelectMore(0x352);SelectMore(0x353);SelectMore(0x354)
    SelectMore(0x355);SelectMore(0x356);SelectMore(0x357);SelectMore(0x358)
    SelectMore(0x359);SelectMore(0x35a);SelectMore(0x35b);SelectMore(0x35c)
    SelectMore(0x35d);SelectMore(0x35e);SelectMore(0x35f);SelectMore(0x360)
    SelectMore(0x361);SelectMore(0x362);SelectMore(0x363);SelectMore(0x364)
    SelectMore(0x365);SelectMore(0x366);SelectMore(0x367);SelectMore(0x368)
    SelectMore(0x369);SelectMore(0x36a);SelectMore(0x36b);SelectMore(0x36c)
    SelectMore(0x36d);SelectMore(0x36e);SelectMore(0x36f);SelectMore(0x370)
    SelectMore(0x371);SelectMore(0x372);SelectMore(0x373);SelectMore(0x374)
    SelectMore(0x375);SelectMore(0x376);SelectMore(0x377);SelectMore(0x378)
    SelectMore(0x379);SelectMore(0x37a);SelectMore(0x37b);SelectMore(0x37c)
    SelectMore(0x37d);SelectMore(0x37e);SelectMore(0x37f);SelectMore(0x380)
    SelectMore(0x381);SelectMore(0x382);SelectMore(0x383);SelectMore(0x384)
    SelectMore(0x385);SelectMore(0x386);SelectMore(0x387);SelectMore(0x388)
    SelectMore(0x389);SelectMore(0x38a);SelectMore(0x38b);SelectMore(0x38c)
    SelectMore(0x38d);SelectMore(0x38e);SelectMore(0x38f);SelectMore(0x390)
    SelectMore(0x391);SelectMore(0x392);SelectMore(0x393);SelectMore(0x394)
    SelectMore(0x395);SelectMore(0x396);SelectMore(0x397);SelectMore(0x398)
    SelectMore(0x399);SelectMore(0x39a);SelectMore(0x39b);SelectMore(0x39c)
    SelectMore(0x39d);SelectMore(0x39e);SelectMore(0x39f);SelectMore(0x3a0)
    SelectMore(0x3a1);SelectMore(0x3a2);SelectMore(0x3a3);SelectMore(0x3a4)
    SelectMore(0x3a5);SelectMore(0x3a6);SelectMore(0x3a7);SelectMore(0x3a8)
    SelectMore(0x3a9);SelectMore(0x3aa);SelectMore(0x3ab);SelectMore(0x3ac)
    SelectMore(0x3ad);SelectMore(0x3ae);SelectMore(0x3af);SelectMore(0x3b0)
    SelectMore(0x3b1);SelectMore(0x3b2);SelectMore(0x3b3);SelectMore(0x3b4)
    SelectMore(0x3b5);SelectMore(0x3b6);SelectMore(0x3b7);SelectMore(0x3b8)
    SelectMore(0x3b9);SelectMore(0x3ba);SelectMore(0x3bb);SelectMore(0x3bc)
    SelectMore(0x3bd);SelectMore(0x3be);SelectMore(0x3bf);SelectMore(0x3c0)
    SelectMore(0x3c1);SelectMore(0x3c2);SelectMore(0x3c3);SelectMore(0x3c4)
    SelectMore(0x3c5);SelectMore(0x3c6);SelectMore(0x3c7);SelectMore(0x3c8)
    SelectMore(0x3c9);SelectMore(0x3ca);SelectMore(0x3cb);SelectMore(0x3cc)
    SelectMore(0x3cd);SelectMore(0x3ce);SelectMore(0x3cf);SelectMore(0x3d0)
    SelectMore(0x3d1);SelectMore(0x3d2);SelectMore(0x3d3);SelectMore(0x3d4)
    SelectMore(0x3d5);SelectMore(0x3d6);SelectMore(0x3d7);SelectMore(0x3d8)
    SelectMore(0x3d9);SelectMore(0x3da);SelectMore(0x3db);SelectMore(0x3dc)
    SelectMore(0x3dd);SelectMore(0x3de);SelectMore(0x3df);SelectMore(0x3e0)
    SelectMore(0x3e1);SelectMore(0x3e2);SelectMore(0x3e3);SelectMore(0x3e4)
    SelectMore(0x3e5);SelectMore(0x3e6);SelectMore(0x3e7);SelectMore(0x3e8)
    SelectMore(0x3e9);SelectMore(0x3ea);SelectMore(0x3eb);SelectMore(0x3ec)
    SelectMore(0x3ed);SelectMore(0x3ee);SelectMore(0x3ef);SelectMore(0x3f0)
    SelectMore(0x3f1);SelectMore(0x3f2);SelectMore(0x3f3);SelectMore(0x3f4)
    SelectMore(0x3f5);SelectMore(0x3f6);SelectMore(0x3f7);SelectMore(0x3f8)
    SelectMore(0x3f9);SelectMore(0x3fa);SelectMore(0x3fb);SelectMore(0x3fc)
    SelectMore(0x3fd);SelectMore(0x3fe);SelectMore(0x3ff);SelectMore(0x400)
    SelectMore(0x401);SelectMore(0x402);SelectMore(0x403);SelectMore(0x404)
    SelectMore(0x405);SelectMore(0x406);SelectMore(0x407);SelectMore(0x408)
    SelectMore(0x409);SelectMore(0x40a);SelectMore(0x40b);SelectMore(0x40c)
    SelectMore(0x40d);SelectMore(0x40e);SelectMore(0x40f);SelectMore(0x410)
    SelectMore(0x411);SelectMore(0x412);SelectMore(0x413);SelectMore(0x414)
    SelectMore(0x415);SelectMore(0x416);SelectMore(0x417);SelectMore(0x418)
    SelectMore(0x419);SelectMore(0x41a);SelectMore(0x41b);SelectMore(0x41c)
    SelectMore(0x41d);SelectMore(0x41e);SelectMore(0x41f);SelectMore(0x420)
    SelectMore(0x421);SelectMore(0x422);SelectMore(0x423);SelectMore(0x424)
    SelectMore(0x425);SelectMore(0x426);SelectMore(0x427);SelectMore(0x428)
    SelectMore(0x429);SelectMore(0x42a);SelectMore(0x42b);SelectMore(0x42c)
    SelectMore(0x42d);SelectMore(0x42e);SelectMore(0x42f);SelectMore(0x430)
    SelectMore(0x431);SelectMore(0x432);SelectMore(0x433);SelectMore(0x434)
    SelectMore(0x435);SelectMore(0x436);SelectMore(0x437);SelectMore(0x438)
    SelectMore(0x439);SelectMore(0x43a);SelectMore(0x43b);SelectMore(0x43c)
    SelectMore(0x43d);SelectMore(0x43e);SelectMore(0x43f);SelectMore(0x440)
    SelectMore(0x441);SelectMore(0x442);SelectMore(0x443);SelectMore(0x444)
    SelectMore(0x445);SelectMore(0x446);SelectMore(0x447);SelectMore(0x448)
    SelectMore(0x449);SelectMore(0x44a);SelectMore(0x44b);SelectMore(0x44c)
    SelectMore(0x44d);SelectMore(0x44e);SelectMore(0x44f);SelectMore(0x450)
    SelectMore(0x451);SelectMore(0x452);SelectMore(0x453);SelectMore(0x454)
    SelectMore(0x455);SelectMore(0x456);SelectMore(0x457);SelectMore(0x458)
    SelectMore(0x459);SelectMore(0x45a);SelectMore(0x45b);SelectMore(0x45c)
    SelectMore(0x45d);SelectMore(0x45e);SelectMore(0x45f);SelectMore(0x460)
    SelectMore(0x461);SelectMore(0x462);SelectMore(0x463);SelectMore(0x464)
    SelectMore(0x465);SelectMore(0x466);SelectMore(0x467);SelectMore(0x468)
    SelectMore(0x469);SelectMore(0x46a);SelectMore(0x46b);SelectMore(0x46c)
    SelectMore(0x46d);SelectMore(0x46e);SelectMore(0x46f);SelectMore(0x470)
    SelectMore(0x471);SelectMore(0x472);SelectMore(0x473);SelectMore(0x474)
    SelectMore(0x475);SelectMore(0x476);SelectMore(0x477);SelectMore(0x478)
    SelectMore(0x479);SelectMore(0x47a);SelectMore(0x47b);SelectMore(0x47c)
    SelectMore(0x47d);SelectMore(0x47e);SelectMore(0x47f);SelectMore(0x480)
    SelectMore(0x481);SelectMore(0x482);SelectMore(0x483);SelectMore(0x484)
    SelectMore(0x485);SelectMore(0x486);SelectMore(0x487);SelectMore(0x488)
    SelectMore(0x489);SelectMore(0x48a);SelectMore(0x48b);SelectMore(0x48c)
    SelectMore(0x48d);SelectMore(0x48e);SelectMore(0x48f);SelectMore(0x490)
    SelectMore(0x491);SelectMore(0x492);SelectMore(0x493);SelectMore(0x494)
    SelectMore(0x495);SelectMore(0x496);SelectMore(0x497);SelectMore(0x498)
    SelectMore(0x499);SelectMore(0x49a);SelectMore(0x49b);SelectMore(0x49c)
    SelectMore(0x49d);SelectMore(0x49e);SelectMore(0x49f);SelectMore(0x4a0)
    SelectMore(0x4a1);SelectMore(0x4a2);SelectMore(0x4a3);SelectMore(0x4a4)
    SelectMore(0x4a5);SelectMore(0x4a6);SelectMore(0x4a7);SelectMore(0x4a8)
    SelectMore(0x4a9);SelectMore(0x4aa);SelectMore(0x4ab);SelectMore(0x4ac)
    SelectMore(0x4ad);SelectMore(0x4ae);SelectMore(0x4af);SelectMore(0x4b0)
    SelectMore(0x4b1);SelectMore(0x4b2);SelectMore(0x4b3);SelectMore(0x4b4)
    SelectMore(0x4b5);SelectMore(0x4b6);SelectMore(0x4b7);SelectMore(0x4b8)
    SelectMore(0x4b9);SelectMore(0x4ba);SelectMore(0x4bb);SelectMore(0x4bc)
    SelectMore(0x4bd);SelectMore(0x4be);SelectMore(0x4bf);SelectMore(0x4c0)
    SelectMore(0x4c1);SelectMore(0x4c2);SelectMore(0x4c3);SelectMore(0x4c4)
    SelectMore(0x4c5);SelectMore(0x4c6);SelectMore(0x4c7);SelectMore(0x4c8)
    SelectMore(0x4c9);SelectMore(0x4ca);SelectMore(0x4cb);SelectMore(0x4cc)
    SelectMore(0x4cd);SelectMore(0x4ce);SelectMore(0x4cf);SelectMore(0x4d0)
    SelectMore(0x4d1);SelectMore(0x4d2);SelectMore(0x4d3);SelectMore(0x4d4)
    SelectMore(0x4d5);SelectMore(0x4d6);SelectMore(0x4d7);SelectMore(0x4d8)
    SelectMore(0x4d9);SelectMore(0x4da);SelectMore(0x4db);SelectMore(0x4dc)
    SelectMore(0x4dd);SelectMore(0x4de);SelectMore(0x4df);SelectMore(0x4e0)
    SelectMore(0x4e1);SelectMore(0x4e2);SelectMore(0x4e3);SelectMore(0x4e4)
    SelectMore(0x4e5);SelectMore(0x4e6);SelectMore(0x4e7);SelectMore(0x4e8)
    SelectMore(0x4e9);SelectMore(0x4ea);SelectMore(0x4eb);SelectMore(0x4ec)
    SelectMore(0x4ed);SelectMore(0x4ee);SelectMore(0x4ef);SelectMore(0x4f0)
    SelectMore(0x4f1);SelectMore(0x4f2);SelectMore(0x4f3);SelectMore(0x4f4)
    SelectMore(0x4f5);SelectMore(0x4f6);SelectMore(0x4f7);SelectMore(0x4f8)
    SelectMore(0x4f9)
    Copy()
    Close()
    Open(circlemplus1m_list[i])
    Select(0x21)
    Paste()
    # Set configuration
    if (fontfamilysuffix != "")
        SetFontNames(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i], \\
                     fontfamily + " " + fontfamilysuffix, \\
                     fontfamily + " " + fontfamilysuffix + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    else
        SetFontNames(fontfamily + "-" + fontstyle_list[i], \\
                     fontfamily, \\
                     fontfamily + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    endif
    ScaleToEm(860, 140)
    SetOS2Value("Weight", fontweight_list[i]) # Book or Bold
    SetOS2Value("Width",                   5) # Medium
    SetOS2Value("FSType",                  0)
    SetOS2Value("VendorID",           "PfEd")
    SetOS2Value("IBMFamily",            2057) # SS Typewriter Gothic
    SetOS2Value("WinAscentIsOffset",       0)
    SetOS2Value("WinDescentIsOffset",      0)
    SetOS2Value("TypoAscentIsOffset",      0)
    SetOS2Value("TypoDescentIsOffset",     0)
    SetOS2Value("HHeadAscentIsOffset",     0)
    SetOS2Value("HHeadDescentIsOffset",    0)
    SetOS2Value("WinAscent",             $cica_ascent)
    SetOS2Value("WinDescent",            $cica_descent)
    SetOS2Value("TypoAscent",            693)
    SetOS2Value("TypoDescent",          -165)
    SetOS2Value("TypoLineGap",             0)
    SetOS2Value("HHeadAscent",           $cica_ascent)
    SetOS2Value("HHeadDescent",         -$cica_descent)
    SetOS2Value("HHeadLineGap",            0)
    SetPanose([2, 11, panoseweight_list[i], 9, 2, 2, 3, 2, 2, 7])
    # Edit zenkaku space (from ballot box and heavy greek cross)
    if ("$zenkaku_space_glyph" == "")
        Select(0u2610); Copy(); Select(0u3000); Paste()
        Select(0u271a); Copy(); Select(0u3000); PasteInto()
        OverlapIntersect()
    else
        Select(${zenkaku_space_glyph}); Copy(); Select(0u3000); Paste()
    endif
    # Edit zenkaku comma and period
    Select(0uff0c); Scale(150, 150, 100, 0); SetWidth(1000)
    Select(0uff0e); Scale(150, 150, 100, 0); SetWidth(1000)
    # Edit zenkaku colon and semicolon
    Select(0uff0c); Copy(); Select(0uff1b); Paste()
    Select(0uff0e); Copy(); Select(0uff1b); PasteWithOffset(0, 400)
    CenterInWidth()
    Select(0uff1a); Paste(); PasteWithOffset(0, 400)
    CenterInWidth()
    # Edit zenkaku brackets
    Select(0u0028); Copy(); Select(0uff08); Paste(); Move(250, 0); SetWidth(1000) # (
    Select(0u0029); Copy(); Select(0uff09); Paste(); Move(250, 0); SetWidth(1000) # )
    Select(0u005b); Copy(); Select(0uff3b); Paste(); Move(250, 0); SetWidth(1000) # [
    Select(0u005d); Copy(); Select(0uff3d); Paste(); Move(250, 0); SetWidth(1000) # ]
    Select(0u007b); Copy(); Select(0uff5b); Paste(); Move(250, 0); SetWidth(1000) # {
    Select(0u007d); Copy(); Select(0uff5d); Paste(); Move(250, 0); SetWidth(1000) # }
    Select(0u003c); Copy(); Select(0uff1c); Paste(); Move(250, 0); SetWidth(1000) # <
    Select(0u003e); Copy(); Select(0uff1e); Paste(); Move(250, 0); SetWidth(1000) # >
    # Edit en dash
    Select(0u2013); Copy()
    PasteWithOffset(200, 0); PasteWithOffset(-200, 0)
    OverlapIntersect()
    # Edit em dash
    Select(0u2014); Copy()
    PasteWithOffset(320, 0); PasteWithOffset(-320, 0)
    Select(0u007c); Copy(); Select(0u2014); PasteInto()
    OverlapIntersect()
    # vertical line to broken vertical line
    Select(0u00a6); Copy(); Select(0u007c); Paste() # |
    # Detach and remove .notdef
    Select(".notdef")
    DetachAndRemoveGlyphs()
    # Post-proccess
    SelectWorthOutputting()
    RoundToInt(); RemoveOverlap(); RoundToInt()
    # Save Cica
    if (fontfamilysuffix != "")
        Print("Save " + fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf.")
        Generate(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    else
        Print("Save " + fontfamily + "-" + fontstyle_list[i] + ".ttf.")
        Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    endif
    Close()
i += 1
endloop

Quit()
_EOT_

########################################
# Generate Cica
########################################

# Generate Cica
$fontforge_command -script ${tmpdir}/${modified_ubuntumono_generator} \
    2> $redirection_stderr || exit 4
$fontforge_command -script ${tmpdir}/${modified_circlemplus1m_generator} \
    2> $redirection_stderr || exit 4
$fontforge_command -script ${tmpdir}/${cica_generator} \
    2> $redirection_stderr || exit 4

# Remove temporary directory
if [ "$leaving_tmp_flag" = "false" ]
then
    echo "Remove temporary files."
    rm -rf $tmpdir
fi

echo "OS2Version to 1 Cica Regular"
. misc/os2version_reviser.sh Cica-Regular.ttf
echo "OS2Version to 1 Cica Bold"
. misc/os2version_reviser.sh Cica-Bold.ttf

echo "Set powerline patch to Cica Regular"
fontforge -lang=py -script ~/Dropbox/dev/vim-powerline/fontpatcher/fontpatcher --no-rename Cica-Regular.ttf
echo "Set powerline patch to Cica Bold"
fontforge -lang=py -script ~/Dropbox/dev/vim-powerline/fontpatcher/fontpatcher --no-rename Cica-Bold.ttf

# Exit
echo "Succeeded to generate Cica!"
exit 0

