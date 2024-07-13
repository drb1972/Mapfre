 PRINT    ELEMENT "        "
)N        THROUGH "<THRUNAME>"
)N        VERSION  <VV>      LEVEL  <LL>
     FROM ENV     "        " STAGE NUM "1"
          SYS     "        " SUBSYSTEM "        " TYPE "        "
)N
)N PRINT  MEMBER  "        "
)N        THROUGH "<MEMBER-NAME>"
)N        USSFILE "<FILE-NAME>
)N   FROM DSNAME  "<DSNAME>                                      "
)N        DDNAME   <DDNAME>
)N        USSPATH "<FILE-SPEC>"
)N
     TO   C1PRINT
)N        C1PRTVB
)N        DDNAME  <DDNAME>
)N
)N USE "MD" LINE COMMANDS TO CONVERT REQUIRED OPTIONS TO VALID SCL
)N NOTE: WHERE KEYWORDS ARE GROUPED, PICK ONE LINE ONLY E.G. SPAN
)N
)N  OPTION
)N      ELEMENT LISTING
)N        COMPONENT LIST TEXT STRING <TEXT-STRING>
)N      ELEMENT
)N      COMPONENT
)N
)N        BROWSE
)N        CHANGE
)N        HISTORY
)N        SUMMARY
)N        MASTER
)N
)N    EXPLODE
)N
)N    NOCC
)N
)N      SEARCH
)N      NOSEARCH
)N
)N  WHERE
)N    CCID
)N      OF CURRENT  EQUAL <CCID>
)N      OF ALL      EQ   (<CCID1>, <CCID2>, <CCID3>)
)N      OF RETRIEVE =     <CCID>
)N    PROCESSOR GROUP EQUAL <PG>
    .
