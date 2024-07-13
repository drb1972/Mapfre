/*--------------------------REXX----------------------------*\
 *  Find current SMF dataset gdg name                       *
 *  and send message to E to submit SMFREAD job.            *
\*----------------------------------------------------------*/
/* trace r */
arg smfid

sysid = mvsvar(sysname) /* System id */
if sysid = 'XXXX' then
  dsn = 'PRHN.NSMFXXXX.DAILY'
else
  dsn = 'PGHN.NSMF'smfid'.STOR'

evlib = 'PGEV.BASE'

q = outtrap(data.)
"listc ent('"dsn"')"
q = outtrap(off)

/* get current gdg dataset name     */
rec = data.0 -1
parse var data.rec . . name
do i = 1 to queued()
  pull x
end
/* send message to E                */
if sysid = 'XXXX' then do
  queue 'SMF DSN=' || name
  "alloc f(smf2) new space(2 2) cylinders recfm(f b) lrecl(80)"
  "execio "queued()" diskw smf2 (finis"
  "xmit rcjesx.e msgfile(smf2) nolog"
  "free f(smf2)"
end

/*--------------------------------------------------------------*/
/*  Submit PPCMSMF job                                          */
/*--------------------------------------------------------------*/
 ppcmmem = 'EE' || left(smfid,2,'X') || 'G' || left(right(name,6),3)
 address tso
 "alloc f(PPCMSMF) dsname('"evlib".JCL(PPCMSMF)') shr"
 "execio * diskr PPCMSMF (stem ppcmjcl. finis"
 "free f(PPCMSMF)"
 queue ppcmjcl.1
 queue "//SETVAR   SET MEMNAME="ppcmmem","
 queue "//         SMFDSN="name","
 queue "//         EVLIB="evlib
 do z = 5 to ppcmjcl.0
   queue ppcmjcl.z
 end
 "alloc fi(jclsub) sysout(a) writer(intrdr) lrecl(80) recfm(f b)"
 "execio "queued()" diskw jclsub (finis"
 "free fi(jclsub)"

exit
