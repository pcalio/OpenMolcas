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
Module ThermoChem
implicit none
Private
Public:: lTherm, lDoubleIso, nUserPT, nsRot, UserT, UserP
#include "real.fh"
Integer :: i

Logical ::  lTherm=.False., lDoubleIso=.False.
Integer ::  nUserPT=0, nsRot=0
Real*8  ::  UserT(64)=[(Zero,i=1,64)], UserP=Zero
End Module ThermoChem
