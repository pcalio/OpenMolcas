************************************************************************
* This file is part of OpenMolcas.                                     *
*                                                                      *
* OpenMolcas is free software; you can redistribute it and/or modify   *
* it under the terms of the GNU Lesser General Public License, v. 2.1. *
* OpenMolcas is distributed in the hope that it will be useful, but it *
* is provided "as is" and without any express or implied warranties.   *
* For more details see the full text of the license in the file        *
* LICENSE or in <http://www.gnu.org/licenses/>.                        *
*                                                                      *
* Copyright (C) 1990,1994, Jeppe Olsen                                 *
************************************************************************
      SUBROUTINE MEMSTR
      Use Str_Info
*
*
* Construct pointers for saving information about strings and
* their mappings
*
*========
* Input :
*========
* Number and types of strings defined by /STRINP/
* Symmetry information stored in         /CSM/
* String information stored in           /STINF/
*=========
* Output
*=========
* Pointers stored in common block /STRBAS/
*
* Jeppe Olsen , Winter of 1990
*
* Last Revision , Dec 24 1990 , Almaden
*
* Updated with iuniqtp, dec 11, 1994
      IMPLICIT REAL*8 (A-H,O-Z)
*
#include "detdim.fh"
#include "stdalloc.fh"
#include "WrkSpc.fh"
#include "orbinp_mclr.fh"
#include "strinp_mclr.fh"
#include "strbas_mclr.fh"
#include "csm.fh"
#include "stinf_mclr.fh"
      LENGTH=100
*. Start of string information
      NTEST = 0000
      IF(NTEST.NE.0) WRITE(6,*) ' First word with string information',
     &                           KSTINF
*
      Call ICopy(MXPSTT,[ip_iDummy],0,KISTSO,1)
      Call ICopy(MXPSTT,[ip_iDummy],0,KEL1  ,1)
      Call ICopy(MXPSTT,[ip_iDummy],0,KEL3  ,1)
      Call ICopy(MXPSTT,[ip_iDummy],0,KEL123,1)
      Call ICopy(MXPSTT,[ip_iDummy],0,KACTP ,1)
      Call ICopy(MXPSTT,[ip_iDummy],0,KZ    ,1)
* =====================================================================
*
* 1 : String information
*
* =====================================================================
*
      Allocate(Str(1:NSTTYP))

      IIITEST = 1
      DO ITYP = 1, NSTTYP
        IF (IUNIQTP(ITYP).EQ.ITYP) THEN
        NSTRIN = NUMST3(NELEC(ITYP),NORB1,MNRS1(ITYP),MXRS1(ITYP),
     &                  NORB2,NORB3,MNRS3(ITYP),MXRS3(ITYP) )
        LSTRIN = NSTRIN * NELEC(ITYP)
*.  Offsets for occupation of strings and reordering array
          Call mma_allocate(Str(ITYP)%OCSTR_Hidden,LSTRIN,Label='OCSTR')
          Str(ITYP)%OCSTR => Str(ITYP)%OCSTR_Hidden
          Call mma_allocate(Str(ITYP)%STREO_Hidden,NSTRIN,Label='STREO')
          Str(ITYP)%STREO => Str(ITYP)%STREO_Hidden

*. Symmetry and class of each string
          Call mma_allocate(Str(ITYP)%STSM_Hidden,NSTRIN,Label='STSM')
          Str(ITYP)%STSM  => Str(ITYP)%STSM_Hidden
          Call mma_allocate(Str(ITYP)%STCL_Hidden,NSTRIN,Label='STCL')
          Str(ITYP)%STCL  => Str(ITYP)%STCL_Hidden
        ELSE
          IITYP = - IUNIQTP(ITYP)
          Str(ITYP)%OCSTR => Str(IITYP)%OCSTR_Hidden
          Str(ITYP)%STREO => Str(IITYP)%STREO_Hidden
          Str(ITYP)%STSM  => Str(IITYP)%STSM_Hidden
          Str(ITYP)%STCL  => Str(IITYP)%STCL_Hidden
        END IF
      END DO

*. Number of strings per symmetry and occupation
      DO ITYP = 1, NSTTYP
        IF (IUNIQTP(ITYP).EQ.ITYP) THEN
           Call mma_allocate(Str(ITYP)%NSTSO_Hidden,NOCTYP(ITYP)*NSMST,
     &                       Label='NSTSO')
          Str(ITYP)%NSTSO => Str(ITYP)%NSTSO_Hidden
*. Offset of strings per symmetry and occupation
        Call GetMem('ISTSO ','ALLO','INTEGER',
     &             KISTSO(ITYP),NOCTYP(ITYP)*NSMST)
*. Number of electrons in RAS1 and RAS3 per sub type, is sub-type active
        Call GetMem('IEL1  ','ALLO','INTEGER',
     &              KEL1(ITYP),NOCTYP(ITYP))
        Call GetMem('IEL3  ','ALLO','INTEGER',
     &               KEL3(ITYP),NOCTYP(ITYP))
        Call GetMem('ACTP ','ALLO','INTEGER',
     &             KACTP(ITYP),NOCTYP(ITYP))
CMS: New array introduced according to Jeppes new strinfo representation
        Call GetMem('KEL123','ALLO','INTEGER',
     &                KEL123(ITYP),3*NOCTYP(ITYP))
**. Lexical adressing of arrays: NB! Not allocated here in Jeppes new version!
*       CALL MEMMAN(KZ(ITYP),NACOB*NELEC(ITYP),'ADDS  ',1,'Zmat  ')
        Call GetMem('Zmat  ','ALLO','INTEGER',
     &                    KZ(ITYP),NACOB*NELEC(ITYP))
        ELSE
*. redirect
          IITYP = - IUNIQTP(ITYP)
          Str(ITYP)%NSTSO => Str(IITYP)%NSTSO_Hidden
          KISTSO(ITYP) = KISTSO(IITYP)
          KEL1(ITYP)   = KEL1(IITYP)
          KEL3(ITYP)   = KEL3(IITYP)
          KACTP(ITYP)  = KACTP(IITYP)
          KZ(ITYP)     = KZ(IITYP)
          KEL123(ITYP) = KEL123(IITYP)
        END IF
      END DO

CMS: Introduced according to Jeppes new concept.
CMS: NB! WORK(KEL123(ITYP) added to IEL13 parameter list!
CMS: Be aware that IEL13 is also called in STRINF
      DO  ITYP = 1, NSTTYP
        IF(IUNIQTP(ITYP).EQ.ITYP) THEN
        CALL IEL13(MNRS1(ITYP),MXRS1(ITYP),MNRS3(ITYP),MXRS3(ITYP),
     &             NELEC(ITYP),NOCTYP(ITYP),iWORK(KEL1(ITYP)),
     &             iWORK(KEL3(ITYP)),iWORK(KEL123(ITYP)),
     &             iWORK(KACTP(ITYP)) )
        END IF
      END DO

*. Mappings between different string types
      DO ITYP = 1, NSTTYP
c          write(6,*) nelec(ityp),nstrin
          NSTRIN = NSTFTP(ITYP)
          IF(ISTAC(ITYP,2).NE.0.AND.ISTAC(ITYP,1).NE.0) THEN
*.creation on string allowed , use full orbital notation
            LENGTH = NACOB*NSTRIN
*. No explicit offset or length. NEW:
            KSTSTMI(ITYP) = ip_iDummy
            KSTSTMN(ITYP) = ip_iDummy
          ELSE IF(ISTAC(ITYP,1).NE.0.AND.ISTAC(ITYP,2).EQ.0) THEN

*. only annihilation allowed, use compact scheme
            LENGTH = NELEC(ITYP)*NSTRIN
*. No explicit offset or length. NEW:
            KSTSTMI(ITYP) = ip_iDummy
            KSTSTMN(ITYP) = ip_iDummy
CMS: New else block
          ELSE IF (ISTAC(ITYP,1).EQ.0.AND.ISTAC(ITYP,2).NE.0) THEN
*. Only creation allowed, use compact scheme with offsets
*
          CALL NUMST4_MCLR(NELEC(ITYP),NORB1,MNRS1(ITYP),MXRS1(ITYP),
     &                     NORB2,NORB3,MNRS3(ITYP),MXRS3(ITYP),
     &                     Str(ITYP)%NSTSO)
            LENGTH = NCASTR_MCLR(2,Str(ITYP)%NSTSO,NOCTYP(ITYP),
     &                      ITYP,NOBPT,3,iWORK(KEL123(ITYP)))
*. Explicit offsets and lengths
            Call GetMem('STSTMI','ALLO','INTEGER',KSTSTMI(ITYP),NSTRIN)
            Call GetMem('STSTMN','ALLO','INTEGER',KSTSTMN(ITYP),NSTRIN)
          END IF
*. has this map been constructed before ?
          IIIITEST = 0
          IF(IUNIQTP(ITYP).EQ.ITYP.OR.IIIITEST.EQ.1) THEN
            IMNEW = 1
            IUNIQMP(ITYP) = ITYP
          ELSE
*. check type of previous map
            DO JJTYP = 1, ITYP-1
            IITYP = -IUNIQTP(ITYP)
            IF(ABS(IUNIQTP(JJTYP)).EQ.IITYP.AND.
     &          IUNIQMP(JJTYP).EQ.JJTYP) THEN
            IF((ISTAC(ITYP,1).EQ.0.AND.ISTAC(JJTYP,1).EQ.0).OR.
     &         (ISTAC(ITYP,1).NE.0.AND.ISTAC(JJTYP,1).NE.0.AND.
     &          ABS(IUNIQTP(ISTAC(ITYP,1))).EQ.
     &          ABS(IUNIQTP(ISTAC(JJTYP,1)))) ) THEN
                IANEQ = 1
            ELSE
                IANEQ = 0
            END IF
            IF((ISTAC(ITYP,2).EQ.0.AND.ISTAC(JJTYP,2).EQ.0).OR.
     &         (ISTAC(ITYP,2).NE.0.AND.ISTAC(JJTYP,2).NE.0.AND.
     &          ABS(IUNIQTP(ISTAC(ITYP,2))).EQ.
     &          ABS(IUNIQTP(ISTAC(JJTYP,2)))) ) THEN
                ICREQ = 1
            ELSE
                ICREQ = 0
            END IF
            IF(IANEQ.EQ.1.AND.ICREQ.EQ.1) THEN
              IMNEW = 0
              IUNIQMP(ITYP) = -JJTYP
              GOTO 1211
            END IF
*
            END IF
            END DO
*. Normal exit from DO loop only if no identical map was found
            IMNEW = 1
            IUNIQMP(ITYP) = ITYP
 1211       CONTINUE
          END IF
          IF(IMNEW.EQ.1) THEN
            Call GetMem('CREMAP','ALLO','INTE',KSTSTM(ITYP,1),LENGTH)
            Call GetMem('ANNMAP','ALLO','INTE',KSTSTM(ITYP,2),LENGTH)
C             WRITE(6,*) ' Map for ITYP = ', ITYP, ' is created '
          ELSE
            KSTSTM(ITYP,1) = KSTSTM(-IUNIQMP(ITYP),1)
            KSTSTM(ITYP,2) = KSTSTM(-IUNIQMP(ITYP),2)
C             WRITE(6,*)
C     &      ' Map for ITYP=',ITYP,' corresponds to map for JTYP=',
C     &        -IUNIQMP(ITYP)
          END IF
      END DO

*. Symmetry of conjugated orbitals and orbital excitations
*     KCOBSM,KNIFSJ,KIFSJ,KIFSJO
      Call GetMem('Cobsm ','ALLO','INTEGER',KCOBSM,NACOB)
      Call GetMem('Nifsj ','ALLO','INTEGER',KNIFSJ,NACOB*NSMSX)
      Call GetMem('Ifsj  ','ALLO','INTEGER',KIFSJ,NACOB**2 )
      Call GetMem('Ifsjo ','ALLO','INTEGER',KIFSJO,NACOB*NSMSX)
*. Symmetry of excitation connecting  strings of given symmetry
      Call GetMem('Ststx ','ALLO','INTEGER',KSTSTX,NSMST*NSMST)
*
**. Up and down mappings of strings containing the same number of electrons
*
      DO ITYP = 1, NSTTYP
       IF(INUMAP(ITYP).NE.0)
     &Call GetMem('Numup ','ALLO','INTEGER',KNUMAP(ITYP),NSTFTP(ITYP))
       IF(INDMAP(ITYP).NE.0)
     &Call GetMem('Ndmup ','ALLO','INTEGER',KNDMAP(ITYP),NSTFTP(ITYP))
      END DO

*. Last word of string information
      RETURN
      END
