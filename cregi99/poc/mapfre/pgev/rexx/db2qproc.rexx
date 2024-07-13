/*-----------------------------REXX----------------------------------*\
 *   Process DB2PROC calls for binds or stored procedures to         *
 *   bind/create back normally from stage P.                         *
 *                                                                   *
 *   Sample JCL is in NDVEDIT                                        *
 *                                                                   *
 *   Receives element, subsystem, environment, request type, system  *
 *   and target DB2 subsystem.                                       *
 *                                                                   *
 *   Currently request types can be 'BIND', 'BINDBACK', 'CREATE'     *
 *   or 'CREATEBACK'.                                                *
 *                                                                   *
 *   Currently Environment can be 'UNIT', 'SYST' or 'ACPT'.          *
 *                                                                   *
 *   Subsytem must be 3 characters in length                         *
 *                                                                   *
 *   Calls made to DB2PROC for 'BIND' and 'BINDBACK'                 *
 *                                                                   *
 *   Calls made to DB2SPCR for 'CREATE' and 'CREATEBACK'             *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

parse upper arg element subsystem environment runtype no_of_subsys

say rexxname':' Date() Time()
say rexxname':'
say rexxname': element.........:' element
say rexxname': subsystem.......:' subsystem
say rexxname': environment.....:' environment
say rexxname': runtype.........:' runtype
say rexxname': no_of_subsys....:' no_of_subsys
say rexxname':'

false = 0
true  = 1

call validate_input

if no_of_subsys = 'ALL' then call calculate_subsys
                        else subsys_list = subsystem

do j = 1 to words(subsys_list)
  call process_envs word(subsys_list,j)
end /* j = 1 to words(subsys_list) */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* validate_input - check input is valid and set up data if it is    */
/*-------------------------------------------------------------------*/
validate_input:
 select
   when environment = 'PROD' then back_env = 'ACPT SYST UNIT'
   when environment = 'ACPT' then back_env = 'ACPT SYST UNIT'
   when environment = 'SYST' then back_env = 'SYST UNIT'
   when environment = 'UNIT' then back_env = 'UNIT'
   otherwise
     call exception 12 'Input environment invalid:' environment
 end /* select */

 /* set up common data for calls to get processor group info         */
 c1sy    = left(subsystem,2)

 if environment = 'ACPT' & no_of_subsys = 'ALL' then do
   c1env     = 'PROD' /* NDVEDIT currently sets environment to ACPT  */
   search_su = c1sy'1'
 end /* environment = 'ACPT' & no_of_subsys = 'ALL' */
 else do
   c1env     = environment
   search_su = subsystem
 end /* else */

 select
   when c1env = 'PROD' then search_stage = 'P'
   when c1env = 'ACPT' then search_stage = 'E'
   when c1env = 'SYST' then search_stage = 'C'
   when c1env = 'UNIT' then search_stage = 'A'
 end /* select */

 /* validate runtype and determine process_type                      */
 select
   when left(runtype,4) = 'BIND' then do
     process_type = 'DBRMLIB'
     call get_proc_grp_info 'BIND'
     if ^element_found then do
       say rexxname': *** No BIND element found, checking type DBRM'
       call get_proc_grp_info 'DBRM'
       if ^element_found then
         call exception 12 '*** No BIND or DBRM element found for',
                     element 'in' search_su 'at' c1env
       else
         say rexxname': *** DBRM type element found'
     end /* ^element_found */
   end /* left(runtype,4) = 'BIND' */
   when left(runtype,6) = 'CREATE' then do
     process_type = 'SQLP'
     call get_proc_grp_info process_type
     if element_found then do
       srce = "'PREV."c1stage || c1su"."process_type"("element")'"
       say rexxname': Using' process_type 'member from' srce
     end /* element found */
     else do
       say rexxname': *** No' process_type 'element found',
       'checking type SPDEF'
       process_type = 'SPDEF'
       call get_proc_grp_info process_type
       if element_found then do
         say rexxname': *** SPDEF type element found'
         srce = "'PREV."c1stage || c1su"."process_type"("element")'"
         say rexxname': Using' process_type 'member from' srce
       end /* element found */
       else call exception 12 '*** No SQLP or SPDEF element',
                     'found for' element 'in' search_su 'at' c1env
     end /* else */
   end /* left(runtype,6) = 'CREATE' */
   otherwise call exception 12 ' Input runtype invalid:' runtype
 end /* select */

return /* validate_input: */

/*-------------------------------------------------------------------*/
/* calculate_subsys - build list of all subsystems for the system    */
/*-------------------------------------------------------------------*/
calculate_subsys:

 char_list   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
 subsys_list = ''
 do k = 1 to length(char_list)
   trial_subsys = left(subsystem,2) || substr(char_list,k,1)
   dsn  = 'PREV.A'trial_subsys'.'process_type
   if sysdsn("'"dsn"'") ^= 'DATASET NOT FOUND' then
     subsys_list = subsys_list trial_subsys
 end /* k = 1 to length(char_list) */

return /* calculate_subsys: */

/*-------------------------------------------------------------------*/
/* Process_envs - Work out 'back-environments' and process           */
/* Note, we attempt binds at all environments, whether or not a      */
/* DRBMLIB member exists, because package versioning is switched on  */
/* and so no harm is done (and maybe some good)                      */
/* Stored procedures on the other hand are not versioned and so only */
/* one version of a stored procedure is allowed at any one time.     */
/* Processing therefore stops once another stored procedure element  */
/* is encountered.                                                   */
/*-------------------------------------------------------------------*/
process_envs:
parse arg curr_subsys /* current subsystem to be processed           */

 if process_type = 'DBRMLIB' then do
   c1su     = curr_subsys
   c1ty     = 'BIND'
   procgrp  = processor_grp
   tidyplan = 'N'
   tidypack = 'N'
   location = 'LOCAL'
   do i = 1 to words(back_env)
     c1en = word(back_env,i)
     call exec_bind_process

   end /* i = 1 to words(back_env) */
 end /* process_type = 'DBRMLIB' */
 else do
   c1su     = curr_subsys
   c1ty     = process_type
   c1si     = 'NotApp'
   procgrp  = processor_grp

   end_of_back_processing = false

   do i = 1 to words(back_env) until end_of_back_processing
     c1en = word(back_env,i)
     select
       when c1en = 'ACPT' then do
         stage_2 = 'F'
         stage_1 = 'E'
       end /* c1en = 'ACPT' */
       when c1en = 'SYST' then do
         stage_2 = 'D'
         stage_1 = 'C'
       end /* c1en = 'SYST' */
       when c1en = 'UNIT' then do
         stage_2 = 'B'
         stage_1 = 'A'
       end /* c1en = 'UNIT' */
     end /* select */
     x = sysdsn("'PREV."stage_2 || c1su"."c1ty"("element")'")
     if x ^= 'OK' | c1en = c1env then do
       x = sysdsn("'PREV."stage_1 || c1su"."c1ty"("element")'")
       if x ^= 'OK' then call exec_sp_process
     end /* x ^= 'OK' */
     else do
       say rexxname':' c1ty 'member found at' stage_2 'for subsystem',
                   c1su 'stopping back process'
       end_of_back_processing = true
     end /* else */
   end /* until end_of_back_processing | i > words(back_env) */
 end /* else */

return /* process_envs: */

/*-------------------------------------------------------------------*/
/* Exec_bind_process - call utility to do bind(s) for an environment */
/*-------------------------------------------------------------------*/
exec_bind_process:
 x = db2proc(c1su element element c1en c1ty procgrp tidyplan tidypack ,
             runtype location)

 say rexxname':'
 say rexxname': RC from DB2PROC call for' element 'in' ,
     c1en c1su 'is -' x
 say rexxname':'

return /* exec_bind_process: */

/*-------------------------------------------------------------------*/
/* Exec_sp_process - call utility to create stored procedure(s) for  */
/* an environment                                                    */
/*-------------------------------------------------------------------*/
exec_sp_process:
 "alloc f(SOURCE) da("srce") shr reu"
 say ' '
 x = db2spcr(c1su element c1ty c1en c1si procgrp runtype)
 "free f(SOURCE)"

 say ''
 say rexxname': RC from DB2SPCR call for' element 'in' ,
      c1en c1su 'is -' x
 say ''

return /* exec_sp_process: */

/*-------------------------------------------------------------------*/
/* get_proc_grp_info - Execute the CSV report                        */
/*-------------------------------------------------------------------*/
get_proc_grp_info:
 arg elt_type

 inp.1 = '  LIST ELEMENT' element
 inp.2 = '    FROM ENV' c1env
 inp.3 = '         SYS' c1sy
 inp.4 = '         SUB' search_su
 inp.5 = '         TYP' elt_type
 inp.6 = '         STA' search_stage
 inp.7 = '    OPTIONS SEARCH NOCSV'
 inp.8 = '  .'
 inp.0 = 8
 call csv_rpt

 if csv.0 = 0 then
   element_found = false
 else do
   element_found = true
   processor_grp = substr(word(csv.1,7),7,8)
   c1stage       = left(word(csv.1,7),1)
   c1su          = word(csv.1,3)
 end /* else */

return /* get_proc_grp_info: */

/*-------------------------------------------------------------------*/
/* CSV_RPT - Execute the CSV report.                                 */
/*-------------------------------------------------------------------*/
csv_rpt:

 address tso
 /* Free incase there are hangovers. Do not code an exception call   */
 test = msg(off)
 "free f(bsterr c1msgsa csvmsgs1 apiextr csvipt01)"
 test = msg(on)

 "alloc f(csvipt01) new space(1 1) tracks recfm(f b) lrecl(80)"
 if rc ^= 0 then call exception rc 'ALLOC of CSVIPT01 failed.'

 /* Write the input for the CSV utility                              */
 'execio' inp.0 'diskw csvipt01 (stem inp. finis)'
 if rc ^= 0 then call exception rc 'DISKW to CSVIPT01 failed.'

 /* Allocate files to process SCL                                    */
 "alloc f(apiextr) new space(1 1) tracks recfm(f b) lrecl(1600)"
 if rc ^= 0 then call exception rc 'ALLOC of APIEXTR failed.'

 /* Allocate the necessary datasets                                  */
 test = msg(off)
 "alloc F(C1MSGSA)  new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of C1MSGSA failed.'
 "alloc f(CSVMSGS1) new space(1 1) tracks recfm(f b a) lrecl(134)"
 if rc ^= 0 then call exception rc 'ALLOC of CSVMSGS1 failed.'
 "ALLOC F(BSTERR) SYSOUT(a)"
 if rc ^= 0 then call exception rc 'ALLOC of BSTERR failed.'
 test = msg(on)

 /* Invoke the CSV utility                                           */
 if environ = 'FORE' then
   address "LINKMVS" 'BC1PCSV0'
 else
   "CALL   *(NDVRC1) 'BC1PCSV0'"
 lnk_rc = rc

 if lnk_rc > 0 then do
   say rexxname':CSV processing got a return code of' lnk_rc
   say rexxname':CSVMSGS1 and CSVMSGSA output follow'
   /* exception processing, so no further exception checking         */
   "execio * diskr CSVMSGS1 (stem c1. finis"
   do i = 1 to c1.0
     say '  >>' strip(c1.i,'T')
   end /* i = 1 to c1.0 */
   "execio * diskr C1MSGSA  (stem c1. finis"
   do i = 1 to c1.0
     say '  >>>' strip(c1.i,'T')
   end /* i = 1 to c1.0 */
   if lnk_rc > 8 then
     call exception lnk_rc 'Call to BC1PCSV0 failed'
 end /* rc > 0 */

 "free f(bsterr c1msgsa csvmsgs1 csvipt01)"

 csv.0 = 0
 g = listdsi(APIEXTR file) /* Check for output                       */
 if g = 0 then do
   "execio * diskr APIEXTR (stem csv. finis"
   if rc ^= 0 then call exception rc 'DISKR of APIEXTR failed.'
   "free f(apiextr)"
 end /* g = 0 */

return /* csv_rpt: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT non ISPF            */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg('off')
 "free f(MSGDEL MSGB MSGMAST)"
 address tso 'delstack' /* Clear down the stack                      */
 z = msg('on')

 if return_code < 12 | return_code > 4095 then return_code = 12

exit return_code
