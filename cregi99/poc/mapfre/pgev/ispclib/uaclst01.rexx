/* +-REXX----------------------------------------------------------+ */
/* | This utility is used to display the results from the Vanguard | */
/* | dataset PGEV.ENDEVOR.RACF.USER.REPORT                         | */
/* |                                                               | */
/* | It is invoked from option 15 of the Endevor User panel        | */
/* +---------------------------------------------------------------+ */
Parse arg debug .
if debug = 'TRACE' then do
  debug='Y'
  trace ir
end /* if debug = 'TRACE' then do                                    */

Call set_up

/* +---------------------------------------------------------------+ */
/* | Display the front panel                                       | */
/* +---------------------------------------------------------------+ */
do forever
  "ISPEXEC DISPLAY PANEL(UACLST01)"
  if rc = 8 then Leave
  Call get_new_list
end /* do forever                                                    */

call tidy_up

exit

/* +---------------------------------------------------------------+ */
/* |                S U B R O U T I N E S                          | */
/* +---------------------------------------------------------------+ */

/* +---------------------------------------------------------------+ */
/* | Allocate all the datasets required for the routine            | */
/* +---------------------------------------------------------------+ */
set_up:
 access_dsn = 'PGEV.ENDEVOR.RACF.USER.REPORT'
 "ALLOC FI(SORTOUT) LRECL(133) RECFM(F,B) NEW CYL SPACE(20 5) REUSE"
 "ALLOC FI(SYSIN) LRECL(80) RECFM(F,B) NEW TRACK SPACE(1 1) REUSE"
 "ALLOC FI(SORTIN) DS('"access_dsn"') SHR REUSE"
 "ALLOC FI(SYSOUT) LRECL(133) RECFM(F,B) NEW CYL SPACE(20 5) REUSE"
Return

/* +---------------------------------------------------------------+ */
/* | Free the files that were allocated for the routine            | */
/* +---------------------------------------------------------------+ */
tidy_up:
 "FREE FI(SYSIN SORTIN SORTOUT SYSOUT)"
Return

/* +---------------------------------------------------------------+ */
/* | Initiate a sort to get the data from the Vanguard dataset     | */
/* +---------------------------------------------------------------+ */
Get_new_list:
 "ISPEXEC VGET (VAREVNME SYS U1SOVR RUSERID) PROFILE"

 call bld_SYSIN

 "ISPEXEC SELECT PGM(SORT)"
 sort_rc = rc
 "EXECIO 1 DISKR SORTOUT (STEM SORTOUT. FINIS"
 if sort_rc = 0 &  sortout.0 = 0 then do
   zedsmsg = 'Nothing Found'
   zedlmsg = "No Users found, adjust your parameters and try again"
   "ISPEXEC SETMSG MSG(ISRZ001)"
   if debug = 'Y' then call display_error
   return
 end

 if sort_rc = 0 & debug ^= 'Y' then call display_file
 else call display_error

return

/* +---------------------------------------------------------------+ */
/* | Browse the output result set                                  | */
/* +---------------------------------------------------------------+ */
display_file:
 "ISPEXEC LMINIT DATAID(DATAID) DDNAME(SORTOUT)"

 if rc = 0 Then do
   "ISPEXEC BROWSE  DATAID("DATAID") PANEL(UACLST02)"
   return
 end

 zedsmsg = '^Found'
 zedlmsg = 'Problem reading the temporary RACF access file.'
 "ISPEXEC SETMSG MSG(ISRZ001)"
return

/* +---------------------------------------------------------------+ */
/* | Issue message if there is a problem                           | */
/* +---------------------------------------------------------------+ */
display_error:
 "ISPEXEC LMINIT DATAID(DATAID) DDNAME(SYSOUT)"
 if rc = 0 Then do
   "ISPEXEC BROWSE  DATAID("DATAID")"
   return
 end
 zedsmsg = '^Found'
 zedlmsg = 'Problem reading the temporary RACF access file.'
 "ISPEXEC SETMSG MSG(ISRZ001)"
return

/* +---------------------------------------------------------------+ */
/* | Build the sysin for the sort program                          | */
/* +---------------------------------------------------------------+ */
bld_SYSIN:
 sysin. = ''
 sysin.1 = " SORT FIELDS=(10,2,CH,A,19,8,CH,A)"
 sysin.2 = "  INCLUDE   COND=(58,7,CH,NE,C'P@IDBS2 ',AND,"
 sysin.3 = "                  58,7,CH,NE,C'PRENDEVR',AND,"
 ss = 3

 if VAREVNME ^= '*'   then do
   ss = ss + 1
   sysin.ss = copies(' ',18)"1,8,CH,EQ,C'"Left(VAREVNME,8,' ')"',AND,"
 end

 if sys ^= '*'   then do
   ss = ss + 1
   sysin.ss = copies(' ',18)"10,8,CH,EQ,C'"Left(sys,8,' ')"',AND,"
 end

 select
   when U1SACC = 'O' then do
     ss = ss + 1
     sysin.ss = copies(' ',18)"49,8,CH,EQ,C'OVERRIDE',AND,"
   end /* U1SACC = 'O' */
   when U1SACC = 'U' then do
     ss = ss + 1
     sysin.ss = copies(' ',18)"(49,8,CH,EQ,C'OVERRIDE',OR,"
     ss = ss + 1
     sysin.ss = copies(' ',18)" 49,6,CH,EQ,C'UPDATE'),AND,"
   end /* U1SACC = 'U' */
   when U1SACC = 'R' then do
     ss = ss + 1
     sysin.ss = copies(' ',18)"49,4,CH,EQ,C'READ',AND,"
   end /* U1SACC = 'R' */
   otherwise nop
 end /* select */

 if Strip(RUSERID) ^= ''   then do
   ss = ss + 1
   sysin.ss = copies(' ',18)"19,8,CH,EQ,C'"Left(RUSERID,8,' ')"',AND,"
 end

 if sys = 'EV' Then NOP

 /* suppress certain userids or access groups                        */
 Else do
   ss = ss + 1
   sysin.ss = copies(' ',18)"49,8,CH,NE,C'ADMIN   ',AND," /* group   */
   ss = ss + 1
   sysin.ss = copies(' ',18)"19,8,CH,NE,C'ENDVPUR ',AND," /* userid  */
   ss = ss + 1
   sysin.ss = copies(' ',18)"19,8,CH,NE,C'ENDEVOR ',AND," /* userid  */
   ss = ss + 1
   sysin.ss = copies(' ',18)"19,8,CH,NE,C'PMFBCH  ',AND," /* userid  */
   ss = ss + 1
   sysin.ss = copies(' ',18)"19,8,CH,NE,C'HKPGEND ',AND," /* userid  */
 end

 sysin.ss = overlay(")    ",sysin.ss,pos(',AND,',sysin.ss,5))
 sysin.0 = ss
 "EXECIO * DISKW SYSIN (STEM SYSIN. FINIS"

Return
