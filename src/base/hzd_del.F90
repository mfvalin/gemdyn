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

!**s/r hzd_del2 - horizontal diffusion problem
!
      subroutine hzd_del2  (F_sol, F_rhs_8, F_opsxp0_8, F_opsyp0_8, &
                            F_aix_8,F_bix_8,F_cix_8,F_dix_8, &
                            F_aiy_8,F_biy_8,F_ciy_8,F_g1_8,F_g2_8, &
                            Minx,Maxx,Miny,Maxy,Nk, Gni,Gnj, lnjs_nh,  &
                            nk12s, nk12, ni22s, ni22, fnjb)
      implicit none
#include <arch_specific.hf>

      integer Minx,Maxx,Miny,Maxy, Nk, Gni, Gnj, lnjs_nh, &
              nk12s, nk12, ni22s, ni22, fnjb

      real   F_sol(Minx:Maxx,Miny:Maxy,Nk)
      real*8 F_rhs_8,F_opsxp0_8(*),F_opsyp0_8(*), &
             F_aix_8(lnjs_nh,Gni),F_bix_8(lnjs_nh,Gni), &
             F_cix_8(lnjs_nh,Gni),F_dix_8(lnjs_nh,Gni), &
             F_aiy_8(ni22s,Gnj),F_biy_8(ni22s,Gnj),F_ciy_8(ni22s,Gnj), &
             F_g1_8(Miny:Maxy,nk12s,*),F_g2_8(nk12s,ni22s,*)

!author    
!     J.P. Toviessi / Jean Cote
!
!revision
! v2_00 - Desgagne M.       - initial MPI version
! v2_11 - Desgagne M.       - remove vertical modulation
! v3_10 - Corbeil & Desgagne & Lee - AIXport+Opti+OpenMP
! v3_11 - Corbeil L.        - new RPNCOMM transpose
!
!arguments
!  Name        I/O                 Description
!----------------------------------------------------------------
!  F_sol       I/O           result
!  F_rhs_8      I            r.h.s. of horizontal diffusion equation
!  
!----------------------------------------------------------------

#include "glb_ld.cdk"
#include "ptopo.cdk"

      integer i, j, k, cnt,k0,kn,k1,klon,ktotal
      real*8 g1(nk12*l_nj,Gni), ax(nk12*l_nj,Gni), cx(nk12*l_nj,Gni), &
             g2(nk12*ni22,Gnj), ay(nk12*ni22,Gnj), cy(nk12*ni22,Gnj)

!     __________________________________________________________________
!
!
      call rpn_comm_transpose48 ( F_sol , l_minx,l_maxx, Gni,1, (maxy-miny+1), &
                                (maxy-miny+1), 1, nk12s, Nk  , F_g1_8,  1 &
                                ,1.0d0,0.d0)
!$omp parallel private(k0,kn,k1,cnt,i,j,k) shared(g1,g2,ax,ay,cx,cy,ktotal,klon)

!$omp do
      do i = 1, Gni-1
         cnt = 0
         do j = 1, l_nj
         do k = 1, nk12
            cnt = cnt + 1
            g1(cnt,i) = F_bix_8(j,i)*F_opsxp0_8(i)*F_g1_8(j,k,i)
            ax(cnt,i) = F_aix_8(j,i)
            cx(cnt,i) = F_cix_8(j,i)
         enddo
         enddo 
      enddo
!$omp enddo
      cnt = 0
!$omp do
      do k = 1, nk12
      do j = 1, l_nj
         cnt = k + (j-1)*nk12
         g1(cnt,Gni) = F_opsxp0_8(Gni)*F_g1_8(j,k,Gni)
      enddo
      enddo 
!$omp enddo
      
!
      ktotal=l_nj*nk12
      klon = (ktotal+Ptopo_npeOpenMP)/Ptopo_npeOpenMP
!$omp do
      do k1=1,Ptopo_npeOpenMP
         k0=1+klon*(k1-1)
         kn=min(ktotal,klon*k1)
         do i = 2, Gni-1
         do k = k0, kn
            g1(k,i) = g1(k,i) - ax(k,i)*g1(k,i-1)
         end do
         end do
         do i = Gni-2, 1, -1
         do k = k0, kn
            g1(k,i) = g1(k,i) - cx(k,i)*g1(k,i+1)
         end do
         end do
      end do
!$omp enddo
!
      cnt = 0
!$omp do
      do k = 1, nk12
!VDIR NOVECTOR
      do j = 1, l_nj
         cnt = k + (j-1)*nk12
         F_g1_8(j,k,Gni) =   F_bix_8(j,Gni)*g1(cnt,Gni  ) &
                           + F_cix_8(j,Gni)*g1(cnt,1    ) &
                           + F_aix_8(j,1  )*g1(cnt,Gni-1)
      enddo
      enddo
!$omp enddo
!$omp do
      do i = 1, Gni - 1
         do k = 1, nk12
         do j = 1, l_nj
            cnt = k + (j-1)*nk12
            F_g1_8(j,k,i) = g1(cnt,i) + F_dix_8(j,i)*F_g1_8(j,k,Gni)
         enddo
         enddo
      enddo
!$omp enddo
!
!$omp single
      call rpn_comm_transpose ( F_g1_8 , l_miny,l_maxy, Gnj, nk12s, &
                                1, ni22s, Gni, F_g2_8,  2, 2 )
!$omp end single
!
! ___ Calcul le long de Y
!
      cnt = 0

!$omp do
      do j = 1, fnjb
         do k = 1, nk12
         do i = 1, ni22
            cnt = k + (i-1)*nk12
            g2 (cnt,j) = F_biy_8(i,j)*F_opsyp0_8(j)*F_g2_8(k,i,j)
            ay (cnt,j) = F_aiy_8(i,j)
            cy (cnt,j) = F_ciy_8(i,j)
         enddo
         enddo
      enddo
!$omp enddo
!
      ktotal = ni22*nk12

      klon = (ktotal+Ptopo_npeOpenMP)/Ptopo_npeOpenMP

!$omp do
      do k1=1,Ptopo_npeOpenMP
         k0=1+klon*(k1-1)
         kn=min(ktotal,klon*k1)
         do j = 2, fnjb
         do k = k0, kn
            g2 (k,j) = g2(k,j) - ay(k,j)*g2(k,j-1)
         end do
         end do
         do j = fnjb-1, 1, -1
         do k = k0,kn
            g2 (k,j) = g2(k,j) - cy(k,j)*g2(k,j+1)
         end do
         end do
      enddo
!$omp enddo
!
!$omp do
      do j = 1, fnjb
         cnt = 0
         do i = 1, ni22
         do k = 1, nk12
            cnt = cnt + 1
            F_g2_8(k,i,j)= g2(cnt,j)
         end do
      enddo
      enddo
!$omp enddo
!$omp end parallel
!
      call rpn_comm_transpose ( F_g1_8 , Miny, Maxy, Gnj, nk12s, &
                                1, ni22s, Gni, F_g2_8, -2, 2 )
!
      call rpn_comm_transpose48 ( F_sol , Minx, Maxx, Gni,1, (maxy-miny+1), &
                                (maxy-miny+1), 1, nk12s, Nk  , F_g1_8, -1 &
                                ,1.0d0,0.d0)
!     __________________________________________________________________
!
      return
      end
