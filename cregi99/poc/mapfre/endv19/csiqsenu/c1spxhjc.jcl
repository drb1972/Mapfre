)CM  PACKAGE SHIPMENT BATCH JCL - JOB CARD FOR HOST JOBS
)CM  ISPSLIB(C1BMXIN)
)CM  HOST SITE JOB CARD INFORMATION.  FILL IN THE /*ROUTE
)CM  INFORMATION THAT THIS JOB WILL EXECUTE AT THE HOST SITE EVEN WHEN
)CM  SUBMITTED AT THE REMOTE SITE.
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM  TAILORING INSTRUCTIONS:
)CM
)CM  1.  THE &C1BJX_ STATEMENTS WILL EXPAND INTO THE JOB CARD WHICH
)CM      IS CURRENTLY IN EFFECT ON THE PACKAGE SHIPMENT PANEL
)CM      (OPTION 6 ON THE PACKAGE OPTION MENU).  THEY AND THEIR )SEL
)CM      AND )ENDSEL BOOKENDS CAN BE REPLACED WITH A "HARD CODED" JOB
)CM      STATEMENT.
)CM
)CM  2.  THIS JOB CARD MUST BE ABLE TO RUN ON BOTH THE HOST AND REMOTE
)CM      SYSTEMS.  SUBSTITUTE A SITE SPECIFIC VALUE FOR THE "HOSTNAME"
)CM      ON THE /*ROUTE CARD WHICH WILL CAUSE A JOB SUBMITTED AT EITHER
)CM      SITE TO BE ROUTED TO THE HOST FOR EXECUTION.
)CM
)CM  3.  ADDITIONAL JES CONTROL CARDS AND/OR JCL CAN BE APPENDED AS
)CM      NEEDED.
)CM
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM  PTF 9224280 APPLIED TO CHANGE //*ROUTE TO /*ROUTE
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM  FOR JES3 THE /*ROUTE CARD MOVES FROM THE END TO THE BEGINNING
)CM  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
)CM
)CM
/*ROUTE XEQ HOSTNAME
)SEL &C1SJC1 ^= &Z
&C1SJC1
)ENDSEL
)SEL &C1SJC2 ^= &Z
&C1SJC2
)ENDSEL
)SEL &C1SJC3 ^= &Z
&C1SJC3
)ENDSEL
)SEL &C1SJC4 ^= &Z
&C1SJC4
)ENDSEL