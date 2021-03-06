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
subroutine adx_trajsp2 ( F_lon, F_lat, F_x, F_y, F_z, F_u, F_v, &
                         F_cx_8,F_cy_8,F_sx_8,F_sy_8, &
                         F_dt,i0,in,j0,jn,k0,F_ni,F_nj )
   implicit none
#include <arch_specific.hf>
!
   !@objective improves estimates of upwind positions
!
   !@arguments
   real, dimension(*) :: &
        F_lon,         &     !O, upwind longitudes at central time 
        F_lat,         &     !I/O, upwind lat at central time 
        F_x, F_y, F_z, &     !O, upwind cartesian positions at central time
        F_u, F_v             !I, real wind components at upwind pos
   real    :: F_dt           !I, timestep lenght
   integer :: i0,in,j0,jn,k0 !I, scope of operator
   integer :: F_ni,F_nj
   real*8, dimension(F_ni) :: F_cx_8,F_sx_8
   real*8, dimension(F_nj) :: F_cy_8,F_sy_8
!
   !@author  alain patoine
   !@revisions
   ! v3_00 - Desgagne & Lee    - Lam configuration
   ! v3_10 - Corbeil & Desgagne & Lee - AIXport+Opti+OpenMP
!*@/

#include "adx_dims.cdk"

   integer :: vnij, i,j,k, n
   real*8 :: pdsa, pdca, pdcai, pdso, pdco, pdx, pdy, pdz
   real*8 :: pdux, pduy, pduz, pdsinal, pdcosal
   real*8,dimension(i0:in,j0:jn) :: xcos, ycos, xsin, ysin, yrec
   real*8,dimension(i0:in,j0:jn) :: xasin, yasin, xatan, yatan, zatan

   !---------------------------------------------------------------------

   call msg(MSG_DEBUG,'adx_trajsp')
   vnij = (in-i0+1)*(jn-j0+1)

!$omp parallel do private(ysin,ycos,yrec,xasin,xatan,yatan, &
!$omp zatan,yasin,xsin,xcos, n,pdx,pdy,pdz,pdsa,pdca, &
!$omp pdcai,pdso,pdco,pdux,pduy,pduz,pdsinal,pdcosal)
   do k=k0,adx_lnk
      do j=j0,jn
         do i=i0,in
            n = (k-1)*adx_mlnij + ((j-1)*adx_mlni) + i
            xcos(i,j) = F_lat(n)
            xsin(i,j) = sqrt(F_u(n)**2 + F_v(n)**2) * F_dt
         end do
      end do
      call vsin(ysin, xsin, vnij)
      call vcos(ycos, xcos, vnij)
      call vrec(yrec, ycos, vnij)

      do j=j0,jn
         do i=i0,in
            n = (k-1)*adx_mlnij + (j-1)*adx_mlni + i

            ! cartesian coordinates of grid points

            pdx = F_cx_8(adx_trj_i_off+i)
            pdy = F_sx_8(adx_trj_i_off+i)
            pdz = F_sy_8(j)

            ! if very small wind set upwind point to grid point

            if (abs(F_u(n))+abs(F_v(n)) < 1.e-10) go to 99

            pdx = pdx * F_cy_8(j)
            pdy = pdy * F_cy_8(j)

            ! sin and cosin of first guess of upwind positions

            pdsa  = F_z(n)
            pdca  = ycos(i,j)
            pdcai = yrec(i,j)
            pdso  = F_y(n) * pdcai
            pdco  = F_x(n) * pdcai

            ! wind components in cartesian coordinate at upwind positions

            pdux = - F_u(n) * pdso - F_v(n) * pdco * pdsa
            pduy =   F_u(n) * pdco - F_v(n) * pdso * pdsa
            pduz =   F_v(n) * pdca

            pdsinal = pdx * pdux + pdy * pduy + pdz * pduz
            pdux = pdux - pdx * pdsinal
            pduy = pduy - pdy * pdsinal
            pduz = pduz - pdz * pdsinal
            pdcosal = sqrt((1.+ysin(i,j)) * (1.-ysin(i,j)))
            pdsinal = ysin(i,j) / &
                 sqrt(pdux * pdux + pduy * pduy + pduz * pduz)

            F_x(n) = pdcosal * pdx - pdsinal * pdux
            F_y(n) = pdcosal * pdy - pdsinal * pduy
            F_z(n) = pdcosal * pdz - pdsinal * pduz
99          F_z(n) = min(1.D0,max(1.D0*F_z(n),-1.D0))

            xasin(i,j) = F_z(n)
            xatan(i,j) = F_x(n)
            yatan(i,j) = F_y(n)

         enddo
      enddo

      call vasin(yasin, xasin, vnij)
      call vatan2(zatan, yatan, xatan, vnij)

      do j=j0,jn
         do i=i0,in
            n = (k-1)*adx_mlnij + (j-1)*adx_mlni + i
            F_lat(n) = yasin(i,j)
            F_lon(n) = zatan(i,j) 
            if (F_lon(n) < 0.) F_lon(n) = F_lon(n) + CONST_2PI_8
         end do
      end do
   enddo
!$omp end parallel do

   call msg(MSG_DEBUG,'adx_trajsp [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_trajsp2
