C PACKAGE ERPRT77	 DESCRIPTION OF	INDIVIDUAL USER	ENTRIES
C			 FOLLOWS THIS PACKAGE DESCRIPTION.
C
C LATEST REVISION	 FEBRUARY 1985
C
C PURPOSE		 TO PROVIDE A PORTABLE,	FORTRAN	77 ERROR
C			 HANDLING PACKAGE.
C
C USAGE			 THESE ROUTINES	ARE INTENDED TO	BE USED	IN
C			 THE SAME MANNER AS THEIR SIMILARLY NAMED
C			 COUNTERPARTS ON THE PORT LIBRARY.  EXCEPT
C			 FOR ROUTINE SETER, THE	CALLING	SEQUENCES
C			 OF THESE ROUTINES ARE THE SAME	AS FOR
C			 THEIR PORT COUNTERPARTS.
C			 ERPRT77 ENTRY		PORT ENTRY
C			 -------------		----------
C			 ENTSR			ENTSRC
C			 RETSR			RETSRC
C			 NERRO			NERROR
C			 ERROF			ERROFF
C			 SETER			SETERR
C			 EPRIN			EPRINT
C			 FDUM			FDUMP
C
C I/O			 SOME OF THE ROUTINES PRINT ERROR MESSAGES.
C
C PRECISION		 NOT APPLICABLE
C
C REQUIRED LIBRARY	 MACHCR, WHICH IS LOADED BY DEFAULT ON
C FILES			 NCAR'S	CRAY MACHINES.
C
C LANGUAGE		 FORTRAN 77
C
C HISTORY		 DEVELOPED OCTOBER, 1984 AT NCAR IN BOULDER,
C			 COLORADO BY FRED CLARE	OF THE SCIENTIFIC
C			 COMPUTING DIVISION BY ADAPTING	THE NON-
C			 PROPRIETARY, ERROR HANDLING ROUTINES
C			 FROM THE PORT LIBRARY OF BELL LABS.
C
C PORTABILITY		 FULLY PORTABLE
C
C REFERENCES		 SEE THE MANUAL
C			   PORT	MATHEMATICAL SUBROUTINE	LIBRARY
C			 ESPECIALLY "ERROR HANDLING" IN	SECTION	2
C			 OF THE	INTRODUCTION, AND THE VARIOUS
C			 SUBROUTINE DESCRIPTIONS.
C ******************************************************************
C
C SUBBROUTINE ENTSR(IROLD,IRNEW)
C
C PURPOSE		SAVES THE CURRENT RECOVERY MODE	STATUS AND
C			SETS A NEW ONE.	 IT ALSO CHECKS	THE ERROR
C			STATE, AND IF THERE IS AN ACTIVE ERROR
C			STATE A	MESSAGE	IS PRINTED.
C
C USAGE			CALL ENTSR(IROLD,IRNEW)
C
C ARGUMENTS
C
C ON INPUT		 IRNEW
C			   VALUE SPECIFIED BY USER FOR ERROR
C			   RECOVERY
C			   = 0 LEAVES RECOVERY UNCHANGED
C			   = 1 GIVES  RECOVERY
C			   = 2 TURNS  RECOVERY OFF
C
C ON OUTPUT		 IROLD
C			   RECEIVES THE	CURRENT	VALUE OF THE ERROR
C			   RECOVERY MODE
C
C SPECIAL CONDITIONS	 IF THERE IS AN	ACTIVE ERROR STATE, THE
C			 MESSAGE IS PRINTED AND	EXECUTION STOPS.
C
C			 ERROR STATES -
C			 1 - ILLEGAL VALUE OF IRNEW.
C			 2 - CALLED WHILE IN AN	ERROR STATE.
C ******************************************************************
C
C SUBROUTINE RETSR(IROLD)
C
C PURPOSE		 SETS THE RECOVERY MODE	TO THE STATUS GIVEN
C			 BY THE	INPUT ARGUMENT.	 A TEST	IS THEN	MADE
C			 TO SEE	IF A CURRENT ERROR STATE EXISTS	WHICH
C			 IS UNRECOVERABLE; IF SO, RETSR	PRINTS AN
C			 ERROR MESSAGE AND TERMINATES THE RUN.
C
C			 BY CONVENTION,	RETSR IS USED UPON EXIT
C			 FROM A	SUBROUTINE TO RESTORE THE PREVIOUS
C			 RECOVERY MODE STATUS STORED BY	ROUTINE
C			 ENTSR IN IROLD.
C
C USAGE			 CALL RETSR(IROLD)
C
C ARGUMENTS
C
C ON INPUT		 IROLD
C			   = 1 SETS FOR	RECOVERY
C			   = 2 SETS FOR	NONRECOVERY
C
C ON OUTPUT		 NONE
C
C SPECIAL CONDITIONS	 IF THE	CURRENT	ERROR BECOMES UNRECOVERABLE,
C			 THE MESSAGE IS	PRINTED	AND EXECUTION STOPS.
C
C			 ERROR STATES -
C			   1 - ILLEGAL VALUE OF	IROLD.
C ******************************************************************
C
C INTEGER FUNCTION NERRO(NERR)
C
C PURPOSE		 PROVIDES THE CURRENT ERROR NUMBER (IF ANY)
C			 OR ZERO IF THE	PROGRAM	IS NOT IN THE
C			 ERROR STATE.
C
C USAGE			 N = NERRO(NERR)
C
C ARGUMENTS
C
C ON INPUT		 NONE
C
C ON OUTPUT		 NERR
C			   CURRENT VALUE OF THE	ERROR NUMBER
C ******************************************************************
C SUBROUTINE ERROF
C
C PURPOSE		 TURNS OFF THE ERROR STATE BY SETTING THE
C			 ERROR NUMBER TO ZERO
C
C USAGE			 CALL ERROF
C
C ARGUMENTS
C
C ON INPUT		 NONE
C
C ON OUTPUT		 NONE
C ******************************************************************
C
C SUBROUTINE SETER(MESSG,NERR,IOPT)
C
C PURPOSE		 SETS THE ERROR	INDICATOR AND, DEPENDING
C			 ON THE	OPTIONS	STATED BELOW, PRINTS A
C			 MESSAGE AND PROVIDES A	DUMP.
C
C
C USAGE			 CALL SETER(MESSG,NERR,IOPT)
C
C ARGUMENTS
C
C ON INPUT		 MESSG
C			   HOLLERITH STRING CONTAINING THE MESSAGE
C			   ASSOCIATED WITH THE ERROR
C
C			 NERR
C			   THE NUMBER TO ASSIGN	TO THE ERROR
C
C			 IOPT
C			   = 1 FOR A RECOVERABLE ERROR
C			   = 2 FOR A FATAL ERROR
C
C			  IF IOPT = 1 AND THE USER IS IN ERROR
C			  RECOVERY MODE, SETERR	SIMPLY REMEMBERS
C			  THE ERROR MESSAGE, SETS THE ERROR NUMBER
C			  TO NERR, AND RETURNS.
C
C			  IF IOPT = 1 AND THE USER IS NOT IN ERROR
C			  RECOVERY MODE, SETERR	PRINTS THE ERROR
C			  MESSAGE AND TERMINATES THE RUN.
C
C			  IF IOPT = 2 SETERR ALWAYS PRINTS THE ERROR
C			  MESSAGE, CALLS FDUM, AND TERMINATES THE RUN.
C
C ON OUTPUT		 NONE
C
C SPECIAL CONDITIONS	 CANNOT	ASSIGN NERR = 0, AND CANNOT SET	IOPT
C			 TO ANY	VALUE OTHER THAN 1 OR 2.
C ******************************************************************
C
C  SUBROUTINE EPRIN
C
C PURPOSE		 PRINTS	THE CURRENT ERROR MESSAGE IF THE
C			 PROGRAM IS IN THE ERROR STATE;	OTHERWISE
C			 NOTHING IS PRINTED.
C
C USAGE			 CALL EPRIN
C
C ARGUMENTS
C
C ON INPUT		 NONE
C
C ON OUTPUT		 NONE
C ******************************************************************
C
C SUBROUTINE FDUM
C
C PURPOSE		 TO PROVIDE A DUMMY ROUTINE WHICH SERVES
C			 AS A PLACEHOLDER FOR A	SYMBOLIC DUMP
C			 ROUTINE, SHOULD IMPLEMENTORS DECIDE TO
C			 PROVIDE SUCH A	ROUTINE.
C
C USAGE			 CALL EPRIN
C
C ARGUMENTS
C
C ON INPUT		 NONE
C
C ON OUTPUT		 NONE
C ******************************************************************
      SUBROUTINE ENTSR(IROLD,IRNEW)
C
      LOGICAL TEMP
      IF (IRNEW.LT.0 .OR. IRNEW.GT.2)
     1	 CALL SETER(' ENTSR - ILLEGAL VALUE OF IRNEW',1,2)
C
      TEMP = IRNEW.NE.0
      IROLD = I8SAV(2,IRNEW,TEMP)
C
C  IF HAVE AN ERROR STATE, STOP	EXECUTION.
C
      IF (I8SAV(1,0,.FALSE.) .NE. 0) CALL SETER
     1	 (' ENTSR - CALLED WHILE IN AN ERROR STATE',2,2)
C
      RETURN
C
      END
      SUBROUTINE RETSR(IROLD)
C
      IF (IROLD.LT.1 .OR. IROLD.GT.2)
     1	CALL SETER(' RETSR - ILLEGAL VALUE OF IROLD',1,2)
C
      ITEMP=I8SAV(2,IROLD,.TRUE.)
C
C  IF THE CURRENT ERROR	IS NOW UNRECOVERABLE, PRINT AND	STOP.
C
      IF (IROLD.EQ.1 .OR. I8SAV(1,0,.FALSE.).EQ.0) RETURN
C
	CALL EPRIN
	CALL FDUM
c       STOP
C
      END
      INTEGER FUNCTION NERRO(NERR)
C
      NERRO=I8SAV(1,0,.FALSE.)
      NERR=NERRO
      RETURN
C
      END
      SUBROUTINE ERROF
C
      I=I8SAV(1,0,.TRUE.)
      RETURN
C
      END
      SUBROUTINE SETER(MESSG,NERR,IOPT)
C
      CHARACTER*(*) MESSG
      COMMON /UERRF/IERF
C
C  THE UNIT FOR	ERROR MESSAGES IS I1MACH(4)
C
c +noao:  blockdata uerrbd changed to runtime initialization subroutine
C     FORCE LOAD OF BLOCKDATA
C
c     EXTERNAL UERRBD
      call uerrbd
c -noao
      IF (IERF .EQ. 0) THEN
      IERF = I1MACH(4)
      ENDIF
C
      NMESSG = LEN(MESSG)
      IF (NMESSG.GE.1) GO TO 10
C
C  A MESSAGE OF	NON-POSITIVE LENGTH IS FATAL.
C
c +noao:  FTN writes rewritten as calls to uliber for IRAF
c       WRITE(IERF,9000)
c9000	FORMAT(' ERROR 1 IN SETER - MESSAGE LENGTH NOT POSITIVE.')
        call uliber (1,' SETER - MESSAGE LENGTH NOT POSITIVE.', 80) 
c -noao
	GO TO 60
C
   10 CONTINUE
      IF (NERR.NE.0) GO	TO 20
C
C  CANNOT TURN THE ERROR STATE OFF USING SETER.
C
c +noao:  FTN writes rewritten as calls to uliber for IRAF
c       WRITE(IERF,9001)
c9001	FORMAT(' ERROR 2 IN SETER - CANNOT HAVE NERR=0'/
c    1	       ' THE CURRENT ERROR MESSAGE FOLLOWS'/)
        call uliber (2, ' SETER - CANNOT HAVE NERR=0', 80)
        call uliber (2, ' SETER - THE CURRENT ERROR MSG FOLLOWS', 80) 
c -noao
	CALL E9RIN(MESSG,NERR,.TRUE.)
	ITEMP=I8SAV(1,1,.TRUE.)
	GO TO 50
C
C  SET LERROR AND TEST FOR A PREVIOUS UNRECOVERED ERROR.
C
 20   CONTINUE
      IF (I8SAV(1,NERR,.TRUE.).EQ.0) GO	TO 30
C
c +noao: FTN writes rewritten as calls to uliber for IRAF
c       WRITE(IERF,9002)
c9002	FORMAT(' ERROR	  3 IN SETER -',
c    1	       ' AN UNRECOVERED	ERROR FOLLOWED BY ANOTHER ERROR.'//
c    2	       ' THE PREVIOUS AND CURRENT ERROR	MESSAGES FOLLOW.'///)
        call uliber (3,' SETER - A SECOND UNRECOV ERROR SEEN.', 80)
        call uliber (3,' SETER - THE ERROR MESSAGES FOLLOW.', 80)
c -noao
	CALL EPRIN
	CALL E9RIN(MESSG,NERR,.TRUE.)
	GO TO 50
C
C  SAVE	THIS MESSAGE IN	CASE IT	IS NOT RECOVERED FROM PROPERLY.
C
 30   CALL E9RIN(MESSG,NERR,.TRUE.)
C
      IF (IOPT.EQ.1 .OR. IOPT.EQ.2) GO TO 40
C
C  MUST	HAVE IOPT = 1 OR 2.
C
c +noao:  FTN writes rewritten as calls to uliber for IRAF
c     WRITE(IERF,9003)
c9003	FORMAT(' ERROR	  4 IN SETER - BAD VALUE FOR IOPT'//
c    1	       ' THE CURRENT ERROR MESSAGE FOLLOWS'///)
        call uliber (4, ' SETER - BAD VALUE FOR IOPT', 80)
	call uliber (4, ' SETER - THE CURRENT ERR MSG FOLLOWS', 80)
c -noao 
	GO TO 50
C
C  TEST	FOR RECOVERY.
C
 40   CONTINUE
      IF (IOPT.EQ.2) GO	TO 50
C
      IF (I8SAV(2,0,.FALSE.).EQ.1) RETURN
C
      CALL EPRIN
      CALL FDUM
c     STOP
C
 50   CALL EPRIN
 60   CALL FDUM
c     STOP
C
      END
      SUBROUTINE EPRIN
C
      CHARACTER*1 MESSG
C
      CALL E9RIN(MESSG,1,.FALSE.)
      RETURN
C
      END
      SUBROUTINE E9RIN(MESSG,NERR,SAVE)
C
C  THIS	ROUTINE	STORES THE CURRENT ERROR MESSAGE OR PRINTS THE OLD ONE,
C  IF ANY, DEPENDING ON	WHETHER	OR NOT SAVE = .TRUE. .
C
      CHARACTER*(*) MESSG
      CHARACTER*113 MESSGP
      LOGICAL SAVE
      COMMON /UERRF/IERF
C
C  MESSGP STORES THE FIRST 113 CHARACTERS OF THE PREVIOUS MESSAGE
C
C
C  START WITH NO PREVIOUS MESSAGE.
C
c+noao
c Moved save to before data statements.
      SAVE MESSGP,NERRP
c-noao
      DATA MESSGP/'1'/
      DATA NERRP/0/
C
      IF (.NOT.SAVE) GO	TO 20
C
C  SAVE	THE MESSAGE.
C
	NERRP=NERR
	MESSGP = MESSG
C
	GO TO 30
C
 20   IF (I8SAV(1,0,.FALSE.).EQ.0) GO TO 30
C
C  PRINT THE MESSAGE.
C
c +noao:  FTN write rewritten as call to uliber
c     WRITE(IERF,9000) NERRP,MESSGP
c9000 FORMAT(' ERROR ',I4,' IN ',A113)
      call uliber (nerrp, messgp, 113)
C
 30   RETURN
C
      END
      INTEGER FUNCTION I8SAV(ISW,IVALUE,SET)
C
C  IF (ISW = 1)	I8SAV RETURNS THE CURRENT ERROR	NUMBER AND
C		SETS IT	TO IVALUE IF SET = .TRUE. .
C
C  IF (ISW = 2)	I8SAV RETURNS THE CURRENT RECOVERY SWITCH AND
C		SETS IT	TO IVALUE IF SET = .TRUE. .
C
      LOGICAL SET
C
C  START EXECUTION ERROR FREE AND WITH RECOVERY	TURNED OFF.
C
c+noao
c Moved save to before data statement.
      SAVE LERROR,LRECOV
      DATA LERROR/0/ , LRECOV/2/
c-noao
      IF (ISW .EQ. 1) THEN
	I8SAV =	LERROR
	IF (SET) LERROR	= IVALUE
      ELSE IF (ISW .EQ.	2) THEN
	I8SAV =	LRECOV
	IF (SET) LRECOV	= IVALUE
      ENDIF
      RETURN
      END
      SUBROUTINE FDUM
C
C     DUMMY ROUTINE TO BE LOCALLY IMPLEMENTED
C
      RETURN
      END
c +noao:  Blockdata uerrbd rewritten as a runtime initialization subroutine
c     BLOCKDATA	UERRBD
      subroutine uerrbd
c
      COMMON /UERRF/IERF
C     DEFAULT ERROR UNIT
c     DATA IERF/0/
      IERF= 0
      END
c -noao
