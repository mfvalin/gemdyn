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

!**s/r get_field - Read field F_nomvar_S from file F_filename_S and proceed
!                  with horizontal interpolation using scheme F_inttyp_S

      subroutine get_field ( F_dest, ni, nj, F_nomvar_S, F_filename_S,&
                                   F_inttyp_S, F_xfi, F_yfi, F_status )
      implicit none
#include <arch_specific.hf>
!
      character*(*) F_nomvar_S, F_filename_S, F_inttyp_S
      integer ni,nj,F_status
      real F_dest(ni,nj), F_xfi(ni), F_yfi(nj)
!
!author   
!     M. Desgagne  -   Spring 2010
!
!revision
! v4_13 -  Desgagne M.           - initial version
! v4_40 -  Lee V.                - get non Z source grid as well
!
#include "hgc.cdk"
#include "lun.cdk"
#include "glb_ld.cdk"
#include "glb_pil.cdk"
#include <clib_interface_mu.hf>
!
      integer,external :: fnom,fstouv,fstinf,fstprm,fstluk,fstfrm,fclos,&
           ezgdef_fmem,ezdefset,ezsetopt,ezsint,ezqkdef,ezgetopt,&
           ezsetival,ezgetival,ezgetval,samegrid_gid

      character*1   typ, grd, grd_me, grd_pos
      character*2   var
      character*8   lab, inttyp
      character*32  onesubgrid_S, oldsubgrid_S
      integer dte, det, ipas, p1, p2, p3, g1, g2, g3, g4, bit, &
              dty, swa, lng, dlf, ubc, ex1, ex2, ex3,          &
              g1o,g2o,g3o,g4o,nvar
      integer unf,key,ni1,nj1,nk1,i,j,err,subid,oldsubid
      integer sgid,dgid,nis,njs,nic,njc
      real, dimension(:  ), allocatable :: ax,ay
      real, dimension(:,:), allocatable :: source
      real*8 rad2deg_8 
      real extrap_value

!-----------------------------------------------------------------------
!
      F_status = -1

      subid= -1 ; oldsubid= -1

      err = clib_isfile(trim(F_filename_S))
      if ( err.lt.0 ) then
         if (Lun_out.gt.0) write (Lun_out, 9001) trim(F_filename_S)
         goto 999
      endif

      unf = 0
      err = fnom  (unf,trim(F_filename_S),'RND+OLD+R/O',0)
      if ( err.lt.0 ) then
         if (Lun_out.gt.0) &
              write (Lun_out, 9002) trim(F_filename_S),'RND+OLD+R/O'
         goto 999
      endif

      err = fstouv(unf,'RND')
      if ( err.lt.0 ) then
         if (Lun_out.gt.0) write (Lun_out, 9003) trim(F_filename_S),'RND'
         goto 999
      endif

      write (6,1000) trim(F_filename_S),unf
      
      key = fstinf (unf, nis,njs,nk1,-1," ",-1,-1,-1," ",F_nomvar_S)
      if (key.lt.0) then
         if (Lun_out.gt.0) write (Lun_out,9004) F_nomvar_S
         goto 999
      endif

      allocate (source(nis,njs))
      err = fstluk (source, key, ni1,nj1,nk1)

      err = fstprm (key, dte,det,ipas,ni1,nj1,nk1,bit,dty,&
                       p1, p2, p3, typ, var, lab, grd_ME, &
                       g1,g2,g3,g4, swa, &
                       lng, dlf, ubc, ex1, ex2, ex3)

      dgid = ezgdef_fmem (ni, nj , 'Z', 'E', Hgc_ig1ro, &
                 Hgc_ig2ro, Hgc_ig3ro, Hgc_ig4ro, F_xfi , F_yfi )

      if (any(grd_ME==(/'Z','z'/))) then

         allocate (ax(nis),ay(njs))

         key = fstinf (unf, ni1,nj1,nk1,-1," ",g1,g2,-1," ",">>")
         if (key.lt.0) then
            write (6,9004)
            goto 999
         endif
         err = fstluk (ax, key, ni1,nj1,nk1)

         key = fstinf (unf, ni1,nj1,nk1,-1," ",g1,g2,-1," ","^^")
         if (key.lt.0) then
            write (6,9004)
            goto 999
         endif
         err = fstluk (ay, key, ni1,nj1,nk1)

         err = fstprm (key, dte,det,ipas,ni1,nj1,nk1,bit,dty,&
                       p1, p2, p3, typ, var, lab, grd_POS,   &
                       g1,g2,g3,g4, swa,                     &
                       lng, dlf, ubc, ex1, ex2, ex3)

         sgid = ezgdef_fmem (nis, njs, grd_ME, grd_POS, &
                                   g1,g2,g3,g4, ax, ay)

         if (samegrid_gid (sgid, Hgc_ig1ro,Hgc_ig2ro,Hgc_ig3ro,Hgc_ig4ro,&
                           F_xfi, F_yfi, ni, nj) .gt. -1) &
                           F_inttyp_S = 'NEAREST'

      else

         sgid= ezqkdef(nis, njs, grd_ME, g1,g2,g3,g4,unf)
         err = ezgetopt ('USE_1SUBGRID',oldsubgrid_S)
         err = ezgetival('SUBGRIDID',oldsubid)
         if (any(grd_ME==(/'U','u'/))) then

! We only test samegrid on core domain
            nic = G_ni - Glb_pil_w - Glb_pil_e 
            njc = G_nj - Glb_pil_s - Glb_pil_n
            if (nis >= nic .and. njs/2 >= njc) then
               subid= samegrid_gid ( sgid, Hgc_ig1ro,Hgc_ig2ro              ,&
                                     Hgc_ig3ro,Hgc_ig4ro, F_xfi(1+Glb_pil_w),&
                                     F_yfi(1+Glb_pil_s), nic, njc )
               if (subid >= 0) print *,'U grid contains sub grid match to ',ni,nj
            endif
            if (subid.ge.0) then
               F_inttyp_S = 'NEAREST'
               onesubgrid_S = 'YES'
               err = ezsetival('SUBGRIDID',subid)
               err = ezsetopt ('USE_1SUBGRID',trim(onesubgrid_S))
            endif
         endif

      endif

      err = fstfrm (unf)
      err = fclos  (unf)

      write (6,1001) F_nomvar_S, trim(F_inttyp_S)

      err = ezdefset ( dgid, sgid )
      err = ezsetopt ('INTERP_DEGREE', trim(F_inttyp_S))
      err = ezsint   (F_dest, source)

      if (subid.ge.0) then
!     Reset to original values
         err = ezsetival ('SUBGRIDID'   ,oldsubid)
         err = ezsetopt  ('USE_1SUBGRID',trim(oldsubgrid_S))
      endif

      if (err.lt.0) then
         write (6,9005)
         goto 999
      endif

      F_status = 0

 1000 format (/' GET_FIELD:  file ',a,' open on unit: ',i7)
 1001 format ( ' GET_FIELD: Interpolating ',a,' with scheme: ',a/)
 9001 format ( ' GET_FIELD: FILE ',a,' NOT AVAILABLE'/)
 9002 format ( ' GET_FIELD: PROBLEM WITH fnom on file: ',a,' with attributes: ',a/)
 9003 format ( ' GET_FIELD: PROBLEM WITH fstouv on file: ',a,' with attributes: ',a/)
 9004 format ( ' GET_FIELD: Variable ',a,' NOT AVAILABLE')
 9005 format ( ' GET_FIELD: PROBLEM WITH ezsint'/)
!
!-----------------------------------------------------------------------
!
 999  return
      end
!

