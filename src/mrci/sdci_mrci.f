!***********************************************************************
! This file is part of OpenMolcas.                                     *
!                                                                      *
! OpenMolcas is free software; you can redistribute it and/or modify   *
! it under the terms of the GNU Lesser General Public License, v. 2.1. *
! OpenMolcas is distributed in the hope that it will be useful, but it *
! is provided "as is" and without any express or implied warranties.   *
! For more details see the full text of the license in the file        *
! LICENSE or in <http://www.gnu.org/licenses/>.                        *
!***********************************************************************
      SUBROUTINE SDCI_MRCI()
      IMPLICIT REAL*8 (A-H,O-Z)

#include "SysDef.fh"

#include "mrci.fh"
#include "WrkSpc.fh"
!      DIMENSION H(MAXMEM), iH(RtoI*MAXMEM)
! PUT THE SUBROUTINE NAME ONTO THE ENTRY NAME STACK
! INPUT AND MEMORY ALLOCATION:
!      CALL READIN(HWork,iHWork)
      CALL READIN_MRCI()
! INTEGRAL SORTING AND DIAGONAL ELEMENTS:
! USE COUPLING COEFFS FROM UNIT 10, TRANSFORMED INTEGRALS FROM 13 AND 17
! PRODUCE FILES UNIT 14, 15 AND 16 WITH SORTED INTEGRALS.
! ALSO FOCK MATRIX TO UNIT 25 AND DIAGONAL ELEMENTS TO UNIT 27.
!PAM04 ALLOCATION OF FOCK MATRIX MOVED HERE FROM ALLOC.
      CALL GETMEM('FOCK','ALLO','REAL',LFOCK,NBTRI)
      CALL DIAGCT()
! CREATE REFERENCE CI HAMILTONIAN:
!PAM04      CALL MKHREF (HWork(LHREF),Hwork(LFOCK),HWork(LFIJKL),
!PAM04     &             HWork(LJREFX))
      NHREF=(NREF*(NREF+1))/2
      CALL GETMEM('HREF','ALLO','REAL',LHREF,NHREF)
      NIJ=(LN*(LN+1))/2
      NIJKL=(NIJ*(NIJ+1))/2
      CALL GETMEM('FIJKL','ALLO','REAL',LFIJKL,NIJKL)
      CALL MKHREF (Work(LHREF),Work(LFOCK),Work(LFIJKL),                &
     &             IWork(LJREFX))
! SOLVE REFERENCE CI EQUATIONS:
!PAM04      CALL REFCI (HWork(LHREF),HWork(LAREF),HWork(LEREF),HWork(LCSPCK),
!PAM04     *            HWork(LCISEL),HWork(LPLEN))
      CALL GETMEM('AREF','ALLO','REAL',LAREF,NREF**2)
      CALL GETMEM('EREF','ALLO','REAL',LEREF,NREF)
      CALL GETMEM('PLEN','ALLO','REAL',LPLEN,NREF)
      CALL REFCI (Work(LHREF),Work(LAREF),Work(LEREF),IWork(LCSPCK),    &
     &            Work(LCISEL),Work(LPLEN))
      CALL GETMEM('PLEN','FREE','REAL',LPLEN,NREF)
      CALL GETMEM('HREF','FREE','REAL',LHREF,NHREF)
      IF(IREFCI.EQ.1) THEN
       CALL GETMEM('FOCK','FREE','REAL',LFOCK,NBTRI)
       CALL GETMEM('FIJKL','FREE','REAL',LFIJKL,NIJKL)
       GOTO 900
      END IF
! SOLVE MRCI OR ACPF EQUATIONS:
! FIRST, SET UP START CI ARRAYS, AND ALSO TRANSFORM DIAGONAL ELEMENTS:
!------
! POW: Initialize HSMALL(1,1)
      HSMALL(1,1)=0.0d0
!------
      CALL GETMEM('ICI','ALLO','INTE',LICI,MBUF)
      CALL GETMEM('CI','ALLO','REAL',LCI,NCONF)
      CALL GETMEM('SGM','ALLO','REAL',LSGM,NCONF)
      CALL CSTART(Work(LAREF),Work(LEREF),Work(LCI),IWork(LICI))
      CALL MQCT(WORK(LAREF),WORK(LEREF),Work(LCI),Work(LSGM),           &
     &          IWork(LICI))
      CALL GETMEM('SGM','FREE','REAL',LSGM,NCONF)
      CALL GETMEM('CI','FREE','REAL',LCI,NCONF)
      CALL GETMEM('ICI','FREE','INTE',LICI,MBUF)
!PAM04 EXPLICIT DEALLOCATION OF FOCK MATRIX
      CALL GETMEM('FOCK','FREE','REAL',LFOCK,NBTRI)
! DENSITY (AND MAYBE TRANSITION DENSITY) MATRICES IN AO BASIS:
!PAM04 ALLOCATION OF DMO AND TDMO MOVED HERE FROM ALLOC:
      CALL GETMEM('DMO','ALLO','REAL',LDMO,NBTRI)
      IF(ITRANS.EQ.1) CALL GETMEM('TDMO','ALLO','REAL',LTDMO,NBAST**2)
!PAM04 End of addition
      CALL DENSCT(WORK(LAREF))
      CALL GETMEM('AREF','FREE','REAL',LAREF,NREF**2)
      CALL GETMEM('EREF','FREE','REAL',LEREF,NREF)
! NATURAL ORBITALS AND PROPERTIES (AND MAYBE TRANSITION PROPS):
      CALL PROPCT()
!PAM04 EXPLICIT DEALLOCATION ADDED:
      CALL GETMEM('DMO','FREE','REAL',LDMO,NBTRI)
      IF(ITRANS.EQ.1) CALL GETMEM('TDMO','FREE','REAL',LTDMO,NBAST**2)
!PAM04 End of addition
 900  CONTINUE
      CALL GETMEM('FIJKL','FREE','REAL',LFIJKL,NIJKL)
      CALL GETMEM('CISEL','FREE','REAL',LCISEL,NSEL*NREF)
      CALL GETMEM('JREFX','FREE','INTE',LJREFX,NCVAL)
      CALL GETMEM('ISAB','FREE','INTE',LISAB,NVIRT**2)
      CALL GETMEM('INDX','FREE','INTE',LINDX,NIWLK)
      CALL GETMEM('INTSY','FREE','INTE',LINTSY,NINTSY)
      CALL GETMEM('CSPCK','FREE','INTE',LCSPCK,NCSPCK)
! POP THE SUBROUTINE NAME FROM THE ENTRY NAME STACK
      RETURN
      END
