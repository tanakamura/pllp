<html>
<head>
  <meta charset="utf-8"/>
  <title> デバッガ </title>
  <link rel="stylesheet" type="text/css" href="../style.css">
</head>

<body>

<!-- TOC -->
<!-- end TOC -->

<p> <a href="../index.html"> 戻る </a> </p>

<h1> <a href="debugger.html"> デバッガ </a> </h1>

<p>
  これまで何度も使ってきたgdb、つまりデバッガだが、これがどのように動いているかを見ていこう。
</p>

<p>
  "デバッガ" とはなんだろうか。
  "デバッガ" というと、バグを取ってくれるようなツールに聞こえるが、みなさんご存知のとおり、デバッガはプログラマのかわりにバグを取ってくれるわけではない。
  実際のデバッガの動作は実行中のプログラムの状態を見れるツール、つまり "プログラムの状態ビューワ" とでも言ったほうが、現実とあっているだろう。
</p>

<p>
  個人的には'デバッガ"という名称は実態とあってない、とは思うが、この章では、慣習にしたがって、プログラムの状態を調査、変更するツールのことを"デバッガ"と呼び、
  そのデバッガを使って実際に何かをすることを"デバッグ"と呼ぶ。
  また、デバッグされるプログラムの対象を"デバッギ(debugee)"と呼ぶ。
</p>

<p>
  この章では、まず、デバッガが必要とする基本的な操作について説明し、続けてデバッグ情報についても説明する。そのあと、その操作とデバッグ情報を組み合わせて、デバッガの機能を実現する方法について説明していく。
</p>

<h2> ptrace </h2>

<p>
  Linux ではデバッガの実装時に役立つ、ptrace というシステムコールがある。
</p>

<p>
  <em>ptrace</em> は、対象となるプロセスの状態を読み書きできるシステムコールである。
</p>

<p>
  デバッガを実装する場合、対象となるプログラムのメモリやレジスタを読み書きしたい場合が多い。
  ptrace を使えば、それが実現できる。
</p>

  {{ start_file("ptrace1.c") }}
  {{ include_source() }}
  {{ set_expected("aa55aa55
") }}
  {{ gcc_and_run() }}
  {{ end_file("ptrace1.c") }}

<p>
  まず、PTRACE_ATTACHと対象プロセスのpidを引数にして、ptrace を呼び出す。これで、対象プロセスがアタッチされる(操作可能になる)。
  ptraceの説明では、操作する側のプロセス(ここでは親プロセス)を <em>tracer</em>、操作される側(ここでは子プロセス)を<em>tracee</em>
  と呼んでいる。それにならって、ここでは同じようにtracer,traceeと呼ぶことにしよう。
</p>

<p>
  tracer が tracee をアタッチすると、tracee は停止する。これは非同期に実行されるので、停止したのが確定するまでwaitpidで待つ。
</p>

<p>
  アタッチしたあと、PTRACE_PEEKDATAとpid,アドレスを引数にして、ptraceを呼び出すと、traceeのメモリからデータを読むことができる。
</p>

<p>
  この例では、tracee は、trace から fork したプロセスなので、変数 "x" のアドレスは同じになっている。そのため、PTRACE_PEEKDATA に x のアドレスを渡すと、traceeの変数"x"の値が取得できる。
  fork しない場合は、変数名とアドレスの対応は、なんらかの方法で取得する必要がある。取得方法についてはあとでデバッグ情報のところで解説しよう。
</p>

<p>
  tracerが必要な操作を終えたあとは、PTRACE_DETACHでデタッチする(操作を終了する)。traceeがアタッチされたままだと、シグナルがtracerに送られてしまい、挙動が変わってしまう。このプログラムはシグナルを使っていないので影響ないが、正しく処理するときはデタッチしておこう。
</p>


<p> tracee のメモリを書きかえたいときは、PTRACE_POKEDATA を使う。PTRACE_ATTACHで一時停止したプログラムは、PTRACE_CONT を使えば、再開できる。また、この例では使っていないが、再開したプログラムを再度一時停止したい場合は、SIGSTOPを止めたいスレッドに送る。 </p>

{{ start_file("ptrace2.c") }}
{{ include_source() }}
{{ set_expected("88888888
") }}
  {{ gcc_and_run() }}
  {{ end_file("ptrace2.c") }}


<p> メモリと同様に、traceeのレジスタを読み書きすることができる。読むときはPTRACE_GETREGS、書くときはPTRACE_SETREGSを使う。</p>

{{ start_file("ptrace3.c") }}
{{ include_source() }}
{{ gcc_and_run() }}
{{ end_file("ptrace3.c") }}

<p> プログラムカウンタが、main の近くにあることを確認しよう。 </p>

<h2> Linux 以外 (ptraceが無い場合) </h2>

<p> ここまでに、</p>

<ul>
  <li> プログラムを一時停止、再開する (実行状態の変更) </li>
  <li> メモリの読み書き </li>
  <li> レジスタの読み書き </li>
</ul>

<p>
  これらの操作について説明してきた。
  これらの操作は、デバッガを作るときの、一番基本となる操作である。
  デバッガには、色々な機能があるが、多くの機能が、この操作を使って実現されている。
  つまり、これらの操作ができれば、その上にデバッガを実装できるわけだ。
</p>

<p>
  Linux では、これらの操作を実現するために、ptraceというシステムコールを使っていた。POSIX互換のOSでは、ptraceが実装されていることが多く、OSX等でも同じようにこれらの操作ができる。では他のシステムではどうだろうか。
</p>

<h3> Windows </h3>

<p>
  Windowsでは、これらの操作と対応するAPIが用意されており、それを使えばこれらの操作を実現できる。
</p>

<table>
  <tr> <th> 操作 </th> <th> API </th> <th> 対応するLinuxでの操作 </th> </tr>

  <tr> <td> デバッグの開始 </td> <td> DebugActiveProcess </td> <td> ptrace(PTRACE_ATTACH) </td> </tr>
  <tr> <td> デバッグの終了 </td> <td> DebugActiveProcessStop </td> <td> ptrace(PTRACE_DETACH) </td> </tr>
  <tr> <td> 実行の一時停止 </td> <td> SuspendThread </td> <td> SIGSTOPを送る </td> </tr>
  <tr> <td> 実行の再開 </td> <td> ResumeThread </td> <td> ptrace(PTRACE_CONT) </td> </tr>
  <tr> <td> メモリからの読み込み </td> <td> ReadProcessMemory </td> <td> ptrace(PTRACE_PEEKDATA) </td> </tr>
  <tr> <td> メモリへの書き込み </td> <td> WriteProcessMemory </td> <td> ptrace(PTRACE_POKEDATA) </td> </tr>
  <tr> <td> レジスタからの読み込み </td> <td> GetThreadContext </td> <td> ptrace(PTRACE_PEEKUSER) </td> </tr>
  <tr> <td> レジスタへの書き込み </td> <td> SetThreadContext </td> <td> ptrace(PTRACE_POKEUSER) </td> </tr>
</table>


<h3> gdb stub(OSが無い場合) </h3>

<p> ではOSが無い場合はどうだろうか。 </p>

<p> OSが無い場合の対処方はいくつかあるが、gdb stub を使う方法を紹介しよう。 </p>

<p> <em>gdb stub</em> (GDBのマニュアルでは、<em>Remote Stub</em> と呼ばれている) というのは、デバッガからのコマンドを受けて、デバッガが必要とする操作を対象プログラムの中で実行するモジュールのことだ。 </p>

<p>
  実行中のプログラムは、自分が実行されている環境のメモリやレジスタの値を読み書きできる。これはつまり自分自身がデバッガの機能を実現するための一部になれるということである。
</p>

<div class="imgbox">
  <img src="gdbstub.svg" width="100%">
</div>

<p>
  gdb stub は、対象プログラムに埋め込まれて、外部のgdbからコマンドを待つ。gdbからはメモリを読み書きしろとか、レジスタを読み書きしろというコマンドが送られてくる。
  gdb stub は、そのコマンドに従って、プログラムの状態を読み書きし、その結果をgdbに返す。
</p>

<p> gdb のソースコードには、いくつかのCPU用のstubが付属している。例えば、i386用のstubは、 <a href="https://sourceware.org/git/?p=binutils-gdb.git;a=blob;f=gdb/stubs/i386-stub.c;h=04996b75cf68073a9bdc3baba92ad96419d567fd;hb=HEAD">https://sourceware.org/git/?p=binutils-gdb.git;a=blob;f=gdb/stubs/i386-stub.c;h=04996b75cf68073a9bdc3baba92ad96419d567fd;hb=HEAD</a> このようになっている。</p>

<p> 詳細な説明は省略するが、レジスタやメモリを読み書きできるように作ってあることを読み取ってほしい </p>

<h3> JTAG </h3>

<p> <em> JTAG </em> (Joint Test Action Group) とは、狭義にはハードウェアのテスト用の標準を定めるグループと、そのグループが決めた仕様のことである </p>

<p> 現代のCPUのような超高密度な集積回路は、外部から触れられるピンだけを使って、内部の状態を観測することが現実的ではない。 </p>

<p> そのため、集積度の高い回路では、内部に、テスト用の回路も作っておき、そのテスト用の回路を経由して、回路に問題がないかテストするという方法がとられることが多い。
<em>JTAG</em> は、このテスト用の回路をどうやって接続するか、というのを決めた仕様のことである。
</p>

</p>
…が、プログラマがJTAGと言った場合は、ほぼ確実に、<em>CPUに搭載されたデバッグ用のハードウェアを使ってデバッグするインターフェース、ツール類のこと</em>を指す。
プログラマが言う"JTAG"は、本来の意味と少し違ってしまっていることに注意してほしい。
</p>

<p>
  現代(と言ってもかなり昔からだが)のCPUは、その機能の一部に、CPUやメモリの状態を読み書きする「デバッグ用ハードウェア」が搭載されている。このハードウェアは、ほぼ確実にJTAG仕様に準拠した信号線を経由して、外部と繋がっている。そのため、この「デバッグ用のハードウェア」を使う場合は、JTAGケーブルを使って、プログラムの状態を観測することになる。
</p>

<p>
  この、「JTAG経由で繋がったデバッグ用のハードウェアを使ってgdbなどのデバッガを動かす」というのが、省略されて、「JTAGデバッグ」、そして、その周辺ツールが「JTAG」と呼ばれるようになっている。(筆者は、この用語の使いかたはWikipediaをWikiと略すよりひどいのではないかと思う。データの経路が名前になっているから、Wikipediaをインターネットと呼ぶようなものである)
</p>

<p>
  「デバッグ用のハードウェア」は、ptraceやgdb stubとほぼ同じように、プログラムの実行状態の制御、メモリ・レジスタの読み書きができる。
</p>

<p>
  デバッグ用のハードウェアは、CPUの状態とは独立して動くので、ソフトウェアが完全に壊れて何も動かない場合や、ソフトウェアが初期化されていない状態でも使える。
  gdb stub を動かすには、割り込みなどが正しく処理されている必要があり、割り込みが動かないような問題をデバッグしたい場合や、割り込み等を初期化する前の状態をデバッグしたい場合には使えない。そのような場合でも、JTAG経由なら、デバッグできる場合が多いのは、助かる場面が多いだろう。
</p>

<p>
  JTAG経由でデバッガを使う場合は、実装方法は色々あるが、一例として接続サーバー経由でgdbを使う方法を説明しておこう。
</p>

<p>
  gdb stubのところで簡単に説明したが、gdbは、gdb stubに送るコマンドを、ネットワーク経由でも送れるようになっている。
  JTAG用に実装された接続サーバーは、gdb stubと同様に、gdbから送られるコマンドをパースして、それをハードウェア依存のコマンドに変換してJTAG経由でそのコマンドを状態観測用ハードウェアに送る。ハードウェアから得られた情報は、gdb stubと同様に、ネットワーク経由でgdbに届けられる。
  (接続サーバーが、gdb stubのように動作する)
</p>

<div class="imgbox">
  <img src="jtagdebug.svg" width="100%">
</div>


<h3> ICE (特に小さなCPUを使う場合) </h3>

<p> 組み込み開発でも、特に小さなCPUを使う場合は、<em> ICE </em> (In-circuit Emulator)というものを使うことがある。 </p>

<p>
  ICE は、状態観測用のインターフェースを付けた、デバッガに接続するためのCPUだ。
</p>

<p>
  JTAGが、CPUの機能の一部として実装されているのに対し、ICE は、チップ全体がデバッグ用に作られている。
</p>

<p>
  色々な周辺機器が繋がったSoCの場合、JTAG 経由では、CPUのコアしか状態観測ができず、I/Oの状態はCPUから見た状態しか観測できないが、ICE では、周辺I/Oも含めて、状態を監視、変更することができる。
</p>

<p>
  例えば、ダイマデバイスなどは、JTAG経由ではCPUを停止しても動き続けるが、ICE で状態を停止すると、タイマとCPUコアを同時に停止でき、問題が発生したときのタイマの状態を正しく観測できる。
</p>

<p>
  ただ、これが実現できるのは、CPUが本当に小さい場合だけで、大きなCPUでは、デバッグ専用のハードウェアを作るのは現実的ではない。現在では、組み込み開発でも本物のICEを見ることはほとんどなくなってしまったのではないかと思う。(筆者も数回ぐらいしか使ったことがない)
</p>


<h2> デバッガの実装 </h2>

<p> ここまでで、CPUやメモリの状態を観測する基本的な方法を説明した。ここからは、その方法を使ってどのようにデバッガを作っていくかを説明しよう。 </p>

<h3> デバッグ情報 </h3>

<p>
  デバッガの機能で興味深いのは、<em>変数や関数が存在するかのように見える</em> 点ではないだろうか。
</p>

{{ start_file("print-a.c") }}
{{ include_source() }}
{{ gcc('-no-pie -g -Wall') }}
{{ gdb('start','print int_value','print str_value', 'set int_value=123456', 'continue') }}

<pre>
(gdb) <span class="gdb-command">print int_value # 変数名 "int_value" が使える</span>
</pre>

<p>
  gdb が、変数 "int_value","str_value" という変数の名前をそのまま使えていることを確認してほしい。
  さらに、変数の型に応じて、適切な表示方法を採用しているのも確認してほしい。
  int型の変数に対しては、数字を表示し、char[]型の変数に対しては、文字列を表示している。
</p>

<p>
  CPUが実行する時に使うデータは、メモリ上に展開されたバイナリデータだけで、操作するデータの変数名や型などは、実行時には必要ではない。
  ところが、デバッガからプログラムを実行すると、そこに変数名や型が存在するかのようにプログラムの状態を操作できるのだ。これはどうやって実現しているのだろうか。
</p>

<p>
  これを実現するために、コンパイラやリンカは、実行ファイルの出力時に、<em>デバッグ情報</em>と呼ばれる、デバッガを補助するための追加のデータを、実行ファイルに含めて出力する。(Visual Studio のコンパイラでは、実行ファイルとは別に出力される)
</p>

{{ gcc('-no-pie -g -Wall') }}
{{ end_file("print-a.c") }}

<p> ここでは、コンパイル時に <em>-g</em> を付けている点に注意してほしい。この <em>-g</em> は、デバッグ情報を生成するようにgccに指示するオプションだ。これを付けると、gccとリンカは、出力される実行ファイルにデバッグ情報を追加する。</p>

<p> デバッグ情報の中身を見てみよう。デバッグ情報は readelf に -w オプションを付けるか、objdump に -g オプションを付けると見ることができる。どちらも同じものが表示されるので、以下では readelf -w を使うことにする。 </p>

<pre>
 $ readelf -w print-a
Contents of the .eh_frame section:


00000000 0000000000000014 00000000 CIE
  Version:               1
  Augmentation:          "zR"
  Code alignment factor: 1
  Data alignment factor: -8
  Return address column: 16
  Augmentation data:     1b
  DW_CFA_def_cfa: r7 (rsp) ofs 8
  DW_CFA_offset: r16 (rip) at cfa-8
  DW_CFA_nop
  DW_CFA_nop

... (以下大量の出力) ...
</pre>

<p> たった8行のプログラムにしては、かなりの量の情報がある。ここには一体何が含まれているのだろうか。以下では、このデバッグ情報の中身について説明していこう。 </p>

<h4> シンボルからアドレスと型情報への変換 </h4>

<p>
  デバッグ情報には、どういう情報を含めておけばよいだろうか。まず、print-a の例で説明したような、
</p>

<pre>
 (gdb) print int_value
 (gdb) set int_value=123456
</pre>

<p>
  といったようなコマンドを実現するためには、
</p>

<ul>
  <li> シンボル名から機械語中の実行時のアドレスを取得する </li>
  <li> シンボル名から型情報を取得する </li>
</ul>

<p>
  という処理が必要だ。これらの処理ができれば、gdb の print は、
</p>

<ol>
  <li> int_value という名前から、型情報とアドレスを取得する </li>
  <li> ptrace を使って、変数のアドレスから型のサイズ分バイト列を取得する </li>
  <li> 取得したバイト列を型情報に従って表示する </li>
</ol>

<p>
  という手順で実現できる。
</p>

<p>
  では、シンボル名からアドレスや型情報を取得するデータとはどのようなものだろうか。
</p>

<p>
  次のようなプログラムを考えよう。
</p>

{{ start_file("dummy-debuginfo.c") }}
{{ include_source() }}

<p>
  これは、以下のテーブルから、文字列と関連付けられた情報を取得するプログラムだ。
</p>

<pre>
/* デバッグ情報のようなもの */
const struct VarDebugInfo dummy_debuginfo[] = {
    {"int_value", TYPE_INT, 0x8000},
    {"str_value", TYPE_CHAR_ARRAY, 0x8008},
    {NULL}                              /* 終端 */
};
</pre>


<p>
ここでは、テーブルに入っている値は意味のない値だが、とりあえず何か名前を指定すると、その名前と関連する情報が表示される点を確認してほしい。
</p>

{{ gcc('') }}
<pre>
 $ ./dummy-debuginfo int_value 
sym: int_value, type:int, addr=0x0000000000008000 <em> # "int_value" という文字列と関連する情報が表示される </em>

 $ ./dummy-debuginfo str_value 
sym: str_value, type:char[], addr=0x0000000000008008 <em> # "str_value" という文字列と関連する情報が表示される </em>

</pre>

{{ end_file("dummy-debuginfo.c") }}

<p>
  では、この dummy_debuginfo に意味のある値が入っていたらどうなるだろうか。
</p>

<p> 次のプログラムをコンパイルしたのち、readelf -s を使って、int_value, str_value のアドレスを取得しよう。
  (実行ファイルを簡単にするため、libcとスタートアップルーチンをリンクしていない。これの意味については<a href="../linker.html">リンカの章</a>を参照のこと)
 </p>

{{ start_file("debuggee1.c") }}
{{ include_source() }}
{{ gcc('-no-pie -g -nostartfiles -nostdlib') }}
{{ run_cmd(["readelf","-s","debuggee1"]) }}

<pre>
 $ readelf -s debugee1 | grep int_value | awk '{print $2}' # 変数 int_value のアドレス
0000000000404000
 $ readelf -s debugee1 | grep str_value | awk '{print $2}' # 変数 str_value のアドレス
0000000000404008
</pre>

{{ end_file('debuggee1.c') }}

<p> この取得したアドレスをさきほどのプログラムに入れたらどうなるだろうか。 </p>
<pre>
/* debugee1.c のデバッグ情報 */
const struct VarDebugInfo debuginfo_for_debugee1[] = {
    {"int_value", TYPE_INT, 0x404000},
    {"str_value", TYPE_CHAR_PTR, 0x404008},
    {NULL}                              /* 終端 */
};
</pre>

<p> これは、もはやダミーの情報ではなく、debugee1 というプログラムのためのデバッグ情報になるのだ。 </p>

<p> このテーブルを使って、gdb の print のような機能を実装してみよう。 </p>

{{ start_file('debugger1.c') }}
{{ include_source() }}
{{ gcc('') }}
{{ run_cmd(["./debugger1","int_value"], expected="int_value:9999, addr=404000
") }}
{{ run_cmd(["./debugger1","str_value"], expected="str_value:@ello World, var_addr=404008
") }}
{{ end_file('debugger1.c') }}

<p>
  このプログラムを実行して、
</p>

<ul>
  <li> 引数に int_value を指定した場合は、対象プログラム debugee1 の変数int_valueの値が整数値として表示される</li>
  <li> 引数に str_value を指定した場合は、変数str_valueの値が文字列として表示される </li>
</ul>

<p> の二点を確認し、debuginfo_for_debugee1というテーブルが、gdb の print コマンドのようなものを実行するのに必要な情報として機能していることを確認してほしい。 </p>

<p> このテーブルは、<em> シンボル名をキーにして、そのシンボルと関連する情報を取得できる </em> データとなっている。 </p>

<p> これが、デバッグ情報が持つ重要な機能のうちのひとつだ。 </p>

<p> 実際のデバッグ情報が、このテーブルと同じような情報を持っていることを確認してみよう。</p>

<p>
  さきほどと同じように、readelf -w でデバッグ情報を見ていく。readelf -w は、デバッグ情報と関連するセクションを全て表示するが、表示するセクションを選ぶこともできる。
  readelf -wi を使って、.debug_info セクションのみを表示してみよう。
</p>


{{ run_cmd(["readelf","-wi","debuggee1"]) }}

<p> 次の箇所に注目しよう </p>

<pre>
 &lt;1&gt;&lt;2e&gt;: 省略番号: 1 (DW_TAG_variable)
    &lt;2f&gt;   DW_AT_name        : (間接文字列、オフセット: 0x52): int_value  <em> # シンボル名int_value </em>
    &lt;33&gt;   DW_AT_decl_file   : 1
    &lt;33&gt;   DW_AT_decl_line   : 1
    &lt;34&gt;   DW_AT_decl_column : 5
    &lt;35&gt;   DW_AT_type        : &lt;0x43&gt; <em> # この0x43が下の &lt;43&gt; と対応していて、signed int を意味する </em>
    &lt;39&gt;   DW_AT_external    : 1
    &lt;39&gt;   DW_AT_location    : 9 byte block: 3 0 40 40 0 0 0 0 0 	(DW_OP_addr: 404000) <em> # int_valueのアドレスは0x404000 </em>
 &lt;1&gt;&lt;43&gt;: 省略番号: 4 (DW_TAG_base_type) <em> # signed int </em>
    &lt;44&gt;   DW_AT_byte_size   : 4
    &lt;45&gt;   DW_AT_encoding    : 5	(signed)
    &lt;46&gt;   DW_AT_name        : int

(.. 省略 ..)

 &lt;1&gt;&lt;4a&gt;: 省略番号: 5 (DW_TAG_array_type) <em> # char [] 型 </em>
    &lt;4b&gt;   DW_AT_type        : &lt;0x61&gt; <em> # 下の&lt;61&gt;と対応していて、char型を意味する </em>
    &lt;4f&gt;   DW_AT_sibling     : &lt;0x5a&gt;

(.. 省略 ..)

 &lt;1&gt;&lt;61&gt;: 省略番号: 2 (DW_TAG_base_type) <em> # char 型 </em>
    &lt;62&gt;   DW_AT_byte_size   : 1
    &lt;63&gt;   DW_AT_encoding    : 6	(signed char)
    &lt;64&gt;   DW_AT_name        : (間接文字列、オフセット: 0x5c): char

(.. 省略 ..)

 &lt;1&gt;&lt;68&gt;: 省略番号: 1 (DW_TAG_variable)
    &lt;69&gt;   DW_AT_name        : (間接文字列、オフセット: 0x36): str_value <em> # シンボル名str_value </em>
    &lt;6d&gt;   DW_AT_decl_file   : 1
    &lt;6d&gt;   DW_AT_decl_line   : 2
    &lt;6e&gt;   DW_AT_decl_column : 6
    &lt;6f&gt;   DW_AT_type        : &lt;0x4a&gt; <em> # 上の &lt;4a&gt; 対応して char[] を意味する </em>
    &lt;73&gt;   DW_AT_external    : 1
    &lt;73&gt;   DW_AT_location    : 9 byte block: 3 8 40 40 0 0 0 0 0 	(DW_OP_addr: 404008) <em> # str_valueのアドレスは0x404008 </em>
</pre>

<p> この情報は、さきほど作った </p>

<pre>
/* debugee1.c のデバッグ情報 */
const struct VarDebugInfo debuginfo_for_debugee1[] = {
    {"int_value", TYPE_INT, 0x404000},
    {"str_value", TYPE_CHAR_PTR, 0x404008},
    {NULL}                              /* 終端 */
};
</pre>

<p>
  このテーブルとかなり似たデータが含まれている。つまり、この.debug_info セクションを適切に読むことができれば、
  上で見たdebuggee1.c のプログラムと同じように <em> シンボル名をキーにして、そのシンボルと関連する情報を取得できる </em> できるわけだ。
</p>

<p>
  この.debug_infoに含まれる情報は、<em>DWARF (debugging with attributed record formats)</em>という仕様に従って、格納されている。
  DWARFの構造は、少し複雑なので、ひととおりデバッグ情報について説明したあとで解説しよう。
  しばらくは readelf -w の情報を参考に、読み進めていってほしい。
</p>

<!--
<p>
  それでは、実際に、この .debug_info セクションから、VarDebugInfo のテーブルを作るプログラムを書いてみよう。
  このプログラムは、ELFファイルを操作する処理が含まれている。ELFファイルを操作するために知っておく構造については、リンカの章で説明しているので、そちらも参照してほしい。<span class="kokomade"> (まだ書いてないです。そのうち書きます) </span>
</p>
-->



<p> <a href="../index.html"> 戻る </a> </p>

</body>
</html>
