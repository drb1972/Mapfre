/*REXX */
/*--------------------------REXX----------------------------*\
 *  Package inspect utility                                 *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
\*----------------------------------------------------------*/
trace 0

arg parm
select
  when subword(parm,1,1) = 'BATCH' then do
    pkgid = ''
    bflag = 'BATCH'
  end
  when subword(parm,1,1) = 'TEST' then do
    pkgid = ''
    bflag = ''
  end
  otherwise do
    pkgid = subword(parm,1,1)
    bflag = subword(parm,2,1)
  end
end

if pkgid = '' then do
  /* first check for point and shoot to a valid dsn */
  address ispexec 'VGET (ZSCREENI,ZSCREENC)'  /* Extract screen image */
  delims = "&<>()=', " || '"'
  curpos = zscreenc + 1
  do x = curpos to 1 by -1        /* find start of field */
    if pos(substr(zscreeni,x,1),delims) ^= 0 then do
      start = x + 1
      leave
    end
  end
  do x = curpos to length(zscreeni)  /* find end of field */
    if pos(substr(zscreeni,x,1),delims) ^= 0 then do
      len = x - start
      if len > 0 then do
        paspkgid = substr(zscreeni,start,len)
        upper paspkgid
        if left(paspkgid,2) = 'C0' then
          pkgid = paspkgid
        leave
      end
    end
  end
end

if pkgid = '' then do
  say 'Package id not specified'
  say
end
if pkgid = '' | pkgid = 'HELP' then do
  say 'To run in foreground:-'
  say ' From Endevor enter "IN <pkgid>"'
  say '           or enter "IN" and point and shoot to the package id'
  say ' From ISPF    enter "TSO EVIN <pkgid>"'
  say
  say 'To run in batch:-'
  say ' From Endevor enter "IN <pkgid> BATCH"'
  say '           or enter "IN BATCH" and point and shoot to the',
                           'package id'
  say ' From ISPF    enter "TSO EVIN <pkgid> BATCH"'
  exit 8
end

if bflag = 'BATCH' then
  call batch_run
else
  call foreground_run

exit


/*--------------------------------------------------------------------*/
/*  Batch run                                                         */
/*--------------------------------------------------------------------*/
batch_run:

  x = queued()               /* clear down queue in case of problems */
  do i = 1 to x
    pull
  end
  signal on error name exception
  address ispexec
    'vget (C1BJC1)'
    'vget (C1BJC2)'
    'vget (C1BJC3)'
    'vget (C1BJC4)'
  if c1bjc1 = '' then do
    say 'RC=8:  Unable to read jobcard information'
    exit 8
  end
  queue C1BJC1
  if c1bjc2 <> '' then
    queue C1BJC2
  if c1bjc3 <> '' then
    queue C1BJC3
  if c1bjc4 <> '' then
    queue C1BJC4
  queue '//*                                           '
  queue '//*  PACKAGE INSPECT                          '
  queue '//*                                           '
  queue '//ENBP1000 EXEC PGM=NDVRC1,                   '
  queue '//             PARM=ENBP1000,                 '
  queue '//             DYNAMNBR=1500                  '
  queue '//C1MSGS1  DD SYSOUT=*                        '
  queue '//C1MSGS2  DD SYSOUT=*                        '
  queue '//APIPRINT DD SYSOUT=*                        '
  queue '//HLAPILOG DD SYSOUT=*                        '
  queue '//SYSABEND DD SYSOUT=*                        '
  queue '//JCLOUT   DD SYSOUT=(A,INTRDR),              '
  queue '//            DCB=(LRECL=80,RECFM=F,BLKSIZE=0)'
  queue '//ENPSCLIN DD *                               '
  queue '  INSPECT PACKAGE' pkgid '.'
  queue ''
  address tso
  "alloc file(inspjcl) space(15,20) tracks reuse lrecl(80)"
  "execio * diskw inspjcl ( finis"
  x = listdsi(inspjcl file)
  "submit '"sysdsname"'"
  "free file(inspjcl)"

return

/*--------------------------------------------------------------------*/
/*  Foreground run                                                    */
/*--------------------------------------------------------------------*/
foreground_run:

  prog = 'ENBP1000'

  /*  Prepare SCL                                                       */
  address tso
  test=msg(off)
  "free f(enpsclin)"
  "alloc f(enpsclin) new space(2  2) cylinders recfm(f b) lrecl(80)"
  test=msg(on)
  queue "  INSPECT PACKAGE" pkgid "."
  "execio "queued()" diskw enpsclin (finis)"

  /*  Process SCL                                                      */
  test=msg(off)
  "alloc f(c1msgs1) new space(2  2) cylinders recfm(f b) lrecl(133)"
  "alloc f(sysprint) sysout(a)";
  "alloc f(systerm) sysout(a)";
  "alloc f(sysabend) sysout(a)";

  address "LINKMVS" prog
  linkrc = rc
  if rc < 5 then do
    zedsmsg  = 'Inspect RC='linkrc
    zedlmsg  = 'The inspect was successfull for package' pkgid
    address "ISPEXEC" "SETMSG MSG(ISRZ001)"
  end
  else do
    address ispf
    zedsmsg = 'Inspect error'
    address tso
    "execio * diskr c1msgs1 (stem i. finis"
    if rc <> 0 then do
      say 'Internal error. Contact Endevor Support'
      leave
    end
      address ispexec
    "lminit dataid(cid) ddname(c1msgs1)" /* init report for edit  */
    signal off error
    "browse dataid(&cid)"
    "lmfree dataid(&cid)"
    zedsmsg  = 'Inspect Failed RC='linkrc
    zedlmsg  = 'The inspect failed for package' pkgid
    address "ISPEXEC" "SETMSG MSG(ISRZ001)"
  end

  address tso
  "free f(ensclin)";
  "free f(c1msgs1)";
  "free f(sysprint)";
  "free f(systerm)";
  "free f(sysabend)";
  test=msg(off)

return
