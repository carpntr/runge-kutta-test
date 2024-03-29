!******************************************************************************
! Module containing global variables for test_cases.f90 as well as allocation
! and deallocation routines
!******************************************************************************
! REQUIRED FILES:
! PRECISION_VARS.F90            *DEFINES PRECISION FOR ALL VARIABLES
! SBP_COEF_MODULE.F90           *DEFINES CSR DERIVATIVE OPERATORS
!******************************************************************************

      module control_variables
      
      use precision_vars, only : wp
      
      implicit none; save
      
      private
      public :: probname, Jac_case, isamp,jmax,jactual
      public :: Temporal_splitting, Temporal_Splitting_OTD
      public :: tol,dt_error_tol
      public :: uvec,uexact,b,usum,uveco
      public :: errvec,errvecT,tmpvec
      public :: resE,resI,error,errorP,xjac,errorL2
      public :: b1save,b1Psave,b1L2save,ustage,predvec 
      public :: allocate_vars,deallocate_vars
      public :: programstep,var_names
      public :: ipred
      public :: OTD, OTDN, Ovec, Oveco, Osum, err_OTD
      public :: orth_proj, wr, wi
      public :: resE_Tens_OTD, resI_Tens_OTD
      public :: dudtE_OTD, dudtI_OTD, resE_OTD, resI_OTD, Jac_OTD
      public :: uvecS, uvecoS, xjacS
      public :: update_jac

!--------------------------VARIABLES-------------------------------------------
!     character(len=80), parameter :: Temporal_Splitting    = 'EXPLICIT'
!     character(len=80), parameter :: Temporal_Splitting    = 'IMEX' 
!     character(len=80)            :: Temporal_Splitting    = 'IMPLICIT'  
      character(len=80)            :: Temporal_Splitting    = 'FIRK'  

      character(len=80), parameter :: Temporal_Splitting_OTD= 'EXPLICIT'
!     character(len=80), parameter :: Temporal_Splitting_OTD= 'IMEX'

      character(len=17)            :: probname
      character(len=6)             :: Jac_case='DENSE' !default value
      character(len=80)            :: programstep
      integer, parameter           :: isamp  =70
      integer, parameter           :: jmax   =81     
      integer, parameter           :: jactual=81     
      integer, parameter           :: ipred  = 0

      logical                      :: update_jac = .true. !  Default value

      logical                      :: OTD    = .false.    !  Default value
      integer                      :: OTDN   = 1          !  Default value
      
      real(wp)                     :: tol,dt_error_tol

      real(wp), dimension(:),   ALLOCATABLE :: uvec,uexact,b,usum,uveco
      real(wp), dimension(:),   allocatable :: errvec,errvecT,tmpvec
      real(wp), dimension(:,:), allocatable :: resE,resI,error,errorP,xjac
      real(wp), dimension(:,:), allocatable :: b1save,b1Psave,ustage,predvec
      real(wp), dimension(:,:), allocatable :: errorL2,b1L2save

      real(wp), dimension(:,:), allocatable :: Ovec, Oveco, err_OTD, Osum
      real(wp), dimension(:,:), allocatable :: dudtE_OTD, dudtI_OTD
      real(wp), dimension(:,:), allocatable :: resE_OTD, resI_OTD, Jac_OTD
      real(wp), dimension(:,:,:), allocatable :: resE_Tens_OTD,resI_Tens_OTD
      real(wp), dimension(:),   allocatable :: orth_proj, wr, wi

!  FIRK storage variables
      real(wp), dimension(:),   allocatable :: uvecS, uvecoS
      real(wp), dimension(:,:), allocatable :: xjacS
       
      character(len=12), dimension(:), allocatable :: var_names
!------------------------------------------------------------------------------
 
      contains

!==============================================================================
!******************************************************************************
! Subroutine to allocate global variables
!******************************************************************************
! MODULE VARIABLES:
! uvec     -> Array containing variables       
! uexact   -> Array containing exact solution to variables              
! resE     -> Explicit RHS vector
! resI     -> Implicit RHS vector
! error    -> solution error
! errorP   -> solution error, predicted
! b        -> convergence rate
! errorL2  -> solution error, L2 norm
! usum     -> Array containing summation from test_cases
! xjac     -> matrix containing dense Jacobian
! ustage   -> stage value predictor
! predvec  -> stage value predictor
! uveco    -> newton iteration / usum storage (?)
! errvec   -> temporary error storage
! errvecT  -> error storage for each time step
! tmpvec   -> (uvec-uexact)
! b1save   -> convergence rate storage
! b1Psave  -> convergence rate storage, predicted
! b1L2save -> convergence rate storage, L2 norm
! isamp    -> number of dt's
! jmax     -> number of epsilon values
!******************************************************************************
! INPUTS:
! nveclen -> u-vector length,          integer
! neq     -> number of equations,      integer
! is      -> maximum number of stages, integer
!******************************************************************************
      subroutine allocate_vars(nveclen,nvecS,neq,ns,is)
      
      integer, intent(in)    :: nveclen,neq,ns,is
      integer, intent(  out) :: nvecS
    
      !**ALLOCATE VARIABLES**
      !problemsub
      AllOCATE(uvec(nveclen),uexact(nveclen),resE(nveclen,is),resI(nveclen,is))
   
      !data outs
      ALLOCATE(error(isamp,nveclen),errorP(isamp,nveclen),b(nveclen*2+neq))
      ALLOCATE(errorL2(isamp,neq))

      !Newton_iteration
      ALLOCATE(usum(nveclen),xjac(nveclen,nveclen))       

      !internal
      ALLOCATE(ustage(nveclen,is),predvec(nveclen,is),uveco(nveclen))
      ALLOCATE(errvec(nveclen),errvecT(nveclen),tmpvec(nveclen))
      ALLOCATE(b1save(jmax,nveclen),b1Psave(jmax,nveclen),b1L2save(jmax,neq))

      if(Temporal_Splitting == 'FIRK') then
        nvecS = nveclen * ns
        allocate(uvecS (nvecS      ))
        allocate(uvecoS(nvecS      ))
        allocate(xjacS (nvecS,nvecS))
      endif

      if(OTD .eqv. .true.) then 

        allocate(       wr(OTDN           ))
        allocate(       wi(OTDN           ))

        allocate(orth_proj(nveclen        ))

        allocate(Ovec     (nveclen,OTDN   ))
        allocate(Oveco    (nveclen,OTDN   ))
        allocate(Osum     (nveclen,OTDN   ))
        allocate(err_OTD  (nveclen,OTDN   ))

        allocate(dudtE_OTD(nveclen,OTDN   ))
        allocate(dudtI_OTD(nveclen,OTDN   ))
        allocate(resE_OTD (nveclen,OTDN   ))
        allocate(resI_OTD (nveclen,OTDN   ))

        allocate(resE_Tens_OTD(nveclen,OTDN,is))
        allocate(resI_Tens_OTD(nveclen,OTDN,is))

      endif

      end subroutine allocate_vars
     
!==============================================================================
!******************************************************************************
! Subroutine to deallocate global variables at end of problem loop
!******************************************************************************
! SBP_COEF_MODULE.F90       *DEFINES CSR OPERATORS 
! JACOBIAN_CSR_MOD.F90      *ALLOCATE AND STORE CSR JACOBIAN VARIABLES
!******************************************************************************
! GLOBAL VARIABLES:
! From SBP_Coef_Module:
!   Pmat,Pinv,iD1,jD1,D1,iD2,jD2,D2,D1_per,iD1_per,jD1_per,D2_per,jD2_per,iD2_per
! From Jacobian_CSR_Mod:
!   iaJac,jaJac,aJac,jUJac,jLUJac,aLUJac,iw
! 
! MODULE VARIABLES:
! uvec     -> Array containing variables       
! uexact   -> Array containing exact solution to variables              
! resE     -> Explicit RHS vector
! resI     -> Implicit RHS vector
! error    -> solution error
! errorP   -> solution error, predicted
! b        -> convergence rate
! errorL2  -> solution error, L2 norm
! usum     -> Array containing summation from test_cases
! xjac     -> matrix containing dense Jacobian
! ustage   -> stage value predictor
! predvec  -> stage value predictor
! uveco    -> newton iteration / usum storage (?)
! errvec   -> temporary error storage
! errvecT  -> error storage for each time step
! tmpvec   -> (uvec-uexact)
! b1save   -> convergence rate storage
! b1Psave  -> convergence rate storage, predicted
! b1L2save -> convergence rate storage, L2 norm
!******************************************************************************
! INPUTS:
! nveclen -> u-vector length,          integer
! neq     -> number of equations,      integer
! is      -> maximum number of stages, integer
!******************************************************************************
      subroutine deallocate_vars()
      
      use SBP_Coef_Module,  only: Pmat,Pinv,iD1,jD1,D1,iD2,jD2,D2,D1_per,&
     &                            iD1_per,jD1_per,D2_per,jD2_per,iD2_per
      use Jacobian_CSR_Mod, only: iaJac,jaJac,aJac,jUJac,jLUJac,aLUJac,iw
      
      !**DEALLOCATE VARIABLES**
      !problemsub
      DEAllOCATE(uvec,uexact,resE,resI,var_names)
      
      !data out
      DEALLOCATE(error,errorP,b,errorL2)
      
      !Newton_iteration
      DEALLOCATE(usum,xjac)   
         
      !internal
      DEALLOCATE(ustage,predvec,uveco)
      DEALLOCATE(errvec,errvecT,tmpvec,b1save,b1Psave,b1L2save)
      
      !D CSR
      if(allocated(D1)) deallocate(Pmat,Pinv,jD1,jD2,iD1,iD2,D1,D2,D1_per,&
     &                              iD1_per,jD1_per,D2_per,jD2_per,iD2_per) 
     
      !Jacobian CSR
      if(allocated(iaJac)) deallocate(iaJac,jaJac,aJac,jUJac,jLUJac,aLUJac,iw)  

      if(Temporal_Splitting == 'FIRK') then
        deallocate(uvecS,uvecoS)
        deallocate(xjacS)
      endif

      
      if(OTD .eqv. .true.) then 

        deallocate(wr,wi)                        ! dimension: (OTDN)
        deallocate(orth_proj)                    ! dimension: (nveclen)

        deallocate(Ovec,Oveco,Osum, err_OTD)     ! dimension: (nveclen,OTDN)
        deallocate(resE_OTD, resI_OTD, dudtE_OTD, dudtI_OTD)           ! dimension: (nveclen,OTDN)

        deallocate(resE_Tens_OTD,resI_Tens_OTD)                ! dimension: (nveclen,OTDN,is)

      endif

      !close all open files
     ! do i=10,900
       ! inquire(unit=i, opened=open_logical)!, iostat=io_int)
       ! if (open_logical) print*,'io_int',io_int
       ! printstop
       ! enddo                               
      
      end subroutine deallocate_vars
      
!==============================================================================
      
      end module control_variables      
