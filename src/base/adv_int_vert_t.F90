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
!
      subroutine adv_int_vert_t ( F_xt, F_yt, F_zt, F_xtn, F_ytn, F_ztn, F_xm, F_ym, F_zm, &
                                  F_wat, F_wdm, F_ni,F_nj, F_nk     , &
                                  F_k0, i0,in,j0,jn, F_cubic_L )
      implicit none
#include <arch_specific.hf>

      integer :: F_ni,F_nj, F_nk,F_k0
      integer i0,in,j0,jn,k00
      real, dimension(F_ni,F_nj,F_nk) :: F_xt,F_yt,F_zt
      real, dimension(F_ni,F_nj)      :: F_xtn,F_ytn,F_ztn
      real, dimension(F_ni,F_nj,F_nk) :: F_xm,F_ym,F_zm
      real, dimension(F_ni,F_nj,F_nk) :: F_wat,F_wdm
      logical :: F_cubic_L

!authors
!     A. Plante & C. Girard
!
!object
!     see id section
!
!arguments
!______________________________________________________________________
!              |                                                 |     |
! NAME         | DESCRIPTION                                     | I/O |
!--------------|-------------------------------------------------|-----|
!              |                                                 |     |
! F_xt         | upwind longitudes for themodynamic level        |  o  |
! F_yt         | upwind latitudes for themodynamic level         |  o  |
! F_zt         | upwind height for themodynamic level            |  o  |
! F_xm         | upwind longitudes for momentum level            |  i  |
! F_ym         | upwind latitudes for momentum level             |  i  |
! F_zm         | upwind height for momentum level                |  i  |
!______________|_________________________________________________|_____|


#include "constants.h"
#include "adv_grid.cdk"
#include "ver.cdk"
#include "cstv.cdk"
#include "schm.cdk"
      integer :: i,j,k
      real*8  two, half
      real*8, dimension(2:F_nk-2) :: w1, w2, w3, w4
      real*8, dimension(i0:in,F_nk) :: wdt
      real*8 :: lag3, hh, x, x1, x2, x3, x4, ww, wp, wm
      real :: ztop_bound, zbot_bound
      parameter (two = 2.0, half=0.5)

      lag3( x, x1, x2, x3, x4 ) = &
        ( ( x  - x2 ) * ( x  - x3 ) * ( x  - x4 ) )/ &
        ( ( x1 - x2 ) * ( x1 - x3 ) * ( x1 - x4 ) )
!     
!---------------------------------------------------------------------
!     
!***********************************************************************
! Note : extra computation are done in the pilot zone if
!        (Lam_gbpil_t != 0) for coding simplicity
!***********************************************************************
!
      ztop_bound=Ver_z_8%m(0)
      zbot_bound=Ver_z_8%m(F_nk+1)



! Prepare parameters for cubic intepolation
      do k=2,F_nk-2
         hh = Ver_z_8%t(k)
         x1 = Ver_z_8%m(k-1)
         x2 = Ver_z_8%m(k  )
         x3 = Ver_z_8%m(k+1)
         x4 = Ver_z_8%m(k+2)
         w1(k) = lag3( hh, x1, x2, x3, x4 )
         w2(k) = lag3( hh, x2, x1, x3, x4 )
         w3(k) = lag3( hh, x3, x1, x2, x4 )
         w4(k) = lag3( hh, x4, x1, x2, x3 )
      enddo

      k00=max(F_k0-1,1)

!$omp parallel private(i,j,k,wdt,ww,wp,wm)
!$omp do
    do j=j0,jn

!     Fill non computed upstream positions with zero to avoid math exceptions
!     in the case of top piloting
      do k=1,k00-1
         do i=i0,in
           F_xt(i,j,k)=0.0
           F_yt(i,j,k)=0.0
           F_zt(i,j,k)=0.0
         end do
      enddo

      do k=k00,F_nk-1 
         if(F_cubic_L.and.k.ge.2.and.k.le.F_nk-2)then
           !Cubic
            do i=i0,in
               F_xt(i,j,k) = w1(k)*F_xm(i,j,k-1)+ &
                             w2(k)*F_xm(i,j,k  )+ &
                             w3(k)*F_xm(i,j,k+1)+ &
                             w4(k)*F_xm(i,j,k+2)
               F_yt(i,j,k) = w1(k)*F_ym(i,j,k-1)+ &
                             w2(k)*F_ym(i,j,k  )+ &
                             w3(k)*F_ym(i,j,k+1)+ &
                             w4(k)*F_ym(i,j,k+2)
            enddo
         else
           !Linear
            do i=i0,in
               F_xt(i,j,k) = (F_xm(i,j,k )+F_xm (i,j,k+1))*half
               F_yt(i,j,k) = (F_ym(i,j,k )+F_ym (i,j,k+1))*half
            enddo
         endif
      enddo
  
   if(Schm_trapeze_L.or.Schm_step_settls_L) then
         !working with displacements for the vertical position
 
       do k=k00,F_nk-1            
         do i=i0,in
           if(k.ge.2.and.k.le.F_nk-2)then
                  !Cubic
                  wdt(i,k) = &
                       w1(k)*F_wdm(i,j,k-1)+ &
                       w2(k)*F_wdm(i,j,k  )+ &
                       w3(k)*F_wdm(i,j,k+1)+ &
                       w4(k)*F_wdm(i,j,k+2)
           else
                  !Linear
                  wdt(i,k) = (F_wdm(i,j,k)+F_wdm(i,j,k+1))*0.5d0
           endif

            F_zt(i,j,k)=Ver_z_8%t(k) - Cstv_dtD_8*  wdt(i,  k) &
                                     - Cstv_dtA_8*F_wat(i,j,k)
            F_zt(i,j,k)=max(F_zt(i,j,k),ztop_bound)
            F_zt(i,j,k)=min(F_zt(i,j,k),zbot_bound)
         enddo
      enddo
 
        !for the last level when at the surface
         wp=(Ver_z_8%m(F_nk+1)-Ver_z_8%m(F_nk-1))*Ver_idz_8%t(F_nk-1)
         wm=1.d0-wp
          do i=i0,in
           !extrapolating horizontal positions downward
           F_xt(i,j,F_nk)=wp*F_xm(i,j,F_nk)+wm*F_xm(i,j,F_nk-1)
           F_yt(i,j,F_nk)=wp*F_ym(i,j,F_nk)+wm*F_ym(i,j,F_nk-1)

           !vertical position
           F_zt(i,j,F_nk)=zbot_bound
          enddo

          !for the last level when half way between surface and last momentum level
           ww=Ver_wmstar_8(F_nk)
           wp=(Ver_z_8%t(F_nk  )-Ver_z_8%m(F_nk-1))*Ver_idz_8%t(F_nk-1)
           wm=1.d0-wp
          do i=i0,in
           !extrapolating horizontal positions downward
           F_xtn(i,j)=wp*F_xm(i,j,F_nk)+wm*F_xm(i,j,F_nk-1)
           F_ytn(i,j)=wp*F_ym(i,j,F_nk)+wm*F_ym(i,j,F_nk-1)

           !interpolating vertical positions     
           F_ztn(i,j)= Ver_z_8%t(F_nk)-ww*(Cstv_dtD_8*  wdt(i,  F_nk-1) &
                                       +Cstv_dtA_8*F_wat(i,j,F_nk-1))
           F_ztn(i,j)= min(F_ztn(i,j),zbot_bound)
          enddo
     
   else     
        !working directly with positions
         do k=k00,F_nk-1
            do i=i0,in
               if(k.ge.2.and.k.le.F_nk-2)then
                  !Cubic
                  F_zt(i,j,k)= &
                       w1(k)*F_zm(i,j,k-1)+ &
                       w2(k)*F_zm(i,j,k  )+ &
                       w3(k)*F_zm(i,j,k+1)+ &
                       w4(k)*F_zm(i,j,k+2)
               else
                  !Linear
                  F_zt(i,j,k) = (F_zm(i,j,k)+F_zm(i,j,k+1))*half
               endif
               ! Must stay in domain
               F_zt(i,j,k)=max(F_zt(i,j,k),ztop_bound)
               F_zt(i,j,k)=min(F_zt(i,j,k),zbot_bound)
            end do
         end do
      ! For last thermodynamic level, positions in the horizontal are those  
      ! of the momentum levels; no displacement allowed in the vertical      
      ! at bottum. At top vertical displacement is obtian from linear inter. 
      ! and is bound to first thermo level.                                  
          do i=i0,in
             F_xt(i,j,F_nk) = F_xm(i,j,F_nk)
             F_yt(i,j,F_nk) = F_ym(i,j,F_nk)
             F_zt(i,j,F_nk) = zbot_bound
             F_xtn(i,j) = F_xm(i,j,F_nk)
             F_ytn(i,j) = F_ym(i,j,F_nk)
             F_ztn(i,j) = zbot_bound
          enddo

   endif

enddo
!$omp enddo
!$omp end parallel
!     
!---------------------------------------------------------------------
! 
      return
      end subroutine adv_int_vert_t
