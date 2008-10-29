! This is a general interface for doing runtime diagnostics on the state.
! It is called at the end of advance

module diag_module

  use bl_types
  use multifab_module
  use ml_layout_module

  implicit none

  private

  public :: diag

contains

  subroutine diag(time,dt,dx,s,u,normal)

    use bl_prof_module
    use geometry, only: dm, nlevs

    real(kind=dp_t), intent(in   ) :: dt,dx(:,:),time
    type(multifab) , intent(in   ) :: s(:)
    type(multifab) , intent(in   ) :: u(:)
    type(multifab) , intent(in   ) :: normal(:)


    ! Local
    real(kind=dp_t), pointer::  sp(:,:,:,:)
    real(kind=dp_t), pointer::  up(:,:,:,:)
    real(kind=dp_t), pointer::  np(:,:,:,:)

    integer :: lo(dm),hi(dm),ng_s,ng_u,ng_n
    integer :: i,n

    type(bl_prof_timer), save :: bpt

    call build(bpt, "diagnostics")

    ng_s = s(1)%ng
    ng_u = u(1)%ng
    ng_n = normal(1)%ng

    do n = 1, nlevs
       do i = 1, s(n)%nboxes
          if ( multifab_remote(s(n), i) ) cycle
          sp => dataptr(s(n) , i)
          up => dataptr(u(n) , i)
          np => dataptr(normal(n) , i)

          lo =  lwb(get_box(s(n), i))
          hi =  upb(get_box(s(n), i))

          select case (dm)
          case (2)
             call diag_2d(time,dt,dx(n,:), &
                          sp(:,:,1,:),ng_s, &
                          up(:,:,1,:),ng_u, &
                          np(:,:,1,:),ng_n, &
                          lo,hi)
          case (3)
             call diag_3d(time,dt,dx(n,:), &
                          sp(:,:,:,:),ng_s, &
                          up(:,:,:,:),ng_u, &
                          np(:,:,:,:),ng_n, &
                          lo,hi)
          end select
       end do
    end do

    call destroy(bpt)

  end subroutine diag

  subroutine diag_2d(time,dt,dx,s,ng_s,u,ng_u,normal,ng_n,lo,hi)

    use variables, only: rho_comp, spec_comp, temp_comp, rhoh_comp
    use network, only: nspec

    integer, intent(in) :: lo(:), hi(:), ng_s, ng_u, ng_n
    real (kind = dp_t), intent(in   ) ::      s(lo(1)-ng_s:,lo(2)-ng_s:,:)
    real (kind = dp_t), intent(in   ) ::      u(lo(1)-ng_u:,lo(2)-ng_u:,:)
    real (kind = dp_t), intent(in   ) :: normal(lo(1)-ng_n:,lo(2)-ng_n:,:)
    real (kind = dp_t), intent(in   ) :: time, dt, dx(:)

    !     Local variables
    integer            :: i, j

    do j = lo(2), hi(2)
       do i = lo(1), hi(1)

          ! do diagnostics here
          !
          ! access state variables as:
          !   s(i,j,rho_comp)
          !
          ! access velocity components as:
          !   u(i,j,1), u(i,j,2), u(i,j,3)
          !
          ! access normal vector as:
          !   normal(i,j,1), normal(i,j,2), normal(i,j,3)
          
       enddo
    enddo

  end subroutine diag_2d

  subroutine diag_3d(time,dt,dx,s,ng_s,u,ng_u,normal,ng_n,lo,hi)

    use variables, only: rho_comp, spec_comp, temp_comp, rhoh_comp
    use network, only: nspec

    integer, intent(in) :: lo(:), hi(:), ng_s, ng_u, ng_n
    real (kind = dp_t), intent(in   ) ::      s(lo(1)-ng_s:,lo(2)-ng_s:,lo(3)-ng_s:,:)
    real (kind = dp_t), intent(in   ) ::      u(lo(1)-ng_u:,lo(2)-ng_u:,lo(3)-ng_u:,:)
    real (kind = dp_t), intent(in   ) :: normal(lo(1)-ng_n:,lo(2)-ng_n:,lo(3)-ng_n:,:)
    real (kind = dp_t), intent(in   ) :: time, dt, dx(:)

    !     Local variables
    integer            :: i, j, k

    do k = lo(3), hi(3)
       do j = lo(2), hi(2)
          do i = lo(1), hi(1)

             ! do diagnostics here
             !
             ! access state variables as:
             !   s(i,j,k,rho_comp)
             !
             ! access velocity components as:
             !   u(i,j,k,1), u(i,j,k,2), u(i,j,k,3)
             !
             ! access normal vector as:
             !   normal(i,j,k,1), normal(i,j,k,2), normal(i,j,k,3)

          enddo
       enddo
    enddo

  end subroutine diag_3d

end module diag_module
