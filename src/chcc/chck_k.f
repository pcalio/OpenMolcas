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
        subroutine Chck_K (K,dimbe,addbe,dima,adda)
c
c        check K(be,u,i,a)
c
        implicit none
#include "chcc1.fh"
        integer dimbe,addbe,dima,adda
        real*8 K(1:dimbe,1:no,1:no,1:dima)
c
        integer be,u,i,a,bad
        real*8 s
c
        bad=0
        do a=adda+1,adda+dima
        do i=1,no
        do u=1,no
        do be=addbe+1,addbe+dimbe
c
          s=Kc(i,be,u,a)
c
          if (abs(K(be-addbe,u,i,a-adda)-s).gt.1.0d-10) then
            bad=bad+1
          end if
c
        end do
        end do
        end do
        end do
c
        write (6,*) ' Chck K :',bad
c99        format (a9,1x,i8,1x,4(i3,1x))
c
        return
        end
