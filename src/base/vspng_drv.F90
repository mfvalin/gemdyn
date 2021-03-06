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

!**s/r vspng_drv - Main driver for top sponge layer

      subroutine vspng_drv3 ( F_u, F_v, F_zd, F_w, F_t, &
                               Minx,Maxx,Miny,Maxy, Nk)
      implicit none
#include <arch_specific.hf>

      integer Minx,Maxx,Miny,Maxy, Nk
      real F_u  (Minx:Maxx,Miny:Maxy,Nk), F_v (Minx:Maxx,Miny:Maxy,Nk), &
           F_zd (Minx:Maxx,Miny:Maxy,Nk), F_w (Minx:Maxx,Miny:Maxy,Nk), &
           F_t  (Minx:Maxx,Miny:Maxy,Nk)

!author
!     Michel Desgagne  - October 2000
!
!revision
! v2_11 - Desgagne M.       - initial version 
! v2_21 - Desgagne M.       - control for sponge on momentum only
! v2_21                       Vspng_nk levels + sponge on top level only
! v2_21                       on all other variables
! v2_31 - Tanguay M.        - restaure link between F_pip and F_ip at 
!                             top; remove top_only_L and stkmemw
! v3_01 - Desgagne & Lee    - introduce Vspng_rwnd_L
! v3_10 - Corbeil & Desgagne & Lee - AIXport+Opti+OpenMP
! v3_11 - Toviessi J. P.    - variable higher order diffusion operator
! v3_30 - Spacek L.         - Added Vspng_zmean_L. If .true. the zonal
!                             mean of u component is subtracted before
!                             the diffusion and added back after it
! v4    - Gravel-Girard-Plante - staggered version
! v4_02 - Girard-Plante     - Diffuse only real winds, zdot and first temp. level.
! v4_03 - Tanguay M.        - Bugfix for calculation of cy_8 for vert wind
! v4_04 - Plante A.         - Diffuse zdot like in hzd, w only if non hydro
! v4_05 - Plante A.         - Diffuse w.
! v4_10 - Tanguay M.        - Replace tmean by tmean_8 as in GEM333
! v4_50 - Qaddouri A.       - Call Sponge for Yin-Yang   
!  
!object
!     The diffusion coefficients are (Vspng_coef*Cstv_dt_8) for the
!     momentum only.
!
#include "glb_ld.cdk"
#include "dcst.cdk"
#include "cstv.cdk"
#include "schm.cdk"
#include "geomg.cdk"
#include "trp.cdk"
#include "vspng.cdk"
#include "hzd.cdk"
#include "opr.cdk"
#include "grd.cdk"
#include "lun.cdk"

      integer i,j,jj,k,nkspng
      real*8 HALF_8,TWO_8,c_8,invp0t_8
      parameter( HALF_8  = 0.5 )
      parameter(  TWO_8  = 2.0 )
      parameter(invp0t_8 = .00001d0)

      real*8 tmean_8(l_nj,Nk)
      real*8, dimension (trp_12emax*G_ni*Vspng_nk) ::  &
                                                aix_8,bix_8,cix_8,dix_8
      real*8, dimension (trp_22emax*G_nj*Vspng_nk) :: aiy_8,biy_8,ciy_8
      real*8 cy_8(l_nj+1), xp0_8(G_ni), yp0_8(G_nj)
!
!     ---------------------------------------------------------------
!
      if(G_lam)then
         call vspng_drv_lam ( F_u, F_v, F_zd, F_w, F_t, &
                                Minx,Maxx,Miny,Maxy, Nk )
         return
      endif

      do i = 1, G_ni
         xp0_8 (i) = G_xg_8(i+1) - G_xg_8(i)
      end do
      do j = 1, G_nj
         yp0_8 (j) = sin(G_yg_8(j+1))-sin(G_yg_8(j))
      end do
!
!     Horizontal Momentum
!     ~~~~~~~~~~~~~~~~~~~       
!     Substract the mean for the zonal component if wanted
!
      if (Vspng_zmean_L) &
           call vspng_zmean (F_u,F_u,tmean_8,Minx,Maxx,Miny,Maxy,Nk,.true.)
!     
      do j = 1, l_nj+1
         cy_8(j) = G_yg_8(l_j0+j-1)
      end do

      if (Hzd_difva_L) then
         call vspng_abc2( aix_8,bix_8,cix_8,dix_8, &
                          aiy_8,biy_8,ciy_8,cy_8 , &
                          Hzd_xp0_8,Hzd_xp2_8,Opr_opsyp0_8,Hzd_yp2su_8, &
                          Vspng_coef_8, Vspng_njpole, G_ni,G_nj,G_nj,Vspng_nk)
      else
         call vspng_abc2( aix_8,bix_8,cix_8,dix_8, &
                          aiy_8,biy_8,ciy_8,cy_8 , &
                          Hzd_xp0_8,Hzd_xp2_8,Opr_opsyp0_8,Opr_opsyp2_8, &
                          Vspng_coef_8, Vspng_njpole, G_ni,G_nj,G_nj,Vspng_nk)
      endif
!     
      call vspng_del2 ( F_u, xp0_8, Opr_opsyp0_8(G_nj+1)         , &
                        aix_8,bix_8,cix_8,dix_8,aiy_8,biy_8,ciy_8, &
                        l_minx,l_maxx,l_miny,l_maxy,Vspng_nk,trp_12emax,trp_22emax,G_nj)
!     
      do j = 1, l_nj+1
         jj = l_j0+j-1
         cy_8(j) = cos((G_yg_8(jj+1)+G_yg_8(jj)) * HALF_8) **TWO_8
      end do

      call vspng_abc2( aix_8,bix_8,cix_8,dix_8, &
                       aiy_8,biy_8,ciy_8,cy_8 , &
                       Opr_opsxp0_8,Opr_opsxp2_8,Hzd_yp0_8,Hzd_yp2_8, &
                       Vspng_coef_8, Vspng_njpole, G_ni,G_nj,G_njv,Vspng_nk)
!     
      call vspng_del2 ( F_v, Opr_opsxp0_8(G_ni+1), yp0_8         , &
                        aix_8,bix_8,cix_8,dix_8,aiy_8,biy_8,ciy_8, &
                        l_minx,l_maxx,l_miny,l_maxy,Vspng_nk,trp_12emax,trp_22emax,G_njv)
!     
!     Add back the mean for the zonal component
!     
      if (Vspng_zmean_L) &
           call vspng_zmean (F_u,F_u,tmean_8,Minx,Maxx,Miny,Maxy,Nk,.false.)
!     
      do j = 1, l_nj+1
         cy_8(j) = G_yg_8(l_j0+j-1)
      end do
!     
      if (Hzd_difva_L) then
         call vspng_abc2(aix_8,bix_8,cix_8,dix_8, &
                         aiy_8,biy_8,ciy_8,cy_8 , &
                         Opr_opsxp0_8,Opr_opsxp2_8,Opr_opsyp0_8,Hzd_yp2su_8, &
                         Vspng_coef_8, Vspng_njpole, G_ni,G_nj,G_nj,Vspng_nk)
      else
         call vspng_abc2(aix_8,bix_8,cix_8,dix_8, &
                         aiy_8,biy_8,ciy_8,cy_8 , &
                         Opr_opsxp0_8,Opr_opsxp2_8,Opr_opsyp0_8,Opr_opsyp2_8,&
                         Vspng_coef_8, Vspng_njpole, G_ni,G_nj,G_nj,Vspng_nk)
      endif
!
!     Vertical motion
!     ~~~~~~~~~~~~~~~
!********not physical, done nevertheless*******
      call vspng_del2 (F_zd, Opr_opsxp0_8(G_ni+1),Opr_opsyp0_8(G_nj+1), &
                       aix_8,bix_8,cix_8,dix_8,aiy_8,biy_8,ciy_8      , &
                       l_minx,l_maxx,l_miny,l_maxy,Vspng_nk,trp_12emax,trp_22emax,G_nj)
      
!     Vertical wind
!     ~~~~~~~~~~~~~
      call vspng_del2 (F_w, Opr_opsxp0_8(G_ni+1),Opr_opsyp0_8(G_nj+1), &
                       aix_8,bix_8,cix_8,dix_8,aiy_8,biy_8,ciy_8     , &
                       l_minx,l_maxx,l_miny,l_maxy,Vspng_nk,trp_12emax,trp_22emax,G_nj)
!     
!     Temperature
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if (Hzd_difva_L) then
         call vspng_abc2(aix_8,bix_8,cix_8,dix_8, &
                         aiy_8,biy_8,ciy_8,cy_8 , &
                         Opr_opsxp0_8,Opr_opsxp2_8,Opr_opsyp0_8,Hzd_yp2su_8, &
                         Vspng_coef_8, Vspng_njpole, G_ni,G_nj,G_nj,Vspng_nk)
      else
         call vspng_abc2(aix_8,bix_8,cix_8,dix_8, &
                         aiy_8,biy_8,ciy_8,cy_8 , &
                         Opr_opsxp0_8,Opr_opsxp2_8,Opr_opsyp0_8,Opr_opsyp2_8,&
                         Vspng_coef_8, Vspng_njpole, G_ni,G_nj,G_nj,Vspng_nk)
      endif
      call vspng_del2 (F_t, Opr_opsxp0_8(G_ni+1),Opr_opsyp0_8(G_nj+1), &
                       aix_8,bix_8,cix_8,dix_8,aiy_8,biy_8,ciy_8     , &
                       l_minx,l_maxx,l_miny,l_maxy,Vspng_nk,trp_12emax,trp_22emax,G_nj)
!
!     ---------------------------------------------------------------
!
      return
      end
