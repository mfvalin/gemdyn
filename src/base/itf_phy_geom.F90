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

   subroutine itf_phy_geom4 (F_istat)
   use iso_c_binding
   use nest_blending, only: nest_blend
   implicit none
#include <arch_specific.hf>

   integer F_istat

#include <rmnlib_basics.hf>
#include <gmm.hf>
#include <msg.h>
#include "glb_ld.cdk"
#include "cstv.cdk"
#include "geomg.cdk"
#include "geomn.cdk"
#include "p_geof.cdk"
#include "dcst.cdk"
#include "lam.cdk"

   logical :: nest_it
   integer :: i,j,istat
   real,pointer :: wrk1(:,:) 
   real(kind=8) :: deg2rad_8
   real :: w1(l_minx:l_maxx,l_miny:l_maxy,2),&
           w2(l_minx:l_maxx,l_miny:l_maxy,2)
   type(gmm_metadata) :: mymeta
!
!-------------------------------------------------------------------
!
   F_istat = RMN_OK

   mymeta = GMM_NULL_METADATA
   mymeta%l(1) = gmm_layout(1,l_ni,0,0,l_ni)
   mymeta%l(2) = gmm_layout(1,l_nj,0,0,l_nj)

   deg2rad_8 = acos(-1.D0)/180.D0
  
   nullify(wrk1)
   istat = gmm_create('DLAT',wrk1,mymeta)
   if (RMN_IS_OK(istat)) then
      wrk1 = deg2rad_8*Geomn_latrx
   else
      F_istat = RMN_ERR
      call msg(MSG_ERROR,'(itf_phy_geom) Problem creating DLAT')
   endif

   nullify(wrk1)
   istat = gmm_create('DLON',wrk1,mymeta)
   if (RMN_IS_OK(istat)) then
      where(Geomn_lonrx >= 0)
         wrk1 = deg2rad_8*Geomn_lonrx
      elsewhere
         wrk1 = deg2rad_8*(Geomn_lonrx+360.)
      endwhere
   else
      F_istat = RMN_ERR
      call msg(MSG_ERROR,'(itf_phy_geom) Problem creating DLON')
   endif

   nullify(wrk1)
   istat = gmm_create('DXDY',wrk1,mymeta)
   if (RMN_IS_OK(istat)) then
      do j = 1,l_nj
         do i = 1,l_ni
             wrk1(i,j) = geomg_hx_8*geomg_hy_8*     &
                  Dcst_rayt_8*Dcst_rayt_8*geomg_cy_8(j)
         end do
      end do
   else
      F_istat = RMN_ERR
      call msg(MSG_ERROR,'(itf_phy_geom) Problem creating DXDY')
   endif

   nullify(wrk1)
   istat = gmm_create('TDMASK',wrk1,mymeta)
   if (RMN_IS_OK(istat)) then
      w1 = 1.
      nest_it = ( Lam_0ptend_L .and. G_lam .and. &
                ((Lam_blend_Hx.gt.0).or.(Lam_blend_Hy.gt.0)) )
      if ( nest_it ) then
         w2 = 0.
         call nest_blend (w1(:,:,1),w2(:,:,1),l_minx,l_maxx,l_miny,l_maxy,'M',level=G_nk+1)
      endif
      wrk1(1:l_ni,1:l_nj) = w1(1:l_ni,1:l_nj,1)
   else
      F_istat= RMN_ERR
      call msg(MSG_ERROR,'(itf_phy_geom) Problem creating TDMASK')
   endif
!
!-------------------------------------------------------------------
!
   return
   end subroutine itf_phy_geom4
