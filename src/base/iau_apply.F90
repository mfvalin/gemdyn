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

subroutine iau_apply2(F_kount)
   use iso_c_binding
   use vGrid_Descriptors
   use vgrid_wb
   use input_mod
   implicit none
   !@params
   integer, intent(in) :: F_kount !step_kound
   !@author
   !       R. McTaggart-Cowan - Summer 2013
   !@revision
   !       S.Chamberland, 2014-07: use input_mod, allow vinterp
   !@object
   !  Add an analysis increments to the model state (IAU).
#include <arch_specific.hf>
#include "rpn_comm.inc"
#include <rmnlib_basics.hf>
#include <clib_interface_mu.hf>
#include <gmm.hf>
#include <msg.h>
#include "dcst.cdk"
#include "cstv.cdk"
#include "lctl.cdk"
#include "step.cdk"
#include "glb_ld.cdk"
#include "grd.cdk"
#include "path.cdk"
#include "var_gmm.cdk"
#include "vt1.cdk"
#include "pw.cdk"
#include "iau.cdk"
   character(len=2),parameter :: IAU_PREFIX='I_'
   character(len=6),parameter :: IAU_FILE = 'IAUREP'
   logical,parameter :: UVSCAL2WGRID = .false.
   logical,parameter :: ALLOWDIR = .true.
   logical,parameter :: DO_TT2TV = .true.
   logical,save :: is_init_L = .false.
   integer,save :: inputid = -1, nbvar = 0, step_freq2 = 0, kount = 0
   real,pointer,save :: weight(:)
   real, pointer, dimension(:,:) :: refp0,pw_p0
   character(len=256) :: incfg_S,vgrid_S,msg_S
   character(len=16)  :: iname0_S,iname1_S,datev_S
   integer :: istat,dateo,datev,iau_vtime,step_freq,ivar,ni1,nj1,i,j,n,nw,add,&
        lijk(3),uijk(3),step_0
   real,pointer,dimension(:,:,:) :: data0,data1,myptr0,myptr1
   real,pointer,dimension(:,:) :: myptr2d
   type(gmm_metadata) :: mymeta
   type(vgrid_descriptor) :: vgridm,vgridt
   integer,pointer :: ip1list(:),ip1listref(:)
   !--------------------------------------------------------------------------
!!$   write(msg_S,'(l,i4,a,i7,a,i7)') (Cstv_dt_8*F_kount > Iau_period .or. Iau_interval<=0.),F_kount,'; t=',nint(Cstv_dt_8*F_kount),'; p=',nint(Iau_period)
!!$   call msg(MSG_INFO,'IAU YES/NO?: '//trim(msg_S))

   if (Cstv_dt_8*F_kount > Iau_period .or. Iau_interval<=0.) return
   call timing_start2(50, 'IAU', 1)

   istat = rpn_comm_bloc(Iau_ninblocx, Iau_ninblocy)

   call datp2f(dateo,Step_runstrt_S)
   iau_vtime = -Step_delay*Cstv_dt_8 + Iau_interval * nint((Lctl_step)*Cstv_dt_8/Iau_interval-epsilon(1.))
   call incdatr(datev,dateo,dble(iau_vtime)/3600.d0)
   call datf2p(datev_S,datev)

   IF_INIT: if (.not.is_init_L) then
      is_init_L = .true.

      !# Set up input module
      inputid = input_new(dateo,nint(Cstv_dt_8))
      istat = input_setgridid(inputid,Grd_lclcore_gid)
      istat = min(input_set_basedir(inputid,Path_input_S),inputid)
      istat = min(input_set_filename(inputid,IAU_FILE,IAU_FILE,ALLOWDIR,INPUT_FILES_ANAL),istat)
      step_freq  = nint(Iau_interval/Cstv_dt_8)
      step_freq2 = nint((Iau_interval/2)/Cstv_dt_8) !TODO: check
      step_0 = mod((nint(Iau_period)/nint(Iau_interval)),2)*step_freq2
      write(incfg_S,'(a,i4,a,i4,a,a,a)') 'freq=',step_0,',',step_freq, &
           '; search=',trim(IAU_FILE), &
           '; typvar=R; hinterp=cubic; vinterp=c-cond'
      call msg(MSG_INFO,'(iau_apply) add input: in=TT; levels=-1;'//trim(incfg_S))
      istat = min(input_add(inputid,'in=TT; levels=-1;'//trim(incfg_S)),istat)
      call msg(MSG_INFO,'(iau_apply) add input: in=HU; levels=-1;'//trim(incfg_S))
      istat = min(input_add(inputid,'in=HU; levels=-1;'//trim(incfg_S)),istat)
      call msg(MSG_INFO,'(iau_apply) add input: in=UU; IN2=VV; levels=-1;'//trim(incfg_S))
      istat = min(input_add(inputid,'in=UU; IN2=VV; levels=-1;'//trim(incfg_S)),istat)
      write(incfg_S,'(a,i4,a,i4,a,a,a)') 'freq=',step_0,',',step_freq, &
           '; search=',trim(IAU_FILE), &
           '; typvar=R; hinterp=cubic'
      call msg(MSG_INFO,'(iau_apply) add input: in=P0;'//trim(incfg_S))
      istat = min(input_add(inputid,'in=P0; '//trim(incfg_S)),istat)
      ivar = 1
      do while (len_trim(Iau_tracers_S(ivar)) > 0)
         istat = min(clib_tolower(Iau_tracers_S(ivar)),istat)
         if (Iau_tracers_S(ivar) /= 'hu') then
            call msg(MSG_INFO,'(iau_apply) add input: in='//trim(Iau_tracers_S(ivar))//'; levels=-1;'//trim(incfg_S))
            istat = min(input_add(inputid,'in='//trim(Iau_tracers_S(ivar))//'; levels=-1;'//trim(incfg_S)),istat)
         endif
         ivar = ivar+1 
         if (ivar > size(Iau_tracers_S)) exit
      enddo
      nbvar = input_nbvar(inputid)
      call handle_error_l(RMN_IS_OK(istat).and.nbvar>0,'iau_apply', &
           'Problem initializing the input module')

      !# Create data space to save inc values between read-incr
      DO_IVAR0: do ivar = 1,nbvar
         istat = input_meta(inputid,ivar,iname0_S,iname1_S)
         nullify(data0,data1)
         if (iname0_S == 'p0') then
            mymeta = meta2d ; mymeta%l(3) = gmm_layout(1,1,0,0,1)
            istat = gmm_create(IAU_PREFIX//trim(iname0_S),data0, &
                 mymeta,GMM_FLAG_IZER)
         else
            istat = gmm_create(IAU_PREFIX//trim(iname0_S),data0, &
                 meta3d_nk,GMM_FLAG_IZER)
            if (iname1_S /= ' ') &
                 istat = gmm_create(IAU_PREFIX//trim(iname1_S),data1, &
                 meta3d_nk,GMM_FLAG_IZER)
         endif
      end do DO_IVAR0

      !# Precompute filter coefficients on initialization
      nw = nint(Iau_period/Cstv_dt_8)
      add = 0; if (mod(nw,2) == 0) add = 1
      nw = nw+add
      allocate(weight(nw))
      call msg(MSG_INFO,'(iau_apply) Precompute filter coefficients - '//trim(Iau_weight_S))
      istat = clib_tolower(Iau_weight_S)
      select case (Iau_weight_S)
      case ('constant')
         weight = Cstv_dt_8 / Iau_period
      case ('spike')
         weight = 0.
         weight(nw/2) = 1.
      case ('sin')
         call handle_error_l(Iau_cutoff>0.,'iau_apply', &
              'Cutoff period must be greater than 0')
         j = 0 ; i = nw ; n = nw/2
         do while (j < nw)
            i = j-n; j = j+1
            if (i == 0) then
               weight(j) = 2.*Cstv_dt_8/(Iau_cutoff*3600.)
            else
               weight(j) = sin(i*Dcst_pi_8/(n+1)) / (i*Dcst_pi_8/(n+1)) * &
                    sin(i*(2.*Dcst_pi_8*Cstv_dt_8/(Iau_cutoff*3600.))) / &
                    (i*Dcst_pi_8)
            endif
         enddo
         weight = weight/sum(weight(1:size(weight)-add))
      case default
         call handle_error(RMN_ERR,'iau_apply', &
              'Unknown Iau_weight_S='//trim(Iau_weight_S))
      end select

      !# define a vert coor with ref on l_ni/j
      nullify(ip1list)
      istat = vgrid_wb_get('ref-m',vgridm,ip1list)
      ip1listref => ip1list(1:G_nk)
      istat = vgrid_wb_put('iau-m',vgridm,ip1listref,'IAUREFP0:P', &
              F_overwrite_L=.true.)
      nullify(ip1list)
      istat = vgrid_wb_get('ref-t',vgridt,ip1list)
      ip1listref => ip1list(1:G_nk)
      istat = vgrid_wb_put('iau-t',vgridt,ip1listref,'IAUREFP0:P', &
              F_overwrite_L=.true.)
      mymeta = GMM_NULL_METADATA
      mymeta%l(1) = gmm_layout(1,l_ni,0,0,l_ni)
      mymeta%l(2) = gmm_layout(1,l_nj,0,0,l_nj)
      nullify(refp0)
      istat = gmm_create('IAUREFP0:P',refp0,mymeta)
 
   endif IF_INIT

   !# Update reference surface field for vgrid
   nullify(pw_p0,refp0)
   istat = gmm_get('PW_P0:P',pw_p0)
   istat = gmm_get('IAUREFP0:P',refp0)
   if (associated(refp0) .and. associated(pw_p0)) then
      refp0(:,:) = pw_p0(1:l_ni,1:l_nj)
   endif


   if (F_kount > 0) kount = F_kount+step_freq2-1
   DO_IVAR: do ivar = 1,nbvar
      istat = input_meta(inputid,ivar,iname0_S,iname1_S)
      nullify(data0,data1)
      istat = gmm_get(IAU_PREFIX//trim(iname0_S),data0)
      if (iname1_S /= '') istat = gmm_get(IAU_PREFIX//trim(iname1_S),data1)
      if (.not.associated(data0) .or. &
           (iname1_S /= '' .and..not.associated(data1))) then
         call msg(MSG_ERROR,'(iau_apply) Problem getting ptr for: '//trim(iname0_S)//' '//trim(iname1_S))
         cycle DO_IVAR
      endif

      istat = input_isvarstep(inputid,ivar,kount)
      IF_READ: if (RMN_IS_OK(istat)) then

         write(msg_S,'(i7)') kount*nint(Cstv_dt_8)
         call msg(MSG_INFO,'(iau_apply) Reading: '//trim(iname0_S)//' at t0+'//trim(msg_S)//'s')

         !# Get interpolted data from file
         vgrid_S = 'iau-t'
         if (iname0_S == 'uu') vgrid_S = 'iau-m'
         nullify(myptr0,myptr1,myptr2d)
         istat = input_get(inputid,ivar,kount,Grd_local_gid,vgrid_S, &
              myptr0,myptr1)
         if (.not.RMN_IS_OK(istat) .or. .not.associated(myptr0) .or. &
           (iname1_S /= '' .and..not.associated(myptr1))) then
            call msg(MSG_ERROR,'(iau_apply) Problem getting data for: '//trim(iname0_S)//' '//trim(iname1_S))
            istat = RMN_ERR
         endif
         call handle_error(istat,'(iau_apply) Problem getting data for: '//trim(iname0_S)//' '//trim(iname1_S))

         !# Move data to grid with halos; save in GMM
         if (associated(myptr0)) then
            data0(1:l_ni,1:l_nj,:) = myptr0(1:l_ni,1:l_nj,:)
            deallocate(myptr0, stat=istat)
         endif
         if (associated(myptr1)) then
            data1(1:l_ni,1:l_nj,:) = myptr1(1:l_ni,1:l_nj,:)
            deallocate(myptr1,stat=istat)
         endif

         !# Adapt units and horizontal positioning
         lijk = lbound(data0) ; uijk = ubound(data0)
         if (iname0_S == 'uu') then
            data0 = data0 * Dcst_knams_8
            data1 = data1 * Dcst_knams_8
            nullify(myptr0,myptr1)
            allocate(myptr0(l_minx:l_maxx,l_miny:l_maxy,uijk(3)),myptr1(l_minx:l_maxx,l_miny:l_maxy,uijk(3)))
            myptr0 = 0.; myptr1 = 0.
            myptr0(1:l_ni,1:l_nj,:) = data0(1:l_ni,1:l_nj,:)
            myptr1(1:l_ni,1:l_nj,:) = data1(1:l_ni,1:l_nj,:)
            call itf_phy_uvgridscal(myptr0,myptr1,l_minx,l_maxx,l_miny,l_maxy,uijk(3),UVSCAL2WGRID)
            data0(1:l_ni,1:l_nj,:) = myptr0(1:l_ni,1:l_nj,:)
            data1(1:l_ni,1:l_nj,:) = myptr1(1:l_ni,1:l_nj,:)
            deallocate(myptr0,myptr1,stat=istat); nullify(myptr0,myptr1)
         endif
         if (iname0_S == 'p0') data0 = 100.*data0

         IF_YY: if (Grd_yinyang_L .and. &
              (iname0_S == 'hu' .or. .not.any(iname0_S == Iau_tracers_S))) then
            if (iname1_S /= ' ' .and. associated(data1)) then
               call yyg_nestuv(data0,data1,lijk(1),uijk(1), &
                    lijk(2),uijk(2),uijk(3))
            else
               call yyg_xchng (data0 ,lijk(1),uijk(1),lijk(2),uijk(2),uijk(3), &
                    .false., 'CUBIC')
               call rpn_comm_xch_halo(data0,lijk(1),uijk(1),lijk(2),uijk(2), &
                    l_ni,l_nj,uijk(3),G_halox,G_haloy,G_periodx,G_periody, &
                    l_ni,0 )
            endif
         endif IF_YY

      endif IF_READ
      
      IF_KOUNT0: if (F_kount > 0 .and. weight(max(1,F_kount)) > 0.) then

         !# Add increments to model and tracer states
         ni1 = l_ni ; nj1 = l_nj
         nullify(myptr0,myptr1,myptr2d)
         select case(iname0_S)
         case('tt')
            istat = gmm_get(gmmk_pw_tt_plus_s,myptr0)
!!$            print '(a,i4," : ",f10.5," : ",f10.5," < ",f10.5)','[iau_apply] ',F_kount,data0(l_ni/2,l_nj/2,l_nk/2),minval(data0),maxval(data0)
         case('uu')
            ni1 = l_niu ; nj1 = l_njv
            istat = gmm_get(gmmk_ut1_s,myptr0)
            istat = gmm_get(gmmk_vt1_s,myptr1)
         case('p0')
            istat = gmm_get(gmmk_st1_s,myptr2d)
         case default
            istat = clib_toupper(iname0_S)
            istat = gmm_get('TR/'//trim(iname0_S)//':P',myptr0)
         end select

         write(msg_S,'(a,i6,3(a,f12.6))') '; step=',F_kount,'; w=',weight(F_kount),'; min=',minval(data0(1:ni1,1:l_nj,:)),'; max=',maxval(data0(1:ni1,1:l_nj,:))
         call msg(MSG_INFO,'(iau_apply) Add increments: '//trim(iname0_S)//trim(msg_S))
         if (associated(data1)) then
            write(msg_S,'(a,i6,3(a,f12.6))') '; step=',F_kount,'; w=',weight(F_kount),'; min=',minval(data1(1:ni1,1:l_nj,:)),'; max=',maxval(data1(1:ni1,1:l_nj,:))
            call msg(MSG_INFO,'(iau_apply) Add increments: '//trim(iname1_S)//trim(msg_S))
         endif

         if (associated(myptr0)) myptr0(1:ni1,1:l_nj,:) = &
              myptr0(1:ni1,1:l_nj,:) + weight(F_kount) * data0(1:ni1,1:l_nj,:)
         if (associated(myptr1).and.associated(data1)) myptr1(1:l_ni,1:nj1,:) = &
              myptr1(1:l_ni,1:nj1,:) + weight(F_kount) * data1(1:l_ni,1:nj1,:)
         if (associated(myptr2d)) then
            if (iname0_S == 'p0') then
               myptr2d(1:l_ni,1:l_nj) = myptr2d(1:l_ni,1:l_nj) + log(1 + weight(F_kount)*data0(1:l_ni,1:l_nj,1)/Cstv_pref_8)
            else
               myptr2d(1:l_ni,1:l_nj) = myptr2d(1:l_ni,1:l_nj) + weight(F_kount) * data0(1:l_ni,1:l_nj,1)
            endif
         endif
      endif IF_KOUNT0

   enddo DO_IVAR

   if (F_kount > 0) then
      nullify(myptr0)
      istat = gmm_get(gmmk_tt1_s,myptr0)
      call tt2virt2(myptr0, DO_TT2TV, l_minx,l_maxx,l_miny,l_maxy, G_nk)
      call pw_update_GPW
      call pw_update_UV
      call pw_update_T

      call msg(MSG_INFO,' IAU_APPLY - APPLIED ANALYSIS INCREMENTS VALID AT '//trim(datev_S))
   endif
   call timing_stop(50)
   !--------------------------------------------------------------------------
   return
end subroutine iau_apply2
