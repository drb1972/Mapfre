 ADD      ELEMENT "        "
)N        THROUGH "        "
     FROM DSNAME  "<DSNAME>                                    "
)N        MEMBER  "        "
)N        DDNAME  "<DDNAME>"
)N        USSPATH "/<PATH SPEC WITH TRAILING '/'>      /"
)N        USSFILE "<FILENAME>"
)N
     TO   ENV     "        "
          SYS     "        " SUBSYSTEM "        " TYPE "        "
)N
)N USE "MD" LINE COMMANDS TO CONVERT REQUIRED OPTIONS TO VALID SCL
)N NOTE: WHERE KEYWORDS ARE GROUPED, PICK ONE LINE ONLY E.G. SPAN
)N
)N  OPTION
)N    CCID    "            "
)N    COMMENT "                                        "
)N
)N    NEW VERSION <VV>
)N
)N    UPDATE IF PRESENT
)N
)N    DELETE INPUT SOURCE
)N
)N    OVERRIDE SIGNOUT
)N
)N      BYPASS GENERATE PROCESSOR
)N      PROCESSOR GROUP EQUAL <PG>
)N
)N    AUTOGEN
)N      SPAN NONE
)N      SPAN ALL
)N      SPAN SYSTEMS
)N      SPAN SUBSYSTEMS
)N
    .
