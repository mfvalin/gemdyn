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
#include "msg.h"
#include "stop_mpi.h"

subroutine adx_exch_1()
   call stop_mpi(STOP_ERROR,'adx_exch_1','called a deprecated sub')
   return
end subroutine adx_exch_1

subroutine adx_exch_1b()
   call stop_mpi(STOP_ERROR,'adx_exch_1b','called a deprecated sub')
   return
end subroutine adx_exch_1b

!/@*
subroutine adx_exch_1c(F_x_out,F_y_out,F_z_out,F_c_out,F_x_in,F_y_in,F_z_in, &
     F_ni,F_nj,F_k0,F_nk)
   implicit none
#include <arch_specific.hf>
   !@objective 
   !@arguments
   integer :: F_ni,F_nj,F_nk        !I, dims
   integer :: F_k0                  !I, vertical scope F_k0 to F_nk
   integer,dimension(F_ni*F_nj*F_nk) :: &
        F_c_out                    !O, 3D points coor with outside upstream pos
   real,dimension(F_ni*F_nj*F_nk) :: &
        F_x_out, F_y_out, F_z_out  !O, points coor with outside upstream pos
   real,dimension(F_ni,F_nj,F_nk) :: &
        F_x_in, F_y_in, F_z_in     !I, upstream positions
   !@author alain patoine
   !@revisions
   ! v2_31 - Corbeil L.        - replaced MPI calls by rpn_comm
   ! v3_00 - Desgagne & Lee    - Lam configuration
   ! V4.4  - Plante A.         - Added vertical scope parameter F_k0
   !@description
   !  Establish list and number of points for 
   !  which upstream positions are outside 
   !  advection source grid.
   !
   !  Fill output vectors with coordinates of these 
   !  upstream positions in preparation for exchange 
   !  with other processors.
   !
   !  Take note 3D coordinates of points for which
   !  upstream positions are outside advection source
   !  grid.
   !
   !  Exchange number of points to be exchanged to 
   !  allow temporary space allocation.
   ! 
   !  Move upstream positions that are outside advection source inside
   !  the domain (at j=1) so that interpolation performed on all points
   !  will be valid.
   !
   ! The positions are stored  in the following manner:
   ! adx_for_n values followed by adx_for_s values = adx_for_a values
!*@/
#include "adx_nml.cdk"
#include "adx_dims.cdk"
#include "adx_grid.cdk"
#include "adx_poles.cdk"
   integer :: nwrn,nwrs,status
   integer :: i,j,k
   !---------------------------------------------------------------------
   call msg(MSG_DEBUG,'adx_exch_1')

   adx_for_n = 0
   adx_for_s = 0
   adx_fro_n = 0
   adx_fro_s = 0

   if (.not.adx_is_north) then
      do k = F_k0, F_nk
         do j = 1, adx_mlnj
            do i = 1, adx_mlni
               if (F_y_in(i,j,k) >= adx_yy_8(adx_lmaxy-1)) then
                  adx_for_n = adx_for_n + 1
                  F_x_out(adx_for_n) = F_x_in(i,j,k)
                  F_y_out(adx_for_n) = F_y_in(i,j,k)
                  F_z_out(adx_for_n) = F_z_in(i,j,k)
                  F_c_out(adx_for_n) = (k-1)*adx_mlni*adx_mlnj + (j-1)*adx_mlni + i
                  F_y_in(i,j,k) = adx_yy_8(1)
               endif
            enddo
         enddo
      enddo
   endif

   if (.not.adx_is_south) then
      do k = F_k0, F_nk
         do j = 1, adx_mlnj
            do i = 1, adx_mlni
               if (F_y_in(i,j,k) <= adx_yy_8(adx_lminy+1)) then
                  adx_for_s = adx_for_s + 1
                  F_x_out(adx_for_n+adx_for_s) = F_x_in(i,j,k)
                  F_y_out(adx_for_n+adx_for_s) = F_y_in(i,j,k)
                  F_z_out(adx_for_n+adx_for_s) = F_z_in(i,j,k)
                  F_c_out(adx_for_n+adx_for_s) = (k-1)*adx_mlni*adx_mlnj + (j-1)*adx_mlni + i
                  F_y_in(i,j,k) = adx_yy_8(1)
               endif
            enddo
         enddo
      enddo
   endif

   call RPN_COMM_swapns(1,adx_for_n,1,adx_for_s, &
        1,nwrn,adx_fro_n,1,nwrs,adx_fro_s,adx_is_period_y, &
        status)

   adx_for_a = adx_for_n + adx_for_s
   adx_fro_a = adx_fro_n + adx_fro_s

   if (adw_exdg_L) then
      if (adx_fro_a>0) &
           print '(A,3I8)','adx_exch_1 EXDG fro:', &
           adx_fro_n, adx_fro_s, adx_fro_a
      if (adx_for_a>0) &
           print '(A,3I8)','adx_exch_1 EXDG for:', &
           adx_for_n, adx_for_s, adx_for_a
   endif
   call msg(MSG_DEBUG,'adx_exch_1 [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_exch_1c
