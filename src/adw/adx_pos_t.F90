!-------------------------------------- LICENCE BEGIN ------------------------------------
!Environment Canada - Atmospheric Science and Technology License/Disclaimer, 
!                     version 3; Last Modified: May 7, 2008.
!This is free but copyrighted software; you can use/redistribute/modify it under the terms 
!of the Environment Canada - Atmospheric Science and Technology License/Disclaimer 
!version 3 or (at your option) any later version that should be found at: 
!http://collaboration.cmc.ec.gc.ca/science/rpn.comm/license.html 
!
!This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
!without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
!See the above mentioned License/Disclaimer for more details.
!You should have received a copy of the License/Disclaimer along with this software; 
!if not, you can write to: EC-RPN COMM Group, 2121 TransCanada, suite 500, Dorval (Quebec), 
!CANADA, H9P 1J3; or send e-mail to service.rpn@ec.gc.ca
!-------------------------------------- LICENCE END --------------------------------------
!**s/r adx_pos_t - vertical interpolation of upstream position of momentum
!                    level to obtain those of the thermodynamic levels
!
#include "constants.h"
!
subroutine adx_pos_t ( F_xt, F_yt, F_zt, F_xm, F_ym, F_zm, F_wat, F_wdm, &
     F_ni,F_nj,F_k0,F_nk,i0,in,j0,jn,F_cubic_xy_L)
!
   implicit none
#include <arch_specific.hf>
!
   integer :: F_ni,F_nj,F_k0,F_nk
   integer i0,in,j0,jn,k00
   real, dimension(F_ni,F_nj,F_nk) :: F_xt,F_yt,F_zt
   real, dimension(F_ni,F_nj,F_nk) :: F_xm,F_ym,F_zm
   real, dimension(F_ni,F_nj,F_nk) :: F_wat,F_wdm
   logical :: F_cubic_xy_L
!
!authors
!     A. Plante & C. Girard based on adx_meanpos from sylvie gravel
!
!revision
!     A. Plante - nov 2011 - add vertial scope for top piloting
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
!                      |
!                      |
!    No top nesting    |       With top nesting
!                      |
!                      | NOTES: F_k0 = adx_gbpil_t+1
!                      | For this example adx_gbpil_t=3 -> F_k0=4
!                      |
!  ======== Model Top  |   ==========
!  -------- %m 1       |   ---------- uptream pos. not available (F_k0-3)
!  Linear   %t 1       |   Not needed
!  -------- %m 2       |   ----------
!  Cubic    %t 2       |   Not needed
!  -------- %m 3       |   ----------
!  Cubic    %t 3       |   Cubic      %t F_k0-1
!  -------- %m 4       |   ---------- %m F_k0
!                      |
!     ...              |       ...     
!                      |       
!  Cubic    %t N-2     |   Cubic
!  -------- %m N-1     |   ----------
!  Linear   %t N-1     |   Linear
!  -------- %m N       |   ----------
!  Constant %t N       |   Constant
!  ======== Model Sfc  |   ===========
!                      |
!----------------------------------------------------------------------
!
!implicits
#include "adx_dims.cdk"
#include "adx_grid.cdk"
#include "adx_dyn.cdk"
#include "schm.cdk"
!***********************************************************************
   integer vnik, vnikm, i,j,k
!
   real*8  r2pi_8, two, half, alpha
   real*8, dimension(i0:in,adx_lnk) :: xcos,ycos,xsin,ysin,cx,cy,cz
   real*8, dimension(i0:in,1:adx_lnk-1) :: yasin,zatan,cxp,cyp,czp
   real*8, dimension(2:adx_lnk-2) :: w1, w2, w3, w4
   real*8 :: lag3, hh, x, x1, x2, x3, x4, wdt
   real :: ztop_bound, zbot_bound
   parameter (two = 2.0, half=0.5)
   !***********************************************************************
   !
   lag3( x, x1, x2, x3, x4 ) = &
        ( ( x  - x2 ) * ( x  - x3 ) * ( x  - x4 ) )/ &
        ( ( x1 - x2 ) * ( x1 - x3 ) * ( x1 - x4 ) )
   !
   !***********************************************************************
   ! Note : extra computation are done in the pilot zone if
   !        (adx_gbpil_t != 0) for coding simplicity
   !***********************************************************************
   !
   ztop_bound=adx_verZ_8%m(0)
   zbot_bound=adx_verZ_8%m(adx_lnk+1)
   !
   vnik = (in-i0+1)*adx_lnk
   vnikm= (in-i0+1)*(adx_lnk-1)
   !
   r2pi_8 = two * CONST_PI_8
   !
   ! Prepare parameters for cubic intepolation
   do k=2,adx_lnk-2
      hh = adx_verZ_8%t(k)
      x1 = adx_verZ_8%m(k-1)
      x2 = adx_verZ_8%m(k  )
      x3 = adx_verZ_8%m(k+1)
      x4 = adx_verZ_8%m(k+2)
      w1(k) = lag3( hh, x1, x2, x3, x4 )
      w2(k) = lag3( hh, x2, x1, x3, x4 )
      w3(k) = lag3( hh, x3, x1, x2, x4 )
      w4(k) = lag3( hh, x4, x1, x2, x3 )         
   enddo

   k00=max(F_k0-1,1)

!***********************************************************************
!     call tmg_start ( 33, 'adx_meanpos' )
!$omp parallel private(i,j,k,ysin,ycos, &
!$omp zatan,yasin,xsin,xcos, alpha, &
!$omp cx, cy, cz, cxp, cyp, czp, wdt)
!$omp do 
   do j=j0,jn
      do k=1,adx_lnk
      do i=i0,in
         xcos(i,k) = F_xm(i,j,k)
         ycos(i,k) = F_ym(i,j,k)
      end do
      end do
!
!     Fill non computed upstream positions with zero to avoid math exceptions
!     in the case of top piloting
      do k=1,F_k0-2
         do i=i0,in
            xcos(i,k)=0.0
            ycos(i,k)=0.0
         end do
      enddo
!
      call vsin(xsin, xcos, vnik)
      call vsin(ysin, ycos, vnik)
      call vcos(xcos, xcos, vnik)
      call vcos(ycos, ycos, vnik)
!
!***********************************************************************
! For 1st and last thermodynamic levels positions in the horizontal are*
! those of the momentum levels; no displacement allowed in the vertical*
! at bottum. At top vertical displacement is obtian from linear inter. *
! and is bound to first thermo level.                                  *
!***********************************************************************
      do i=i0,in
         F_xt(i,j,adx_lnk) = F_xm(i,j,adx_lnk)
         F_yt(i,j,adx_lnk) = F_ym(i,j,adx_lnk)
         F_zt(i,j,adx_lnk) = zbot_bound
      enddo
!
!***********************************************************************
! cartesian coordinates of each momemtum levels                        *
!***********************************************************************
      do k=1,adx_lnk
      do i=i0,in
         cx(i,k) = xcos(i,k)*ycos(i,k)
         cy(i,k) = xsin(i,k)*ycos(i,k)
         cz(i,k) = ysin(i,k)
      enddo
      enddo
!
!***********************************************************************
! cartesian coordinates of intermediate thermodynamic levels
!***********************************************************************            
!     Fill missing values with zero to avoid math exception in case of
!     top piloting
      do k=1,k00-1
         do i=i0,in
            cxp(i,k)=0.0
            cyp(i,k)=0.0
            czp(i,k)=0.0
         enddo
      enddo
      do k=k00,adx_lnk-1
         if(F_cubic_xy_L.and.k.ge.2.and.k.le.adx_lnk-2)then
            ! Cubic
            do i=i0,in
               cxp(i,k) = w1(k)*cx(i,k-1)+ &
                          w2(k)*cx(i,k  )+ &
                          w3(k)*cx(i,k+1)+ &
                          w4(k)*cx(i,k+2)
               cyp(i,k) = w1(k)*cy(i,k-1)+ &
                          w2(k)*cy(i,k  )+ &
                          w3(k)*cy(i,k+1)+ &
                          w4(k)*cy(i,k+2)
               czp(i,k) = w1(k)*cz(i,k-1)+ &
                          w2(k)*cz(i,k  )+ &
                          w3(k)*cz(i,k+1)+ &
                          w4(k)*cz(i,k+2)
               alpha=1./sqrt(cxp(i,k)*cxp(i,k)+ &
                             cyp(i,k)*cyp(i,k)+ &
                             czp(i,k)*czp(i,k))
               cxp(i,k)=alpha*cxp(i,k)
               cyp(i,k)=alpha*cyp(i,k)
               czp(i,k)=alpha*czp(i,k)            
            enddo
         else
            ! Linear
            do i=i0,in
               alpha    = half*( 1.+cx(i,k)*cx(i,k+1) &
                                   +cy(i,k)*cy(i,k+1) &
                                   +cz(i,k)*cz(i,k+1) )
               alpha    = 1./(two*sqrt(alpha))
               cxp(i,k) = (cx(i,k)+cx(i,k+1))*alpha
               cyp(i,k) = (cy(i,k)+cy(i,k+1))*alpha
               czp(i,k) = (cz(i,k)+cz(i,k+1))*alpha
            enddo
         endif
         do i=i0,in
            if (czp(i,k).gt.1.d0) then
               czp(i,k)=1.d0
            elseif (czp(i,k).lt.-1.d0) then
               czp(i,k)=-1.d0
            endif
         enddo
      enddo
      
      call vatan2(zatan,cyp,cxp,vnikm)
      call vasin (yasin,czp,vnikm)
   
!***********************************************************************
! polar coordinates of upstream position for intermediate thermo levels*
!***********************************************************************

      if(adx_trapeze_L.or.Schm_step_settls_L) then
   !  if(.false.) then
         do k=k00,adx_lnk-1
            do i=i0,in
               F_yt(i,j,k) = yasin(i,k)
               F_xt(i,j,k) = zatan(i,k)
               if ( F_xt(i,j,k) .lt. 0.0 ) F_xt(i,j,k) = F_xt(i,j,k) + r2pi_8
               if(k.ge.2.and.k.le.adx_lnk-2)then
                  !Cubic
                  wdt = &
                       w1(k)*F_wdm(i,j,k-1)+ &
                       w2(k)*F_wdm(i,j,k  )+ &
                       w3(k)*F_wdm(i,j,k+1)+ &
                       w4(k)*F_wdm(i,j,k+2)
               else
                  !Linear
                  wdt = (F_wdm(i,j,k)+F_wdm(i,j,k+1))*half
               endif
               F_zt(i,j,k)=adx_verZ_8%t(k)-(wdt+F_wat(i,j,k))*adx_dt_8*0.5d0
               ! Must stay in domain
               F_zt(i,j,k)=max(F_zt(i,j,k),ztop_bound)
               F_zt(i,j,k)=min(F_zt(i,j,k),zbot_bound)
            end do
         end do
      else
         do k=k00,adx_lnk-1
            do i=i0,in
               F_yt(i,j,k) = yasin(i,k)
               F_xt(i,j,k) = zatan(i,k)
               if ( F_xt(i,j,k) .lt. 0.0 ) F_xt(i,j,k) = F_xt(i,j,k) + r2pi_8
               if(k.ge.2.and.k.le.adx_lnk-2)then
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
      endif

   enddo
!$omp enddo
!$omp end parallel
!
return
end subroutine adx_pos_t
