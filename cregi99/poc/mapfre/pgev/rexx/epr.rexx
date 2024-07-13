/* Rexx *************************
trace s
*/
/*
::   Expand Processor and Symbolic Substitution into JCL
::
::   By  Andrew Bassett-Smith, 1996-9
::
::   This routine expands the C1MSGS1 output from your job log (needs
::    to be copied into a dataset first!) into pure JCL.
::
::   The routine expects that the full C1MSGS1 output be used
::
::   The output from this routine is all the symbolics replaced with
::    their execution values!, the SCL statement, and Step RC's inserted
::
::   This is ideal where you need to debug a processor and it's
::    symbolics
::
::
::   For help/further info, I can be contacted via email at:
::    andrewbs@ozemail.com.au (H)
*/
/*
::
::   As datasets are required, chg the following lines so that
::    swdsnpfx eventually has the standard for your personal
::    dataset naming...
::
::   If you can create datasets beginning with your userid, then
::    use...    swdsnpfx = userid( )
::    other sites require some form of group HLQ based on your logon
::    profile
::
::  Update - March 1999
::    Use full C1MSGS1 stuff
::    Output shows SCL statement, then JCL used, and Step RC's
::
::
::
*/
swuid = sysvar("SYSUID")
swpref = sysvar("SYSPREF")
swdsnpfx = swpref"."swuid
f = 'Y'
e = 'Y'
dsq0 = ''
dsq1 = ''
dsq2 = ''
dsq3 = ''
dsq4 = ''
dsq5 = ''
dsq6 = ''
dsq7 = ''
dsq8 = ''
dsq9 = ''
dsq10 = ''
do forever
  "ISPEXEC DISPLAY PANEL(EPR01)"
  if rc = 8 then exit
  din = "'"dsq0"'"
  if din = "''" then din = "'"dsq1'.'dsq2'.'dsq3'('dsq4")'"
  a = msg("OFF")
  z = sysdsn(din)
  a = msg("ON")
  if z ^= 'OK' then do
    zedsmsg = z
    zedlmsg = 'Dataset 'din' not available for input processing...',
              ' Reason: 'z
    "ISPEXEC SETMSG MSG(ISRZ001)"
    iterate
   end
  leave
 end
do forever
  "ISPEXEC DISPLAY PANEL(EPR02)"
  if rc = 8 then exit
  dcr8 = 'Y'
  dout = "'"dsq9"'"
  if dout = "''" then do
    dout = "'"dsq5'.'dsq6'.'dsq7"'"
    a = msg("OFF")
    z = sysdsn(din)
    a = msg("ON")
    if z ^= 'OK' then do
      zedsmsg = z
      zedlmsg = 'Dataset 'din' not available for output processing...',
                ' Reason: 'z
      "ISPEXEC SETMSG MSG(ISRZ001)"
      iterate
     end
    dout = "'"dsq5'.'dsq6'.'dsq7'('dsq8")'"
    dcr8 = 'N'
   end
  leave
 end
a = msg("OFF")
"FREE FI(C1MSGS PROCESS PROCES1 SYMBOLS STEPRC)"
/*
::   Edit the input dataset, ensure that the Processor listing
::    and Symbolic substitution sections are included...
*/
if e = 'Y' then "ISPEXEC EDIT DATASET("din")"
/*
::   The second and third files have the processor and symbolic
::    information written to them respectively
*/
"ALLOC DD(C1MSGS) DSN("din") SHR"
"DELETE '"swdsnpfx".PROCESS'"
"DELETE '"swdsnpfx".STEPRC'"
"DELETE '"swdsnpfx".SYMBOLS'"
if dcr8 = 'Y' then do
  "DELETE "dout
  "ALLOC DD(proces1) DSN("dout") NEW CATALOG,
    SPACE(1 1) TRACKS UNIT(SYSDA) LRECL(80) BLKSIZE(9040) RECFM(F B)"
 end
else do
  "ALLOC DD(proces1) DSN("dout") shr"
 end
a = msg("ON")
"ALLOC DD(PROCESS) DSN('"swdsnpfx".PROCESS') NEW CATALOG,
  SPACE(1 1) TRACKS UNIT(SYSDA) LRECL(80) BLKSIZE(9040) RECFM(F B)"
"ALLOC DD(SYMBOLS) DSN('"swdsnpfx".SYMBOLS') NEW CATALOG,
  SPACE(1 1) TRACKS UNIT(SYSDA) LRECL(80) BLKSIZE(9040) RECFM(F B)"
"ALLOC DD(STEPRC) DSN('"swdsnpfx".STEPRC') NEW CATALOG,
  SPACE(1 1) TRACKS UNIT(SYSDA) LRECL(80) BLKSIZE(9040) RECFM(F B)"
t.1 = ''
t.2 = 'Started'
t.3 = 'Complete'
scl1 = ''
scl2 = ''
scl3 = ''
scl4 = ''
scl5 = ''
scl6 = ''
scl7 = ''
scl8 = ''
scl9 = ''
scl10 = ''
pls = 1
sys = 1
sts = 1
sos = 1
ass = 1
ats = 1
wrs = 1
wos = 1
sclno = 0
do forever
  ij=0
  do forever
    execio 1 diskr c1msgs
    src = rc
    if sRC = 2 then leave
    pull ln_detls
    if substr(ln_detls,22,2) ^= 'C1' then iterate
    ln1 = substr(ln_detls,22,8)
/*
::   SCL statement starts...
*/
    if ln1 = C1G0202I then
     do
      sclno = sclno + 1
      scl1 = ''
      scl2 = ''
      scl3 = ''
      scl4 = ''
      scl5 = ''
      scl6 = ''
      scl7 = ''
      scl8 = ''
      scl9 = ''
      scl10 = ''
      sclln. = ''
      scno = 0
      pls = 1
      sys = 1
      sts = 1
      sos = 1
      ass = 1
      ats = 1
      wrs = 1
      call msgs
      do forever
        execio 1 diskr c1msgs
        pull ln_detls
        if substr(ln_detls,22,2) ^= C1 then iterate
        ln2 = substr(ln_detls,22,8)
        if ln2 = C1G0265I | ln2 = C1G0200I then leave
        ln_detls = substr(ln_detls,30)
        ln2 = ''
        lnc = length(ln_detls)
        do while lnc > 60
          ln2 = substr(ln_detls,lnc,1)ln2
          lnc = lnc - 1
         end
        do while substr(ln_detls,lnc,1) ^= ' ' & ln2 > ''
          ln2 = substr(ln_detls,lnc,1)ln2
          lnc = lnc - 1
         end
        ln_detls = substr(ln_detls,1,lnc)
        queue '//*'ln_detls
        execio 1 diskw proces1
        scno = scno + 1
        sclln.scno = ':'ln_detls
        call sclmsgs
        if ln2 > '' then do
          ln2 = '             'ln2
          scno = scno + 1
          sclln.scno = ':'ln2
          call sclmsgs
          queue '//*'ln2
          execio 1 diskw proces1
         end
       end
     end
/*
::   A Processor listing line has been read - write to it's output
::    file - IFF no symbolics have been read (ie ij = 0)
*/
    if ln1 = C1G0249I then
     do
      if pls = 1 then do
        pls = 2
        call msgs
       end
      queue substr(ln_detls,32)
      execio 1 diskw process
     end
/*
::   A Symbolic line has been found - ensure that the & is present
::
::   and there is a second line with the replacement value (bypass
::    any page header type lines)
*/
    if ln1 = C1G0009I then
     do
      ij=1
      if sys = 1 then do
        pls = 3
        sys = 2
        call msgs
       end
      if substr(ln_detls,36,8) = ORIGINAL then
       do
        queue substr(ln_detls,50)
        execio 1 diskw symbols
        execio 1 diskr c1msgs
        pull ln_detls
        do forever
          if substr(ln_detls,36,12) = SUBSTITUTED then leave
          execio 1 diskr c1msgs
          pull ln_detls
         end
        queue substr(ln_detls,50)
        execio 1 diskw symbols
       end
     end
/*
::   A Step RC has been found
*/
    if  ln1 = C1X0010I & ij = 1 then
     do
      if sts = 1 then do
        sts = 2
        pls = 3
        sys = 3
        call msgs
       end
      queue substr(ln_detls,32,80)
      execio 1 diskw steprc
     end
/*
::   End of Element processing has been found
*/
    if ln1 = C1G0200I then leave
   end
/*
::   Ok, all the input data has been read in
*/
  sts = 3
  pls = 3
  sys = 3
  if src = 2 then leave
  execio 0 diskw process "(FINIS"
  execio 0 diskw symbols "(FINIS"
  execio 0 diskw steprc "(FINIS"
/*
:: read in saved details
*/
  jcl. = ''
  execio "*" diskr process "(STEM jcl. FINIS"
  symb. = ''
  execio "*" diskr symbols "(STEM symb. FINIS"
  strc. = ''
  execio "*" diskr steprc "(STEM strc. FINIS"
  do x = 1 to jcl.0
    jcl.x = strip(jcl.x)
   end
  do x = 1 to symb.0
    symb.x = strip(symb.x)
   end
  do x = 1 to strc.0
    strc.x = strip(strc.x)
   end
  sos = 2
  call msgs
/*
::  Sort and remove SYMBOL duplicates
*/
  syma. = ''
  symm. = ''
  syma.1 = symb.1
  symm.1 = symb.2
  x=1
  y=3
  do while y < symb.0
    a = symb.y
    y = y + 1
    b = symb.y
    y = y + 1
    z = 0
    do z1 = 1 to x
      if a = syma.z1 then z = 1
     end
    if z = 1 then iterate
    z = x
    x = x + 1
    z1 = x
    do forever
      if a > syma.z then do
        syma.z1 = syma.z
        symm.z1 = symm.z
        z1 = z
        z = z - 1
        if z = 0 then leave
        iterate
       end
      leave
     end
    syma.z1 = a
    symm.z1 = b
   end
  y=1
  do forever
    f2c = substr(jcl.y,1,2)
    f3c = substr(jcl.y,1,3)
    y = y + 1
    if f2c = '/*' | f3c = '//*' then iterate
    leave
   end
  y = y+1
  do forever
    f2c = substr(jcl.y,1,2)
    f3c = substr(jcl.y,1,3)
    if f2c = '/*' | f3c = '//*' | f3c = '// ' then
     do
      y = y + 1
      iterate
     end
    leave
   end
  sos = 3
  ass = 2
  call msgs
  do forever
    z = index(jcl.y,'&')
    if z = 0 then
     do
      if y >= jcl.0 then leave
      y = y + 1
      iterate
     end
    afnd = 0
    do z = 1 to x
      z1 = index(jcl.y,syma.z)
      if z1 = 0 then iterate
      afnd = 1
      za = length(syma.z)
      ln1 = substr(jcl.y,1,z1-1)
      ln2 = substr(jcl.y,z1 + za,1000)
      jcl.y = ln1||symm.z||ln2
     end
    if afnd = 0 then do
      if y = jcl.0 then leave
      y =y+1
     end
   end
  x = 1
  ln1 = word(strc.x,2)
  ass = 3
  ats = 2
  call msgs
  do y = 1 to jcl.0
    f2c = jcl.y
    f3c = substr(f2c,1,3)
    if f3c = '/* ' | f3c = '//*' | f3c = '// ' then iterate
    f3c = substr(word(f2c,1),3)
    if f3c <> ln1 then iterate
    strcl.x = y
    x = x + 1
    ln1 = word(strc.x,2)
   end
  y = 1
  ats = 3
  wrs = 2
  call msgs
  do x = 1 to jcl.0
    queue jcl.x
    execio 1 diskw proces1
    if x <> strcl.y then iterate
    queue '//** 'strc.y
    execio 1 diskw proces1
    y = y + 1
   end
 end
execio 0 diskr c1msgs "(FINIS"
wrs = 3
wos = 2
call msgs
execio 0 diskw proces1 "(FINIS"
"FREE FI(C1MSGS PROCES1 PROCESS SYMBOLS STEPRC)"
a = msg("OFF")
"DELETE '"swdsnpfx".PROCESS'"
"DELETE '"swdsnpfx".STEPRC'"
wos = 3
call msgs2
"DELETE '"swdsnpfx".SYMBOLS'"
a = msg("ON")
if f = 'Y' then "ISPEXEC EDIT DATASET("dout")"
exit

msgs:
plt = t.pls
syt = t.sys
stt = t.sts
sot = t.sos
ast = t.ass
att = t.ats
wrt = t.wrs
wot = t.wos
"ISPEXEC CONTROL DISPLAY LOCK"
"ISPEXEC DISPLAY PANEL(EPR2)"
return

msgs2:
wot = t.wos
"ISPEXEC CONTROL DISPLAY LOCK"
"ISPEXEC DISPLAY PANEL(EPR3)"
return

sclmsgs:
select
 when scno = 1 then scl1 = sclln.scno
 when scno = 2 then scl2 = sclln.scno
 when scno = 3 then scl3 = sclln.scno
 when scno = 4 then scl4 = sclln.scno
 when scno = 5 then scl5 = sclln.scno
 when scno = 6 then scl6 = sclln.scno
 when scno = 7 then scl7 = sclln.scno
 when scno = 8 then scl8 = sclln.scno
 when scno = 9 then scl9 = sclln.scno
 when scno = 10 then scl10 = sclln.scno
 end
call msgs
return
