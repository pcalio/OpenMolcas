************************************************************************
* This file is part of OpenMolcas.                                     *
*                                                                      *
* OpenMolcas is free software; you can redistribute it and/or modify   *
* it under the terms of the GNU Lesser General Public License, v. 2.1. *
* OpenMolcas is distributed in the hope that it will be useful, but it *
* is provided "as is" and without any express or implied warranties.   *
* For more details see the full text of the license in the file        *
* LICENSE or in <http://www.gnu.org/licenses/>.                        *
*                                                                      *
* Copyright (C) 2020, Ignacio Fdez. Galvan                             *
************************************************************************

      subroutine False_Program(rc)
      use False_Global, only: Run_Command, Will_Print
      implicit none
      integer, intent(out) :: rc
      character(len=180) :: InFile,OutFile
      integer :: n
      integer, external :: iPrintLevel
      logical, external :: Reduce_Prt
#include "para_info.fh"

      rc = 0

      Will_Print = (iPrintLevel(-1) >= 2) .and. (.not. Reduce_Prt())

      call Read_Input()

      ! only the master process calls the external program
      if (King()) then
        call Write_Input()

        call PrgmTranslate('INPUT',InFile,n)
        call PrgmTranslate('OUTPUT',OutFile,n)
        if (Will_Print) then
          write(6,100) 'Command to run:  '//trim(Run_Command)
          write(6,100) 'First argument:  '//trim(InFile)
          write(6,100) 'Second argument: '//trim(OutFile)
        end if
        call SystemF(trim(Run_Command)
     &     //' '//trim(InFile)//' '//trim(OutFile),rc)
      end if

#ifdef _MOLCAS_MPP_
      ! files of interest are broadcasted to all slaves
      if (Is_Real_Par()) then
        call GA_Sync()
        call PFGet_ASCII('INPUT')
        call PFGet_ASCII('OUTPUT')
        call GA_Sync()
      end if
#endif

      call Write_Data()
      return

100   format(A)
      end subroutine False_Program
