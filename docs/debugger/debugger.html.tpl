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
    さて、これまで何度も使ってきたgdb、つまりデバッガだが、これがどのように動いているかを見ていこう。
  </p>

  <p>
    "デバッガ" とはなんだろうか。
    "デバッガ" というと、バグを取ってくれるようなツールに聞こえるが、みなさんご存知のとおり、デバッガはプログラマのかわりにバグを取ってくれるわけではない。
    実際のデバッガの動作は実行中のプログラムの状態を見れるツール、つまり "プログラムの状態ビューワ" とでも言ったほうが、現実とあっているだろう。
  </p>

  <p>
    ここでは、外部のプログラムから、プログラムの状態を調べる方法を説明し、それを使うデバッガがどのように動いているかを説明していこう。
  </p>

<h2> ptrace </h2>

  <p>
    Linux ではデバッガの実装時に役立つ、ptrace というシステムコールがある。
  </p>

  <p>
    <em>ptrace</em> は、対象となるプロセスの状態を監視し、変更できるシステムコールである。
  </p>

  <p>
    デバッガを実装する場合、対象となるプログラムのメモリやレジスタを読んだり変更したりしたい場合は多いだろう。
    ptrace を使えば、それが実現できる。
  </p>

  {{ start_file("ptrace1.c") }}
  {{ include_source() }}
  {{ set_expected("aa55aa55
") }}
  {{ gcc_and_run() }}
  {{ end_file("ptrace1.c") }}

<p>
  まず、PTRACE_ATTACHと対象プロセスのpidを引数にして、ptrace を呼び出す。これで、対象プロセスが操作可能になる。
  ptraceの説明では、操作する側のプロセス(ここでは親プロセス)を <em>tracer</em>、操作される側(ここでは子プロセス)を<em>tracee</em>
  と呼んでいる。それにならって、ここでは同じようにtracer,traceeと呼ぶことにしよう。
</p>

<p>
  tracer が tracee をアタッチすると、tracee は停止する。これは非同期に実行されるので、停止したのが確定するまで待つ。これは、waitpidを使う。
</p>

<p>
  アタッチしたあと、PTRACE_PEEKDATAとpid,アドレスを引数にして、ptraceを呼び出すと、traceeのメモリからデータを読むことができる。
</p>

<p>
  この例では、tracee は、trace から fork したプロセスなので、変数 "x" のアドレスは同じになっている。そのため、PTRACE_PEEKDATA に x のアドレスを渡すと、traceeの変数"x"の値が取得できる。
  fork しない場合は、変数名とアドレスの対応は、なんらかの方法で取得する必要がある。取得方法についてはあとで説明しよう。
</p>


<p> tracee のメモリを書きかえたいときは、PTRACE_POKEDATA を使う </p>

{{ start_file("ptrace2.c") }}
{{ include_source() }}
{{ set_expected("88888888
") }}
  {{ gcc_and_run() }}
  {{ end_file("ptrace2.c") }}


<p> メモリと同様に、traceeのレジスタを読み書きすることができる。読むときはPTRACE_GETREGS、書くときはPTRACE_SETREGSだ。</p>

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

<ul>
  <li> SuspendThread, ResumeThread : スレッドの一時停止、再開 </li>
  <li> ReadProcessMemory, WriteProcessMemory : 対象プロセスのメモリの読み書き </li>
  <li> GetThreadContext, SetThreadContext : 対象プロセスのレジスタの読み書き </li>
</ul>

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
…が、プログラマがJTAGと言った場合は、ほぼ確実に、<em>CPUに搭載された状態観測用のハードウェアを使ってデバッグするインターフェース、ツール類のこと</em>を指す。
プログラマが言う"JTAG"は、本来の意味と少し違ってしまっていることに注意してほしい。
</p>

<p>
  現代(と言ってもかなり昔からだが)のCPUは、その機能の一部に、「CPUやメモリの状態を読み書きする専用のハードウェア」が搭載されている。このハードウェアは、ほぼ確実にJTAG仕様に準拠した信号線を経由して、外部と繋がっている。そのため、この「CPUやメモリの状態を読み書きする専用のハードウェア」を使う場合は、JTAGケーブルを使って、プログラムの状態を観測することになる。
</p>

<p>
  この、「JTAG経由で繋がった状態観測用のハードウェアを使ってgdbなどのデバッガを動かす」というのが、省略されて、「JTAGデバッグ」、そして、その周辺ツールが「JTAG」と呼ばれるようになっている。(筆者は、この用語の使いかたはWikipediaをWikiと略すよりひどいのではないかと思う。データの経路が名前になっているから、Wikipediaをインターネットと呼ぶようなものである)
</p>

<p>
  「CPUやメモリの状態を読み書きする専用のハードウェア」ができることは、gdb stubとほとんど同じだと考えてもらってよい。メモリやレジスタを読み書きでき、CPU実行の一時停止、再開ができる。
</p>

<p>
  gdb stubと違い、JTAG経由でCPUの状態を観測する場合は、ソフトウェアが完全に壊れて何も動かない場合や、ソフトウェアが初期化されていない状態でも使える。これは嬉しい場面が多いだろう。
  gdb stub を動かすには、割り込みなどが正しく処理されている必要があり、割り込みが動かないような問題の状態を観測したい場合には使えない。
  また、割り込みが動作して、シリアルケーブルが使えるようになるまでには、それなりの初期化が必要で、初期化処理を観測したい場合には、gdb stubは使えない。そのような場合でも、JTAG経由なら、CPUの状態を観測できる場合が多い。
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
{{ gdb('start','print value99','print helloworld', 'set value99=123456', 'continue') }}

<pre>
(gdb) <span class="gdb-command">print value99 # 変数名 "value99" が使える</span>
</pre>

<p> gdb が、変数 "value99","helloworld" という変数の名前をそのまま使えていることを確認してほしい。
  さらに、変数の型に応じて、適切な表示方法を採用しているのも確認してほしい。
  int型の変数に対しては、数字を表示し、char*型の変数に対しては、文字列を表示している。
</p>

<p>
  CPUが実行する時に使うデータは、メモリ上に展開されたバイナリデータだけで、操作するデータの変数名や型などは、実行時には必要ではない。
  ところが、デバッガからプログラムを実行すると、そこに変数名や型が存在するかのようにプログラムの状態を操作できるのだ。これはどうやっているのだろうか。
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
 (gdb) print value99
 (gdb) set value99=123456
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
  <li> value99 という名前から、型情報とアドレスを取得する </li>
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
  これは、テーブルから、シンボルの情報を取得するプログラムだ。ここでは、値は特に意味のない値だが、文字列をプログラムに渡すと、その型とアドレスのようなものが出力されることを確認してほしい。
</p>

{{ gcc('') }}
{{ run_cmd(["./dummy-debuginfo", "int_value"], ["./dummy-debuginfo", "str_value"]) }}
{{ end_file("dummy-debuginfo.c") }}

<p>
  ここでは、dummy_debuginfo には意味のない値が入っているが、ここに意味のある値が入っていたらどうなるだろうか。
</p>

<p> 次のプログラムをコンパイルして、readelf -s を使って、int_value, str_value のアドレスを取得しよう。</p>

{{ start_file("debugee1.c") }}
{{ include_source() }}
{{ gcc('-no-pie -nostartfiles -nostdlib') }}
{{ run_cmd(["readelf","-s","debugee1"]) }}

<pre>
 $ readelf -s a.out | grep int_value | awk '{print $2}' # 変数 int_value のアドレス
0000000000404000
 $ readelf -s a.out | grep str_value | awk '{print $2}' # 変数 str_value のアドレス
0000000000404008
</pre>

{{ end_file('debugee1.c') }}

<p> この取得したアドレスをさきほどのプログラムに入れたらどうなるだろうか。 </p>
<pre>
/* debugee1.c のデバッグ情報 */
const struct VarDebugInfo dummy_debuginfo[] = {
    {"int_value", TYPE_INT, 0x404000},
    {"str_value", TYPE_CHAR_PTR, 0x404008},
    {NULL}                              /* 終端 */
};
</pre>

<p> これは、もはやダミーのデバッグ情報ではなく、debugee1 というプログラムのためのデバッグ情報になるのだ。 </p>

<p> この debugee1 というプログラムのデバッグ情報を使って、gdb の print 相当の機能を実装してみよう。 </p>

{{ start_file('debugger1.c') }}
{{ include_source() }}
{{ gcc('') }}
{{ run_cmd(["./debugger1","int_value"], expected="int_value:1234, addr=404000
") }}
{{ run_cmd(["./debugger1","str_value"], expected="str_value:Hello World, var_addr=404008, value_addr=402000
") }}
{{ end_file('debugger1.c') }}

<p>
  このプログラムに int_value を指定した場合は、対象プログラム debugee1 の変数int_valueの値が整数値として、
  str_value を指定した場合は、変数str_valueの値が文字列として表示されることを確認し、この(自分で作った)テーブルが、デバッグ情報のようなものとして機能していることを確認しよう。
</p>

<p> <a href="../index.html"> 戻る </a> </p>

</body>
</html>
