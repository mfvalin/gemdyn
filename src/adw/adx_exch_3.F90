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

subroutine adx_exch_3()
   call stop_mpi(STOP_ERROR,'adx_exch_3','called a stub')
   return
end subroutine adx_exch_3

!/@*
subroutine adx_exch_3b(F_1_out, F_2_out, F_3_out, F_4_out, F_5_out, &
                       F_1_in , F_2_in , F_3_in , F_4_in , F_5_in , F_c_in, F_n_treat, &
   F_ni,F_nj,F_nk)
   implicit none
#include <arch_specific.hf>
#include "adx_dims.cdk"
#include "adx_poles.cdk"
   !@objective fetch back interpolated values after being 
   !           obtained from neighbor processors for 1 or 2 fields
   !@arguments
   integer :: F_ni,F_nj,F_nk        !I, dims
   integer :: F_n_treat
   integer :: F_c_in(adx_for_a)
   real    :: F_1_in(adx_for_a), F_2_in(adx_for_a), F_3_in(adx_for_a), F_4_in(adx_for_a), F_5_in(adx_for_a)
   real,dimension(F_ni*F_nj*F_nk) :: F_1_out, F_2_out, F_3_out, F_4_out, F_5_out
   !______________________________________________________________________
   !              |                                                 |     |
   ! NAME         | DESCRIPTION                                     | I/O |
   !--------------|-------------------------------------------------|-----|
   !              |                                                 |     |
   ! F_1_out      | \ interpolated fields for which some values     |  o  |
   ! F_2_out      | | obtained from neighbors have to be fetched    |  o  |
   ! F_3_out      | |  back in the appropriate positions            |  o  |
   ! F_4_out      | |                                               |  o  |
   ! F_5_out      | /                                               |  o  |
   !              |                                                 |     |
   ! F_1_in       | \ interpolated values obtained from neighbors   |  i  |
   ! F_2_in       | |                                               |  i  |
   ! F_3_in       | |                                               |  i  |
   ! F_4_in       | |                                               |  i  |
   ! F_5_in       | /                                               |  i  |
   !              |                                                 |     |
   ! F_c_in       | 3D coordinates of points for which upstream     |  i  |
   !              | positions were outside advection source grid and|     |
   !              | interpolated values were obtained from neighbors|  i  |
   !              |                                                 |     |
   ! F_n_treat    | number of vectors to treat                      |  i  |
   !______________|_________________________________________________|_____|
   !@author alain patoine
   !@revisions
   ! v4_XX - Tanguay M.       - GEM4 Mass-Conservation
   !  
!*@/
   integer :: n
   !---------------------------------------------------------------------
   call msg(MSG_DEBUG,'adx_exch_3')
   if (F_n_treat == 1) then

      do n = 1, adx_for_a
         F_1_out(F_c_in(n)) = F_1_in(n)
      enddo

   else if (F_n_treat == 2) then

      do n = 1, adx_for_a
         F_1_out(F_c_in(n)) = F_1_in(n)
         F_2_out(F_c_in(n)) = F_2_in(n)
      enddo

   else if (F_n_treat == 5) then

      do n = 1, adx_for_a
         F_1_out(F_c_in(n)) = F_1_in(n)
         F_2_out(F_c_in(n)) = F_2_in(n)
         F_3_out(F_c_in(n)) = F_3_in(n)
         F_4_out(F_c_in(n)) = F_4_in(n)
         F_5_out(F_c_in(n)) = F_5_in(n)
      enddo

   endif
   call msg(MSG_DEBUG,'adx_exch_3 [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_exch_3b
