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
#include "constants.h"
#include "msg.h"

!/@*
subroutine adx_set_interp()
   implicit none
#include <arch_specific.hf>
   !@objective set 1-D interpolation of grid reflexion across the pole 
   !@author  alain patoine
   !@revisions
   !*@/
   !
   !     Example of level positions for a 5 layer model (adx_lnkm=5)
   !
   !     %m (Momentum)      %t (Thermo)        %s (Superwinds)
   ! top ===============    ===============    =============== 1
   !     --------------- 1                     --------------- 2
   !                        --------------- 1  --------------- 3
   !     --------------- 2                     --------------- 4
   !                        --------------- 2  --------------- 5
   !     --------------- 3                     --------------- 6
   !                        --------------- 3  --------------- 7ERCI
   !     --------------- 4                     --------------- 8
   !                        --------------- 4  --------------- 9
   !     --------------- 5                     --------------- 10
   ! Srf ===============    =============== 5  =============== 11
   !
   !        N levels           N levels           N+1 levels        2N+1 levels

#include "adx_dims.cdk"
#include "adx_grid.cdk"
#include "adx_interp.cdk"
   
   real*8, parameter :: LARGE_8 = 1.D20
   real*8, parameter :: FRAC1OV6_8 = 1.D0/6.D0

   integer :: i, j, k, ij, pnerr, trj_i_off, nij, n, istat, istat2, ind
   integer :: i0, j0, k0, pnx, pny, nkm, nkt, nks

   real*8 :: ra,rb,rc,rd
   real*8 :: prhxmn, prhymn, prhzmn, dummy, pdfi

   real*8 ::whx(adx_gni+2*adx_halox)
   real*8 ::why(adx_gnj+2*adx_haloy)

   real*8 :: qzz_m_8(3*adx_lnk), qzi_m_8(4*adx_lnk)
   real*8 :: qzz_t_8(3*adx_lnk), qzi_t_8(4*adx_lnk)

   real*8,dimension(:),pointer :: whzt,whzm,whzs,super_z_8

#if !defined(TRIPROD)
#define TRIPROD(za,zb,zc,zd) ((za-zb)*(za-zc)*(za-zd))
#endif
   !---------------------------------------------------------------------
   ! See drawing above
   nkm=adx_lnk
   nkt=adx_lnk
   adx_lnks=2*adx_lnk+1
   nks=adx_lnks

   allocate( &
        whzm(0:nkm+1), &
        whzt(0:nkt+1), &
        whzs(0:nks+1), &
        super_z_8(nks), &
        stat = istat)

   allocate( &
        adx_xbc_8(adx_gni+2*adx_halox), &   ! (xc-xb)     along x
        adx_xabcd_8(adx_gni+2*adx_halox), & ! triproducts along x
        adx_xbacd_8(adx_gni+2*adx_halox), &
        adx_xcabd_8(adx_gni+2*adx_halox), &
        adx_xdabc_8(adx_gni+2*adx_halox), &
        adx_ybc_8(adx_gnj+2*adx_haloy), &   ! (yc-yb)     along y 
        adx_yabcd_8(adx_gnj+2*adx_haloy), & ! triproducts along y
        adx_ybacd_8(adx_gnj+2*adx_haloy), &
        adx_ycabd_8(adx_gnj+2*adx_haloy), &
        adx_ydabc_8(adx_gnj+2*adx_haloy), &
        stat = istat2)

   call handle_error_l(istat==0.and.istat2==0,'adx_set_interp','problem allocating mem')

   do i = adx_gminx+1,adx_gmaxx-2
      ra = adx_xg_8(i-1)
      rb = adx_xg_8(i)
      rc = adx_xg_8(i+1)
      rd = adx_xg_8(i+2)
      adx_xabcd_8(adx_halox+i) = 1.D0/TRIPROD(ra,rb,rc,rd)
      adx_xbacd_8(adx_halox+i) = 1.D0/TRIPROD(rb,ra,rc,rd)
      adx_xcabd_8(adx_halox+i) = 1.D0/TRIPROD(rc,ra,rb,rd)
      adx_xdabc_8(adx_halox+i) = 1.D0/TRIPROD(rd,ra,rb,rc)
   enddo

   do i = adx_gminx,adx_gmaxx-1
      rb = adx_xg_8(i)
      rc = adx_xg_8(i+1)
      adx_xbc_8(adx_halox+i) = 1.D0/(rc-rb)
   enddo

   do j = adx_gminy+1,adx_gmaxy-2
      ra = adx_yg_8(j-1)
      rb = adx_yg_8(j)
      rc = adx_yg_8(j+1)
      rd = adx_yg_8(j+2)
      adx_yabcd_8(adx_haloy+j) = 1.D0/TRIPROD(ra,rb,rc,rd)
      adx_ybacd_8(adx_haloy+j) = 1.D0/TRIPROD(rb,ra,rc,rd)
      adx_ycabd_8(adx_haloy+j) = 1.D0/TRIPROD(rc,ra,rb,rd)
      adx_ydabc_8(adx_haloy+j) = 1.D0/TRIPROD(rd,ra,rb,rc)
   enddo

   do j = adx_gminy,adx_gmaxy-1
      rb = adx_yg_8(j)
      rc = adx_yg_8(j+1)
      adx_ybc_8(adx_haloy+j) = 1.D0/(rc-rb)
   enddo


   trj_i_off = adx_mli0 - adx_li0

   adx_x00_8 = adx_xg_8(adx_gminx)
   adx_y00_8 = adx_yg_8(adx_gminy)

   prhxmn = LARGE_8
   prhymn = LARGE_8
   prhzmn = LARGE_8

   do i = adx_gminx,adx_gmaxx-1
      whx(adx_halox+i) = adx_xg_8(i+1) - adx_xg_8(i)
      prhxmn = min(whx(adx_halox+i), prhxmn)
   enddo

   do j = adx_gminy,adx_gmaxy-1
      why(adx_haloy+j) = adx_yg_8(j+1) - adx_yg_8(j)
      prhymn = min(why(adx_haloy+j), prhymn)
   enddo

   ! Prepare zeta on super vertical grid
   Super_z_8(1)=adx_verZ_8%m(0)
   do k = 2,nks
      if (mod(k,2) == 0)then
         ! momentum level
         ind = k/2
         Super_z_8(k) = adx_verZ_8%m(ind)
      else
         ! thermo level
         ind = (k+1)/2-1
         Super_z_8(k) = adx_verZ_8%t(ind)            
      endif
   enddo

   whzt(0    ) = 1.0
   whzt(nkt  ) = 1.0
   whzt(nkt+1) = 1.0
   do k = 1,nkt-1
      whzt(k) = adx_verZ_8%t(k+1) - adx_verZ_8%t(k)
      prhzmn = min(whzt(k), prhzmn)
   enddo

   whzm(0    ) = 1.0
   whzm(nkm  ) = 1.0
   whzm(nkm+1) = 1.0
   do k = 1,nkm-1
      whzm(k) = adx_verZ_8%m(k+1) - adx_verZ_8%m(k)
      prhzmn = min(whzm(k), prhzmn)
   enddo

   whzs(0    ) = 1.0
   whzs(nks  ) = 1.0
   whzs(nks+1) = 1.0
   do k=1,nks-1
      whzs(k) = Super_z_8(k+1) - Super_z_8(k)
      if(adx_superwinds_L)prhzmn = min(whzs(k), prhzmn)
   enddo

   adx_ovdx_8 = 1.0d0/prhxmn
   adx_ovdy_8 = 1.0d0/prhymn
   adx_ovdz_8 = 1.0d0/prhzmn

   pnx = int(1.0+(adx_xg_8(adx_gmaxx)-adx_x00_8)   *adx_ovdx_8)
   pny = int(1.0+(adx_yg_8(adx_gmaxy)-adx_y00_8)   *adx_ovdy_8)
   pnz = nint(1.0+(adx_verZ_8%m(nkm+1)-adx_verZ_8%m(0))*adx_ovdz_8)

   allocate( &
        adx_lcx(pnx), &
        adx_lcy(pny), &
        adx_bsx_8(adx_gni+2*adx_halox), &
        adx_dlx_8(adx_gni+2*adx_halox), &
        adx_dix_8(adx_gni+2*adx_halox), &
        adx_bsy_8(adx_gnj+2*adx_haloy), &
        adx_dly_8(adx_gnj+2*adx_haloy), &
        adx_diy_8(adx_gnj+2*adx_haloy), &
        adx_lcz%t(pnz), &
        adx_lcz%m(pnz),  &
        adx_lcz%s(pnz), &
        adx_bsz_8%t(0:nkt-1)  , &
        adx_bsz_8%m(0:nkm-1), &
        adx_bsz_8%s(0:nks-1), &
        adx_dlz_8%t(-1:nkt) , &
        adx_dlz_8%m(-1:nkm), &
        adx_diz_8(-1:nks), &
        stat=istat)
   call handle_error_l(istat==0,'adx_set_interp','problem allocating mem')

   i0 = 1
   do i=1,pnx
      pdfi = adx_xg_8(adx_gminx) + (i-1) * prhxmn
      if (pdfi > adx_xg_8(i0+1-adx_halox)) i0 = min(adx_gni+2*adx_halox-1,i0+1)
      adx_lcx(i) = i0
   enddo
   do i = adx_gminx,adx_gmaxx-1
      adx_dlx_8(adx_halox+i) =       whx(adx_halox+i)
      adx_dix_8(adx_halox+i) = 1.0d0/whx(adx_halox+i)
   enddo
   do i = adx_gminx,adx_gmaxx
      adx_bsx_8(adx_halox+i) = adx_xg_8(i)
   enddo

   j0 = 1
   do j = 1,pny
      pdfi = adx_yg_8(adx_gminy) + (j-1) * prhymn
      if (pdfi > adx_yg_8(j0+1-adx_haloy)) j0 = min(adx_gnj+2*adx_haloy-1,j0+1)
      adx_lcy(j) = j0
   enddo
   do j = adx_gminy,adx_gmaxy-1
      adx_dly_8(adx_haloy+j) =       why(adx_haloy+j)
      adx_diy_8(adx_haloy+j) = 1.0d0/why(adx_haloy+j)
   enddo
   do j = adx_gminy,adx_gmaxy
      adx_bsy_8(adx_haloy+j) = adx_yg_8(j)
   enddo

   k0 = 1

   do k = 1,pnz
      pdfi = adx_verZ_8%m(0) + (k-1) * prhzmn
      if (pdfi > adx_verZ_8%t(k0+1)) k0 = min(nkt-2, k0+1)
      adx_lcz%t(k) = k0
   enddo
   do k = 0,nkt+1                    !! warning note the shift in k !!
      adx_dlz_8%t(k-1) =       whzt(k)
   enddo
   do k = 1,nkt
      adx_bsz_8%t(k-1) = adx_verZ_8%t(k)
   enddo

   k0 = 1
   do k = 1,pnz
      pdfi = adx_verZ_8%m(0) + (k-1) * prhzmn
      if (pdfi > adx_verZ_8%m(k0+1)) k0 = min(nkm-2, k0+1)
      adx_lcz%m(k) = k0
   enddo
   do k = 0,nkm+1                    !! warning note the shift in k !!
      adx_dlz_8%m(k-1) =       whzm(k)
   enddo
   do k = 1,nkm
      adx_bsz_8%m(k-1) = adx_verZ_8%m(k)
   enddo

   k0 = 1
   do k = 1,pnz
      pdfi = adx_verZ_8%m(0) + (k-1) * prhzmn
      if (pdfi > Super_z_8(k0+1)) k0 = min(nks-2, k0+1)
      adx_lcz%s(k) = k0
   enddo
   do k = 1,nks
      adx_bsz_8%s(k-1) = Super_z_8(k)
   enddo

   if(adx_superwinds_L)then
      do k = 0,nks+1                  !! warning note the shift in k !!
         adx_diz_8(k-1) = 1.0d0/whzs(k)
      enddo
   else
      do k = 0,nkm+1                  !! warning note the shift in k !
         adx_diz_8(k-1) = 1.0d0/whzm(k)
      enddo
   endif

   allocate( &
        adx_zbc_8%t(nkt),   adx_zbc_8%m(nkm),   adx_zbc_8%s(nks)  , &
        adx_zabcd_8%t(nkt), adx_zabcd_8%m(nkm), adx_zabcd_8%s(nks), &
        adx_zbacd_8%t(nkt), adx_zbacd_8%m(nkm), adx_zbacd_8%s(nks), &
        adx_zcabd_8%t(nkt), adx_zcabd_8%m(nkm), adx_zcabd_8%s(nks), &
        adx_zdabc_8%t(nkt), adx_zdabc_8%m(nkm), adx_zdabc_8%s(nks), &
        stat=istat)
   call handle_error_l(istat==0,'adx_set_interp','problem allocating mem')

   do k = 2,nkm-2
      ra = adx_verZ_8%m(k-1)
      rb = adx_verZ_8%m(k)
      rc = adx_verZ_8%m(k+1)
      rd = adx_verZ_8%m(k+2)

      adx_zabcd_8%m(k) = 1.0/TRIPROD(ra,rb,rc,rd)
      adx_zbacd_8%m(k) = 1.0/TRIPROD(rb,ra,rc,rd)
      adx_zcabd_8%m(k) = 1.0/TRIPROD(rc,ra,rb,rd)
      adx_zdabc_8%m(k) = 1.0/TRIPROD(rd,ra,rb,rc)
   enddo

   do k = 2,nkt-2
      ra = adx_verZ_8%t(k-1)
      rb = adx_verZ_8%t(k)
      rc = adx_verZ_8%t(k+1)
      rd = adx_verZ_8%t(k+2)

      adx_zabcd_8%t(k) = 1.0/TRIPROD(ra,rb,rc,rd)
      adx_zbacd_8%t(k) = 1.0/TRIPROD(rb,ra,rc,rd)
      adx_zcabd_8%t(k) = 1.0/TRIPROD(rc,ra,rb,rd)
      adx_zdabc_8%t(k) = 1.0/TRIPROD(rd,ra,rb,rc)
   enddo

   do k = 2,nks-2
      ra = Super_z_8(k-1)
      rb = Super_z_8(k)
      rc = Super_z_8(k+1)
      rd = Super_z_8(k+2)

      adx_zabcd_8%s(k) = 1.0/TRIPROD(ra,rb,rc,rd)
      adx_zbacd_8%s(k) = 1.0/TRIPROD(rb,ra,rc,rd)
      adx_zcabd_8%s(k) = 1.0/TRIPROD(rc,ra,rb,rd)
      adx_zdabc_8%s(k) = 1.0/TRIPROD(rd,ra,rb,rc)
   enddo

   do k = 1,nkm-1
      rb = adx_verZ_8%m(k)
      rc = adx_verZ_8%m(k+1)
      adx_zbc_8%m(k) = 1.0/(rc-rb)
   enddo

   do k = 1,nkt-1
      rb = adx_verZ_8%t(k)
      rc = adx_verZ_8%t(k+1)
      adx_zbc_8%t(k) = 1.0/(rc-rb)
   enddo

   do k = 1,nks-1
      rb = Super_z_8(k)
      rc = Super_z_8(k+1)
      adx_zbc_8%s(k) = 1.0/(rc-rb)
   enddo

   deallocate(whzt, whzm, whzs, super_z_8)
   !---------------------------------------------------------------------
   return
end subroutine adx_set_interp
