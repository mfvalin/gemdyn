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
!**s/r wil_case2
!

!
      subroutine wil_case2(gz_temp,lni,lnj,nk)
      implicit none
#include <arch_specific.hf>
      integer lni,lnj,lniu,lnju,lniv,lnjv,nk
      real    gz_temp(lni,lnj,nk)
!
!author 
!     Abdessamad Qaddouri and Vivian Lee 
!
!revision
!
!object
!     To setup williamson case 2 for Yin-Yang & Global(Yin) model: 
!     STEADY STATE NONLINEAR GEOSTROPHIC FLOW 
!     Documentation: Nonlinear shallow-water equations on the Yin Yang grid. 
!     Quart.J.Roy.Meteor.Soc., 137, 656, 810-818.
!	
!arguments
!	none
!

#include "glb_ld.cdk"
#include "grd.cdk"
#include "dcst.cdk"
#include "schm.cdk"
#include "ptopo.cdk"
#include "wil_williamson.cdk"

!
      integer i,j,k
      REAL*8  PHI0,UBAR,SINA,COSA,ETAAMP,PHIAMP
      real    PICLL(G_ni,G_nj),gzloc(l_minx:l_maxx,l_miny:l_maxy)
      real    UICLL(G_ni,G_nj),uloc(l_minx:l_maxx,l_miny:l_maxy)
      real    VICLL(G_ni,G_nj),vloc(l_minx:l_maxx,l_miny:l_maxy)
      real    EICLL(G_ni,G_nj)
      real    DICLL(G_ni,G_nj)
      REAL*8  RLON,RLAT,TIME, SINT,COST,PHIAY,PHIBY,PHICY
      real*8  s(2,2),x_a,y_a,SINL,COSL

!*
!     ---------------------------------------------------------------
!
!     
      PHI0 = 29400.0d0
      UBAR = (2.0*Dcst_pi_8*Dcst_rayt_8)/(12.0*24.0*3600.0)

      SINA = SIN(Williamson_alpha)
      COSA = COS(Williamson_alpha)
      ETAAMP = 2.0*(UBAR/Dcst_rayt_8 + Dcst_omega_8)
      PHIAMP = Dcst_rayt_8*Dcst_omega_8*UBAR + ((UBAR*UBAR)/2.0)

!
      if (Ptopo_couleur.eq.0) then !Yin
!
!     ------------------------------
!
         DO 151 J=1,G_nj
            RLAT = G_yg_8(J)
            COST = COS(RLAT)
            SINT = SIN(RLAT)
            DO 150 I=1,G_ni
               RLON = G_xg_8(I)
               SINL = SIN(RLON)
               COSL = COS(RLON)

               PICLL(I,J) =(PHI0-PHIAMP*(- COSL*COST*SINA +   &
               SINT*COSA)*(- COSL*COST*SINA +SINT*COSA))/Dcst_grav_8

  150       CONTINUE

  151    CONTINUE
!
      else
!        YAN
!        ------------------------------
!
         DO 153 J=1,G_nj

            DO 152 I=1,G_ni
               x_a = G_xg_8(I)-acos(-1.D0)
               y_a = G_yg_8(J)
               call smat(s,RLON,RLAT,x_a,y_a)
               RLON = RLON+acos(-1.D0)
               SINT = SIN(RLAT)
               COST = COS(RLAT)

               SINL = SIN(RLON)
               COSL = COS(RLON)

              
               PICLL(I,J) =(PHI0-PHIAMP*(- COSL*COST*SINA + &
               SINT*COSA)*(- COSL*COST*SINA +SINT*COSA)) /Dcst_grav_8


  152       CONTINUE
  153    CONTINUE

      endif

      call glbdist (PICLL,G_ni,G_nj,gzloc,l_minx,l_maxx,l_miny,l_maxy, &
                               1,G_halox,G_haloy)
      do k=1,nk
      do j=1,lnj
      do i=1,lni
         gz_temp(i,j,k)=gzloc(i,j)
      enddo
      enddo
      enddo
!
!     ---------------------------------------------------------------
!
      return
      end
