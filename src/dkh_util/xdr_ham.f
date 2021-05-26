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
! Copyright (C) 2011, Daoling Peng                                     *
!***********************************************************************
!----------------------------------------------------------------------|
      subroutine XDR_Ham(nbas,isize,jsize,imethod,paratyp,dkhorder,     &
     &                   xorder,inS,inK,inV,inpVp,inUL,inUS,clight)
!
!  ------------------------------------------------------------------------------------------
!
!  Implementation of the scalar-relativistic
!     Arbitrary Order  DKH (Douglas-Kroll-Hess)
!     eXact Decoupling X2C (eXact-2-Component)
!     eXact Decoupling BSS (Barysz-Sadlej-Snijders)
!  transformations for Hamiltonian and property integrals
!
!  Written by Daoling Peng, ETH Zurich, 2011
!
!
!  Reference to the generalized arbitrary/infinite-order DKH method:
!
!     A. Wolf, M. Reiher, B.A. Hess, J. Chem. Phys. 117 (2002) 9215-9226
!     M. Reiher, A. Wolf, J.Chem.Phys. 121 (2004) 2037-2047   partI   [Theory]
!     M. Reiher, A. Wolf, J.Chem.Phys. 121 (2004) 10945-10956 partII  [Algorithm]
!     A. Wolf, M. Reiher, J.Chem.Phys. 124 (2006) 064102      partIII [Properties-Theory]
!     A. Wolf, M. Reiher, J.Chem.Phys. 124 (2006) 064103      partIV  [Properties-Implementation]
!     D. Peng, K. Hirao,  J.Chem.Pyhs. 130 (2009) 044102      [Polynomial cost algorithm]
!
!  Reference to the exact decoupling X2C method:
!
!     W. Kutzelnigg, W. Liu, J.Chem.Phys. 123 (2005) 241102   [Theory]
!     W. Liu, D. Peng, J.Chem.Phys. 125 (2006) 044102         [Implementation]
!     D. Peng, W. Liu, Y. Xiao, L. Cheng, J.Chem.Phys. 127 (2007) 104106   [Implementation]
!
!  Reference to the exact decoupling BSS method:
!
!     M. Barysz, A. J. Sadlej, J. G. Snijders, Int.J.QuantumChem. 65 (1997) 225-239   [Theory]
!     D. Kedziera, M. Barysz, Chem.Phys.Lett. 446 (2007) 176-181   [Non-iterative scheme]
!
!  ----------------------------------------------------------------------------------------------
!
!  Input:
!
!     nbas         number of basis functions ( dimension of matrix )
!     isize        =nbas*(nbas+1)/2  number of elements in triangle matrix
!     jsize        =nbas*nbas number of elements in square matrix
!     imethod      { 1 : DKH, 2 : X2C, 3 : BSS }
!     paratyp      parameterization of DKH unitary transformation
!     dkhorder     order of DKH for Hamiltonian
!     xorder       order of DKH for property integrals
!                  >0, do transformation for exact decoupling methods
!     clight       speed of light in atomic unit
!     inS(isize)   overlap matrix
!     inV(isize)   external potential
!     inpVp(isize) matrix representation of <pxVpx>+<pyVpy>+<pzVpz>
!     inK(isize)   non-relativistic kinetic matrix <p**2>/2
!
!  Output
!
!     inK(isize)   relativistic transformed one-electron Hamiltonian matrix
!     inUL(jsize)  store the relativistic transformation matrix ( Large component part )
!     inUS(jsize)  store the relativistic transformation matrix ( Small component part )
!
!  -----------------------------------------------------------------------------------------
!
      implicit none
#include "WrkSpc.fh"
! Input variables
      integer nbas,isize,jsize,imethod,paratyp,dkhorder,xorder
      Real*8 clight
      Real*8 inS(isize),inV(isize),inpVp(isize)
! Input/Output variables
      Real*8 inK(isize)
! Output variables
      Real*8 inUL(jsize),inUS(jsize)
! Local variables
      integer nn,i,j,k
      integer jS,jK,jV,jpVp
!
! Convert triangle matrices to square matrices
!
      nn = nbas*nbas+4
      call getmem('skin ','ALLOC','REAL',jK   ,nn)
      call getmem('sSS  ','ALLOC','REAL',jS   ,nn)
      call getmem('sV   ','ALLOC','REAL',jV   ,nn)
      call getmem('spVp ','ALLOC','REAL',jpVp ,nn)
      k = 0
      do i=1,nbas
        do j=1,i
          k = k + 1
          Work(jK + j-1 + (i-1)*nbas ) = inK(k)
          Work(jS + j-1 + (i-1)*nbas ) = inS(k)
          Work(jV + j-1 + (i-1)*nbas ) = inV(k)
          Work(jpVp + j-1 + (i-1)*nbas ) = inpVp(k)
          if(i.ne.j)then
            Work(jK + i-1 + (j-1)*nbas ) = inK(k)
            Work(jS + i-1 + (j-1)*nbas ) = inS(k)
            Work(jV + i-1 + (j-1)*nbas ) = inV(k)
            Work(jpVp + i-1 + (j-1)*nbas ) = inpVp(k)
          end if
        end do
      end do
!
! Calculate relativistic one-electron Hamiltonian
!
      if(imethod.eq.2)then
!
! Call X2C driver
!
        call x2c_ts1e(nbas,Work(jS),Work(jK),Work(jV),Work(jpVp),       &
     &                inUL,inUS,clight )
      else if(imethod.eq.3)then
!
! Call BSS driver
!
        call bss_ts1e(nbas,Work(jS),Work(jK),Work(jV),Work(jpVp),       &
     &                inUL,inUS,clight )
      else if(imethod.eq.1)then
!
! Call arbitrary order DKH driver
!
        call dkh_ts1e(nbas,Work(jS),Work(jK),Work(jV),Work(jpVp),       &
     &                inUL,inUS,clight,dkhorder,xorder,paratyp )
      end if
!
! Copy relativistic one-electron Hamiltonian back to inK
!
      k=0
      do i=1,nbas
        do j=1,i
          k=k+1
          inK(k)=Work(jV+j-1+(i-1)*nbas)
        end do
      end do
!
! Free temp memories
!
      call getmem('skin ','FREE','REAL',jK   ,nn)
      call getmem('sSS  ','FREE','REAL',jS   ,nn)
      call getmem('sV   ','FREE','REAL',jV   ,nn)
      call getmem('spVp ','FREE','REAL',jpVp ,nn)
!
      return
      end
