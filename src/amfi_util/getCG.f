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
      real*8 function  getCG(                                           &
     &j1,                                                               & ! integer  2*j1
     &j2,                                                               & ! integer  2*j2
     &j3,                                                               & ! integer  2*j3
     &m1,                                                               & ! integer  2*m1
     &m2,                                                               & ! integer  2*m2
     &m3)     ! integer  2*m2
!bs this routine calculates the Clebsch-Gordan-coefficients
!bs by actually calculating the 3j-symbol
!bs  ---                 ---
!bs  |  j1   j2    |   j3   |         j1+m1+j2-m2
!bs  |             |        |  =  (-)                 sqrt (2  j3+1) *
!bs  |  m1   m2    |   m3   |
!bs  ---                 ---
!bs
!bs                             ---             ---
!bs                             |  j1   j2   j3   |
!bs                             |                 |
!bs                             |  m1   m2  -m3   |
!bs                              ---            ---
      implicit real*8(a-h,o-z)
!bs   initialize CG-coefficient
      getCG=0d0
!bs   quick check
      if (m1+m2.ne.m3) return
      if (j1.lt.0.or.j2.lt.0.or.j3.lt.0) return
!bs   check the correct sign    beginning
      idummy=(j1+j2+m1-m2)/2
      if (mod(idummy,2).eq.0) then
      isign=1
      else
      isign=-1
      endif
!bs   check the correct sign    end
      fac1=sqrt(DBLE(j3+1))
      fac2=regge3j(j1,j2,j3,m1,m2,-m3)
      getCG=DBLE(isign)*fac1*fac2
      return
      end
