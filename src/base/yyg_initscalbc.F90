!---------------------------------- LICENCE BEGIN -------------------------------
! GEM - Library of kernel routines for the GEM numerical atmospheric model
! Copyright (C) 1990-2010 - Division de Recherche en Prevision Numerique
!                       Environnement Canada
! This library is free software; you can redistribute it and/or modify it
! under the terms of the GNU Lesser General Public License as published by
! the Free Software Foundation, version 2.1 of the License. This library is
! distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
! without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
! PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
! You should have received a copy of the GNU Lesser General Public License
! along with this library; if not, write to the Free Software Foundation, Inc.,
! 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
!---------------------------------- LICENCE END ---------------------------------
!***s/r yyg_initscalbc - to initialize communication pattern for scalar fields
!


      Subroutine yyg_initscalbc()
      implicit none
#include <arch_specific.hf>
!
!author
!           Abdessamad Qaddouri/ V.lee - October 2009
!
!     setup nearest and linear interpolation communication pattern
      call yyg_initscalbc0()
!     setup cubic interpolation communication pattern
      call yyg_initscalbc2()

      return
      end

