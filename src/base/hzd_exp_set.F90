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

!**s/r hzd_exp_set

      subroutine hzd_exp_set
      implicit none
#include <arch_specific.hf>


#include "glb_ld.cdk"
#include "hzd.cdk"
#include "dcst.cdk"
#include "cstv.cdk"
#include "lun.cdk"
#include "ver.cdk"

      character*256 str1
      integer i,j,k,ind1,ind2,npin,nvalid
      integer, dimension(:) , allocatable :: pwr, lvl
      real   , dimension(:) , allocatable :: lnr
      real*8 c_8, x1, x2, rr, weight
      real levhyb,coef
      real*8 pt25,nudif,epsilon
      parameter (epsilon = 1.0d-12, pt25=0.25d0)
!
!     ---------------------------------------------------------------
!
      call hzd_exp_geom

      if ( Hzd_type_S .eq. 'HO_EXP5P' ) call hzd_exp5p_set

      if ( Hzd_type_S .eq. 'HO_EXP9P' ) then

         npin= 0
         do i=1,HZD_MAXPROF
            if ( Hzd_prof_S(i) .ne. "NIL") npin= npin+1
         end do

         allocate (lnr(npin+2), lvl(npin+2), pwr(npin+2))
         allocate (Hzd_del(G_nk+1), Hzd_visco_8(G_nk+1))

         if (npin.gt.0) then
            nvalid= 1
            do i=1,npin
               call low2up (Hzd_prof_S(i),str1)
               ind1 = index(str1,'DEL')
               ind2 = index(str1,'.')
               if ((ind1.ne.1).or.(ind2.ne.5)) cycle
               str1=str1(4:)
               ind1 = index(str1,'@')
               if (ind1.eq.0) cycle
               
               nvalid= nvalid+1
               read(str1(1:1     ),*) pwr(nvalid)
               read(str1(2:ind1-1),*) lnr(nvalid)
               read(str1(ind1+1: ),*) levhyb
               do k=1,G_nk+1
                  lvl(nvalid)=k
                  if (Ver_hyb%m(k) .gt. levhyb) exit
               end do
               if (lvl(nvalid).lt.G_nk+1) lvl(nvalid)=lvl(nvalid)-1
            end do
            call sorthzdexp (lvl(2),pwr(2),lnr(2),nvalid-1)
            pwr(1) = pwr(2)
            lnr(1) = lnr(2)
            lvl(1) = 1
            pwr(nvalid+1) = pwr(nvalid)
            lnr(nvalid+1) = lnr(nvalid)
            lvl(nvalid+1) = G_nk+1
            nvalid = nvalid+1
         else
            pwr(1) = Hzd_pwr
            lnr(1) = Hzd_lnR
            lvl(1) = 1
            pwr(2) = Hzd_pwr
            lnr(2) = Hzd_lnR
            lvl(2) = G_nk+1
            nvalid = 2
         endif

         Hzd_del(1) = pwr(1)
         do i=1,nvalid-1
            Hzd_del(lvl(i)+1:lvl(i+1)) = pwr(i+1)
            if (lvl(i+1).eq.lvl(i)) then
               Hzd_visco_8(lvl(i):lvl(i+1)) = lnr(i)
            else
               x2 = lvl(i+1)
               x1 = lvl(i)
               rr = x2-x1
               do k=lvl(i),lvl(i+1)
                  weight = (k-x1)/rr
                  Hzd_visco_8(k) = weight*lnr(i+1) + (1.0d0-weight)*lnr(i)
               end do
            endif
         end do

         do k=1,G_nk+1
            Hzd_visco_8(k)= min(max(0.d0,Hzd_visco_8(k)),0.9999999d0)
            Hzd_del(k) = Hzd_del(k) / 2
            Hzd_del(k) = min(max(2,Hzd_del(k)*2),8)
         end do

! Vertical variation of Hzd_del will be implemented later
! For now we set it to minval(Hzd_del(1:G_nk+1))

         ind1   = minval(Hzd_del(1:G_nk+1))
         Hzd_del= ind1

         i=G_ni/2
         j=G_nj/2
         c_8= min ( G_xg_8(i+1) - G_xg_8(i), G_yg_8(j+1) - G_yg_8(j) )

         if (Lun_out.gt.0) then
            write(Lun_out,1000)
            if (npin.gt.0) then
               write (Lun_out,1011)
               do k=1,G_nk+1
                  coef= (2./c_8)**Hzd_del(k) / (-log(1.- Hzd_visco_8(k)))
                  write (Lun_out,1012) k,Hzd_del(k),Hzd_visco_8(k),&
                  (Dcst_rayt_8**2.)/(Cstv_dt_8*coef),Hzd_del(k)/2
               end do
            else
               nudif= log(1.- Hzd_lnR)
               nudif= 1.0d0 - exp(nudif)

               nudif= pt25*nudif**(2.d0/Hzd_pwr)
               nudif= min ( nudif, pt25-epsilon)
               nudif= min ( nudif, pt25 )

               write(Lun_out,1010)  &
               nudif*((Dcst_rayt_8*c_8)**2)/Cstv_dt_8 ,Hzd_pwr/2,'U,V,W,ZD'
            endif

            nudif= log(1.- Hzd_lnR_tr)
            nudif= 1.0d0 - exp(nudif)

            nudif= pt25*nudif**(2.d0/Hzd_pwr_tr)
            nudif= min ( nudif, pt25-epsilon)
            nudif= min ( nudif, pt25 )
            
            write(Lun_out,1010)  &
            nudif*((Dcst_rayt_8*c_8)**2)/Cstv_dt_8 ,Hzd_pwr_tr/2,'tracers'

            nudif= log(1.- Hzd_lnR_theta)
            nudif= 1.0d0 - exp(nudif)
            
            nudif= pt25*nudif**(2.d0/Hzd_pwr_theta)
            nudif= min ( nudif, pt25-epsilon)
            nudif= min ( nudif, pt25 )
            
            write(Lun_out,1010)  &
            nudif*((Dcst_rayt_8*c_8)**2)/Cstv_dt_8 ,Hzd_pwr_theta/2,'theta'
            
         endif

      endif

 1000 format (3X,'For the 9 points diffusion operator:')
 1010 format (3X,'Diffusion Coefficient =  (',e15.10,' m**2)**',i1,'/sec ',a )
 1011 format (/' VERTICAL PROFILE OF HORIZONTAL DIFFUSION PWR/LNR: '/, &
               2x,'level',3x,'PWR',7x,'LNR',10x,'COEFFICIENT')
 1012 format (1x,i4,3x,i4,6x,f7.5,3x,'(',e15.10,' m**2)**',i1,'/sec ')
!
!     ---------------------------------------------------------------
      return
      end

      subroutine sorthzdexp (F_lvl,F_pwr,F_lnr,nk)
      implicit none
#include <arch_specific.hf>
!
      integer nk
      integer F_lvl(nk),F_pwr(nk)
      real    F_lnr(nk)
!
      integer k,i,m,j,n,x1
      real x2
!
!----------------------------------------------------------------------
!
      n = nk
      do i = 1, n-1
         k = i
         do j = i+1, n
            if (F_lvl(k) .gt. F_lvl(j))  k=j
         enddo
         if (k .ne. i) then
            x2     = F_lnr(k)
            x1     = F_lvl(k)
            m      = F_pwr(k)
            F_lvl(k) = F_lvl(i)
            F_pwr(k) = F_pwr(i)
            F_lnr(k) = F_lnr(i)
            F_lvl(i) = x1
            F_pwr(i) = m
            F_lnr(i) = x2
         endif
      enddo
!
!----------------------------------------------------------------------
!
      return
      end
