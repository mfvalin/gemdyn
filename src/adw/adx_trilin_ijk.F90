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
subroutine adx_trilin_ijk1 ( F_x, F_y, F_z, F_capz, F_ii, F_jj, F_kk,       &
                            F_lcx, F_lcy, F_lcz, F_bsx_8, F_bsy_8, F_bsz_8, &
                            F_diz_8, F_z00_8, F_iimax,                      &
                            F_num, i0, in, j0, jn, k0, F_nk, F_nkm )
   implicit none
#include <arch_specific.hf>
!
   !@objective Optimized tri-linear interpolation with SETINT inside
!
   !@arguments
   integer :: F_nk,F_nkm                        !I, number of vertical levels
   integer :: F_num                             !I, dims of position fields
   integer :: i0,in,j0,jn,k0                    !I, scope ofthe operator
   integer F_iimax
   integer,dimension(F_num) :: &
        F_ii, F_jj, F_kk                        !I/O, localisation indices
   real,dimension(F_num)    :: &
        F_capz, &                               !I/O, precomputed displacements along the z-dir
        F_x, F_y, F_z                           !I, x,y,z positions 
   integer,dimension(*)  :: F_lcx,F_lcy,F_lcz
   real*8  F_z00_8
   real*8, dimension(*)        :: F_bsx_8,F_bsy_8
   real*8, dimension( 0:*) :: F_bsz_8
   real*8, dimension(-1:*) :: F_diz_8
!
   !@author Valin, Tanguay  
   !@revisions
   ! v3_20 -Valin & Tanguay -  initial version 
   ! v3_21 -Tanguay M.      -  evaluate min-max vertical CFL as function of k 
   ! v4_10 -Plante A.       -  Replace single locator vector with 3 vectors.
!*@/

#include "adx_dims.cdk"
#include "adx_interp.cdk"

   integer :: n, n0, o1, o2
   integer :: i, j, k, ii, jj, kk
   real    :: capx, capy, capz
   real*8  :: rri, rrj, rrk, prf1, prf2, prf3, prf4

   !---------------------------------------------------------------------

!$omp parallel do private(n,n0,ii,jj,kk,rri,rrj,rrk,capx,capy,capz,o1,o2,prf1,prf2,prf3,prf4)
   DO_K: do k=k0,F_nk
      DO_J: do j=j0,jn

         n0 = (k-1)*adx_mlnij + (j-1)*adx_mlni
         do i=i0,in
            n = n0 + i

            rri= F_x(n)
            ii = (rri - adx_x00_8) * adx_ovdx_8
            ii = F_lcx(ii+1) + 1
            if (rri < F_bsx_8(ii)) ii = ii - 1
            F_ii(n) = max(1,min(ii,F_iimax))
            rrj= F_y(n)

            jj = (rrj - adx_y00_8) * adx_ovdy_8
            jj = F_lcy(jj+1) + 1
            if (rrj < F_bsy_8(jj)) jj = jj - 1
            F_jj(n) = max(adx_haloy,min(jj,adx_jjmax))

            rrk= F_z(n)
            kk = (rrk - F_z00_8) * adx_ovdz_8
            kk = F_lcz(kk+1)

            rrk = rrk - F_bsz_8(kk)
            if (rrk < 0.) kk = kk - 1

            capz = rrk * F_diz_8(kk)
            if (rrk < 0.) capz = 1. + capz

            !- We keep F_capz, otherwise we would need rrk  
            F_capz(n) = capz
            F_kk(n) = kk
         enddo

      enddo DO_J
   enddo DO_K
!$omp end parallel do

   !---------------------------------------------------------------------

   return
end subroutine adx_trilin_ijk1

!/@*
subroutine adx_trilin_ijk()
   call stop_mpi(STOP_ERROR,'adx_trilin_ijk','called a stub')
   return
end subroutine adx_trilin_ijk

