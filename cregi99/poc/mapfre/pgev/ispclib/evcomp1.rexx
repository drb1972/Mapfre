/*--------------------------REXX----------------------------*/
/*  Compare Endevor controlled libraries                    */
/*----------------------------------------------------------*/
/*  Author:     Emlyn Williams                              */
/*              Endevor Support                             */
/*----------------------------------------------------------*/
trace n

arg dsn

sysuid   = sysvar(sysuid)
prefix   = sysvar(syspref)
cplex = 'N'
dplex = 'N'
eplex = 'N'
fplex = 'N'
mplex = 'Y'
nplex = 'Y'
pplex = 'Y'
qplex = 'Y'
rplex = 'N'
prev  = 'Y'

do forever
  cmprcmd = ''
  waitcmd = ''

  address ispexec "DISPLAY PANEL(EVCOMP)"

  if rc = 08 | pfk = pf03 | pfk = pf04 then leave

  if cplex = 'Y' then do
    cmprcmd = 'C1F' || ','
    waitcmd = 'CHKC1'
  end /* if cplex = 'Y' then do */

  if dplex = 'Y' then do
    cmprcmd = cmprcmd || 'D1F' || ','
    waitcmd = waitcmd 'CHKD1'
  end /* if dplex = 'Y' then do */

  if eplex = 'Y' then do
    cmprcmd = cmprcmd || 'E1F' || ','
    waitcmd = waitcmd 'CHKE1'
  end /* if eplex = 'Y' then do */

  if fplex = 'Y' then do
    cmprcmd = cmprcmd || 'F1F' || ','
    waitcmd = waitcmd 'CHKF1'
  end /* if fplex = 'Y' then do */

  if mplex = 'Y' then do
    cmprcmd = cmprcmd || 'M1F' || ','
    waitcmd = waitcmd 'CHKM1'
  end /* if mplex = 'Y' then do */

  if nplex = 'Y' then do
    cmprcmd = cmprcmd || 'N1F' || ','
    waitcmd = waitcmd 'CHKN1'
  end /* if nplex = 'Y' then do */

  if pplex = 'Y' then do
    cmprcmd = cmprcmd || 'P1F' || ','
    waitcmd = waitcmd 'CHKP1'
  end /* if pplex = 'Y' then do */

  if qplex = 'Y' then cmprcmd = cmprcmd || 'Q1F' || ','

  if rplex = 'Y' then do
    cmprcmd = cmprcmd || 'R1F' || ','
    waitcmd = waitcmd 'CHKR1'
  end /* if rplex = 'Y' then do */

  if prev  = 'Y' then do
    cmprcmd = cmprcmd || 'PREV' || ','
    prevdsn = 'PREV.P'substr(dsn,3,2)'1.'substr(dsn,11)
      if right(prevdsn,4) = 'DBRM' then prevdsn = prevdsn||'LIB'
      if left(dsn,6) = 'PGEV.P'
        then prevdsn = 'PREV.P'substr(dsn,7,2)'1.'substr(dsn,11)
  end /* if prev  = 'Y' then do */

  cmprcmd = STRIP(cmprcmd,'T',',')

  address ispexec 'ftopen temp'
  address ispexec 'ftincl ' evcomp
  address ispexec 'ftclose'
  address ispexec 'vget (ztempn)'
  address ispexec 'lminit dataid(did) ddname('ztempn')'
  address ispexec 'edit dataid('did')'
  address ispexec 'lmclose dataid('did')'
  address ispexec 'lmfree  dataid('did')'
/*address ispexec 'vget (ztempf) shared'*/
/*address tso     "submit '"ztempf"'"*/
  zcmd = ''
end /* do forever */

exit
