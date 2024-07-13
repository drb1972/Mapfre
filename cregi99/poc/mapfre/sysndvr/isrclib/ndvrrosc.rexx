<<NDVRROSC>>
:*--------------------------------------------------------------------*
:*                                                                    *
:* COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                   *
:*                                                                    *
:* Name: NDVRROSC                                                     *
:*                                                                    *
:* Function: This RPF is used to modify the SCL statements for the    *
:*  ADD or RETRIEVE actions.  The ENDEVOR/ROSCOE interface will allow *
:*  the user to add to or retrieve from a ROSCOE member.  Unfortunat- *
:*  ely, the ENDEVOR/MVS I/O routines do not support direct access    *
:*  to ROSCOE libraries.  To overcome this limitation, the SCL created*
:*  by the ENDEVOR/ROSCOE interface is modified in the following      *
:*  manner:                                                           *
:*    1) If the ADD action is from a ROSCOE member, that is, the      *
:*       ADD FROM clause is DSNAME ROSCOE, a step will be added       *
:*       prior to the execution of C1BM3000 to copy the member to     *
:*       a standard OS dataset.  The ADD action FROM clause is mod-   *
:*       ified to point to the dataset created in the first step.     *
:*    2) If the RETRIEVE action is to create a ROSCOE member, that is,*
:*       the RETRIEVE TO is DSNAME ROSCOE, the RETRIEVE action FROM   *
:*       clause will be modified to write to a temporary MVS dataset. *
:*       The TO DSNAME 'ROSCOE' clause will be replaced with a TO     *
:*       DDNAME ROSCOER clause.  The step(s) needed to load the ROSCOE*
:*       library member will be created in the NDVR RPF.              *
:*                                                                    *
:*  Note: This RPF is extremely dependent on the sequence and location*
:*  of the SCL action clauses.  It will probably fail if it is run    *
:*  against JCL that was NOT created by the ENDEVOR/ROSCOE interface  *
:*  program, C1RPUSER.                                                *
:*                                                                    *
:*--------------------------------------------------------------------*
:*--------------------------------------------------------------------*
:* Obtain a current directory listing.                                *
:*--------------------------------------------------------------------*
:* DIR
 LET L15 = 'N'                   :Indicate no ROSCOPY steps
:*--------------------------------------------------------------------*
:* Resequence the AWS beginning at 500000.  If the resequence failed, *
:* immediately exit. The AWS is assumed to contain the current SCL.   *
:*--------------------------------------------------------------------*
 TRAP ON
 R 900000 100                           :Resequence the AWS
 IF S.TC EQ 6
   S.RC = 16
   RETURN
 ENDIF
 TRAP OFF
 TOP
 LOOP
:  *------------------------------------------------------------------*
:  * Search for the clause FROM DSNAME 'ROSCOE'.  This clause is used *
:  * to identify a ROSCOE source location.  If found, change the      *
:  * clause to FROM DDNAME ROSCOEA.  The batch JCL will be modified   *
:  * to include a ROSCOEA DD statement.                               *
:  *------------------------------------------------------------------*
   TRAP
   NEXT AWS /FROM DSNAME 'ROSCOE'/
   TRAP OFF
   IF S.TC NE 0                          : If not found then
     ESCAPE                              :  immediately exit
   ENDIF
   EDIT F /FROM DSNAME 'ROSCOE'/FROM DDNAME ROSCOEA/
   READ AWS * L1
<<RECHKMEM>>
:  *----------------------------------------------------------------*
:  * If the clause contained the MEMBER statement, extract and save *
:  * the member name.                                               *
:  *----------------------------------------------------------------*
   LET L2=INDEX(L1 'MEMBER')
   IF L2 GT 0
     LET L6=LTRIM(TRIM(SUBSTR(L1 L2+8)))
     LET L6=SUBSTR(L6,1,INDEX(L6,'''')-1)
   ELSE
:    *----------------------------------------------------------------*
:    * The previous AWS record should be the action name.  If the     *
:    * action is LIST or PRINT then do not modify the SCL.            *
:    *----------------------------------------------------------------*
     READ AWS *-1 L1
     IF SUBSTR(L1,1,5) EQ 'LIST ' OR SUBSTR(L1,1,6) EQ 'PRINT '
       GOTO <<RECHKMEM>>
     ENDIF
     POINT *+1
     LET L6=''
   ENDIF
:  *----------------------------------------------------------------*
:  * Find the element name specified on the action ELEMENT clause.  *
:  * If the action did not contain a MEMBER clause then use the     *
:  * element name as the action source name.                        *
:  *----------------------------------------------------------------*
   TRAP
   PREV /ELEMENT/ 10
   TRAP OFF
   IF L6 EQ ''
     READ AWS * L1
     LET L2=INDEX(L1 'ELEMENT')
     LET L6=LTRIM(TRIM(SUBSTR(L1 L2+9)))
     LET L6=SUBSTR(L6,1,INDEX(L6,'''')-1)
   ENDIF
:  *----------------------------------------------------------------*
:  * Determine if a wildcard was specified.                         *
:  *----------------------------------------------------------------*
   LET L4=INDEX(L6 '*')
:  *----------------------------------------------------------------*
:  * If a wildcard was NOT specified then search for the THRU spec- *
:  * ification.  If found, extrace the THRU element name.           *
:  *----------------------------------------------------------------*
   IF L4 LE 0
     LET L2=INDEX(L1 'THRU')
     IF L2 GT 1
       LET L7=TRIM(SUBSTR(L1 L2+6))
       LET L7=SUBSTR(L7,1,INDEX(L7,'''')-1)
     ELSE
:      *-------------------------------------------------------------*
:      * There is no wildcard and a THRU clause was not specified.   *
:      *-------------------------------------------------------------*
       LET L7=''
       LET L8 = S.SEQ
       WRITE AWS T
         '//*-----------------------------------------------*    '
         '//* THE FOLLOWING JCL MUST BE CUSTOMIZED FOR THE  *    '
         '//* INSTALLATION. VERIFY THAT THE ROSLIBXX AND THE*    '
         '//* STEPLIB DATSETS ARE CORRECT.                  *    '
         '//*-----------------------------------------------*    '
         '//'|L6|'   EXEC PGM=ROSCOPY,PARM='''| S.KEY |'''       '
         '//STEPLIB  DD  DISP=SHR,DSN=ROSCOE.ROXXLIB             '
         '//ROSLIB00 DD  DISP=SHR,DSN=ROSCOE.ROSLIB00            '
         '//ROSLIB01 DD  DISP=SHR,DSN=ROSCOE.ROSLIB01            '
         '//ROSLIB02 DD  DISP=SHR,DSN=ROSCOE.ROSLIB02            '
         '//ROSLIB03 DD  DISP=SHR,DSN=ROSCOE.ROSLIB03            '
         '//SYSPRINT DD  SYSOUT=*                                '
         '//*SYSLIST DD  SYSOUT=*                                '
         '//SYSOUT   DD  DSN=&&NDVRADD('|L6|'),                  '
         '//             DISP=(OLD,PASS)                         '
         '//SYSIN    DD  *                                       '
         ' COPY MAXNAME=1,NOSEQ                                  '
         ' MEMBER NAME=('|S.PREFIX|'.'|L6|')                     '
       ENDWRITE
       LET L15 = 'Y'              :Indicate a ROSCOPY step was added
:      *--------------------------------------------------------------*
:      * Processing is complete.  Branch to the top of the loop to    *
:      * look at the next statement.                                  *
:      *--------------------------------------------------------------*
+      POINT +L8+
       RELOOP
     ENDIF
:  *-----------------------------------------------------------------*
:  * The source element is wildcarded.  Set the FROM and THRU member *
:  * name to the root portion of the wildcarded element name.        *
:  *-----------------------------------------------------------------*
   ELSE
     LET L6=L7=SUBSTR(L6 1 L4-1)
   ENDIF
:  *-----------------------------------------------------------------*
:  * Append as many trailing '9' characters to the THRU element name *
:  * as needed in order to create an eight character long string.    *
:  *-----------------------------------------------------------------*
   LET L7=PAD(L7,8,'9')
   ATTACH ZZZZZDIR 1,,
   LET L8 = S.SEQ
   LET L1='T'
   TRAP
   IF LENGTH(L6) GT 0
+    FIRST LIB 5 12 /+L6+/ PREFIX
   ENDIF
   TRAP OFF
:  *-----------------------------------------------------------------*
:  * If a THRU element was specified, loop over the directory and    *
:  * build a ROSCOPY step to copy each element in the THRU range.    *
:  *-----------------------------------------------------------------*
   LOOP
     UNTIL (S.TC NE 0)
       READ LIB * L2 5 8
     UNTIL (L2 GT L7)
       WRITE AWS T
         '//*-----------------------------------------------*    '
         '//* THE FOLLOWING JCL MUST BE CUSTOMIZED FOR THE  *    '
         '//* INSTALLATION. VERIFY THAT THE ROSLIBXX AND THE*    '
         '//* STEPLIB DATSETS ARE CORRECT.                  *    '
         '//*-----------------------------------------------*    '
         '//'|L2|'   EXEC PGM=ROSCOPY,PARM='''| S.KEY |'''       '
         '//STEPLIB  DD  DISP=SHR,DSN=ROSCOE.ROXXLIB             '
         '//ROSLIB00 DD  DISP=SHR,DSN=ROSCOE.ROSLIB00            '
         '//ROSLIB01 DD  DISP=SHR,DSN=ROSCOE.ROSLIB01            '
         '//ROSLIB02 DD  DISP=SHR,DSN=ROSCOE.ROSLIB02            '
         '//ROSLIB03 DD  DISP=SHR,DSN=ROSCOE.ROSLIB03            '
         '//SYSPRINT DD  SYSOUT=*                                '
         '//*SYSLIST DD  SYSOUT=*                                '
         '//SYSOUT   DD  DSN=&&NDVRADD('|L2|'),                  '
         '//             DISP=(OLD,PASS)                         '
         '//SYSIN    DD  *                                       '
         ' COPY MAXNAME=1,NOSEQ                                  '
         ' MEMBER NAME=('|S.PREFIX|'.'|L2|')                     '
       ENDWRITE
       LET L1 = '*'
       LET L15 = 'Y'              :Indicate a ROSCOPY step was added
       TRAP
       POINT LIB LINE *+1
       TRAP OFF
   ENDLOOP
+  POINT +L8+
 ENDLOOP
:  *------------------------------------------------------------------*
:  * If any ADD SCL was processed and a ROSDATA step added to the JCL *
:  * then include a step to preallocate the &&NDVRADD dataset.        *
:  *------------------------------------------------------------------*
 IF L15 EQ 'Y'
   WRITE AWS T
     '//*---------------------------------------------------* '
     '//* Allocate a temporary dataset to be used by the    * '
     '//* ROSCOPY steps below.                              * '
     '//*---------------------------------------------------* '
     '//ALLOCADD EXEC PGM=IEFBR14                             '
     '//ALLOCADD DD  DSN=&&NDVRADD,                           '
     '//             UNIT=SYSDA,                              '
     '//             SPACE=(TRK,(15,30,24)),                  '
     '//             DISP=(NEW,PASS,DELETE),                  '
     '//             DCB=(LRECL=80,RECFM=FB,BLKSIZE=15440)    '
   ENDWRITE
:  *-----------------------------------------------------------*
:  * If a ROSCOPY step was added to the JCL then add an ROSCOEA*
:  * DD statement to the end of the execution JCL.             *
:  *-----------------------------------------------------------*
   WRITE AWS B
     '//ROSCOEA  DD DSN=&&NDVRADD,                          '
     '//            DISP=(OLD,PASS)                         '
   ENDWRITE
 ENDIF
:*--------------------------------------------------------------------*
:* Change any occurance of the TO DSNAME 'ROSCOE' clause to TO DDNAME *
:* ROSCOER.  The NDVR RPF will process the modified SCL.              *
:*--------------------------------------------------------------------*
 TRAP ON
 EDIT /TO   DSNAME 'ROSCOE'/TO DDNAME ROSCOER/
 TRAP OFF
:*--------------------------------------------------------------------*
:* Position to the top of the AWS.                                    *
:*--------------------------------------------------------------------*
 TOP
