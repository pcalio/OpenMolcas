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

subroutine StartLight(ModuleName)

#ifndef _HAVE_EXTRA_
use Prgm, only: prgmfree
#endif
use Definitions, only: u5

implicit none
character(len=*), intent(in) :: ModuleName
character(len=100) :: SuperName
character(len=100), external :: Get_SuperName
#include "timtra.fh"

!                                                                      *
!***********************************************************************
!                                                                      *
! Statistics

nfld_tim = 0
nfld_stat = 0
!                                                                      *
!***********************************************************************
!                                                                      *
call prgmfree()
call prgminit(ModuleName)
!                                                                      *
!***********************************************************************
!                                                                      *
! Unix-related information must be set or checked here or later,
! PID and master/slave status may not have been set before now.
! (DO NOT MOVE FROM HERE)

SuperName = Get_SuperName()
call UnixInfo(SuperName,ModuleName)

close(u5)
call molcas_open(u5,'stdin')
!                                                                      *
!***********************************************************************
!                                                                      *
! Initiate I/O

call FIOInit()
!                                                                      *
!***********************************************************************
!                                                                      *
! Statistics, release old fields

call IniTim()
call IniStat()

return

end subroutine StartLight
