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
! Copyright (C) 1994, Niclas Forsberg                                  *
!***********************************************************************
!!-----------------------------------------------------------------------!
!!
      Subroutine Freq_mula(Hess,G,V,Lambda,B,Bnew,qMat,nOsc,NumOfAt)
!!
!!  Purpose:
!!    Find eigenvalues and eigenvectors of FG matrix.
!!    The eigenvalues are stored in the array Lambda and the eigen-
!!    vectors are stored as the columns of the matrix V.
!!    The eigenvectors are then used to calculate the cartesian
!!    displacements, which are stored in matrix X.
!!
!!  Input:
!!    Hess     : Real*8 two dimensional array -  contains
!!               the force constants expressed in internal
!!    G        : Real*8 two dimensional array.
!!    B        : Real*8 two dimensional array.
!!    Bnew     : Real*8 two dimensional array.
!!
!!  Output:
!!    V        : Real*8 two dimensional array  - contains
!!               the eigenvectors of F*G as columns.
!!    Lambda   : Real*8 array  - contains the eigenvalues
!!               of F*G.
!!    qMat     : Real*8 array - contains the cartesian
!!               displacements of the atoms.
!!
!!  Local:
!!    U,Tmp    : Real*8 two dimensional arrays.
!!
!!  Uses:
!!    LinAlg
!!
!!  Written by:
!!    Niclas Forsberg,
!!    Dept. of Theoretical Chemistry, Lund University, 1994.
!!
      Implicit Real*8 ( a-h,o-z )
#include "Constants_mula.fh"
      Real*8 Hess(nOsc,nOsc),G(nOsc,nOsc),V(nOsc,nOsc)
      Real*8 B(3*NumOfAt,nOsc),Bnew(3*NumOfAt,nOsc),                    &
     &  qMat(3*NumOfAt,nOsc)
      Real*8 Lambda(nOsc)
#include "WrkSpc.fh"

!!
!!---- Get dimensions.
      NumInt  = nOsc
!!
!!---- Solve secular equation.
      Call SolveSecEq(Hess,NumInt,V,G,Lambda)
!!
!!---- get memory space for U.
      Call GetMem('U','Allo','Real',ipU,nOsc*nOsc)
!!
!!---- Copy matrix containing eigenvectors to U, because this matrix
!!     will be destroyed when subroutine Dool_MULA is called.
      nSqrInt = NumInt**2
      call dcopy_(nSqrInt,V,1,Work(ipU),1)
!!
!!     Calculate the cartesian diplacements, i.e. solve
!!
!!              qMat = B * ( B(T) * B )^(-1) * V.
!!
!!---- get memory for matrix Temp.
      Call GetMem('Temp','Allo','Real',ipTemp,nOsc*nOsc)
!!
      Call DGEMM_('T','N',                                              &
     &            NumInt,NumInt,3*NumOfAt,                              &
     &            1.0d0,B,3*NumOfAt,                                    &
     &            B,3*NumOfAt,                                          &
     &            0.0d0,Work(ipTemp),NumInt)
      Call Dool_MULA(Work(ipTemp),NumInt,NumInt,Work(ipU),              &
     &  NumInt,NumInt,Det)
      Call DGEMM_('N','N',                                              &
     &            3*NumOfAt,NumInt,NumInt,                              &
     &            1.0d0,B,3*NumOfAt,                                    &
     &            Work(ipU),NumInt,                                     &
     &            0.0d0,qMat,3*NumOfAt)
!!
!!---- free memory space of Temp and U.
      Call GetMem('U','Free','Real',ipU,nOsc*nOsc)
      Call GetMem('Temp','Free','Real',ipTemp,nOsc*nOsc)
!!
! Avoid unused argument warnings
      If (.False.) Call Unused_real_array(Bnew)
      End
