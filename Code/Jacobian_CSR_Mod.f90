      module Jacobian_CSR_Mod
      
      use precision_vars,  only: wp
      
      implicit none; save
      
      public :: iaJac,jaJac,aJac,jUJac,jLUJac,aLUJac,iw,Allocate_CSR_Storage
      public :: Jacobian_CSR
      private
      
      real(wp),    parameter              ::   toljac = 1.0e-13_wp

      integer                             ::   nJac
      integer                             :: nnzJac
      logical                             :: allo_test=.false.

      integer,  allocatable, dimension(:) ::  iaJac
      integer,  allocatable, dimension(:) ::  jaJac
      real(wp), allocatable, dimension(:) ::   aJac

      integer,  allocatable, dimension(:) ::  jUJac
      integer,  allocatable, dimension(:) ::  jLUJac
      real(wp), allocatable, dimension(:) ::  aLUJac
!      integer                             ::   ierr
      integer,  allocatable, dimension(:) ::  iw         
      
      contains
      
!==============================================================================
      subroutine Allocate_CSR_Storage(nJac,nnz)
      
      integer, intent(in) :: nJac !nJac=nveclen
      integer, intent(in) :: nnz 
      
      if(.not.allo_test) then
      
        allocate(iaJac(nJac+1))
        allocate(jaJac(nnz))
        allocate( aJac(nnz))

        allocate(jUJac(nJac))
        allocate(jLUJac(nnz))
        allocate(aLUJac(nnz))

        allocate(iw(nJac))
        
      endif
      allo_test=.true.
      end subroutine

!==============================================================================
      subroutine Jacobian_CSR(nJac,xjac)
 
      integer,                  intent(in   ) :: nJac
      real(wp), dimension(:,:), intent(in   ) :: xjac
      integer                                 :: i,j,icnt,jcnt,nnz
      
      nnz=nJac

      call Allocate_CSR_Storage(nJac,nnz)

!     U_t = F(U);  Jac = \frac{\partial F(U)}{\partial U};  xjac = I - akk dt Jac

      ! Initialize CSR
      iaJac(:) = 0
      iaJac(1) = 1
      jaJac(:) = 0 
      aJac(:) = 0.0_wp
      
      ! Store dense matrix into CSR format
      icnt = 0   
      do i = 1,nJac
        jcnt = 0   
        do j = 1,nJac
          if(abs(xjac(i,j)) >= tolJac) then
            icnt = icnt + 1 
            jcnt = jcnt + 1 
             
            jaJac(icnt) = j
             aJac(icnt) = xjac(i,j)
          endif
        enddo
        iaJac(i+1) = iaJac(i) + jcnt
      enddo

      end subroutine Jacobian_CSR
!==============================================================================
      end module Jacobian_CSR_Mod