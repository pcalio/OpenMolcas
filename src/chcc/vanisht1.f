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
        subroutine VanishT1 (wrk,wrksize)
c
c        this routine do:
c        Vanish T1o
c
        implicit none
#include "chcc1.fh"
#include "wrk.fh"
c
c        help variables
        integer len
c
        len=no*nv
        call mv0zero (len,len,wrk(PossT1o))
c
        return
        end
