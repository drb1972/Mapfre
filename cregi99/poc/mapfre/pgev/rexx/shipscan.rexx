/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 * This Rexx is used by the Endevor archiving process and is         *
 * run during the R job execution to scan the shipment detail        *
 * report to search for members deleted from LOAD, CICS or           *
 * OBJECT libraries. If any are found then a job is created to       *
 * copy the members from the backout datasets into the ARCH          *
 * datasets. This is an alternative to using a MOVE processor.       *
 *                                                                   *
 * INPUT PARMs                                                       *
 *    EVHLQ   : Endevor high level qualifier                         *
 *                                                                   *
 * INPUT DDNAMEs                                                     *
 *    REPIN   : Package Shipment Detail Report (C1BMXDEL)            *
 *                                                                   *
 * OUTPUT DDNAMEs                                                    *
 *    COPYJCL : Batch Job to Copy deleted members to the ARCH        *
 *              environment libraries.                               *
 *                                                                   *
\*-------------------------------------------------------------------*/
trace n
parse arg evhlq ccid

Parse Source . . Me .
uid = sysvar('sysuid')
if sysdsn("'TTEV."uid".ENDEVOR.TRACES("me")'") = 'OK' then
   trace IR
if sysdsn("'TTEV."uid".ENDEVOR.TRACES($ALL)'") = 'OK' then
   trace IR

say 'SHIPSCAN: --------------------------------------------'
say 'SHIPSCAN: Analysis of Shipment Detail Report started'
say 'SHIPSCAN: --------------------------------------------'
call extract_data_from_report
say 'SHIPSCAN:'
say 'SHIPSCAN: --------------------------------------------'
say 'SHIPSCAN: Selecting eligible datasets and creating JCL'
say 'SHIPSCAN: --------------------------------------------'

call create_main_jcl
call create_copy_dds_and_stmts

if exitrc = 0 then do
  "execio" jclcnt "diskw JCLOUT (finis stem jcl.)"
  if rc ^= 0 then call exception rc 'DISKW to JCLOUT failed.'
end /* exitrc = 0 */

exit exitrc

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* Read the shipment detail report and extract the info from the     */
/* relevant lines. Save the info for later.                          */
/*-------------------------------------------------------------------*/
Extract_data_from_report:

 "execio * diskr repin (stem rep. finis"
 if rc ^= 0 then call exception rc 'DISKR of REPIN failed.'

 exitrc = 4 /* Set default rc=4 in case no deletes are found.        */

 /* Initialise variables to track the dataset names and how many     */
 dsn_count = 0
 dsn_list. = ''
 cur_dsn   = ''
 comp_dsn  = ''

 do c = 1 to rep.0
   Select
     /* If its the SHIPMENT line, if target is Qplex set current     */
     /* dataset name.  If 1st time for this dsn set dsn member list  */
     /* to null, set dsn member count to 0, incr dset count and save */
     /* the dataset name. If not Qplex then reset the variables.     */
     when left(strip(rep.c),24) = 'SHIPMENT OF MODULES FROM' then do
       if word(rep.c,7) = 'PLEXE1' then do
         cur_dsn     = word(rep.c,5)
         cur_dsn_var = translate(cur_dsn,'_','.')
         comp_dsn    = ''
         if datatype(value(cur_dsn_var'.0')) = 'CHAR' then do
           say 'SHIPSCAN: Dataset                      :' cur_dsn
           x = value(cur_dsn_var,'')
           x = value(cur_dsn_var'.','')
           x = value(cur_dsn_var'.0',0)
           dsn_count          = dsn_count + 1
           dsn_list.dsn_count = cur_dsn
         end /* datatype(value(cur_dsn_var'.0')) = 'CHAR' */
       end /* word(rep.c,7) = 'PLEXE1' */
       else do
         comp_dsn    = ''
         cur_dsn     = ''
         cur_dsn_var = ''
       end /* else */
     end /* left(strip(rep.c),24) = 'SHIPMENT OF MODULES FROM' */

     /* If it is a DELETE statement and we are still in the shipment */
     /* section. If this member not already in the list then save the*/
     /* member name under dsn and increment dsn member count.        */
     when word(rep.c,1) = 'DELETE' & cur_dsn ^= '' then do
       mem  = word(rep.c,2)
       mpos = wordpos(mem,value(cur_dsn_var))
       if mpos = 0 then do
         say 'SHIPSCAN:   Member                     :' mem
         x = value(cur_dsn_var,value(cur_dsn_var) mem)
         x = value(cur_dsn_var'.0',value(cur_dsn_var'.0') + 1)
       end /* mpos = 0 */
     end /* word(rep.c,1) = 'DELETE' & cur_dsn ^= '' */

     /* If it is the COMPLEMENTARY dataset line and the target is the*/
     /* Qplex then reset current dsn save compl dsn.                 */
     when left(strip(rep.c),22) = 'COMPLEMENTARY FILE FOR' &,
          word(rep.c,6)         = 'PLEXE1'                 then do
       cur_dsn      = ''
       comp_dsn     = word(rep.c,4)
       comp_dsn_var = translate(comp_dsn,'_','.')
     end

     /* If it is the Host Staging dataset line & the staging dataset */
     /* name is not hex 0's and complementary dataset name var is not*/
     /* then save the backout dataset name under the compl dsn var   */
     when left(strip(rep.c),17)      = 'HOST STAGING DSN:' &,
          substr(strip(rep.c),20,1) ^= x2c(00)             &,
          comp_dsn                  ^= ''                  then do
       comp_dsn = ''
       bout_dsn = word(rep.c,4)
       say 'SHIPSCAN:   Backout staging ds         : 'bout_dsn
       x = value(comp_dsn_var'.backout',bout_dsn)
     end /* left(strip(rep.c),17) = 'HOST STAGING DSN:' & .... */

     otherwise nop /* Otherwise ignore the record                    */
   end /* select */
end /* c = 1 to rep.0 */

drop rep.

return /* Extract_data_from_report */

/*-------------------------------------------------------------------*/
/* Put the main JCL for the copies into the stem vars.               */
/*-------------------------------------------------------------------*/
Create_main_JCL:

 jcl.1  = "//*--------------------------------------------------      "
 jcl.2  = "//*                                                        "
 jcl.3  = "//* STEP PRODUCED BY SHIPSCAN REXX IN JOB R"right(CCID,7)
 jcl.4  = "//*                                                        "
 jcl.5  = "//* ENDEVOR PRODUCTION RELEASE: ENDEVOR ARCHIVE JOB        "
 jcl.6  = "//*                                                        "
 jcl.7  = "//* CHANGE:"ccid
 jcl.8  = "//*                                                        "
 jcl.9  = "//*--------------------------------------------------      "
 jcl.10 = "//IEBCOPY  EXEC PGM=IEBCOPY                                "
 jcl.11 = "//SYSPRINT DD  SYSOUT=*                                    "
 jclcnt = 11

return /* Create_main_JCL */

/*-------------------------------------------------------------------*/
/* Create the rest of the DD cards for the in and out datasets and   */
/* create the copy statements.                                       */
/*-------------------------------------------------------------------*/
Create_copy_dds_and_stmts:

 cccnt = 0
 ddcnt = 0
 cc.   = ''
 dd.   = ''
 do c = 1 to dsn_count
   tempdsn = dsn_list.c
   tempdsv = translate(dsn_list.c,'_','.')

   /* If next dataset in list has a backout dataset and if the       */
   /* dataset is LOAD, CICS, OBJECT or DBRMLIB then build JCL.       */
   if value(tempdsv'.backout') = '' then iterate
   parse var tempdsn with pfx '.' mid '.' sfx '.' empty_I_hope
   if wordpos(sfx,'CICS LOAD OBJECT DBRMLIB') = 0 then iterate
   newdsn = overlay('Z',tempdsn,6)

   /* Create the DD cards                                            */
   ddcnt  = ddcnt + 1
   jclcnt = jclcnt + 1
   dd     = left('//DDIN'ddcnt,11)
   jcl.jclcnt = dd'DD  DSN='value(tempdsv'.backout') || ',DISP=SHR'
   say 'SHIPSCAN: '
   say 'SHIPSCAN: Dataset selected for copying:' newdsn
   say 'SHIPSCAN: from backout dataset        :' value(tempdsv'.backout')
   say 'SHIPSCAN: Number of members to copy   :' value(tempdsv'.0')
   call check_allocation_for_newdsn

   /* Create the control cards                                       */
   memcnt   = value(tempdsv'.0')
   memlst   = value(tempdsv)
   cccnt    = cccnt + 1
   cc.cccnt = ' COPY I=((DDIN'ddcnt',R)),O=DDOUT'ddcnt
   do memnum = 1 to memcnt
     cccnt = cccnt + 1
     cc.cccnt = ' S M='word(value(tempdsv),memnum)
   end /* memnum = 1 to memcnt */

 end /* c = 1 to dsn_count */

 /* Add the SYSIN dd card and then insert the control cards          */
 if cccnt > 0 then do
   exitrc     = 0
   jclcnt     = jclcnt + 1
   jcl.jclcnt = '//SYSIN   DD *'
   do c = 1 to cccnt
     jclcnt     = jclcnt + 1
     jcl.jclcnt = cc.c
   end /* c = 1 to cccnt */
   call Add_SPWARN_steps
 end /* cccnt > 0 */

return /* Create_copy_dds_and_stmts */

/*-------------------------------------------------------------------*/
/* Add the step to check the condition code and abend if there were  */
/* any problems.                                                     */
/*-------------------------------------------------------------------*/
Add_SPWARN_steps:

 jclcnt     = jclcnt + 1
 jcl.jclcnt = '//*                                    '
 jclcnt     = jclcnt + 1
 jcl.jclcnt = '//CHECKIT  IF IEBCOPY.RC GT 0 THEN     '
 jclcnt     = jclcnt + 1
 jcl.jclcnt = '//@SPWARN  EXEC @SPWARN                '
 jclcnt     = jclcnt + 1
 jcl.jclcnt = '//CHECKIT  ENDIF                       '
 jclcnt     = jclcnt + 1
 jcl.jclcnt = '//*                                    '

return /* Add_SPWARN_steps: */

/*-------------------------------------------------------------------*/
/* See if the target dataset already exists and set the disp field   */
/* value. If it does not exist then call routine for space and dcb   */
/* parameters.                                                       */
/*-------------------------------------------------------------------*/
check_allocation_for_newdsn:

 ds_state = sysdsn("'"newdsn"'")
 select
   when ds_state = "OK" then do
     say 'SHIPSCAN: Target dataset' newdsn ' already exists'
     ds_disp    = 'SHR'
     jclcnt     = jclcnt + 1
     dd         = left('//DDOUT'ddcnt,11)
     jcl.jclcnt = dd'DD  DSN='newdsn',DISP='ds_disp
   end /* ds_state = "OK" */
   when ds_state = "DATASET NOT FOUND" then do
     say 'SHIPSCAN: Target dataset' newdsn ' will be created as new'
     ds_disp = '(,CATLG,DELETE),'
     call get_dataset_alloc_values
   end /* ds_state = "DATASET NOT FOUND" */
   otherwise do
     say 'SHIPSCAN: Target dataset' newdsn 'ERROR:' ds_state
     exit 12
   end /* otherwise */
 end /* select */

return /* check_allocation_for_newdsn */

/*-------------------------------------------------------------------*/
/* Look at staging and stage P datasets and calculate the space      */
/* and dcb parameters.                                               */
/*-------------------------------------------------------------------*/
get_dataset_alloc_values:

 skip_rest = 'no'
 bo_ds     = value(tempdsv'.backout')
 bo_state  = listdsi("'"bo_ds"'")
 if rc ^= 0 then do
   say 'SHIPSCAN: Backout dataset' bo_ds 'ERROR:LISTDSI Failed with'
   say 'SHIPSCAN: RC='rc 'Reason Code='sysreason
   say 'SHIPSCAN: SYSMSGLVL1:' SYSMSGLVL1
   say 'SHIPSCAN: SYSMSGLVL2:' SYSMSGLVL2
   exit 12
 end /* rc ^= 0 */
 ds_spacU   = sysunits
 jclcnt     = jclcnt + 1
 dd         = left('//DDOUT'ddcnt,11)
 jcl.jclcnt = dd'DD  DSN='newdsn',DISP='ds_disp
 jclcnt     = jclcnt + 1
 jcl.jclcnt = '//             LRECL='syslrecl',BLKSIZE='sysblksize||,
              ',RECFM='sysrecfm',DSNTYPE=LIBRARY,'
 /* We want to allocate in trks so work out the factor to multiply   */
 /* the current space allocations by to do it.                       */
 select
   when sysunits = 'CYLINDER' then ds_factor = 15
   when sysunits = 'TRACK'    then ds_factor = 1
   when sysunits = 'BLOCK'    then ds_factor = 1/sysblkstrk
   otherwise do
     say 'SHIPSCAN: Backout dataset' bo_ds 'ERROR:',
         'Unable to establish space parameters'
     jclcnt     = jclcnt + 1
     jcl.jclcnt = '//             LIKE='bo_ds
     skip_rest  = 'yes'
   end /* otherwise */
 end /* select */

 /* If we could see the sysunits then allocate the space.            */
 if skip_rest = 'no' then do
   ds_spacep  = (sysprimary + (sysseconds * (sysextents - 1)) + 1) *,
                ds_factor
   ds_spaces  = sysseconds * ds_factor
   jclcnt     = jclcnt + 1
   jcl.jclcnt = '//             SPACE=(TRK,('ds_spacep',' || ,
                ds_spaces',44),RLSE)'
 end /* skip_rest = 'no' */

return /* get_dataset_alloc_values */

/*-------------------------------------------------------------------*/
/* Error with line number displayed                                  */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 address tso 'delstack' /* Clear down the stack                      */

 parse source . . rexxname . /* Get the rexx name(generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
