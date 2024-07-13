/* rexx */
trace n
arg parm

address ispexec
if parm = 'TEST' then do
  "libdef ispslib dataset id('prev.oev1.ispslib',
                             'prev.pev1.ispslib') stack"
  "libdef ispplib dataset id('prev.oev1.ispplib',
                             'prev.pev1.ispplib') stack"
end
else do
  "libdef ispslib dataset id('prev.pev1.ispslib') stack"
  "libdef ispplib dataset id('prev.pev1.ispplib') stack"
end

"vget (zuser)"
"vget (zprefix)"
"vget (zscreen)"
"vget (ddiofile)   profile"
"vget (ddiofil2)   profile"
"vget (ddiomem)    profile"

exportds =    zprefix"."zuser".TMP"zscreen"DDIO"

"display panel(xpq)"
panel_rc  = rc
do while panel_rc <> 08 & pfk <> pf03 & pfk <> pf04
  ddiofile = strip(ddiofile,,"'")
  ddiofil2 = strip(ddiofil2,,"'")
  exportds = strip(exportds,,"'")
  if parm = 'TEST' then
    call editjob xpq1
  else
    call subjob  xpq1
  "display panel(xpq)"
  panel_rc = rc
end

address ispexec
"vput (ddiofile)   profile"
"vput (ddiofil2)   profile"
"vput (ddiomem)    profile"
"libdef ispplib"
"libdef ispslib"

exit

/* +--------------------------------------------------------------+ */
/* !  SUBJOB - creates the JCL with file tailoring and submits    ! */
/* +--------------------------------------------------------------+ */
SUBJOB:
  arg skelid
  address ispexec 'ftopen temp'
  address ispexec 'ftincl ' skelid
  address ispexec 'ftclose'
  address ispexec 'vget (ztempf) shared'
  address tso     "submit '"ztempf"'"
return

/* +--------------------------------------------------------------+ */
/* !  EDITJOB - creates the JCL with file tailoring and edits     ! */
/* +--------------------------------------------------------------+ */
EDITJOB:
  arg skelid
  address ispexec 'ftopen temp'
  address ispexec 'ftincl ' skelid
  address ispexec 'ftclose'
  address ispexec 'vget (ztempn)'
  address ispexec 'lminit dataid(did) ddname('ztempn')'
  address ispexec 'edit dataid('did')'
  address ispexec 'lmclose dataid('did')'
  address ispexec 'lmfree  dataid('did')'
return
