/***rexx*********************************************************/
/** PROGRAM: CHECKVAL                                          **/
/** Author: Stuart Ashby                                       **/
/** DATE: Started 26/04/2007                                   **/
/**                                                            **/
/** Function: This rexx checks the contents of the CHECKSUM    **/
/** datasets to ensure something has been captured.            **/
/**                                                            **/
/** 27/12/2007: make the checking more intelligent so that     **/
/**             if there are more or less input files, only    **/
/**             those that exist are checked.                  **/
/****************************************************************/

trace o

/* Get the dataset name */
"EXECIO * DISKR INPDSN (STEM DSN. FINIS)"

baselib = word(dsn.1,1)        /* get the base dataset name */
baselib = strip(baselib)

plexes  = word(dsn.1,2)
plexes  = strip(plexes)

sys     = substr(baselib,3,2)  /* system for dataset name */
uid     = sysvar(sysuid)       /* userid for dataset name */

duals  = translate(baselib,' ','.') /* get each dataset qualifier */
dual1  = word(duals,1)              /* hlq */
dual2  = word(duals,2)              /* 2nd qualifier */
dual3  = word(duals,3)
   dual3 = strip(dual3)
dual4  = word(duals,4)
   dual4 = strip(dual4)
     if dual4 = '' then llq = dual3 /* if dual4 is empty dual3 is llq */
                   else llq = dual3||'.'||dual4
testdsn = 'PGKS.'||uid||'.CKSUM.'||sys||'.'||llq||'.CHK'

cplex_res = 0
dplex_res = 0
mplex_res = 0
nplex_res = 0
pplex_res = 0
eplex_res = 0
rplex_res = 0
prev_res  = 0

/* Check if the Cplex file exists */
if pos('C1F',plexes) > 0 then do
if sysdsn("'"testdsn||'C1'"'") = 'OK' then do
  /* read the Cplex checksum file */
  "EXECIO * DISKR C1FILE (STEM CPLEX. FINIS)"

  /* if the dataset is empty then exit */
  if cplex.0 = 0 then call abendit cplex 1

  do i = 1 to cplex.0
    if substr(cplex.i,1,1) = '3' then cplex_res = 1
  end /* do i = 1 to cplex.0 */

end /* if sysdsn("'"testdsn||'C1'"'") = 'OK' then do */
else say 'CHECKVAL: No Cplex file found when there should have been'
end /* if pos('C1F',plexes) > 0 then do */
else cplex_res = 1

/* Check if the Dplex file exists */
if pos('D1F',plexes) > 0 then do
if sysdsn("'"testdsn||'D1'"'") = 'OK' then do
  /* read the Dplex checksum file */
  "EXECIO * DISKR D1FILE (STEM DPLEX. FINIS)"

  /* if the dataset is empty then exit */
  if dplex.0 = 0 then call abendit dplex 1

  do i = 1 to dplex.0
    if substr(dplex.i,1,1) = '3' then dplex_res = 1
  end /* do i = 1 to dplex.0 */

end /* if sysdsn("'"testdsn||'d1'"'") = 'OK' then do */
else say 'CHECKVAL: No Dplex file found when there should have been'
end /* if pos('D1F',plexes) > 0 then do */
else dplex_res = 1

/* Check if the Mplex file exists */
if pos('M1F',plexes) > 0 then do
if sysdsn("'"testdsn||'M1'"'") = 'OK' then do
  /* read the Mplex checksum file */
  "EXECIO * DISKR M1FILE (STEM MPLEX. FINIS)"

  /* if the dataset is empty then exit */
  if mplex.0 = 0 then call abendit mplex 1

  do i = 1 to mplex.0
    if substr(mplex.i,1,1) = '3' then mplex_res = 1
  end /* do i = 1 to mplex.0 */

end /* if sysdsn("'"testdsn||'m1'"'") = 'OK' then do */
else say 'CHECKVAL: No Mplex file found when there should have been'
end /* if pos('M1F',plexes) > 0 then do */
else mplex_res = 1

/* Check if the Nplex file exists */
if pos('N1F',plexes) > 0 then do
if sysdsn("'"testdsn||'N1'"'") = 'OK' then do
  /* read the Nplex checksum file */
  "EXECIO * DISKR N1FILE (STEM NPLEX. FINIS)"

  /* if the dataset is empty then exit */
  if nplex.0 = 0 then call abendit nplex 1

  do i = 1 to nplex.0
    if substr(nplex.i,1,1) = '3' then nplex_res = 1
  end /* do i = 1 to nplex.0 */

end /* if sysdsn("'"testdsn||'n1'"'") = 'OK' then do */
else say 'CHECKVAL: No Nplex file found when there should have been'
end /* if pos('N1F',plexes) > 0 then do */
else nplex_res = 1

/* Check if the Pplex file exists */
if pos('P1F',plexes) > 0 then do
if sysdsn("'"testdsn||'P1'"'") = 'OK' then do
  /* read the Pplex checksum file */
  "EXECIO * DISKR P1FILE (STEM PPLEX. FINIS)"

  /* if the dataset is empty then exit */
  if pplex.0 = 0 then call abendit pplex 1

  do i = 1 to pplex.0
    if substr(pplex.i,1,1) = '3' then pplex_res = 1
  end /* do i = 1 to pplex.0 */

end /* if sysdsn("'"testdsn||'p1'"'") = 'OK' then do */
else say 'CHECKVAL: No Pplex file found when there should have been'
end /* if pos('P1F',plexes) > 0 then do */
else pplex_res = 1

/* Check if the Eplex file exists */
if pos('E1F',plexes) > 0 then do
if sysdsn("'"testdsn||'E1'"'") = 'OK' then do
  /* read the Eplex checksum file */
  "EXECIO * DISKR E1FILE (STEM EPLEX. FINIS)"

  /* if the dataset is empty then exit */
  if eplex.0 = 0 then call abendit eplex 1

  do i = 1 to eplex.0
    if substr(eplex.i,1,1) = '3' then eplex_res = 1
  end /* do i = 1 to eplex.0 */

end /* if sysdsn("'"testdsn||'q1'"'") = 'OK' then do */
else say 'CHECKVAL: No Eplex file found when there should have been'
end /* if pos('E1F',plexes) > 0 then do */
else eplex_res = 1

/* Check if the Rplex file exists */
if pos('R1F',plexes) > 0 then do
if sysdsn("'"testdsn||'R1'"'") = 'OK' then do
  /* read the Rplex checksum file */
  "EXECIO * DISKR R1FILE (STEM RPLEX. FINIS)"

  /* if the dataset is empty then exit */
  if rplex.0 = 0 then call abendit rplex 1

  do i = 1 to rplex.0
    if substr(rplex.i,1,1) = '3' then rplex_res = 1
  end /* do i = 1 to rplex.0 */

end /* if sysdsn("'"testdsn||'r1'"'") = 'OK' then do */
else say 'CHECKVAL: No Rplex file found when there should have been'
end /* if pos('R1F',plexes) > 0 then do */
else rplex_res = 1

do i = 1 to qplex.0
   if substr(qplex.i,1,1) = '3' then qplex_res = 1
end /* do i = 1 to qplex.0 */

/* read the PREV checksum file */
"EXECIO * DISKR PREV (STEM PREV. FINIS)"
/* if the read fails then exit */
if rc > 0 then say 'CHECKVAL: No prev file found'

/* if the dataset is empty then exit */
if prev.0 = 0 then call abendit prev 1

do i = 1 to prev.0
   if substr(prev.i,1,1) = '3' then prev_res = 1
end /* do i = 1 to prev.0 */

if prev_res = 1 then if cplex_res = 0 then call abendit cplex 0
if prev_res = 1 then if dplex_res = 0 then call abendit dplex 0
if prev_res = 1 then if mplex_res = 0 then call abendit mplex 0
if prev_res = 1 then if nplex_res = 0 then call abendit nplex 0
if prev_res = 1 then if pplex_res = 0 then call abendit pplex 0
if prev_res = 1 then if eplex_res = 0 then call abendit qplex 0
if prev_res = 1 then if rplex_res = 0 then call abendit rplex 0

"execio * diskw prodlog (finis"

exit
Abendit:
arg ver reason

if reason = '0' then answer = 'Dataset is empty, but PREV has data'
if reason = '1' then answer = 'Checksum is empty'

queue 'CHECKVAL: Check 'baselib' on the 'ver' because 'answer
return
