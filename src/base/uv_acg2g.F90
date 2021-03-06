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

!**s/r uv_acg2g - Arakawa-C grid to grid interpolator for wind
!                 like quantities
!

!
      subroutine uv_acg2g (F_dst,F_src,F_gridi,F_grido,Minx,Maxx,Miny,Maxy,  &
                                        Nk, F_i0,F_in,F_j0,F_jn)
      implicit none
#include <arch_specific.hf>
!
      integer Minx,Maxx,Miny,Maxy,Nk,F_i0,F_in,F_j0,F_jn
      integer F_gridi, F_grido
      real F_dst(Minx:Maxx,Miny:Maxy,Nk), F_src(Minx:Maxx,Miny:Maxy,Nk)

!author
!     J. Caveen - rpn - july 1995
!
!revision
! v2_00 - Lee V.        - initial MPI version (from bongril v1_03)
! v2_31 - Laroche S.    - add two options to interpolate from scalar
!                         grid to wind grids. Note that variables pil_?
!                         and linear interpolation are not yet
!                         implemented in these options.
! v3_20 - Tanguay M.    - replace grido by gridi in exchange halo
! v3_22 - Desgagne M.   - Revision OpenMP
! v3_30 - Tanguay M.    - Revision Openmp LAM
!
!object
!     Subroutine to move a given field to a specified target grid
!     bongril checks the type of the input grid and takes the necessary
!     steps to move the field to the target grid.
!     On output, bongrid returns the grid dimensions of the target grid
!
!arguments
!  Name        I/O                 Description
!----------------------------------------------------------------
! F_dst        O    - field on target grid
! F_src        I    - field on source grid
! F_gridi      I    - type of input grid : 0 - scalar-grid
!                                          1 - u-grid
!                                          2 - v-grid
! F_grido      I    - type of output grid: see F_gridi
! F_i0         O    - starting point of computation on W-E axis
! F_in         O    - ending   point of computation on W-E axis
! F_j0         O    - starting point of computation on N-S axis
! F_jn         O    - ending   point of computation on N-S axis
!
#include "glb_ld.cdk"
#include "schm.cdk"
#include "inuvl.cdk"
#include "geomg.cdk"

      logical cubic
      integer i,j,k,nie,nje

      real*8, parameter :: half=0.5d0 , alpha1=-1.d0/16.d0 , alpha2=9.d0/16.d0
!
!-----------------------------------------------------------------
!
      cubic = Schm_adcub_L

!     check input grid

      if (F_grido .eq. F_gridi) then

!     copy grid as is

         F_i0 = 1
         F_in = l_ni
         F_j0 = 1
         F_jn = l_nj




!$omp parallel private(i,j)
!$omp do
         do k =  1, Nk
         do j = F_j0, F_jn
         do i = F_i0, F_in
            F_dst(i,j,k) = F_src(i,j,k)
         end do
         end do
         end do
!$omp enddo
!$omp end parallel

      else

         nie = l_ni
         nje = l_nj
         if (F_gridi.eq.1) nie = l_niu
         if (F_gridi.eq.2) nje = l_njv
         call rpn_comm_xch_halo (F_src,l_minx,l_maxx,l_miny,l_maxy,nie,nje,Nk, &
                   G_halox,G_haloy,G_periodx,G_periody,l_ni,0)

      endif

      if ( F_gridi .eq. 1 .and. F_grido .eq. 0) then

         F_i0 = 1
         F_in = l_niu
         F_j0 = 1
         F_jn = l_nj
         if ((G_lam).and.(l_west)) then
            F_i0 = 2
            if (cubic) F_i0 = 3
         endif
         if ((G_lam).and.(l_east).and.(cubic)) F_in = l_niu-1

!$omp parallel private(i,j)
!$omp do
         do k = 1,Nk
            if ( .not. cubic ) then ! Linear interpolation

            do j = F_j0, F_jn
            do i = F_i0, F_in
               F_dst(i,j,k)= (F_src(i-1,j,k) + F_src(i,j,k))*half
            end do
            end do

            else                   ! Lagrange cubic interpolation

            do j = F_j0, F_jn
            do i = F_i0, F_in
               F_dst(i,j,k) =  ( F_src(i-2,j,k) + F_src(i+1,j,k) )*alpha1  &
                               + ( F_src(i-1,j,k) + F_src(i  ,j,k) )*alpha2
                            
            end do
            end do

            endif
         end do
!$omp enddo
!$omp end parallel

      endif

      if ( F_gridi .eq. 2 .and. F_grido .eq. 0) then

         F_i0 = 1
         F_in = l_ni
         F_j0 = 1
         F_jn = l_njv
         if (cubic) then
            if (l_south) F_j0 = 3
            if (l_north) F_jn = l_njv - 1
         else
            if (l_south) F_j0 = 2
         endif

!$omp parallel private(i,j)
!$omp do
         do k = 1,Nk
            if ( .not. cubic ) then ! Linear interpolation

            do j = F_j0, F_jn
            do i = F_i0, F_in
            F_dst(i,j,k)= (F_src(i,j-1,k) + F_src(i,j,k))*half
            end do
            end do

            if (.not.G_lam) then
               if (l_south) then
               do i = F_i0, F_in
                  F_dst(i,1,k) = F_src(i,1,k)*half
               end do
               endif
               if (l_north) then
               do i = F_i0, F_in
                  F_dst(i,F_jn+1,k)= F_src(i,F_jn,k)*half
               end do
               endif
            endif

            else                   ! Lagrange cubic interpolation

            do j = F_j0, F_jn
            do i = F_i0, F_in
            F_dst(i,j,k) =  inuvl_wyvy3_8(j,1) * F_src(i,j-2,k) &
                          + inuvl_wyvy3_8(j,2) * F_src(i,j-1,k) &
                          + inuvl_wyvy3_8(j,3) * F_src(i,j  ,k) &
                          + inuvl_wyvy3_8(j,4) * F_src(i,j+1,k)
            end do
            end do

            if (.not.G_lam) then
               if (l_south) then
               do i = F_i0, F_in
               F_dst(i,1,k) = (inuvl_wyvy3_8(1,3) * F_src(i,1,k) * geomg_cyv_8(1) &
                             + inuvl_wyvy3_8(1,4) * F_src(i,2,k) * geomg_cyv_8(2))&
                             * geomg_invcy_8(1)

               F_dst(i,2,k) = (inuvl_wyvy3_8(2,2) * F_src(i,1,k) * geomg_cyv_8(1) &
                             + inuvl_wyvy3_8(2,3) * F_src(i,2,k) * geomg_cyv_8(2) &
                             + inuvl_wyvy3_8(2,4) * F_src(i,3,k) * geomg_cyv_8(3))&
                             * geomg_invcy_8(2)
               end do
               endif

               if (l_north) then
               do i = F_i0, F_in
               F_dst(i,F_jn+2,k) = (inuvl_wyvy3_8(F_jn+2,1) * F_src(i,F_jn  ,k) * geomg_cyv_8(F_jn)   &
                                  + inuvl_wyvy3_8(F_jn+2,2) * F_src(i,F_jn+1,k) * geomg_cyv_8(F_jn+1))&
                                  * geomg_invcy_8(F_jn+2)
               F_dst(i,F_jn+1,k) = (inuvl_wyvy3_8(F_jn+1,1) * F_src(i,F_jn-1,k) * geomg_cyv_8(F_jn-1) &
                                  + inuvl_wyvy3_8(F_jn+1,2) * F_src(i,F_jn  ,k) * geomg_cyv_8(F_jn  ) &
                                  + inuvl_wyvy3_8(F_jn+1,3) * F_src(i,F_jn+1,k) * geomg_cyv_8(F_jn+1))&
                                  * geomg_invcy_8(F_jn+1)
               end do
               endif
            endif
            endif
         enddo
!$omp enddo
!$omp end parallel

         if (.not.G_lam) then
            F_j0 = 1
            F_jn = l_nj
         endif

      endif
!stl
!stl  ------------------- NEW OPTIONS--------------------------------
!stl            Linear interpolation not coded yet

      if ( F_gridi .eq. 0 .and. F_grido .eq. 1) then

         F_i0 = 1
         F_in = l_niu
         F_j0 = 1
         F_jn = l_nj
         if ((G_lam).and.(l_west)) F_i0 = 2
         if ((G_lam).and.(l_east)) F_in = l_niu-1

!$omp parallel private(i,j)
!$omp do
         do k = 1,Nk
            do j = F_j0, F_jn
            do i = F_i0, F_in
               F_dst(i,j,k) = ( F_src(i-1,j,k) + F_src(i+2,j,k) )*alpha1  &
                            + ( F_src(i  ,j,k) + F_src(i+1,j,k) )*alpha2
                            
            end do
            end do
         end do
!$omp enddo
!$omp end parallel

      endif

      if ( F_gridi .eq. 0 .and. F_grido .eq. 2) then

         F_i0 = 1
         F_in = l_ni
         F_j0 = 1
         F_jn = l_njv
         if (l_south) F_j0 = 2
         if (l_north) F_jn = l_njv - 1

!$omp parallel private(i,j)
!$omp do
         do k = 1,Nk
            do j = F_j0, F_jn
            do i = F_i0, F_in
               F_dst(i,j,k) = alpha1*( F_src(i,j-1,k) + F_src(i,j+2,k) ) &
                            + alpha2*( F_src(i,j  ,k) + F_src(i,j+1,k))                           
            end do
            end do

            if (.not.G_lam) then
               if (l_south) then
               do i = F_i0, F_in
                  F_dst(i,1,k) =(inuvl_wyyv3_8(1,2)*F_src(i,1,k) * geomg_cy_8(1) &
                               + inuvl_wyyv3_8(1,3)*F_src(i,2,k) * geomg_cy_8(2) &
                               + inuvl_wyyv3_8(1,4)*F_src(i,3,k) * geomg_cy_8(3))&
                               * geomg_invcy_8(1)
               end do
               endif
               if (l_north) then
               do i = F_i0, F_in
                   F_dst(i,l_njv,k) =  &
                              (inuvl_wyyv3_8(l_njv,1)*F_src(i,l_njv-1,k) * geomg_cy_8(l_njv-1) &
                             + inuvl_wyyv3_8(l_njv,2)*F_src(i,l_njv  ,k) * geomg_cy_8(l_njv)   &
                             + inuvl_wyyv3_8(l_njv,3)*F_src(i,l_njv+1,k) * geomg_cy_8(l_njv+1))&
                             * geomg_invcy_8(l_njv)
               end do
               endif
            endif
         enddo
!$omp enddo
!$omp end parallel

         if (.not.G_lam) then
            F_j0 = 1
            F_jn = l_njv
         endif
      endif
!
!-----------------------------------------------------------------
!
      return
      end
