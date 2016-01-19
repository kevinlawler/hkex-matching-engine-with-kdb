\d .q
/each: +-*%&|^<>=$ <= >= <> @ ? in within bin div abs log exp sqrt sin cos tan  f' f\: f/:
neg:-:;not:~:;null:^:;string:$:;reciprocal:%:;floor:_:;ceiling:-_-:;signum:{(x>0)-x<0}
mod:{x-y*x div y};xbar:{x*y div x:$[16h=abs[@x];"j"$x;x]};xlog:{log[y]%log x};and:&;or:|;each:{x'y};scan:{x\y};over:{x/y};prior:{x':y}
mmu:$;lsq:!;inv:!:;md5:-15!;ltime:%:;gtime:{t+x-%t:x+x-%x}; /xnull:{$[0>@y;(,y)@~x=y;x=y;y 0N;y]}

/aggr: last sum prd min max avg wsum wavg f/   /beta:{cov[x;y]%var x}
count:#:;first:*:;svar:{(n*var x)%-1+n:(#x)-+/^x};sdev:{sqrt svar x};scov:{(n*cov[x;y])%-1+n:(#x)-+/^x+y};med:{avg x(<x)@_.5*-1 0+#x,:()};all:min"b"$;any:max"b"$;rand:{*1?x}

/unif: f': f\
sums:+\;prds:*\;mins:&\;maxs:|\;fills:^\;deltas:-':;ratios:%':;avgs:{(+\x)%+\~^x};differ:~~':;prev: :':;next:{$[0h>@x;'`rank;1_x,,x 0N]};
rank:{$[0h>@x;'`rank;<<x]};reverse:|:;iasc:{$[0h>@x;'`rank;<x]};idesc:{$[0h>@x;'`rank;>x]}
asc:{$[99h=@x;(!x)[i]!`s#r i:<r:. x;`s=-2!x;x;0h>@x;'`rank;`s#x@<x]};desc:{$[99h=@x;(!x)[i]!r i:>r:. x;0h>@x;'`rank;x@>x]}

msum:{$[99h=@y;(!y)!.z.s[x;. y];y-(-x)_(0i*x#y),y:+\y]};mcount:{msum[x;~^y]};mavg:{msum[x;0.0^y]%mcount[x;y]};mdev:{sqrt mavg[x;y*y]-m*m:mavg[x;y:"f"$y]}
xrank:{$[0h>@y;'`rank;_y*x%#y:<<y]};mmin:{(x-1)&':/y};mmax:{(x-1)|':/y};xprev:{$[0h>@y;'`rank;y(!#y)-x]};rotate:{$[0h>@y;'`rank;98h<@y;'`type;#y;,/|(0;mod[x;#y])_y;y]}

/other: ~,#_ !.   getenv exit
distinct:?:;group:=:;where:&:;flip:+:;type:@:;key:!:;til:{$[0>@x;!x;'`type]};value:get:.:;attr:-2!;cut:{$[0h>@x;x*!-_-(#y)%x;x]_y}
set:{$[@x;.[x;();:;y];-19!((,y),x)]};upsert:.[;();,;] / :: ,: files?
raze:,/;union:?,;inter:{x@&x in y};except:{x@&~x in y};cross:{n:#m:&(#x)##y;$[99h=@x;((!x)[m],'n#!y)!(. x)[m],'n#. y;((),x)[m],'n#y]} /extant:{x@&~^x}
sv:{x/:y};vs:{x\:y};sublist:{$[99h=@y;sublist[x;!y]!sublist[x;. y];~0h>@x;$[.Q.qp y;.Q.ind[y];y]i+!"j"$0|x[1]&(#y)-i:*x;abs[x]<#y;x#y;y]}

/file&comm
read0:0::;read1:1::;hopen:<:;hclose:>:;hdel:~:;hsym:-1!';hcount:-7!;peach:{x':y};system:."\\",

/string:  like ss
ltrim:{$[~t&77h>t:@x;.z.s'x;" "=*x;(+/&\" "=x)_x;x]};rtrim:{$[~t&77h>t:@x;.z.s'x;" "=last x;|ltrim@|x;x]};trim:{ltrim rtrim x}
lower:{$[~t&77h>t:abs@@x;.z.s'x;19<t;.z.s@. x;~t in 10 11h;'`type;_x]}
upper:{$[~t&77h>t:abs@@x;.z.s'x;19<t;.z.s@. x;~t in 10 11h;'`type;[c:"c"$@[!256;97+!26;-;32];$[11=t;`$c@$x;c x]]]}
ssr:{,/@[x;1+2*!_.5*#x:(0,/(0,{n:x?"[";$[n=#x;n;n+.z.s$[(#x)=p:x?"]";'"unmatched ]";p]_x:(n+2+"^"=x n+1)_x]}y,"")+/:x ss y)_x;$[100h>@z;:[;z];z]]}

/select insert update delete exec  / fkeys[&keys] should be eponymous, e.g. order.customer.nation   
/{keys|cols}`t `f's{xasc|xdesc}`t n!`t xcol(prename) xcols(prearrange)  FT(xcol xasc xdesc)
view:{*|.`. .`\:x};tables:{."\\a ",$$[^x;`;x]};views:{."\\b ",$$[^x;`;x]}
cols:{$[.Q.qp x:.Q.v x;.Q.pf,!+x;98h=@x;!+x;11h=@!x;!x;!+0!x]} /cols:{!.Q.V x}
xcols:{(x,f@&~(f:cols y)in x)#y};keys:{$[98h=@x:.Q.v x;0#`;!+!x]};xkey:{(#x)!.[0!y;();xcols x]};
xcol:{.Q.ft[{+(x,(#x)_!y)!. y:+y}x]y};xasc:{$[$[#x;~`s=-2!(0!.Q.v y)x;0];.Q.ft[@[;*x;`s#]].Q.ord[<:;x]y;y]};xdesc:{$[#x;.Q.ord[>:;x]y;y]}
fkeys:{(&~^x)#x:.Q.fk'.Q.V x};meta:{([!c].Q.ty't;f:.Q.fk't;a:-2!'t:. c:.Q.V x)}

/ R uj R(union join) R lj K(left(equi/asof)join)   trade asof`sym`time!(`IBM;09:31:00.0)
lj:{.Q.ft[,\:[;y];x]} /;la:{$[&/j:z>-1;x,'y z;+.[+ff[x]y;(!+y;j);:;.+y z j:&j]]}{la[x;. y](!y)?(!+!y)#x}[;y]]x} /lj:,\:;aj:{lj[y]`s#xkey[x]z};aj0:{lj[y]`s#(x#z)!z}; /;bn:{@[i;&0>i:x bin y;:;#x]}
ljf:{$[`s=-2!y;aj[!+!y;x;0!y];.Q.ft[{$[&/j:(#y:. y)>i?:(!+i:!y)#x;.Q.fl[x]y i;+.[+x;(f;j);:;.+.Q.fl[((f:!+y)#x:.Q.ff[x]y)j]y i j:&j]]}[;y]]x]}
aj:{.Q.ft[{d:x_z;$[&/j:-1<i:(x#z)bin x#y;y,'d i;+.[+.Q.ff[y]d;(!+d;j);:;.+d i j:&j]]}[x,();;0!z]]y}
aj0:{.Q.ft[{d: z;$[&/j:-1<i:(x#z)bin x#y;y,'d i;+.[+.Q.ff[y]d;(!+d;j);:;.+d i j:&j]]}[x,();;0!z]]y}
ij:{.Q.ft[{x[j],'(. y)i j:&(#y)>i:(!y)?(!+!y)#x}[;y]]x}
pj:{.Q.ft[{x+0i^y(!+!y)#x}[;y]]x};asof:{f:!$[99h=@y;y;+y];(f_x)(f#x)bin y}
uj:{$[()~x;y;98h=@x;x,(!+x:.Q.ff[x;y])#.Q.ff[y;x];lj[(?(!x),!y)#x]y]}

/wj[-1000 2000+\:trade`time;`sym`time;trade;(quote;(max;`ask);(min;`bid))]  (given `sym`time xasc quote)
ww:{[a;w;f;y;z]f,:();e:+1_z;z:*z;y,'+f!+{[e;d;a;b]e@'d@\:a+!b-a}[*e;z f:*|e]/'+$[#g;(g#z)?g#y;0]|/:a+$[#g:-1_f;(f#z)bin@[f#y;*|f;:;]@;z[*f]bin]'w}
wj:{[w;f;y;z]ww[0 1;w;f;y;z]};wj1:{[w;f;y;z]ww[1;w-1 0;f;y;z]}

fby:{@[(#y)#x[0]0#x 1;g;:;x[0]'x[1]g:.=y]};xgroup:{x,:();a:x#y:0!y;$[#x_:y;+:'x@=a;a!+f!(#f:!+x)#()]};ungroup:{$[#x:0!x;,/+:'x;x]}
ej:{x,:();y[&#:'i],'(x_z)(!0),/i:(=x#z:0!z)x#y:0!y} /{ungroup lj[z]xgroup[x]y}

/`[:../]t[.{csv|txt}]
save:{$[1=#p:`\:*|`\:x:-1!x;set[x;. *p];   x 0:.h.tx[p 1]@.*p]}'
load:{$[1=#p:`\:*|`\:x:-1!x;set[*p;. x];set[*p].h.xt[p 1]@0:x]}'
rsave:{x:-1!x;.[`/:x,`;();:;.*|`\:x]}'
rload:{x:-1!x;.[*|`\:x;();:;.     x]}'
dsave:{.[*x;1_x,y,`;:;@[;*!+a;`p#].Q.en[*x]a:. y];y}/: 

show:{1 .Q.s x;};csv:"," / ";"  also \z 1 for "D"$"dd/mm/yyyy"

parse:{$["\\"=*x;(system;1_x);-5!x]};eval:-6!;reval:-24!
\d .Q  /def[`a`b`c!(0;0#0;`)]`b`c!(("23";"24");,"qwe")
k:3.3;host:-12!;addr:-13!;gc:-20!;w:{`used`heap`peak`wmax`mmap`mphy`syms`symw!(."\\w"),."\\w 0"}  / used: dpft en par chk ind fs fu fc
res:`in`within`like`bin`binr`ss`if`do`while`exec`select`insert`update`delete`avg`last`sum`prd`min`max`wsum`wavg`div`xexp`abs`sqrt`log`exp`sin`asin`cos`acos`tan`atan`exit`getenv`setenv`var`dev`cov`cor`enlist`svar`reval 
addmonths:{("d"$m+y)+x-"d"$m:"m"$x}
.Q.Xf:{y 1:0xfe20,("x"$77+@x$()),13#0x00;(`$($y),"#")1:0x};.Q.Cf:.Q.Xf`char
f:{$[^y;"";y<0;"-",f[x;-y];y<1;1_f[x;10+y];9e15>j:"j"$y*/x#10;(x_j),".",(x:-x)#j:$j;$y]}
fmt:{$[x<#y:f[y;z];x#"*";(-x)$y]}

/DO NOT USE ROUTINES PAST HERE. SUBJECT TO CHANGE
ff:{$[&/(!+y)in f:!+x;x;x,'(f_y)(#x)#0N]}
fl:{$[98h=t:@x;+fl[+x;+y];99h=t;@[x,y;f;:;x[f]fl'y f@:&(f:!x)in!y];t&t<78h;x^y;@[y;i;:;x i:&(0<#:'x)&~#:'y]]}
opt:{[o]x::$[#i:&o like"-[^0-9]*";i[0]#o;o];((`$1_*:)'o)!1_'o:i_o};def:{x,((!y)#x){$[0h>@x;*:;::](@*x)$y}'y}
qt:{$[99h=@x;(98h=@!x)&98h=@. x;98h=@x]}; v:{$[-11h=@x;.$[":"=*t:$x;`$t,"/";x];x]};
qp:{$[~98h=@x;0;@x:.+x;~":"=*$x;0]};      V:{$[qp x:v x;((,pf)!,. pf),+$[(~x in!d0[])&(x:.+x)in !.Q.vt;.Q.vp x;d0[]@x];0h>@*x:+0!x;x@'!x;x]}
ft:{$[$[99h=@t:v y;98h=@. t;0];[n:#+!y;n!x 0!y];x y]};
ord:{if[~&/b:(y,:())in .q.cols z;'y b?0b];ft[@[;!+t;@[;x@+y!(t:0!v z)y]]]z}

tx:{$[(77h<t)|~t:@x;$[0<t:@*x;-t;0];20h>t;t;11h=t:@x:.!x;t;98h=t;6h;1=#x:+!x;tx@*x;6h]};tt:0|tx'. V@
fk:{$[(20h>t)|77h<t:@x;`;98h>@. t:!x;`;t]};t:" bg xhijefcspmdznuvts";ty:{$[0h>x:tx x;.q.upper t@-x;t x]}
nct:{$[`~x;,/nct'.q.tables`.;([]n:x;c:.q.cols x;t:tt x)]}

fu:{[f;x]$[0h>@x;f x;f[u](u:?x)?x]}         /uniques
fc:{[f;x]$[(#x)&1<n:"j"$."\\s";,/f':(n;0N)#x;f x]}  /parallel on cut
A:"c"$65+!26;a:"c"$97+!26;n:"0123456789";nA:n,A;an:a,A,"_",n;b6:A,a,n,"+/"
id:{$[0h>@x;`${$[(*x)in n;"a",x;x]}x@&(x:$x)in an;ft[{s[i]:`$($s i:&(s in`i,res,!`.q)|~(s?s)=!#s:id'!x:+x),'"1";+s!. x}]x]}
j10:64/:b6?;x10:b6@0x40\: /base64 J from char10
j12:36/:nA?;x12:nA@0x24\: /base36 J from char12(cusip)

l:{if[$[1>@d:!f:-1!x;1;`.d~*d];:.[$[qt d;*|`\:f;`.];();:;d:. f]];d@:&~d like"*$";p:(d=`par.txt)|d like"[0-9]*";
 ."\\cd ",$x;{.q.set[x]$[0h>@!a:-1!x;. a;a`]}'d@&~(d=`html)|p|s:"."in'$d;if[|/p;L d@&p];if[~`.=x;(."\\l ",$:)'d@&s&~p];}

sw:{.q.sublist[_.5**|."\\C"]x};tab:{" "/:'(x*|/#:''y)$/:y};t0:{$[x>#y;((#*y)#'" -"),y;y]}
s1:{-3!x} /{$[0>t:@x;$x;99h<t;-3!x;1h=t;"01"x;4h=t;,/$sw x;10h=t;x;t&t<98h;" "/:$sw x;-3!x]}
s2:{$[99h=t:@x;((|/#:'x)$x:t0[#d;x]),'"| ",/:t0[#x:s2@!x]d:s2@. x;98h=t;(1#x),(,(#*x)#"-"),1_x:tab[1](,$!x),$[#*r:s2'. x:sw@+x;+r;()]
 ~#x;();t>77h;s1'x;t;$x;|/(97h<t)|0h>t:?@:'x;s1'x;(1<#?#:'x)|$[1=#t;(*t)in 1 4 10h;0];s1'x;tab[1]@s2'sw'x]}
S:{x[1]{$[x<#y;((x-2)#y),"..";y]}'$[t&77h>t:@z;,s1 z;99h<t;"\n"\:$z;$[s;,[;,".."];::]s2 .q.sublist[(y;n-s:(y+n:x[0]-2*.Q.qt z)<#z)]z]}
s:{$[(::)~x;"";`/:$[10h=@r:@[S[(."\\c")-2 1;0];x;::];,-3!x;r]]}

a0:(#:;*:;last;sum;prd;min;max;.q.all;.q.any;?:),a1:(avg;wsum;wavg;var;dev;cov;cor),`.q `svar`sdev`scov`med
IN:{$[99h<@x;x in y;0]};qa:{$[qb x;0;IN[*x;a0];1;|/qa'1_x]};qb:{(2>#x)|(@x)&~11=@x}

/ CAN EXIT HERE FOR SMALL Q
/ pt(tables) pf(date/month/year/int) pd(dirs) pv(values) pn(count)   pt::0#pf::`
vt:()!();
bv:{g:$[(::)~x;last;*:];x:`:.;f:{`/:'x,'d@&(d:!x)like"[0-9]*"};d@:<.:'$last'`\:'d:$[`par.txt in!x;,/f'-1!'`$0:`/:x,`par.txt;f x];
 T:!:'d;x:.q.except[?,/T]'({("DMJJ"`date`month`year`int?.Q.pf)$$last@`\:x}'d)!T;.Q.vt:t!{&max'x in y}[x;]'t:?,/. x;
 .Q.vp:t!{(+(,.Q.pf)!,0#y),'|0#?[`/:.Q.par[`:.;y;x],`;();0b;()]}'[t;.{x .q.except[. .Q.pf;y]}[g]'.Q.vt];
 .Q.pt,:{.[x;();:;+(!+.Q.vp x)!x];x}'.q.except[t;.Q.pt];}

pt:pm:();MAP:{{$[0>@a:.+0!. x;.q.set[x]@.`$-1_$a;]}'a@&~(a:."\\a")in pt;if[#pt;pm::pt!((`u#pd,'pv)!?[;();0b;()]'(pd dd'pv)#')'pt]}
dd:{`/:x,`$$y};d0:{dd[*|pd;*|pv]};p1:{$[#pm;pm[x](y;z);z in vt x;vp x;+(!+. x)!`/:dd[y;z],x]};p2:{0!(?).@[x;0;p1[;y;z]]}

p:{$[~#D;p2[x;`:.]':y;(,/p2[x]'/':P[i](;)'y)@<,/y@:i:&0<#:'y:D{x@&x in y}\:y]}
view:{pd::PD x:$[(::)~x;x;&PV in x];u~:?u::..[pf;();:;pv::PV x];x{.[y;();:;+(x . y,`.d)!y]}'pt::!x:d0[];pn::pt!(#pt)#()}
L:{D::();if[x~,`par.txt;if[~#x:,/D::!:'P::`$":",'0:*x;'`empty]];if[^*PV::x@:<x:(t:"DMJJ"i:10 7 4?#$*x)$$x;'`part]
 PD::$[#D::t$'$D;,/{P@&x in'D}'?PV;(#PV)#`:.];pf::`date`month`year`int i;view[];if[(0>."\\p")|."\\_";cn'.:'pt];}
/L:{P::,`:.;D::,x;pf::`date;pt::!P[0]@**D;T::P!P{z!{x!(y . ,[;`]z,)'x}[x;y]'z}[pt]'D}

cn:{$[#n:pn x:.+x;n;pn[x]:{#p1[x;y;z]}'[x;pd;pv]]};pcnt:{+/cn x};dt:{cn[y]@&pv in x}
ind:{,/i[j]{fp[pf;p]p1[x;pd y;p:pv y]z}[.+x]'(j:&~=':i)_y-n i:(n:+\0,cn x)bin y}
fp:{+((,*x)!,(#z)#$[-7h=@y;y;(*|x)$y]),+z}
foo:{[t;c;b;a;v;d]if[v;g:*|`\:b f:*!b;b:1_b];,/$[v|~#a;d fp[$[v;f,g;pf]]';::]p[(.+t;c;b;a)]d}

/ select{u's|a's[by[date,]u's]}from t where[date..],[sym{=|in}..],..
a2:({(%;(sum;("f"$;x));(#:;`i))};{(sum;(*;("f"$;x);y))};{(%;(wsum;x;y);(sum;("f"$;x)))};{(cov;x;x)};{(sqrt;(var;x))}
 {(-;(avg;(*;("f"$;x);y));(*;(avg;x);(avg;y)))};{(%;(cov;x;y);(*;(dev;x);(dev;y)))};{(.q.scov;x;x)};{(sqrt;(.q.svar;x))};{(*;(%;(#:;`i);(+;-1;(#:;`i)));(cov;x;y))})

/ x0 translate;x1 aggrs;x2 translate  ?terminal (subselect/exec within partition)  unknown assumed uniform?
qd:{$[(#:)~*x;(?:)~*x 1;0]};xy:{`$$*&x~/:y};         x1:{$[qb x;();IN[*x;a0];$[qd x;1_x;,x];,/x1'1_x]}
x0:{$[qb x;x;IN[*x;a1];x0 a2[a1?*x]. 1_x;x0'x]};x2:{$[qb x; x;IN[*x;a0];$[qd x;(#:;(?:;(,/;xy[x 1]y)));[y:xy[x]y;$[(?:)~*x;(?:;(,/;y));(#:)~*x;(sum;y);(*x;y)]]];x2[;y]'x]}
ua:{((`$$!#u)!u;x2[;u:?,/x1'x]'x:x0'x)};q0:{$[~qb x;,/q0'x;-11h=@x;*`\:x;()]};qe:{$[#x;99h=@x;1]}
ps:{[t;c;b;a]if[-11h=@t;t:. t];if[~qe[a]&qe[b]|-1h=@b;'`nyi];d:pv;v:$[q:0>@b;0;~#b;0;-11h=@v:*. b;pf~*`\:v;0]
 if[$[~#c;0;@*c;0;-11h=@x:c[0]1;pf~*`\:x;0];d@:&-6!*c;c:1_c]
 if[$[#c;0;(g:(. a)~,pf)|(. a)~,(#:;`i)];f:!a;j:dt[d]t;if[q;:+f!,$[g;?d@&0<j;,+/j]];if[v&1=#b;:?[+(pf,f)!(d;j)[;&0<j];();b;f!,(sum;*f)]]]
 if[~#d;d:pv@&pv=*|pv;c:,()];f:$[q;0#`;!b];g:$[#a;qa@*a;0]
 $[(1=#d)|$[q;~g;u&pf~*. b];$[~q;.q.xkey[f];b;?:;::]foo[t;c;b;a;v]d;(?).(foo[t;c;$[q;()!();b];*a;v]d;();$[q;0b;f!f];*|a:$[g;ua a;(a;$[#a;(,/;)'k!k:!a;()])])]}

/if[$[#a;pf~*!a;0];:fp[pf'`pf];if[$[#.Q.pm;(=;`date)~2#*c;0];:p3(pm[.+t;-6!*|*c];1_c;b;a)]
/dir part [`p#field] table [:,] x(dict) /group&index?  `:d/sym?x
/.[dir;();,;.Q.en[dir]x];@[f xasc dir;f;`p#]
en:{[d;x]if[#f@:&11h=@:'x f:!+x;(`/:d,`sym)??,/?:'x f;];@[x;f;`sym?]}
/en:{[d;x]@[x;f@&11h=@:'x f:!+x;`sym?]}  init(`:sym set `u#0#`)  everyday (sym:get`:sym;.Q.en;.Q.en;..;`:sym set sym)
par:{[d;p;t]`/:($[@!h:`/:d,`par.txt;`$":",h .q.mod[p;#h:0:h];d];`$$p;t)};qm:{$[(@x)|~#x;1;t:@*x;&/t=@:'x;0]}
dpt:{[d;p;t]@[par[d;p;t];`;:;en[d]`. . `\:t]} / allows `a.b
dpft:{[d;p;f;t]if[~&/qm'r:+en[d]`. . `\:t;'`unmappable];{[d;t;i;x]@[d;x;:;t[x]i]}[d:par[d;p;t];r;<r f]'!r;@[;f;`p#]@[d;`.d;:;f,r@&~f=r:!r];t}
hdpf:{[h;d;p;f](@[`.;;0#]dpft[d;p;f]@)'t@>(#.:)'t:.q.tables`.;if[h:@[<:;h;0];h"\\l .";>h]}

/loop through text /lc:{+/{+/0xa=1:(x;y*z;y)}[x;m]'!-_-(-7!x)%m:1048576} /line count of big file
fsn:{[f;s;n]((-7!s)>){[f;s;x;n]i:(#r)^1+last@&"\n"=r:1:(s;x;n);f@`\:i#r;x+i}[f;s;;n]/0};fs:fsn[;;131000]
/e.g. p:` sv(d:`:dir;`2007.02.12;`t);@[;`sym;`p#]p{@[x;`;,;`sym xasc .Q.en[d]get y]}/rdb's
dsftg:{[dpt;xom;f;tw;g]d:*dpt;dpt:par . dpt;x:*xom;if[~0<m:xom 2;m+:-7!x]  //(loop load/save)
 if[a>m:_a:(m-:o:xom 1)%b:+/tw 10=@*tw;'`length];0N!($dpt),": ",$m&:M;i::0;n::1000000&_1e8%b
 do[-_-m%n;@[dpt;`;$[i;,;:];en[d]@+g f!tw 1:(x;o+b*i;b*n&:m-i)];0N!i+:n];dpt};M:0W

/ fill in empty partitions
chk:{f:{`/:'x,'d@&(d:!x)like"[0-9]*"};d@:>.:'$last'`\:'d:$[`par.txt in!x;,/f'-1!'`$0:`/:x,`par.txt;f x]
 {[e;u;d]u[i]{.[x;(y;`);:;?[z;();0b;()]]}[d]'e i:&~u in!d}[d[(+u in/:t)?\:1b](0#.)'u,'`;u:?,/t:!:'d]'d}

\d .h / <t a>c</t>
htc:{,/("<";x;y;"</";x:($x),">")};hta:{,/("<";$x;,/" ",'($!y),'"=",'{$[10h=@x;"\"",x,"\"";$x]}'. y;">")};htac:{,/(hta[x]y;z;"</";$x;">")}
ha:{htac[`a;(,`href)!,x]y};hb:{htac[`a;`target`href!`v,,x]y};pre:{htc[`pre]@`/:x};xmp:{htc[`xmp]@`/:x}
cd:{.q.csv 0:x};td:{"\t"0:x};hc:{"&lt;"/:"<"\:x};xs:.q.ssr/[;"&<>";("&amp;";"&lt;";"&gt;")]
xd:{g:{(#*y)#'(,,"<",x),y,,,"</",x:($x),">"};(,"<R>"),(,/'+g[`r]@,/(!x)g'{,$[11h=@x;xs'$x;t&78h>t:@x;$x;xs'x]}'x:+0!x),,"</R>"}

ex:("<?xml version=\"1.0\"?><?mso-application progid=\"Excel.Sheet\"?>";);iso8601:{$[^x;"";@[$"p"$x;4 7 10;:;"--T"]]}
eb:{htac[`Workbook;(`$"xmlns",/:$``:ss`:o`:x`:html)!("urn:schemas-microsoft-com:office:",/:$(2#`spreadsheet),`office`excel),,"http://www.w3.org/TR/REC-html40"]x}
es:{htac[`Worksheet;(,`ss:Name)!,$x]htc[`Table]@,/(htc[`Row]@,/ec')'(,!+y),+.+y:0!y};ed:{ex eb es[`Sheet1]x};edsn:{ex eb@"\r\n"/:(!x)es'. x}
ec:{htc[`Cell]htac[`Data;(,`ss:Type)!,$`String`Number`String`DateTime`DateTime`String i](xs;$:;xs@$:;iso8601;iso8601 1899.12.31+"n"$;xs@$:)[i:-10 1 10 12 16 20h bin -@x]x}

\d .j    /[]{} Cbg*xhijefcspmdznuvt
e:{"c"$$[x<128;x;0b/:'@[;0;(1b,i#1b),]10b,/:((5 10;0 4 10)i:x>2047h)_0b\:"h"$x]}@256/:
q:"\"";s:{q,x,q};J:(($`0`1)!$`false`true;s;{$[#x;x;"null"]};s;{s@[x;&"."=8#x;:;"-"]};s)1 2 5 11 12 16h bin
j:{$[10=abs t:@x;s@,/{$[x in r:"\t\n\r\"\\";"\\","tnr\"\\"r?x;x]}'x;99=t;"{",(","/:(j'!x),'":",'j'. x),"}";-1<t;"[",($[98=t;",\n ";","]/:.Q.fc[j']x),"]";J[-t]@$x]}
/ c:{$["{"=*x;(`$c'n#'x)!c'(1+n:(u'x)?'":")_'x:d x;"["=*x;.Q.fc[c']d x;q=*x;$[1<+/v x;'`err;"",@[.:;x;. .q.ssr[.q.ssr[x;"\\\\";"\\134"];"\\u????";{1_-1_-3!e@"X"$2 2#2_x}]]];"a">*x;"F"$x;"n"=*x;0n;"t"=*x]}
/ k:{c x@&~v[x]&x in" \t\n\r"};v:{~0(0 1 0;1 0 2;1 1 1)\x*3>x:" \"\\"?x};u:{?[v x;x;" "]};d:{$[1<n:(s:+\1 -1 1 -1"{}[]"?t:u x)?0;1_'(0,&(","=n#t)&1=n#s)_x:n#x;()]}
k:-29!

\d .h
tx:`json`csv`txt`xml`xls!(.j.j';cd;td;xd;ed);xt:{$[`json=x;.j.k'y;'`nyi]} /;+(`$*y)!`$+1_y:"\t"\:'y}	/ *bifcsmdzuvt   /$[x~`xml;"<?xml version='1.0' encoding='UTF-8'?>"

c0:`024C7E;c1:`958600;logo:"kx.com" /logo:,/(c0;c1;c0){htac[`font;(,`color)!,x]y}'("[kx";"systems";"]")  /808000
logo:,/(c0;c1){htac[`font;(,`color)!,x]htc[`b]y}'("kx";".com")
sa:"a{text-decoration:none}",/`link`visited`active{"a:",($x),"{color:",y,"}"}'$(c0;c0;c1)
html:{htc[`html]htc[`head;htc[`style]sa,sb],htc[`body]x};sb:"body{font:10pt verdana;text-align:justify}"
fram:{htc[`html]htc[`head]htc[`title;x],htac[`frameset;(,`cols)!,($116|316&43+(7+"?"~*z)*|/#:'y),",*"]@,/hta[`frame]'((,`src)!,*z;`name`src!`v,,*|z)}
jx:{[j;x]x:. x;$[$[.Q.qt[x];(N:(*."\\C")-4)<n:#x;0];(" "/:ha'["?[",/:$(0;0|j-N),|&\(n-N;j+N);$`home`up`down`end],,($n),"[",($j),"]";"");()],hc'.Q.S[."\\C";j]x}
uh:{(*x),/{("c"$"X"$2#x),2_x}'1_x:"%"\:x} /uh:ssr[;"%??";{,"X"$1_x}];hu:ssr/[;" %";{"%",$"x"$*x}]
sc:"$-.+!*'(),",.Q.an;hug:{,/@["%",'$"x"$!256;x;:;x]@};hu:hug sc /rfc1738 safe
ty:{(`$*x)!*|x:+" "\:'x}("htm text/html";"html text/html";"csv text/comma-separated-values";"txt text/plain";"xml text/plain";"xls application/msexcel"
 "gif image/gif";"jpg image/jpeg";"png image/png";"bmp image/bmp";"ico image/x-icon";"svg image/svg+xml";"pdf application/pdf";"css text/css"
 "zip application/x-compressed";"js application/x-javascript";"doc application/msword";"swf application/x-shockwave-flash";"json application/json")
hn:{"HTTP/1.1 ",x,"\r\nContent-Type: ",$[#t:ty y;t;"application/octet-stream"],"\r\nConnection: close\r\nContent-Length: ",($#z),"\r\n\r\n",z}
HOME:"html";hy:hn"200 OK";hp:hy[`htm]html pre@;he:hn["400 Bad Request";`txt]"'",hc@   /GET /[r.{txt|csv|xml|xsl}]?..  or ?[J
.z.ph:{x:uh$[@x;x;*x];$[~#x;hy[`htm]fram[$.z.f;x]("?";"?",*x@<x:$(."\\v"),."\\b");x~,"?";hp@{hb["?",x]x}'n@<n:$(."\\v"),."\\b";"?["~2#x;hp jx["J"$2_x]R
  "?"=*x;@[{hp jx[0j]R::1_x};x;he];"?"in x;@[{hy[t]@`/:tx[t:*|`\:`$n#x]@.(1+n:x?"?")_x};x;he]
  #r:@[1::;`$":",p:HOME,"/",x;""];hy[`$last@"."\:x]"c"$r;hn["404 Not Found";`txt]p,": not found"]}

/ (notepad;.h.ht`kdb;browse) t/t0/t1 .head;para(http://.. \tcode\t); code(\t align)  <img <a#link print"all frames"
br:"<br>";hr:{(#x)#"-"};nbr:htc[`nobr];code:{" "/:@[x;1+2*!_.5*#x:"\t"\:x;{htc[`code]nbr hc x}]}
http:{$[#i:ss[x]"http://";(i[0]#x),/{ha[x;x:i#x],(i:&/x?") ")_x}'i_x;x]};text:{`/:{htc[`p]http code x}'x@&0<#:'x}
data:{if[100<#*x:.Q.tab[1]n#'x,\:(n:|/#:'x:"\t"\:'x:1_'x)#,"";0N!#*x;0N!'x];xmp$["- "~2#x 1;@[x;1;hr];x]}
ht:{[t]x:0:`$"src/",(T:t:$t),".txt";if[~"."=**x;T:*x;x:1_x];h:.q.trim(n@:i)_'x i:&0<n:("."=x)?'0b
 x[i]:h{htac[`h5;(,`id)!,x;y]}'H:("."/:'$(){$[y>#x;x,1;(y#x),1+x y-:1]}\n),'" ",/:h
 x:`/:("Copyright &copy; ",logo;htc[`h5]T),((#x)#(text;data))@'x:(&~=':~(0<#:'x)&" "=*:'x)_x
 c:h{hb[x,"#",y;z],br}[a:t,".htm"]'H;c:nbr@`/:$[&/n=:1;c;1_,/(,br),/:(&n)_c]
 (`$a)1:fram[T;H]b:"a/",/:("_",a;a);(`$b)1:'html'(($.z.D),htc[`h5;"Contents"],c;x);}

\d .o /odbc   timedec/cs could be 3(23,12)
ex:{$[.Q.qt x:."s)",x;0!x;x]} / char(1+) binary(display2*) -1 longvarchar -4 longvarbinary sql_no_total(-4)SAS/4096
T:`text`bit```tinyint`smallint`int`bigint`real`float`char`varchar``date`date`datetime``time`time`time
T0:  -1 -7 0 0 -6 5  4 -5  7  8 1  12 0  9  9 11 0 10 10 10h
B0:4096  1 0 0  1 2  4  8  4  8 1 255 0  6  6 16 0  6  6  6
C0:4096  1 0 0  3 5 10 19  7 15 1 255 0 10 10 23 0  8  8  8
PS:   1  2 0 0  2 2  2  2  2  2 3   3 0  2  2  2 0  2  2  2h /char basic both
t:0 1 4 5 6 7 8 9 10 11 14 15 19;Columns:{$[#x;Cols`$x;,/Cols'.q.tables`.]}
q)TI:`DATA_TYPE xasc([]TYPE_NAME:T t;DATA_TYPE:T0 t;COLUMN_SIZE:C0 t;LITERAL_PREFIX:`;LITERAL_SUFFIX:`;CREATE_PARAMS:`;NULLABLE:1h;CASE_SENSITIVE:1h;SEARCHABLE:PS t;UNSIGNED_ATTRIBUTE:0h;FIXED_PREC_SCALE:0h;AUTO_INCREMENT:0h;LOCAL_TYPE_NAME:`;MINIMUM_SCALE:0h;MAXIMUM_SCALE:0h)
q)TypeInfo:{$[count x;select from TI where DATA_TYPE="H"$x;TI]} /msqry32 uses special e.g. select p.i from p p
q)Special:{([]SCOPE:2h;COLUMN_NAME:(0&0<count x)#`i;DATA_TYPE:4h;TYPE_NAME:`int;COLUMN_SIZE:10;BUFFER_LENGTH:4;DECIMAL_DIGITS:0h;PSEUDO_COLUMN:2h)}
q)o:{flip(`TABLE_CAT`TABLE_SCHEM!``),flip x};Tables:{Ts[x 0;$[count t:1_x:`$","vs x except"'";t;enlist`TABLE]]}
q)Ts:{y:raze{([]TABLE_NAME:(tables`.;views`.)`TABLE`VIEW?x;TABLE_TYPE:x;REMARKS:`)}each y;o$[`~x;y;y where x=y`TABLE_NAME]}
q)Stats:{o([]TABLE_NAME:1#`$x;NON_UNIQUE:0Nh;INDEX_QUALIFIER:`;INDEX_NAME:`;TYPE:0h;ORDINAL_POSITION:0h;COLUMN_NAME:`;ASC_OR_DESC:`;CARDINALITY:count value x;PAGES:0N;FILTER_CONDITION:`)}
q)Cols:{o([]TABLE_NAME:x;COLUMN_NAME:cols x;DATA_TYPE:T0 t;TYPE_NAME:T t;COLUMN_SIZE:C0 t;BUFFER_LENGTH:B0 t:.Q.tt x;DECIMAL_DIGITS:0h;NUM_PREC_RADIX:10h;NULLABLE:1h;REMARKS:`)}
q)Key:{o([]TABLE_NAME:x;COLUMN_NAME:r;KEY_SEQ:"h"$1+til count r:keys x:`$x;PK_NAME:`)}
q)FG:{o([]PKTABLE_NAME:x;PKCOLUMN_NAME:"s"$(first keys@)each x;FKTABLE_CAT:`;FKTABLE_SCHEM:`;FKTABLE_NAME:y;FKCOLUMN_NAME:z;KEY_SEQ:1h;UPDATE_RULE:0h;DELETE_RULE:0h;FK_NAME:`;PK_NAME:`)}
Fkey:{FG[. r;x;!r:.q.fkeys x:`$x]};Gkey:{FG[x;"s"$*r;"s"$*|r:+,/(x:`$x){y,'&x=.q.fkeys y}'.q.tables`.]}

\d .
{@[.:;"\\l ",$[#e:getenv`QINIT;e;"q.q"];::]}[];

\
clib: strlen strcat strcmp    regexp  str[str|chr] str[n]cpy  (strmat strind substr trim)
java: length concat compareTo matches indexOf      substring trim to{Lower|Upper}Case
sql3: char_length || < == >   similar position     substring trim   {lower|upper}
