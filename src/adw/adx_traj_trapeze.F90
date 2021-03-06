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
#include "constants.h"
#include "stop_mpi.h"
!/@*
subroutine adx_traj_trapeze ( F_lon, F_lat, F_x, F_y, F_z, &
                              F_ud, F_vd, F_ua, F_va, &
                              F_dth,i0,in,j0,jn,k0 )
   implicit none
#include <arch_specific.hf>
!
   !@objective improves estimates of upwind positions (trapezoidal method)
!
   !@arguments
   real, dimension(*) ::   &
        F_lon,             & !O,   upwind longitudes
        F_lat,             & !O,   upwind latitudes
        F_x, F_y, F_z,     & !I/O, upwind cartesian positions
        F_ud,F_vd,F_ua,F_va  !I,   wind components at departure and arrival
   real    :: F_dth          !I,   half-timestep lenght
   integer :: i0,in,j0,jn,k0 !I,   scope of operators
!
   !@author  claude girard
!*@/

#include "adx_dims.cdk"
#include "adx_grid.cdk"

   integer :: vnij, i,j,k, n

   real*8,dimension(i0:in,j0:jn) :: alfa, sinalfa, beta, sinbeta
   real*8,dimension(i0:in,j0:jn) :: pdzD, pdxD, pdyD, latD, lonD
   real*8,dimension(i0:in,j0:jn) :: pduxD, pduyD, pduzD

   real*8 :: pdsxA, pdcxA, pdsyA, pdcyA, pduxA, pduyA, pduzA
   real*8 :: pdxA, pdyA, pdzA, pdsinA, pdcosA
   real*8 :: pdsxD, pdcxD, pdsyD, pdcyD, pdcyDi, pdsinD, pdsecD

   !---------------------------------------------------------------------

   call msg(MSG_DEBUG,'adx_traj_trapeze')
   vnij = (in-i0+1)*(jn-j0+1)

!$omp parallel do private(n, &
!$omp alfa,sinalfa,beta,sinbeta, &
!$omp pdzD,pdxD,pdyD,latD,lonD, &
!$omp pduxD,pduyD,pduzD, &
!$omp pdsxA,pdcxA,pdsyA,pdcyA,pduxA,pduyA,pduzA, &
!$omp pdxA,pdyA,pdzA,pdsinA,pdcosA, &
!$omp pdsxD,pdcxD,pdsyD,pdcyD,pdcyDi,pdsinD,pdsecD)

   do k=k0,adx_lnk

      do j=j0,jn
         do i=i0,in
            n = (k-1)*adx_mlnij + ((j-1)*adx_mlni) + i

            ! sin and cosin of previous upwind positions

            pdsyD = F_z(n)
            pdcyD = sqrt((1.d0+pdsyD)*(1.d0-pdsyD))

            if (pdcyD/=0.) then !TEMPORAIRE (PROBLEM otherwise at 360x180)   

            pdcyDi= 1.d0 / pdcyD
            pdsxD = F_y(n) * pdcyDi
            pdcxD = F_x(n) * pdcyDi

            ! wind in cartesian coordinates at previous Departure positions

            pduxD(i,j) = - F_ud(n) * pdsxD - F_vd(n) * pdcxD * pdsyD
            pduyD(i,j) =   F_ud(n) * pdcxD - F_vd(n) * pdsxD * pdsyD
            pduzD(i,j) =   F_vd(n) * pdcyD

            ! angular displacements

            alfa(i,j) = sqrt(F_ua(n)**2 + F_va(n)**2) * F_dth
            beta(i,j) = sqrt( pduxD(i,j)*pduxD(i,j) + pduyD(i,j)*pduyD(i,j) & 
                                                    + pduzD(i,j)*pduzD(i,j) ) * F_dth
            else

            beta(i,j) = 0. 

            endif

         end do
      end do

      call vsin(sinalfa, alfa, vnij)
      call vsin(sinbeta, beta, vnij)

      do j=j0,jn
         do i=i0,in
            n = (k-1)*adx_mlnij + (j-1)*adx_mlni + i

            ! if very small wind set upwind point to grid point
            if (beta(i,j) < 1.e-10) go to 99

            ! cartesian coordinates of grid points

            pdcxA = adx_cx_8(adx_trj_i_off+i)
            pdsxA = adx_sx_8(adx_trj_i_off+i)
            pdsyA = adx_sy_8(j)
            pdcyA = adx_cy_8(j)

            pdxA = pdcxA * pdcyA
            pdyA = pdsxA * pdcyA
            pdzA = pdsyA

            ! wind in cartesian coordinates at Arrival positions (grid points)

            pduxA = - F_ua(n) * pdsxA - F_va(n) * pdcxA * pdsyA
            pduyA =   F_ua(n) * pdcxA - F_va(n) * pdsxA * pdsyA
            pduzA =   F_va(n) * pdcyA

            ! calculation of new Departure positions

            pdsinA = F_dth * sinalfa(i,j) / max(alfa(i,j),1.d-10)
            pdsinD = F_dth * sinbeta(i,j) / beta(i,j)

            pdcosA =      sqrt((1.+sinalfa(i,j)) * (1.-sinalfa(i,j)))
            pdsecD = 1.d0/sqrt((1.+sinbeta(i,j)) * (1.-sinbeta(i,j)))

            F_x(n) = ( pdxA * pdcosA - pdsinA * pduxA - pdsinD * pduxD(i,j) ) * pdsecD
            F_y(n) = ( pdyA * pdcosA - pdsinA * pduyA - pdsinD * pduyD(i,j) ) * pdsecD
            F_z(n) = ( pdzA * pdcosA - pdsinA * pduzA - pdsinD * pduzD(i,j) ) * pdsecD
99          F_z(n) = min(1.D0,max(1.D0*F_z(n),-1.D0))

            pdxD(i,j) = F_x(n)
            pdyD(i,j) = F_y(n)
            pdzD(i,j) = F_z(n)

         enddo
      enddo

      ! new Departure positions in spherical coordinates (lat,lon)

      call vasin (latD, pdzD, vnij)
      call vatan2(lonD, pdyD, pdxD, vnij)

      do j=j0,jn
         do i=i0,in
            n = (k-1)*adx_mlnij + (j-1)*adx_mlni + i
            F_lat(n) = latD(i,j)
            F_lon(n) = lonD(i,j) 
  !!!!!!!! CARTESIAN DISPLACEMENTS: replace above 2 by !!!!!!!!!
  !!!                             + modifs in prep           !!!
  !!!       F_lon(n) = Adx_xx_8(i)-(F_ud(n)+F_ua(n))*F_dth   !!!
  !!!       F_lat(n) = Adx_yy_8(j)-(F_vd(n)+F_va(n))*F_dth   !!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            if (F_lon(n) < 0.) F_lon(n) = F_lon(n) + CONST_2PI_8
         end do
      end do
   enddo
!$omp end parallel do

   call msg(MSG_DEBUG,'adx_traj_trapeze [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_traj_trapeze
