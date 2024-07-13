/*REXX*****************************************************************/
/*  Rexx Name:     EVRPLEX1                                           */
/*  Description:   When the Rplex is used for Proving we need to      */
/*                 ensure that the Infoman local status is updated.   */
/*                 The Rplex is SNA isolated so the normal MSF style  */
/*                 of communication is not possible. By using the     */
/*                 RUN TASK command to submit a job to the Qplex it   */
/*                 is possible to update Infoman.                     */
/**********************************************************************/
trace o
parse arg type

/* The type parm passed will be the cjob or bjob jobname, by looking  */
/* at the first character we can determine whether to update Infoman  */
/* with IMPL or IMPLFAIL                                              */

  if substr(type,1,1) = 'C' then jobname = 'EVL6004D'
                            else jobname = 'EVL6005D'

  if substr(type,1,1) = 'C' then status = 'IMPL'
                            else status = 'IMPLFAIL'

  cmr = 'C'||substr(type,2,7)

say 'EVRPLEX1: Submit 'jobname' to Tplex to run and update'
say 'EVRPLEX1: Infoman with the status of 'status' for change 'cmr
say 'EVRPLEX1:'
say 'EVRPLEX1: Check JMR on the Tplex to confirm run was okay'

LINE.0  = 5
LINE.1  = cmr' PROCESS SNODE=CD.OS390.Q102'
LINE.2  = 'CMRUPDTE RUN TASK (PGM=DMRTSUB, -'
LINE.3  = '     PARM=("DSN=PGEV.BASE.JCL('jobname'),DISP=SHR", -'
LINE.4  = '                     "CMR      'cmr'", - '
LINE.5  = '                     )) SNODE'

"execio * diskw process ( stem line. finis"

exit
