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
!/@*
subroutine adx_interp_gmm7 ( F_out_S, F_in_S , F_wind_L, &
                             F_capx1, F_capy1, F_capz1 , &
                             F_capx2, F_capy2, F_capz2 , &
                             F_c1, F_nk, i0,in,j0,jn,k0, F_lev_S, F_mono_kind, F_mass_kind )
   implicit none
#include <arch_specific.hf>
!
   !@objective
!
   !@arguments
   character(len=*), intent(in) :: F_out_S !I, gmm label for interpolated field
   character(len=*), intent(in) :: F_in_S  !I, gmm label for field to interpolate
   logical, intent(in) :: F_wind_L         !I, .true. if field is wind like
   integer, intent(in) :: F_nk             !I, number of vertical levels
   integer, intent(in) :: i0,in,j0,jn,k0   !I, scope of operator
   integer, intent(in) :: F_c1(*)
   real, intent(in)    :: F_capx1(*), F_capy1(*), F_capz1(*)
   real, intent(in)    :: F_capx2(*), F_capy2(*), F_capz2(*)
   character(len=*), intent(in) :: F_lev_S !I, m/t : Momemtum/thermo level
   integer, intent(in) :: F_mono_kind      !I, Kind of Shape preservation
   integer, intent(in) :: F_mass_kind      !I, Kind of  Mass conservation
!
   !@revisions
   !  2009-12,  Stephane Chamberland: original code from adx_main_3
   !  2012-06,  Stephane Gaudreault: Code optimization, Positivity-preserving advection
   !  2015-11,  Monique Tanguay    : GEM4 Mass-Conservation and FLUX calculations 
!*@/

#include "gmm.hf"
#include "adx_nml.cdk"
#include "adx_dims.cdk"
#include "vt_tracers.cdk"

   type(gmm_metadata) :: mymeta
   logical :: mono_L, clip_positive_L, conserv_L
   integer :: err,flux_n
   real, pointer, dimension (:,:,:) :: fld_in, fld_out
   real, pointer, dimension (:,:,:) :: no_conserv, no_flux
   real, pointer, dimension(:,:,:) ::cub_o,cub_i,in_o,in_i


   !---------------------------------------------------------------------

   err =     gmm_get(F_in_S ,fld_in ,mymeta)
   err = min(gmm_get(F_out_S,fld_out,mymeta),err)

   no_conserv => fld_in !# Note: dummy pointer, not used
   no_flux    => fld_in !# Note: dummy pointer, not used

   mono_L = .false.
   clip_positive_L = .false.
   if (F_in_S(1:3) == 'TR/') then
      if (adw_positive_L) then
         clip_positive_L = .true.
      else
         mono_L = adw_mono_L
      endif

   endif

   flux_n = 0
   if (F_mass_kind == 1.and.adx_lam_L.and..not.adx_yinyang_L) flux_n = 1

   conserv_L = F_mono_kind/=0.or.F_mass_kind/=0

   if (conserv_L) then

      mono_L = .false.
      clip_positive_L = .false.

      nullify(fld_cub,fld_mono,fld_lin,fld_min,fld_max)

      err = gmm_get(gmmk_cub_s ,fld_cub ,mymeta)
      err = gmm_get(gmmk_mono_s,fld_mono,mymeta)
      err = gmm_get(gmmk_lin_s ,fld_lin ,mymeta)
      err = gmm_get(gmmk_min_s ,fld_min ,mymeta)
      err = gmm_get(gmmk_max_s ,fld_max ,mymeta)

      !To maintain nesting values
      !--------------------------
      fld_cub  = fld_out
      fld_mono = fld_out

      if (flux_n>0) then

         allocate (cub_o(adx_mlminx:adx_mlmaxx,adx_mlminy:adx_mlmaxy,F_nk),cub_i(adx_mlminx:adx_mlmaxx,adx_mlminy:adx_mlmaxy,F_nk), &
                    in_o(adx_mlminx:adx_mlmaxx,adx_mlminy:adx_mlmaxy,F_nk), in_i(adx_mlminx:adx_mlmaxx,adx_mlminy:adx_mlmaxy,F_nk))

      else 

         cub_o => no_flux
          in_o => no_flux
         cub_i => no_flux
          in_i => no_flux

      endif

   else

      fld_cub  => no_conserv
      fld_mono => no_conserv
      fld_lin  => no_conserv
      fld_min  => no_conserv
      fld_max  => no_conserv

         cub_o => no_flux
          in_o => no_flux
         cub_i => no_flux
          in_i => no_flux

   endif

   call adx_interp7 (fld_out (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                     fld_cub (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                     fld_mono(mymeta%l(1)%low,mymeta%l(2)%low,1),&
                     fld_lin (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                     fld_min (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                     fld_max (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                     fld_in  (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                     cub_o,in_o,cub_i,in_i,flux_n,               &
                     F_c1, F_capx1, F_capy1, F_capz1            ,&
                     F_capx2, F_capy2, F_capz2                  ,&
                     mymeta%l(1)%low,mymeta%l(1)%high           ,&
                     mymeta%l(2)%low,mymeta%l(2)%high, F_nk     ,&
                     F_wind_L, mono_L, clip_positive_L          ,&
                     conserv_L,i0,in,j0,jn,k0, F_lev_S)

   if (conserv_L)  call adx_tracers_mono_mass (F_out_S,                                    &
                                               fld_out (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                                               fld_cub (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                                               fld_mono(mymeta%l(1)%low,mymeta%l(2)%low,1),&
                                               fld_lin (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                                               fld_min (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                                               fld_max (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                                               fld_in  (mymeta%l(1)%low,mymeta%l(2)%low,1),&
                                               cub_o,cub_i,                                &
                                               mymeta%l(1)%low,mymeta%l(1)%high           ,&
                                               mymeta%l(2)%low,mymeta%l(2)%high,F_nk      ,&
                                               i0,in,j0,jn,k0,F_mono_kind,F_mass_kind)

   if (flux_n>0) deallocate(cub_o,cub_i,in_o,in_i) 

  !---------------------------------------------------------------------

   return
end subroutine adx_interp_gmm7
