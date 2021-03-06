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
subroutine adx_lag3d_tricub2(F_out, F_in, F_x, F_y, F_z, &
                             adx_y00_8,adx_x00_8,p_z00_8,adx_ovdx_8,adx_ovdy_8,adx_ovdz_8, &
                             adx_lcx,adx_lcy,p_lcz, adx_bsx_8,adx_bsy_8,p_bsz_8, &
                             adx_xabcd_8,adx_xbacd_8,adx_xcabd_8,adx_xdabc_8, &
                             adx_yabcd_8,adx_ybacd_8,adx_ycabd_8,adx_ydabc_8, &
                             p_zabcd_8,p_zbacd_8, p_zcabd_8, p_zdabc_8, p_zbc_8,&
                             F_num, F_mono_L, i0, in, j0, jn, k0, F_nk, kkmax)
   implicit none
#include <arch_specific.hf>
!
   !@objective Tri-cubic interp: Lagrange 3d (Based on adx_tricub v3.1.1)
!
   !@arguments
   integer :: F_num            !I, number points
   integer :: F_nk             !I, number of vertical levels
   integer :: i0,in,j0,jn,k0   !I, scope of operator
   logical :: F_mono_L         !I, .true. monotonic interpolation
   real,dimension(F_num) :: &
        F_x, F_y, F_z          !I, interpolation target x,y,z coordinates
   real,dimension(*) :: &
        F_in                   !I, field to interpolate 
   real,dimension(F_num) :: &
        F_out                  !O, result of interpolation

   integer :: kkmax
   real*8  :: p_z00_8

   !TODO: specify min:max if not starting from zero
   integer,dimension(*) :: p_lcz
   real*8, dimension(0:kkmax+2) :: p_bsz_8
   real*8, dimension(*) :: p_zbc_8, p_zabcd_8,p_zbacd_8, p_zcabd_8, p_zdabc_8

   integer,dimension(*) :: adx_lcx,adx_lcy
   real*8, dimension(*) :: adx_bsx_8,adx_bsy_8
   real*8, dimension(*) :: adx_xabcd_8,adx_xbacd_8,adx_xcabd_8,adx_xdabc_8
   real*8, dimension(*) :: adx_yabcd_8,adx_ybacd_8,adx_ycabd_8,adx_ydabc_8
   real*8  :: adx_y00_8,adx_x00_8,adx_ovdx_8,adx_ovdy_8,adx_ovdz_8
!
   !@author Gravel, Valin, Tanguay 
   !@revisions
   ! v3_20 - Gravel & Valin & Tanguay - initial version 
   ! v3_21 - Desgagne M.       - Revision Openmp
!*@/

!#undef __ADX_DIMS__
#include "adx_dims.cdk"

!!$#define TRIPROD(ZA,ZB,ZC,ZD) ((ZA-ZB)*(ZA-ZC)*(ZA-ZD))
   integer :: n,i,j,k,ii,jj,kk
   logical :: zcubic_L

   real :: prmin, prmax

   integer :: o1, o2, o3, o4
   real*8  :: a1, a2, a3, a4
   real*8  :: b1, b2, b3, b4
   real*8  :: c1, c2, c3, c4
   real*8  :: d1, d2, d3, d4
   real*8  :: p1, p2, p3, p4
   real*8  :: rri,rrj,rrk,ra,rb,rc,rd

   real*8 :: triprd,za,zb,zc,zd
   triprd(za,zb,zc,zd)=(za-zb)*(za-zc)*(za-zd)

   !---------------------------------------------------------------------
   call handle_error_l(.false.,'adx_lag3d_tricub2','Should not be used!')

!$omp do
   DO_K2: do k=k0,F_nk
      DO_J2: do  j=j0,jn
         DO_I2: do  i=i0,in
            n = (k-1)*Adx_mlnij + ((j-1)*adx_mlni) + i

            rri= F_x(n)
            ii = (rri - adx_x00_8) * adx_ovdx_8
            ii = adx_lcx(ii+1) + 1
            if (rri < adx_bsx_8(ii)) ii = ii - 1
            ii = max(2,min(ii,Adx_iimax))

            rrj= F_y(n)
            jj = (rrj - adx_y00_8) * adx_ovdy_8
            jj = adx_lcy(jj+1) + 1
            if (rrj < adx_bsy_8(jj)) jj = jj - 1
            jj = max(adx_haloy,min(jj,Adx_jjmax))

            rrk= F_z(n)
            kk = (rrk - p_z00_8) * adx_ovdz_8
            kk = p_lcz(kk+1)
            if (rrk < p_bsz_8(kk)) kk = kk - 1
            kk = min(kkmax-1,max(0,kk))

            zcubic_L = (kk > 1) .and. (kk < kkmax-1)

            !- x interpolation
            ra = adx_bsx_8(ii-1)
            rb = adx_bsx_8(ii  )
            rc = adx_bsx_8(ii+1)
            rd = adx_bsx_8(ii+2)
            p1 = triprd(rri,rb,rc,rd)*adx_xabcd_8(ii)
            p2 = triprd(rri,ra,rc,rd)*adx_xbacd_8(ii)
            p3 = triprd(rri,ra,rb,rd)*adx_xcabd_8(ii)
            p4 = triprd(rri,ra,rb,rc)*adx_xdabc_8(ii)

            o2 = (kk-1)*Adx_nijag + (jj-Adx_int_j_off-1)*Adx_nit + (ii-Adx_int_i_off)
            o1 = o2-Adx_nit
            o3 = o2+Adx_nit
            o4 = o3+Adx_nit

            if (zcubic_L) then
               a1 = p1 * F_in(o1-1) + p2 * F_in(o1) + p3 * F_in(o1+1) + p4 * F_in(o1+2)
               a2 = p1 * F_in(o2-1) + p2 * F_in(o2) + p3 * F_in(o2+1) + p4 * F_in(o2+2)
               a3 = p1 * F_in(o3-1) + p2 * F_in(o3) + p3 * F_in(o3+1) + p4 * F_in(o3+2)
               a4 = p1 * F_in(o4-1) + p2 * F_in(o4) + p3 * F_in(o4+1) + p4 * F_in(o4+2)
            endif

            o1 = o1 + Adx_nijag
            o2 = o2 + Adx_nijag
            o3 = o3 + Adx_nijag
            o4 = o4 + Adx_nijag

            if (F_mono_L) then
               prmax = max(F_in(o2),F_in(o2+1),F_in(o3),F_in(o3+1))
               prmin = min(F_in(o2),F_in(o2+1),F_in(o3),F_in(o3+1))
            endif
            b1 = p1 * F_in(o1-1) + p2 * F_in(o1) + p3 * F_in(o1+1) + p4 * F_in(o1+2)
            b2 = p1 * F_in(o2-1) + p2 * F_in(o2) + p3 * F_in(o2+1) + p4 * F_in(o2+2)
            b3 = p1 * F_in(o3-1) + p2 * F_in(o3) + p3 * F_in(o3+1) + p4 * F_in(o3+2)
            b4 = p1 * F_in(o4-1) + p2 * F_in(o4) + p3 * F_in(o4+1) + p4 * F_in(o4+2)

            o1 = o1 + Adx_nijag
            o2 = o2 + Adx_nijag
            o3 = o3 + Adx_nijag
            o4 = o4 + Adx_nijag

            if (F_mono_L) then
               prmax = max(prmax,F_in(o2),F_in(o2+1),F_in(o3),F_in(o3+1))
               prmin = min(prmin,F_in(o2),F_in(o2+1),F_in(o3),F_in(o3+1))
            endif
            c1 = p1 * F_in(o1-1) + p2 * F_in(o1) + p3 * F_in(o1+1) + p4 * F_in(o1+2)
            c2 = p1 * F_in(o2-1) + p2 * F_in(o2) + p3 * F_in(o2+1) + p4 * F_in(o2+2)
            c3 = p1 * F_in(o3-1) + p2 * F_in(o3) + p3 * F_in(o3+1) + p4 * F_in(o3+2)
            c4 = p1 * F_in(o4-1) + p2 * F_in(o4) + p3 * F_in(o4+1) + p4 * F_in(o4+2)

            if (zcubic_L) then
               o1 = o1 + Adx_nijag
               o2 = o2 + Adx_nijag
               o3 = o3 + Adx_nijag
               o4 = o4 + Adx_nijag

               d1 = p1 * F_in(o1-1) + p2 * F_in(o1) + p3 * F_in(o1+1) + p4 * F_in(o1+2)
               d2 = p1 * F_in(o2-1) + p2 * F_in(o2) + p3 * F_in(o2+1) + p4 * F_in(o2+2)
               d3 = p1 * F_in(o3-1) + p2 * F_in(o3) + p3 * F_in(o3+1) + p4 * F_in(o3+2)
               d4 = p1 * F_in(o4-1) + p2 * F_in(o4) + p3 * F_in(o4+1) + p4 * F_in(o4+2)
            endif

            !- y interpolation
            ra = adx_bsy_8(jj-1)
            rb = adx_bsy_8(jj  )
            rc = adx_bsy_8(jj+1)
            rd = adx_bsy_8(jj+2)
            p1 = triprd(rrj,rb,rc,rd)*adx_yabcd_8(jj)
            p2 = triprd(rrj,ra,rc,rd)*adx_ybacd_8(jj)
            p3 = triprd(rrj,ra,rb,rd)*adx_ycabd_8(jj)
            p4 = triprd(rrj,ra,rb,rc)*adx_ydabc_8(jj)

            b1 = p1 * b1 + p2 * b2 + p3 * b3 + p4 * b4
            c1 = p1 * c1 + p2 * c2 + p3 * c3 + p4 * c4

            !- z interpolation
            if (zcubic_L) then
               a1 = p1 * a1 + p2 * a2 + p3 * a3 + p4 * a4
               d1 = p1 * d1 + p2 * d2 + p3 * d3 + p4 * d4
               ra = p_bsz_8(kk-1)
               rb = p_bsz_8(kk  )
               rc = p_bsz_8(kk+1)
               rd = p_bsz_8(kk+2)
               p1 = triprd(rrk,rb,rc,rd)*p_zabcd_8(kk+1)
               p2 = triprd(rrk,ra,rc,rd)*p_zbacd_8(kk+1)
               p3 = triprd(rrk,ra,rb,rd)*p_zcabd_8(kk+1)
               p4 = triprd(rrk,ra,rb,rc)*p_zdabc_8(kk+1)

               F_out(n) = p1 * a1 + p2 * b1 + p3 * c1 + p4 * d1
            else
               p3 = (rrk-p_bsz_8(kk))*p_zbc_8(kk+1)
               p2 = 1. - p3

               F_out(n) = p2 * b1 + p3 * c1
            endif

            if (F_mono_L) then
               F_out(n) = max(prmin , min(prmax,F_out(n)))
            endif
         enddo DO_I2
      enddo DO_J2
   enddo DO_K2
!$omp enddo

   !---------------------------------------------------------------------

   return
end subroutine adx_lag3d_tricub2

