import os
import re
import subprocess
import html
from pygdbmi.gdbcontroller import GdbController
from jinja2 import Template,Environment,FileSystemLoader
from pygments import highlight
from pygments.lexers import get_lexer_for_filename
from pygments.formatters import HtmlFormatter

def exe_name(path):
    return os.path.splitext(path)[0]

def compile_and_run(path,opt,argv):
    command = "gcc %s -o %s %s"%(opt,exe_name(path),path)
    os.system(command)
    p = subprocess.Popen(["./%s"%(exe_name(path))]+argv, stdout=subprocess.PIPE)
    out,err = p.communicate()
    if err:
        raise Exception("err")
    if p.returncode != 0:
        raise Exception("err")

    return (command,out.decode())

def compile(path,opt):
    command = "gcc %s -o %s %s"%(opt,exe_name(path),path)
    os.system(command)
    return command

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


    def gcc_and_run(gcc_options="-Wall -no-pie",argv=[]):
        nonlocal cur_session
        command,out = compile_and_run(cur_session.path,gcc_options,argv)

        result = ""

        result += ("<pre>\n")
        result += (" $ " + command + "\n")
        result += (" $ ./%s"%(exe_name(cur_session.path)))
        result += ("</pre>\n")

        result += ("<pre>\n")
        result += (out)
        result += ("</pre>\n")

        if cur_session.expected:
            if cur_session.expected != out:
                raise Exception("assert failed: %s != %s"%(cur_session.expected, out))

        return result

    def run_cmd(*cmdlist,expected=None):

        result = ""

        result += ("<pre>\n")

        for cmd in cmdlist:
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
            out,err = p.communicate()
            out = out.decode()
            if err:
                raise Exception(err)

            cmdstr = ""
            for c in cmd:
                cmdstr += c + " "
            result += (" $ " + cmdstr + "\n")
            result += (out)
            result += "\n"
        result += ("</pre>\n")

        if expected:
            if expected != out:
                raise Exception("assert failed: %s != %s"%(expected, out))

        return result

    def gcc(gcc_options="-Wall -no-pie"):
        nonlocal cur_session
        command = compile(cur_session.path,gcc_options)

        result = ""
        result += ("<pre>\n")
        result += (" $ " + command + "\n")
        result += ("</pre>\n")

        return result

    def gdb(*commands):
        gdb_args = ["gdb", "--nx", "--quiet", "--interpreter=mi3", "--args", "./%s"%(exe_name(cur_session.path))]
        gdb = GdbController(command=gdb_args)

        result = ""
        result += ("<pre>\n")
        result += " $ gdb --args ./%s\n"%(exe_name(cur_session.path))

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
                elif r['type'] == 'output':
                    result += (r['payload'].encode('utf-8').decode('unicode_escape')) + "\n"


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
    template.globals['run_cmd'] = run_cmd
    template.globals['gcc'] = gcc
    template.globals['gdb'] = gdb
    template.globals['end_file'] = end_file

    result = template.render()

    output = open(newpath, "w")
    output.write(result)
    output.close()
    os.rename(newpath, path)
