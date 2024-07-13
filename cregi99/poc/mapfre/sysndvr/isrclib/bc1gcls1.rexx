/*********************************************************************/
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                */
/*                                                                   */
/*   MAIN CLIST TO INVOKE STANDALONE PDM (ISRCLIB)                   */
/*                                                                   */
/*********************************************************************/
          PROC 0
          CONTROL MSG NOFLUSH
          FREE  F(SYSPROC)
          ALLOC F(SYSPROC)  DS( -
                 'TSOXX4.ENDEVOR.V16.CSIQCLS0' -
                 'ISP.SISPCLIB' -
                 ) SHR
          FREE  F(ISPLLIB)
          ALLOC F(ISPLLIB)  DS( -
                 'TSOXX4.ENDEVOR.V16.CSIQLOAD' -
                 ) SHR
          FREE  F(CONLIB)
          ALLOC F(CONLIB)  DS( -
                 'TSOXX4.ENDEVOR.V16.CSIQLOAD' -
                 ) SHR
          FREE  F(ISPPLIB)
          ALLOC F(ISPPLIB) DS( -
                 'ISP.SISPPENU' -
                 'TSOXX4.ENDEVOR.V16.CSIQPENU' -
                 ) SHR
          FREE  F(ISPMLIB)
          ALLOC F(ISPMLIB) DS( -
                 'ISP.SISPMENU' -
                 'TSOXX4.ENDEVOR.V16.CSIQMENU' -
                 ) SHR
          FREE  F(ISPSLIB)
          ALLOC F(ISPSLIB) DS( -
                 'ISP.SISPSENU' -
                 'TSOXX4.ENDEVOR.V16.CSIQSENU' -
                 ) SHR
