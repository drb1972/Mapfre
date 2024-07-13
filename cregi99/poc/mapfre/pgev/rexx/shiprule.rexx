/*--------------------------REXX----------------------------*\
 * This rexx reads in Endevor Shipement rules and a list    *
 * of dataset names.                                        *
 * It applies the shipemnet rules to the datasets to give   *
 * the target dataset name.                                 *
 *----------------------------------------------------------*
 *  Author:     Emlyn Williams                              *
 *              Endevor Support                             *
\*----------------------------------------------------------*/
trace n

arg plex

say 'SHIPRULE: Building shipment rules for' plex

/* Read the excluded hlqs member and apply the data to this rexx */
exclude_selects = ''
"execio * diskr EXCLUDES (stem exclude. finis" /* DSN list */
if rc ^= 0 then call exception 20 'DISKR from EXCLUDES failed RC='rc
do i = 1 to exclude.0
  exclude_selects = exclude_selects strip(exclude.i)
end /* i = 1 to exclude.0 */
say 'SHIPRULE: The following HLQs will be excluded...'
say exclude_selects
say

z        = 0     /* counter for SELECT statements */
exit_rc  = 0
count_w  = 1     /* counter for warnings          */
count_e  = 1     /* counter for warnings          */
warn.count_w = 'SHIPRULE: Plex:...' plex
excl.count_e = 'SHIPRULE: Plex:...' plex
plex     = substr(plex,5,1)

/* Read the shipment rules from batch admin & build varables */
call shiprules

/* Read PREV datasets and apply the rules to them */
"execio * diskr PREVDSNS (stem prevdsns. finis"
if rc ^= 0 then call exception 20 'DISKR from PREVDSNS failed RC='rc

do i = 1 to prevdsns.0
  dsn = word(prevdsns.i,1)
  vol = word(prevdsns.i,2)
  if vol ^= '*ALIAS' then do
    parse value dsn with ,
      dsn_qual1 '.' dsn_qual2 '.' dsn_qual3 '.' dsn_qual4 '.' dsn_qual5
    /* Exclude wizard shipment datasets */
    if left(dsn_qual4,2) = 'C0' | ,
       left(dsn_qual4,2) = 'B0' then iterate
    /* Exclude datasets with 5 qualifiers */
    if strip(dsn_qual5) ^= '' then iterate

    call applyrule
  end /* vol ^= '*ALIAS' */
end /* do i = 1 to prevdsns.0 */

call check_used

/* Write out the shipement rules for each dataset */
say
say 'SHIPRULE:  Writing' queued() 'lines to RESULT'
"execio * diskw RESULT (finis"
if rc ^= 0 then call exception 20 'DISKW to RESULT failed RC='rc

/* Write out the PDSM37 SELECT statements */
say
say 'SHIPRULE:  Writing' z 'lines to TGTDSNS'
"execio" z "diskw TGTDSNS (stem seldsn. finis"
if rc ^= 0 then call exception 20 'DISKW to TGTDSNS failed RC='rc

/* Write out any warnings for emailing to ¯ endevor */
say
say 'SHIPRULE:  Writing' count_w 'lines to WARNINGS'
"execio" count_w "diskw WARNINGS (stem warn. finis"
if rc ^= 0 then call exception 20 'DISKW to WARNINGS failed RC='rc

/* Write out any excluded datasets                  */
say
say 'SHIPRULE:  Writing' count_e 'lines to EXCLUDED'
"execio" count_e "diskw EXCLUDED (stem excl. finis"
if rc ^= 0 then call exception 20 'DISKW to EXCLUDES failed RC='rc

exit exit_rc

/*----------------------------------------*/
/* Build the shipment rules for each plex */
/*----------------------------------------*/
shiprules:

 c_fully = 0 /* Fully qualified rule counter */
 c_4qual = 0 /* 4 qualifier     rule counter */
 c_3qual = 0 /* 3 qualifier     rule counter */

 /* Read in the shipment rules from PGEV.AUTO.DATA */
 "execio * diskr SHIPRULE (stem line. finis"
 if rc ^= 0 then call exception 20 'DISKR from SHIPRULE failed RC='rc

 do i = 1 to line.0
   if substr(line.i,8,14) = "HOST DATASET '" then do
     hostmask = strip(subword(line.i,3),,"'")
     parse value hostmask with ,
           hqual1 '.' hqual2 '.' hqual3 '.' hqual4 '.' hqual5
     rmtdsn  = 'EXCLUDE'
     i = i + 1
     if subword(line.i,1,3) = "MAPS TO REMOTE" then do
       i = i + 1
       rmtdsn = strip(subword(line.i,1),,"'")
     end /* subword(line.i,1,3) = "MAPS TO REMOTE" */

     select
       when pos('*',hostmask) = 0 then do /* fully qualified */
         c_fully = c_fully + 1
         host_fully.c_fully = left(hostmask,30) rmtdsn
       end /* pos('*',hostmask) = 0 */

       when hqual4 ^= '' then do         /* 4 qaulifiers */
         c_4qual = c_4qual + 1
         host_4qual.c_4qual = left(hostmask,30) rmtdsn
       end /* hqual4 ^= '' */

       when hqual3 ^= '' then do         /* 3 qaulifiers */
         c_3qual = c_3qual + 1
         host_3qual.c_3qual = left(hostmask,30) rmtdsn
       end /* hqual3 ^= '' */

       otherwise do
         count_w  = count_w + 1
         warn.count_w = left(hostmask,30) 'not compatible with shiprules'
         exit_rc  = 1
       end /* otherwise */
     end /* select */

   end /* substr(line.i,8,14) = "HOST DATASET '" */

 end /* i = 1 to line.0 */

return

/*----------------------------------------*/
/* Apply the shipment rules for each plex */
/*----------------------------------------*/
applyrule:

 do x = 1 to c_fully        /* Fully qualified */
   hostmask = word(host_fully.x,1)
   if dsn = hostmask then do
     tgtmask = word(host_fully.x,2)
     call convert
     return
   end /* dsn = hostmask */
 end /* x = 1 to c_fully */

 if dsn_qual4 ^= '' then do /* Loop through 4 qualifier masks */
   do x = 1 to c_4qual
     hostmask = word(host_4qual.x,1)
     match2 = 'N'
     match3 = 'N'
     match4 = 'N'
     parse value hostmask with hqual1 '.' hqual2 '.' hqual3 '.' hqual4
     ast2 = pos('*',hqual2)
     ast3 = pos('*',hqual3)
     ast4 = pos('*',hqual4)
     if dsn_qual2 = hqual2 then
       match2 = 'Y'
     if ast2 > 0 then
       if left(dsn_qual2,ast2-1) = left(hqual2,ast2-1) then
         match2 = 'Y'
     if dsn_qual3 = hqual3 then
       match3 = 'Y'
     if ast3 > 0 then
       if left(dsn_qual3,ast3-1) = left(hqual3,ast3-1) then
         match3 = 'Y'
     if dsn_qual4 = hqual4 then
       match4 = 'Y'
     if ast4 > 0 then
       if left(dsn_qual4,ast4-1) = left(hqual4,ast4-1) then
         match4 = 'Y'
     if match2 = 'Y' & ,
        match3 = 'Y' & ,
        match4 = 'Y' then do
       tgtmask = word(host_4qual.x,2)
       call convert
       return
     end /* found a match */
   end /* x = 1 to c_4qual */
 end /* dsn_qual4 ^= '' */

 if dsn_qual3 ^= '' & ,
    dsn_qual4  = '' then do
   do x = 1 to c_3qual
     hostmask = word(host_3qual.x,1)
     match2 = 'N'
     match3 = 'N'
     parse value hostmask with ,
           hqual1 '.' hqual2 '.' hqual3
     ast2 = pos('*',hqual2)
     ast3 = pos('*',hqual3)
     if dsn_qual2 = hqual2 then
       match2 = 'Y'
     if ast2 > 0 then
       if left(dsn_qual2,ast2-1) = left(hqual2,ast2-1) then
         match2 = 'Y'
     if dsn_qual3 = hqual3 then
       match3 = 'Y'
     if ast3 > 0 then
       if left(dsn_qual3,ast3-1) = left(hqual3,ast3-1) then
         match3 = 'Y'
     if match2 = 'Y' & ,
        match3 = 'Y' then do
       tgtmask = word(host_3qual.x,2)
       call convert
       return
     end /* found a match */
   end /* x = 1 to c_3qual */

 end /* dsn_qual3 ^= '' */

 count_w  = count_w + 1
 warn.count_w = left(dsn,30) 'maps to itself and is ignored by SHIPRULE'
 exit_rc  = 1

return

/*----------------------------------------*/
/* Convert the target dsn                 */
/*----------------------------------------*/
convert:

 hostused.hostmask = 'USED'

 if tgtmask = 'EXCLUDE' then do
   count_e  = count_e + 1
   excl.count_e = left(dsn,30) 'excluded'
   return
 end /* tgtmask = 'EXCLUDE' */

 parse value tgtmask with ,
       tqual1 '.' tqual2 '.' tqual3 '.' tqual4

 if tqual2 ^= '' then do
   aster = pos('*',tqual2)
   if aster > 0 then do
     en = aster - 1
     tqual2  = substr(tqual2,1,en) || substr(dsn_qual2,aster)
   end /* aster > 0 */
   tqual2  = '.'tqual2
 end /* tqual2 ^= '' */

 if tqual3 ^= '' then do
   aster = pos('*',tqual3)
   if aster > 0 then do
     en = aster - 1
     tqual3  = substr(tqual3,1,en) || substr(dsn_qual3,aster)
   end /* aster > 0 */
   tqual3  = '.'tqual3
 end /* tqual3 ^= '' */

 if tqual4 ^= '' then do
   aster = pos('*',tqual4)
   if aster > 0 then do
     en = aster - 1
     tqual4  = substr(tqual4,1,en) || substr(dsn_qual4,aster)
   end /* aster > 0 */
   tqual4  = '.'tqual4
 end /* tqual4 ^= '' */

 tgtdsn = tqual1 || tqual2 || tqual3 || tqual4

 if left(tgtdsn,4) = 'PG##' then do
   tgtdsn  = overlay(substr(tgtdsn,7,2),tgtdsn,3)
   tgtdsn  = overlay('BASE',tgtdsn,6)
 end /* left(tgtdsn,4) = 'PG##' */

 /* Wizard real target datasets are excluded so add the real target */
 /* and dont do the CMPARM dataset                                  */
 if right(tgtdsn,7) = '.CMPARM' then
   call build_select left(tgtdsn,length(tgtdsn)-7)
 else
   call build_select tgtdsn

 queue plex left(dsn,44) 'rule' left(tgtmask,22) 'maps to' tgtdsn

return

/*----------------------------------------*/
/* Check for rules that are not used      */
/*----------------------------------------*/
check_used:

 /* Read unused rules that are ok                  */
 "execio * diskr UNUSEDOK (stem unusedok. finis"
 if rc ^= 0 then call exception 20 'DISKR from UNUSEDOK failed RC='rc

 do x = 1 to unusedok.0
   rule = space(unusedok.x,0)
   ok.rule = 'YES'
 end /* x = 1 to unusedok.0 */

 do x = 1 to c_fully        /* Fully qualified */
   hostmask = word(host_fully.x,1)
   hostmasks = space(host_fully.x,0)
   if hostused.hostmask ^= 'USED' & ,
      ok.hostmasks ^= 'YES' then do
     count_w  = count_w + 1
     warn.count_w = left(host_fully.x,65) 'rule not used'
     exit_rc  = 1
   end /* hostused.hostmask ^= 'USED' & ok.hostmasks ^= 'YES' */
 end /* x = 1 to c_fully */

 do x = 1 to c_3qual
   hostmask = word(host_3qual.x,1)
   hostmasks = space(host_3qual.x,0)
   if hostused.hostmask ^= 'USED' & ,
      ok.hostmasks ^= 'YES' then do
     count_w  = count_w + 1
     warn.count_w = left(host_3qual.x,65) 'rule not used'
     exit_rc  = 1
   end /* hostused.hostmask ^= 'USED' & ok.hostmasks ^= 'YES' */
 end /* x = 1 to c_3qual */

 do x = 1 to c_4qual
   hostmask = word(host_4qual.x,1)
   hostmasks = space(host_4qual.x,0)
   if hostused.hostmask ^= 'USED' & ,
      ok.hostmasks ^= 'YES' then do
     count_w  = count_w + 1
     warn.count_w = left(host_4qual.x,65) 'rule not used'
     exit_rc  = 1
   end /* hostused.hostmask ^= 'USED' & ok.hostmasks ^= 'YES' */
 end /* x = 1 to c_4qual */

return

/* +---------------------------------------------------------------+ */
/* | build select statements                                       | */
/* +---------------------------------------------------------------+ */
build_select:
 arg select_dsn

 if tgtdsnf.select_dsn ^= 'DONE' then do
   tgtdsnf.select_dsn = 'DONE'
   if wordpos(left(select_dsn,9),exclude_selects) = 0  then do
     z = z + 1
     seldsn.z = ' SELECT DSN='select_dsn
   end /* wordpos(left(select_dsn,9),exclude_selects) = 0 */
 end /* tgtdsnf.select_dsn ^= 'DONE' */

return

/* +---------------------------------------------------------------+ */
/* | Error with line number displayed                              | */
/* +---------------------------------------------------------------+ */
exception:
 parse arg return_code comment

 do i = 1 to queued() /* Clear down the stack */
   pull
 end

 parse source . . rexxname . /* Get the rexx name (generic subroutine)*/
 say rexxname':'
 say rexxname':' comment
 say rexxname': Exception called from line' sigl

exit return_code
