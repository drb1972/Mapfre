/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* | This Rexx builds VALIDATE cards and email data for            | */
/* | EVHVAL%% jobs that do element validate.                       | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */

jobname = mvsvar('SYMDEF',JOBNAME)
say 'VALIDBLD: Jobname......' jobname

env = substr(jobname,7,1)
sys = substr(jobname,8,1)
if sys = '1' then
  sys = '' /* Do all systems for UTIL & ARCH */

/* Work out the envrionment name from the 7th char of the jobanme */
select
  when env = 'U' then envr = 'UNIT'
  when env = 'S' then envr = 'SYST'
  when env = 'A' then envr = 'ACPT'
  when env = 'P' then envr = 'PROD'
  when env = 'T' then envr = 'UTIL'
  when env = 'Z' then envr = 'ARCH'
  otherwise do
    say 'VALIDBLD: Jobname' jobname ' has an unknown environment'
    say 'VALIDBLD: at postion 7 of the job name'
    exit 12
  end  /* otherwise */
end /* select */
say 'VALIDBLD: Environment..' envr
say 'VALIDBLD: System.......' sys'*'

/* Build & write the validate cards           */
queue " VALIDATE ENV" envr "SYS" sys"* ."
"EXECIO 1 DISKW VALCARD (FINIS"
if rc ^= 0 then call exception 20 'DISKW to VALCARD failed RC='rc

/* Build & write the email header information */
queue " FROM: mapfre.endevor@ibm.com"
queue " TO: VERTIZOS@kyndryl.com"
queue " SUBJECT: EPLEX -" jobname "- Endevor Element Validation Error -" || ,
      " Please check"
"EXECIO 3 DISKW EADDR (FINIS"
if rc ^= 0 then call exception 20 'DISKW to EADDR failed RC='rc

exit

/*---------------------- S U B R O U T I N E S -----------------------*/

/*---------------------------------------------------------------*/
/* Error with line number displayed                              */
/*---------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack */
 do i = 1 to queued()
   pull
 end

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
