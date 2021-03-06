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
#include "stop_mpi.h"

subroutine adx_polx()
   implicit none
#include <arch_specific.hf>
   !---------------------------------------------------------------------
   call stop_mpi(STOP_ERROR,'adx_polx','called a stub')
   !---------------------------------------------------------------------
   return
end subroutine adx_polx

subroutine adx_polx2()
   implicit none
#include <arch_specific.hf>
   !---------------------------------------------------------------------
   call stop_mpi(STOP_ERROR,'adx_polx2','called a stub')
   !---------------------------------------------------------------------
   return
end subroutine adx_polx2

!/@*
subroutine adx_polx3(F_field, F_sud, F_aminx,F_amaxx,F_aminy,F_amaxy, &
     F_lni,F_lnj, F_halox,F_haloy, F_nk )
   implicit none
#include <arch_specific.hf>
   !@objective extension of a scalar field beyond the poles in view of cubic lagrange interpolation along the north-south direction
   !@arguments
   integer :: F_lni, F_lnj, F_nk !I, Field computational area dims
   integer :: F_halox, F_haloy   !I, Field halo dims
   integer :: F_aminx,F_amaxx,F_aminy,F_amaxy !I, adw local array bounds
   logical :: F_sud              !I, .T.=S-Pole ; .F.=N-Pole
   real,dimension(F_aminx:F_amaxx,F_aminy:F_amaxy, F_nk):: &
        F_field                  !I/O, field to treat
   !@author alain patoine
   !@revisions
   ! v3_21 - Desgagne M.           - Revision Openmp
!*@/
#include "adx_grid.cdk"
#include "adx_poles.cdk"

   integer :: ns, nd, i, i2, k
   real :: e(0:F_lni+49) !TODO: why 49?

   ! Basic statement functions for cubic int. on a non-uniform mesh
   real triprd, delta, poly
   real*8 y, y1, y2, y3, y4
   real v1, v2, v3, v4
   triprd(y1, y2, y3, y4) = (y1 - y2) * (y1 - y3) * (y1 - y4)

   ! triprd is fully symmetric in y2, y3, y4.
   ! and hence delta is symmetric in y2, y3, y4.
   delta(y, y1, y2, y3, y4) = triprd(y, y2, y3, y4) / triprd(y1, y2, y3, y4)

   ! delta is a cubic in y which asumes the value 1.0 at y = y1,
   ! and the value 0.0 for y = y2, y3, y4.
   ! consequently a cubic which takes the values v1, v2, v3, v4 at
   ! y = y1, y2, y3, y4, is
   poly(v1, v2, v3, v4, y, y1, y2, y3, y4) = &
        v1 * delta(y, y1, y2, y3, y4) + &
        v2 * delta(y, y2, y1, y3, y4) + &
        v3 * delta(y, y3, y1, y2, y4) + &
        v4 * delta(y, y4, y1, y2, y3)
   !---------------------------------------------------------------------
   ns = F_lnj
   if (F_sud) ns = 1
   nd = F_lnj+2
   if (F_sud) nd = -1

!$omp do
   do k = 1, F_nk
      e(0)         = F_field(F_lni, ns, k)
      e(F_lni + 1) = F_field(1,     ns, k)
      e(F_lni + 2) = F_field(2,     ns, k)

      do i = 1, F_lni
         e(i) = F_field(i,ns,k)
      enddo

      do i = 1, F_lni
         i2 = adx_iln(i)
         F_field(i,nd,k) = poly(e(i2-1),e(i2),e(i2+1),e(i2+2),adx_lnr_8(i), &
              adx_xg_8(i2-1),adx_xg_8(i2),adx_xg_8(i2+1),adx_xg_8(i2+2))
      enddo

      do i = 1, F_halox
         F_field(F_lni+i,nd,k) = F_field(i,        nd,k)
         F_field(1-i,    nd,k) = F_field(F_lni+1-i,nd,k)
      enddo
   enddo
!$omp enddo
   !---------------------------------------------------------------------
   return
end subroutine adx_polx3

