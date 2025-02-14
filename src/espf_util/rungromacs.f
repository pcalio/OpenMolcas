************************************************************************
* This file is part of OpenMolcas.                                     *
*                                                                      *
* OpenMolcas is free software; you can redistribute it and/or modify   *
* it under the terms of the GNU Lesser General Public License, v. 2.1. *
* OpenMolcas is distributed in the hope that it will be useful, but it *
* is provided "as is" and without any express or implied warranties.   *
* For more details see the full text of the license in the file        *
* LICENSE or in <http://www.gnu.org/licenses/>.                        *
************************************************************************
#ifdef _GROMACS_
      SUBROUTINE RunGromacs(nAtIn,Coord,ipMltp,MltOrd,Forces,
     &                      ipGrad,Energy)

      USE, INTRINSIC :: iso_c_binding, only: c_int, c_loc, c_ptr
      IMPLICIT NONE

#include "espf.fh"
#include "opt_mmo.fh"
#include "stdalloc.fh"

      INTEGER, INTENT(IN) :: ipMltp,MltOrd,nAtIn
      INTEGER, INTENT(OUT) :: ipGrad
      REAL*8, DIMENSION(3,nAtIn), INTENT(IN) :: Coord
      REAL*8, INTENT(OUT) :: Energy
      LOGICAL, INTENT(IN) :: Forces

      TYPE(c_ptr) :: ipCR,ipGMS
      INTEGER :: iAtGMX,iAtIn,iAtOut,ic,iLast,iOk
      INTEGER :: j,LuExtPot,LuWr,nAtGMX,nAtOut
      INTEGER, DIMENSION(:), ALLOCATABLE :: AT
      REAL*8 :: EnergyGMX,Energy2GMX,q
      REAL*8, DIMENSION(:), ALLOCATABLE :: PotGMX,Pot2GMX
      REAL*8, DIMENSION(:,:), ALLOCATABLE :: CoordGMX,CoordMMO
      REAL*8, DIMENSION(:,:), ALLOCATABLE :: FieldGMX,Field2GMX
      REAL*8, DIMENSION(:,:), ALLOCATABLE :: ForceGMX,Force2GMX
      REAL*8, DIMENSION(:,:), ALLOCATABLE :: GradMMO
      CHARACTER(LEN=12) :: ExtPotFormat
      CHARACTER(LEN=100) :: ProgName
      CHARACTER(LEN=256) :: LogFileName,Message,TPRFileName
      LOGICAL :: Found,isNotLast

      INTEGER, EXTERNAL :: isFreeUnit
      CHARACTER(LEN=100), EXTERNAL :: Get_SuperName
      INTERFACE
        SUBROUTINE mmslave_done(gms) BIND(C,NAME='mmslave_done_')
          USE, INTRINSIC :: iso_c_binding, ONLY: c_ptr
          TYPE(c_ptr), VALUE :: gms
        END SUBROUTINE mmslave_done
        FUNCTION mmslave_init(cr,log_) BIND(C,NAME='mmslave_init_')
          USE, INTRINSIC :: iso_c_binding, ONLY: c_char, c_ptr
          TYPE(c_ptr) :: mmslave_init
          TYPE(c_ptr), VALUE :: cr
          CHARACTER(kind=c_char) :: log_(*)
        END FUNCTION mmslave_init
        FUNCTION mmslave_read_tpr(tpr,gms)
     &           BIND(C,NAME='mmslave_read_tpr_')
          USE, INTRINSIC :: iso_c_binding, ONLY: c_char, c_int, c_ptr
          INTEGER(kind=c_int) :: mmslave_read_tpr
          CHARACTER(kind=c_char) :: tpr(*)
          TYPE(c_ptr), VALUE :: gms
        END FUNCTION mmslave_read_tpr
        FUNCTION mmslave_set_q(gms,id,q) BIND(C,NAME='mmslave_set_q_')
          USE, INTRINSIC :: iso_c_binding, ONLY: c_double, c_int, c_ptr
          INTEGER(kind=c_int) :: mmslave_set_q
          TYPE(c_ptr), VALUE :: gms
          INTEGER(kind=c_int), VALUE :: id
          REAL(kind=c_double), VALUE :: q
        END FUNCTION mmslave_set_q
        FUNCTION init_commrec() BIND(C,NAME='init_commrec_')
          USE, INTRINSIC :: iso_c_binding, ONLY: c_ptr
          TYPE(c_ptr) :: init_commrec
        END FUNCTION init_commrec
      END INTERFACE


      LuExtPot = 1
      LuWr = 6
      Energy = Zero
      ProgName = Get_SuperName()

      WRITE(ExtPotFormat,'(a4,i2,a6)') '(I4,',MxExtPotComp,'F13.8)'

! Get MMO coordinates and atom types from runfile
      CALL Qpg_dArray('MMO Coords',Found,nAtOut)
      nAtOut = nAtOut/3
      CALL mma_allocate(CoordMMO,3,nAtOut)
      IF (Found) THEN
         CALL Get_dArray('MMO Coords',CoordMMO,3*nAtOut)
      ELSE
         Message = 'RunGromacs: MMO coordinates not found on runfile'
         CALL WarningMessage(2,Message)
         CALL Abend()
      END IF

      CALL Qpg_iArray('Atom Types',Found,nAtGMX)
      CALL mma_allocate(AT,nAtGMX)
      IF (Found) THEN
         CALL Get_iArray('Atom Types',AT,nAtGMX)
      ELSE
         Message = 'RunGromacs: Atom types not found on runfile'
         CALL WarningMessage(2,Message)
         CALL Abend()
      END IF

! Since this is the first time we use information from runfile, do a
! consistency check
      IF (nAtGMX.NE.nAtIn+nAtOut) THEN
         Message = 'RunGromacs: nAtGMX and nAtIn+nAtOut not equal'
         CALL WarningMessage(2,Message)
         CALL Abend()
      END IF

! Initialize Gromacs mmslave
      ipCR = init_commrec()
      CALL prgmtranslate('GMX.LOG',LogFileName,iLast)
      LogFileName(iLast+1:iLast+1) = CHAR(0)
      ipGMS = mmslave_init(ipCR,LogFileName)

! Let Gromacs read tpr file
      TPRFileName = TPRDefName
      iLast = LEN_TRIM(TPRFileName)
      TPRFileName(iLast+1:iLast+1) = CHAR(0)
      iOk = mmslave_read_tpr(TPRFileName,ipGMS)
      IF (iOk.ne.1) THEN
         Message = 'RunGromacs: mmslave_read_tpr is not ok'
         CALL WarningMessage(2,Message)
         CALL Abend()
      END IF

! Perform microiterations, though only if (1) it is requested, (2) there
! are MMO atoms to optimize, (3) not last energy, (4) multipoles are
! available, and (5) no gradient calculation
      IF (MMIterMax>0.AND.nAtOut>0) THEN
         isNotLast = ProgName(1:11).NE.'last_energy'
         IF ((ipMltp.NE.ip_Dummy).AND.(.NOT.Forces).AND.isNotLast) THEN
            CALL Opt_MMO(nAtIn,Coord,nAtOut,CoordMMO,nAtGMX,AT,ipGMS)
         END IF
      END IF

! Trick: Set QM charges in Gromacs to zero (or, currently, to a very
! small number). This is needed to exclude their contribution to the
! external potential.
      DO iAtGMX = 1,nAtGMX
         IF (AT(iAtGMX)==QM) THEN
            iOk = mmslave_set_q(ipGMS,INT(iAtGMX-1,kind=c_int),
     &                          SmallNumber)
            IF (iOk.NE.1) THEN
               Message = 'RunGromacs: mmslave_set_q is not ok'
               CALL WarningMessage(2,Message)
               CALL Abend()
            END IF
         END IF
      END DO

! Get energy, forces and external potential from Gromacs
      CALL mma_allocate(CoordGMX,3,nAtGMX)
      CALL mma_allocate(FieldGMX,3,nAtGMX)
      CALL mma_allocate(ForceGMX,3,nAtGMX)
      CALL mma_allocate(PotGMX,nAtGMX)
      iAtIn = 1
      iAtOut = 1
      DO iAtGMX = 1,nAtGMX
         IF (AT(iAtGMX)==QM.OR.AT(iAtGMX)==MMI) THEN
            CALL dcopy_(3,Coord(1,iAtIn),1,CoordGMX(1,iAtGMX),1)
            iAtIn = iAtIn+1
         ELSE
            CALL dcopy_(3,CoordMMO(1,iAtOut),1,CoordGMX(1,iAtGMX),1)
            iAtOut = iAtOut+1
         END IF
      END DO
      CALL dscal_(3*nAtGMX,AuToNm,CoordGMX,1)
      CALL dcopy_(3*nAtGMX,Zero,0,FieldGMX,1)
      CALL dcopy_(3*nAtGMX,Zero,0,ForceGMX,1)
      CALL dcopy_(nAtGMX,Zero,0,PotGMX,1)
      iOk = mmslave_calc_energy_wrapper(ipGMS,CoordGMX,ForceGMX,
     &                                  FieldGMX,PotGMX,EnergyGMX)
      IF (iOk.NE.1) THEN
         Message='RunGromacs: mmslave_calc_energy is not ok'
         CALL WarningMessage(2,Message)
         CALL Abend()
      END IF

! Special case: forces on MM atoms
      IF (Forces) THEN
         ic = 0
         CALL mma_allocate(Field2GMX,3,nAtGMX)
         CALL mma_allocate(Force2GMX,3,nAtGMX)
         CALL mma_allocate(Pot2GMX,nAtGMX)
         CALL dcopy_(3*nAtGMX,Zero,0,Field2GMX,1)
         CALL dcopy_(3*nAtGMX,Zero,0,Force2GMX,1)
         CALL dcopy_(nAtGMX,Zero,0,Pot2GMX,1)
         DO iAtGMX = 1,nAtGMX
            IF (AT(iAtGMX)==QM) THEN
               q = Work(ipMltp+ic)
               iOk = mmslave_set_q(ipGMS,INT(iAtGMX-1,kind=c_int),q)
               IF (iOk.ne.1) THEN
                  Message = 'RunGromacs: mmslave_set_q is not ok'
                  CALL WarningMessage(2,Message)
                  CALL Abend()
               END IF
               ic = ic+MltOrd
            END IF
         END DO
         iOk = mmslave_calc_energy_wrapper(ipGMS,CoordGMX,Force2GMX,
     &                                     Field2GMX,Pot2GMX,Energy2GMX)
         IF (iOk.NE.1) THEN
            Message = 'RunGromacs: mmslave_calc_energy is not ok'
            CALL WarningMessage(2,Message)
            CALL Abend()
         END IF
      END IF

! Store classical contributions to energy and gradient
      Energy = EnergyGMX/AuToKjPerMol
      IF (Forces) THEN
         CALL GetMem('GradCl','ALLO','REAL',ipGrad,3*nAtIn)
         CALL mma_allocate(GradMMO,3,nAtOut)
         iAtIn = 1
         iAtOut = 1
         DO iAtGMX = 1,nAtGMX
            IF (AT(iAtGMX)==QM) THEN
               CALL dcopy_(3,ForceGMX(1,iAtGMX),1,
     &                     Work(ipGrad+3*(iAtIn-1)),1)
               iAtIn = iAtIn+1
            ELSE IF (AT(iAtGMX)==MMI) THEN
               CALL dcopy_(3,Force2GMX(1,iAtGMX),1,
     &                     Work(ipGrad+3*(iAtIn-1)),1)
               iAtIn = iAtIn+1
            ELSE
               CALL dcopy_(3,Force2GMX(1,iAtGMX),1,
     &                     GradMMO(1,iAtOut),1)
               iAtOut = iAtOut+1
            END IF
         END DO
         CALL dscal_(3*nAtIn,-One/AuToKjPerMolNm,Work(ipGrad),1)
         CALL dscal_(3*nAtOut,-One/AuToKjPerMolNm,GradMMO,1)
         CALL Put_dArray('MMO Grad',GradMMO,3*nAtOut)
      END IF

! Write external potential to ESPF.EXTPOT file
      LuExtPot = isFreeUnit(LuExtPot)
      CALL molcas_open(LuExtPot,'ESPF.EXTPOT')
      WRITE(LuExtPot,'(I1)') 0
      iAtIn = 1
      DO iAtGMX = 1,nAtGMX
         IF (AT(iAtGMX)==QM.OR.AT(iAtGMX)==MMI) THEN
            WRITE(LuExtPot,ExtPotFormat) iAtIn,
     &                     PotGMX(iAtGMX)/AuToKjPerMol,
     &                    -FieldGMX(1,iAtGMX)/AuToKjPerMolNm,
     &                    -FieldGMX(2,iAtGMX)/AuToKjPerMolNm,
     &                    -FieldGMX(3,iAtGMX)/AuToKjPerMolNm,
     &                     (Zero,j=5,MxExtPotComp)
            iAtIn = iAtIn+1
         END IF
      END DO
      CLOSE(LuExtPot)

! Clean up
      CALL mma_deallocate(CoordMMO)
      CALL mma_deallocate(AT)
      CALL mma_deallocate(CoordGMX)
      CALL mma_deallocate(FieldGMX)
      CALL mma_deallocate(ForceGMX)
      CALL mma_deallocate(PotGMX)
      IF (Forces) THEN
         CALL mma_deallocate(Field2GMX)
         CALL mma_deallocate(Force2GMX)
         CALL mma_deallocate(Pot2GMX)
         CALL mma_deallocate(GradMMO)
      END IF
      CALL mmslave_done(ipGMS)

      RETURN

      CONTAINS

      FUNCTION mmslave_calc_energy_wrapper(gms,x,f,A,phi,energy)
      INTEGER :: mmslave_calc_energy_wrapper
      TYPE(c_ptr) :: gms
      REAL*8, TARGET :: x(*), f(*), A(*), phi(*)
      REAL*8 :: energy
      INTERFACE
        FUNCTION mmslave_calc_energy(gms,x,f,A,phi,energy)
     &           BIND(C,NAME='mmslave_calc_energy_')
          USE, INTRINSIC :: iso_c_binding, ONLY: c_double, c_int, c_ptr
          INTEGER(kind=c_int) :: mmslave_calc_energy
          TYPE(c_ptr), VALUE :: gms, x, f, A, phi
          REAL(kind=c_double) :: energy
        END FUNCTION mmslave_calc_energy
      END INTERFACE
      mmslave_calc_energy_wrapper = mmslave_calc_energy(gms,c_loc(x(1)),
     &  c_loc(f(1)),c_loc(A(1)),c_loc(phi(1)),energy)
      END FUNCTION mmslave_calc_energy_wrapper

      END
#elif defined (NAGFOR)
! Some compilers do not like empty files
      SUBROUTINE empty_RunGromacs()
      END
#endif
