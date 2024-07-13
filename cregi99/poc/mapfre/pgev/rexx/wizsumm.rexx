/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* |  This routine builds a User and Department Summary Report     | */
/* |  from the &HLQL..WIZARD.TOTALS report, this Summary Report    | */
/* |  is called &HLQL..WIZARD.SUMMARY.                             | */
/* |                                                               | */
/* |                                                               | */
/* |  Name    : PGEV.BASE.REXX(WIZSORT)                            | */
/* |  Author  : John Lewis                                         | */
/* |  Date    : 10th December 2007                                 | */
/* |                                                               | */
/* |  Input Parms   : None                                         | */
/* |                                                               | */
/* |  DDNAME WIZINP : A Sorted version of &HLQL.WIZARD.TOTALS      | */
/* |                  built by step BATCH2 of PROCLIB(EVGWIZ1D)    | */
/* |                                                               | */
/* |  DDNAME REPORT : The new &ID.EV.NWIZARD.EVHBSERM.SUMMARY(+1)  | */
/* |                                                               | */
/* |  Amended Log:                                                 | */
/* | +---------+---------+-------------------------------------+   | */
/* | | Who     |Date     |Description                          |   | */
/* | +---------+---------+-------------------------------------+   | */
/* | | J.Lewis |02/02/10 |Fix department names.                |   | */
/* | |         |         |                                     |   | */
/* | +---------+---------+-------------------------------------+   | */
/* +---------------------------------------------------------------+ */
Inf_Team = 'GILLESR WIFFINS WRIGHJC LILLGR'
/* +---------------------------------------------------------------+ */
/* | Set up Work variables                                         | */
/* +---------------------------------------------------------------+ */
Header_written = 'N'
rUser = ''
IP_Count = 0     ;  IP_pkgCT = 0
ITMS_Count = 0   ;  ITMS_pkgCT = 0
ITMF_Count = 0   ;  ITMF_pkgCT = 0
OPS_Count = 0    ;  OPS_pkgCT = 0
OTH_Count = 0    ;  OTH_pkgCT = 0
TOTAL_count = 0  ;  TOTAL_pkgCT = 0
/* +---------------------------------------------------------------+ */
/* | Process the sorted version of HLQL..WIZARD.REPORT.TOTALS      | */
/* +---------------------------------------------------------------+ */
do forever
 new_line = readnext()
 if new_line = 'EOF' Then Call Exit
 parse var new_line 1 . 25 uCount 29 . 31 YYMM 35 . 42 uUser 49 .
 if Header_Written = 'N' then Call Write_Header
 uCount = strip(uCount,'L',0)
 uUser  = strip(uUser)

 /* +---------------------------------------+ */
 /* | Count the Packages for each User      | */
 /* +---------------------------------------+ */
 if value(uUser'_pkgct') = uUser'_PKGCT' then
        garbage = value(uUser'_pkgct',1)
   else garbage = value(uUser'_pkgct',value(uUser'_pkgct')+1)

 /* +---------------------------------------+ */
 /* | Count the Components for each User    | */
 /* +---------------------------------------+ */
 if value(uUser'_elmct') = uUser'_ELMCT' then
        garbage = value(uUser'_elmct',uCount)
   else garbage = value(uUser'_elmct',value(uUser'_elmct')+uCount)

 /* +---------------------------------------+ */
 /* | When we get a new User, get the Name  | */
 /* | and Department of the Old User and    | */
 /* | write all the details out to REPORT   | */
 /* +---------------------------------------+ */
 if rUser ^= '' & rUser ^= uUser then do
   call Get_User_Details(rUser)
   call Writerec(' 'Left(rUser,7,' '),
           Right(value(rUser'_pkgct'),5,' '),
           Right(value(rUser'_elmct'),5,' '),
           left(rName,20,' ') Left(rDept,35,' '))
   end
 rUser = uUser
 call Get_User_Details(rUser)

 /* +------------------------------------------+ */
 /* | Keep tally of totals for each Department | */
 /* +------------------------------------------+ */
 Select
   When Left(rDept,5) = 'IP - '     Then call Add_To_Summary('IP')
   When wordpos(rUser,Inf_Team) > 0 Then call Add_To_Summary('ITMS')
   When Left(rDept,7) = 'IT MAIN'   Then call Add_To_Summary('ITMF')
   Otherwise call Add_To_Summary('OTH')
   end
 end

Exit:

 /* +------------------------------------------+ */
 /* | Write details out for the very last User | */
 /* +------------------------------------------+ */
call Get_User_Details(uUser)
call Writerec(' 'Left(uUser,7,' '),
        Right(value(uUser'_pkgct'),5,' '),
        Right(value(uUser'_elmct'),5,' '),
        left(rName,20,' ') Left(rDept,35,' '))

call Get_Percentages

 /* +----------------------------------------------+ */
 /* | Write header for Department Summary report   | */
 /* +----------------------------------------------+ */
call Writerec(' ')
call writerec(' ')
call writerec(center('WIZARD - DEPARTMENT SUMMARY REPORT FOR',
              rMonth '20'||left(YYMM,2),72,' '))
call Writerec(' ')
call Writerec(copies(' ',35) '    CMR        COMPONENT')
call Writerec(' 'Left('DEPARTMENT',35,' ') '   COUNT(%)   COUNT(%)')
call Writerec(' 'copies('=',35) copies('=',13) copies('=',13))

 /* +-----------------------------------------------+ */
 /* | Write details for Department Summary report   | */
 /* +-----------------------------------------------+ */
call writerec(left(' IP - Batch Development',36,' '),
      right(IP_pkgCT,6,' ')right('('strip(IP_ppct)')',7,' '),
      right(IP_Count,6,' ')right('('strip(IP_pct)')',7,' '))

call writerec(left(' IT - BATCH INFRASTRUCTURE',36,' '),
      right(ITMS_pkgCT,6,' ')right('('strip(ITMS_ppct)')',7,' '),
      right(ITMS_Count,6,' ')right('('strip(ITMS_pct)')',7,' '))

call writerec(left(' IT - Batch Services',36,' '),
      right(ITMF_pkgCT,6,' ')right('('strip(ITMF_ppct)')',7,' '),
      right(ITMF_Count,6,' ')right('('strip(ITMF_pct)')',7,' '))

call writerec(left(' OTHER',36,' '),
      right(OTH_pkgCT,6,' ')right('('strip(OTH_ppct)')' ,7,' '),
      right(OTH_Count,6,' ')right('('strip(OTH_pct)')' ,7,' '))

call writerec(' 'copies('-',35) copies('-',13) copies('-',13))

call writerec(right('TOTAL:',36,' ') right(TOTAL_pkgCT,6,' '),
               right(TOTAL_Count,13,' '))
call writerec(' 'copies('-',35) copies('-',13) copies('-',13))
Exit 0
Return

Add_To_Summary:

 /* +------------------------------------------------------+ */
 /* | Tally grand totals for the Department Summary Report | */
 /* +------------------------------------------------------+ */
arg pfx .
garbage = value(pfx||'_Count',value(pfx||'_Count')+uCount)
TOTAL_Count = TOTAL_Count + uCount
garbage = value(pfx||'_pkgCT',value(pfx||'_pkgCT')+1)
TOTAL_pkgCT = TOTAL_pkgCT + 1
Return

Get_Percentages:
/* +---------------------------------------------------------+ */
/* | Calculate percentages for the Department Summary Report | */
/* +---------------------------------------------------------+ */
IP_PCT   = format((IP_Count   / TOTAL_Count)*100,2,2)
ITMS_PCT = format((ITMS_Count / TOTAL_Count)*100,2,2)
ITMF_PCT = format((ITMF_Count / TOTAL_Count)*100,2,2)
OTH_PCT  = format((OTH_Count  / TOTAL_Count)*100,2,2)

IP_pPCT   = format((IP_pkgCT   / TOTAL_pkgCT)*100,2,2)
ITMS_pPCT = format((ITMS_pkgCT / TOTAL_pkgCT)*100,2,2)
ITMF_pPCT = format((ITMF_pkgCT / TOTAL_pkgCT)*100,2,2)
OTH_pPCT  = format((OTH_pkgCT  / TOTAL_pkgCT)*100,2,2)
Return

Get_User_Details:
/* +----------------------------------------------------+ */
/* | Use RACUNL0 to obtain the User Name and Department | */
/* +----------------------------------------------------+ */
arg gUser .
  X = OUTTRAP('LIST.')
"racunl0 user("gUser")"
  X = OUTTRAP('OFF')

if right(Strip(list.1),9) = 'NOT FOUND' then do
   rName = '*UNKNOWN*'
   rDept = '*UNKNOWN*'
   end
  Else do
   rName = STRIP(SUBSTR(LIST.1,35),T)
   rDept = STRIP(SUBSTR(LIST.2,35),T)
   end
Return

readnext:
/* +------------------------------------------+ */
/* | Get the next input record                | */
/* +------------------------------------------+ */
"EXECIO 1 DISKR WIZINP"
if rc = 2 then return 'EOF'
if rc ^= 0 then do
  Say 'ERROR: Problem reading DDNAME WIZINP, RC='||rc
  EXIT 999
  end
pull nextline
Return nextline

Write_Header:
/* +--------------------------------------------+ */
/* | Write header for the User Summary Report   | */
/* +--------------------------------------------+ */
Header_written = 'Y'
allMonths = 'JANUARY FEBRUARY MARCH APRIL MAY JUNE JULY AUGUST',
            'SEPTEMBER OCTOBER NOVEMBER DECEMBER'
rMonth = word(allmonths,substr(YYMM,3,2))

call writerec(' ')
call writerec(center('WIZARD - USER SUMMARY REPORT FOR',
              rMonth '20'||left(YYMM,2),72,' '))
call writerec(' ')
call Writerec(' 'left('USERID',7,' ') left('CMRS',5,' '),
    left('COUNT',5,' ') left('NAME',20,' ') left('DEPARTMENT',35,' '))
call Writerec(' 'copies('=',7) copies('=',5) copies('=',5),
    copies('=',20) copies('=',35))
Return

writerec:

/* +------------------------------------------+ */
/* | Write record to output file              | */
/* +------------------------------------------+ */
arg out_line
push out_line
"EXECIO 1 DISKW REPORT"
Return
