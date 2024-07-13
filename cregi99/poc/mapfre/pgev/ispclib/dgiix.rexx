        /***************************************************************
        /*   SCREEN  DEFINITION  FACILITY II MVS  -  RELEASE 3 LEVEL 0
        /*        LICENSED MATERIAL - PROGRAM  PROPERTY OF IBM
        /*         5665-366 (C) COPYRIGHT IBM CORP. 1987, 1992.
        /*                      ALL RIGHTS RESERVED.
        /**************************************************************/
        PROC 0                      /*                              */+
          UNIT()                    /* UNIT OF INPUT DATA SET       */+
          VOL()                     /* VOL OF INPUT DATA SET        */+
          LANGUAGE()                /* LANGUAGE TO BE USED          */+
          TRACE(OFF)                /* TRACE SETTING                */+
          DEBUG                     /* RUN IN DEBUG MODE            */+
        /************************************************************/
        /*                                                          */
        /*  SDF II MVS                                              */
        /*                                                          */
        /*  DGIIX - INVOKE SDF II VIA THE INVOCATION INTERFACE      */
        /*                                                          */
        /*  *** NOTE ***                                            */
        /*  WHEN MAKING ANY CHANGES TO THIS CLIST, YOU SHOULD       */
        /*  LEAVE COLUMNS 1-8 AND COLUMNS 73-LRECL BLANK.  THAT     */
        /*  WILL ALLOW THIS CLIST TO BE RUN FROM A PDS WITH         */
        /*  RECFM=F OR RECFM=V.                                     */
        /*                                                          */
        /*  PARAMETERS AND OPTIONS:                                 */
        /*    DSN      - THE INPUT DATA SET.  FORMAT OF EACH        */
        /*               RECORD IS "COLUMN = VALUE".                */
        /*    UNIT     - UNIT OF INPUT DATA SET                     */
        /*    VOL      - VOLSER OF INPUT DATA SET                   */
        /*    LANGUAGE - THE LANGUAGE THAT IS TO BE USED            */
        /*               THE POSSIBLE LANGUAGES ARE                 */
        /*               ENGLISH, JAPANESE, GERMAN, SWISS AND       */
        /*               SPANISH,                                   */
        /*               THE CORRESPONDING PARAMETER VALUES ARE     */
        /*               EU, JN, DU, DS, EP                         */
        /*    TRACE    - INITIAL TRACE SETTING. OFF, ON OR ALL
        /*    DEBUG    - RUN IN DEBUG MODE (CONTROL LIST CONLIST).  */
        /*                                                          */
        /*  RETURN CODES:                                           */
        /*    0     - NORMAL COMPLETION                             */
        /*    12    - ERROR (MESSAGE DISPLAYED ON TERMINAL)         */
        /*    OTHER - RETURN CODE FROM SDF II                       */
        /*                                                          */
        /* CHANGE ACTIVITY:                                         */
        /************************************************************/

        /*----------------------------------------------------------*/
        /* INITIALIZE                                               */
        /*----------------------------------------------------------*/
        SET DEBUG = DEBUG
        CONTROL MAIN MSG            /* THIS IS MAIN COMMAND PROC.   */
        IF &DEBUG = DEBUG THEN      /* IF DEBUG OPTION SPECIFIED    */+
          CONTROL LIST CONLIST      /* DISPLAY CMDS AND STATEMENTS  */
        ERROR                       /* ERROR ROUTINE                */+
          DO                        /*                              */
            SET CC = &LASTCC        /* SAVE RETURN CODE             */
            IF (&CC>=800) &&        /* IF ERROR IS FROM CLIST       */+
               (&CC<=999) THEN      /*     INTERPRETER              */+
              GOTO ERR99            /* GO ISSUE ERROR MESSAGE       */
            ELSE                    /* SOME OTHER ERROR             */+
              GOTO LEAVE            /* RETURN TO NEXT STMT @BA57253C*/
          END                       /*                              */
        IF &SYSISPF ^= &STR(ACTIVE) THEN                              +
          GOTO ERR10                /* GO ISSUE ERROR MESSAGE       */
        SET TABLE = DGIIFTAB        /* FUNCTION TABLE NAME          */
        SET NAMES =                 /* COLUMN NAMES                 */+
          &STR(NAMES(+
            IIVROW   +
            IIVREQ   +
            IIVNAM   +
            IIVTYP   +
            IIVLIB   +
            IIVONAM  +
            IIVOLIB  +
            IIVDEV   +
            IIVMOD   +
            IIVPRO   +
            IIVRETC  +
            ))

        /*----------------------------------------------------------*/
        /* ALLOCATE AND OPEN INPUT DATA SET                         */
        /*----------------------------------------------------------*/

/*      CONTROL NOMSG                  TEMPORARILY TURN OFF MSGS    */
/*      FREE DATASET(&DSN)             FREE INPUT DATA SET          */
/*      CONTROL MSG                    RESTORE MSGS                 */
        SET UN = &STR()
        IF &STR(&UNIT) ^= &STR() THEN                                 +
          SET UN = &STR(UNIT(&STR(&UNIT)))
        SET VO = &STR()
        IF &STR(&VOL) ^= &STR() THEN                                  +
          SET VO = &STR(VOL(&STR(&VOL)))
/*      ALLOCATE                       ALLOCATE INPUT DATA SET      */+
/*        DDNAME(DGIIX)                                             */+
/*        DATASET(&DSN) &UN &VO                                     */+
/*        SHR                                                       */+
/*        REUSE                                                     */
/*      SET CC = &LASTCC               SAVE RETURN CODE             */
/*      IF &CC^=0 THEN                 IF ALLOCATE FAILED           */+
/*        GOTO ERR00                   GO ISSUE ERROR MESSAGE       */
        OPENFILE DGIIX              /* OPEN INPUT DATA SET          */
        SET CC = &LASTCC            /* SAVE RETURN CODE             */
        IF &CC^=0 THEN              /* IF OPEN FAILED               */+
          DO                        /*                              */
            FREE DDNAME(DGIIX)      /* FREE THE DATA SET            */
            GOTO ERR00              /* GO ISSUE ERROR MESSAGE       */
          END                       /*                              */

        /*----------------------------------------------------------*/
        /* READ INPUT DATA SET. SAVE COLUMN VALUES IN VARIABLES     */
        /* "CCCCCRRR" WHERE "CCCCC" IS COLUMN NAME (WITHOUT THE     */
        /* 'IIV' PREFIX) AND "RRR" IS THE ROW NUMBER.               */
        /*----------------------------------------------------------*/

        SET I = 0                   /* INIT RECORD NUMBER           */
        SET NEWROW = YES            /* CAUSE NEW ROW TO BE INIT'ED  */
        DO WHILE 0 = 0              /* DO UNTIL END-OF-FILE         */

          /*--------------------------------------------------------*/
          /* IF THIS IS NEW ROW, SET COLUMNS TO DEFAULT VALUES      */
          /*--------------------------------------------------------*/

        ITERATE:                    /*                              */+
          IF &NEWROW=YES THEN       /* IF THIS IS NEW TABLE ROW     */+
            DO                      /*                              */
              SET I = &I + 1        /* BUMP TO NEXT RECORD          */
              DO WHILE &LENGTH(&STR(&I))<3  /* PAD RECORD NUMBER    */
                SET I = 0&STR(&I)   /* WITH LEADING ZEROS           */
              END                   /*                              */
              SET NUM&I  = 0
              SET NEWROW = NO       /* DON'T INIT NEW ROW           */
            END                     /*                              */

          /*--------------------------------------------------------*/
          /* READ NEXT RECORD OF INPUT DATA SET                     */
          /*--------------------------------------------------------*/

          GETFILE DGIIX             /* READ NEXT RECORD             */
          SET CC = &LASTCC          /* SAVE RETURN CODE             */
          IF &CC^=0 THEN            /* IF READ FAILED               */+
            IF &CC=400 THEN         /* IF END-OF-FILE               */+
              GOTO LEAVE            /* EXIT READ LOOP               */
            ELSE                    /* SOME OTHER READ ERROR        */+
              GOTO ERR02            /* GO ISSUE ERROR MESSAGE       */
          ELSE                      /* READ WAS SUCCESSFUL          */

          /*--------------------------------------------------------*/
          /* REMOVE SEQUENCE NUMBER AND DISPLAY RECORD AT TERMINAL  */
          /*--------------------------------------------------------*/

          IF &LENGTH(&STR(&DGIIX))>8 THEN  /* IF RECORD COULD       */+
                                    /* HAVE A SEQUENCE NUMBER       */+
            SET L = &LENGTH(&STR(&DGIIX)) - 8  /* LAST DATA         */+
                                    /* POSITION IS BEFORE SEQ. NO.  */
          ELSE                      /* NOT ENOUGH ROOM FOR SEQ. NO. */+
            SET L = &LENGTH(&STR(&DGIIX))  /* LAST DATA POSITION    */+
                                    /* IS END OF RECORD             */
          SET SYSDVAL =             /* COPY DATA SET RECORD         */+
            &SUBSTR(1:&L,&STR(&DGIIX))  /* WITHOUT SEQUENCE NUMBER  */

          /*--------------------------------------------------------*/
          /* GET THE TOKENS IN THE RECORD, CHECK FOR VALIDITY       */
          /*--------------------------------------------------------*/

          READDVAL T1 T2 T3 T4      /* GET TOKENS                   */
          SET COL = &STR(&T1)       /* GET COLUMN NAME              */
          IF &STR(&COL)=&STR(*) THEN  /* IF IT'S END-OF-RECORD      */+
                                    /* MARKER                       */+
            DO                      /*                              */
              SET NEWROW = YES      /* CAUSE NEW ROW TO BE INIT'ED  */
              GOTO ITERATE          /* ITERATE READ LOOP            */
            END                     /*                              */

          SET EQS = &STR(&T2)       /* GET EQUAL SIGN               */
          IF &STR(&EQS)^=&STR(=) THEN  /* IF IT'S NOT "="           */+
            GOTO ERR12              /* GO ISSUE ERROR MESSAGE       */

          SET VAL = &STR(&T3)       /* GET COLUMN VALUE             */

          SET REST = &STR(&T4)      /* GET REMAINING TOKENS (IF ANY)*/
          IF &STR(&REST)^=&STR() THEN  /* IF THEY'RE NOT BLANK      */+
            GOTO ERR13              /* GO ISSUE ERROR MESSAGE       */

          /*--------------------------------------------------------*/
          /* SET COLUMNS TO SPECIFIED VALUES                        */
          /*--------------------------------------------------------*/

          SET L = &LENGTH(&STR(&VAL))  /* SAVE LENGTH OF VALUE      */
          IF (&L=0) |               /* IF VALUE IS NULL             */+
             &STR(&VAL)=&STR('') THEN  /*                           */+
            SET VAL = &STR()        /* MAKE IT BLANK                */
          ELSE                      /* VALUE IS NOT NULL            */+
            IF &SUBSTR(1,&STR(&VAL))=&STR(") && /* IF VALUE IS      */+
                                    /* QUOTED                       */+
               &SUBSTR(&L,&STR(&VAL))=&STR(") THEN /*               */+
              SET VAL = &STR(&SUBSTR(2:&L-1,&STR(&VAL)))              +
                                    /* STRIP OFF QUOTES             */
          ELSE                      /* VALUE IS NOT NULL            */+
            IF &SUBSTR(1,&STR(&VAL))=&STR(') && /* IF VALUE IS      */+
                                    /* QUOTED                       */+
               &SUBSTR(&L,&STR(&VAL))=&STR(') THEN /*               */+
              SET VAL = &STR(&SUBSTR(2:&L-1,&STR(&VAL)))              +
                                    /* STRIP OFF QUOTES             */
            ELSE                    /* VALUE IS NOT QUOTED          */
          SET K = &&NUM&I
          SET J = &K + 1
          DO WHILE &LENGTH(&STR(&J))<3  /* PAD RECORD NUMBER        */
            SET J = 0&STR(&J)       /* WITH LEADING ZEROS           */
            END                     /*                              */
          SET ROW&I&J = &STR(&COL)
          SET J = &J + 1
          DO WHILE &LENGTH(&STR(&J))<3  /* PAD RECORD NUMBER        */
            SET J = 0&STR(&J)       /* WITH LEADING ZEROS           */
            END                     /*                              */
          SET ROW&I&J = &STR(&VAL)
          SET NUM&I = &K + 2        /* BUMP TO NEXT RECORD          */
        END                         /* END READ LOOP                */
        LEAVE:                      /*                              */+
        CLOSFILE DGIIX              /* CLOSE THE INPUT DATA SET     */
        FREE DDNAME(DGIIX)          /* FREE THE INPUT DATA SET      */

        /*----------------------------------------------------------*/
        /* BUILD TABLE                                              */
        /*----------------------------------------------------------*/

        ISPEXEC CONTROL ERRORS RETURN  /* RETURN TO CLIST ON ERRORS */
        ISPEXEC TBCREATE &TABLE     /* CREATE THE TABLE             */+
          &NAMES                    /*                              */+
          NOWRITE                   /* SAVE OR DON'T SAVE TABLE     */+
          REPLACE                   /*                              */
        SET CC = &LASTCC            /* SAVE RETURN CODE             */
        IF &CC>4 THEN               /* IF CREATE FAILED             */+
          GOTO ERR01                /* GO ISSUE ERROR MESSAGE       */
        SET J = 1                   /* INIT COUNTER                 */
        SET I = &I                  /* GET RID OF LEADING ZEROS     */
        DO WHILE &J <= &I           /* FOR EACH ROW OF TABLE        */
          DO WHILE &LENGTH(&STR(&J))<3  /* PAD WITH LEADING ZEROS   */
            SET J = 0&STR(&J)       /*                              */
          END                       /*                              */
          SET IIVROW = &STR(V)      /* INITIALIZE FIELDS             */
          SET IIVREQ = &STR()       /*                               */
          SET IIVNAM = &STR()       /*                               */
          SET IIVTYP = &STR()       /*                               */
          SET IIVLIB = &STR()       /*                               */
          SET IIVONAM = &STR()      /*                               */
          SET IIVOLIB = &STR()      /*                               */
          SET IIVDEV = &STR()       /*                               */
          SET IIVMOD = &STR()       /*                               */
          SET IIVPRO = &STR(G)      /*                               */
          SET IIVRETC = &STR()      /*                               */
          /* SET COLUMNS TO VALUES SPECIFIED IN INPUT DATA SET      */
          SET K = 1
          SET KE = &&NUM&J
          SET ENAM = &STR()
          DO WHILE &K <= &KE
            DO WHILE &LENGTH(&STR(&K))<3  /* PAD WITH LEADING ZEROS */
              SET K = 0&STR(&K)     /*                              */
            END                     /*                              */
            SET VAR      = &STR(&&ROW&J&K)  /* BUILD VARIABLE NAME  */
            IF &SUBSTR(1:3,&STR(&VAR)) ^= &STR(IIV) THEN              +
              SET ENAM = &STR(&ENAM &VAR)
            SET K = &K + 1
            DO WHILE &LENGTH(&STR(&K))<3  /* PAD WITH LEADING ZEROS */
              SET K = 0&STR(&K)     /*                              */
            END                     /*                              */
            SET VALUE    = &STR(&&ROW&J&K)
            SET K = &K + 1
            SET &&VAR = &STR(&VALUE)
            END
          IF &STR(&ENAM) ^= &STR() THEN                               +
            SET ENAM = &STR(SAVE(&STR(&ENAM)))
          ISPEXEC TBADD &TABLE &ENAM  /* ADD THE ROW                */
          SET CC = &LASTCC          /* SAVE RETURN CODE             */
          IF &CC>0 THEN             /* IF ERROR OCCURRED            */+
            GOTO ERR03              /* GO ISSUE ERROR MESSAGE       */
          SET J = &J + 1            /* BUMP ROW COUNT               */
        END                         /* END TABLE BUILD LOOP         */

        /*----------------------------------------------------------*/
        /* CALL SDF II                                              */
        /*----------------------------------------------------------*/
        SET TRACE = I
        ISPEXEC SELECT CMD(%SDF2INV REQUEST(SDF2I) +
                           LANGUAGE(&LANGUAGE) +
                           TRACE(&TRACE)) NEWAPPL /*                */
        SET RC = &LASTCC            /* SAVE RETURN CODE             */
        ISPEXEC TBEND &TABLE        /* SAVE OR PURGE TABLE          */
        EXIT CODE(&RC)              /* RETURN TO CALLER             */

        /*----------------------------------------------------------*/
        /* ERROR MESSAGES                                           */
        /*----------------------------------------------------------*/

        ERR00: +
        WRITE RETURN CODE &CC ALLOCATING OR OPENING DATA SET &DSN..
        GOTO ERREXIT

        ERR01: +
        WRITE RETURN CODE &CC FROM TBCREATE &TABLE..
        GOTO ERREXIT

        ERR02: +
        WRITE RETURN CODE &CC READING DATA SET &DSN..
        GOTO CLEANUP

        ERR03: +
        WRITE RETURN CODE &CC FROM TBADD &TABLE..
        GOTO ERREXIT

        ERR10: +
        WRITE
        WRITE INVOKE THIS CLIST FROM ISPF/PDF OPTION 6, OR USE THE
        WRITE ISPSTART COMMAND.  THE SYNTAX IS:
        WRITE
        WRITE   ISPSTART CMD(DGIIX DSN(INPUT-DATA-SET))
        GOTO ERREXIT

        ERR11: +
        WRITE DATA IN DATA SET &DSN HAS AN UNEXPECTED FORMAT:
        WRITE '&STR(&COL)' IS NOT A VALID COLUMN NAME.
        GOTO CLEANUP

        ERR12: +
        WRITE DATA IN DATA SET &DSN HAS AN UNEXPECTED FORMAT:
        WRITE THERE IS NO EQUAL SIGN (=) FOLLOWING THE COLUMN NAME.
        GOTO CLEANUP

        ERR13: +
        WRITE DATA IN DATA SET &DSN HAS AN UNEXPECTED FORMAT:
        WRITE THERE ARE EXTRA PARAMETERS AFTER THE COLUMN VALUE.
        GOTO CLEANUP

        ERR99: +
        IF &CC=900 THEN             /* IF AMPERSAND IN INPUT DATA   */+
          WRITE AMPERSANDS MAY NOT BE USED IN ANY INPUT DATA.
        ELSE                        /* SOME OTHER ERROR             */+
          DO                        /*                              */
            WRITE ERROR IN &SYSICMD CLIST:
            WRITE RETURN CODE &CC FROM CLIST INTERPRETER.
          END                       /*                              */
        GOTO ERREXIT

        CLEANUP: +
        CLOSFILE DGIIX              /* CLOSE THE INPUT DATA SET     */
        FREE DDNAME(DGIIX)          /* FREE THE INPUT DATA SET      */
        GOTO ERREXIT

        ERREXIT: +
        WRITE
        EXIT CODE(12)               /* RETURN TO CALLER             */
        END                         /* END CLIST                    */
