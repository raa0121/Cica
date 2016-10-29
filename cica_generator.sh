#!/bin/bash
rm -rf ./tmp # :p
rm -rf ./Cica
mkdir tmp
mkdir Cica
#
# Cica Generator
cica_version="1.0"
#
# Ricty Author: Yasunori Yusa <lastname at save.sys.t.u-tokyo.ac.jp>
# Cica Author : miiton <vo.gu.ba.miiton@gmail.com>
# This script is to generate ``Cica'' font from UbuntuMono and Rounded Mgen+ 1M.
# It requires 2-5 minutes to generate Cica. Owing to Ubuntu Font License
# Version 1.1 section 5, it is PROHIBITED to distribute the generated font.
# This script supports following versions of inputting fonts.
# * UbuntuMono Version
# * Rounded Mgen+ 1M
#
# Usage:
# 1. Install FontForge
#    Debian/Ubuntu: # apt-get install fontforge
#    Fedora/CentOS: # yum install fontforge
#    OpenSUSE:      # zypper install fontforge
#    Other Linux:   Get from http://fontforge.sourceforge.net/
# 2. Get UbuntuMono-R.ttf to ./sourceFonts/
# 3. Get rounded-mgenplus-1m-regular/bold.ttf to ./sourceFonts/ 
# 4. Run this script
#        % sh cica_generator.sh auto
# 5. Install Cica
#        % cp -f Cica*.ttf ~/.fonts/
#        % fc-cache -vf
#

# Set familyname
cica_familyname="Cica"

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
fonts_directories="./sourceFonts"

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
modified_roundedmgenplus_generator="modified_roundedmgenplus_generator.pe"
modified_roundedmgenplus_regu="Modified-rounded-mgenplus-1m-regular.sfd"
modified_roundedmgenplus_bold="Modified-rounded-mgenplus-1m-bold.sfd"
cica_generator="cica_generator.pe"
post_script="post_script.pe"

########################################
# Pre-process
########################################

# Print information message
cat << _EOT_
Cica Generator ${cica_version} ( forked from Ricty Generator by Yasunori Yusa )

Author: miiton

This script is to generate \`\`Cica'' font from UbuntuMono and Rounded Mgen+ 1M.
It requires 10-60 minutes to generate Cica...

_EOT_

# Define displaying help function
cica_generator_help()
{
    echo "Usage: cica_generator.sh [options] auto"
    echo "       cica_generator.sh [options] UbuntuMono-R.ttf rounded-mgenplus-1m-regular.ttf rounded-mgenplus-1m-bold.ttf"
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
    echo "  -s                     Disable scaling down Rounded Mgen+ 1M"
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
            echo "Option: Disable scaling down Rounded Mgen+ 1M"
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
    # Search Rounded Mgen+ 1M
    input_roundedmgenplus_regu=`find $fonts_directories -follow -iname rounded-mgenplus-1m-regular.ttf | head -n 1`
    input_roundedmgenplus_bold=`find $fonts_directories -follow -iname rounded-mgenplus-1m-bold.ttf    | head -n 1`
    if [ -z "$input_roundedmgenplus_regu" -o -z "$input_roundedmgenplus_bold" ]
    then
        echo "Error: rounded-mgenplus-1m-regular.ttf and/or rounded-mgenplus-1m-bold.ttf not found" >&2
        exit 1
    fi
elif [ $# -eq 3 ]
then
    # Get arguments
    input_ubuntumono=$1
    input_roundedmgenplus_regu=$2
    input_roundedmgenplus_bold=$3
    # Check existance of files
    if [ ! -r "$input_ubuntumono" ]
    then
        echo "Error: ${input_ubuntumono} not found" >&2
        exit 1
    elif [ ! -r "$input_roundedmgenplus_regu" ]
    then
        echo "Error: ${input_roundedmgenplus_regu} not found" >&2
        exit 1
    elif [ ! -r "$input_roundedmgenplus_bold" ]
    then
        echo "Error: ${input_roundedmgenplus_bold} not found" >&2
        exit 1
    fi
    # Check filename
    [ "$(basename $input_ubuntumono)" != "UbuntuMono-R.ttf" ] \
        && echo "Warning: ${input_ubuntumono} is really UbuntuMono?" >&2
    [ "$(basename $input_roundedmgenplus_regu)" != "rounded-mgenplus-1m-regular.ttf" ] \
        && echo "Warning: ${input_roundedmgenplus_regu} is really Rounded Mgen+ 1M Regular?" >&2
    [ "$(basename $input_roundedmgenplus_bold)" != "rounded-mgenplus-1m-bold.ttf" ] \
        && echo "Warning: ${input_roundedmgenplus_bold} is really Rounded Mgen+ 1M Bold?" >&2
else
    cica_generator_help
fi

# Make temporary directory
tmpdir=`mktemp -d ./tmp/cica_generator_tmpdir.XXXXXX` || exit 2


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
    foreach
        ExpandStroke(${ascii_regular_width}, 0, 0, 0, 2)
    endloop
    Select(0u003e); Copy()           # >
    Select(0u003c); Paste(); HFlip() # <
    RoundToInt(); RemoveOverlap(); RoundToInt()
    Save("${tmpdir}/${modified_ubuntumono_regu}")
    Close()
endif

Quit()
_EOT_

########################################
# Generate script for modified Rounded Mgen+ 1M
########################################

cat > ${tmpdir}/${modified_roundedmgenplus_generator} << _EOT_
#!$fontforge_command -script

# Print message
Print("Generate modified Rounded Mgen+ 1M.")

# Set parameters
input_list  = ["${input_roundedmgenplus_regu}",    "${input_roundedmgenplus_bold}"]
output_list = ["${modified_roundedmgenplus_regu}", "${modified_roundedmgenplus_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
    # Open Rounded Mgen+ 1M
    Print("Find " + input_list[i] + ".")
    Open(input_list[i])
    # Scale Rounded Mgen+ 1M to standard glyph size
    ScaleToEm(860, 140)
    SelectWorthOutputting()
    ClearInstrs(); UnlinkReference()
    if ("$scaling_down_flag" == "true")
        Print("While scaling " + input_list[i]:t + ", wait a little...")
        SetWidth(-1, 1); Scale(91, 91, 0, 0); SetWidth(110, 2); SetWidth(1, 1)
        Move(23, 0); SetWidth(-23, 1)
    endif
    RoundToInt(); RemoveOverlap(); RoundToInt()
    # Save modified Rounded Mgen+ 1M
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
roundedmgenplus_list = ["${tmpdir}/${modified_roundedmgenplus_regu}", \\
                     "${tmpdir}/${modified_roundedmgenplus_bold}"]
fontfamily        = "$cica_familyname"
fontstyle_list    = ["Regular", "Bold"]
fontweight_list   = [400,       700]
panoseweight_list = [4,         7]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(fontstyle_list))
    # Merge fonts
    Print("While merging " + ubuntumono_list[i]:t \\
          + " with " + roundedmgenplus_list[i]:t + ", wait a little...")
    Open(ubuntumono_list[i])
    # Copy Ubuntu Mono Glyphs (0x21-0x4f9)
    u = 0x21
    while (u < 0x4f9)
        SelectMore(u)
        u++
    endloop
    Copy()
    Close()
    Open(roundedmgenplus_list[i])
    Select(0x21)
    Paste()
    # Set configuration
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
    # Modify Math Symbol to 2byte
    Select(0xb1); SelectMore(0xf7)
    Scale(200,130)
    Move(250,80)
    SetWidth(1000)
    ExpandStroke(30,45,1,1,0,2)
    Select(0x2715); Copy(); Select(0xd7); Paste()
    Scale(120)
    Move(20,0)
    SetWidth(1000)
    # Post-proccess
    SelectWorthOutputting()
    if(fontstyle_list[i] == "Light")
        # Copy 0x3e -> 0x3c & HFlip
        Print("Create <")
        ExpandStroke(20,45,1,1,0,2)
        Select(0x3e); Copy(); Select(0x3c); Paste(); HFlip()
        SelectWorthOutputting()
        Print("ExpandStroke for " + fontstyle_list[i] + " style....")
    endif

    RoundToInt(); RemoveOverlap(); RoundToInt()

    SetFontNames("Cica-" + fontstyle_list[i], \\
            "Cica", \\
            "Cica " + fontstyle_list[i], \\
            fontstyle_list[i])
    SetTTFName(0x411,0, "Takahiro Minami")
    SetTTFName(0x411,1, "Cica")
    SetTTFName(0x411,2, fontstyle_list[i])
    SetTTFName(0x411,4, "Cica " + fontstyle_list[i])
    SetTTFName(0x411,16, "Cica")
    SetTTFName(0x411,17, fontstyle_list[i])
    SetTTFName(0x409,0, "Takahiro Minami")
    SetTTFName(0x409,1, "Cica")
    SetTTFName(0x409,2, fontstyle_list[i])
    SetTTFName(0x409,4, "Cica " + fontstyle_list[i])
    SetTTFName(0x409,16,"Cica")
    SetTTFName(0x409,17, fontstyle_list[i])
    # Save Cica
    Print("Save " + fontfamily + "-" + fontstyle_list[i] + ".ttf.")
    Generate("./tmp/" + fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    Close()
i += 1
endloop

Quit()
_EOT_

########################################
# Generate Cica
########################################

$fontforge_command -script ${tmpdir}/${modified_ubuntumono_generator} \
    2> $redirection_stderr || exit 4
$fontforge_command -script ${tmpdir}/${modified_roundedmgenplus_generator} \
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
. misc/os2version_reviser.sh ./tmp/Cica-Regular.ttf
echo "OS2Version to 1 Cica Bold"
. misc/os2version_reviser.sh ./tmp/Cica-Bold.ttf
# echo "OS2Version to 1 Cica Light"
# . misc/os2version_reviser.sh Cica-Light.ttf

echo "Set powerline patch to Cica Regular"
fontforge -lang=py -script ./fontpatcher/scripts/powerline-fontpatcher --no-rename ./tmp/Cica-Regular.ttf
echo "Set powerline patch to Cica Bold"
fontforge -lang=py -script ./fontpatcher/scripts/powerline-fontpatcher --no-rename ./tmp/Cica-Bold.ttf

echo "Set underline position to Cica Regular"
fontforge -lang=py -script ./modify_underline.py "./Cica Regular.ttf"
echo "Set underline position to Cica Bold"
fontforge -lang=py -script ./modify_underline.py "./Cica Bold.ttf"

mv "./Cica Regular.ttf" ./tmp/Cica-Regular.ttf
mv "./Cica Bold.ttf" ./tmp/Cica-Bold.ttf
# echo "Set powerline patch to Cica Light"
# fontforge -lang=py -script ./fontpatcher/scripts/powerline-fontpatcher --no-rename Cica-Light.ttf

########################################
# Make temporary directory
tmpdir=`mktemp -d ./tmp/post_script_tmpdir.XXXXXX` || exit 2
cat > ${tmpdir}/${post_script} << _EOT_
# Print message
Print("Post Script...")

# Modify Cica Regular
Print("Modifying Cica-Regular.ttf")
Open("./tmp/Cica-Regular.ttf")
Print("Powerline griphs")
SelectMore(0xe0a0);SelectMore(0xe0a1);SelectMore(0xe0a2)
SelectMore(0xe0b0);SelectMore(0xe0b1);SelectMore(0xe0b2);SelectMore(0xe0b3)
ClearInstrs(); UnlinkReference()
Scale(64, 100)
SetWidth(500)
Select(0xe0a0);SelectMore(0xe0a1);SelectMore(0xe0a2)
CenterInWidth()
Select(0xe0b0);SelectMore(0xe0b1)
Move(-168, -50)
SetWidth(500)
Select(0xe0b2);SelectMore(0xe0b3)
Move(-265, -50)
SetWidth(500)
RoundToInt(); RemoveOverlap(); RoundToInt()
Generate("./Cica/Cica-Regular.ttf", "", 0x84)
Close()

# Modify Cica Bold
Print("Modifying Cica-Bold.ttf")
Open("./tmp/Cica-Bold.ttf")
Print("Scaling Powerline griphs")
SelectMore(0xe0a0);SelectMore(0xe0a1);SelectMore(0xe0a2)
SelectMore(0xe0b0);SelectMore(0xe0b1);SelectMore(0xe0b2);SelectMore(0xe0b3)
ClearInstrs(); UnlinkReference()
Scale(64, 100)
SetWidth(500)
Select(0xe0a0);SelectMore(0xe0a1);SelectMore(0xe0a2)
CenterInWidth()
Select(0xe0b0);SelectMore(0xe0b1)
Move(-168, -50)
SetWidth(500)
Select(0xe0b2);SelectMore(0xe0b3)
Move(-265, -50)
SetWidth(500)
RoundToInt(); RemoveOverlap(); RoundToInt()
Generate("./Cica/Cica-Bold.ttf", "", 0x84)
Close()

_EOT_

# Execute post_script

$fontforge_command -script ${tmpdir}/${post_script} \
    2> $redirection_stderr || exit 4
# Exit
$fontforge_command -script ./02_MergeEmoji.pe
$fontforge_command -script ./03_MergeDevIcon.pe
$fontforge_command -script ./09_SetFontInfo.pe
echo "Succeeded to generate Cica! check ./Cica/ directory"
exit 0
