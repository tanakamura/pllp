import os
import re
import subprocess
import html
from pygdbmi.gdbcontroller import GdbController
from jinja2 import Template,Environment,FileSystemLoader
from pygments import highlight
from pygments.lexers import get_lexer_for_filename
from pygments.formatters import HtmlFormatter

def compile_and_run(path):
    command = "gcc -no-pie -g -Wall -o test_prog " + path
    os.system(command)
    p = subprocess.Popen("./test_prog", stdout=subprocess.PIPE)
    out,err = p.communicate()
    if err:
        raise Exception("err")
    if p.returncode != 0:
        raise Exception("err")

    return (command,out.decode())

def compile(path):
    command = "gcc -no-pie -g -Wall -o test_prog " + path
    os.system(command)
    return command

def test(path, expect):
    (com,out) = compile_and_run(path)
    if out != expect:
        raise Exception("fail")
    return 0

class SourceSession:
    def __init__(self,path):
        self.path = path
        self.expected = None


def update_document(path):
    newpath = path + ".tmp"

    cur_session = None

    env = Environment(loader=FileSystemLoader('.'))
    template = env.get_template(path + '.tpl')
    formatter = HtmlFormatter(style='colorful', cssclass="pygments")

    def start_file(path):
        nonlocal cur_session
        cur_session = SourceSession(path)
        return ""
    def end_file(path):
        nonlocal cur_session
        if cur_session.path != path:
            raise Exception("unmatched path: %s != %s"%(cur_session.path, path))
        cur_session = None
        return ""

    def set_expected(expected):
        nonlocal cur_session
        cur_session.expected = expected
        return ""


    def gcc_and_run(gcc_options="-Wall -no-pie"):
        nonlocal cur_session
        command,out = compile_and_run(cur_session.path)

        result = ""

        result += ("<pre>\n")
        result += (" $ " + command + "\n")
        result += (" $ ./test_prog")
        result += ("</pre>\n")

        result += ("<pre>\n")
        result += (out)
        result += ("</pre>\n")

        if cur_session.expected:
            if cur_session.expected != out:
                raise Exception("assert failed: %s != %s"%(cur_session.expected, out))

        return result

    def gcc(gcc_options="-Wall -no-pie"):
        nonlocal cur_session
        command = compile(cur_session.path)

        result = ""
        result += ("<pre>\n")
        result += (" $ " + command + "\n")
        result += ("</pre>\n")

        return result

    def gdb(*commands):
        gdb_args = ["gdb", "--nx", "--quiet", "--interpreter=mi3", "--args", "./test_prog"]
        gdb = GdbController(command=gdb_args)

        result = ""
        result += ("<pre>\n")

        response = gdb.write("")
        for r in response:
            if r['type'] == 'stream' or r['type'] == 'console' or r['type'] == 'log':
                result += (r['payload'].encode('utf-8').decode('unicode_escape'))

        for c in commands:
            result += ("(gdb) ")
            response = gdb.write(c)
            for r in response:
                if r['type'] == 'log':
                    result += ('<span class="gdb-command">')
                    result += (r['payload'].encode('utf-8').decode('unicode_escape'))
                    result += ("</span>")
                elif r['type'] == 'stream' or r['type'] == 'console' or r['type'] == 'log':
                    result += (r['payload'].encode('utf-8').decode('unicode_escape'))

        result += ("</pre>\n")
        return result


    def include_source():
        nonlocal cur_session
        cur_file = cur_session.path
        result = ""
        result += ('<p><a href="%s"> %s </a><p>\n'%(cur_file,cur_file))
        src = open(cur_file).read()
        result += highlight(src,
                            lexer=get_lexer_for_filename(cur_file),
                            formatter=formatter)

        return result


    template.globals['start_file'] = start_file
    template.globals['include_source'] = include_source
    template.globals['set_expected'] = set_expected
    template.globals['gcc_and_run'] = gcc_and_run
    template.globals['gcc'] = gcc
    template.globals['gdb'] = gdb
    template.globals['end_file'] = end_file

    result = template.render()

    output = open(newpath, "w")
    output.write(result)
    output.close()
    os.rename(newpath, path)

#    lines = open(path).readlines()
#    newpath = path + ".tmp"
#    output = open(newpath, "w")
#
#    start_pat = re.compile(".*<!-- include ([a-zA-Z./_0-9\-]+) (run)? *-->.*")
#    expected_pat = re.compile(".*<!-- expected output -->.*")
#    end_pat = re.compile(".*<!-- *end +([a-zA-Z./_0-9\-]+) *-->.*")
#    gdb_start_pat = re.compile(".*<!-- gdb command *")
#    gdb_end_pat = re.compile(".*end gdb-->.*")
#
#    skip_start_pat = re.compile(".*<!-- start skip -->.*")
#    skip_end_pat = re.compile(".*<!-- end skip -->.*")
#
#    enabled = True
#    cur_file = None
#    cur_out = None
#    cur_com = None
#    has_expected = False
#    has_gdb = False
#
#    pos = 0
#    while pos < len(lines):
#        line = lines[pos]
#        m = start_pat.match(line)
#        if m:
#            if not enabled:
#                raise Exception("unmatched include")
#
#            output.write(line)
#            cur_file = m[1]
#            run = m[2]
#
#            output.write('<p><a href="%s"> %s </a><p>\n'%(cur_file,cur_file))
#            output.write("<pre>\n")
#            with open(cur_file) as source:
#                for line2 in source:
#                    output.write(html.escape(line2))
#            output.write("</pre>\n")
#
#            if run:
#                (cur_com,cur_out) = compile_and_run(cur_file)
#                output.write("<pre>\n")
#                output.write(" $ " + cur_com + "\n")
#                output.write(" $ ./test_prog")
#                output.write("</pre>\n")
#
#            enabled = False
#            pos = pos + 1
#        elif enabled:
#            output.write(line)
#            pos = pos + 1
#        else:
#            m = expected_pat.match(line)
#            if m:
#                pos=pos+2 # skip <pre>
#                cur_expect = ""
#                while True:
#                    line2 = lines[pos]
#                    pos = pos+1
#                    if line2 == "</pre>\n":
#                        break
#                    else:
#                        cur_expect += line2
#                        if cur_expect != cur_out:
#                            raise Exception("unexpected output")
#
#                output.write("<!-- expected output -->\n")
#                output.write("<pre>\n")
#                output.write(cur_out)
#                output.write("</pre>\n")
#                print("%-40s ... PASS"%(cur_file))
#                has_expected = True
#            elif gdb_start_pat.match(line):
#                gdb_coms = []
#                output.write(lines[pos])
#                pos = pos+1
#                while True:
#                    l = lines[pos]
#                    pos = pos+1
#                    output.write(l)
#                    if gdb_end_pat.match(l):
#                        break
#                    gdb_coms.append(l.rstrip('\n'))
#
#                gdb_args = ["gdb", "--nx", "--quiet", "--interpreter=mi3", "--args", "./test_prog"]
#                gdb = GdbController(command=gdb_args)
#
#                output.write("<!-- start skip -->\n")
#                output.write("<pre>\n")
#
#                response = gdb.write("")
#                for r in response:
#                    if r['type'] == 'stream' or r['type'] == 'console' or r['type'] == 'log':
#                        output.write(r['payload'].encode('utf-8').decode('unicode_escape'))
#
#                for c in gdb_coms:
#                    output.write("(gdb) ")
#                    response = gdb.write(c)
#                    for r in response:
#                        if r['type'] == 'log':
#                            output.write('<span class="gdb-command">')
#                            output.write(r['payload'].encode('utf-8').decode('unicode_escape'))
#                            output.write("</span>")
#                        elif r['type'] == 'stream' or r['type'] == 'console' or r['type'] == 'log':
#                            output.write(r['payload'].encode('utf-8').decode('unicode_escape'))
#
#
#                output.write("</pre>\n")
#                output.write("<!-- end skip -->\n")
#
#                print("%-40s ... with GDB"%(cur_file))
#                has_gdb = True
#            elif skip_start_pat.match(line):
#                pos = pos+1
#                while True:
#                    l = lines[pos]
#                    pos = pos+1
#                    if skip_end_pat.match(l):
#                        break
#            else:
#                pos = pos + 1
#                m = end_pat.match(line)
#                if m:
#                    end_file = m[1]
#                    if end_file != cur_file:
#                        raise Exception("unmatched include path name : " + end_file + " " + cur_file)
#
#                    if (not has_expected) and (not has_gdb):
#                        output.write("<pre>\n")
#                        output.write(cur_out)
#                        output.write("</pre>\n")
#
#                        print("%-40s ... SKIP"%(cur_file))
#
#                    output.write(line)
#                    enabled = True
#                    has_expected = False
#                    has_gdb = False
#
#
#    if not enabled:
#        raise Exception("unmatched include")
#
#    output.close()
#    os.rename(newpath, path)
