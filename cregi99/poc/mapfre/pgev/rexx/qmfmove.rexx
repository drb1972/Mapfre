/*--------------------------REXX----------------------------*\
 * This rexx is executed by the qmf data migrate move       *
 * processor MQMFMIG.                                       *
 * It creates a delete QMFQUERY and NDM data cards          *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace i
arg cmrno sub snode db2sub tables
rjob = 'R' || substr(cmrno,2,7)
tables = strip(tables,b,"'")
sub1 = left(sub,2) || '1'

say 'QMGMOVE: ' DATE() TIME()

/* Copy the QMFQUERY & change SELECTs to DELETEs  */
say 'QMGMOVE:  Creating DELETE query'
"execio * diskr qmfin (stem line. finis"
if rc > 0 then exit(5)
do i = 1 to line.0
  if word(line.i,1) = 'SELECT' & word(line.i,2) = '*' then
    line.i = 'DELETE' subword(line.i,3)
end /* i = 1 to line.0 */
/* Both the PARMD & PARMD# DSNs are the same.       */
/* The first write is done with BACKOUT=N so that   */
/* there is an existing member to back out to, thus */
/* leaving the member for backout execution.        */
"execio * diskw parmd# (stem line. finis"
if rc > 0 then exit(5)
"execio * diskw parmd  (stem line. finis"
if rc > 0 then exit(5)

/* Create the NDM data cards                      */
say 'QMGMOVE:  Creating NDM data cards'
queue rjob "PROCESS SNODE=CD.OS390."snode
do i = 1 to words(tables)
  table = word(tables,i)
  llq = translate(table,'#','_')
  select
    when length(llq) > 16 then
      llq = left(llq,8)'.'substr(llq,9,8)'.'substr(llq,17)
    when length(llq) > 8 then
      llq = left(llq,8)'.'substr(llq,9)
    otherwise nop
  end
  queue "STEPTAB"i" COPY FROM (PNODE DISP=SHR -"
  queue "  DSN=PREV."sub"."llq"("cmrno")) -"
  queue "  TO   (DISP=(RPL) -"
  queue "  UNIT=SYSDA DCB=(DSORG=PS) -"
  queue "  DSN=PGEV."sub1"."cmrno"."llq")"
end
"execio * diskw ndmdata (finis"
if rc > 0 then exit(5)


/* Copy the db2subsystem & owner info   */
say 'QMGMOVE:  Creating DB2 Subsystem parm'
"execio * diskr db2subi (stem db2. finis"
if rc > 0 then exit(5)
"execio * diskw db2subo (stem db2. finis"
if rc > 0 then exit(5)

/* Read the QMF SET GLOBAL variables from the procesor */
"execio * diskr parmin (stem set. finis"
if rc > 0 then exit(5)

db2own = word(db2.1,2)
/* Create the prod parms               */
say 'QMGMOVE:  Creating production parms'
do i = 1 to set.0
  queue set.i
end
queue " SET GLOBAL(OWNER="db2own
queue " SET GLOBAL(BACKOUT='NO'"
queue " SET GLOBAL(TRAINING='NO'"
"execio * diskw parmp (finis"
if rc > 0 then exit(5)

/* Create the prod backout parms       */
say 'QMGMOVE:  Creating production backout parms'
do i = 1 to set.0
  parmb.i = set.i
end
parmb.i = " SET GLOBAL(OWNER="db2own
i  = i + 1
parmb.i = " SET GLOBAL(BACKOUT='YES'"
i  = i + 1
parmb.i = " SET GLOBAL(TRAINING='NO'"
parmb.0 = i
/* Both the PARMB & PARMB# DSNs are the same.       */
/* The first write is done with BACKOUT=N so that   */
/* there is an existing member to back out to, thus */
/* leaving the member for backout execution.        */
"execio * diskw parmb# (stem parmb. finis"
if rc > 0 then exit(5)
"execio * diskw parmb  (stem parmb. finis"
if rc > 0 then exit(5)

/* Create training parms if a training owner has been set */
if db2.0 > 1 then do
  db2own = word(db2.2,2)
  /* Create the training parms           */
  say 'QMGMOVE:  Creating training parms'
  do i = 1 to set.0
    queue set.i
  end
  queue " SET GLOBAL(OWNER="db2own
  queue " SET GLOBAL(BACKOUT='NO'"
  queue " SET GLOBAL(TRAINING='YES'"
  "execio * diskw parmt (finis"
  if rc > 0 then exit(5)

  /* Create the training backout parms   */
  say 'QMGMOVE:  Creating training backout parms'
  do i = 1 to set.0
    parmx.i = set.i
  end
  parmx.i = " SET GLOBAL(OWNER="db2own
  i = i + 1
  parmx.i = " SET GLOBAL(BACKOUT='YES'"
  i = i + 1
  parmx.i = " SET GLOBAL(TRAINING='YES'"
  parmx.0 = i
  /* Both the PARMX & PARMX# DSNs are the same.       */
  /* The first write is done with BACKOUT=N so that   */
  /* there is an existing member to back out to, thus */
  /* leaving the member for backout execution.        */
  "execio * diskw parmx# (stem parmx. finis"
  "execio * diskw parmx  (stem parmx. finis"
  if rc > 0 then exit(5)
end /* if db2.0 > 1 */

exit
