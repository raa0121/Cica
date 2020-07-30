from bottle import get, post, request, static_file, run
import subprocess
import zipfile

@get('/')
def getIndex():
    return '''
        <form action="/" method="post">
            全角スペースに枠を
                <input type="radio" name="space" value="0" checked="checked">つける</input>
                <input type="radio" name="space" value="1">つけない</input><br>
            ゼロを
                <input type="radio" name="zero" value="0" checked="checked">dotted</input>
                <input type="radio" name="zero" value="1">slashed</input>
                <input type="radio" name="zero" value="2">Hack</input>
                <input type="radio" name="zero" value="3">blanked</input><br>
            アスタリスクのタイプを
                <input type="radio" name="asterisk" value="0" checked="checked">radial</input> 
                <input type="radio" name="asterisk" value="1">star</input><br>
            Dを
                <input type="radio" name="stroked_d" value="0" checked="checked">stroked</input> 
                <input type="radio" name="stroked_d" value="1">normal</input><br>
            縦線を
                <input type="radio" name="vertical_line" value="0" checked="checked">broken</input> 
                <input type="radio" name="vertical_line" value="1">solid</input><br>
            曖昧幅文字幅を
               <input type="radio" name="ambiguous_width" value="0" checked="checked">single</input> 
               <input type="radio" name="ambiguous_width" value="1">double</input><br>
            三点リーダー類の幅を
               <input type="radio" name="ellipsis" value="0" checked="checked">single</input> 
               <input type="radio" name="ellipsis" value="1">double</input><br>
            絵文字類を
               <input type="radio" name="emoji" value="0" checked="checked">noto emoji</input> 
               <input type="radio" name="emoji" value="1">system</input><br>
            mの中心の線が
               <input type="radio" name="modified_m" value="0" checked="checked">short</input> 
               <input type="radio" name="modified_m" value="1">Hack</input><br>
            WとMが
               <input type="radio" name="modified_WM" value="0" checked="checked">modified</input> 
               <input type="radio" name="modified_WM" value="1">Hack</input><br>
            emdashを
               <input type="radio" name="broken_emdash" value="0" checked="checked">broken</input>
               <input type="radio" name="broken_emdash" value="1">Hack</input><br>
            <input value="生成" type="submit" />
        </form>
    '''

@post('/')
def postIndex():
    command = ['fontforge', '-lang=py', '-script', 'cica.py']
    space = request.forms.space
    zero = request.forms.zero
    asterisk = request.forms.asterisk
    stroked_d = request.forms.stroked_d
    vertical_line = request.forms.vertical_line
    ambiguous_width = request.forms.ambiguous_width
    ellipsis = request.forms.ellipsis
    emoji = request.forms.emoji
    modified_m = request.forms.modified_m
    modified_WM = request.forms.modified_WM
    broken_emdash = request.forms.broken_emdash
    if space != '0':
        command.append('-s ' + space)
    if zero != '0':
        command.append('-z ' + zero)
    if asterisk != '0':
        command.append('-a ' + asterisk)
    if stroked_d != '0':
        command.append('-d ' + stroked_d)
    if vertical_line != '0':
        command.append('-v ' + vertical_line)
    if ambiguous_width != '0':
        command.append('-w ' + ambiguous_width)
    if ellipsis != '0':
        command.append('-e ' + ellipsis)
    if emoji != '0':
        command.append('-i ' + emoji)
    if modified_m != '0':
        command.append('-m ' + modified_m)
    if modified_WM != '0':
        command.append('-W ' + modified_WM)
    if broken_emdash != '0':
        command.append('-b ' + broken_emdash)
    try:
        res = subprocess.check_output(command)
    except:
        return '生成に失敗しました'
    else:
        filename = 'Cica.zip'
        with zipfile.ZipFile(filename, 'w', compression=zipfile.ZIP_DEFLATED) as new_zip:
            new_zip.write('dist/Cica-Regular.ttf', arcname="Cica-Regular.ttf")
            new_zip.write('dist/Cica-RegularItalic.ttf', arcname="Cica-RegularItalic.ttf")
            new_zip.write('dist/Cica-BoldItalic.ttf', arcname="Cica-Bold.ttf")
            new_zip.write('dist/Cica-Bold.ttf', arcname="Cica-BoldItalic.ttf")
            new_zip.write('LICENSE.txt', arcname="LICENSE.txt")
            new_zip.write('COPYRIGHT.txt', arcname="COPYRIGHT.txt")
        return static_file(filename, root='/work', download=filename)

run(host='0.0.0.0', port=8080, debug=True)
