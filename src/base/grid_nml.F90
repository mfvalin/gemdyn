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

!**s/r grid_nml
!
      integer function grid_nml2 (F_namelistf_S, F_lam)
      implicit none
#include <arch_specific.hf>

      character* (*) F_namelistf_S
      logical F_lam

!author
!     M. Desgagne    - Summer  2006
!
!revision
! v3_30 - Desgagne M.       - initial version
! v3_31 - Lee V.            - added extra CHECK for LAM grid
! v4_04 - Plante            - Remove offline mode
! v4_40 - Qaddouri/Lee      - Add Yin/Yang grid
! v4_60 - Lee V.            - GY grids need only Grd_nj (Y points)
!
!object
!  Default configuration and reading namelist grid

#include "grd.cdk"
#include "hgc.cdk"
#include "lun.cdk"
#include "schm.cdk"

      integer, external ::  fnom, yyg_checkrot

      character*120 dumc
      integer unf,nrec,err
      real*8 epsilon,a_8,b_8,c_8,d_8,xyz1_8(3),xyz2_8(3), delta_8
      real*8 yan_xlat1_8, yan_xlon1_8, yan_xlat2_8, yan_xlon2_8
      parameter (epsilon = 1.0d-5)
!
!-------------------------------------------------------------------
!
      grid_nml2 = -1

      if ((F_namelistf_S.eq.'print').or.(F_namelistf_S.eq.'PRINT')) then
         grid_nml2 = 0
         if (Lun_out.gt.0) write (Lun_out  ,nml=grid) 
         return
      endif

! Defaults values for grid namelist variables

      Grd_typ_S = 'GY'
      Grd_ni    = 0
      Grd_nj    = 0 
      Grd_maxcfl= 1
      Grd_dx    = 0.
      Grd_dy    = 0.
      Grd_iref  = 1
      Grd_jref  = 1
      Grd_latr  = 0.
      Grd_lonr  = 180.
      Grd_overlap=0.0
!Orientation of Global and Yin grid
!xlon1,xlat1 is centre of grid
      Grd_xlon1 = 180.
      Grd_xlat1 = 0.
      Grd_xlon2 = 270.
      Grd_xlat2 = 0.

      if (F_namelistf_S .ne. '') then
         unf = 0
         if (fnom (unf,F_namelistf_S, 'SEQ+OLD', nrec) .ne. 0) then
            if (Lun_out.ge.0) write (Lun_out, 7050) trim( F_namelistf_S )
            goto 9999
         endif
         rewind(unf)
         read (unf, nml=grid, end = 9120, err=9130)
         goto 9000
      endif

 9120 if (Lun_out.ge.0) write (Lun_out, 7060) trim( F_namelistf_S )
      goto 9999
 9130 if (Lun_out.ge.0) write (Lun_out, 7070) trim( F_namelistf_S )
      goto 9999

 9000 call low2up (Grd_typ_S,dumc)
      Grd_typ_S    = dumc

      F_lam = (Grd_typ_S(1:1).eq.'L') .or. (Grd_typ_S(1:2).eq.'GY') 

      ! basic global lateral boundary conditions depth
      Grd_bsc_base = 5
      if(Grd_yinyang_L) Grd_bsc_base=Grd_bsc_base+1
      ! added points for proper de-staggering of u,v at physics interface
      Grd_bsc_ext1 = 2
      ! added points for user specified Grd_maxcfl
      Grd_maxcfl   = max(1,Grd_maxcfl)
      ! total extension to user specified grid configuration
      Grd_extension= 0
      if (F_lam) Grd_extension= Grd_maxcfl + Grd_bsc_base + Grd_bsc_ext1

      Grd_xlon1_8= Grd_xlon1 ; Grd_xlat1_8= Grd_xlat1
      Grd_xlon2_8= Grd_xlon2 ; Grd_xlat2_8= Grd_xlat2
      if (Grd_typ_S(1:2).eq.'GY') Grd_ni=(Grd_nj-1)*3 + 1

      if (Grd_ni*Grd_nj.eq.0) then
         if (Lun_out.gt.0) write(Lun_out,*)  &
                           'VERIFY Grd_NI & Grd_NJ IN NAMELIST grid'
         goto 9999
      endif

      Grd_x0_8=  0.0 ; Grd_xl_8=360.0
      Grd_y0_8=-90.0 ; Grd_yl_8= 90.0

      select case (Grd_typ_S(1:1))

      case ('G')                             ! Global grid

         select case (Grd_typ_S(2:2))

         case ('U')             ! Uniform
            Grd_dx   = 360./Grd_ni
            Grd_dy   = 180./Grd_nj

         case ('Y')             ! Yin-Yang
            if (yyg_checkrot().lt.0) goto 9999

            if (trim(Grd_yinyang_S) .eq. 'YAN') then
               call yyg_yangrot ( Grd_xlat1_8, Grd_xlon1_8, Grd_xlat2_8, Grd_xlon2_8,&
                                  yan_xlat1_8, yan_xlon1_8, yan_xlat2_8, yan_xlon2_8 )
               Grd_xlat1_8= yan_xlat1_8 ; Grd_xlon1_8= yan_xlon1_8
               Grd_xlat2_8= yan_xlat2_8 ; Grd_xlon2_8= yan_xlon2_8
               Grd_xlat1  = yan_xlat1_8 ; Grd_xlon1  = yan_xlon1_8
               Grd_xlat2  = yan_xlat2_8 ; Grd_xlon2  = yan_xlon2_8
            endif
            if (Lun_out.gt.0) write(Lun_out,1003) Grd_ni,Grd_nj

            Grd_x0_8 =   45.0 - 3.0*Grd_overlap
            Grd_xl_8 =  315.0 + 3.0*Grd_overlap
            Grd_y0_8 = -45.0  -     Grd_overlap
            Grd_yl_8 =  45.0  +     Grd_overlap

            delta_8  = (Grd_xl_8-Grd_x0_8)/(Grd_ni-1)
            Grd_dx   = delta_8
            Grd_x0_8 = Grd_x0_8 - Grd_extension*delta_8
            Grd_xl_8 = Grd_xl_8 + Grd_extension*delta_8

            delta_8  = (Grd_yl_8-Grd_y0_8)/(Grd_nj-1)
            Grd_dy   = delta_8
            Grd_y0_8 = Grd_y0_8 - Grd_extension*delta_8
            Grd_yl_8 = Grd_yl_8 + Grd_extension*delta_8

            Grd_ni   = Grd_ni + 2  *Grd_extension
            Grd_nj   = Grd_nj + 2  *Grd_extension

         end select

      case ('L')                             ! Limited area grid

         if (Grd_dx*Grd_dy.eq.0) then
            if (Lun_out.gt.0) write(Lun_out,*)  &
                             'VERIFY Grd_DX & Grd_DY IN NAMELIST grid'
            goto 9999
         endif
         Grd_ni   = Grd_ni   + 2*Grd_extension
         Grd_nj   = Grd_nj   + 2*Grd_extension
         Grd_iref = Grd_iref +   Grd_extension
         Grd_jref = Grd_jref +   Grd_extension
         if (Grd_iref.lt.1.or.Grd_iref.gt.Grd_ni.or. &
             Grd_jref.lt.1.or.Grd_jref.gt.Grd_nj) then
            if (Lun_out.gt.0) write(Lun_out,1002) &
                              Grd_ni,Grd_nj,Grd_iref,Grd_jref
            goto 9999
         endif
         Grd_x0_8   = Grd_lonr - (Grd_iref-1) * Grd_dx
         Grd_y0_8   = Grd_latr - (Grd_jref-1) * Grd_dy
         Grd_xl_8   = Grd_x0_8 + (Grd_ni  -1) * Grd_dx
         Grd_yl_8   = Grd_y0_8 + (Grd_nj  -1) * Grd_dy
         if (Grd_x0_8.lt.0.) Grd_x0_8=Grd_x0_8+360.
         if (Grd_xl_8.lt.0.) Grd_xl_8=Grd_xl_8+360.
         if ( (Grd_x0_8.lt.  0.).or.(Grd_y0_8.lt.-90.).or. &
              (Grd_xl_8.gt.360.).or.(Grd_yl_8.gt. 90.) ) then
            if (Lun_out.gt.0) write (Lun_out,1001)  &
                              Grd_x0_8,Grd_y0_8,Grd_xl_8,Grd_yl_8
            goto 9999
         endif

      end select

!     compute RPN/FST grid descriptors
!
      Hgc_gxtyp_s = 'E'
      call cxgaig ( Hgc_gxtyp_S,Hgc_ig1ro,Hgc_ig2ro,Hgc_ig3ro,Hgc_ig4ro, &
                              Grd_xlat1,Grd_xlon1,Grd_xlat2,Grd_xlon2 )
      call cigaxg ( Hgc_gxtyp_S,Grd_xlat1,Grd_xlon1,Grd_xlat2,Grd_xlon2, &
                              Hgc_ig1ro,Hgc_ig2ro,Hgc_ig3ro,Hgc_ig4ro )

      if (Lun_out.gt.0) write(6,1100) trim(Grd_yinyang_S)       , &
                                      Grd_ni, Grd_x0_8, Grd_xl_8, &
                                      Grd_nj, Grd_y0_8, Grd_yl_8, &
                                      Grd_typ_S, Grd_dx ,Grd_dx

      if (Lun_out.gt.0) write (Lun_out,1004) Grd_xlat1,Grd_xlon1,Grd_xlat2,Grd_xlon2,&
                                             Hgc_ig1ro,Hgc_ig2ro,Hgc_ig3ro,Hgc_ig4ro

      Grd_roule = .not. ( (abs(Grd_xlon1-180.d0).lt.epsilon) .and. &
                        (  abs(Grd_xlon2-270.d0).lt.epsilon) .and. &
                        (  abs(Grd_xlat1       ).lt.epsilon) .and. &
                        (  abs(Grd_xlat2       ).lt.epsilon) )

      Grd_rot_8      = 0.
      Grd_rot_8(1,1) = 1.
      Grd_rot_8(2,2) = 1.
      Grd_rot_8(3,3) = 1.

      if (Grd_roule) then
!
!     Compute the rotation matrix that allows transformation
!     from the none-rotated to the rotated spherical coordinate system.
!
!     Compute transform matrices xyz1_8 and xyz2_8
!
         call llacar ( xyz1_8, Grd_xlon1, Grd_xlat1, 1, 1 )
         call llacar ( xyz2_8, Grd_xlon2, Grd_xlat2, 1, 1 )
!
!     Compute a = cos(alpha) & b = sin(alpha)
!
         a_8 = (xyz1_8(1)*xyz2_8(1)) + (xyz1_8(2)*xyz2_8(2))  &
                                     + (xyz1_8(3)*xyz2_8(3))
         b_8 = sqrt (((xyz1_8(2)*xyz2_8(3)) - (xyz2_8(2)*xyz1_8(3)))**2 &
                  +  ((xyz2_8(1)*xyz1_8(3)) - (xyz1_8(1)*xyz2_8(3)))**2  &
                  +  ((xyz1_8(1)*xyz2_8(2)) - (xyz2_8(1)*xyz1_8(2)))**2)
!
!     Compute c = norm(-r1) & d = norm(r4)
!
         c_8 = sqrt ( xyz1_8(1)**2 + xyz1_8(2)**2 + xyz1_8(3)**2 )
         d_8 = sqrt ( ( ( (a_8*xyz1_8(1)) - xyz2_8(1) ) / b_8 )**2 + &
                      ( ( (a_8*xyz1_8(2)) - xyz2_8(2) ) / b_8 )**2 + &
                      ( ( (a_8*xyz1_8(3)) - xyz2_8(3) ) / b_8 )**2  )

         Grd_rot_8(1,1)=  -xyz1_8(1)/c_8
         Grd_rot_8(1,2)=  -xyz1_8(2)/c_8
         Grd_rot_8(1,3)=  -xyz1_8(3)/c_8
         Grd_rot_8(2,1)=  ( ((a_8*xyz1_8(1)) - xyz2_8(1)) / b_8)/d_8
         Grd_rot_8(2,2)=  ( ((a_8*xyz1_8(2)) - xyz2_8(2)) / b_8)/d_8
         Grd_rot_8(2,3)=  ( ((a_8*xyz1_8(3)) - xyz2_8(3)) / b_8)/d_8
         Grd_rot_8(3,1)=   &
              ( (xyz1_8(2)*xyz2_8(3)) - (xyz2_8(2)*xyz1_8(3)))/b_8
         Grd_rot_8(3,2)=   &
              ( (xyz2_8(1)*xyz1_8(3)) - (xyz1_8(1)*xyz2_8(3)))/b_8
         Grd_rot_8(3,3)=   &
              ( (xyz1_8(1)*xyz2_8(2)) - (xyz2_8(1)*xyz1_8(2)))/b_8

      endif

      grid_nml2 = 1

 1001 format(/,' WRONG LAM GRID CONFIGURATION --- ABORT ---'/, &
               ' Grd_x0,Grd_y0,Grd_xl,Grd_yl:'/4f10.3/)
 1002 format(/,' WRONG LAM GRID CONFIGURATION --- ABORT ---'/, &
               ' Grd_ni,Grd_nj,Grd_iref,Grd_jref:'/4I8/)
 1003 format(/, '-----------------------------------'/,&
            /1X,' GY uses GRD_NJ to compute GRD_NI  '/, &
                'WILL IGNORE GRD_NI in NAMELIST grid'/, &
            /1X,' YIN-YANG (CORE) GRID WILL BE: '/, &
            /1X,' GRD_NI=',I5,' GRD_NJ=',I5,/, &
            /,  '-----------------------------------')
 1004 format (1x,'Numerical equator: ',2('(',f9.4,',',f9.4,') ')/&
                21x,'IG1-4: ',4i8)
 1100 FORMAT (1X,'FINAL HORIZONTAL GRID CONFIGURATION: UNIFORM RESOLUTION: ',a, &
        /1X,' NI=',I5,' FROM x0=',F11.5,' TO xl=',F11.5,' DEGREES' &
        /1X,' NJ=',I5,' FROM y0=',F11.5,' TO yl=',F11.5,' DEGREES' &
        /1X,' GRIDTYPE= ',a,'     DX= ',F11.5,'   DY= ',F11.5/)
 7050 format (/,' FILE: ',A,' NOT AVAILABLE'/)
 7060 format (/,' Namelist &grid NOT AVAILABLE in FILE: ',a/)
 7070 format (/,' NAMELIST &grid IS INVALID IN FILE: ',A/)
!
!-------------------------------------------------------------------
!
 9999 call fclos (unf)
      return
      end
