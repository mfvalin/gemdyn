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

!**s/r vspng_set - Vertical sponge setup

      subroutine vspng_set
      implicit none
#include <arch_specific.hf>

#include "glb_ld.cdk"
#include "cstv.cdk"
#include "dcst.cdk"
#include "lun.cdk"
#include "vspng.cdk"
#include "grd.cdk"
#include "ver.cdk"
#include "ptopo.cdk"

      integer, external :: vspng_imp_transpose2
      integer i,j,k,istat,err
      real*8, dimension(:), allocatable :: weigh
      real*8 pis2_8,pbot_8,delp_8,c_8,nutop
!
!     ---------------------------------------------------------------
!
      Vspng_niter = 0
      if (Vspng_coeftop.lt.0.) Vspng_nk = 0
      if (Vspng_nk.le.0) return

      if (Lun_out.gt.0) write (Lun_out,1001)

      istat = 0
      if ( Vspng_zmean_L .and. (G_lam.or.Grd_roule) ) then
         if (Lun_out.gt.0) write (Lun_out,9001)
         istat = -1
      endif

      call gem_error(istat,'vspng_set','')

      Vspng_nk = min(G_nk,Vspng_nk)
      pis2_8   = Dcst_pi_8/2.0d0

      pbot_8 = exp(Ver_z_8%m(Vspng_nk+1))
      delp_8 = pbot_8 - exp(Ver_z_8%m(1))

      allocate ( weigh(Vspng_nk), Vspng_coef_8(Vspng_nk) )
      do k=1,Vspng_nk
         weigh(k) = (sin(pis2_8*(pbot_8-exp(Ver_z_8%m(k)))/(delp_8)))**2
      end do

      i=G_ni/2
      j=G_nj/2
      c_8 = min ( G_xg_8(i+1) - G_xg_8(i), G_yg_8(j+1) - G_yg_8(j) )

      nutop = Vspng_coeftop*Cstv_dt_8/(Dcst_rayt_8*c_8)**2
      Vspng_niter = int(8.d0*nutop+0.9999999)

      if (Lun_out.gt.0) then
         write (Lun_out,2002) Vspng_coeftop,Vspng_nk,nutop,Vspng_niter
         write (Lun_out,3001) 
      endif

      nutop = dble(Vspng_coeftop)/max(1.d0,dble(Vspng_niter))

      do k=1,Vspng_nk
         Vspng_coef_8(k) = weigh(k) * nutop
         if (Lun_out.gt.0) write (Lun_out,2005) &
                       Vspng_coef_8(k)      ,&
                       Vspng_coef_8(k)*Cstv_dt_8/(Dcst_rayt_8*c_8)**2,&
                       exp(Ver_z_8%m(k)),k
         Vspng_coef_8(k)= Vspng_coef_8(k) * & 
                          Cstv_dt_8/(Dcst_rayt_8*Dcst_rayt_8)
      end do

      if (.not.G_lam) then
         err= vspng_imp_transpose2 ( Ptopo_npex, Ptopo_npey, .false. )
         call gem_error(err,'VSPNG_IMP_TRANSPOSE',&
                        'ILLEGAL DOMAIN PARTITIONING -- ABORTING')
      endif

 1001 format(/,'INITIALIZATING SPONGE LAYER PROFILE ',  &
               '(S/R VSPNG_SET)',/,51('='))
 2002 format('  SPONGE LAYER PROFILE BASED ON: Vspng_coeftop=',1pe10.2, &
             '  m**2 AND Vspng_nk=',i3/'  Nu_top=',1pe14.6, &
             '  Vspng_niter=',i8)
 2005 format(1pe14.6,1pe14.6,f11.2,i8)
 2007 format('  SPONGE LAYER Vspng_zmean_L =',l2)
 3001 format('     Coef           Nu            Pres      Level')
 9001 format('Vspng_zmean_L works ONLY with GU unrotated grid')
!
!     ---------------------------------------------------------------
!
      return
      end
