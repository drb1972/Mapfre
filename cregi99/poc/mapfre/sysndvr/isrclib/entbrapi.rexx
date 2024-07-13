/* REXX */
trace O
/************************************************************/
/* Call the API utility program, ENTBJAPI, to build         */
/* a response file containing a list of all the systems     */
/* defined in stage 2 of environment env-name. The response */
/* records are written to 'uprfx.uqual.APIRSP' and the API  */
/* Execution Messages are written to 'uprfx.uqual.APIMSG'.  */
/************************************************************/
/************************************************************/
/* Note: Depending on how your site's installation, you     */
/*       may need to add additional statments to allocate   */
/*       the CONLIB and STEPLIB libraries. This procedure   */
/*       assumes the CONLIB and STEPLIB libraries are       */
/*       allocated prior to executing this REXX procedure.  */
/************************************************************/

/************************************************************/
/* Parameters                                               */
/************************************************************/
  p_envir  = "env-name"                     /* ENV name     */
  p_rspdsn = "'uprfx.uqual.APIRSP'"         /* Response DSN */
  p_msgdsn = "'uprfx.uqual.APIMSG'"         /* Message DSN  */

/************************************************************/
/* Allocate datasets                                        */
/************************************************************/
/* - Work Datasets            */
  "ALLOC DD(BSTAPI) DUMMY"
  "ALLOC DD(BSTERR) DUMMY"
  "ALLOC DD(SYSPRINT) DUMMY"
  "ALLOC DD(SYSOUT) DUMMY"

/* - Input for ENTBJAPI utility */
  "ALLOC DD(SYSIN) ",
  "SPACE(1 1) CYL UNIT(SYSDA) DSORG(PS) ",
  "LRECL(80) RECFM(F B)"

/* - API Message Dataset        */
  "DELETE" p_msgdsn
  "ALLOC DD(DDMSG) DSN("p_msgdsn") ",
  "SPACE(1 1) CYL UNIT(SYSDA) DSORG(PS) ",
  "LRECL(133) RECFM(F B)"

/* - API Response Dataset       */
  "DELETE" p_rspdsn
  "ALLOC DD(DDOUT) DSN("p_rspdsn") ",
  "SPACE(1 1) CYL UNIT(SYSDA) DSORG(PS) ",
  "LRECL(2048) RECFM(V B)"

/************************************************************/
/* Build AACTL Structure Control Record                     */
/************************************************************/
/* - AACTL Structure Layout */
/*   Keyword        CHAR 5  */
/*   Shutdown flag  CHAR 1  */
/*   MSG DDN        CHAR 8  */
/*   LIST DDN       CHAR 8  */
queue "AACTLYDDMSG   DDOUT   "

/************************************************************/
/* Build Request Structure Control Record                   */
/*  Note: Refer to the "Sample Inventory List Function Call */
/*        - ENTBJAPI" section of the API Guide for the      */
/*        layout of the request structures                  */
/************************************************************/
/* - ALSYS_RQ Request Structure Layout */
/*   Keyword        CHAR 6  */
/*   PATH           CHAR 1  */
/*   RETURN         CHAR 1  */
/*   SEARCH         CHAR 1  */
/*   ENV            CHAR 8  */
/*   STAGE ID       CHAR 1  */
/*   SYSTEM         CHAR 8  */
queue "ALSYS",                  /* Keyword */
    ||         "LAN ",          /* Options */
    ||         left(p_envir,8), /* Environment name */
    ||         "2",             /* Stage id */
    ||         "*"              /* System   */

/************************************************************/
/* Build ENTBJAPI RUN and quit Control Records              */
/************************************************************/
queue "RUN"
queue "QUIT"

/************************************************************/
/* Write all the Control Records to the SYSIN file          */
/************************************************************/
"EXECIO" queued() "DISKW SYSIN (FINIS)"

/************************************************************/
/* Execute the API utility program                          */
/************************************************************/
"ENTBJAPI"

/************************************************************/
/* Free allocations                                         */
/************************************************************/
"FREE DD(BSTAPI BSTERR SYSPRINT SYSOUT)"
"FREE DD(SYSIN DDMSG DDOUT)"
