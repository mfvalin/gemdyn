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
!**s/r wil_case6
!

!
      subroutine wil_case6(gz_temp,lni,lnj,nk)
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
!   To setup williamson case 6 ROSSBY-HAURWITZ WAVE for Yin-Yang/Global model
!   Documentation: Nonlinear shallow-water equations on the Yin Yang grid. 
!   Quart.J.Roy.Meteor.Soc., 137, 656, 810-818.
!	
!arguments
!	none
!

#include "glb_ld.cdk"
#include "grd.cdk"
#include "dcst.cdk"
#include "schm.cdk"
#include "ptopo.cdk"

!
      integer i,j,k,R_case
      REAL*8  PHI0,DLON,K_Case,OMG
      real    PICLL(G_ni,G_nj),gzloc(l_minx:l_maxx,l_miny:l_maxy)
      real    UICLL(G_ni,G_nj),uloc(l_minx:l_maxx,l_miny:l_maxy)
      real    VICLL(G_ni,G_nj),vloc(l_minx:l_maxx,l_miny:l_maxy)
      real    EICLL(G_ni,G_nj)
      real    DICLL(G_ni,G_nj)
      real*8  phia(G_nj),phib(G_nj),phic(G_nj)
      REAL*8  RLON,RLAT,TIME, SINT,COST,PHIAY,PHIBY,PHICY
      real*8  s(2,2),x_a,y_a

!*
!     ---------------------------------------------------------------
!
!     ROSSBY-HAURWITZ WAVE AS USED BY PHILIPS IN
!     MONTHLY WEATHER REVIEW, 1959
!     
      time=0.0
      R_Case = 4
      K_Case = 7.848E-6
      OMG = 7.848E-6
      PHI0 = 8000.0
!     COMPUTE LATITUDE-DEPENDENT FACTORS FOR GEOPOTENTIAL
!     ---------------------------------------------------
!     PHIA(G_nj),PHIB(G_nj) AND PHIC(G_nj)
!
      if (Ptopo_couleur.eq.0) then !Yin
!
!        LONGITUDINAL CHANGE OF FEATURE
!        ------------------------------
         DLON = (R_Case*(3+R_Case)*OMG - 2.0*Dcst_omega_8)/  &
                       ((1+R_Case)*(2+R_Case))*TIME
!
         DO 151 J=1,G_nj
            RLAT = G_yg_8(J)
            COST = COS(RLAT)
            PHIA(J) = 0.5*OMG*(2.0*Dcst_omega_8+OMG)*COST*COST + &
                      0.25*K_Case*K_Case*COST**(2*R_Case) *      &
                      ((R_Case+1)*COST*COST+(2*R_Case*R_Case-R_Case-2) -  &
                      2.0*R_Case*R_Case/(COST*COST))
            PHIB(J) = (2.0*(Dcst_omega_8+OMG)*K_Case)/((R_Case+1)*(R_Case+2))* &
                      COST**R_Case* &
                      ((R_Case*R_Case+2*R_Case+2)-(R_Case+1)**2*COST*COST)
            PHIC(J) = 0.25*K_Case*K_Case*COST**(2*R_Case)* &
                      ((R_Case+1)*COST*COST-(R_Case+2))
            DO 150 I=1,G_ni
               RLON = G_xg_8(I)
               SINT = SIN(RLAT)
               COST = COS(RLAT)
               DICLL(I,J) = 0.0
               EICLL(I,J) = 2.0*(OMG+Dcst_omega_8)*SINT - &
                            (1+R_Case)*(2+R_Case)*SINT* &
                            K_Case*COST**R_Case*COS(R_Case*(RLON-DLON))
               UICLL(I,J) = Dcst_rayt_8*OMG*COST + &
                            Dcst_rayt_8*K_Case*COST**(R_Case-1)*  &
                            (R_Case*SINT*SINT-COST*COST)*COS(R_Case*(RLON-DLON))
               VICLL(I,J) = -Dcst_rayt_8*K_Case*R_Case*COST**(R_Case-1)*SINT &
                            * SIN(R_Case*(RLON-DLON))
               PICLL(I,J) = PHI0 + (Dcst_rayt_8*Dcst_rayt_8*(PHIA(J)+PHIB(J) &
                            * COS(R_Case*(RLON-DLON))+PHIC(J)   &
                            * COS(2*R_Case*(RLON-DLON))))/Dcst_grav_8
  150       CONTINUE
  151    CONTINUE
      else !        YAN (Yang)
!        LONGITUDINAL CHANGE OF FEATURE
!        ------------------------------
         DLON = (R_Case*(3+R_Case)*OMG - 2.0*Dcst_omega_8)/ &
                ((1+R_Case)*(2+R_Case))*TIME
!
         DO 153 J=1,G_nj

            DO 152 I=1,G_ni
               x_a = G_xg_8(I)-acos(-1.D0)
               y_a = G_yg_8(J)
               call smat(s,RLON,RLAT,x_a,y_a)
               RLON = RLON+acos(-1.D0)
               COST = COS(RLAT)
              
               PHIAY = 0.5*OMG*(2.0*Dcst_omega_8+OMG)*COST*COST +       &
                      0.25*K_Case*K_Case*COST**(2*R_Case) *             &
                      ((R_Case+1)*COST*COST+(2*R_Case*R_Case-R_Case-2) -&
                      2.0*R_Case*R_Case/(COST*COST))
               PHIBY = (2.0*(Dcst_omega_8+OMG)*K_Case)/      &
                       ((R_Case+1)*(R_Case+2))*COST**R_Case* &
                       ((R_Case*R_Case+2*R_Case+2)-(R_Case+1)**2*COST*COST)
               PHICY = 0.25*K_Case*K_Case*COST**(2*R_Case)* &
                      ((R_Case+1)*COST*COST-(R_Case+2))

               SINT = SIN(RLAT)
               DICLL(I,J) = 0.0
               EICLL(I,J) = 2.0*(OMG+Dcst_omega_8)*SINT - &
                            (1+R_Case)*(2+R_Case)*SINT*   &
                            K_Case*COST**R_Case*COS(R_Case*(RLON-DLON))
               UICLL(I,J) = Dcst_rayt_8*OMG*COST +                &
                            Dcst_rayt_8*K_Case*COST**(R_Case-1)*  &
                            (R_Case*SINT*SINT-COST*COST)*COS(R_Case*(RLON-DLON))
               VICLL(I,J) = -Dcst_rayt_8*K_Case*R_Case*COST**(R_Case-1)*SINT &
                            * SIN(R_Case*(RLON-DLON))
               PICLL(I,J) = PHI0 + (Dcst_rayt_8*Dcst_rayt_8*(PHIAY+PHIBY &
                            * COS(R_Case*(RLON-DLON))+PHICY              &
                            * COS(2*R_Case*(RLON-DLON))))/Dcst_grav_8
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
