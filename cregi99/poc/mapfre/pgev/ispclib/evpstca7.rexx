/*--rexx-------------------------------------------------------------*/
/*  PROGRAM: EVPSTCA7                                                */
/*  DATE: Started 04/07/2006                                         */
/*                                                                   */
/*  This utility uses the following skeletons:-                      */
/*  EVPSTJCL EVPSTCA7 EVPSTEND                                       */
/*                                                                   */
/*  Function: Posts CA7 holds for Endevor Package records            */
/*-------------------------------------------------------------------*/

trace o
x=msg(off)
uid  = sysvar(sysuid)
plex = MVSVAR(sysplex)

/* Check on Q-plex else exit                                         */
if plex ^= 'PLEXQ1' then do
  say "EVPSTCA7: This must only run on Q-plex.....exiting"
  Exit 8
end /* if plex ^= 'PLEXQ1' then do                                   */

Call Defaults


do forever /* display panel EVPSTCA7                                 */

  address ispexec
  Term = 'NO'
  "DISPLAY PANEL(EVPSTCA7)"
  if Term = 'YES' then exit 0

  /* if rc 8 then PF3 was pressed                                    */
  if rc = 8 then exit

  NOSCA7 = 0   /* set ca7 counter to 0                               */

  /* Check each C7P0* value to see how many have been set to Y */
  if C7P02 = 'Y' then NOSCA7 = NOSCA7 + 1

  if C7P03 = 'Y' then NOSCA7 = NOSCA7 + 1

  if C7P04 = 'Y' then NOSCA7 = NOSCA7 + 1

  if C7P05 = 'Y' then NOSCA7 = NOSCA7 + 1

  if C7P06 = 'Y' then NOSCA7 = NOSCA7 + 1

  if C7P07 = 'Y' then NOSCA7 = NOSCA7 + 1

  if C7P08 = 'Y' then NOSCA7 = NOSCA7 + 1

  if C7P09 = 'Y' then NOSCA7 = NOSCA7 + 1

  /* error check that if C7ALL=Y, all the others are =N              */
  if C7ALL = 'Y' & NOSCA7 > 0 then do
    "ADDPOP ROW(3) COLUMN(5)"
    "DISPLAY PANEL(EVPSTC7M)"
    "REMPOP"
    if Term = 'YES' then iterate
  end /* if C7ALL = 'Y' & NOSCA7 > 0 then do                         */

  /* error check that at least one CA7 has been selected             */
  if C7ALL = 'N' & NOSCA7 = 0 then do
    "SETMSG MSG(EVPS007X)"
    iterate
  end /* if C7ALL = 'N' & NOSCA7 = 0 then do                         */

  Call Alloc_ISP

  say "EVPSTCA7: "CMRNO

  Call Build_JCL

  Call Sub_Edit

end /* do forever                                                    */
Exit 0

/*-------------------------------------------------------------------*/
/*                  S U B R O U T I N E S                            */
/*-------------------------------------------------------------------*/

Defaults:
 /* set default values                                               */
 zcmd = ''
 C7ALL = 'Y'
 C7P02 = 'N'
 C7P03 = 'N'
 C7P04 = 'N'
 C7P05 = 'N'
 C7P06 = 'N'
 C7P07 = 'N'
 C7P08 = 'N'
 C7P09 = 'N'
 SUBED = 'S'

return /* defaults:                                                  */

Alloc_ISP:

 hlq = Sysvar(Syspref) /* Get the users default HLQ                  */

 dsname = hlq"."uid".EVPSTCA7" /* ISPFILE dataset name               */

 jobname = hlq||'POST' /* actual jobname                             */

 /* delete Output file if already exists                             */
 ADDRESS TSO
 "DEL '"dsname"'"

 /* allocate ISPFILE                                                 */
 ADDRESS TSO

 "ALLOC DA('"dsname"') NEW CATALOG SPACE(5,5),
 RECFM(F,B) LRECL(80) BLKSIZE(23440) DSORG(PS),
 F(ISPFILE)"
 cc = rc
 if cc > 0 then call exception cc 'Error allocating ISPFILE dsn' dsname

return /* Alloc_ISP:                                                 */

Build_JCL:
 /* start file tailoring                                             */
 ADDRESS ISPEXEC
 FTOPEN

 /* Build the JCL and NDMDATA cards */
 FTINCL  EVPSTJCL /* Job JCL to execute C:D commands                 */

 if C7P02 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'P102'
   CA7 = 'CA7=P02;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P02"
 end /* if C7P02 = 'Y' && C7ALL = 'Y' then do                        */

 if C7P03 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'N102'
   CA7 = 'CA7=P03;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P03"
 end /* if C7P03 = 'Y' && C7ALL = 'Y' then do                        */

 if C7P04 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'Q102'
   CA7 = 'CA7=P04;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P04"
 end /* if C7P04 = 'Y' && C7ALL = 'Y' then do                        */

 if C7P05 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'M102'
   CA7 = 'CA7=P05;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P05"
 end /* if C7P05 = 'Y' && C7ALL = 'Y' then do                        */

 if C7P06 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'E102'
   CA7 = 'CA7=P06;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P06"
 end /* if C7P06 = 'Y' && C7ALL = 'Y' then do                        */

 if C7P07 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'C102'
   CA7 = 'CA7=P07;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P07"
 end /* if C7P07 = 'Y' && C7ALL = 'Y' then do                        */

 if C7P08 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'D102'
   CA7 = 'CA7=P08;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P08"
 end /* if C7P08 = 'Y' && C7ALL = 'Y' then do                        */

 if C7P09 = 'Y' && C7ALL = 'Y' then do
   NODEOUT = 'F102'
   CA7 = 'CA7=P09;'
   FTINCL  EVPSTCA7
   say "EVPSTCA7: Cards Created for CA7P09"
 end /* if C7P09 = 'Y' && C7ALL = 'Y' then do                        */

 FTINCL  EVPSTEND

 FTCLOSE
 ADDRESS TSO
 "FREE F(ISPFILE)"

return /* Build_JCL:                                                 */

Sub_Edit:
 /* Decide whether to submit the job or bring up the JCL in Edit     */
 ADDRESS TSO

 if SUBED = "S" then do /* user has requested to submit the job      */
   "submit '"dsname"'"
   say "EVPSTCA7: Job "jobname" has been submitted, check CD02 for"
   say "successful completion of each runtask"
 end /* if SUBED = "S" then do                                       */

 if SUBED = "E" then do /* user has requested to edit the job        */
   ADDRESS ISPEXEC
   "EDIT DATASET('"dsname"')"
 end /* if SUBED = "E" then do                                       */

return /* Sub_Edit:                                                  */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* Clear down the stack                                             */
 do i = 1 to queued()
   pull
 end /* do i = 1 to queued()                                         */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
