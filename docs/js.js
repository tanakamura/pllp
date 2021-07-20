function clear_sections(off,a)
{
    for (var i=off+1; i<a.length; i++) {
        a[i] = 0;
    }
}

function insert_space(off) {
    var ret = "";
    for (var i=0; i<off; i++) {
        ret += "&nbsp;";
    }
    return ret;
}


function gen_section(x,off,sections)
{
    sections[off]++;
    var secname = "sec";
    var t = "";

    for (var i=0; i<=off; i++) {
        if (i == 0) {
            secname = secname + sections[i];
            t = "" + sections[i];
        } else {
            secname = secname + "." + sections[i];
            t = t + "." + sections[i];
        }
    }

    t = t + x.innerHTML;
    toc.innerHTML = toc.innerHTML + "<p><a href=\"#" + secname + "\">" + insert_space(off) + t + "</a></p>";
    x.innerHTML = "<a name=\"" + secname + "\" href=\"#" + secname + "\">" + t + "</a>";

    for (var i=off+1; i<sections.length; i++) {
        sections[i] = 0;
    }
}


function assign_section()
{
    var body = document.getElementById("global");
    var toc = document.getElementById("toc");
    var cn = body.childNodes;

    var sections = [0,0,0,0,0];

    for (var i=0; i<cn.length; i++){
        var x = cn[i];

        if (x.tagName == "H1") {
            gen_section(x,0,sections);
        }

        if (x.tagName == "H2") {
            gen_section(x,1,sections);
        }

        if (x.tagName == "H3") {
            gen_section(x,2,sections);
        }

        if (x.tagName == "H4") {
            gen_section(x,3,sections);
        }
    }
}

