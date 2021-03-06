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

!**s/r px_param - to return A,B values given a list of keys tagged to records
!                 in a RPN standard file

      integer function px_param ( iun,fstkeys,ip1,fstkeys_max,ip1_max,hyb_8 , &
                                  staglevs,a_8,b_8,vcode_S,vcode,diag_lvl_L )
      use vGrid_Descriptors, only: vgrid_descriptor,vgd_new,vgd_get,VGD_OK,vgd_print
      implicit none
#include <arch_specific.hf>

      logical diag_lvl_L
      integer iun,fstkeys_max,ip1_max,vcode
      integer ip1(fstkeys_max),fstkeys(fstkeys_max)
      real*8  hyb_8(fstkeys_max),hybm_8(fstkeys_max)
      real*8  a_8(fstkeys_max),b_8(fstkeys_max)
      character*1 staglevs
      character*8 vcode_S

!author
!     V.Lee July 2008 (from GEMDM, hybrid code)
!     and contributions from Andre Plante, Cecilien Charette
!
!revision
! ________________________________________________________________
!  Name        I/O      Description
! ----------------------------------------------------------------
! iun           I       unit number to input RPNstd file
! fstkeys       I       list of keys tagged to records from RPNstd file
! fstkeys_max   I       number of keys in fstkeys given
! ip1           O       list of ip1 codes sorted by real level values and
!                       redundant levels are eliminated
! ip1_max       O       number of ip1 codes returned
! hyb_8         O       list of level values as decoded by convip for ip1
! a_8           O       list of A coefficients for each level
! b_8           O       list of B coefficients for each level
! vcode         O       code number for type of vertical coordinate
!                        0=pressure
!                        1=SIGMA 
!                        2=ETASEF (eta for spectral)
!                        3=SIGPT  (eta, rcoef=1.0)
!                        4=HYBLG  (hybrid Laprise/Girard)
!                        5=ECMWF  (ecmwf levels)
!                        6=HYBSTAG(staggered hybrid Girard)
! vcode_S       O       name of vertical coordinate found
! ----------------------------------------------------------------
! the function will return 0 upon success, -1 if there is an error

      integer   fstinf, fstprm, fstlir, fstluk, fnom, &
                read_decode_hyb,read_decode_bang
      external  fstinf, fstprm, fstlir, fstluk, fnom, &
                read_decode_hyb,read_decode_bang
      integer  ni,nj,nk,ni1,nj1,nk1,i,j,k,n,m,ip1x,ip2x,ip3x
      integer  e1_key,hy_key,pt_key,p0_key,xx_key
      integer  datev, dateo, deet, ipas, ip1a, ip2a, ip3a,  &
               ig1a, ig2a, ig3a, ig4a, bit, datyp, &
               swa, lng, dlf, ubc, ex1, ex2, ex3, kind, ip1mode, status
      real     rcoef(2),lev,ptop,pref,pr1
      real*8   x1_8,etatop_8,eta1_8,ptop_8,pref_8,pr1_8,pr2_8,rcoef_8(2)
      character*1  tva, grda, blk_S
      character*4  var
      character*12 etik_S
      logical found
      type(vgrid_descriptor) :: vgd

      integer,dimension(:), pointer :: lookup_ip1
      real,   dimension(:,:), allocatable :: work
      real*8, dimension(:), pointer :: lookup_a_8,lookup_b_8
      real*8, dimension(:,:),allocatable:: work_8
!
! ---------------------------------------------------------------------
!
      nullify(lookup_ip1,lookup_a_8,lookup_b_8)
      px_param=0
      rcoef(1)=0.0
      rcoef(2)=0.0
      pref=0.0
      ptop=0.0
      etatop_8=0.0d0
      ptop_8=0.0d0
      pref_8=0.0d0
      rcoef_8(1)=0.0d0
      rcoef_8(2)=0.0d0

      diag_lvl_L = .false.
      do k=1,fstkeys_max
         px_param = fstprm ( fstkeys(k), dateo, deet, ipas, ni, nj, nk,&
                    bit, datyp, ip1a,ip2a,ip3a, tva, var, etik_S, grda,&
                 ig1a,ig2a,ig3a,ig4a, swa,lng, dlf, ubc, ex1, ex2, ex3 )
         if (px_param.lt.0) then
             print *,'px_param error: fstprm on key',fstkeys(k)
             return
         endif
         call convip (ip1a, lev, i,-1, blk_S, .false.)
         if (k.eq.1) kind=i
         if ((k.eq.fstkeys_max).and.(i.eq.4)) diag_lvl_L = .true.
         ip1(k)=ip1a
         hyb_8(k)=lev
      enddo
      
      call incdatr(datev,dateo,ipas*deet/3600.0d0)

!     Sort levels in ascending order
      if (fstkeys_max.gt.1) then
         n = fstkeys_max
         do i = 1, n-1
            k = i
            do j = i+1, n
               if (hyb_8(k) .gt. hyb_8(j))  k=j
            enddo
            if (k .ne. i) then
               x1_8     = hyb_8(k)
               m      = ip1(k)
               hyb_8(k) = hyb_8(i)
               ip1(k)  = ip1(i)
               hyb_8(i) = x1_8
               ip1(i)  = m
            endif
         enddo
!   AND  Eliminate levels that are redundant in LISTE
         i = 1
         do j=2,n
            if (hyb_8(i) .ne. hyb_8(j)) then
                i = i+1
                if (i .ne. j) then
                    hyb_8(i) = hyb_8(j)
                     ip1(i) =  ip1(j)
                endif
            endif
         enddo
         ip1_max = i
      else
         ip1_max = 1 
      endif

      hy_key=fstinf (iun,ni,nj,nk,datev,' ',-1,  -1,  -1,' ','HY')
      pt_key=fstinf (iun,ni,nj,nk,datev,' ',-1,  -1,  -1,' ','PT')
      e1_key=fstinf (iun,ni,nj,nk,datev,' ',-1,  -1,  -1,' ','E1')
      if (kind.eq.1) then
          rcoef_8(1) = 1.0
          rcoef_8(2) = 1.0
          pref_8  = 800.0
          p0_key=fstinf (iun,ni,nj,nk,datev,etik_S,-1,ip2a,ip3a,' ','P0')
          if (p0_key.lt.0) then
                 print *,'px_param error: No p0 found, kind = 1'
                 px_param = -1
                 return
          endif
          if (hy_key.ge.0) then
              vcode_S='HYBLG'
              vcode = 4
              px_param=read_decode_hyb (iun,'HY',  -1,  -1,' ', &
                                                 datev,ptop,pref,rcoef(1))
              if (px_param.lt.0) then
                  print *,'px_param error: in read_decode_hyb'
                  return
              endif
              ptop_8=ptop
              pref_8=pref
              rcoef_8(1) = rcoef(1)
              rcoef_8(2) = rcoef(2)
          else if (pt_key.ge.0) then
               allocate (work(ni,nj))
               px_param = fstluk(work,pt_key,ni,nj,nk)
               if (px_param.lt.0) then
                   print *,'px_param error: in fstluk PT'
                   return
               endif
               ptop = work(1,1)
               ptop_8 = work(1,1)
               deallocate (work)
               if (e1_key.ge.0) then
                   allocate (work(ni,nj))
                   px_param = fstluk(work,e1_key,ni,nj,nk)
                   if (px_param.lt.0) then
                       print *,'px_param error: in fstluk E1'
                       return
                   endif
                   etatop_8 = work(1,1)
                   deallocate (work)
                   vcode_S='ETASEF'
                   vcode = 2
                   eta1_8=1.0d0 / (1.0d0 - etatop_8)
                   do i=1,ip1_max
                      b_8(i) = (hyb_8(i) - etatop_8)*eta1_8 
                      a_8(i) = ptop_8*100.0d0* (1.0d0 - b_8(i))
                   enddo
               else
                vcode_S='SIGPT' !pure ETA
                vcode = 3
                do i=1,ip1_max
                   b_8(i) = hyb_8(i)
                   a_8(i) = ptop_8*100.0d0* (1.0d0 - hyb_8(i))
                enddo
               endif
          else 
               vcode_S='SIGMA'
               vcode = 1
               do i=1,ip1_max
                  a_8(i) = 0.0d0
                  b_8(i) = hyb_8(i) 
               enddo
          endif
      endif

      if (kind.eq.2) then
         vcode_S='PRESS'
         vcode = 0
         do i=1,ip1_max
            a_8(i) = hyb_8(i)
            b_8(i) = 0.0
         enddo
      endif

      if (kind.eq.5) then
         rcoef(1) = 1.0
         rcoef(2) = 1.0
         pref_8  = 800.0
         ptop_8=0.0
!         xx_key=fstinf (iun,ni, nj, nk, -1,' ',ig1a,ig2a,-1 ,' ','!!  ')
         xx_key=fstinf (iun,ni, nj, nk, -1,' ',-1,-1,-1 ,' ','!!  ')
         if (xx_key.ge.0) then
             status = vgd_new (vgd,unit=iun,format='fst',ip1=-1,ip2=-1)
             if (status /= VGD_OK) then
                print*, 'px_param error: cannot build coordinate descriptor'
                return
             endif
             status =          vgd_get(vgd,key='CA_'//stagLevs,value=lookup_a_8)
             status = status + vgd_get(vgd,key='CB_'//stagLevs,value=lookup_b_8)
             status = status + vgd_get(vgd,key='VIP'//stagLevs,value=lookup_ip1)
             if (status /= VGD_OK) then
                print*, 'px_param error: cannot retrieve info from !!'
                return
             endif

!             status = vgd_print (vgd)
             do i=1,size(ip1)
                j = 1; found = .false.
                do while (.not.found .and. j<=minval((/size(lookup_a_8),size(lookup_b_8),size(lookup_ip1)/)))
                   if (ip1(i).eq.lookup_ip1(j)) then                         
                      a_8(i)=lookup_a_8(j)
                      b_8(i)=lookup_b_8(j)
                      found = .true.
                   endif
                   j = j+1
                enddo
             enddo
             deallocate(lookup_a_8,lookup_b_8,lookup_ip1)
             nullify(lookup_a_8,lookup_b_8,lookup_ip1)

             if (.not.found) then
                print*, 'px_param error: cannot match ip1 to a/b coefs: ',ip1(i)
                return
             endif
             status = vgd_get(vgd,key='PREF - reference pressure',value=pref_8)
             status = status + vgd_get(vgd,key='RC_1 - first R-coef value',value=rcoef_8(1))
             status = status + vgd_get(vgd,key='RC_2 - second R-coef value',value=rcoef_8(2))

             if (status /= VGD_OK) then
                print*, 'px_param error: cannot retrieve coordinate details'
                return
             endif
             vcode = 6
             vcode_S='HYBSTAG'
         else if (hy_key.ge.0) then
              p0_key=fstinf (iun,ni,nj,nk,datev,etik_S,-1,ip2a,ip3a,' ','P0')
              if (p0_key.lt.0) then
                 print *,'px_param error: HY found,No p0 found, kind = 5'
                 px_param = -1
                 return
              endif
              vcode_S='HYBLG'
              vcode = 4
              px_param=read_decode_hyb (iun,'HY',  -1,  -1,' ', &
                                                 datev,ptop,pref,rcoef(1))
              if (px_param.lt.0) then
                  print *,'px_param error: in read_decode_hyb'
                  return
              endif
              ptop_8=ptop
              pref_8=pref
              rcoef_8(1) = rcoef(1)
              rcoef_8(2) = rcoef(2)
         else
             print *,'px_param error: kind=5 but !! or !!sf  or HY NOT FOUND'
             px_param = -1
             return
         endif
      endif
      if ( vcode.eq.4 ) then
           if (kind.eq.1) then
               do i=1,ip1_max
                  hybm_8(i) = hyb_8(i) + (1.0d0 - hyb_8(i))*ptop_8/pref_8
               enddo
           endif
           if ( kind.eq.5 ) then
               do i=1,ip1_max
                  hybm_8(i) = hyb_8(i)
               enddo
           endif
           pr2_8 = ptop_8/hybm_8(1)
           pr1_8 = 1.0d0/(1.0d0 - hybm_8(1))
           do i=1,ip1_max
              b_8(i) = ( (hybm_8(i) - hybm_8(1)) * pr1_8)**rcoef_8(1)
              a_8(i) = pr2_8 * 100.0d0* (hybm_8(i) - b_8(i) )
           enddo
      endif

      px_param = 0
!
! ---------------------------------------------------------------------
!
      return
      end
