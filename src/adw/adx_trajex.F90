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
subroutine adx_trajex2 (F_xto,  F_yto,  F_xcto, F_ycto, &
                        F_zcto, F_xctm, F_yctm, F_zctm,i0,in,j0,jn,k0)
   implicit none
#include <arch_specific.hf>
!
   !@objective compute positions at origin (o) by extrapolation using positions at mid-trajectory (m)
!
   !@arguments
   real, dimension(*) :: &
        F_xto, F_yto, &          !O, upstream positions at origin
        F_xcto, F_ycto, F_zcto,& !O, upstream cartesian positions at origin 
        F_xctm, F_yctm, F_zctm   !I, upstream cartesian positions at mid-traj
   integer :: i0,in,j0,jn,k0     !I, scope of operator
!
   !@author  alain patoine
   !@revisions
   ! v3_00 - Desgagne & Lee    - Lam configuration
   ! v3_10 - Corbeil & Desgagne & Lee - AIXport+Opti+OpenMP
!*@/

#include "adx_dims.cdk"
#include "adx_grid.cdk"

   integer :: i,j,k, n, vnij
   real*8 :: prx, pry, prz, prdot2
   real*8,dimension(i0:in,j0:jn) :: xasin, yasin, xatan, yatan, zatan

   !---------------------------------------------------------------------

   call msg(MSG_DEBUG,'adx_trajex')
   vnij = (in-i0+1)*(jn-j0+1)

!$omp parallel private(xasin,yasin,xatan,yatan,zatan,n,prx,pry,prz,prdot2)
!$omp do
   do k=k0,adx_lnk
      do j=j0,jn
         do i=i0,in

            n = (k-1)*adx_mlnij+((j-1)*adx_mlni) + i
            pry = dble(adx_cy_8(j))
            prx = dble(adx_cx_8(adx_trj_i_off+i)) * pry
            pry = dble(adx_sx_8(adx_trj_i_off+i)) * pry
            prz = dble(adx_sy_8(j))

            prdot2 = 2.0 * ( prx * dble(F_xctm(n)) + &
                 pry * dble(F_yctm(n)) + &
                 prz * dble(F_zctm(n)) )

            F_xcto(n) = prdot2 * dble(F_xctm(n)) - prx
            F_ycto(n) = prdot2 * dble(F_yctm(n)) - pry
            F_zcto(n) = prdot2 * dble(F_zctm(n)) - prz

            xatan(i,j) = F_xcto(n)
            yatan(i,j) = F_ycto(n)
            xasin(i,j) = max(-1.,min(1.,F_zcto(n)))

         enddo
      enddo

      call vatan2(zatan, yatan, xatan, vnij)
      call vasin(yasin, xasin, vnij)

      do j=j0,jn
         do i=i0,in
            n = (k-1)*adx_mlnij+((j-1)*adx_mlni) + i
            F_xto(n) = zatan(i,j)
            F_yto(n) = yasin(i,j)
            if (F_xto(n) < 0.) F_xto(n) = F_xto(n) + CONST_2PI_8
         enddo
      enddo
   enddo
!$omp enddo
!$omp end parallel

   call msg(MSG_DEBUG,'adx_trajex [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_trajex2

!========================================================================
!=== stubs ==============================================================
!========================================================================

subroutine adx_trajex1()
   call stop_mpi(STOP_ERROR,'adx_pos_lam2','called a stub')
   return
end subroutine adx_trajex1

