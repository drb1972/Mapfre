/*-----------------------------REXX----------------------------------*\
 *                                                                   *
 * This routine is run by job EVGENFOD to scan Infoman for package   *
 * CMRs that were assigned in advance of the implementation change   *
 * window so it wasn't turned in to an Rjob straight away.           *
 *                                                                   *
 * It creates datasets for a subsequent job to read and create an    *
 * Rjob and schedule it.                                             *
 *                                                                   *
 * Calls       : $DATEINC in PGIB.BASE.CLIST                         *
 *             : $DTECONV in PGIB.BASE.CLIST                         *
 *             :                                                     *
 * Input vars  : session - Used during the Infoman query             *
 *             : class   - Used during the Infoman query             *
 *             : hlq     - Use to create the CMR datasets            *
 *             : user_id - Used during the Infoman query             *
 *             :                                                     *
 * Links       : BLGYRXM which is the Infoman connector program      *
 *             :                                                     *
 * Called by   : EVGENFOD scheduled in CA7P04                        *
 *                                                                   *
\*-------------------------------------------------------------------*/
signal on syntax  name exception /* Required for ISPF batch only     */
signal on failure name exception /* Required for ISPF batch only     */

parse source . . rexxname . . . . addr .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

arg session class hlq user_id

/* initialise variable                                               */
jobs  = 0
count = 0
dsn   = hlq'.NCMR.ASSIGN'

call initialise /* set up variables and establish Infoman connection */

if RC = 0 then call inquiry /* run date based Infoman query          */

if RC = 0 & p > 0 then do /* p = # recs to process                   */

  call retrieve /* Retrieve ENDEVOR system id                        */

  call checkout /* checkout records                                  */

end /* RC = 0 & p > 0 */

else do

  call terminate RC /* close Infoman link and call exception         */

end /* else */

if RC = 0 & m > 0 then call update /* update Infoman status          */

if RC = 0 & k > 0 then call checkin /* execute Infoman checkin       */

if RC = 0 then call write /* create datasets for EVGRJOBD            */

if RC = 0 then call terminate rc /* close down Infoman link          */

exit

/*---------------------- S U B R O U T I N E S ----------------------*/

/*-------------------------------------------------------------------*/
/* This procedure initialises INFO/MGT.                              */
/*-------------------------------------------------------------------*/
initialise:
 i = 0
 m = 0
 k = 0
 l = 0
 say rexxname': '
 say rexxname':' time() 'Package CMR extraction started on' date(w) date()
 session_member            = session
 privilege_class           = class
 application_id            = user_id
 table_count               = 0
 apimsg_option             = 'P'
 hlimsg_option             = 'P'
 spool_interval            = 10
 default_data_storage_size = 0
 default_option            = 'NONE'
 timeout_interval          = 360
 class_count               = 1

 init_control.1   = 'application_id'
 init_control.2   = 'session_member'
 init_control.3   = 'privilege_class'
 init_control.4   = 'table_count'
 init_control.5   = 'apimsg_option'
 init_control.6   = 'hlimsg_option'
 init_control.7   = 'spool_interval'
 init_control.8   = 'default_data_storage_size'
 init_control.9   = 'default_option'
 init_control.10  = 'timeout_interval'
 init_control.11  = 'class_count'
 init_control.0   = 11

 /* get information from Infoman                                     */
 ADDRESS LINK "blgyrxm init,init_control"
 if RC = 0 then say rexxname':' time() 'INFO/MGT initialised OK'
 else do
   cc = rc
   say rexxname':' time() 'Initialisation failed'
   say rexxname':' time() 'RC ............'rc
   say rexxname':' time() 'BLG_RC ........'blg_rc
   say rexxname':' time() 'BLG_REAS ......'blg_reas

   call exception cc 'Investigate failed Infoman search.'
 end /* else */

return /* initialise: */

/*-------------------------------------------------------------------*/
/* This procedure performs the inquiry to get potential change       */
/* records for cat 1, then cat2, and then 3/4.                       */
/*-------------------------------------------------------------------*/
inquiry:

 /* Retrieve listed Bank holiday dates from list processor LIST0011  */
 call bank_holiday_retr

 /* Set search argument for catagory 1 package type changes          */
 call calculate_end_date 8

 parse Value end_date with end_date .
 end_date = $dteconv(end_date) /* $dteconv is in pgib.base.clist     */

 parse value end_date with yy'/'mm'/'dd

 pidt_name         = 'CMSEXTI'
 associated_data   = 'S8A24'
 control.1         = 'pidt_name'
 control.2         = 'associated_data'
 control.0         = 2

 freeform.1.?data  = 'CLSS/D'
 freeform.2.?data  = 'STAC/ASSIGN'
 freeform.3.?data  = 'STAQ/ASSIGN'
 freeform.4.?data  = 'PKST/APPROVED'
 freeform.5.?data  = 'TYPE/PACKAGE'
 freeform.6.?data  = '^PKEX/I'
 freeform.7.?data  = '^PKEX/C'
 freeform.8.?data  = '^PKEX/F'
 freeform.9.?data  = 'IMPR/1'
 freeform.10.?data = 'GROA/O**'
 freeform.11.?data = 'DATD*/2000/01/01'
 freeform.12.?data = '-DATD*/20'end_date
 freeform.0        = 12

 srcharg.1.?name   = 'freeform'
 srcharg.0         = 1

 /* Display search arguments for debugging purposes                  */
 do i = 1 to freeform.0
   if i = 1 then
     say rexxname':' time() 'Search arguments:' freeform.i.?data
   else
     say rexxname':' time() '                 ' freeform.i.?data
 end /* i = 1 to freeform.0 */

 /* Perform Infoman search                                           */
 ADDRESS LINK "BLGYRXM search,control,srcharg,inqres"
 if RC ^= 0 then do
   say rexxname':' time() 'Search failed'
   say rexxname':' time() 'RC ............'rc
   say rexxname':' time() 'BLG_RC ........'blg_rc
   say rexxname':' time() 'BLG_REAS ......'blg_reas
   say rexxname':' time() 'PIDT_NAME .....'pidt_name;

   call exception rc 'Investigate failed Infoman search.'
 end
 else do
   say rexxname':' time() 'Category 1 package CMR search ended okay.'
   say rexxname':' time() inqres.0 'CMRs found.'

   p = 0 /* initialise counter                                       */

   /* copy the results in to a cumulative counter                    */
   do i = 1 to inqres.0
     p = p + 1
     inq_rnid.p  = inqres.i.?rnid
     inq_assoc.p = inqres.i.?assoc
   end /* i = 1 to inqres.0 */

 end /* else */

 /* Set search argument for catagory 2 package type changes          */
 call calculate_end_date 3

 parse Value end_date with end_date .
 end_date = $dteconv(end_date) /* $dteconv is in pgib.base.clist     */

 parse value end_date with yy'/'mm'/'dd

 pidt_name         = 'CMSEXTI'
 associated_data   = 'S8A24'
 control.1         = 'pidt_name'
 control.2         = 'associated_data'
 control.0         = 2

 freeform.1.?data  = 'CLSS/D'
 freeform.2.?data  = 'STAC/ASSIGN'
 freeform.3.?data  = 'STAQ/ASSIGN'
 freeform.4.?data  = 'PKST/APPROVED'
 freeform.5.?data  = 'TYPE/PACKAGE'
 freeform.6.?data  = '^PKEX/I'
 freeform.7.?data  = '^PKEX/C'
 freeform.8.?data  = '^PKEX/F'
 freeform.9.?data  = 'IMPR/2'
 freeform.10.?data = 'GROA/O**'
 freeform.11.?data = 'DATD*/2000/01/01'
 freeform.12.?data = '-DATD*/20'end_date
 freeform.0        = 12

 srcharg.1.?name   = 'freeform'
 srcharg.0         = 1

 /* Display search arguments for debugging purposes                  */
 do i = 1 to freeform.0
   if i = 1 then
     say rexxname':' time() 'Search arguments:' freeform.i.?data
   else
     say rexxname':' time() '                 ' freeform.i.?data
 end /* i = 1 to freeform.0 */

 /* Perform Infoman search                                           */
 ADDRESS LINK "BLGYRXM search,control,srcharg,inqres"
 if RC ^= 0 then do
   say rexxname':' time() 'Search failed'
   say rexxname':' time() 'RC ............'rc
   say rexxname':' time() 'BLG_RC ........'blg_rc
   say rexxname':' time() 'BLG_REAS ......'blg_reas
   say rexxname':' time() 'PIDT_NAME .....'pidt_name;

   call exception rc 'Investigate failed Infoman search.'
 end
 else do
   say rexxname':' time() 'Category 2 package CMR search ended okay.'
   say rexxname':' time() inqres.0 'CMRs found.'

   /* copy the results in to a cumulative counter                    */
   do i = 1 to inqres.0
     p = p + 1
     inq_rnid.p  = inqres.i.?rnid
     inq_assoc.p = inqres.i.?assoc
   end /* i = 1 to inqres.0 */

 end /* else */

 /* Set search argument for catagory 3 & 4                           */
 call calculate_end_date 1

 parse value end_date with end_date .
 end_date = $dteconv(end_date) /* $dteconv is in pgib.base.clist     */

 pidt_name         = 'CMSEXTI'
 associated_data   = 'S8A24'
 control.1         = 'pidt_name'
 control.2         = 'associated_data'
 control.0         = 2

 freeform.1.?data  = 'CLSS/D'
 freeform.2.?data  = 'STAC/ASSIGN'
 freeform.3.?data  = 'STAQ/ASSIGN'
 freeform.4.?data  = 'PKST/APPROVED'
 freeform.5.?data  = 'TYPE/PACKAGE'
 freeform.6.?data  = '^PKEX/I'
 freeform.7.?data  = '^PKEX/C'
 freeform.8.?data  = '^PKEX/F'
 freeform.9.?data  = 'IMPR/3'
 freeform.10.?data = '|IMPR/4'
 freeform.11.?data = 'GROA/O**'
 freeform.12.?data = 'DATD*/2000/01/01'
 freeform.13.?data = '-DATD*/20'end_date
 freeform.0        = 13

 srcharg.1.?name   = 'freeform'
 srcharg.0         = 1

 /* Display search arguments for debugging purposes                  */
 do i = 1 to freeform.0
   if i = 1 then
     say rexxname':' time() 'Search arguments:' freeform.i.?data
   else
     say rexxname':' time() '                 ' freeform.i.?data
 end /* i = 1 To freeform.0 */

 /* Perform Infoman search                                           */
 ADDRESS LINK "BLGYRXM search,control,srcharg,inqres"
 if RC ^= 0 then do
   say rexxname':' time() 'Search failed'
   say rexxname':' time() 'RC ............'rc
   say rexxname':' time() 'BLG_RC ........'blg_rc
   say rexxname':' time() 'BLG_REAS ......'blg_reas
   say rexxname':' time() 'PIDT_NAME .....'pidt_name;

   call exception rc 'Investigate failed Infoman search.'
 end
 else do
   say rexxname':' time() 'Category 3/4 package CMR search ended okay.'
   say rexxname':' time() inqres.0 'CMRs found.'

   /* copy the results in to a cumulative counter                    */
   do i = 1 to inqres.0
     p = p + 1
     inq_rnid.p  = inqres.i.?rnid
     inq_assoc.p = inqres.i.?assoc
   end /* i = 1 to inqres.0 */
 end /* else */

 say rexxname':' time()
 say rexxname':' time() 'Inquiries ended. In total' p 'records found.'

return /* inquiry: */

/*-------------------------------------------------------------------*/
/* This procedure performs the retrieve to get the ENDEVOR system id */
/* for all records being processed                                   */
/*-------------------------------------------------------------------*/
retrieve:
 pidt_name = 'CMSENDR'
 endev_sys = 'S89F5'

 do i = 1 to p /* p is the total number package CMRs found in search */
   rnid_symbol = inq_rnid.i
   ret_con.1   = 'pidt_name'
   ret_con.2   = 'rnid_symbol'
   ret_con.0   = 2

   /* Retrieve ENDEVOR system id                                     */
   ADDRESS LINK "blgyrxm retrieve,ret_con,,ret_out"
   if RC ^= 0 then do
     say rexxname':' time() 'Retrieve failed'
     say rexxname':' time() 'RC ............'rc
     say rexxname':' time() 'BLG_RC ........'blg_rc
     say rexxname':' time() 'BLG_REAS ......'blg_reas
     say rexxname':' time() 'PIDT_NAME .....'pidt_name;

     call exception rc 'Investigate failed Infoman retrieve.'
   end /* RC ^= 0 */

   else write_array.i.?ndvr = ret_out.s89f5 /* save record           */

 end /* i = 1 to p */

return /* retrieve: */

/*-------------------------------------------------------------------*/
/* This procedure checks out records found in the inquiry.           */
/*-------------------------------------------------------------------*/
checkout:
 checkout_control.0 = 1
 checkout_control.1 = 'rnid_symbol'

 m = 0 /* initialise counter                                         */

 do i = 1 to p /* p is the total number package CMRs found in search */

   add_to_array = 'YES'
   rnid_symbol = inq_rnid.i

   /* Checkout each record in Infoman                                */
   ADDRESS LINK "blgyrxm checkout,checkout_control"
   if RC = 0 then
     say rexxname':' time() 'Record' rnid_symbol 'checked out'

   if blg_rc = 12 & blg_reas = 11 then do
     say rexxname':' time() 'CMR' rnid_symbol ,
         'was unavailable & not processed'
     RC = 0
     add_to_array='NO'
   end /* blg_rc = 12 & blg_reas = 11 */

   if BLG_RC = 4 & BLG_REAS = 12 then do
     RC = 0
     say rexxname': 'time() 'CMR' rnid_symbol 'is already checked out'
     add_to_array = 'NO'
   end /* BLG_RC = 4 & BLG_REAS = 12 */

   if RC = 0 & add_to_array = 'YES' then do
     m = m + 1
     update_array.m.?rnid = rnid_symbol
     update_array.m.?assoc = inq_assoc.i
   end /* RC = 0 & add_to_array = 'YES' */

   if RC ^= 0 & add_to_array = 'YES' then do
     say rexxname':' time() 'Checkout failed'
     say rexxname':' time() 'RC ............'rc
     say rexxname':' time() 'BLG_RC ........'blg_rc
     say rexxname':' time() 'BLG_REAS ......'blg_reas
     say rexxname':' time() 'Record ........'rnid_symbol
     say rexxname':' time() 'BLG_VARNAME ...'blg_varname

     call exception rc 'Investigate failed Infoman checkout.'
   end /* RC ^= 0 & add_to_array = 'YES' */

 end /* i = 1 to p */

return /* checkout: */

/*-------------------------------------------------------------------*/
/* This procedure updates change records that were successfully      */
/* checked out in the previous procedure.                            */
/*-------------------------------------------------------------------*/
update:
 pidt_name        = 'CMSEXTU'
 update_control.1 = 'pidt_name'
 update_control.2 = 'rnid_symbol'
 update_control.0 = 2

 k = 0 /* initialise counter                                         */

 do i = 1 to m /* m is the counter set in the check: subroutine      */

   rnid_symbol = update_array.i.?rnid
   exec_status = 'I'
   rjob_status = 'I'
   s8a13       = exec_status
   s8b27       = rjob_status

   update_input.1.?name = 's8a13'
   update_input.2.?name = 's8b27'
   update_input.0       = 2

   /* update record in Infoman                                       */
   ADDRESS LINK "blgyrxm update,update_control,update_input"

   if RC = 0 then do
     say rexxname':' time() 'Record' rnid_symbol 'updated'
     say rexxname': with exec_status as' exec_status
     say rexxname': and  rjob_status as' rjob_status

     k = k + 1

     checkin_array.k.?rnid  = rnid_symbol
     checkin_array.k.?assoc = update_array.i.?assoc

   end /* RC = 0 */

   else do
     say rexxname':' time() 'Update failed'
     say rexxname':' time() 'RC ............'rc
     say rexxname':' time() 'BLG_RC ........'blg_rc
     say rexxname':' time() 'BLG_REAS ......'blg_reas
     say rexxname':' time() 'Record ........'rnid_symbol
     say rexxname':' time() 'BLG_VARNAME ...'blg_varname

     call exception rc 'Investigate failed Infoman update.'
   end /* else do */

 end /* i = 1 to m */

return /* update: */

/*-------------------------------------------------------------------*/
/* This procedure checks in records that were successfully updated   */
/* in the previous procedure.                                        */
/*-------------------------------------------------------------------*/
checkin:
 checkin_control.0 = 1
 checkin_control.1 = 'rnid_symbol'

 l = 0

 do i = 1 to k /* k is the counter set in the update: routine        */
   rnid_symbol = checkin_array.i.?rnid

   /* Checkin each record in Infoman                                 */
   ADDRESS LINK "blgyrxm checkin,checkin_control"
   if RC = 0 then do
     say rexxname':' time() 'Record' rnid_symbol 'checked in'
     l = l + 1
     write_array.l.?rnid = rnid_symbol
     write_array.l.?assoc = checkin_array.i.?assoc
   end /* RC = 0 */

   else do
     say rexxname':' time() 'Checkin failed'
     say rexxname':' time() 'RC ............'rc
     say rexxname':' time() 'BLG_RC ........'blg_rc
     say rexxname':' time() 'BLG_REAS ......'blg_reas
     say rexxname':' time() 'Record ........'rnid_symbol
     say rexxname':' time() 'BLG_VARNAME ...'blg_varname

     call exception rc 'Investigate failed Infoman checkin.'
   end /* else */

 end /* i = 1 to k */

return /* checkin: */

/*-------------------------------------------------------------------*/
/* This procedure writes out data regarding the record and package   */
/* for those records successfully checked in.                        */
/*-------------------------------------------------------------------*/
write:
 notify = ''
 if l > 0 then do i = 1 to l /* l is set in the checkin: routine     */

   /* build the contents for the PGEV.NCMR.ASSIGN dataset            */
   queue write_array.i.?rnid' 'write_array.i.?assoc' ',
         write_array.i.?ndvr' 'CMASSIGN

   /* set up the complete dataset name ready for allocation          */
   cmr_dsn = dsn'.'write_array.i.?rnid

   address tso
   /* Allocate dataset with assignment data ready for EVGRJOBD       */
   "ALLOC F(ASSIGN) DA('"cmr_dsn"') NEW" ,
     "CATALOG SPACE(1  1) TRACKS RECFM(F B) LRECL(80) BLKSIZE(0)"
   if rc ^= 0 then call exception rc 'ALLOC of' cmr_dsn 'failed.'

   "execio" queued() "diskw ASSIGN (finis" /* write queued data      */
   if rc ^= 0 then call exception rc 'DISKW to ASSIGN failed.'

   "FREE FI(ASSIGN)" /* free the dataset after writing the data      */
   if rc ^= 0 then call exception rc 'FREE of ASSIGN DDdname failed.'

   say rexxname':'
   say rexxname': Dataset' cmr_dsn 'has been created & populated.'
   say rexxname':'

 end /* i = 1 to l */

return /* write: */

/*-------------------------------------------------------------------*/
/* Terminate INFO/API REXX interface.                                */
/*-------------------------------------------------------------------*/
terminate:
 arg cc /* store the return code                                     */

 say rexxname':' time() 'Terminating INFO/MGT'
 say rexxname':'

 /* Close down Infoman link                                          */
 ADDRESS LINK "blgyrxm term"
 if cc > 0 then
   call exception cc '!!!! Investigate the failure !!!!'

return /* terminate: */

/*-------------------------------------------------------------------*/
/* Retrieve bank holiday dates from list processor LIST0011.         */
/*-------------------------------------------------------------------*/
bank_holiday_retr:
 Arg end_date
 rnid_symbol     = "LIST0011"
 ret_inp.1.?name = "s8298"
 ret_inp.0       = 1
 pidt_name       = "BHOLSR"
 ret_con.1       = "pidt_name"
 ret_con.2       = "rnid_symbol"
 ret_con.0       = 2

 /* read LIST0011 record for special dates                           */
 ADDRESS LINK "blgyrxm retrieve,ret_con,ret_inp,ret_out"
 if RC > 0 then do
   say rexxname': Retrieve failed'
   say rexxname': RC ..........'rc
   say rexxname': BLG_RC ......'blg_rc
   say rexxname': BLG_REAS ....'blg_reas

   call exception rc 'Investigate failed LIST0011 retrieval.'
 end /* ret_code > 0 */

 tname = ret_out.2.?name
 bank_hols = ret_out.tname

return /* bank_holiday_retr: */

/*-------------------------------------------------------------------*/
/* Calculate end date. Number of days passed to routine as variable  */
/* DAYS.                                                             */
/*-------------------------------------------------------------------*/
calculate_end_date:
 arg days
 end_date = date(e)
 Parse Value end_date With end_date dow

 do j = 1 to days
   end_date = $dateinc(1 end_date) /* $dateinc in pgib.base.clist    */
   parse Value end_date With end_date dow

   do until dow ^= "Sat" & dow ^= "Sun"

     select

       When dow = "Sat" | dow = "Sun" then do
         end_date = $dateinc(1 end_date)
         Parse Value end_date With end_date dow
       end /* dow = "Sat" | dow = "Sun" */

       otherwise Nop

     end /* select */

   end /* until dow ^= "Sat" & dow ^= "Sun" */

   call bank_holiday_check

 end /* j = 1 to days */

return /* calculate_end_date: */

/*-------------------------------------------------------------------*/
/* Check for bank holiday and weekends. If equal to bank holidays,   */
/* increment the end_date by 1 day. then check that the end_date is  */
/* not a weekend. If it is increment another day until variables     */
/* HOLIDAY and WEEKEND are equal to NO.                              */
/*-------------------------------------------------------------------*/
bank_holiday_check:
 holiday = ''
 weekend = ''
 do until holiday = "NO" & weekend = "NO"
   m = Index(bank_hols,end_date)
   if m > 0 then do
     holiday = "YES"
     end_date = $dateinc(1 end_date) /* $dateinc in pgib.base.clist  */
     Parse Value end_date With end_date dow
   end /* m > 0 */

   else holiday = "NO"

   if holiday = "NO" & Substr(dow,1,1) = "S" then do
     end_date = $dateinc(1 end_date) /* $dateinc in pgib.base.clist  */
     weekend = "YES"
     Parse Value end_date With end_date dow
   end /* holiday = "NO" & Substr(dow,1,1) = "S" */

   else weekend = "NO"

 end /* until holiday = "NO" & weekend = "NO" */

 rnid_symbol     = ''
 ret_inp.1.?name = ''
 ret_inp.0       = ''
 pidt_name       = ''
 ret_con.0       = ''
 ret_con.1       = ''
 ret_con.2       = ''
 ret_code        = ''
 BLG_RC          = ''
 BLG_REAS        = ''
 tname           = ''

return end_date /* bank_holiday_check: */

/*-------------------------------------------------------------------*/
/* Error with line number displayed - for IKJEFT ISPF                */
/*-------------------------------------------------------------------*/
exception:
 parse arg return_code comment

 /* This if is for ISPF in batch only                                */
 if wordpos(condition('C'),'SYNTAX FAILURE') > 0 then do
   say 'Line' sigl':' left(sourceline(sigl),70)
   say 'Errortext:' errortext(rc)
   return_code = rc
   comment     = condition('C') 'failure at line' sigl
 end /* wordpos(condition('C'),'SYNTAX FAILURE') > 0 */

 say rexxname':'
 say rexxname':' comment'. RC='return_code
 say rexxname': Exception called from line' sigl

 z = msg(off)
 address tso 'delstack' /* Clear down the stack                      */
 z = msg(on)

 if return_code < 0 then return_code = 12 /* - RCs can be invalid    */

 zispfrc = return_code
 address ispexec "vput (zispfrc) shared"

exit return_code
