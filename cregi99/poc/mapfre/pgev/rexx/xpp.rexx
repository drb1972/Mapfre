/* rexx */
trace off
arg parm

address ispexec
if parm = 'TEST' then do
  "libdef ispslib dataset id('prev.oev1.ispslib',
                             'prev.pev1.ispslib') stack"
  "libdef ispplib dataset id('prev.oev1.ispplib',
                             'prev.pev1.ispplib') stack"
end /* if parm = 'TEST' then do */
else do
  "libdef ispslib dataset id('prev.pev1.ispslib') stack"
  "libdef ispplib dataset id('prev.pev1.ispplib') stack"
end /* else do */

"vget (zuser zprefix zscreen)"
"vget (plextg pddiofi2 pddiofil pddiomem)    profile"

exportds =    zprefix"."zuser".TMP"zscreen"DDIO"

"display panel(xpp)"
panel_rc  = rc
do while panel_rc <> 08 & pfk <> pf03 & pfk <> pf04
if plextg = 'PLEXP1' then do
  pddiofil = strip(pddiofil,,"'")
  pddiofi2 = strip(pddiofi2,,"'")
  exportds = strip(exportds,,"'")
end /* if plextg = 'PLEXP1' then do */
if plextg = 'PLEXN1' then do
  pddiofil = strip(pddiofil,,"'")
  pddiofi2 = strip(pddiofi2,,"'")
  exportds = strip(exportds,,"'")
end /* if plextg = 'PLEXN1' then do */
if plextg = 'PLEXR1' then do
  pddiofil = strip(pddiofil,,"'")
  pddiofi2 = strip(pddiofi2,,"'")
  exportds = strip(exportds,,"'")
end /* if plextg = 'PLEXR1' then do */
if plextg = 'PPE100' then do
  pddiofil = strip(pddiofil,,"'")
  pddiofi2 = strip(pddiofi2,,"'")
  exportds = strip(exportds,,"'")
end /* if plextg = 'PPE100' then do */
  if parm = 'TEST' then
    call editjob xpp1
  else
    call subjob  xpp1
  "display panel(xpp)"
  panel_rc = rc
end /* do while panel_rc <> 08 & pfk <> pf03 & pfk <> pf04 */

address ispexec
 if plextg = 'PLEXP1' then do
  "vput (plextg pddiofil pddiofi2 pddiomem)    profile"
  "libdef ispplib"
  "libdef ispslib"
End /* if plextg = 'PLEXP1' then do */
 if plextg = 'PLEXN1' then do
  "vput (plextg pddiofil pddiofi2 pddiomem)    profile"
  "libdef ispplib"
  "libdef ispslib"
End /* if plextg = 'PLEXN1' then do */
 if plextg = 'PLEXR1' then do
  "vput (plextg pddiofil pddiofi2 pddiomem)    profile"
  "libdef ispplib"
  "libdef ispslib"
End /* if plextg = 'PLEXR1' then do */

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
