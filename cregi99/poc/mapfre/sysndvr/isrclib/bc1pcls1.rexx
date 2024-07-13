PROC 0 DEBUG(NO)
/*-------------------------------------------------------------------*/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                 */
/*                                                                   */
/* NAME: BC1PCLS1                                                    */
/*                                                                   */
/* FUNCTION: THIS CLIST ALLOCATE THE PRODUCT LIBRARIES FOR THE       */
/*   ISPF DIALOG                                                     */
/*                                                                   */
/*   NOTE: ALL DATASET NAMES WILL HAVE TO BE CUSTOMIZED TO YOU SITE  */
/*  SPECIFICATIONS.                                                  */
/*                                                                   */
/*-------------------------------------------------------------------*/
          IF (&DEBUG EQ YES) THEN +
            CONTROL LIST MSG NOFLUSH
          ELSE +
            CONTROL NOLIST NOMSG NOFLUSH

          GLOBAL PNLCSR PNLMSG CSPMBR CIELM ACTION

          FREE  FI(SYSPROC)
          ALLOC FI(SYSPROC) +
                DA('ISP.SISPCLIB' +
                   'TSOXX4.ENDEVOR.V16.CSIQCLS0') +
                SHR

          FREE  FI(CONLIB)
          ALLOC FI(CONLIB) +
                DA('TSOXX4.ENDEVOR.V16.CSIQLOAD') +
                SHR

          FREE  FI(ISPPLIB)
          ALLOC FI(ISPPLIB) +
                DA('ISP.SISPPENU' +
                   'TSOXX4.ENDEVOR.V16.CSIQPENU') +
                SHR

          FREE  FI(ISPMLIB)
          ALLOC FI(ISPMLIB) +
                DA('ISP.SISPMENU' +
                   'TSOXX4.ENDEVOR.V16.CSIQMENU') +
                SHR

          FREE  FI(ISPSLIB)
          ALLOC FI(ISPSLIB) +
                DA('ISP.SISPSENU' +
                   'TSOXX4.ENDEVOR.V16.CSIQSENU') +
                SHR

          FREE  FI(ISPTLIB)
          ALLOC FI(ISPTLIB) +
                DA('ISP.SISPSENU' +
                   'TSOXX4.ENDEVOR.V16.CSIQTENU') +
                SHR

          WRITE DATA SET ALLOCATIONS ARE COMPLETE
          EXIT(0)
