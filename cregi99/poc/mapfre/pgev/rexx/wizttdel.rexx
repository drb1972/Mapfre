/*--------------------------REXX---------------------------------*\
 *  Read a report of wizard TT dsns                              *
 *  Read a report of unimplemented INFOMAN CMRs                  *
 *  Produce DLETE & HDELETE statements to delete all the         *
 *  TT datasets where the CMR has been deleted or run            *
 *  Excludes any DSN with words PREP or DOCJOBS in any qualifier *
 *---------------------------------------------------------------*
 *  Author:     Emlyn Williams                                   *
 *              Endevor Support                                  *
 *  Executed by : PROC EVHWIZTW and JOBS EVHWIZ*W (*=Plex)       *
\*---------------------------------------------------------------*/
address tso
"execio * diskr dsns    (stem dsn. finis" /* TT dsn list */
"execio * diskr infoman (stem inf. finis" /* CMR list    */
"execio * diskr hlqs    (stem hlq. finis" /* CMR list    */

count1 = 0
count2 = 0
count3 = 0
space  = 0

do x = 1 to inf.0            /* Analyse CMR list */
   ccid = substr(inf.x,222,8)
   cmr.ccid = 'Y'
end

do x = 1 to dsn.0            /* Analyse DSN list */
   exclude = 0               /* Reset flags to 0 */
   prep = 0
   docj = 0
   dsn = word(dsn.x,1)       /* get DSN from list */
   say 'WIZTTDEL: Processing dataset 'dsn
   vol = subword(dsn.x,2,1)  /* get vol/migrat info */
   s = pos('.C0',dsn)        /* get CCID */
   s = s + 1
   ccid = substr(dsn,s,8)
/* Check DSN for PREP or DOCJOBS and set exclude flag to 1 if found */
   prep = pos('PREP',dsn)
   docj = pos('DOCJOBS',dsn)
   if prep > 0 | docj > 0 then
      exclude = 1
/* If a CMR exists for the CCID & the exclude flag is '0' - does */
/* not contain excluded qualifier - then create a delete card    */
   if cmr.ccid ^= 'Y' & exclude ='0' then do
/* Check whether DSN is migrated and create HDELETE command      */
     if left(vol,6) = 'MIGRAT' then do
       say left(dsn,50) 'HDELETE'
       count3 = count3 + 1
       queue 'HDELETE' "'"dsn"'" 'WAIT'
     end
/* If DSN is not migrated then create DELETE command             */
     else do
       say left(dsn,50) 'DELETE'
       count1 = count1 + 1
       deldsns.count1 = '  DELETE' dsn
       if Word(dsn.x,2) ^= '*VSAM*' then
         space = space + subword(dsn.x,7,1)
     end
   end
/* Anything else must not be a valid CMR or Excluded so keep     */
   else do
     count2 = count2 + 1
     savedsns.count2 = ccid dsn
   end
end
'execio * diskw hdelete (finis'   /* Write out HDELETE commands */

do i = 1 to count1
  queue deldsns.i
end
queue '   SET MAXCC=0'
'execio * diskw delete (finis'    /* Write out DELETE commands */

do i = 1 to count2
  queue savedsns.i
end
'execio * diskw savedsns (finis'  /* Write out non deleted DSNs */

queue ' DUMP DATASET(INCLUDE(               -'
do i = 1 to hlq.0                 /* Dump all hlq masks rather than   */
  queue '  ' word(hlq.i,1) '-'    /* individual datasets due to dfdss */
end                               /* limit                            */
queue '      )) -'
queue '      OUTDDNAME(OUTPUT) SHR COMPRESS'
'execio * diskw backup (finis'    /* Write out backup cards     */

/* Write summary report */
do i = 1 to hlq.0
  queue 'WIZTTDEL: Mask' i word(hlq.i,1)
end
queue 'WIZTTDEL:'
queue 'WIZTTDEL:' count3 'Migrated datasets will be deleted'
queue 'WIZTTDEL:' count1 'Online datasets will be deleted'
queue 'WIZTTDEL:' count2 'Datasets remaining'
queue 'WIZTTDEL: Online dataset delete saved' space 'tracks'
'execio * diskw summary (finis'

exit 0
