! Compute the initial timestep
!
! The differences between firstdt and estdt are as follows:
!   firstdt does not use the base state velocity w0 since it's supposed to be 0
!   firstdt uses the sound speed time step constraint if the velocity is 0
!
! After the initial projection, we should have a source term that gives
! rise to a velocity field, and we can use the normal estdt.

module firstdt_module

  use bl_types
  use multifab_module
  use ml_layout_module
  use define_bc_module

  implicit none

  private

  public :: firstdt

contains

  subroutine firstdt(mla,the_bc_level,u,gpi,s,divU,rho0,p0,grav,gamma1bar, &
                     dx,cflfac,dt)

    use geometry, only: dm, nlevs, nlevs_radial, spherical, nr_fine
    use variables, only: rel_eps, rho_comp
    use bl_constants_module
    use probin_module, only: init_shrink, verbose
    use mk_vel_force_module

    type(ml_layout), intent(inout) :: mla
    type(bc_level) , intent(in   ) :: the_bc_level(:)
    type(multifab) , intent(in   ) ::      u(:)
    type(multifab) , intent(in   ) ::  gpi(:)
    type(multifab) , intent(in   ) ::      s(:)
    type(multifab) , intent(in   ) ::   divU(:)
    real(kind=dp_t), intent(in   ) ::      rho0(:,0:)
    real(kind=dp_t), intent(in   ) ::        p0(:,0:)
    real(kind=dp_t), intent(in   ) ::      grav(:,0:)
    real(kind=dp_t), intent(in   ) :: gamma1bar(:,0:)
    real(kind=dp_t), intent(in   ) :: dx(:,:)
    real(kind=dp_t), intent(in   ) :: cflfac
    real(kind=dp_t), intent(  out) :: dt

    type(multifab) :: force(nlevs)
    type(multifab) :: umac_dummy(nlevs,dm)
    type(multifab) :: w0mac_dummy(nlevs,dm)
    type(multifab) :: w0_force_cart_dummy(nlevs)

    logical :: is_final_update

    real(kind=dp_t), allocatable :: w0_dummy(:,:)
    real(kind=dp_t), allocatable :: w0_force_dummy(:,:)
    
    real(kind=dp_t), pointer::   uop(:,:,:,:)
    real(kind=dp_t), pointer::   sop(:,:,:,:)
    real(kind=dp_t), pointer::    fp(:,:,:,:)
    real(kind=dp_t), pointer:: divup(:,:,:,:)

    integer         :: lo(dm),hi(dm),ng_u,ng_s,ng_f,ng_dU,i,n
    integer         :: comp
    real(kind=dp_t) :: dt_proc,dt_grid,dt_lev
    real(kind=dp_t) :: umax,umax_proc,umax_grid

    allocate(w0_force_dummy(nlevs_radial,0:nr_fine-1))
    allocate(w0_dummy      (nlevs       ,0:nr_fine))
    w0_force_dummy = 0.d0
    w0_dummy = 0.d0

    do n=1,nlevs
       call multifab_build(force(n), mla%la(n), dm, 1)
       call multifab_build(w0_force_cart_dummy(n),mla%la(n),dm,1)
       call setval(w0_force_cart_dummy(n),0.d0,all=.true.)

       ! create an empty umac so we can call the vel force routine --
       ! this will not be used
       do comp=1,dm
          call multifab_build_edge(umac_dummy(n,comp), mla%la(n),1,1,comp)
          call setval(umac_dummy(n,comp), ZERO, all=.true.)
       end do

    end do
    w0_dummy(:,:) = ZERO

    if (spherical .eq. 1) then

       do n=1,nlevs
          do comp=1,dm
             call multifab_build_edge(w0mac_dummy(n,comp),mla%la(n),1,1,comp)
             call setval(w0mac_dummy(n,comp), ZERO, all=.true.)
          end do
       end do

    end if

    is_final_update = .false.
    call mk_vel_force(force,is_final_update, &
                      u,umac_dummy,w0_dummy,w0mac_dummy,gpi,s,rho_comp, &
                      rho0,grav,dx,w0_force_dummy,w0_force_cart_dummy,the_bc_level,mla)

    do n=1,nlevs
       call destroy(w0_force_cart_dummy(n))
       do comp=1,dm
          call destroy(umac_dummy(n,comp))
          if (spherical .eq. 1) then
             call destroy(w0mac_dummy(n,comp))
          end if
       end do
    end do

    ng_u  = nghost(u(1))
    ng_s  = nghost(s(1))
    ng_f  = nghost(force(1))
    ng_dU = nghost(divU(1))

    do n=1,nlevs

       dt_proc   = 1.d99
       dt_grid   = 1.d99
       umax_proc = 0.d0
       umax_grid = 0.d0
       
       do i = 1, nboxes(u(n))
          if ( multifab_remote(u(n), i) ) cycle
          uop   => dataptr(u(n), i)
          sop   => dataptr(s(n), i)
          fp    => dataptr(force(n), i)
          divup => dataptr(divU(n),i)
          lo    =  lwb(get_box(u(n), i))
          hi    =  upb(get_box(u(n), i))
          select case (dm)
          case (1)
             call firstdt_1d(n, uop(:,1,1,1), ng_u, sop(:,1,1,:), ng_s, fp(:,1,1,1), ng_f, &
                             divup(:,1,1,1), ng_dU, p0(n,:), gamma1bar(n,:), lo, hi, &
                             dx(n,:), dt_grid, umax_grid, cflfac)
          case (2)
             call firstdt_2d(n, uop(:,:,1,:), ng_u, sop(:,:,1,:), ng_s, fp(:,:,1,:), ng_f, &
                             divup(:,:,1,1), ng_dU, p0(n,:), gamma1bar(n,:), lo, hi, &
                             dx(n,:), dt_grid, umax_grid, cflfac)
          case (3)
             if (spherical .eq. 1) then
                call firstdt_3d_sphr(uop(:,:,:,:), ng_u, sop(:,:,:,:), ng_s, &
                                     fp(:,:,:,:), ng_f, divup(:,:,:,1), ng_dU, p0(1,:), &
                                     gamma1bar(1,:), lo, hi, dx(n,:), &
                                     dt_grid, umax_grid, cflfac)
             else
                call firstdt_3d(n, uop(:,:,:,:), ng_u, sop(:,:,:,:), ng_s, &
                                fp(:,:,:,:), ng_f, divup(:,:,:,1), ng_dU, p0(n,:), &
                                gamma1bar(n,:), lo, hi, dx(n,:), dt_grid, umax_grid, cflfac)
             end if
          end select
          
          dt_proc   = min(  dt_proc,   dt_grid)
          umax_proc = max(umax_proc, umax_grid)
    
       end do

       call parallel_reduce(dt_lev,   dt_proc, MPI_MIN)
       call parallel_reduce(  umax, umax_proc, MPI_MAX)
          
       if (parallel_IOProcessor() .and. verbose .ge. 1) then
          print*,"Call to firstdt for level",n,"gives dt_lev =",dt_lev
       end if
       
       dt_lev = dt_lev*init_shrink
       
       if (parallel_IOProcessor() .and. verbose .ge. 1) then
          print*, "Multiplying dt_lev by init_shrink; dt_lev =",dt_lev
       end if
       
       dt = min(dt,dt_lev)
       
       rel_eps = 1.d-8*umax

    end do

     do n=1,nlevs
        call destroy(force(n))
     end do

     deallocate(w0_force_dummy,w0_dummy)

  end subroutine firstdt

  subroutine firstdt_1d(n,u,ng_u,s,ng_s,force,ng_f,divu,ng_dU,p0,gamma1bar,lo,hi,dx,dt, &
                        umax,cfl)

    use eos_module
    use network, only: nspec
    use variables, only: rho_comp, temp_comp, spec_comp
    use geometry,  only: nr
    use bl_constants_module
    use probin_module, only: use_soundspeed_firstdt, use_divu_firstdt
    
    integer, intent(in)             :: n, lo(:), hi(:), ng_u, ng_s, ng_f, ng_dU
    real (kind = dp_t), intent(in ) ::     u(lo(1)-ng_u :)
    real (kind = dp_t), intent(in ) ::     s(lo(1)-ng_s :,:)  
    real (kind = dp_t), intent(in ) :: force(lo(1)-ng_f :)
    real (kind = dp_t), intent(in ) ::  divu(lo(1)-ng_dU:)
    real (kind = dp_t), intent(in ) :: p0(0:), gamma1bar(0:)
    real (kind = dp_t), intent(in ) :: dx(:)
    real (kind = dp_t), intent(out) :: dt, umax
    real (kind = dp_t), intent(in ) :: cfl
    
    ! local variables
    real (kind = dp_t)  :: spdx,pforcex,ux,eps,dt_divu,dt_sound,rho_min
    real (kind = dp_t)  :: gradp0,denom
    integer             :: i
    
    rho_min = 1.d-20
    
    eps = 1.0d-8
    
    spdx    = ZERO
    pforcex = ZERO
    ux      = ZERO

    dt = 1.d99
    umax = ZERO
   
    do i = lo(1), hi(1)
          
       ! compute the sound speed from rho and temp
       den_eos(1)  = s(i,rho_comp)
       temp_eos(1) = s(i,temp_comp)
       xn_eos(1,:) = s(i,spec_comp:spec_comp+nspec-1)/den_eos(1)
       
       pt_index_eos(:) = (/i, -1, -1/)

       ! dens, temp, and xmass are inputs
       call eos(eos_input_rt, den_eos, temp_eos, &
                npts, &
                xn_eos, &
                p_eos, h_eos, e_eos, & 
                cv_eos, cp_eos, xne_eos, eta_eos, pele_eos, &
                dpdt_eos, dpdr_eos, dedt_eos, dedr_eos, &
                dpdX_eos, dhdX_eos, &
                gam1_eos, cs_eos, s_eos, &
                dsdt_eos, dsdr_eos, &
                .false., &
                pt_index_eos)
       
       spdx    = max(spdx,cs_eos(1))
       pforcex = max(pforcex,abs(force(i)))
       ux      = max(ux,abs(u(i)))

    enddo
    
    umax = max(umax,ux)

    ux = ux / dx(1)
    
    spdx = spdx / dx(1)

    ! advective constraint
    if (ux .ne. ZERO) then
       dt = cfl / ux
    else if (spdx .ne. ZERO) then
       dt = cfl / spdx
    end if

    ! sound speed constraint
    if (use_soundspeed_firstdt) then
       if (spdx .eq. ZERO) then
          dt_sound = 1.d99
       else
          dt_sound = cfl / spdx
       end if
       dt = min(dt,dt_sound)
    end if
    
    ! force constraints
    if (pforcex > eps) dt = min(dt,sqrt(2.0D0*dx(1)/pforcex))
    
    ! divU constraint
    if (use_divu_firstdt) then
       
       dt_divu = 1.d99
       
       do i = lo(1), hi(1)
          if (i .eq. 0) then
             gradp0 = (p0(i+1) - p0(i))/dx(1)
          else if (i .eq. nr(n)-1) then
             gradp0 = (p0(i) - p0(i-1))/dx(1)
          else
             gradp0 = HALF*(p0(i+1) - p0(i-1))/dx(1)
          endif
          
          denom = divU(i) - u(i)*gradp0/(gamma1bar(i)*p0(i))
          if (denom > ZERO) then
             dt_divu = min(dt_divu,0.4d0*(ONE - rho_min/s(i,rho_comp))/denom)
          endif
       enddo
    
       dt = min(dt,dt_divu)

    end if

  end subroutine firstdt_1d
  
  subroutine firstdt_2d(n,u,ng_u,s,ng_s,force,ng_f,divu,ng_dU,p0,gamma1bar,lo,hi,dx,dt, &
                        umax,cfl)

    use eos_module
    use network, only: nspec
    use variables, only: rho_comp, temp_comp, spec_comp
    use geometry,  only: nr
    use bl_constants_module
    use probin_module, only: use_soundspeed_firstdt, use_divu_firstdt
    
    integer, intent(in)             :: n, lo(:), hi(:), ng_u, ng_s, ng_f, ng_dU
    real (kind = dp_t), intent(in ) ::     u(lo(1)-ng_u :,lo(2)-ng_u :,:)  
    real (kind = dp_t), intent(in ) ::     s(lo(1)-ng_s :,lo(2)-ng_s :,:)  
    real (kind = dp_t), intent(in ) :: force(lo(1)-ng_f :,lo(2)-ng_f :,:)
    real (kind = dp_t), intent(in ) ::  divu(lo(1)-ng_dU:,lo(2)-ng_dU:)
    real (kind = dp_t), intent(in ) :: p0(0:), gamma1bar(0:)
    real (kind = dp_t), intent(in ) :: dx(:)
    real (kind = dp_t), intent(out) :: dt, umax
    real (kind = dp_t), intent(in ) :: cfl
    
    ! local variables
    real (kind = dp_t)  :: spdx,spdy,pforcex,pforcey,ux,uy,eps,dt_divu,dt_sound,rho_min
    real (kind = dp_t)  :: gradp0,denom
    integer             :: i,j

    rho_min = 1.d-20
    
    eps = 1.0d-8
    
    spdx    = ZERO
    spdy    = ZERO
    pforcex = ZERO
    pforcey = ZERO
    ux      = ZERO
    uy      = ZERO

    dt = 1.d99
    umax = ZERO
    
    do j = lo(2), hi(2)
       do i = lo(1), hi(1)
          
          ! compute the sound speed from rho and temp
          den_eos(1)  = s(i,j,rho_comp)
          temp_eos(1) = s(i,j,temp_comp)
          xn_eos(1,:) = s(i,j,spec_comp:spec_comp+nspec-1)/den_eos(1)

          pt_index_eos(:) = (/i, j, -1/)
          
          ! dens, temp, and xmass are inputs
          call eos(eos_input_rt, den_eos, temp_eos, &
                   npts, &
                   xn_eos, &
                   p_eos, h_eos, e_eos, & 
                   cv_eos, cp_eos, xne_eos, eta_eos, pele_eos, &
                   dpdt_eos, dpdr_eos, dedt_eos, dedr_eos, &
                   dpdX_eos, dhdX_eos, &
                   gam1_eos, cs_eos, s_eos, &
                   dsdt_eos, dsdr_eos, &
                   .false., &
                   pt_index_eos)
          
          spdx    = max(spdx,cs_eos(1))
          spdy    = max(spdy,cs_eos(1))
          pforcex = max(pforcex,abs(force(i,j,1)))
          pforcey = max(pforcey,abs(force(i,j,2)))
          ux      = max(ux,abs(u(i,j,1)))
          uy      = max(uy,abs(u(i,j,2)))

       enddo
    enddo
    
    umax = max(umax,ux,uy)

    ux = ux / dx(1)
    uy = uy / dx(2)
    
    spdx = spdx / dx(1)
    spdy = spdy / dx(2)

    ! advective constraint
    if (ux .ne. ZERO .or. uy .ne. ZERO) then
       dt = cfl / max(ux,uy)
    else if (spdx .ne. ZERO .and. spdy .ne. ZERO) then
       dt = cfl / max(spdx,spdy)
    end if

    ! sound speed constraint
    if (use_soundspeed_firstdt) then
       if (spdx .eq. ZERO .and. spdy .eq. ZERO) then
          dt_sound = 1.d99
       else
          dt_sound = cfl / max(spdx,spdy)
       end if
       dt = min(dt,dt_sound)
    end if
    
    ! force constraints
    if (pforcex > eps) dt = min(dt,sqrt(2.0D0*dx(1)/pforcex))
    if (pforcey > eps) dt = min(dt,sqrt(2.0D0*dx(2)/pforcey))
    
    ! divU constraint
    if (use_divu_firstdt) then
       
       dt_divu = 1.d99
       
       do j = lo(2), hi(2)
          if (j .eq. 0) then
             gradp0 = (p0(j+1) - p0(j))/dx(2)
          else if (j .eq. nr(n)-1) then
             gradp0 = (p0(j) - p0(j-1))/dx(2)
          else
             gradp0 = HALF*(p0(j+1) - p0(j-1))/dx(2)
          endif
          
          do i = lo(1), hi(1)
             denom = divU(i,j) - u(i,j,2)*gradp0/(gamma1bar(j)*p0(j))
             if (denom > ZERO) then
                dt_divu = min(dt_divu,0.4d0*(ONE - rho_min/s(i,j,rho_comp))/denom)
             endif
          enddo
       enddo
    
       dt = min(dt,dt_divu)

    end if

  end subroutine firstdt_2d
  
  subroutine firstdt_3d(n,u,ng_u,s,ng_s,force,ng_f,divU,ng_dU,p0,gamma1bar,lo,hi,dx,dt, &
                        umax,cfl)

    use geometry,  only: spherical, nr, dr, nr_fine
    use variables, only: rho_comp, temp_comp, spec_comp
    use eos_module
    use network, only: nspec
    use bl_constants_module
    use probin_module, only: use_soundspeed_firstdt, use_divu_firstdt
    use fill_3d_module

    integer           , intent(in)  :: n,lo(:), hi(:), ng_u, ng_s, ng_f, ng_dU
    real (kind = dp_t), intent(in ) ::     u(lo(1)-ng_u :,lo(2)-ng_u :,lo(3)-ng_u :,:)
    real (kind = dp_t), intent(in ) ::     s(lo(1)-ng_s :,lo(2)-ng_s :,lo(3)-ng_s :,:)
    real (kind = dp_t), intent(in ) :: force(lo(1)-ng_f :,lo(2)-ng_f :,lo(3)-ng_f :,:)
    real (kind = dp_t), intent(in ) ::  divU(lo(1)-ng_dU:,lo(2)-ng_dU:,lo(3)-ng_dU:) 
    real (kind = dp_t), intent(in ) :: p0(0:), gamma1bar(0:)
    real (kind = dp_t), intent(in ) :: dx(:)
    real (kind = dp_t), intent(out) :: dt, umax
    real (kind = dp_t), intent(in ) :: cfl
    
    ! local variables
    real (kind = dp_t)  :: spdx,spdy,spdz,pforcex,pforcey,pforcez,ux,uy,uz
    real (kind = dp_t)  :: eps,dt_divu,dt_sound,gradp0,denom,rho_min
    integer             :: i,j,k

    eps = 1.0d-8
    
    rho_min = 1.d-20
    
    spdx    = ZERO
    spdy    = ZERO 
    spdz    = ZERO 
    pforcex = ZERO 
    pforcey = ZERO 
    pforcez = ZERO 
    ux      = ZERO
    uy      = ZERO
    uz      = ZERO
    
    dt = 1.d99
    umax = ZERO

    do k = lo(3), hi(3)
       do j = lo(2), hi(2)
          do i = lo(1), hi(1)

             ! compute the sound speed from rho and temp
             den_eos(1) = s(i,j,k,rho_comp)
             temp_eos(1) = s(i,j,k,temp_comp)
             xn_eos(1,:) = s(i,j,k,spec_comp:spec_comp+nspec-1)/den_eos(1)

             pt_index_eos(:) = (/i, j, k/)
             
             ! dens, temp, and xmass are inputs
             call eos(eos_input_rt, den_eos, temp_eos, &
                      npts, &
                      xn_eos, &
                      p_eos, h_eos, e_eos, & 
                      cv_eos, cp_eos, xne_eos, eta_eos, pele_eos, &
                      dpdt_eos, dpdr_eos, dedt_eos, dedr_eos, &
                      dpdX_eos, dhdX_eos, &
                      gam1_eos, cs_eos, s_eos, &
                      dsdt_eos, dsdr_eos, &
                      .false., &
                      pt_index_eos)
             
             spdx    = max(spdx,cs_eos(1))
             spdy    = max(spdy,cs_eos(1))
             spdz    = max(spdz,cs_eos(1))
             pforcex = max(pforcex,abs(force(i,j,k,1)))
             pforcey = max(pforcey,abs(force(i,j,k,2)))
             pforcez = max(pforcez,abs(force(i,j,k,3)))
             ux      = max(ux,abs(u(i,j,k,1)))
             uy      = max(uy,abs(u(i,j,k,2)))
             uz      = max(uz,abs(u(i,j,k,3)))

          enddo
       enddo
    enddo

    umax = max(umax,ux,uy,uz)

    ux = ux / dx(1)
    uy = uy / dx(2)
    uz = uz / dx(3)
    
    spdx = spdx / dx(1)
    spdy = spdy / dx(2)
    spdz = spdz / dx(3)
    
    ! advective constraint
    if (ux .ne. ZERO .or. uy .ne. ZERO .or. uz .ne. ZERO) then
       dt = cfl / max(ux,uy,uz)
    else if (spdx .ne. ZERO .and. spdy .ne. ZERO .and. spdz .ne. ZERO) then
       dt = cfl / max(spdx,spdy,spdz)
    end if

    ! sound speed constraint
    if (use_soundspeed_firstdt) then
       if (spdx .eq. ZERO .and. spdy .eq. ZERO .and. spdz .eq. ZERO) then
          dt_sound = 1.d99
       else
          dt_sound = cfl / max(spdx,spdy,spdz)
       end if
       dt = min(dt,dt_sound)
    end if

    ! force constraints
    if (pforcex > eps) dt = min(dt,sqrt(2.0D0*dx(1)/pforcex))
    if (pforcey > eps) dt = min(dt,sqrt(2.0D0*dx(2)/pforcey))
    if (pforcez > eps) dt = min(dt,sqrt(2.0D0*dx(3)/pforcez))
    
    ! divU constraint
    if (use_divu_firstdt) then

       dt_divu = 1.d99
       
       do k = lo(3), hi(3)
          if (k .eq. 0) then
             gradp0 = (p0(k+1) - p0(k))/dx(3)
          else if (k .eq. nr(n)-1) then
             gradp0 = (p0(k) - p0(k-1))/dx(3)
          else
             gradp0 = HALF*(p0(k+1) - p0(k-1))/dx(3)
          endif
          
          do j = lo(2), hi(2)
             do i = lo(1), hi(1)
                denom = divU(i,j,k) - u(i,j,k,3)*gradp0/(gamma1bar(k)*p0(k))
                if (denom > ZERO) then
                   dt_divu = min(dt_divu,0.4d0*(ONE - rho_min/s(i,j,k,rho_comp))/denom)
                endif
             enddo
          enddo
       enddo
       
       dt = min(dt,dt_divu)

    end if

  end subroutine firstdt_3d

  subroutine firstdt_3d_sphr(u,ng_u,s,ng_s,force,ng_f,divU,ng_dU,p0,gamma1bar,lo,hi,dx, &
                             dt,umax,cfl)

    use geometry,  only: nr, dr, nr_fine
    use variables, only: rho_comp, temp_comp, spec_comp
    use eos_module
    use network, only: nspec
    use bl_constants_module
    use probin_module, only: use_soundspeed_firstdt, use_divu_firstdt
    use fill_3d_module

    integer           , intent(in)  :: lo(:), hi(:), ng_u, ng_s, ng_f, ng_dU
    real (kind = dp_t), intent(in ) ::      u(lo(1)-ng_u :,lo(2)-ng_u :,lo(3)-ng_u :,:)
    real (kind = dp_t), intent(in ) ::      s(lo(1)-ng_s :,lo(2)-ng_s :,lo(3)-ng_s :,:)
    real (kind = dp_t), intent(in ) ::  force(lo(1)-ng_f :,lo(2)-ng_f :,lo(3)-ng_f :,:)
    real (kind = dp_t), intent(in ) ::   divU(lo(1)-ng_dU:,lo(2)-ng_dU:,lo(3)-ng_dU:) 
    real (kind = dp_t), intent(in ) :: p0(0:), gamma1bar(0:)
    real (kind = dp_t), intent(in ) :: dx(:)
    real (kind = dp_t), intent(out) :: dt, umax
    real (kind = dp_t), intent(in ) :: cfl
    
    ! local variables
    real (kind = dp_t)  :: spdx,spdy,spdz,pforcex,pforcey,pforcez,ux,uy,uz 
    real (kind = dp_t)  :: gp_dot_u,gamma1bar_p_avg,eps,dt_divu,dt_sound,denom,rho_min
    integer             :: i,j,k,r

    real (kind = dp_t), allocatable :: gp0_cart(:,:,:,:)

    real (kind = dp_t) :: gp0(0:nr_fine)

    allocate(gp0_cart(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3),3))

    eps = 1.0d-8
    
    rho_min = 1.d-20
    
    spdx    = ZERO
    spdy    = ZERO 
    spdz    = ZERO 
    pforcex = ZERO 
    pforcey = ZERO 
    pforcez = ZERO 
    ux      = ZERO
    uy      = ZERO
    uz      = ZERO
    
    dt = 1.d99
    umax = ZERO

    do k = lo(3), hi(3)
       do j = lo(2), hi(2)
          do i = lo(1), hi(1)

             ! compute the sound speed from rho and temp
             den_eos(1) = s(i,j,k,rho_comp)
             temp_eos(1) = s(i,j,k,temp_comp)
             xn_eos(1,:) = s(i,j,k,spec_comp:spec_comp+nspec-1)/den_eos(1)

             pt_index_eos(:) = (/i, j, k/)
             
             ! dens, temp, and xmass are inputs
             call eos(eos_input_rt, den_eos, temp_eos, &
                      npts, &
                      xn_eos, &
                      p_eos, h_eos, e_eos, & 
                      cv_eos, cp_eos, xne_eos, eta_eos, pele_eos, &
                      dpdt_eos, dpdr_eos, dedt_eos, dedr_eos, &
                      dpdX_eos, dhdX_eos, &
                      gam1_eos, cs_eos, s_eos, &
                      dsdt_eos, dsdr_eos, &
                      .false., &
                      pt_index_eos)
             
             spdx    = max(spdx,cs_eos(1))
             spdy    = max(spdy,cs_eos(1))
             spdz    = max(spdz,cs_eos(1))
             pforcex = max(pforcex,abs(force(i,j,k,1)))
             pforcey = max(pforcey,abs(force(i,j,k,2)))
             pforcez = max(pforcez,abs(force(i,j,k,3)))
             ux      = max(ux,abs(u(i,j,k,1)))
             uy      = max(uy,abs(u(i,j,k,2)))
             uz      = max(uz,abs(u(i,j,k,3)))

          enddo
       enddo
    enddo

    umax = max(umax,ux,uy,uz)

    ux = ux / dx(1)
    uy = uy / dx(2)
    uz = uz / dx(3)
    
    spdx = spdx / dx(1)
    spdy = spdy / dx(2)
    spdz = spdz / dx(3)
    
    ! advective constraint
    if (ux .ne. ZERO .or. uy .ne. ZERO .or. uz .ne. ZERO) then
       dt = cfl / max(ux,uy,uz)
    else if (spdx .ne. ZERO .and. spdy .ne. ZERO .and. spdz .ne. ZERO) then
       dt = cfl / max(spdx,spdy,spdz)
    end if

    ! sound speed constraint
    if (use_soundspeed_firstdt) then
       if (spdx .eq. ZERO .and. spdy .eq. ZERO .and. spdz .eq. ZERO) then
          dt_sound = 1.d99
       else
          dt_sound = cfl / max(spdx,spdy,spdz)
       end if
       dt = min(dt,dt_sound)
    end if

    ! force constraints
    if (pforcex > eps) dt = min(dt,sqrt(2.0D0*dx(1)/pforcex))
    if (pforcey > eps) dt = min(dt,sqrt(2.0D0*dx(2)/pforcey))
    if (pforcez > eps) dt = min(dt,sqrt(2.0D0*dx(3)/pforcez))
    
    ! divU constraint
    if (use_divu_firstdt) then

       dt_divu = 1.d99

       ! spherical divU constraint
       do r=1,nr_fine-1
          gamma1bar_p_avg = HALF * (gamma1bar(r)*p0(r) + gamma1bar(r-1)*p0(r-1))
          gp0(r) = ( (p0(r) - p0(r-1))/dr(1) ) / gamma1bar_p_avg
       end do
       gp0(nr_fine) = gp0(nr_fine-1)
       gp0(      0) = gp0(        1)
       
       call put_1d_array_on_cart_3d_sphr(.true.,.true.,gp0,gp0_cart,lo,hi,dx,0)
       
       do k = lo(3), hi(3)
          do j = lo(2), hi(2)
             do i = lo(1), hi(1)
                
                gp_dot_u = u(i,j,k,1) * gp0_cart(i,j,k,1) + &
                           u(i,j,k,2) * gp0_cart(i,j,k,2) + &
                           u(i,j,k,3) * gp0_cart(i,j,k,3)
                   
                denom = divU(i,j,k) - gp_dot_u 
                
                if (denom > ZERO) then
                   dt_divu = min(dt_divu,0.4d0*(ONE - rho_min/s(i,j,k,rho_comp))/denom)
                endif
                
             enddo
          enddo
       enddo

       dt = min(dt,dt_divu)

    end if

    deallocate(gp0_cart)

  end subroutine firstdt_3d_sphr
  
end module firstdt_module
