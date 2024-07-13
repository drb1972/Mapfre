//*********************************************************************
//** SKELETON CMSNDRA                                                **
//**                                                                 **
//** C1SYSTEMC ENTRIES ON PGEV.BASE.DATA(DESTSYS) DICTATES HOW MANY  **
//** TIMES THIS SKELETON IS INCLUDED IN THE STEP DESTCOPY IN THE     **
//** RJOB                                                            **
//*********************************************************************
//&SRCDSN  DD DISP=SHR,                        /* INPUT DATASET      */
//             DSN=&SHIPHLQC..PROCESS.FILE(&CPYMEM)
//&CJOBIN   DD DISP=SHR,                        /* INPUT DATASET     */
//             DSN=&CJOBCPY
//&BJOBIN   DD DISP=SHR,                        /* INPUT DATASET     */
//             DSN=&BJOBCPY
//&NDMCPY  DD DISP=SHR,                       /* OUTPUT DATASET     */
//             DSN=&SHIPHLQC..PROCESS.FILE(&CDMEMBR.)
//C&DESTID DD DISP=(NEW,CATLG),                /* OUTPUT DATASET     */
//             DSN=&CJOBDSET,
//             LIKE=&CJOBCPY
//B&DESTID DD DISP=(NEW,CATLG),                /* OUTPUT DATASET     */
//             DSN=&BJOBDSET,
//             LIKE=&BJOBCPY
