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
!**s/r wil_uvcase1
!

!
      subroutine wil_uvcase1( u_temp,lniu,lnju,v_temp,lniv,lnjv,nk)
      implicit none
#include <arch_specific.hf>
      integer lniu,lnju,lniv,lnjv,nk
      real    u_temp(lniu,lnju,nk), v_temp(lniv,lnjv,nk)
!
!author 
!     Abdessamad Qaddouri & Vivian Lee 
!
!revision
!
!object
!    To setup williamson case 1 for Yin-Yang/Global model : Advection of a Cosine bell
!    Documentation: Nonlinear shallow-water equations on the Yin Yang grid. 
!    Quart.J.Roy.Meteor.Soc., 137, 656, 810-818.
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
      REAL*8  UBAR,SINA,COSA

      real    uloc(l_minx:l_maxx,l_miny:l_maxy),vloc(l_minx:l_maxx,l_miny:l_maxy)
      real    UICLL(G_ni,G_nj),VICLL(G_ni,G_nj)
      real*8  UI_U(G_niu,G_nj),UI_V(G_ni,G_njv)
      real*8  VI_U(G_niu,G_nj),VI_V(G_ni,G_njv)
      REAL*8  RLON,RLAT,TIME, SINT,COST
      real*8  s(2,2),x_a,y_a ,SINL,COSL
      real*8  xgu_8(G_niu),ygv_8(G_njv)

!*
!     ---------------------------------------------------------------
!
!     ROSSBY-HAURWITZ WAVE AS USED BY PHILIPS IN
!     MONTHLY WEATHER REVIEW, 1959
!     
!        Williamson_alpha=0.*(Dcst_pi_8/180.0)
         UBAR = (2.0*Dcst_pi_8*Dcst_rayt_8)/(12.0*24.0*3600.0)
!          UBAR =20.0

         SINA = SIN(Williamson_alpha)
         COSA = COS(Williamson_alpha)


!        U grid
         do i=1,G_niu
            xgu_8(i)=(G_xg_8(i+1)+G_xg_8(i))*.5
         enddo
!        V grid
         do j=1,G_njv
            ygv_8(j)=(G_yg_8(j+1)+G_yg_8(j))*.5
         enddo
!
!        COMPUTE U VECTOR FOR YIN
!        ---------------------------------------------------
         if (Ptopo_couleur.eq.0) then
!
!        LONGITUDINAL CHANGE OF FEATURE
!        ------------------------------
!

         DO 151 J=1,G_nj
            RLAT = G_yg_8(J)
            SINT = SIN(RLAT)
            COST = COS(RLAT)

            DO 150 I=1,G_niu
               RLON = xgu_8(I)
               SINL = SIN(RLON)
               COSL = COS(RLON)
               UICLL(I,J) =UBAR*(COST*COSA + COSL*SINT*SINA)
  150       CONTINUE
  151    CONTINUE

         else

!        COMPUTE U VECTOR FOR YAN
!        ---------------------------------------------------
!
!
         DO 153 J=1,G_nj
               y_a = G_yg_8(J)
            DO 152 I=1,G_niu
               x_a = xgu_8(I)-acos(-1.D0)
               call smat(s,RLON,RLAT,x_a,y_a)
               RLON = RLON+acos(-1.D0)

               SINT = SIN(RLAT)
               COST = COS(RLAT)
               SINL = SIN(RLON)
               COSL = COS(RLON)

               UI_u(I,J) =UBAR*(COST*COSA + COSL*SINT*SINA)
               VI_u(I,J) =  -UBAR*SINL*SINA

               UICLL(I,J) = s(1,1)*UI_u(I,J) + s(1,2)*VI_u(I,J)
!           if ((j.ge.6).and.(j.le.(G_nj-6+1)) ) print*,'uyan',UICLL(i,j)

  152       CONTINUE
  153    CONTINUE

         endif

         call glbdist (UICLL,G_ni,G_nj,uloc,l_minx,l_maxx,l_miny,l_maxy, &
                               1,G_halox,G_haloy)
         do k=1,nk
         do j=1,lnju
         do i=1,lniu
            u_temp(i,j,k)=uloc(i,j)
         enddo
         enddo
         enddo
!-------------------------------------------------------------------------
!
!        COMPUTE V VECTOR FOR YIN
!        ---------------------------------------------------
         if (Ptopo_couleur.eq.0) then
!
!        LONGITUDINAL CHANGE OF FEATURE
!        ------------------------------
!

         DO 161 J=1,G_njv
            RLAT = ygv_8(J)
            SINT = SIN(RLAT)
            COST = COS(RLAT)

            DO 160 I=1,G_ni
               RLON = G_xg_8(I)
               SINL = SIN(RLON)
               COSL = COS(RLON)

               VICLL(I,J) =  -UBAR*SINL*SINA

!             if ((j.ge.6).and.(j.le.(G_njv-6)) ) print*,'v',VICLL(i,j)

  160       CONTINUE
  161    CONTINUE

         else

!        COMPUTE V VECTOR FOR YAN
!        ---------------------------------------------------
!
!
         DO 163 J=1,G_njv

            y_a = ygv_8(J)
            DO 162 I=1,G_ni
               x_a = G_xg_8(I)-acos(-1.D0)
               call smat(s,RLON,RLAT,x_a,y_a)
               RLON = RLON+acos(-1.D0)

               SINT = SIN(RLAT)
               COST = COS(RLAT)
               SINL = SIN(RLON)
               COSL = COS(RLON)

               UI_v(I,J) =UBAR*(COST*COSA + COSL*SINT*SINA)
               VI_v(I,J) =  -UBAR*SINL*SINA

               VICLL(I,J)=s(2,1)*UI_v(I,J) + s(2,2)*VI_v(I,J)
!              if ((j.ge.6).and.(j.le.(G_njv-6+1)) ) &
!                    print*,'vyan',G_xg_8(I),ygv_8(J),VICLL(i,j)
  162       CONTINUE
!         print*,'===================================='
  163    CONTINUE
          
          print*,'G_njv,G_ni,G_niu,G_nj',G_njv,G_ni,G_niu,G_nj

         endif

         call glbdist (VICLL,G_ni,G_nj,vloc,l_minx,l_maxx,l_miny,l_maxy, &
                               1,G_halox,G_haloy)
         do k=1,nk
         do j=1,lnjv
         do i=1,lniv
            v_temp(i,j,k)=vloc(i,j)
         enddo
         enddo
         enddo
!
!     ---------------------------------------------------------------
!
      return
      end
