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
!**s/r prep - Add metric corrections to r.h.s. of momentum equations.
!               Compute advective contributions on geopotential grid.
!               Interpolate advection contribution from geopotential
!               grid to wind grids. Update r.h.s with advective
!               contributions.
!               Combine some rhs obtaining Rt", Rf" and Rc", the linear
!               contributions to the rhs of Helmholtz equation
!
      subroutine pre ( F_ru  ,F_rv  ,F_ruw1 ,F_ruw2 ,F_rvw1 ,F_rvw2, &
                       F_xct1,F_yct1,F_zct1 ,F_fis  ,F_rc   ,F_rt  , &
                       F_rw  ,F_rf  ,F_rx   ,F_rq   ,F_oru  ,F_orv , &
                       F_rb,F_nest_t, Minx,Maxx,Miny,Maxy, &
                       i0, j0, in, jn, k0, ni, nj, Nk )
      implicit none
#include <arch_specific.hf>

      integer Minx,Maxx,Miny,Maxy, i0, j0, in, jn, k0, ni, nj, Nk
      real F_ru    (Minx:Maxx,Miny:Maxy,Nk)  ,F_rv    (Minx:Maxx,Miny:Maxy,Nk)  , &
           F_ruw1  (Minx:Maxx,Miny:Maxy,Nk)  ,F_ruw2  (Minx:Maxx,Miny:Maxy,Nk)  , &
           F_rvw1  (Minx:Maxx,Miny:Maxy,Nk)  ,F_rvw2  (Minx:Maxx,Miny:Maxy,Nk)  , &
           F_rc    (Minx:Maxx,Miny:Maxy,Nk)  ,F_rt    (Minx:Maxx,Miny:Maxy,Nk)  , &
           F_rw    (Minx:Maxx,Miny:Maxy,Nk)  ,F_rf    (Minx:Maxx,Miny:Maxy,Nk)  , &
           F_rx    (Minx:Maxx,Miny:Maxy,Nk)  ,F_rq    (Minx:Maxx,Miny:Maxy,Nk)  , &
           F_oru   (Minx:Maxx,Miny:Maxy,Nk)  ,F_orv   (Minx:Maxx,Miny:Maxy,Nk)  , &
           F_rb    (Minx:Maxx,Miny:Maxy)     ,F_nest_t(Minx:Maxx,Miny:Maxy,Nk)  , &
           F_fis   (Minx:Maxx,Miny:Maxy)                                        , &
           F_xct1  (ni,nj,Nk), F_yct1 (ni,nj,Nk), F_zct1 (ni,nj,Nk)

!author
!     Alain Patoine
!revision
! v2_00 - Desgagne M.       - initial MPI version (from rhs v1_03)
! v2_21 - Lee V.            - modification for LAM version
! v2_31 - Desgagne M.       - remove stkmemw and switch to adw_*
! v3_00 - Desgagne & Lee    - Lam configuration
! v3_10 - Corbeil & Desgagne & Lee - AIXport+Opti+OpenMP
! v3_11 - Gravel S.         - modify for theoretical cases
! v4_00 - Plante & Girard   - Log-hydro-pressure coord on Charney-Phillips grid
! v4_05 - Girard C.         - Open top
! v4_40 - Qaddouri/Lee      - expand range of calculation for Yin-Yang only
! v4.70 - Gaudreault S.     - Reformulation in terms of real winds (removing wind images)
! v4.80 - Lee V.            - correction in range for xch halo on Ru, Rv

#include "gmm.hf"
#include "glb_ld.cdk"
#include "lun.cdk"
#include "lam.cdk"
#include "cstv.cdk"
#include "dcst.cdk"
#include "grd.cdk"
#include "geomg.cdk"
#include "schm.cdk"
#include "inuvl.cdk"
#include "nest.cdk"
#include "ver.cdk"

      integer :: i0u, inu, j0v, jnv
      integer :: i, j, k, km, k0t
      real*8  x, y, z, cx, cy, cz, rx, ry, rz, mumu, &
              rdiv, w1, w2, w3, w4, w5
      real    w_rt
      real*8, parameter :: zero=0.d0, one=1.d0 , &
                           alpha1=-1.d0/16.d0 , alpha2=9.d0/16.d0
!
!     ---------------------------------------------------------------
!  
      if (Lun_debug_L) write (Lun_out,1000)
      k0t= k0
      if(Schm_opentop_L) k0t= k0-1

      if (.not.G_lam) then ! GU

!*****************************************************************
! Metric corrections to the RHS of horizontal momentum equations *
!*****************************************************************

!$omp parallel private(x,y,z,rz,ry,rx,cx,cy,cz,mumu)

!$omp do
         do k= k0, l_nk
            do j= j0, jn
            do i= i0, in

!                 Compute components of r(t0) and put in x, y, z
!                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  x = geomg_cx_8(i) * geomg_cy_8(j)
                  y = geomg_sx_8(i) * geomg_cy_8(j)
                  z = geomg_sy_8(j)

!                 Compute (Rx, Ry, Rz) = (rx, ry, rz)
!                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  mumu = ( one + F_zct1(i,j,k) )*( one - F_zct1(i,j,k) )
                  if (mumu .GT. zero) mumu = one / mumu

                  rz = F_rvw2(i,j,k)
                  ry =  mumu * (F_xct1(i,j,k)*F_ruw2(i,j,k)- &
                                F_yct1(i,j,k)*F_zct1(i,j,k)*rz)
                  rx = -mumu * (F_yct1(i,j,k)*F_ruw2(i,j,k)+ &
                                F_xct1(i,j,k)*F_zct1(i,j,k)*rz)

!                 Compute components of c and put in cx, cy, cz
!                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  cx = x + Cstv_Beta_8*F_xct1(i,j,k)
                  cy = y + Cstv_Beta_8*F_yct1(i,j,k)
                  cz = z + Cstv_Beta_8*F_zct1(i,j,k)

!                 Compute mu and modify (Rx,Ry,Rz)
!                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  mumu = - ( x*rx + y*ry + z*rz )/( x*cx + y*cy + z*cz )
                  rx = rx + mumu*cx
                  ry = ry + mumu*cy
                  rz = rz + mumu*cz

!                 Compute advective contributions on G-grid
!                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  F_ruw2(i,j,k) = x*ry - y*rx - F_ruw1(i,j,k)
                  F_rvw2(i,j,k) = rz - F_rvw1(i,j,k)
            end do
            end do
            F_rv(:,0   ,k) = 0.
            F_rv(:,l_nj,k) = 0.
         end do
!$omp enddo

!$omp single

         call rpn_comm_xch_halo( F_ruw2, l_minx,l_maxx,l_miny,l_maxy, l_ni,l_nj,G_nk, &
                                 G_halox,G_haloy,G_periodx,G_periody,l_ni,0 )
         call rpn_comm_xch_halo( F_rvw2, l_minx,l_maxx,l_miny,l_maxy, l_ni, l_nj,G_nk, &
                                 G_halox,G_haloy,G_periodx,G_periody,l_ni,0 )
         i0u = i0-1
         j0v = j0-1
         inu = l_niu
         jnv = l_njv
         if (l_south) j0v=j0

!$omp end single

!*********************************************************
! Final form of the RHS of horizontal momentum equations *
!*********************************************************
!$omp do
         do k= k0, l_nk

!     Add advective contributions to Ru & Rv
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            do j= j0, jn
            do i= i0u, inu
               F_ru(i,j,k) =  F_oru(i,j,k)  &
                          + ( F_ruw2(i-1,j,k) + F_ruw2(i+2,j,k) )*alpha1 &
                          + ( F_ruw2(i  ,j,k) + F_ruw2(i+1,j,k) )*alpha2
            end do
            end do

            do j= j0v, jnv
            do i= i0, in
               F_rv(i,j,k) =  F_orv(i,j,k) + &
                            inuvl_wyyv3_8(j,1)*F_rvw2(i,j-1,k) &
                          + inuvl_wyyv3_8(j,2)*F_rvw2(i,j  ,k) &
                          + inuvl_wyyv3_8(j,3)*F_rvw2(i,j+1,k) &
                          + inuvl_wyyv3_8(j,4)*F_rvw2(i,j+2,k)
            end do
            end do
         end do
!$omp enddo
!$omp end parallel

      else

         call rpn_comm_xch_halo( F_ru, l_minx,l_maxx,l_miny,l_maxy, l_niu, l_nj,G_nk, &
                                 G_halox,G_haloy,G_periodx,G_periody,l_ni,0 )
         call rpn_comm_xch_halo( F_rv, l_minx,l_maxx,l_miny,l_maxy, l_ni, l_njv,G_nk, &
                                 G_halox,G_haloy,G_periodx,G_periody,l_ni,0 )

      endif

!*************************************
! Combination of governing equations *
!*************************************

!$omp parallel private(km,rdiv,w1,w2,w3,w4,w5,w_rt)

!$omp do
      do k=k0, l_nk
         km=max(k-1,1)

         if(Schm_nologT_L) then

            w1= Ver_idz_8%m(k)+Ver_wp_8%m(k)
            w2=(Ver_idz_8%m(k)-Ver_wm_8%m(k))*Ver_onezero(k)
            w3=one/Ver_Tstar_8%t(k)
            w4=Dcst_rgasd_8*Ver_Tstar_8%t(k)*Ver_wpstar_8(k)
            w5=Dcst_rgasd_8*Ver_Tstar_8%t(k)*Ver_wmstar_8(k)
            do j= j0, jn
            do i= i0, in

!              Preliminary combinations: Rc', Rt', Rf'
!              ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
               F_rc(i,j,k)=F_rc(i,j,k)-w1*(F_rx(i,j,k )+F_rq(i,j,k ) -   &
                                          (one -Cstv_rE_8)*F_rq(i,j,k )) &
                                      +w2*(F_rx(i,j,km)+F_rq(i,j,km) -   &
                                          (one-Cstv_rE_8)*F_rq(i,j,km))
               F_rt(i,j,k)=F_rt(i,j,k)*w3
               F_rf(i,j,k)=F_rf(i,j,k)+w4*(F_rx(i,j,k ) + F_rq(i,j,k ) -  &
                                          (one-Cstv_rE_8)*F_rq(i,j,k ))   &
                                      +w5*(F_rx(i,j,km)+F_rq(i,j,km) -    &
                                          (one-Cstv_rE_8)*F_rq(i,j,km))

            end do
            end do

         endif

         w1= Ver_igt_8*Ver_wpA_8(k)
         w2= Ver_igt_8*Ver_wmA_8(k)*Ver_onezero(k)
         do j= j0, jn
         do i= i0, in

!           Combine continuity & w equations
!           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            F_rc(i,j,k) = F_rc(i,j,k) - w1*F_rw(i,j,k ) - w2*F_rw(i,j,km)

!           Compute the divergence of the RHS of momentum equations
!           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            rdiv  = (F_ru(i,j,k)-F_ru(i-1,j,k))*geomg_invDXM_8(j) &
                  + (F_rv(i,j,k)*geomg_cyM_8(j)-F_rv(i,j-1,k)*geomg_cyM_8(j-1))*geomg_invDYM_8(j)

!           Combine divergence & continuity equations : Rc"
!           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            F_rc(i,j,k) = rdiv - F_rc(i,j,k) / Cstv_tau_8

         end do
         end do

      end do
!$omp enddo

      if (Schm_opentop_L) then
         w3=one
         if(Schm_nologT_L) w3=one/Ver_Tstar_8%t(k0t)
         w4=Dcst_rgasd_8*Ver_Tstar_8%t(k0t)
!$omp do
         do j= j0, jn
         do i= i0, in
            F_rt(i,j,k0t)=F_rt(i,j,k0t)*w3
            F_rb(i,j) = F_rt(i,j,k0t)
         end do
         end do
!$omp enddo
         if(Schm_nologT_L) then
!$omp do
            do j= j0, jn
            do i= i0, in
               F_rf(i,j,k0t)=F_rf(i,j,k0t)+w4*(F_rx(i,j,k0t)+F_rq(i,j,k0t) &
                                           - (one-Cstv_rE_8)*F_rq(i,j,k0t))
            end do
            end do
!$omp enddo
         endif
      endif

!$omp do
      do k=k0t,l_nk

!        Compute Rt" & Rf"
!        ~~~~~~~~~~~~~~~~~

         w1 = Dcst_cappa_8 /( Dcst_Rgasd_8 * Ver_Tstar_8%t(k) )
         w2 = Cstv_invT_8 / ( Dcst_cappa_8 + Ver_epsi_8(k) )
         do j= j0, jn
         do i= i0, in
!           Combine Rt and Rw
!           ~~~~~~~~~~~~~~~~~
            w_rt = F_rt(i,j,k) + Ver_igt_8 * F_rw(i,j,k)

!           Compute Rt"
!           ~~~~~~~~~~~
            F_rt(i,j,k) = w2 * ( w_rt + Ver_igt2_8 * F_rf(i,j,k) )

!           Compute Rf"
!           ~~~~~~~~~~~
            F_rf(i,j,k) = w2 * ( w_rt - w1 * F_rf(i,j,k) )
         end do
         end do

      enddo
!$omp enddo

!$omp do
      do j= j0, jn
      do i= i0, in
!        Adjust Rt" at last level : Rt"'
!        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         F_rt(i,j,l_nk) = (F_rt(i,j,l_nk)-Ver_wmstar_8(l_nk)*F_rt(i,j,l_nk-1)) &
                          /Ver_wpstar_8(l_nk)
      end do
      end do
!$omp enddo

!************************************************************
! The linear contributions to the RHS of Helmholtz equation *
!************************************************************

!     Finish computations of RP(in Rc), combining Rc", Rt", Rf"
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

!$omp do
      do k=k0,l_nk
         km=max(k-1,1)
         w1= Ver_idz_8%m(k) + Ver_wp_8%m(k)
         w2=(Ver_idz_8%m(k) - Ver_wm_8%m(k))*Ver_onezero(k)
         w3=Ver_wpA_8(k)*Ver_epsi_8(k)
         w4=Ver_wmA_8(k)*Ver_epsi_8(km)*Ver_onezero(k)
         do j= j0, jn
         do i= i0, in
            F_rc(i,j,k) = F_rc(i,j,k) - Cstv_bar0_8 * F_fis(i,j) &
                           - w1 * F_rt(i,j,k) + w2 * F_rt(i,j,km) &
                           - w3 * F_rf(i,j,k) - w4 * F_rf(i,j,km)
         end do
         end do
      end do
!$omp enddo

      if (Schm_opentop_L) then

!        Apply opentop boundary conditions

         w1=Cstv_invT_8/Ver_Tstar_8%t(k0t)
!$omp do
         do j= j0, jn
         do i= i0, in
            F_rb(i,j) = F_rt(i,j,k0t) - Ver_ikt_8*(F_rb(i,j) - w1*(F_nest_t(i,j,k0t)-Ver_Tstar_8%t(k0t)))
            F_rc(i,j,k0  ) = F_rc(i,j,k0  ) - Ver_cstp_8 * F_rb(i,j)
         end do
         end do
!$omp enddo

      endif

!     Apply lower boundary conditions
!
     if(Schm_nologT_L) then
!$omp do
         do j= j0, jn
         do i= i0, in
            F_rt(i,j,l_nk) = F_rt(i,j,l_nk) - Cstv_invT_8 * (F_rx(i,j,l_nk)+F_rq(i,j,l_nk))
         end do
         end do
!$omp enddo
      endif

      w1 = Cstv_invT_8**2 / ( Dcst_Rgasd_8 * Ver_Tstar_8%m(l_nk+1) )
!$omp do
      do j= j0, jn
      do i= i0, in
         F_rt(i,j,l_nk) = F_rt(i,j,l_nk) - w1 * F_fis(i,j)
         F_rt(i,j,l_nk) = Ver_wpstar_8(l_nk) * F_rt(i,j,l_nk)
         F_rc(i,j,l_nk) = F_rc(i,j,l_nk) + Ver_cssp_8 * F_rt(i,j,l_nk)
      end do
      end do
!$omp enddo
!$omp end parallel

1000  format(3X,'UPDATE  THE RIGHT-HAND-SIDES: (S/R PRE)')
!
!     ---------------------------------------------------------------
!  
      return
      end
