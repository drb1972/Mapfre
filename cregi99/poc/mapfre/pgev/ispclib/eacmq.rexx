/* REXX                                                             */
/*------------------------------------------------------------------*/
/*                                                                  */
/*  COPYRIGHT (C) 1986-2010 CA. ALL RIGHTS RESERVED.                */
/*                                                                  */
/*  NAME: EACMQ                                                     */
/*                                                                  */
/*  PURPOSE: ACMQ INVOKES THE ACM QUERY FACILITY                    */
/*           THIS VERSION ALLOWS YOU TO ENTER INPUT COMPONENT LOCN  */
/*                                                                  */
/*  NOTE: THE PRODUCT LIBRARIES MUST BE ALLOCATED PRIOR TO THE      */
/*        EXECUTION OF THIS CLIST                                   */
/*------------------------------------------------------------------*/
   ADDRESS ISPEXEC "LIBDEF ISPPLIB DATASET ID('PREV.UEV1.ISPPLIB',
                    'PGEV.BASE.ISPPLIB') STACK"

  "ISPEXEC SELECT CMD(BC1PACMI) NOCHECK NEWAPPL(CTLI) PASSLIB"

  "ISPEXEC LIBDEF ISPPLIB"
EXIT
