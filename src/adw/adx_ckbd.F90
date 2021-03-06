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

!/@*
function adx_ckbd3(F_y,F_nfrom_n,F_nfrom_s) result(ier)
   implicit none
#include <arch_specific.hf>
   !@objective check if upstream points from north and south 
   !                 pe's for which an interpolation is requested are 
   !                 inside own advection source grid
   !@arguments
   integer :: F_nfrom_n, F_nfrom_s     !I, nb of N/S points outside adw grid
   real    :: F_y(F_nfrom_n+F_nfrom_s) !I, y upstream positions  
   !@returns
   integer :: ier
   !@author alain patoine
   !@revisions
   ! v3_10 - Corbeil & Desgagne & Lee - AIXport+Opti+OpenMP
   !@description
   ! The positions are strored in the following manner:
   ! adx_fro_n values followed by adx_fro_s values = adx_fro_a values
   !*@/
#include "adx_dims.cdk"
#include "adx_grid.cdk"
   integer :: n
   !---------------------------------------------------------------------
   ier = 0
!$omp parallel
!$omp do
   do n = 1,F_nfrom_n  ! adx_fro_n
      if (F_y(n) <= adx_yy_8(adx_lminy+1)) then
         print *,'*************************************************'
         print *,'*                                               *'
         print *,'* PROBLEM:  The upstream point from north pe    *'
         print *,'*           is south of advection source grid   *'
         print *,'*                                               *'
         print *,'*           South border  :',adx_yy_8(adx_lminy+1)
         print *,'*           Upstream point:',F_y(n)
         print *,'*************************************************'
         call flush(6)
         ier = -1
      endif
   enddo
!$omp enddo

!$omp do
   do n = F_nfrom_n+1, F_nfrom_n+F_nfrom_s  ! adx_fro_n+1,adx_fro_a
      if (F_y(n) >= adx_yy_8(adx_lmaxy-1)) then
         print *,'*************************************************'
         print *,'*                                               *'
         print *,'* PROBLEM:  The upstream point from south pe    *'
         print *,'*           is north of advection source grid   *'
         print *,'*                                               *'
         print *,'*           North border  :',adx_yy_8(adx_lmaxy-1)
         print *,'*           Upstream point:',F_y(n)
         print *,'*************************************************'
         call flush(6)
         ier = -1
      endif
   enddo
!$omp enddo
!$omp end parallel
   !---------------------------------------------------------------------
   return
end function adx_ckbd3

