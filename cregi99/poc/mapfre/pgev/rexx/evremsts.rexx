/*************  REXX  *************************************************/
/* Rexx Name    : EVREMSTS                                            */
/* Rexx Library : PGEV.BASE.REXX                                      */
/* Rexx Function: Update the change file with the implementation      */
/*              : status after Change has been actioned               */
/*              : Note: status will be return from all target systems */
/* Author       : Philip Ogden                                        */
/* Support      : Endevor                                             */
/* Related Execs: None                                                */
/* Related Rules: EVINF000                                            */
/* History      : 24/06/2014 Created new                              */
/* History      : 04/08/2014 Add processing to bypass file contention */
/**********************************************************************/
trace o
arg DSTAMP TSTAMP SOURCE STATUS RECORD RETRY_COUNT
 ProcTrys =  0
 Process:
 signal on error
 stat = MSG('off')            /* set tso messages off */
 ADDRESS TSO
    "ALLOC DA('PGEV.REMEDY.CHANGE') F(ChngFil) SHR reuse"

    "EXECIO * DISKR ChngFil(finis stem" Chngrec.


 ADDRESS TSO
 "FREE  FI(ChngFil)"
/*  ensure have latest record for the change number */
  LastRec = 0
  do x = 1 to Chngrec.0
      CCCID  = SUBSTR(Chngrec.x,1,8)
      If Record = CCCID
      then do
          Lastrec = x
          iterate
          End
      END

  If LastRec = 0
  Then EXIT (99)

  x = LastRec

  CCCID    = SUBSTR(Chngrec.x,1,8)
  CIdent   = SUBSTR(Chngrec.x,9,15)
  CUser    = SUBSTR(Chngrec.x,24,8)
  CAuth    = SUBSTR(Chngrec.x,32,8)
  CCat     = SUBSTR(Chngrec.x,40,1)
  CStt     = SUBSTR(Chngrec.x,41,8)
  CProcess = SUBSTR(Chngrec.x,49,1)
  CSys     = SUBSTR(Chngrec.x,50,2)
  CAction  = SUBSTR(Chngrec.x,52,1)
  Cdate    = SUBSTR(Chngrec.x,53,8)
  Ctime    = SUBSTR(Chngrec.x,61,8)
  CTitle   = SUBSTR(Chngrec.x,93,40)


 Ssystem       = substr(Source,1,1)
 CAmender      = 'XCHNG  ' || Ssystem
 CAdate        = Date('o',Dstamp,'s')
 CAtime        = Tstamp
 Cstt          = left(STATUS,8)

 NewRec.1 =  CCCID || CIdent || CUser || CAuth || CCat ||,
              Cstt || CProcess || CSys || Caction || CDate ||,
              Ctime || CAmender || CAdate || CAtime || Ctitle

 /*  add  to change file */
 ADDRESS TSO
    "ALLOC DA('PGEV.REMEDY.CHANGE') F(ChngFil) MOD reuse"
    "EXECIO * DISKW ChngFil(finis stem" NewRec.

 ADDRESS TSO
 "FREE  FI(ChngFil)"

 Exit (0)
 ERROR:
 /*  assume that problem is file access */
 /*  possibly due to several updates    */
 /*  being received simultaniously.     */
 /*  Wait and loop to give time for file*/
 /*  to free up.                        */
 ProcTrys =  Proctrys + 1
 If Proctrys > 9
 then  exit (99)

 CALL SYSCALLS 'ON'
 ADDRESS SYSCALL
 "sleep" 5
 CALL SYSCALLS 'OFF'
 signal Process
