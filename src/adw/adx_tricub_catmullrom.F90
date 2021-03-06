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
subroutine adx_tricub_catmullrom (F_out, F_in, F_x, F_y, F_z, F_num,&
                                  F_mono_L, i0, in, j0, jn, k0, F_nk, F_lev_S)
   implicit none
#include <arch_specific.hf>
!
   !@objective Tri-cubic interp: Lagrange vertical / Catmull-Rom horiz.
!
   !@arguments
   character(len=*), intent(in) :: F_lev_S            ! m/t : Momemtum/thermo level
   integer, intent(in) :: F_num                       ! number points
   integer, intent(in) :: F_nk                        ! number of vertical levels
   integer, intent(in) :: i0,in,j0,jn,k0              ! scope of operator
   logical, intent(in) :: F_mono_L                    ! .true. monotonic interpolation
   real,dimension(F_num), intent(in) :: F_x, F_y, F_z ! interpolation target x,y,z coordinates
   real,dimension(*), intent(in) :: F_in              ! field to interpolate
   real,dimension(F_num), intent(out) :: F_out        ! result of interpolation
   !
   !@revisions
   !  2012-05,  Stephane Gaudreault: code optimization
!*@/

#include "adx_dims.cdk"
#include "adx_grid.cdk"
#include "adx_interp.cdk"

   integer :: kkmax
   real*8  :: p_z00_8

   integer,dimension(:),pointer :: p_lcz
   real*8, dimension(:),pointer :: p_bsz_8, p_zbc_8, p_zabcd_8
   real*8, dimension(:),pointer :: p_zbacd_8, p_zcabd_8, p_zdabc_8

   integer :: n,i,j,k,ii,jj,kk
   integer :: idxk, idxjk
   logical :: zcubic_L

   real :: prmin, prmax

   integer :: o1, o2, o3, o4
   real  :: a1, a2, a3, a4
   real  :: b1, b2, b3, b4
   real  :: c1, c2, c3, c4
   real  :: d1, d2, d3, d4
   real  :: p1, p2, p3, p4
   real*8  :: rri,rrj,rrk,ra,rb,rc,rd
   real    :: ii_d, jj_d

   real*8 :: triprd,za,zb,zc,zd
   triprd(za,zb,zc,zd)=(za-zb)*(za-zc)*(za-zd)

   !---------------------------------------------------------------------

   call timing_start2 (34, 'ADW_CATMUL', 31)

   p_z00_8 = adx_verZ_8%m(0)
   if (F_lev_S == 'm') then
      kkmax   = adx_lnk - 1
      p_lcz     => adx_lcz%m
      p_bsz_8   => adx_bsz_8%m
      p_zabcd_8 => adx_zabcd_8%m
      p_zbacd_8 => adx_zbacd_8%m
      p_zcabd_8 => adx_zcabd_8%m
      p_zdabc_8 => adx_zdabc_8%m
      p_zbc_8   => adx_zbc_8%m
   else if (F_lev_S == 't') then
      kkmax   = adx_lnk-1
      p_lcz     => adx_lcz%t
      p_bsz_8   => adx_bsz_8%t
      p_zabcd_8 => adx_zabcd_8%t
      p_zbacd_8 => adx_zbacd_8%t
      p_zcabd_8 => adx_zcabd_8%t
      p_zdabc_8 => adx_zdabc_8%t
      p_zbc_8   => adx_zbc_8%t
   else if (F_lev_S == 's') then
      kkmax   = adx_lnks - 1
      p_lcz     => adx_lcz%s
      p_bsz_8   => adx_bsz_8%s
      p_zabcd_8 => adx_zabcd_8%s
      p_zbacd_8 => adx_zbacd_8%s
      p_zcabd_8 => adx_zcabd_8%s
      p_zdabc_8 => adx_zdabc_8%s
      p_zbc_8   => adx_zbc_8%s
   else
      !TO DO catch this error (since notr all cpu pass here we cannot call handle_error)
      ! This s/r should be a function with a return status.
      ! print*,'ERROR IN ADX_TRICUB_LAG3D'
   endif

   if (F_mono_L) then

!$omp parallel private(o1, o2, o3, o4, a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4,  &
!$omp                  d1, d2, d3, d4, p1, p2, p3, p4, rri,rrj,rrk,ra,rb,rc,rd, n,i,j,k,&
!$omp                  ii,jj,kk,idxk, idxjk,zcubic_L)                                   &
!$omp          shared (F_out, F_in, F_x, F_y, F_z, adx_y00_8,adx_x00_8,adx_ovdx_8,adx_ovdy_8,   &
!$omp                  adx_ovdz_8, adx_lcx,adx_lcy, adx_bsx_8,adx_bsy_8,p_bsz_8, adx_xabcd_8,   &
!$omp                  adx_xbacd_8,adx_xcabd_8,adx_xdabc_8, adx_yabcd_8,adx_ybacd_8,adx_ycabd_8,&
!$omp                  adx_ydabc_8, p_zabcd_8,p_zbacd_8, p_zcabd_8, p_zdabc_8, p_zbc_8, kkmax,  &
!$omp                  F_num, i0, in, j0, jn, k0, F_nk)
!$omp do private(prmin, prmax)

#define ADX_MONO
#include "adx_tricub_catmullrom_loop.cdk"

!$omp enddo
!$omp end parallel

   else

!$omp parallel private(o1, o2, o3, o4, a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4,  &
!$omp                  d1, d2, d3, d4, p1, p2, p3, p4, rri,rrj,rrk,ra,rb,rc,rd, n,i,j,k,&
!$omp                  ii,jj,kk,idxk, idxjk,zcubic_L)                                   &
!$omp          shared (F_out, F_in, F_x, F_y, F_z, adx_y00_8,adx_x00_8,adx_ovdx_8,adx_ovdy_8,   &
!$omp                  adx_ovdz_8, adx_lcx,adx_lcy,adx_bsx_8,adx_bsy_8,p_bsz_8, adx_xabcd_8,    &
!$omp                  adx_xbacd_8,adx_xcabd_8,adx_xdabc_8, adx_yabcd_8,adx_ybacd_8,adx_ycabd_8,&
!$omp                  adx_ydabc_8, p_zabcd_8,p_zbacd_8, p_zcabd_8, p_zdabc_8, p_zbc_8, kkmax,  &
!$omp                  F_num, i0, in, j0, jn, k0, F_nk)
!$omp do

#undef ADX_MONO
#include "adx_tricub_catmullrom_loop.cdk"

!$omp enddo
!$omp end parallel

   endif

   call timing_stop (34)

   !---------------------------------------------------------------------

   return
end subroutine adx_tricub_catmullrom
