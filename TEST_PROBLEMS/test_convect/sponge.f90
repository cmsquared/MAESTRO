! a module for storing the geometric information so we don't have to pass it

module sponge_module

  use bl_types
  use multifab_module
  use ml_layout_module

  implicit none

  real(dp_t), save :: r_sp, r_md, r_tp
  real(dp_t), save :: r_sp_outer, r_tp_outer

  private

  public :: init_sponge, make_sponge

contains

  subroutine init_sponge(rho0,prob_hi,dx,prob_lo_r)

    real(kind=dp_t), intent(in   ) :: rho0(0:),prob_lo_r
    real(kind=dp_t), intent(in   ) :: prob_hi(:),dx(:)

    r_sp = 2.19140625d8
    r_tp = 2.97265625d8

    if ( parallel_IOProcessor() ) write(6,1000) r_sp, r_tp

1000 format('inner sponge: r_sp      , r_tp      : ',e20.12,2x,e20.12)

  end subroutine init_sponge

  subroutine make_sponge(nlevs,sponge,dx,dt,mla)

    use bl_constants_module
    use ml_restriction_module, only: ml_cc_restriction

    integer        , intent(in   ) :: nlevs
    type(multifab) , intent(inout) :: sponge(:)
    real(kind=dp_t), intent(in   ) :: dx(:,:),dt
    type(ml_layout), intent(in   ) :: mla

    ! Local variables
    real(kind=dp_t), pointer :: sp(:,:,:,:)
    integer :: i,dm,n,ng_sp
    integer :: lo(sponge(1)%dim),hi(sponge(1)%dim)

    dm = sponge(1)%dim
    ng_sp = sponge(1)%ng

    do n=1,nlevs

       do i = 1, sponge(n)%nboxes
          if ( multifab_remote(sponge(n), i) ) cycle
          sp => dataptr(sponge(n), i)
          lo =  lwb(get_box(sponge(n), i))
          hi =  upb(get_box(sponge(n), i))
          select case (dm)
          case (2)
             call mk_sponge_2d(sp(:,:,1,1),ng_sp,lo,hi,dx(n,:),dt)
          case (3)
             call mk_sponge_3d(sp(:,:,:,1),ng_sp,lo,hi,dx(n,:),dt)
          end select
       end do

    end do

    ! the loop over nlevs must count backwards to make sure the finer grids are done first
    do n=nlevs,2,-1
       ! set level n-1 data to be the average of the level n data covering it
       call ml_cc_restriction(sponge(n-1),sponge(n),mla%mba%rr(n-1,:))
    end do

  end subroutine make_sponge

  subroutine mk_sponge_2d(sponge,ng_sp,lo,hi,dx,dt)

    use bl_constants_module
    use probin_module, only: prob_lo_y, sponge_kappa

    integer        , intent(in   ) ::  lo(:),hi(:),ng_sp
    real(kind=dp_t), intent(inout) :: sponge(lo(1)-ng_sp:,lo(2)-ng_sp:)
    real(kind=dp_t), intent(in   ) ::     dx(:),dt

    integer         :: j
    real(kind=dp_t) :: y,smdamp

    sponge = ONE

    do j = lo(2),hi(2)
       y = prob_lo_y + (dble(j)+HALF)*dx(2)

       if (y >= r_sp) then
          if (y < r_tp) then
             smdamp = HALF*(ONE - cos(M_PI*(y - r_sp)/(r_tp - r_sp)))
          else
             smdamp = ONE
          endif
          sponge(:,j) = ONE / (ONE + dt * smdamp* sponge_kappa)
       endif

    end do

  end subroutine mk_sponge_2d

  subroutine mk_sponge_3d(sponge,ng_sp,lo,hi,dx,dt)

    use geometry, only: spherical, center
    use bl_constants_module
    use probin_module, only: prob_lo_x, prob_lo_y, prob_lo_z, sponge_kappa

    integer        , intent(in   ) :: lo(:),hi(:),ng_sp
    real(kind=dp_t), intent(inout) :: sponge(lo(1)-ng_sp:,lo(2)-ng_sp:,lo(3)-ng_sp:)
    real(kind=dp_t), intent(in   ) :: dx(:),dt

    integer         :: i,j,k
    real(kind=dp_t) :: x,y,z,r,smdamp

    sponge = ONE

    if (spherical .eq. 0) then
       do k = lo(3),hi(3)
          z = prob_lo_z + (dble(k)+HALF)*dx(3)
          if (z >= r_sp) then
             if (z < r_tp) then
                smdamp = HALF*(ONE - cos(M_PI*(z - r_sp)/(r_tp - r_sp)))
             else
                smdamp = ONE
             endif
             sponge(:,:,k) = ONE / (ONE + dt * smdamp* sponge_kappa)
          end if
       end do

    else

       do k = lo(3),hi(3)
          z = prob_lo_z + (dble(k)+HALF)*dx(3)
          do j = lo(2),hi(2)
             y = prob_lo_y + (dble(j)+HALF)*dx(2)
             do i = lo(1),hi(1)
                x = prob_lo_x + (dble(i)+HALF)*dx(1)

                r = sqrt( (x-center(1))**2 + (y-center(2))**2 + (z-center(3))**2 )

                ! Inner sponge: damps velocities at edge of star
                if (r >= r_sp) then
                   if (r < r_tp) then
                      smdamp = HALF*(ONE - cos(M_PI*(r - r_sp)/(r_tp - r_sp)))
                   else
                      smdamp = ONE
                   endif
                   sponge(i,j,k) = ONE / (ONE + dt * smdamp * sponge_kappa)
                endif

                ! Outer sponge: damps velocities at edge of domain
                if (r >= r_sp_outer) then
                   if (r < r_tp_outer) then
                      smdamp = &
                           HALF*(ONE - cos(M_PI*(r - r_sp_outer)/(r_tp_outer - r_sp_outer)))
                   else
                      smdamp = ONE
                   endif
                   sponge(i,j,k) = sponge(i,j,k) / (ONE + dt * smdamp * 10.d0 * sponge_kappa)
                endif

             end do
          end do
       end do

    end if

  end subroutine mk_sponge_3d

end module sponge_module
