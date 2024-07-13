<<NDVR>>
:*--------------------------------------------------------------------*
:*                                                                    *
:* COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.
:*                                                                    *
:* Name: NDVR                                                         *
:*                                                                    *
:* Function: This RPF is used to drive the ENDEVOR/ROSCOE dialog.     *
:*  The RPF will call program C1RPUSER to drive the dialog.  The      *
:*  program will use the ETSO SUSP command to pass control back to    *
:*  the RPF for specialized processing.                               *
:*                                                                    *
:* LOG:                                                               *
:* P2305 Correct problem where use of Librarian files results in      *
:*       DATASET NAME IS NOT VALID                                    *
:*             4/2/2001   - Dan Dondero (donda03)                     *
:* P2313 Added a test of the return code from NDVRRETV.               *
:*         See also NDVRRETV, for additional changes.                 *
:*             4/2/2001     - Dan Dondero                             *
:*                                                                    *
:*--------------------------------------------------------------------*
PUSH
:*--------------------------------------------------------------------*
:* Declare and initialize RPF variables and set the appropriate proc- *
:* essing options.                                                    *
:*--------------------------------------------------------------------*
SET MODE B
DECLARE L1<100> PFGO<3> C1RCMD C1RMSG LOGPFX STGPFX PNLPFX
DECLARE CCREC<10> BRDSN BRMEM SUB JCL1 JCL2 BATCHFLG ATTPARM<2> REC
LET PFGO<1>='PF3/PF15'
LET PFGO<2>=PF3
LET PFGO<3>=PF15
LET PF3 = PF15 = 'GO'
LET LOGPFX=S.PREFIX
SET ATTN OFF
SET ESCAPE OFF
SET RPFEXIT OFF
SET ATTACH NOPAUSE
LET P1 = S.CMDLINES
SET CMDLINES 1
SET MONLEVEL ERROR
SET MSGLEVEL ERROR
SET SUBMIT INCLUDE
TRAP
DELETE C1RMSGS               :Delete the existing C1RMSGS member
DIVERT WTP MEM C1RMSGS       :Route WTP messages to the C1RMSGS member
:*--------------------------------------------------------------------*
:* Invoke the ENDEVOR/ROSCOE dialog driver routine, C1RPUSER.         *
:*--------------------------------------------------------------------*
TRAP
+CALL C1RPUSER ~+A1+~
TRAP OFF
LOOP
IF STGPFX LT 'a'
   LET STGPFX=S.PREFIX
ENDIF
: *-------------------------------------------------------------------*
: * Note: when S.ETSSTAT = 2, the program is suspended.               *
: *-------------------------------------------------------------------*
  WHILE S.TC EQ 0 AND S.ETSSTAT EQ 2
: *-------------------------------------------------------------------*
: * Field S.RC will contain the SUSPEND code issued by C1RPUSER.  Use *
: * the suspend code to determine the action to be performed.         *
: *-------------------------------------------------------------------*
   SELECT FIRST
:*--------------------------------------------------------------------*
:* S.RC=601: Attach a spooled member                                  *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 601
      SET DISPLAY LIB NONUM
      LET ATTPARM<1> = 'BROWSE'
      LET ATTPARM<2>='N NEXT FIR FIRST LAS LAST PREV INCL EXCL '
      LET P3 = TRIM(STGPFX ' ')|'.$BRLM'|S.PREFIX
+     ATTACH +P3+
:*--------------------------------------------------------------------*
:* S.RC=602: Browse a spooled member                                  *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 602
      DO <<BREDIT>>
:*--------------------------------------------------------------------*
:* S.RC=603: Delete a spooled member                                  *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 603
      LET P3 = TRIM(STGPFX ' ')|'.$BRLM'|S.PREFIX
+     DELETE +P3+
      SET DISPLAY LIB NUM
:*--------------------------------------------------------------------*
:* S.RC=604: Get profile information                                  *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 604
      DELETE                                 :Clear the AWS
      TRAP
+     FETCH +S.PREFIX+.$NDVRPRO              :Fetch the profile member
      TRAP OFF
      IF S.TC EQ 0 AND S.AWSCOUNT GE 3
        TOP
        READ AWS 1   REC                     :Read the
        READ AWS 2   JCL1                    : three profile
        READ AWS 3   JCL2                    :  records
      ELSE
        LET REC = ' '                        :No profile. Initialize
        LET JCL1 = ' '                       : the records to
        LET JCL2 = ' '                       :  blanks
      ENDIF
      DELETE                                 :Clear the AWS
:*--------------------------------------------------------------------*
:* S.RC=605: Save profile information                                 *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 605
      DELETE                                 :Clear the AWS
      WRITE AWS 1 REC
      WRITE AWS 2 JCL1
      WRITE AWS 3 JCL2
      +UPDATE +S.PREFIX+.$NDVRPRO 'ENDEVOR/ROSCOE User profile' SHARED
      DELETE                                 :Clear the AWS
:*--------------------------------------------------------------------*
:* S.RC=606: Browse a data set                                        *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 606
      LET ATTPARM<1> = 'BROWSE'
      LET ATTPARM<2>='N NEXT FIR FIRST LAS LAST PREV INCL EXCL '
      LOOP
          IF TRIM(BRDSN) EQ 'ROSCOE'
    +       ATTACH +BRMEM+
          ELSE
    +       ATTACH D +TRIM(BRDSN)+(+TRIM(BRMEM)+)
          ENDIF
          DO <<BREDIT>>
        WHILE S.AID EQ 'CLEAR'
      ENDLOOP
      TRAP
      DET DSN
      TRAP OFF
:*--------------------------------------------------------------------*
:* S.RC=607: Validate a data set                                      *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 607
      LET BRDSN = TRIM(BRDSN)
      LET BRMEM = TRIM(BRMEM)
      IF BRDSN EQ 'ROSCOE'
        IF CONFORM(BRMEM 'M') EQ 1
          LET S.RC=2
        ELSE
          IF LENGTH(BRMEM) EQ 0 OR INDEX(BRMEM '*') NE 0
            LET S.RC=8
          ELSE
            LET S.RC=505
          ENDIF
        ENDIF
      ELSE
:* P2305  DO ATTACH FOR LIBR TEST                                :P2305
        TRAP                                                     :P2305
+        ATTACH DSN +BRDSN+ NODSPLY                              :P2305
        TRAP OFF                                                 :P2305
        TRAP
+       INFO D +BRDSN+ NODSPLY
        TRAP OFF
        IF S.TC EQ 0 AND D.DSORG NE 'UPDATE'
          IF D.DSORG EQ 'PS' AND D.ALIB NE 1                     :P2305
            IF LENGTH(BRMEM) EQ 0
              LET S.RC=1
            ELSE
              LET S.RC=500
            ENDIF
          ELSE
            IF D.DSORG EQ 'PO' OR D.DSORG EQ 'DA' OR D.ALIB EQ 1 :P2305
              IF LENGTH(BRMEM) EQ 0 OR INDEX(BRMEM '*') NE 0
                LET S.RC=4
              ELSE
                IF CONFORM(BRMEM 'M') EQ 1
                  LET S.RC=1
                ELSE
                  LET S.RC=501
                ENDIF
              ENDIF
            ELSE
              LET S.RC=502
            ENDIF
          ENDIF
        ELSE
          LET S.RC=503
        ENDIF
      ENDIF
:*--------------------------------------------------------------------*
:* S.RC=608: Write an SCL request                                     *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 608
      LOOP SUB FROM 1 TO 10 BY 1
        IF SUBSTR(CCREC<SUB>,1,20) NE '                    '
          IF SUBSTR(CCREC<SUB>,1,20) NE '  OPTIONS           '
            WRITE AWS B CCREC<SUB>
          ENDIF
        ENDIF
      ENDLOOP
:*--------------------------------------------------------------------*
:* S.RC=609: Update a request dataset                                 *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 609
      IF S.AWSCOUNT GT 0
        LET BRDSN = TRIM(BRDSN)
        LET BRMEM = TRIM(BRMEM)
        IF BATCHFLG EQ 'Y'
          DO <<COPYMEM>>
        ENDIF
        DO <<UPDTMEM>>
      ENDIF
:*--------------------------------------------------------------------*
:* S.RC=610: Edit a request dataset                                   *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 610
      LET BRDSN = TRIM(BRDSN)
      LET BRMEM = TRIM(BRMEM)
      IF BRMEM EQ '$INCL'|S.PREFIX
        LET BRMEM=TRIM(STGPFX ' ')|'.'|BRMEM
      ENDIF
      DELETE
      DO <<COPYMEM>>
      LET LASTMEM=''
      LET ATTPARM<1>='EDIT'
      LET ATTPARM<2>='N NEXT FIR FIRST LAS LAST PREV INCL EXCL E I '
      LOOP
          IF S.AWSCOUNT EQ 0
            WRITE AWS T
              '//* The data set does not exist. You may edit this'
              '//*                                               '
              '//*                                               '
              '//*                                               '
            ENDWRITE
          ENDIF
          ATTACH
          DO <<BREDIT>>
        WHILE S.AID EQ 'CLEAR'
      ENDLOOP
      IF S.AWSCOUNT GT 0
        DO <<UPDTMEM>>
      ENDIF
:*--------------------------------------------------------------------*
:* S.RC=611: Submit a request dataset                                 *
:* Because ENDEVOR/MVS cannot directly access a ROSCOE library, one   *
:* or more pre- or post- processing steps must be added to the        *
:* ENDEVOR batch execution JCL in order to overcome this limitation.  *
:* If the SCL contains an ADD action and the element source is from   *
:* a ROSCOE library, one or more steps are added to use the ROSCOPY   *
:* utility to copy the ROSCOE member into an OS PDS.  The ADD action  *
:* SCL will be modified to read from the dataset.  This processing is *
:* performed by the NDVRROSC RPF.  If the SCL contains a RETIREVE     *
:* action and the target of the RETRIEVE is an ROSCOE library, a      *
:* step will be added after the execution of C1BM3000 to use the      *
:* ROSDATA utility to copy the retrieved element from a temporary     *
:* PDS into the appropriate ROSCOE library.  This processing is       *
:* performed within this RPF.                                         *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 611
      LET P4 = 'N'                     :Indicate no RETRIEVE SCL
      LET P5 = 'N'                     :Indicate no Skeleton found
      LET BRDSN = TRIM(BRDSN)
      LET BRMEM = TRIM(BRMEM)
:     *---------------------------------------------------------------*
:     * Copy the SCL statements to the AWS.  Call RPF NDVRROSC to     *
:     * scan the SCL and make the changes necessary for the RETRIEVE  *
:     * action.                                                       *
:     *---------------------------------------------------------------*
      DELETE                           :Clear the AWS
      DO <<COPYMEM>>                   :Copy the SCL to the AWS
      IF S.TC NE 0
         LET S.RC = 12
         GOTO <<EXIT611>>
      ENDIF
      +EXEC +PROGPFX+.NDVRROSC         :CALL THE SCL CONVERTER
:     *---------------------------------------------------------------*
:     * Write the JCL JOB card statements                             *
:     *---------------------------------------------------------------*
      WRITE AWS T
        P.JCL1
        P.JCL2
        P.JCL3
        P.JCL4
      ENDWRITE
:     *---------------------------------------------------------------*
:     * Delete any of the JOB card statements that do not contain an  *
:     * '/' in the first column.  This will remove blank (null) JOB   *
:     * card statements.                                              *
:     *---------------------------------------------------------------*
      TRAP
      DELETEX 1 1 '/' 1 4
      TRAP OFF
:     RENUMBER FROM 5 START 500000 100                     : C9225300
:     *---------------------------------------------------------------*
:     * Attach the System Profile member.  The first record of the    *
:     * profile is the name of the batch SCL dataset name.  Copy the  *
:     * JCL from the batch SCL dataset into the AWS.                  *
:     *---------------------------------------------------------------*
      TRAP
      +ATTACH +TRIM(PNLPFX)+.$SYSPROF
:     ATTACH +S.PREFIX+.$SYSPROF
      TRAP OFF
      IF S.TC EQ 0
        READ LIB * REC                        :Read the skeleton DSName
        TRAP
        +ATTACH DSN +REC+
        TRAP OFF
        IF S.TC EQ 0
          CS D 1 2 '//' 899000
          D D
          LET P5 = 'Y'                        :Indicate skeleton found
        ELSE
          LET P.MSG='Skeleton data set not found'
        ENDIF
      ELSE
        LET P.MSG='System profile member not found'
      ENDIF
:     *---------------------------------------------------------------*
:     * Execute the following ONLY if the skeleton JCL was found.     *
:     *---------------------------------------------------------------*
      IF P5 EQ 'Y'                            :Only if a skeleton
:       *-----------------------------------------------------------*
:       * If the INCLUDE JCL flag is set to Y then copy the JCL to  *
:       * be included to the execution JCL.                         *
:       *-----------------------------------------------------------*
        IF BATCHFLG EQ 'Y'
          LET P3 = TRIM(STGPFX ' ')|'.$INCL'|S.PREFIX
          TRAP
          +COPY +P3+ B
          TRAP OFF
        ENDIF
:       *--------------------------------------------------------------*
:       * If the SCL contains the DDNAME ROSCOER clause then a Retrieve*
:       * to a ROSCOE dataset is requested.  JCL is inserted after the *
:       * execution of C1BM3000 to invoke the ROSCOPY utility to       *
:       * create a ROSCOE member from the retrieved element.           *
:       *--------------------------------------------------------------*
        TRAP
        FIRST AWS /TO DDNAME ROSCOER/
        TRAP OFF
        IF S.TC EQ 0
:         *------------------------------------------------------------*
:         * If a ROSDATA step has not already been created, add the    *
:         * step to the JCL.                                           *
:         *------------------------------------------------------------*
          IF P4 EQ 'N'
            WRITE AWS B
              '//*-------------------------------------------------* '
              '//* THE FOLLOWING JCL MUST BE CUSTOMIZED BY THE     * '
              '//* INSTALLATION.  VERIFY THAT THE CORRECT ROSLIBXX * '
              '//* STATEMENTS HAVE BEEN SPECIFIED.                 * '
              '//*-------------------------------------------------* '
   '//ROSDATA  EXEC PGM=ROSDATA,PARM=''' | S.KEY | ''',COND=(4,LT)   '
        '//STEPLIB  DD DISP=SHR,DSN=ROSCOE.ROXXLIB                   '
        '//ROSLIB00 DD DISP=SHR,DSN=ROSCOE.ROSLIB00                  '
        '//ROSLIB01 DD DISP=SHR,DSN=ROSCOE.ROSLIB01                  '
        '//ROSLIB02 DD DISP=SHR,DSN=ROSCOE.ROSLIB02                  '
        '//ROSLIB03 DD DISP=SHR,DSN=ROSCOE.ROSLIB03                  '
              '//SYSPRINT DD  SYSOUT=*                               '
            ENDWRITE
            LET P4 = 'Y'        :Indicate a ROSDATA step has been added
          ENDIF
          LET P3 = TRIM(STGPFX ' ')|'.$NDVR$$$'
          +EXEC +PROGPFX+.NDVRRETV
          IF R1 GE 8                                            :P2313
           LET P.MSG = 'MEMBER '| R2 | ' ALREADY EXISTS,  --    :P2313
             AND REPLACE NOT SPECIFIED.'                        :P2313
             GOTO <<EXIT611>>                                   :P2313
          ENDIF                                                 :P2313
          WRITE AWS B
            '//*                                                     '
            '//STEPDRET EXEC PGM=IEFBR14                             '
            '//DD01     DD   DSN=&&NDVRRET,                          '
            '//           DISP=(OLD,DELETE,DELETE)                   '
          ENDWRITE
          TRAP
        ENDIF
:       *-----------------------------------------------------------*
:       * Submit the job for execution and write the JOB SUBMITTED  *
:       * message.                                                  *
:       *-----------------------------------------------------------*
        TRAP
        SUB                                :Submit the JCL
        TRAP OFF
        LET P.MSG=SUBSTR(LASTERR,1,INDEX(LASTERR,'<')-1)
:       *-----------------------------------------------------------*
:       * Clear the AWS contents.                                   *
:       *-----------------------------------------------------------*
        DELETE
      ENDIF
<<EXIT611>>
:*--------------------------------------------------------------------*
:* S.RC=612: Process the system profile                               *
:*--------------------------------------------------------------------*
    WHEN S.RC EQ 612
      TRAP
:     *---------------------------------------------------------------*
:     * Attach the current profile dataset and read the first (only)  *
:     * record in the file.  This should be the name of the dataset   *
:     * that contains the ENDEVOR batch execution JCL.                *
:     *---------------------------------------------------------------*
      +ATTACH +TRIM(PNLPFX)+.$SYSPROF
:     +ATTACH +S.PREFIX+.$SYSPROF
      TRAP OFF
      IF S.TC EQ 0
        READ LIB * REC
      ELSE
        LET REC = ''
      ENDIF
      LET REC=PAD(REC 52)
:     *---------------------------------------------------------------*
:     * Activate and display the System Profile entry panel.          *
:     *---------------------------------------------------------------*
+     PANEL ACTIVATE +TRIM(PNLPFX)+.C1RLM062
      LET P.DSNAME = REC
      PANEL SEND
<<ERR612>>
:     *---------------------------------------------------------------*
:     * Attach the dataset specified by the user.  If the dataset is  *
:     * invalid, stack an error message and redisplay the System Pro- *
:     * file entry panel                                              *
:     *---------------------------------------------------------------*
      IF S.AID NE 'CLEAR'
        TRAP
+       ATTACH D +P.DSNAME+
        TRAP OFF
        IF S.TC EQ 0
          D D
        ELSE
          LET P.MSG = 'Invalid DSN:'|SUBSTR(LASTERR,1,60)
          PANEL RESEND
          GOTO <<ERR612>>
        ENDIF
:     *---------------------------------------------------------------*
:     * Write the Batch JCL dataset name to the AWS and save the      *
:     * AWS as member $SYSPROF.                                       *
:     *---------------------------------------------------------------*
        WRITE AWS T P.DSNAME
+ UPDATE +TRIM(PNLPFX)+.$SYSPROF 'ENDEVOR/ROSCOE System profile' SHARED
        DELETE
      ENDIF
:*--------------------------------------------------------------------*
:* Unmatched suspend code.                                            *
:*--------------------------------------------------------------------*
    WHEN NONE
      RESPONSE 'C1RPUSER application suspended with code='|S.RC
      PAUSE
   ENDSEL
:*--------------------------------------------------------------------*
:* Processing of the suspend operation is complete.  Return to        *
:* C1RPUSER.                                                          *
:*--------------------------------------------------------------------*
   TRAP
   RESUME ETSO
   TRAP OFF
ENDLOOP
:*--------------------------------------------------------------------*
:* The main processing loop has terminated.                           *
:*--------------------------------------------------------------------*
+ SET CMDLINES +P1+
IF LOGPFX NE ''
  SELECT
  WHEN S.TC NE 0
    LET C1RMSG=SUBSTR(LASTERR,1,INDEX(LASTERR,'<')-1)
+   SEND PFX=+LOGPFX+ ~+C1RMSG+ - TC=+TC+~
    WRITE C1RMSG|' - TC='|TC
  WHEN S.RC NE 0
    TRAP
    COPY C1RMSGS 1 1 T
    TRAP OFF
    IF S.TC EQ 0
      READ AWS * C1RMSG
  +   SEND C1RMSGS PFX=+LOGPFX+ ~+C1RMSG+ - RC=+RC+~
    ENDIF
  WHEN ANY
    RESPONSE 'Error during ENDEVOR/ROSCOE processing.  RC='|RC
  ENDSEL
ENDIF
:SET ATTACH PAUSE
TRAP
ATTACH C1RMSGS
TRAP OFF
LET PF3 = PFGO<2>
LET PF15 = PFGO<3>
POP
RETURN
:*--------------------------------------------------------------------*
:* <<BREDIT>>: Local routine to browse/edit a ROSCOE member           *
:*--------------------------------------------------------------------*
<<BREDIT>> PROC
  RESPONSE ATTPARM<1>|' Requested entity.  Press '|PFGO<1>|' to resume'
  LOOP
    READ C1RCMD
  WHILE INDEX(PFGO<1> S.AID) EQ 0 AND S.AID NE 'CLEAR'
    IF LENGTH(C1RCMD) GT 0
      LET C1RCMD=C1RCMD|' '
      IF INDEX(ATTPARM<2> SUBSTR(C1RCMD 1 INDEX(C1RCMD ' '))) NE 0
        TRAP
    +   +C1RCMD+
        TRAP OFF
        IF S.TC NE 0
          LET C1RMSG=SUBSTR(LASTERR,1,INDEX(LASTERR,'<')-1)
          IF SUBSTR(C1RMSG,1,5) EQ 'CMD20'
            LET C1RMSG=C1RMSG|'- All string operands must have delimiters'
          ENDIF
          LET CMDLINE<1>=C1RCMD
          RESPONSE C1RMSG
        ENDIF
      ELSE
        RESPONSE 'C1R01 Valid commands are: '|ATTPARM<2>
      ENDIF
    ENDIF
  ENDLOOP
ENDPROC
:*--------------------------------------------------------------------*
:* <<COPYMEM>>: Local routine to copy a dataset or member to the AWS. *
:*--------------------------------------------------------------------*
<<COPYMEM>> PROC
  IF BRDSN EQ 'ROSCOE'
    TRAP
    +COPY +BRMEM+ T
    TRAP OFF
    IF S.TC NE 0
      LET P.MSG = 'Unable to read the SCL member '
    ENDIF
  ELSE
    TRAP
    IF LENGTH(BRMEM) GT 0
      +ATTACH DSN +BRDSN+(+BRMEM+)
    ELSE
      +ATTACH DSN +BRDSN+
    ENDIF
    TRAP OFF
    IF S.TC EQ 0
      COPY DSN T
      D D
    ELSE
      LET P.MSG = 'Unable to read the SCL dataset'
    ENDIF
  ENDIF
ENDPROC
:*--------------------------------------------------------------------*
:* <<UPDTMEM>>: Local routine to update a dataset or a ROSCOE member. *
:*--------------------------------------------------------------------*
<<UPDTMEM>> PROC
  IF BRDSN EQ 'ROSCOE'
+   UPDATE +BRMEM+ SHARED
  ELSE
    IF LENGTH(BRMEM) GT 0
+     EXP DSN=+BRDSN+(+BRMEM+)
    ELSE
+     EXP DSN=+BRDSN+
    ENDIF
    IF S.RC NE 0
      WRITE 'Error '|RC|' exporting request dataset '|BRDSN
      WRITE LASTERR
      PAUSE
    ENDIF
  ENDIF
  DELETE
ENDPROC
