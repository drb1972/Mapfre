/*+---REXX----------------------------------------------------------+*/
/*| rexx to scan output from batch terminal to ensure that          |*/
/*| ADD, DEMAND and ADDRQ commands have been processed sucesfully   |*/
/*| (also checks for DEPJOB= as an implicit ADDRQ on other commands |*/
/*+-----------------------------------------------------------------+*/
trace n

/* the parm passed is the CA7 that the output came from              */
parse arg locn

/* if locn is not coded then assume P04                              */
if locn = '' then locn = 'P04'

"EXECIO * DISKR CA7IN (STEM IN. FINIS)"
if rc ^= 0 then call exception rc 'DISKR of DDname CA7IN failed'

/* Zero the count fileds */

add      = 0
addrq    = 0
demand   = 0
purge    = 0
cancel   = 0
addok    = 0
addrqok  = 0
demandok = 0
purgeok  = 0
cancelok = 0
flag     = 0
bjob     = 0
cjob     = 0
mjob     = 0

/* Process all records in the input file                             */
do i=1 to IN.0

  /* break the input up in to testable variables                     */
  PARSE VAR IN.i part1 part2 part3 part4 rest

  /* Cater for 'insert' records                                      */
  if part1 = 'INSERT' then do while part1 ^= '$IEND'
    i = i + 1
    PARSE VAR IN.i part1 part2 part3 part4 rest
  end /* if part1 = 'INSERT' then do while part1 ^= '$IEND'          */

  PARSE VAR IN.i string

  /* flag = 0 - looking for start of commands                        */
  /* flag = 1 - processing input commands                            */
  /* flag = 2 - processing CA7 output                                */

  if flag = 1 then do

    select /* What CA7 command are being processed?                  */
      when left(part1,4) = 'ADD,'   then add    = add    + 1
      when left(part1,6) = 'DEMAND' then demand = demand + 1
      when left(part1,5) = 'PURGE'  then purge  = purge  + 1
      when left(part1,6) = 'CANCEL' then cancel = cancel + 1
      otherwise nop
    end /* end select                                                */

    select /* Is there a specific job we need to be watching         */
      when left(part1,6) = 'ADD,B0' then bjob = bjob + 1
      when left(part1,6) = 'ADD,C0' then cjob = cjob + 1
      when left(part1,6) = 'ADD,M0' then mjob = mjob + 1
      otherwise nop
    end /* end select                                                */

    /* Check for ADDRQ command, or "DEPJOB" phrase on other commands */
    if left(part1,6) = 'ADDRQ,' then addrq = addrq + 1
    else if index(IN.i,'DEPJOB=') ^= 0 then addrq  = addrq + 1

    /* Check for end of input commands                               */
    if part1 = '/LOGOFF' then flag = 2

  end /* if flag = 1 then do                                         */

  if flag = 0 then if part1 = '/LOGON' then flag = 1

  if flag = 2 then do /* check error messages                        */

    if part1 = 'SM20-00' & ,
       part2 = 'ADD'     & ,
       left(part3,10) = 'SUCCESSFUL' then addok = addok + 1

    if part1 = 'SM20-07' & ,
       part2 = 'JOB'     & ,
       mjob > 0 then addok = addok + 1

    if part1 = 'SM20-07' & ,
       part2 = 'JOB'     & ,
       locn  = 'FROW'    & ,
       cjob > 0 then addok = addok + 1

    if part1 = 'SM20-07' & ,
       part2 = 'JOB'     & ,
       locn  = 'FROW'    & ,
       bjob > 0 then addok = addok + 1

    if part1 = 'SPO4-00' & ,
       part2 = 'ADDRQ'   & ,
       left(part3,10) = 'SUCCESSFUL' then addrqok = addrqok + 1

    if part1 = 'SPO7-00' then demandok = demandok + 1

    if part1 = 'SM20-00' & ,
       part2 = 'DELETE'  & ,
       purge > 0         & ,
       left(part3,10) = 'SUCCESSFUL' then purgeok = purgeok + 1

    if part1 = 'SM50-00' & ,
       part2 = 'DELETE'  & ,
       purge > 0         & ,
       left(part4,10) = 'SUCCESSFUL' then purgeok = purgeok + 1

    if part1 = 'SPO6-00' & ,
       part2 = 'JOB'     & ,
       pos('HAS BEEN CANCELED.',string) > 0 then cancelok = cancelok +  1

  end /* if flag = 2 then do                                         */

  /* queue the input line for later processing                       */
  queue IN.i

end /* do i=1 to IN.0                                                */

/* write the CA7 output to display all text that was processed       */
"EXECIO "QUEUED()" DISKW CA7OUT  (FINIS)"
if rc ^= 0 then call exception rc 'DISKW of DDname CA7OUT failed'

/* If number of commands match the number of confirmation records,   */
/* and we were had found the /LOGOFF statement then it's all okay.   */
say 'add      =' add    ; say 'addok    =' addok
say 'addrq    =' addrq  ; say 'addrqok  =' addrqok
say 'demand   =' demand ; say 'demandok =' demandok
say 'purge    =' purge  ; say 'purgeok  =' purgeok
say 'cancel   =' cancel ; say 'cancelok =' cancelok
say 'bjob     =' bjob   ; say 'cjob     =' cjob
say 'mjob     =' mjob

if add    = addok    & ,
   addrq  = addrqok  & ,
   demand = demandok & ,
   purge  = purgeok  & ,
   cancel = cancelok & ,
   flag   = 2 then exit 0
else exit 8

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack */
 do i = 1 to queued()
   pull
 end

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
