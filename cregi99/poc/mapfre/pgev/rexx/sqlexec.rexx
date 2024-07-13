/*--------------------------REXX----------------------------*\
 * This rexx executes SQL.                                  *
 * It has been written in order to switch to the Endevor    *
 * alternate id to execute the SQL.                         *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
 *----------------------------------------------------------*
 *                                                          *
\*----------------------------------------------------------*/
trace n

arg db2sub c1prgrp
say 'SQLEXEC: ' DATE() TIME()
say 'SQLEXEC:  *** Input parameters ***'
if left(c1prgrp,3) ^= 'SQL' then
  say 'SQLEXEC:  db2sub.....' db2sub
say 'SQLEXEC:  c1prgrp....' c1prgrp
say 'SQLEXEC:'

/* For processor group SQL get the db2sub by reading the JCL */
/* and getting the SCHENV which should match.                */
if left(c1prgrp,3) = 'SQL' then do
  /* Get the SCHENV by running SDSF to get the JCL */
  sdsf.1 = "SET DISPLAY ON"               /* for debugging */
  sdsf.2 = "PRE" MVSVAR('SYMDEF',JOBNAME)
  sdsf.3 = "DA"
  sdsf.4 = "SYSNAME *"
  sdsf.5 = "FIND "MVSVAR('SYMDEF',JOBNAME)
  sdsf.6 = "++?"
  sdsf.7 = "FIND JESJCL"
  sdsf.8 = "++S"
  sdsf.9 = "PRINT FILE JCLOUT"
  sdsf.10= "PRINT"
  sdsf.11= "PRINT CLOSE"
  "alloc f(ISFIN) new space(2 2) cylinders recfm(f b) lrecl(80)"
  "execio 11 diskw ISFIN (stem sdsf. finis"
  "alloc f(JCLOUT) new space(2 2) cylinders recfm(f b) lrecl(132)"
  "CALL *(ISFAFD)"            /* Call SDSF */
  say 'SQLEXEC:  SDSF RC='rc  /* not much chance of this failing */
  say 'SQLEXEC:'
  /* Read the JCL */
  "EXECIO * DISKR JCLOUT (STEM line. FINIS"
  "free f(JCLOUT ISFIN)"
  /* Ok, did they set a SCHENV on the jobcard? */
  schenv = ''
  line1 = substr(line.1,11)
  /* This searches the first line i.e. //<jobname> JOB .... */
  line1 = strip_quote(line1)  /* get rid of accounting info */
  line1 = strip_quote(line1)  /* get rid of programmer name */
  word3 = word(line1,3)
  x = pos(',SCHENV=',word3)
  if x > 0 then
    schenv = substr(word3,x+8,4)
  else
    do i = 2 to 4      /* Just read the next 3 lines */
      line.i = substr(line.i,11)
      line.i = strip_quote(line.i)  /* get rid of programmer name */
      word2  = word(line.i,2)
      /* This searches the second & subsequent lines */
      x = pos('SCHENV=',word2)
      if left(line.i,3) = '// ' & ,
         x              > 0     then do
        schenv = substr(word2,x+7,4)
        leave
      end
    end /* do i = 1 to 4 */
  if schenv = '' then do
    say 'SQLEXEC:  No SCHENV specified on the jobcard.'
    say 'SQLEXEC:  You must specify a SCHENV for processor group SQL.'
    say 'SQLEXEC:  I.e. For DPA0 specify SCHENV=DOA0'
    say 'SQLEXEC:       For DPE0 specify SCHENV=DOE0 etc.'
    exit 8
  end
  if left(schenv,2) ^= 'DO' then do
    say 'SQLEXEC:  The SCHENV specified on the jobcard must be DO%0.'
    say 'SQLEXEC:  I.e. For DPA0 specify SCHENV=DOA0'
    say 'SQLEXEC:       For DPE0 specify SCHENV=DOE0 etc.'
    exit 8
  end
  say 'SQLEXEC:  The SCHENV from the jobcard is' schenv
  say 'SQLEXEC:'
  db2sub = schenv
end /* c1prgrp = 'SQL' */

/* Get the userid from storage                     */
ascb      = c2x(storage(224,4))
asxb      = c2x(storage(d2x(x2d(ascb)+108),4))
asxbuser  = storage(d2x(x2d(asxb)+192),8)

/* Switch to alternate userid (ENDEVOR)             */
address tso
'alloc f(lgnt$$$i) dummy'
'alloc f(lgnt$$$o) dummy'
'execio * diskr LGNT$$$I (finis'
asxbuser  = storage(d2x(x2d(asxb)+192),8)
say 'SQLEXEC:  User' asxbuser
say 'SQLEXEC:'

/* Execute SQL */
/* The SQL is allocated to SYSIN in the processor */

queue "RUN PROGRAM(DSNTEP2) PLAN(DSNTEP2)
       LIBRARY('SYSDB2."db2sub".RUNLIB.LOAD')"
queue 'END'

'DSN SYSTEM('db2sub')'
sqlrc = rc
say 'SQLEXEC:  SQL return code =' sqlrc
say 'SQLEXEC:'

/* Switch back to the original user id              */
address tso
'execio * diskr LGNT$$$O (finis'
'free f(LGNT$$$I)'
'free f(LGNT$$$O)'
asxbuser = storage(d2x(x2d(asxb)+192),8)
say 'SQLEXEC:  User' asxbuser
say 'SQLEXEC: ' DATE() TIME()

exit sqlrc

/*------------------ S U B R O U T I N E S ------------------*/

/*-----------------------------------*/
/* Strip out text between quotes     */
/*-----------------------------------*/
strip_quote:
 arg line

 quote1 = pos("'",line)
 if quote1 > 0 then do
   quote2 = pos("'",line,quote1+1)
   line = left(line,quote1-1) || substr(line,quote2+1)
 end

return line
