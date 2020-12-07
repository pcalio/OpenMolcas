!***********************************************************************
! This file is part of OpenMolcas.                                     *
!                                                                      *
! OpenMolcas is free software; you can redistribute it and/or modify   *
! it under the terms of the GNU Lesser General Public License, v. 2.1. *
! OpenMolcas is distributed in the hope that it will be useful, but it *
! is provided "as is" and without any express or implied warranties.   *
! For more details see the full text of the license in the file        *
! LICENSE or in <http://www.gnu.org/licenses/>.                        *
!                                                                      *
! Copyright (C) 2020, Roland Lindh                                     *
!***********************************************************************
Module Slapaf_Info
implicit none
Private
Public:: Cx, Gx, Gx0, NAC, Q_nuclear, dMass, Coor, Grd, ANr, Weights, Shift, GNrm, Lambda, &
         Energy, Energy0, DipM, MF, qInt, dqInt, nSup, Atom, RefGeo, &
         BM, dBM, iBM, idBM, nqBM, Free_Slapaf
!
! Arrays always allocated
!
Real*8, Allocatable:: Cx(:,:,:)     ! list of Cartesian coordinates
Real*8, Allocatable:: Gx(:,:,:)     ! list of Cartesian Gradients, State 1
Real*8, Allocatable:: Gx0(:,:,:)    ! list of Cartesian Gradients, State 2 for optimization of conical intersections
Real*8, Allocatable:: Q_nuclear(:)  ! list nuclear charges
Real*8, Allocatable:: dmass(:)      ! list atomic mass in units of (C=12)
Real*8, Allocatable:: Coor(:,:)     ! Cartesian coordinates of the last iteraction
Real*8, Allocatable:: Grd(:,:)      ! gradient of the last iteraction in Cartesian coordinates
Real*8, Allocatable:: Weights(:)    ! list of weights of ALL centers, however, the symmetry unique are first.
Real*8, Allocatable:: Shift(:,:)    ! list of displacements in Cartesian coordinates
Real*8, Allocatable:: GNrm(:)       ! list of the gradient norm for each iteration
Real*8, Allocatable:: Energy(:)     ! list of the energies of each iteration, State 1
Real*8, Allocatable:: Energy0(:)    ! list of the energies of each iteration, State 2 for optimization of conical intersections
Real*8, Allocatable:: MF(:,:)       ! list of Cartesian mode following vectors for each iteration
Real*8, Allocatable:: DipM(:,:)     ! list of dipole moments for each iteration
Real*8, Allocatable:: qInt(:,:)     ! internal coordinates for each iteration
Real*8, Allocatable:: dqInt(:,:)    ! derivatives of internal coordinates for each iteration
Real*8, Allocatable, Target:: RefGeo(:,:)   ! Reference geometry in Cartesian coordinates

! Arrays for automatic internal coordinates
Real*8, Allocatable:: BM(:)         ! ...
Real*8, Allocatable:: dBM(:)        ! ...
Integer, Allocatable:: iBM(:)       ! ...
Integer, Allocatable:: idBM(:)      ! ...
Integer, Allocatable:: nqBM(:)      ! ...

Integer, Allocatable:: ANr(:)       ! list of atomic numbers
!
! Arrays optionally allocated
!
Real*8, Allocatable:: NAC(:,:)      ! list of Cartesian non-adiabatic coupling vector
Real*8, Allocatable:: Lambda(:,:)     ! list of the Lagrange multipiers
!
! Utility arrays
!
Integer, Allocatable:: Atom(:), NSup(:)

Contains
  Subroutine Free_Slapaf()
#include "stdalloc.fh"
  If (Allocated(Energy)) Call mma_deallocate(Energy)
  If (Allocated(Energy0)) Call mma_deallocate(Energy0)
  If (Allocated(DipM)) Call mma_deallocate(DipM)
  If (Allocated(GNrm)) Call mma_deallocate(GNrm)
  If (Allocated(Cx)) Call mma_deallocate(Cx)
  If (Allocated(Gx)) Call mma_deallocate(Gx)
  If (Allocated(Gx0)) Call mma_deallocate(Gx0)
  If (Allocated(MF)) Call mma_deallocate(MF)
  If (Allocated(Lambda)) Call mma_deallocate(Lambda)

  If (Allocated(Q_nuclear)) Call mma_deallocate(Q_nuclear)
  If (Allocated(dMass)) Call mma_deallocate(dMass)
  If (Allocated(Coor)) Call mma_deallocate(Coor)
  If (Allocated(Grd)) Call mma_deallocate(Grd)
  If (Allocated(ANr)) Call mma_deallocate(ANr)
  If (Allocated(Weights)) Call mma_deallocate(Weights)
  If (Allocated(Shift)) Call mma_deallocate(Shift)
  If (Allocated(RefGeo)) Call mma_deallocate(RefGeo)

  If (Allocated(BM)) Call mma_deallocate(BM)
  If (Allocated(dBM)) Call mma_deallocate(dBM)
  If (Allocated(iBM)) Call mma_deallocate(iBM)
  If (Allocated(idBM)) Call mma_deallocate(idBM)
  If (Allocated(nqBM)) Call mma_deallocate(nqBM)

  If (Allocated(NAC)) Call mma_deallocate(NAC)
  If (Allocated(qInt)) Call mma_deallocate(qInt)
  If (Allocated(dqInt)) Call mma_deallocate(dqInt)
  End Subroutine Free_Slapaf
End Module Slapaf_Info
