 RETRIEVE ELEMENT "        "
)N        THROUGH "        "
)N        VERSION <VV>       LEVEL <LL>
)N
     FROM ENV     "        " STAGE NUM "1"
          SYS     "        " SUBSYSTEM "        " TYPE "        "
)N
     TO   DSNAME  "<DSNAME>                                    "
)N        MEMBER  "        "
)N        DDNAME  "<DDNAME>"
)N        USSPATH "/<PATH SPEC WITH TRAILING '/' /"
)N        USSFILE "<FILENAME>"
)N
)N USE "MD" LINE COMMANDS TO CONVERT REQUIRED OPTIONS TO VALID SCL
)N NOTE: WHERE KEYWORDS ARE GROUPED, PICK ONE LINE ONLY E.G. SPAN
)N
)N  OPTION
)N    CCID    "            "
)N    COMMENT "                                        "
)N
)N    REPLACE MEMBER
)N
)N    NO SIGNOUT
)N
)N    EXPAND INCLUDE
)N
)N    OVERRIDE SIGNOUT
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
