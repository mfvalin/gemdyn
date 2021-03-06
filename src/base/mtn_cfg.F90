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

!**s/r mtn_cfg - reads parameters from namelist mtn_cfgs
!
      integer function mtn_cfg (unf)
      implicit none
#include <arch_specific.hf>
      integer unf

!author
!     sylvie gravel   -  Apr 2003
!
!revision
! v3_20 - gravel s        - initial version
! v3_30 - Lee V.          - New control parameters added
!
!object
!     See above id
!
!arguments - none

#include "theonml.cdk"
#include "stat.cdk"

      integer i, j, k, idatx, longueur,istat
      real*8 delta_8, zmt_8(maxhlev)
      real*8 c1_8,Exner_8,height_8,pres_8,p1000hPa_8
      real aa
!
!     ---------------------------------------------------------------

      stat_liste(1)='URT1'
      stat_liste(2)='VRT1'
      stat_liste(3)='WT1'
      stat_liste(4)='ZDT1'
      stat_liste(5)='TT1'
      stat_liste(6)='ST1'
      stat_liste(7)='QT1'

      p1000hPa_8=100000.d0
      mtn_cfg = -1
      Step_gstat = 1
      do k = 1, maxhlev
         hyb(k) = -1.
      end do

      Grd_typ_S='GU'
      Grd_rot_8 = 0.0
      Grd_rot_8(1,1) = 1.
      Grd_rot_8(2,2) = 1.
      Grd_rot_8(3,3) = 1.
      Grd_roule=.false.
      Grd_bsc_base = 5
      Grd_bsc_ext1 = 0
      Grd_maxcfl   = 3
      Grd_bsc_adw  = Grd_maxcfl  + Grd_bsc_base
      Grd_extension= Grd_bsc_adw + Grd_bsc_ext1
!
      G_lam=.true.
      Grd_xlat1=0.
      Grd_xlon1=180.
      Grd_xlat2=0.
      Grd_xlon2=270.
!
      Cstv_bA_8 = 0.5
!
      Grd_rcoef = 1.0
!
      Lam_ctebcs_L=.true.

      hdif_lnr = 0.
      hdif_pwr = 6

      Schm_trapeze_L=.true.
      Schm_cub_traj_L=.true.
      Schm_phyms_L = .false.
      Schm_psadj=0

      G_halox=3

      Zblen_L        = .true.
      Zblen_spngtt_L = .true.
      Zblen_spngthick=0.

      Out3_close_interval_S = '999h'
      Out3_close_interval = 999
      Out3_unit_S = 'HOU'

      istat = 0
      if ( Theo_case_S.eq.'MTN_SCHAR') then

         Out3_etik_s  = 'SCHAR'
         Schm_hydro_L = .false.

         mtn_hght_top = 19500.d0

         mtn_tzero= 288.
         mtn_nstar= 0.01
         mtn_flo  = 10.
         mtn_hwx  = 10
         mtn_hwx1 = 8
         mtn_hght = 250.

         Grd_ni = 401
         Grd_nj = 1
         G_nk   = 65

         Grd_dx = 500.                                   !  in meters

         Lam_blend_H = 25

         Zblen_spngthick=9000.

        !FAST INTEGRATION(4hr)      CLASSICAL INTEGRATION
         Step_total  = 450         !Step_total  = 1800
         Cstv_dt_8   = 32.         !Cstv_dt_8   = 8.
        !GROWING MOUNTAIN
         Vtopo_start = 0
         Vtopo_ndt   = 75          !Vtopo_ndt   = 300

      else if ( Theo_case_S.eq.'MTN_SCHAR2') then

         Out3_etik_s='SCHAR2'
         Schm_hydro_L = .false.

         mtn_hght_top = 19500.d0

         mtn_tzero= 273.16
         mtn_nstar= 0.01871
         mtn_flo  = 18.71
         mtn_hwx  = 10
         mtn_hwx1 = 8
         mtn_hght = 250.

         Grd_ni = 401
         Grd_nj = 1
         G_nk   = 65

         Grd_dx = 500.                                   !  in meters

         Lam_blend_H=25

         Zblen_spngthick=9000.

         Step_total = 2400

         Cstv_dt_8 = 5.34         !   CFL=0.2
!        Cstv_dt_8 = 26.7         !   CFL=1.0
!        attention: dernierement fraction de secondes non disponibles
         Cstv_tstr_8 = mtn_tzero

         Vtopo_start = -99999
         Vtopo_ndt   = 0

      else if ( Theo_case_S.eq.'MTN_PINTY') then

         Out3_etik_s='PINTY'
         Schm_hydro_L = .true.

         mtn_hght_top = 20000.d0

         mtn_tzero= 273.16
         mtn_nstar= -1
         mtn_flo  = 32.
         mtn_hwx  = 5
         mtn_hght = 1.

         Grd_ni = 161
         Grd_nj = 1
         G_nk   = 80

         Grd_dx = 3200.                                  ! in meters

         Lam_blend_H=25

         Zblen_spngthick=10000.

         Step_total = 800

         Cstv_dt_8   = 50.
         Cstv_tstr_8 = mtn_tzero
         Vtopo_start = -99999
         Vtopo_ndt   = 0

      else if ( Theo_case_S.eq.'MTN_PINTY2') then

         Out3_etik_s='PINTY2'
         Schm_hydro_L = .true.

         mtn_hght_top = 20000.d0

         mtn_tzero=273.16
         mtn_nstar=-1
         mtn_flo  = 8.
         mtn_hwx  =5
         mtn_hght = 100.

         Grd_ni = 161
         Grd_nj = 1
         G_nk   = 81

         Grd_dx = 3200.                                  ! in meters

         Lam_blend_H=25

         Zblen_spngthick=2500.

         Step_total = 1600

         Cstv_dt_8   = 200.
         Cstv_tstr_8 = mtn_tzero
         Vtopo_start = -99999
         Vtopo_ndt   = 0

      else if ( Theo_case_S.eq.'MTN_PINTYNL') then

         Out3_etik_s='PINTYNL'
         Schm_hydro_L = .true.

         mtn_hght_top = 20000.d0
         Cstv_ptop_8  = 9575.000118766453d0

         mtn_tzero= 273.16
         mtn_nstar= 0.02
         mtn_flo  = 32.
         mtn_hwx  = 5
         mtn_hght = 800.

         Grd_ni = 161
         Grd_nj = 1
         G_nk   = 80

         Grd_dx = 3200.                                  ! in meters

         Lam_blend_H=25

         Zblen_spngthick=10000.

         Step_total = 1000

         Cstv_dt_8   = 50.
         Cstv_tstr_8 = 2.946394714296820e+02
         Vtopo_start = 0
         Vtopo_ndt   = 60

      else if ( Theo_case_S.eq.'NOFLOW') then

         Out3_etik_s  ='0m_non_hydro'
         Schm_hydro_L =.false.

         Step_total  = 20
         mtn_hwx=1
         Cstv_dt_8=1.0
         Grd_ni=101
         Grd_nj = 1
         Grd_dx = 250.                     ! in meters
         cstv_tstr_8 = 273.16
         mtn_hght_top = 20000.d0
         G_nk      = 80                    ! dz=250m
         mtn_hght  = 0.
         mtn_tzero = 273.16

         ! Stable for hydro with these values (max mtn slope .gt. 82 deg)
         ! Isotherme tstar-tzero=30
         !  mtn_hght  = 4000.
         !  mtn_tzero = 243.16
         ! Barely stable for nonhydro with these values (max mtn slope .lt. 55 deg)
         ! Isotherme tstar-tzero=0
         !  Out3_etik_s  = '800m_nh'
         !  Schm_hydro_L   = .false.
         !  Schm_trapeze_L = .true.
         !  mtn_hght  = 800.
         !  mtn_tzero = 273.16

         mtn_nstar= -1

         zblen_L = .false.
         Lam_blend_H=0

         Vtopo_start = -99999
         Vtopo_ndt   = 0

      else
         istat = -1
      endif
      call handle_error(istat,'mtn_cfg','not a valid mtn_case')

      Hgc_gxtyp_s='E'
      call cxgaig ( Hgc_gxtyp_S,Hgc_ig1ro,Hgc_ig2ro,Hgc_ig3ro,Hgc_ig4ro, &
                              Grd_xlat1,Grd_xlon1,Grd_xlat2,Grd_xlon2 )

      rewind (unf)
      read ( unf, nml=mtn_cfgs, end = 9220, err=9000)
      go to 9221
 9220 if (Ptopo_myproc.eq.0) write( Lun_out,9230) Theo_case_S
 9221 continue

      Grd_dx = (Grd_dx/Dcst_rayt_8)*(180./Dcst_pi_8)  ! in degrees


!   adjust dimensions to include piloted area (pil_n, s, w, e)

      Glb_pil_n = Grd_extension
      Glb_pil_s = Glb_pil_n ; Glb_pil_w=Glb_pil_n ; Glb_pil_e=Glb_pil_n
!
      Grd_ni   = Grd_ni + 2*Grd_extension
      Grd_nj   = Grd_nj + 2*Grd_extension
      Grd_jref = (Grd_nj+1 )/2
      Zblen_hmin = mtn_hght_top - Zblen_spngthick

      if(hyb(1).lt.0) then
         if(mtn_nstar.lt.0.)            &!  isothermal case
            mtn_nstar=Dcst_grav_8/sqrt(Dcst_cpd_8*mtn_tzero)
         if(mtn_nstar.eq.0.0) then     !  isentropic case
            c1_8=Dcst_grav_8/(Dcst_cpd_8*mtn_tzero)
            Exner_8=1.d0-c1_8*mtn_hght_top
         else
            c1_8=Dcst_grav_8**2/(Dcst_cpd_8*mtn_tzero*mtn_nstar**2)
            Exner_8=1.d0-c1_8+c1_8 &
                       *exp(-mtn_nstar**2/Dcst_grav_8*mtn_hght_top)
         endif
         Cstv_ptop_8 = Exner_8**(1.d0/Dcst_cappa_8)*p1000hPa_8
!        Uniform distribution of levels in terms of height
         do k=1,G_nk
            height_8=mtn_hght_top*(1.d0-(dble(k)-.5d0)/G_nk)
            Exner_8=1.d0-c1_8+c1_8*exp(-mtn_nstar**2/Dcst_grav_8*height_8)
            pres_8=Exner_8**(1.d0/Dcst_cappa_8)*p1000hPa_8
            hyb(k)=(pres_8-Cstv_ptop_8)/(p1000hPa_8-Cstv_ptop_8)
         enddo
!
!        denormalize
         do k=1,G_nk
            hyb(k) = hyb(k) + (1.-hyb(k))*Cstv_ptop_8/p1000hPa_8
         enddo
      else
         do k=1024,1,-1
         if(hyb(k).lt.0) G_nk=k-1
         enddo
      endif
!
      Grd_dy = Grd_dx
      Grd_x0_8=0.
      Grd_xl_8=Grd_x0_8 + (Grd_ni -1) * Grd_dx
      Grd_y0_8= - (Grd_jref-1) * Grd_dy
      Grd_yl_8=Grd_y0_8 + (Grd_nj -1) * Grd_dy
      if ( (Grd_x0_8.lt.  0.).or.(Grd_y0_8.lt.-90.).or. &
           (Grd_xl_8.gt.360.).or.(Grd_yl_8.gt. 90.) ) then
          if (Ptopo_myproc.eq.0) write (Lun_out,9600) &
              Grd_x0_8,Grd_y0_8,Grd_xl_8,Grd_yl_8
          return
       endif
      call datp2f( idatx, Step_runstrt_S)
      Out3_date= idatx

      G_halox = min(G_halox,Grd_ni-1)
      G_haloy = G_halox

      mtn_cfg = 1
!
      step_dt=cstv_dt_8
!!$      Step_rsti=9999999
!!$      Step_bkup=9999999
      Fcst_rstrt_S = 'step,9999999'
      Fcst_bkup_S  = 'step,9999999'
      return
!
 9000 write (Lun_out, 9100)
!     ---------------------------------------------------------------
 9100 format (/,' NAMELIST mtn_cfgs INVALID FROM FILE: model_settings'/)
 9230 format (/,' Default setup will be used for :',a/)
 9500 format (/1x,'From subroutine mtn_cfg:', &
              /1x,'wrong value for model top')
 9600 format (/1x,'From subroutine mtn_cfg:', &
              /1x,'wrong lam grid configuration  ')
      end
!
