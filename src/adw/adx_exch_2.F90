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

!/@*
subroutine adx_exch_2(F_a_fro, F_b_fro, F_c_fro, F_d_fro, F_e_fro, &
     F_a_for,   F_b_for,   F_c_for, F_d_for, F_e_for, &
     F_n_fro_n, F_n_fro_s, F_n_fro_a, &
     F_n_for_n, F_n_for_s, F_n_for_a, &
     F_n_treat)
   implicit none
#include <arch_specific.hf>
   !@objective exchange 1 to 3 fields among processors (upstream positions or interpolated values)
   !@arguments
   integer :: F_n_fro_n, F_n_fro_s, F_n_fro_a
   integer :: F_n_for_n, F_n_for_s, F_n_for_a
   integer :: F_n_treat
   real :: F_a_fro(F_n_fro_a), F_b_fro(F_n_fro_a), F_c_fro(F_n_fro_a), F_d_fro(F_n_fro_a), F_e_fro(F_n_fro_a)
   real :: F_a_for(F_n_for_a), F_b_for(F_n_for_a), F_c_for(F_n_for_a), F_d_for(F_n_for_a), F_e_for(F_n_for_a)
   !______________________________________________________________________
   !              |                                                 |     |
   ! NAME         | DESCRIPTION                                     | I/O |
   !--------------|-------------------------------------------------|-----|
   !              |                                                 |     |
   ! F_a_fro      | \                                               |  o  |
   ! F_b_fro      |   information vectors from neighbors            |  o  |
   ! F_c_fro      | /                                               |  o  |
   !              |                                                 |     |
   ! F_a_for      | \                                               |  i  |
   ! F_b_for      |   information vectors for neighbors             |  i  |
   ! F_c_for      | /                                               |  i  |
   !              |                                                 |     |
   ! F_n_fro_n    | number of information pieces from north neighbor|  i  |
   ! F_n_fro_s    | number of information pieces from south neighbor|  i  |
   ! F_n_fro_a    | number of information pieces from all   neighbor|  i  |
   ! F_n_for_n    | number of information pieces for  north neighbor|  i  |
   ! F_n_for_s    | number of information pieces for  south neighbor|  i  |
   ! F_n_for_a    | number of information pieces for  all   neighbor|  i  |
   !              |                                                 |     |
   ! F_n_treat    | number of vectors to exchange                   |  i  |
   !              | for exemple, if we exchange upstream positions, |     |
   !              | the 3 coordinates will be carried in a, b and c |     |
   !              | and F_n_treat should be equal to 3              |     |
   !______________|_________________________________________________|_____|
   !@author alain patoine
   !@revisions
   ! v2_31 - Corbeil L.       - replaced MPI calls by rpn_comm, removed 
   ! v2_31                      ptopo.cdk and removed stkmem calls
   ! v4_XX - Tanguay M.       - GEM4 Mass-Conservation
   !@description
   ! The information is strored in the following manner:
   !
   ! F_n_fro_n values followed by F_n_fro_s values = F_n_fro_a values
   ! ---------                    ---------          ---------
   !
   ! F_n_for_n values followed by F_n_for_s values = F_n_for_a values
   ! ---------                    ---------          ---------
   !
   ! WARNING: This code may result in allocating arrays with 0 size
   !          and therefore will send an empty message
!*@/
#include "adx_dims.cdk"
   integer :: nwrn,nwrs,status,n 
   real :: abc_for_n(F_n_for_n,F_n_treat), abc_for_s(F_n_for_s,F_n_treat)
   real :: abc_fro_n(F_n_fro_n,F_n_treat), abc_fro_s(F_n_fro_s,F_n_treat)
   !---------------------------------------------------------------------
   call msg(MSG_DEBUG,'adx_exch_2')
   if (F_n_for_n > 0) then

      if (F_n_treat == 1) then
         do n = 1, F_n_for_n
            abc_for_n(n,1) = F_a_for(n)
         enddo
      else if (F_n_treat == 2) then
         do n = 1, F_n_for_n
            abc_for_n(n,1) = F_a_for(n)
            abc_for_n(n,2) = F_b_for(n)
         enddo
      else if (F_n_treat == 3) then
         do n = 1, F_n_for_n
            abc_for_n(n,1) = F_a_for(n)
            abc_for_n(n,2) = F_b_for(n)
            abc_for_n(n,3) = F_c_for(n)
         enddo
      else if (F_n_treat == 5) then
         do n = 1, F_n_for_n
            abc_for_n(n,1) = F_a_for(n)
            abc_for_n(n,2) = F_b_for(n)
            abc_for_n(n,3) = F_c_for(n)
            abc_for_n(n,4) = F_d_for(n)
            abc_for_n(n,5) = F_e_for(n)
         enddo
      endif

   endif

   if (F_n_for_s > 0) then

      if (F_n_treat == 1) then
         do n = 1, F_n_for_s
            abc_for_s(n,1) = F_a_for(F_n_for_n+n)
         enddo
      else if (F_n_treat == 2) then
         do n = 1, F_n_for_s
            abc_for_s(n,1) = F_a_for(F_n_for_n+n)
            abc_for_s(n,2) = F_b_for(F_n_for_n+n)
         enddo
      else if (F_n_treat == 3) then
         do n = 1, F_n_for_s
            abc_for_s(n,1) = F_a_for(F_n_for_n+n)
            abc_for_s(n,2) = F_b_for(F_n_for_n+n)
            abc_for_s(n,3) = F_c_for(F_n_for_n+n)
         enddo
      else if (F_n_treat == 5) then
         do n = 1, F_n_for_s
            abc_for_s(n,1) = F_a_for(F_n_for_n+n)
            abc_for_s(n,2) = F_b_for(F_n_for_n+n)
            abc_for_s(n,3) = F_c_for(F_n_for_n+n)
            abc_for_s(n,4) = F_d_for(F_n_for_n+n)
            abc_for_s(n,5) = F_e_for(F_n_for_n+n)
         enddo
      endif

   endif

   call RPN_COMM_swapns(F_n_treat*F_n_for_n,abc_for_n, &
        F_n_treat*F_n_for_s,abc_for_s, &
        F_n_treat*F_n_fro_n,nwrn,abc_fro_n, &
        F_n_treat*F_n_fro_s,nwrs,abc_fro_s, &
        adx_is_period_y,status)

   if (F_n_fro_n > 0) then

      if (F_n_treat == 1) then
         do n = 1, F_n_fro_n
            F_a_fro(n) = abc_fro_n(n,1)
         enddo
      else if (F_n_treat == 2) then
         do n = 1, F_n_fro_n
            F_a_fro(n) = abc_fro_n(n,1)
            F_b_fro(n) = abc_fro_n(n,2)
         enddo
      else if (F_n_treat == 3) then
         do n = 1, F_n_fro_n
            F_a_fro(n) = abc_fro_n(n,1)
            F_b_fro(n) = abc_fro_n(n,2)
            F_c_fro(n) = abc_fro_n(n,3)
         enddo
      else if (F_n_treat == 5) then
         do n = 1, F_n_fro_n
            F_a_fro(n) = abc_fro_n(n,1)
            F_b_fro(n) = abc_fro_n(n,2)
            F_c_fro(n) = abc_fro_n(n,3)
            F_d_fro(n) = abc_fro_n(n,4)
            F_e_fro(n) = abc_fro_n(n,5)
         enddo
      endif

   endif

   if (F_n_fro_s > 0) then

      if (F_n_treat == 1) then
         do n = 1, F_n_fro_s
            F_a_fro(F_n_fro_n+n) = abc_fro_s(n,1)
         enddo
      else if (F_n_treat == 2) then
         do n = 1, F_n_fro_s
            F_a_fro(F_n_fro_n+n) = abc_fro_s(n,1)
            F_b_fro(F_n_fro_n+n) = abc_fro_s(n,2)
         enddo
      else if (F_n_treat == 3) then
         do n = 1, F_n_fro_s
            F_a_fro(F_n_fro_n+n) = abc_fro_s(n,1)
            F_b_fro(F_n_fro_n+n) = abc_fro_s(n,2)
            F_c_fro(F_n_fro_n+n) = abc_fro_s(n,3)
         enddo
      else if (F_n_treat == 5) then
         do n = 1, F_n_fro_s
            F_a_fro(F_n_fro_n+n) = abc_fro_s(n,1)
            F_b_fro(F_n_fro_n+n) = abc_fro_s(n,2)
            F_c_fro(F_n_fro_n+n) = abc_fro_s(n,3)
            F_d_fro(F_n_fro_n+n) = abc_fro_s(n,4)
            F_e_fro(F_n_fro_n+n) = abc_fro_s(n,5)
         enddo
      endif

   endif
   call msg(MSG_DEBUG,'adx_exch_2 [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_exch_2
