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
      real*8 function  regge3j(                                         &
     &j1,                                                               & ! integer  2*j1
     &j2,                                                               & ! integer  2*j2
     &j3,                                                               & ! integer  2*j3
     &m1,                                                               & ! integer  2*m1
     &m2,                                                               & ! integer  2*m2
     &m3)     ! integer  2*m3
!bs   uses magic square of regge (see Lindner pp. 38-39)
!bs
!bs    ---                                            ---
!bs   |                                                  |
!bs   | -j1+j2+j3     j1-j2+j3         j1+j2-j3          |
!bs   |                                                  |
!bs   |                                                  |
!bs   |  j1-m1        j2-m2            j3-m3             |
!bs   |                                                  |
!bs   |                                                  |
!bs   |  j1+m1        j2+m2            j3+m3             |
!bs   |                                                  |
!bs    ---                                            ---
!bs
      implicit real*8(a-h,o-z)
      dimension MAT(3,3)
!BS   logical testup,testdown
      Integer facul,prim,nprim,iwork
      parameter (nprim=11,mxLinRE=36)
!bs   nprim is the number of prime-numbers
      dimension facul(nprim,0:mxLinRE),prim(nprim),                     &
     &iwork(nprim),ihigh(0:mxLinRE)
      data prim /2,3,5,7,11,13,17,19,23,29,31/        !prime numbers
!
!     decompose facultatives into powers of prime numbers
!
      Data facul / 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                     &
     &             0, 0 ,0, 0, 0, 0, 0, 0, 0, 0, 0,                     &
     &             1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                     &
     &             1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,                     &
     &             3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,                     &
     &             3, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,                     &
     &             4, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0,                     &
     &             4, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0,                     &
     &             7, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0,                     &
     &             7, 4, 1, 1, 0, 0, 0, 0, 0, 0, 0,                     &
     &             8, 4, 2, 1, 0, 0, 0, 0, 0, 0, 0,                     &
     &             8, 4, 2, 1, 1, 0, 0, 0, 0, 0, 0,                     &
     &            10, 5, 2, 1, 1, 0, 0, 0, 0, 0, 0,                     &
     &            10, 5, 2, 1, 1, 1, 0, 0, 0, 0, 0,                     &
     &            11, 5, 2, 2, 1, 1, 0, 0, 0, 0, 0,                     &
     &            11, 6, 3, 2, 1, 1, 0, 0, 0, 0, 0,                     &
     &            15, 6, 3, 2, 1, 1, 0, 0, 0, 0, 0,                     &
     &            15, 6, 3, 2, 1, 1, 1, 0, 0, 0, 0,                     &
     &            16, 8, 3, 2, 1, 1, 1, 0, 0, 0, 0,                     &
     &            16, 8, 3, 2, 1, 1, 1, 1, 0, 0, 0,                     &
     &            18, 8, 4, 2, 1, 1, 1, 1, 0, 0, 0,                     &
     &            18, 9, 4, 3, 1, 1, 1, 1, 0, 0, 0,                     &
     &            19, 9, 4, 3, 2, 1, 1, 1, 0, 0, 0,                     &
     &            19, 9, 4, 3, 2, 1, 1, 1, 1, 0, 0,                     &
     &            22,10, 4, 3, 2, 1, 1, 1, 1, 0, 0,                     &
     &            22,10, 6, 3, 2, 1, 1, 1, 1, 0, 0,                     &
     &            23,10, 6, 3, 2, 2, 1, 1, 1, 0, 0,                     &
     &            23,13, 6, 3, 2, 2, 1, 1, 1, 0, 0,                     &
     &            25,13, 6, 4, 2, 2, 1, 1, 1, 0, 0,                     &
     &            25,13, 6, 4, 2, 2, 1, 1, 1, 1, 0,                     &
     &            26,14, 7, 4, 2, 2, 1, 1, 1, 1, 0,                     &
     &            26,14, 7, 4, 2, 2, 1, 1, 1, 1, 1,                     &
     &            31,14, 7, 4, 2, 2, 1, 1, 1, 1, 1,                     &
     &            31,15, 7, 4, 3, 2, 1, 1, 1, 1, 1,                     &
     &            32,15, 7, 4, 3, 3, 1, 1, 1, 1, 1,                     &
     &            32,15, 8, 5, 3, 3, 1, 1, 1, 1, 1,                     &
     &            34,17, 8, 5, 3, 3, 1, 1, 1, 1, 1/
!
      data ihigh /0,0,1,2,2,3,3,4,4,4,4,5,5,                            &
     &            6,6,6,6,7,7,8,8,8,8,9,9,9,                            &
     &            9,9,9,10,10,11,11,11,11,11,11/
!bs  facul,   integer array (nprim,0:mxLinRE) prime-expansion of factorials
!bs  mxLinRE,    integer max. number for facul is given
!bs  nprim,   number of primes for expansion of factorials
!bs  prim,    integer array with the first nprim prime numbers
!bs  iwork)   integer array of size nprim
      regge3j=0d0
!     write(6,'(A24,6I3)') '3J to be calculated for ',
!    *j1,j2,j3,m1,m2,m3
!bs   quick check  if =/= 0 at all
      icheck=m1+m2+m3
      if (icheck.ne.0) then
!     write(6,*) 'sum over m =/= 0'
      return
      endif
!bs   check triangular relation (|j1-j2|<= j3 <= j1+j2 )
      imini=iabs(j1-j2)
      imaxi=j1+j2
      if (j3.lt.imini.or.j3.gt.imaxi) then
!     write(6,*) 'triangular relation not fulfilled'
      return
      endif
!bs   quick check  if =/= 0 at all  end
!bs
!bs   3J-symbol is not zero by simple rules
!bs
!bs   initialize MAT
      MAT(1,1) =-j1+j2+j3
      MAT(2,1) =j1-m1
      MAT(3,1) =j1+m1
      MAT(1,2) =j1-j2+j3
      MAT(2,2) =j2-m2
      MAT(3,2) =j2+m2
      MAT(1,3) =j1+j2-j3
      MAT(2,3) =j3-m3
      MAT(3,3) =j3+m3
      do I=1,3
      do J=1,3
!bs   check for even numbers (2*integer) and positive or zero
      if (mod(MAT(J,I),2).ne.0.or.MAT(J,I).lt.0)  then
!     write(6,*) 'J,I,MAT(J,I): ',J,I,MAT(J,I)
      return
      endif
      MAT(J,I)=MAT(J,I)/2
      if (Mat(j,i).gt.mxLinRE)                                          &
     &Call SysAbendMsg('regge3j','increase mxLinRE for regge3j',' ')
      enddo
      enddo
      Isigma=(j1+j2+j3)/2
!bs   check the magic sums
      do I=1,3
      IROW=0
      ICOL=0
      do J=1,3
      IROW=IROW+MAT(I,J)
      ICOL=ICOL+MAT(J,I)
      enddo
      if (IROW.ne.Isigma.or.ICOL.ne.Isigma) then
!     write(6,*) 'I,IROW,ICOL ',I,IROW,ICOL
      return
      endif
      enddo
!bs   if j1+j2+j3 is odd: check for equal rows or columns
      Isign=1
      if (iabs(mod(Isigma,2)).eq.1) then
      isign=-1
         do I=1,3
         do J=I+1,3
            if (MAT(1,I).eq.MAT(1,J).and.                               &
     &         MAT(2,I).eq.MAT(2,J).and.                                &
     &         MAT(3,I).eq.MAT(3,J)) return
            if (MAT(I,1).eq.MAT(J,1).and.                               &
     &         MAT(I,2).eq.MAT(J,2).and.                                &
     &         MAT(I,3).eq.MAT(J,3)) return
         enddo
         enddo
      endif
!bs   look for the lowest element indices: IFIRST,ISECOND
      imini=MAT(1,1)
      IFIRST=1
      ISECOND=1
      do I=1,3
      do J=1,3
      if (MAT(J,I).lt.imini) then
      IFIRST=J
      ISECOND=I
      imini=MAT(J,I)
      endif
      enddo
      enddo
!     write(6,*) 'Matrix before commuting vectors'
      do ibm=1,3
!     write(6,'(3I5)') (Mat(ibm,j),j=1,3)
      enddo
      if (IFIRST.ne.1) then  !interchange rows
!     write(6,*) 'IFIRST = ',ifirst
      do I=1,3
      IDUMMY=MAT(1,I)
      MAT(1,I)=MAT(IFIRST,I)
      MAT(IFIRST,I)=IDUMMY
      enddo
      endif
      if (ISECOND.ne.1) then  !interchange columns
!     write(6,*) 'ISECOND = ',isecond
      do I=1,3
      IDUMMY=MAT(I,1)
      MAT(I,1)=MAT(I,ISECOND)
      MAT(I,ISECOND)=IDUMMY
      enddo
      endif
!bs   lowest element is now on (1,1)
!     write(6,*) 'Matrix after commuting vectors'
!     do ibm=1,3
!     write(6,'(3I5)') (Mat(ibm,j),j=1,3)
!     enddo
!bs   begin to calculate Sum over s_n
!bs   first the simple cases
      if (Mat(1,1).eq.0) then
      isum=1
      elseif (Mat(1,1).eq.1) then
      isum=Mat(2,3)*Mat(3,2)-Mat(2,2)*Mat(3,3)
      elseif (Mat(1,1).eq.2) then
      isum=Mat(2,3)*(Mat(2,3)-1)*Mat(3,2)*(Mat(3,2)-1)-                 &
     &2*Mat(2,3)*Mat(3,2)*Mat(2,2)*Mat(3,3)+                            &
     &Mat(2,2)*(Mat(2,2)-1)*Mat(3,3)*(Mat(3,3)-1)
      else !  all the cases with Mat(1,1) >= 3
              Icoeff=1
              do Ibm=Mat(3,2)-Mat(1,1)+1,Mat(3,2)
                icoeff=icoeff*ibm
              enddo
              do Ibm=Mat(2,3)-Mat(1,1)+1,Mat(2,3)
                icoeff=icoeff*ibm
              enddo
              isum=icoeff
              do Icount=1,MAT(1,1)
                 icoeff=-icoeff*(Mat(1,1)+1-icount)*(Mat(2,2)+1-icount)*&
     &           (Mat(3,3)+1-icount)
                 Idenom=icount*(Mat(2,3)-Mat(1,1)+icount)*              &
     &           (Mat(3,2)-Mat(1,1)+icount)
                 icoeff=icoeff/Idenom
                 isum=isum+icoeff
              enddo
      endif
!bs  additional sign from interchanging rows or columns
      if (ifirst.ne.1) isum=isum*isign
      if (isecond.ne.1) isum=isum*isign
!     write(6,*) 'isum = ',isum
!bs       Mat(2,3)+Mat(3,2)
!bs    (-)
      if (iabs(mod((Mat(2,3)+Mat(3,2)),2)).eq.1) isum=-isum
!bs   final factor
      LIMIT=ihigh(max(Mat(1,1),Mat(1,2),Mat(1,3),                       &
     &Mat(2,1),Mat(2,2),Mat(2,3),Mat(3,1),Mat(3,2),                     &
     &Mat(3,3),(Isigma+1)))
      do I=1,LIMIT
      iwork(I)=facul(I,Mat(1,2))+facul(I,Mat(2,1))+                     &
     &facul(I,Mat(3,1))+facul(I,Mat(1,3))-                              &
     &facul(I,Mat(1,1))-facul(I,Mat(2,2))-                              &
     &facul(I,Mat(3,3))-facul(I,(Isigma+1))-                            &
     &facul(I,Mat(2,3))-facul(I,Mat(3,2))
      enddo
!     write(6,*) 'Iwork: ',(iwork(i),i=1,LIMIT)
      factor=1d0
!bs   iup=1
!BS   idown=1
!BS   testup=.true.
!BS   testdown=.true.
!BS   do I=1,LIMIT
!BS   do J=1,iwork(I)
!BS   iup=iup*prim(i)
!BS   if (iup.lt.0) testup=.false. !check for Integer overflow
!BS   enddo
!BS   Enddo
!BS   up=DBLE(iup)
!BS   if(.not.testup) then ! if the integers did not run correctly
              up=1d0
              do I=1,LIMIT
              do J=1,iwork(I)
              up=up*DBLE(prim(i))
              enddo
              enddo
!BS   endif
!BS   do I=1,LIMIT
!BS   do J=1,-iwork(I)
!BS   idown=idown*prim(i)
!BS   if (idown.lt.0) testdown=.false.
!BS   enddo
!BS   enddo
!BS   down=DBLE(idown)
!BS   if(.not.testdown) then
              down=1d0
              do I=1,LIMIT
              do J=1,-iwork(I)
              down=down*DBLE(prim(i))
              enddo
              enddo
!BS   endif
!     if (.not.(testup.and.testdown)) then
!     write(6,*) 'j1,j2,j3,m1,m2,m3 ',j1,j2,j3,m1,m2,m3
!     write(6,*) 'iup,idown ',iup,idown,'up,down ',up,down
!     endif
      factor=factor*up/down
!bs   final result
      regge3j=sqrt(factor)*DBLE(isum)
      return
      end
