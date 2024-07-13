)CM  PACKAGE SHIPMENT BATCH JCL - EPILOGUE STEPS - ISPSLIB(C1BMXEND)
)CM
)CM  THIS SKELETON IS USED TO DELETE HOST STAGING DATASETS AND/OR
)CM  HOST STAGING USS DIRECTORIES.
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM  THIS SKELETON WILL ALLOW THE DELETION OF HOST STAGING DATASETS,
)CM  HOST USS DIRECTORIES OR BOTH.  IT MUST BE COPIED TO C1BMXEOJ.
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
//* *--------------------------------------------* ISPSLIB(C1BMXEND) *
//* *--------------------------------------------------------------* *
//* *--------------------------------------------------------------* *
//* *--------------------------------------------------------------* *
//* *--------------------------------------------------------------* *
//C1BMXDSN EXEC PGM=IDCAMS
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   DISP=(OLD,PASS),DSN=&&&&HDEL
//*
//C1BMXUSS EXEC PGM=BPXBATCH
//STDPARM  DD   DISP=(OLD,PASS),DSN=&&&&HUDL
//STDOUT   DD   SYSOUT=*
//STDERR   DD   SYSOUT=*
