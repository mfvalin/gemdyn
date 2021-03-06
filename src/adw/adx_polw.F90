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

subroutine adx_polw()
   implicit none
#include <arch_specific.hf>
   !---------------------------------------------------------------------
   call stop_mpi(STOP_ERROR,'adx_polw','called a stub')
   !---------------------------------------------------------------------
   return
end subroutine adx_polw

subroutine adx_polw2()
   implicit none
#include <arch_specific.hf>
   !---------------------------------------------------------------------
   call stop_mpi(STOP_ERROR,'adx_polw2','called a stub')
   !---------------------------------------------------------------------
   return
end subroutine adx_polw2

!/@*
subroutine adx_polw3(F_u, F_v, F_j, F_aminx,F_amaxx,F_aminy,F_amaxy, F_lni,F_lnj, F_halox,F_haloy, F_nk )
   implicit none
#include <arch_specific.hf>
   !@objective calculate pole values for wind components
   !@arguments
   integer :: F_aminx,F_amaxx,F_aminy,F_amaxy !I, adw local array bounds
   integer :: F_lni, F_lnj, F_nk !I, Field computational area dims
   integer :: F_halox, F_haloy   !I, Field halo dims
   integer :: F_j                !I, j position to fill
   real,dimension(F_aminx:F_amaxx,F_aminy:F_amaxy, F_nk)::&
        F_u, F_v                 !I/O, wind components to treat
   !@author alain patoine
   !@revisions
   ! v3_21 - Desgagne M.       - Revision Openmp
   !*@/
#include "adx_grid.cdk"
   integer :: i,j,k
   real*8  :: vx, vy, coef1, coef2
   !---------------------------------------------------------------------
   if (F_j==0) then
      j     =  1
      coef1 = -1.0
      coef2 =  1.0
   else
      j     =  F_lnj
      coef1 =  1.0
      coef2 = -1.0
   endif

!$omp do
   do k = 1,F_nk
      vx = 0.0
      vy = 0.0
      do i=1,F_lni
         vx = vx + adx_wx_8(i) * (adx_sx_8(i) * dble(F_u(i,j,k)) &
                 + adx_cx_8(i) *  adx_sy_8(j) * dble(F_v(i,j,k)))
         vy = vy + adx_wx_8(i) * (adx_cx_8(i) * dble(F_u(i,j,k)) &
                 - adx_sx_8(i) *  adx_sy_8(j) * dble(F_v(i,j,k)))
      enddo

      do i=1,F_lni
         F_u(i,F_j,k) =         vx * adx_sx_8(i) +         vy * adx_cx_8(i)
         F_v(i,F_j,k) = coef1 * vx * adx_cx_8(i) + coef2 * vy * adx_sx_8(i)
      enddo

      do i = 1, F_halox
         F_u(F_lni+i,F_j,k) = F_u(i        ,F_j,k)
         F_v(F_lni+i,F_j,k) = F_v(i        ,F_j,k)
         F_u(1-i    ,F_j,k) = F_u(F_lni+1-i,F_j,k)
         F_v(1-i    ,F_j,k) = F_v(F_lni+1-i,F_j,k)
      enddo
   enddo
!$omp enddo
   !---------------------------------------------------------------------
   return
end subroutine adx_polw3

