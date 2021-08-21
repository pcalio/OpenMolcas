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
* Copyright (C) 1996-2006, Thorstein Thorsteinsson                     *
*               1996-2006, David L. Cooper                             *
************************************************************************
      subroutine psym_cvb(civec)
      implicit real*8 (a-h,o-z)
#include "main_cvb.fh"
#include "optze_cvb.fh"
#include "files_cvb.fh"
#include "print_cvb.fh"

#include "WrkSpc.fh"
      dimension civec(*)
      dimension dum(mxirrep)
c  *********************************************************************
c  *                                                                   *
c  *  PSYM      := Project CASSCF vector onto irrep(s).                *
c  *                                                                   *
c  *********************************************************************

      icivec=nint(civec(1))
      call psym1_cvb(work(iaddr_ci(icivec)),work(iaddr_ci(icivec)),dum,
     >               1)
      return
      end
