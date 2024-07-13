/* REXX                                                              */
/*-------------------------------------------------------------------*/
/*                                                                   */
/* Copyright (C) 2022 Broadcom. All rights reserved.                 */
/*                                                                   */
/* NAME: ENX#RX1                                                     */
/*                                                                   */
/* PURPOSE: Creates DELETE SCL for elements found in targets.        */
/*-------------------------------------------------------------------*/
  TRACE O
  Arg Req_Subsys Req_Userid Req_CCID;
  My_Rc = 4 ;

  /* Say "Your subsystem is"  Req_Subsys ; */

  "EXECIO * DISKR SCLIN    (STEM SCL. finis"
  "EXECIO * DISKR EXTRACTM (STEM API. finis"

  If API.0 = 0 Then Exit (4)

  Do r# = 1 to API.0
     ELEMENT      = STRIP(SUBSTR(API.r#,039,08));
     ENVIRON      = STRIP(SUBSTR(API.r#,015,08));
     SYSTEM       = STRIP(SUBSTR(API.r#,023,08));
     SUBSYS       = STRIP(SUBSTR(API.r#,031,08));
     IF SUBSYS = Req_Subsys THEN ITERATE ;
     STAGE        = STRIP(SUBSTR(API.r#,065,01));
     TYPE         = STRIP(SUBSTR(API.r#,049,08));
     From_Subsys  = STRIP(SUBSTR(API.r#,886,08));
     CCID         = Strip(Substr(API.r#,156,12));
     signout      = Strip(Substr(API.r#,95,8));

  /* Say ELEMENT"."ENVIRON"."STAGE"."SYSTEM"."SUBSYS,
         " came from subsys" From_Subsys,
         "("signout")" */

     If From_Subsys = Req_Subsys then,
        Do
        My_rc = 0;
        "EXECIO * DISKW SCLOUT   (STEM SCL. "
        Queue " DELETE ELEMENT  " ELEMENT
        Queue "     FROM ENVIRONMENT" ENVIRON "STAGE "STAGE
        Queue "       SYSTEM " SYSTEM "SUBSYSTEM " SUBSYS
        Queue "       TYPE   " TYPE "."
        "EXECIO" QUEUED() "DISKW SCLOUT  "
    /*  Say ELEMENT"."ENVIRON"."STAGE"."SYSTEM"."SUBSYS,
            " to be Deleted." */
        End; /* If From_Subsys = Req_Subsys */

  End;  /* Do r# = 1 to API.0 */

  "EXECIO 0 DISKW SCLOUT (FINIS "

  EXIT (My_Rc)

