!*****************************************************************************
! Module containing routines to describe Boscarino's linear system in "ON A 
! CLASS OF UNIFORMLY ACCURATE IMEX RUNGE–KUTTA SCHEMES AND APPLICATIONS TO 
! HYPERBOLIC SYSTEMS WITH RELAXATION" pg 11, equations 31a/b. 31a was modified 
! to be of the form "u_t+v_x=(b*u+c*v)/epsilon"
!******************************************************************************
! REQUIRED FILES:
! PRECISION_VARS.F90            *DEFINES PRECISION FOR ALL VARIABLES
!******************************************************************************

      module Boscarino31_Mod 

      use precision_vars, only: wp,two,pi

      implicit none; save
  
      private
      public    ::  Boscarino31

!--------------------------------VARIABLES-------------------------------------         
      real(wp)  :: dx
      real(wp),               parameter :: sig0 = -1.0_wp
      real(wp),               parameter :: sig1 = +1.0_wp
      real(wp),               parameter :: a=0.5_wp!, c=1.0_wp
!      real(wp),               parameter :: b=-0.25_wp*(a+c)**2
      
      integer,  parameter    :: vecl=256 !must be even     
      real(wp), dimension(vecl/2) :: x      
      real(wp), parameter :: xL=-1.0_wp,xR=1.0_wp

      real(wp), dimension(4), parameter :: d1vec0= (/-24.0_wp/17.0_wp,  &
                                                  &  +59.0_wp/34.0_wp,  &
                                                  &   -4.0_wp/17.0_wp,  &
                                                  &   -3.0_wp/34.0_wp/)
                                                                      
      real(wp), dimension(4), parameter :: d1vec1= (/+ 3.0_wp/34.0_wp,  &
                                                  &  + 4.0_wp/17.0_wp,  &
                                                  &  -59.0_wp/34.0_wp,  &
                                                  &  +24.0_wp/17.0_wp/)

      integer, dimension(:), allocatable ::  jap_mat 
      real(wp), dimension(:), allocatable :: ap_mat
      integer, dimension(vecl+1) :: iap_mat
!------------------------------------------------------------------------------      
      contains    
!==============================================================================
!******************************************************************************
! Subroutine to Initialize, calculate the RHS, and calculate the Jacobian
! of the Burgers problem 
!******************************************************************************
! REQUIRED FILES:
! PRECISION_VARS.F90        *DEFINES PRECISION FOR ALL VARIABLES
! CONTROL_VARIABLES.F90     *CONTAINS VARIABLES AND ALLOCATION ROUTINES
!******************************************************************************

      subroutine Boscarino31(programStep,nveclen,ep,dt, &
     &                   tfinal,iDT,time,resE_vec,resI_vec,akk)

      use control_variables, only: temporal_splitting,probname,Jac_case, &
     &                             tol,dt_error_tol,uvec,uexact
      use SBP_Coef_Module,   only: Define_CSR_Operators,D1_per
      use unary_mod,         only: rperm,aplsca
      use Jacobian_CSR_Mod,  only: Allocate_CSR_Storage,  iaJac, jaJac,  aJac

!-----------------------VARIABLES----------------------------------------------
      integer,  intent(in   ) :: programStep

      !INIT vars     
      real(wp), intent(in   ) :: ep
      real(wp), intent(inout) :: dt
      integer,  intent(  out) :: nveclen
      real(wp), intent(  out) :: tfinal
      real(wp), intent(in   ) :: time
      integer,  intent(in   ) :: iDT

      real(wp)                :: tinitial
      integer, dimension(vecl+1) :: itemp,itemp2
      integer, dimension(vecl)   :: jtemp,perm,jtemp2
      integer                    :: i
      
      !RHS vars
      real(wp), dimension(vecl), intent(  out) :: resE_vec,resI_vec
      
      !Jacob vars
      real(wp), intent(in   ) :: akk
      integer, dimension(vecl) :: iw
      real(wp), dimension(size(ap_mat)+vecl/2) :: wrk
      integer,  dimension(size(ap_mat)+vecl/2) :: jwrk
      integer,  dimension(vecl+1)              :: iwrk
      

      integer :: nnz_Jac
!------------------------------------------------------------------------------

      !**Pre-initialization. Get problem name and vector length**
      if (programStep==-1) then
        nveclen = vecl
        probname='Boscar_31'     
        tol=1.0e-12_wp  
        dt_error_tol=5.0e-14_wp
        Jac_case='SPARSE'
        
        call grid()           

      !**Initialization of problem information**        
      elseif (programStep==0) then

        if(.not. allocated(D1_per)) call Define_CSR_Operators(vecl/2,dx)   

        tinitial=0.0_wp  ! initial time
        tfinal = 1.0_wp  ! final time           
!        dt = 0.00005_wp*0.1_wp/10**((iDT-1)/20.0_wp) ! timestep
        dt = 0.50_wp*0.1_wp/10**((iDT-1)/20.0_wp)
        
        ! Set IC's
        uvec(1:vecl/2)=sin(two*pi*x(:))
        uvec(vecl/2+1:vecl)=a*sin(two*pi*x(:))+(a**2 - 1)*two*pi*cos(two*pi*x(:))
        
 !       itemp=(/ (i, i=1,vecl+1) /)
!        jtemp=(/ (i, i=1,vecl) /)
!        perm(1)=1
!        do i=2,vecl
!          !even
!          if (MOD(i,2)==0) then
!            perm(i)=perm(i-1)+vecl/2
!          !odd
!          elseif (MOD(i,2)==1) then
!            perm(i)=perm(i-1)+1-vecl/2
!          endif
!        enddo          
!        perm(vecl/2+1)=2
!        do i=2,vecl
!          if (i==vecl/2+1) cycle
!          perm(i)=perm(i-1) + 2
!        enddo
!        print*,perm
!        print*,'uvec',uvec
!        call rperm(vecl,uvec,jtemp,itemp,uvec,jtemp2,itemp2,perm,1)
!        print*,'uvec',uvec
!        stop 
        call exact_Bosc(uexact,ep,tfinal) !set exact solution at tfinal
              
      !**RHS and Jacobian**
      elseif (programStep>=1) then

        select case (Temporal_Splitting)
        
          case('EXPLICIT')
            !**RHS**
            if (programStep==1 .or.programStep==2) then
              call Bosc_dUdt(uvec,resE_vec,ep,dt)
              resI_vec(:)=0.0_wp
            endif
                          
          case('IMPLICIT') ! For fully implicit schemes
            !**RHS**
            if (programStep==1 .or.programStep==2) then
               call Bosc_dUdt(uvec,resI_vec,ep,dt)
               resE_vec(:)=0.0_wp
      
            !**Jacobian**
            elseif (programStep==3) then
            
               nnz_Jac=size(ap_mat)+vecl/2


               call Allocate_CSR_Storage(vecl,nnz_Jac)
               
           !    allocate(wrk(size(ap_mat)))
              
              wrk=-akk*dt*ap_mat   
              jwrk(1:size(jap_mat))=jap_mat
              jwrk(size(jap_mat)+1:)=0
              iwrk=iap_mat
              
       !        print*,size(wrk),size(jap_mat),size(iap_mat),size(iw),vecl                                             !6
               call aplsca(vecl,wrk,jwrk,iwrk,1.0_wp,iw)                          !7       
                   
       !         print*,wrk
               iaJac=iwrk
               jaJac=jwrk
               aJac= wrk!ap_mat!
       !        print*,size(aJac),size(iajac),size(jajac)
               
        !      stop
       !  !      deallocate(wrk)
    !          stop
          !      print*,'size ap_mat',size(ap_mat)
          !      print*,ap_mat
                
          !      do i=1,size(ap_mat)
                 ! if (abs(ap_mat(i))>1e-10) then
          !          print*,ap_mat(i),jap_mat(i)
                 ! endif
           !     enddo
                
                
         !      stop
!               call Build_Jac(uvec,ep,dt,akk,time)          

            endif
!          
!          case('IMEX')
!            if (programstep==1 .or. programstep==2) then
!               call Bosc_dUDt(uvec,resI_vec,ep,dt)
!               resE_vec(:)=0.0_wp
!
!            elseif( programStep==3) then
!            
!               call Allocate_CSR_Storage(vecl,nnz_D2)
!              call Build_Jac(uvec,ep,dt,akk,time)
!              
!            endif
!                      
          case default ! To catch invald inputs
            write(*,*)'Invaild case entered. Enter "EXPLICIT", "IMPLICIT"'!, or "IMEX"'
            write(*,*)'Exiting'
            stop
            
        end select
        
      endif
      
      end subroutine Boscarino31
!==============================================================================
!==============================================================================
!==============================================================================
! PRODUCES GRID
      subroutine grid()
      integer :: i
      
      do i=1,vecl/2
        x(i)= xL + (xR-xL)*(i-1.0_wp)/(vecl/2-1.0_wp)
      enddo
      
      dx=x(2)-x(1)

      end subroutine grid
!==============================================================================
! RETURNS VECTOR WITH EXACT SOLUTION
      subroutine exact_Bosc(u,eps,time)

      real(wp),                  intent(in   ) :: eps,time
      real(wp), dimension(vecl), intent(  out) :: u
      integer                                  :: i

      u(:)=0.0_wp
      !HACK
!      do i = 1,vecl
!        u(i) =  NL_Burg_exactsolution(x(i),time,eps)
!      enddo

      end subroutine exact_Bosc

!==============================================================================
! DEFINES RHS 
      subroutine Bosc_dUdt(u,dudt,eps,dt)!,ap_mat,jap_mat,iap_mat)
      
      use SBP_Coef_Module, only: D1_per,jD1_per,iD1_per, Pinv
      use matvec_module,   only: amux
      use unary_mod,       only: aplb, dperm, csort

      real(wp), dimension(vecl), intent(in   ) :: u
      real(wp), dimension(vecl), intent(  out) :: dudt
      real(wp),                  intent(in   ) :: eps, dt
           
      real(wp), dimension(vecl/2) :: wrk1,wrk2
      integer,  dimension(vecl/2) :: jwrk1,jwrk2
      
      real(wp), dimension(size( D1_per)) :: UR_D1,LL_D1
      integer,  dimension(size(jD1_per)) :: UR_jD1,LL_jD1
       
      real(wp), dimension(vecl) :: wrk3
      integer,  dimension(vecl) :: jwrk3,j_perm
      
      real(wp), dimension(2*size( D1_per)) :: wrk4
      integer,  dimension(2*size( D1_per)) :: jwrk4
      
!      real(wp), dimension(2*size(D1_per)+vecl), intent(out) :: ap_mat
!      integer,  dimension(2*size(D1_per)+vecl), intent(out) :: jap_mat
      
      real(wp), dimension(2*size(D1_per)+vecl) :: a_mat
      integer,  dimension(2*size(D1_per)+vecl) :: iw,ja_mat
      
      integer,  dimension(vecl+1) :: iwrk1,iwrk2,UR_iD1,LL_iD1,iwrk3,iwrk4
      integer,  dimension(vecl+1) :: ia_mat
 !     integer, dimension(vecl+1), intent(out) :: iap_mat 
           
      integer,  dimension(4*size(D1_per)+2*vecl) :: iwork           
           
      integer,dimension(3) :: ierr
      integer              :: i

!------------------------------------------------------------------------------
      if (.not. allocated(ap_mat)) then
      allocate(ap_mat(2*size(D1_per)+vecl),jap_mat(2*size(D1_per)+vecl))
! Set lower right diagaonal
! | | |
! | |x|
      wrk1(:)=-1.0_wp/eps
      iwrk1(:vecl/2)   = 1
      iwrk1(vecl/2+1:) = (/ (i, i=1, vecl/2+1) /)
      jwrk1(:)=(/ (i, i=vecl/2+1, vecl) /)
!      print*,wrk1
!      print*,'iwrk1',iwrk1
!      print*,'jwrk1',jwrk1

! Set lower left diagonal
! | | |
! |x| |
      wrk2(:)=a/eps
      iwrk2(:vecl/2)   = 1
      iwrk2(vecl/2+1:) = (/ (i, i=1, vecl/2+1) /)
      jwrk2(:)=(/ (i, i=1, vecl/2) /)      
!      print*,wrk2
!      print*,'iwrk2',iwrk2
!      print*,'jwrk2',jwrk2
      
! Set upper right D1
! | |x|
! | | |      
      UR_D1=(-1.0_wp)*D1_per
      UR_iD1(:vecl/2+1)=iD1_per
      UR_iD1(vecl/2+2:)=iD1_per(vecl/2+1)
      UR_jD1=jD1_per(:)+vecl/2
!      print*,'UR  D1',UR_D1
!      print*,'UR iD1',UR_iD1
!      print*,'UR jD1',UR_jD1
      
! Set lower left D1
! | | |
! |x| |      
      LL_D1=(-1.0_wp)*D1_per
      LL_iD1(:vecl/2)=1
      LL_iD1(vecl/2+1:)=iD1_per
      LL_jD1=jD1_per
!      print*,'LL  D1',LL_D1
!      print*,'LL iD1',LL_iD1
!      print*,'LL jD1',LL_jD1

! Add all matricies
      ! combine both diagonals
      ! | | |
      ! |x|x|
      call aplb(vecl,vecl,1,wrk2,jwrk2,iwrk2,wrk1,jwrk1,iwrk1,wrk3,jwrk3,iwrk3,vecl,iw,ierr(1))
!     print*,'wrk3',wrk3
!      print*,'iwrk3',iwrk3
!      print*,'jwrk3',jwrk3
      
      ! combine both D1's
      ! | |x|
      ! |x| |
      call aplb(vecl,vecl,1,LL_D1,LL_jD1,LL_iD1,UR_D1,UR_jD1,UR_iD1,wrk4,jwrk4,iwrk4,2*size(D1_per),iw,ierr(2))
!      print*,'wrk4',wrk4
!      print*,'iwrk4',iwrk4
!      print*,'jwrk4',jwrk4      
       
      ! combine diagonals and D1's
      ! | |x|
      ! |x|x|
      call aplb(vecl,vecl,1,wrk3,jwrk3,iwrk3,wrk4,jwrk4,iwrk4,a_mat,ja_mat,ia_mat,2*size(D1_per)+vecl,iw,ierr(3)) 
!      print*,' a',a_mat
!      print*,'ia',ia_mat
!      print*,'ja',ja_mat     
      
! permiate matrix into:
! |x| |
! | |x|

      j_perm(1)=1
      j_perm(vecl/2+1)=2
      do i=2,vecl
        if (i==vecl/2+1) cycle
        j_perm(i)=j_perm(i-1) + 2
      enddo
!      print*,'jperm',j_perm

!HACK
      call dperm(vecl,a_mat,ja_mat,ia_mat,ap_mat,jap_mat,iap_mat,j_perm,j_perm,1)
!      iap_mat=ia_mat
!      jap_mat=ja_mat
!      ap_mat=a_mat
!HACK

      call csort(vecl,ap_mat,jap_mat,iap_mat,iwork,.true.)     
!      print*,' ap_mat',ap_mat
!      print*,'jap_mat',jap_mat
!      print*,'iap_mat',iap_mat

! get dudt

      endif


      
      call amux(vecl,u,dudt,ap_mat,jap_mat,iap_mat)
   
      dudt(:)=dt*dudt(:)      
      
      if (sum(ierr)/=0) then ! Catch errors
        print*,'Error building dudt'
        stop
      endif
  
      end subroutine Bosc_dUdt
      
!==============================================================================
! CREATES JACOBIAN
      subroutine Build_Jac(u,eps,dt,akk,time)

      use SBP_Coef_Module,  only: D1,D2,jD1,jD2,iD1,iD2!    Pinv,   
    !  use matvec_module,    only: amux
      use unary_mod,        only: aplb,aplsca!,amudia,diamua,apldia
      use Jacobian_CSR_Mod, only: iaJac,jaJac,aJac
      
      real(wp), dimension(vecl), intent(in) :: u
      real(wp),                  intent(in) :: eps,dt,akk,time    
        
      integer,  dimension(size(iaJac))  :: iwrk1,iwrk2,iwrk3,iJac
      integer,  dimension(size(jaJac))  :: jwrk1,jwrk2,jwrk3,jJac
      real(wp), dimension(size( aJac))  :: wrk1,wrk2,wrk3,Jac,wrk4,eps_d2      
      
      integer,  dimension(vecl)  :: iw
      real(wp), dimension(vecl)  :: diag
      integer,  dimension(1)     :: ierr
      real(wp)                   :: uL,a1_d,uR,a0_d,a0,a1
      integer                    :: nnz_max
!------------------------------------------------------------------------------ 
      nnz_max=size(aJac)
     

!******Steps to make xjac******
!       jac=eps*d2-2/3*d1*u-1/3*u*d1-1/3*diag(d1*u)+dgsat/du
!1      wrk1=-2/3*d1*u
!2      wrk2=-1/3*u*d1
!3      wrk3=wrk1+wrk2
!4      eps_d2=eps*d2
!5      jac=eps_d2+wrk3-1/3*diag(d1*u)+dgsat/du
!6      wrk4=-akk*dt*jac
!
!       xjac=I-akk*dt*jac=-akk*dt*jac+(1)*I
!7      xjac=wrk4+(1)*I
! 
!8      xjac-> wrk4, iJac, jJac
!******************************
! --------------Make xjac -----------------------------------------------------
!      call amudia(vecl,1,D1,jD1,iD1,u,wrk1,jwrk1,iwrk1)                   !1
!      wrk1(:)=-twothird*wrk1(:)                                              !1
!      
!      call diamua(vecl,1,D1,jD1,iD1,u,wrk2,jwrk2,iwrk2)                   !2
!      wrk2(:)=-third*wrk2(:)                                                 !2
!      
!      call aplb(vecl,vecl,1,wrk1,jwrk1,iwrk1,wrk2,jwrk2,iwrk2,wrk3,&   !3
!     &          jwrk3,iwrk3,nnz_max,iw,ierr(1))                               !3
!
!      eps_d2=eps*D2(:)                                                       !4
      call aplb(vecl,vecl,1,eps*(1-a**2)*D2,jD2,iD2,(-1.0_wp)*D1,jD1,iD1,Jac,&     !5a
     &          jJac,iJac,nnz_max,iw,ierr(1))                                !5a
!
!      call amux(vecl,-third*u,diag,D1,jD1,iD1) !First-derivative of u vec!5b
!      call apldia(vecl,0,Jac,jJac,iJac,diag,Jac,jJac,iJac,iw)            !5b
!
!     ! R - 5c
!      Jac(1)=Jac(1)+sig0*Pinv(1)*(a0+a0_d*(uR- &
!     &       NL_Burg_exactsolution(x(1),time,eps))) 
!      Jac(1:4)=Jac(1:4)+sig0*Pinv(1)*(-eps)*d1vec0(:)/dx
!      
!      ! L - 5c
!      Jac(nnz_max)=Jac(nnz_max)+sig1*Pinv(vecl)*(a1+a1_d*(uL- &
!     &            NL_Burg_exactsolution(x(vecl),time,eps))) 
!      Jac(nnz_max-3:nnz_max)=Jac(nnz_max-3:nnz_max)+ &
!     &                     sig1*Pinv(vecl)*(-eps)*d1vec1(:)/dx
!     
      wrk4=-akk*dt*Jac                                                       !6
      call aplsca(vecl,wrk4,jJac,iJac,1.0_wp,iw)                          !7
!
      !8
      iaJac=iJac
      jaJac=jJac
      aJac=wrk4
!-----------------------------------------------------------------------------  
      if (sum(ierr)/=0) then ! Catch errors
        print*,'Error building Jacobian'
        stop
      endif
   
      end subroutine Build_Jac
      
!==============================================================================
      end module Boscarino31_mod
