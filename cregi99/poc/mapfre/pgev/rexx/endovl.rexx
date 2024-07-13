/* REXX                                                             */
/*------------------------------------------------------------------*/
/*------------------------------------------------------------------*/
/*                                                                  */
/* COPYRIGHT (C) : NIG SKANDIA                            24-APR-97 */
/*                                                                  */
/* NAME    : ENDOVL                                                 */
/*                                                                  */
/* PURPOSE : THIS REXX IS USED TO submit a batch job to validate    */
/*           and print an overlay program.                          */
/*                                                                  */
/* UPDATED : DATE       BY   DESCRIPTION                            */
/*           ====       ===  ===========                            */
/*           24-APR-97  PB6  INITIAL CREATION OF REXX               */
/*                                                                  */
/*------------------------------------------------------------------*/
 Arg suffix c1userid c1si c1su

 user = substr(c1userid,3,3)
 slq = c1si || c1su
 jobn = TTLJ || user

 If length(c1userid) <> 8 then jobn = 'TTLJENDV'

 Queue "//"||jobn||" JOB 'ENDEVOR OVERLAY',NOTIFY="||c1userid
 Queue "//*"
 Queue "//PROVLY EXEC PGM=CPBU7704"
 Queue "//STEPLIB  DD DSN=PGLJ.BASE.LOAD,DISP=SHR"
 Queue "//SYSOUT   DD SYSOUT=*"
 Queue "//SYSIN    DD DATA"
 Queue suffix
 Queue "PORT"
 Queue "/*"
 Queue "//OUT1  OUTPUT CLASS=0,FORMS=NSEP,FLASH=CTXD,DEST=NIG020,"
 Queue "//      USERLIB=('PREV."slq".OVERLAY','PNKN.AFP.NIG.P300LIB')"
 Queue "//PRT01    DD SYSOUT=(,),OUTPUT=*.OUT1,DCB=(RECFM=VBA)"
 Queue "//*"
 Queue "   "
 msgstat = MSG('off')
 "SUBMIT *"

Exit(0)
