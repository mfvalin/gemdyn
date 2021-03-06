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

!**s/r out_mergeyy
!
      subroutine out_mergeyy (F_vec, n)
use iso_c_binding
      implicit none
#include <arch_specific.hf>

      integer n
      real F_vec(n,2)
!
!author
!    Michel Desgagne - Fall 2012
!
!revision
! v4_50 - Desgagne M. - Initial version

#include "ptopo.cdk"
      include "rpn_comm.inc"

      integer tag, status, err
!
!----------------------------------------------------------------------
!
      tag= 401
      if (Ptopo_couleur.eq.0) then
         call RPN_COMM_recv ( F_vec(1,2), n, 'MPI_REAL', 1, &
                              tag, 'GRIDPEERS', status, err )
      else
         call RPN_COMM_send ( F_vec     , n, 'MPI_REAL', 0, &
                              tag, 'GRIDPEERS',         err )
      endif
!
!----------------------------------------------------------------------
!
      return
      end


