      module Jacobian_CSR_Mod
      
      use precision_vars
      
      implicit none
      
      public :: iaJac,jaJac,aJac,Allocate_CSR_Storage
      private
      
      real(wp),    parameter              ::   toljac = 1.0e-13_wp

      integer                             ::   nJac
      integer                             :: nnzJac
      logical                             :: allo_test=.false.

      integer,  allocatable, dimension(:) ::  iaJac
      integer,  allocatable, dimension(:) ::  jaJac
      real(wp), allocatable, dimension(:) ::   aJac
! Not used yet
!      integer,  allocatable, dimension(:) ::   juJac
!      integer,  allocatable, dimension(:) ::  jLUJac
!      real(wp), allocatable, dimension(:) ::  aLUJac
!      integer                             ::   ierr
!      integer,  allocatable, dimension(:) ::  iw         
      
      contains
      
!==============================================================================
      subroutine Allocate_CSR_Storage(nJac)

      integer, intent(in)  :: nJac !nJac=nveclen
      integer              :: nnzJac
      if(.not.allo_test) then
        nnzJac = nJac**2

        allocate(iaJac(nJac+1))
        allocate(jaJac(nnzJac))
        allocate( aJac(nnzJac))
! Not used yet
!        allocate( juJac(nJac+1))
!       allocate(jLUJac(nnzJac))
!       allocate(aLUJac(nnzJac))

!        allocate(iw(nJac))
      endif
      allo_test=.true.
      end subroutine
!==============================================================================
 !     subroutine Deallocate_CSR_Storage()
      
 !     deallocate(iaJac,jaJac,aJac)
! Not used yet
!      deallocate(juJac,jLUJac,aLUJac,iw)     

  !    end subroutine Deallocate_CSR_Storage

!==============================================================================
      subroutine Jacobian_CSR(nJac,xjac,iaJac,jaJac,aJac)
 
      integer,                        intent(in   ) :: nJac
      real(wp), dimension(nJac,nJac), intent(in   ) :: xjac
      real(wp), dimension(:),         intent(  out) :: iaJac,jaJac,aJac
      integer                                       :: i,j,icnt,jcnt

      call Allocate_CSR_Storage(nJac)
      
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
