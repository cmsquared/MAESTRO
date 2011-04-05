module react_state_module

  use bl_types
  use multifab_module
  use define_bc_module
  use ml_layout_module

  implicit none

  private

  public :: react_state

contains

  subroutine react_state(mla,tempbar_init,sold,snew,rho_omegadot,rho_Hnuc,rho_Hext,p0, &
                         dt,dx,the_bc_level)

    use probin_module, only: use_tfromp
    use variables, only: temp_comp

    use multifab_fill_ghost_module
    use multifab_physbc_module, only : multifab_physbc
    use ml_restriction_module , only : ml_cc_restriction_c
    use heating_module        , only : get_rho_Hext 
    use rhoh_vs_t_module      , only : makeTfromRhoP, makeTfromRhoH

    type(ml_layout), intent(in   ) :: mla
    type(multifab) , intent(in   ) :: sold(:)
    type(multifab) , intent(inout) :: snew(:)
    type(multifab) , intent(inout) :: rho_omegadot(:)
    type(multifab) , intent(inout) :: rho_Hnuc(:)
    type(multifab) , intent(inout) :: rho_Hext(:)
    real(dp_t)     , intent(in   ) :: p0(:,0:)
    real(dp_t)     , intent(in   ) :: tempbar_init(:,0:)
    real(kind=dp_t), intent(in   ) :: dt,dx(:,:)
    type(bc_level) , intent(in   ) :: the_bc_level(:)

    ! Local
    type(bl_prof_timer), save :: bpt

    integer :: n,nlevs

    call build(bpt, "react_state")

    nlevs = mla%nlevel

    ! get heating term
    call get_rho_Hext(mla,tempbar_init,sold,rho_Hext,the_bc_level,dx,dt)

    ! do the burning
    call burner_loop(mla,tempbar_init,sold,snew,rho_omegadot,rho_Hnuc,rho_Hext,dx,dt,the_bc_level)

    ! now update temperature
    if (use_tfromp) then
       call makeTfromRhoP(snew,p0,mla,the_bc_level,dx)
    else
       call makeTfromRhoH(snew,mla,the_bc_level, dx)
    end if

    call destroy(bpt)

  end subroutine react_state

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine burner_loop(mla,tempbar_init,sold,snew,rho_omegadot,rho_Hnuc,rho_Hext,dx,dt,the_bc_level)

    use bl_constants_module, only: ZERO
    use variables, only: rho_comp, rhoh_comp, spec_comp, temp_comp, &
                         nscal, ntrac, trac_comp, foextrap_comp
    use multifab_fill_ghost_module
    use ml_restriction_module
    use multifab_physbc_module
    use network, only: nspec
    use probin_module, only: drive_initial_convection
    use geometry, only: spherical
    use fill_3d_module, only: put_1d_array_on_cart

    type(ml_layout), intent(in   ) :: mla
    type(multifab) , intent(in   ) :: sold(:)
    type(multifab) , intent(inout) :: snew(:)
    type(multifab) , intent(inout) :: rho_omegadot(:)
    type(multifab) , intent(inout) :: rho_Hnuc(:)
    type(multifab) , intent(inout) :: rho_Hext(:)
    real(kind=dp_t), intent(in   ) :: tempbar_init(:,0:)
    real(kind=dp_t), intent(in   ) :: dt,dx(:,:)
    type(bc_level) , intent(in   ) :: the_bc_level(:)

    ! Local
    real(kind=dp_t), pointer:: snp(:,:,:,:)
    real(kind=dp_t), pointer:: sop(:,:,:,:)
    real(kind=dp_t), pointer::  rp(:,:,:,:)
    real(kind=dp_t), pointer::  hnp(:,:,:,:)
    real(kind=dp_t), pointer::  hep(:,:,:,:)
    real(kind=dp_t), pointer::  tcp(:,:,:,:)

    type(multifab) :: tempbar_init_cart(mla%nlevel)

    integer :: lo(mla%dim),hi(mla%dim)
    integer :: ng_si,ng_so,ng_rw,ng_he,ng_hn,ng_tc
    integer :: dm,nlevs
    integer :: i,n

    type(bl_prof_timer), save :: bpt

    call build(bpt, "burner_loop")

    dm = mla%dim
    nlevs = mla%nlevel

    ng_si = nghost(sold(1))
    ng_so = nghost(snew(1))
    ng_rw = nghost(rho_omegadot(1))
    ng_hn = nghost(rho_Hnuc(1))
    ng_he = nghost(rho_Hext(1))

    ! put tempbar_init on Cart
    if (spherical == 1) then
       do n=1, nlevs
          ! tempbar_init_cart will hold the initial tempbar on a Cartesian
          ! grid to be used if drive_initial_convection is true
          call build(tempbar_init_cart(n),mla%la(n),1,0)
          call setval(tempbar_init_cart(n), ZERO, all=.true.)
       enddo

       if (drive_initial_convection) then
          ! fill all components
          call put_1d_array_on_cart(tempbar_init,tempbar_init_cart, &
                                    foextrap_comp,.false.,.false.,dx, &
                                    the_bc_level,mla)
       endif
    endif

    do n = 1, nlevs
       do i = 1, nboxes(sold(n))
          if ( multifab_remote(sold(n), i) ) cycle
          snp => dataptr(sold(n) , i)
          sop => dataptr(snew(n), i)
          rp => dataptr(rho_omegadot(n), i)
          hnp => dataptr(rho_Hnuc(n), i)
          hep => dataptr(rho_Hext(n), i)
          lo =  lwb(get_box(sold(n), i))
          hi =  upb(get_box(sold(n), i))
          select case (dm)
          case (1)
             call burner_loop_1d(tempbar_init(n,:), &
                                 snp(:,1,1,:),ng_si,sop(:,1,1,:),ng_so, &
                                 rp(:,1,1,:),ng_rw, &
                                 hnp(:,1,1,1),ng_hn,hep(:,1,1,1),ng_he, &
                                 dt,lo,hi)
          case (2)
             call burner_loop_2d(tempbar_init(n,:), &
                                 snp(:,:,1,:),ng_si,sop(:,:,1,:),ng_so, &
                                 rp(:,:,1,:),ng_rw, &
                                 hnp(:,:,1,1),ng_hn,hep(:,:,1,1),ng_he, &
                                 dt,lo,hi)
          case (3)
             if (spherical == 1) then
                tcp => dataptr(tempbar_init_cart(n), i)
                ng_tc = nghost(tempbar_init_cart(1))
                call burner_loop_3d_sph(tcp(:,:,:,1),ng_tc, &
                                        snp(:,:,:,:),ng_si,sop(:,:,:,:),ng_so, &
                                        rp(:,:,:,:),ng_rw, &
                                        hnp(:,:,:,1),ng_hn,hep(:,:,:,1),ng_he, &
                                        dt,lo,hi)
             else
                call burner_loop_3d(tempbar_init(n,:), &
                                    snp(:,:,:,:),ng_si,sop(:,:,:,:),ng_so, &
                                    rp(:,:,:,:),ng_rw, &
                                    hnp(:,:,:,1),ng_hn,hep(:,:,:,1),ng_he, &
                                    dt,lo,hi)
             endif
          end select
       end do
    end do

    ! pass temperature through for seeding the temperature update eos call
    do n=1,nlevs
       call multifab_copy_c(snew(n),temp_comp,sold(n),temp_comp,1,nghost(sold(n)))
    end do


    if (nlevs .eq. 1) then

       ! fill ghost cells for two adjacent grids at the same level
       ! this includes periodic domain boundary ghost cells
       call multifab_fill_boundary(snew(nlevs))

       ! fill non-periodic domain boundary ghost cells
       call multifab_physbc(snew(nlevs),rho_comp,dm+rho_comp,nscal,the_bc_level(nlevs))

    else

       ! the loop over nlevs must count backwards to make sure the finer grids are done first
       do n=nlevs,2,-1

          ! set level n-1 data to be the average of the level n data covering it
          call ml_cc_restriction(snew(n-1)        ,snew(n)        ,mla%mba%rr(n-1,:))
          call ml_cc_restriction(rho_omegadot(n-1),rho_omegadot(n),mla%mba%rr(n-1,:))
          call ml_cc_restriction(rho_Hext(n-1)    ,rho_Hext(n)    ,mla%mba%rr(n-1,:))
          call ml_cc_restriction(rho_Hnuc(n-1)    ,rho_Hnuc(n)    ,mla%mba%rr(n-1,:))

          ! fill level n ghost cells using interpolation from level n-1 data
          ! note that multifab_fill_boundary and multifab_physbc are called for
          ! both levels n-1 and n
          call multifab_fill_ghost_cells(snew(n),snew(n-1),ng_so,mla%mba%rr(n-1,:), &
                                         the_bc_level(n-1),the_bc_level(n), &
                                         rho_comp,dm+rho_comp,nscal,fill_crse_input=.false.)
       enddo

    end if

    call destroy(bpt)

    if (spherical == 1) then
       do n = 1, nlevs
          call destroy(tempbar_init_cart(n))
       enddo
    endif

  end subroutine burner_loop

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine burner_loop_1d(tempbar_init,sold,ng_si,snew,ng_so,rho_omegadot,ng_rw,rho_Hnuc,ng_hn, &
                            rho_Hext,ng_he,dt,lo,hi)

    use bl_constants_module
    use burner_module
    use variables, only: rho_comp, spec_comp, temp_comp, rhoh_comp, trac_comp, ntrac
    use network, only: nspec, network_species_index
    use probin_module, ONLY: do_burning, burning_cutoff_density, burner_threshold_species, &
         burner_threshold_cutoff, drive_initial_convection

    integer        , intent(in   ) :: lo(:),hi(:),ng_si,ng_so,ng_rw,ng_he,ng_hn
    real(kind=dp_t), intent(in   ) ::        sold (lo(1)-ng_si:,:)
    real(kind=dp_t), intent(  out) ::         snew(lo(1)-ng_so:,:)
    real(kind=dp_t), intent(  out) :: rho_omegadot(lo(1)-ng_rw:,:)
    real(kind=dp_t), intent(  out) ::     rho_Hnuc(lo(1)-ng_hn:)
    real(kind=dp_t), intent(in   ) ::     rho_Hext(lo(1)-ng_he:)
    real(kind=dp_t), intent(in   ) :: tempbar_init(0:)
    real(kind=dp_t), intent(in   ) :: dt

    !     Local variables
    integer            :: i
    real (kind = dp_t) :: rho,T_in
    real (kind = dp_t) :: x_in(nspec)
    real (kind = dp_t) :: x_out(nspec)
    real (kind = dp_t) :: rhowdot(nspec)
    real (kind = dp_t) :: rhoH
    real (kind = dp_t) :: x_test
    integer, save      :: ispec_threshold
    logical, save      :: firstCall = .true.

    if (firstCall) then
       ispec_threshold = network_species_index(burner_threshold_species)
       firstCall = .false.
    endif

    do i = lo(1), hi(1)
          
          rho = sold(i,rho_comp)
          x_in(1:nspec) = sold(i,spec_comp:spec_comp+nspec-1) / rho

          if (drive_initial_convection) then
             T_in = tempbar_init(i)
          else
             T_in = sold(i,temp_comp)
          endif

          ! Fortran doesn't guarantee short-circuit evaluation of logicals so
          ! we need to test the value of ispec_threshold before using it 
          ! as an index in x_in
          if (ispec_threshold > 0) then
             x_test = x_in(ispec_threshold)
          else
             x_test = ZERO
          endif

          ! if the threshold species is not in the network, then we burn
          ! normally.  if it is in the network, make sure the mass
          ! fraction is above the cutoff.
          if (do_burning .and.                                        &
              rho > burning_cutoff_density .and.                      &
              ( ispec_threshold < 0 .or.                              &
               (ispec_threshold > 0 .and.                             &
                x_test > burner_threshold_cutoff                      &
               )                                                      &
              )                                                       &
             ) then
             call burner(rho, T_in, x_in, dt, x_out, rhowdot, rhoH)
          else
             x_out = x_in
             rhowdot = 0.d0
             rhoH = 0.d0
          endif

          ! pass the density through
          snew(i,rho_comp) = sold(i,rho_comp)

          ! update the species
          snew(i,spec_comp:spec_comp+nspec-1) = x_out(1:nspec) * rho

          ! store the energy generation and species creation quantities
          rho_omegadot(i,1:nspec) = rhowdot(1:nspec)
          rho_Hnuc(i) = rhoH

          ! update the enthalpy -- include the change due to external heating
          snew(i,rhoh_comp) = sold(i,rhoh_comp) + dt*rho_Hnuc(i) + dt*rho_Hext(i)

          ! pass the tracers through
          snew(i,trac_comp:trac_comp+ntrac-1) = sold(i,trac_comp:trac_comp+ntrac-1)   
          
    enddo

  end subroutine burner_loop_1d

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine burner_loop_2d(tempbar_init,sold,ng_si,snew,ng_so,rho_omegadot,ng_rw,rho_Hnuc,ng_hn, &
                            rho_Hext,ng_he,dt,lo,hi)

    use bl_constants_module
    use burner_module
    use variables, only: rho_comp, spec_comp, temp_comp, rhoh_comp, trac_comp, ntrac
    use network, only: nspec, network_species_index
    use probin_module, ONLY: do_burning, burning_cutoff_density, burner_threshold_species, &
         burner_threshold_cutoff, drive_initial_convection

    integer        , intent(in   ) :: lo(:),hi(:),ng_si,ng_so,ng_rw,ng_he,ng_hn
    real(kind=dp_t), intent(in   ) ::        sold (lo(1)-ng_si:,lo(2)-ng_si:,:)
    real(kind=dp_t), intent(  out) ::         snew(lo(1)-ng_so:,lo(2)-ng_so:,:)
    real(kind=dp_t), intent(  out) :: rho_omegadot(lo(1)-ng_rw:,lo(2)-ng_rw:,:)
    real(kind=dp_t), intent(  out) ::     rho_Hnuc(lo(1)-ng_hn:,lo(2)-ng_hn:)
    real(kind=dp_t), intent(in   ) ::     rho_Hext(lo(1)-ng_he:,lo(2)-ng_he:)
    real(kind=dp_t), intent(in   ) :: tempbar_init(0:)
    real(kind=dp_t), intent(in   ) :: dt

    !     Local variables
    integer            :: i, j
    real (kind = dp_t) :: rho,T_in
    real (kind = dp_t) :: x_in(nspec)
    real (kind = dp_t) :: x_out(nspec)
    real (kind = dp_t) :: rhowdot(nspec)
    real (kind = dp_t) :: rhoH
    real (kind = dp_t) :: x_test
    integer, save      :: ispec_threshold
    logical, save      :: firstCall = .true.

    if (firstCall) then
       ispec_threshold = network_species_index(burner_threshold_species)
       firstCall = .false.
    endif

    do j = lo(2), hi(2)
       do i = lo(1), hi(1)
          
          rho = sold(i,j,rho_comp)
          x_in(1:nspec) = sold(i,j,spec_comp:spec_comp+nspec-1) / rho
          
          if (drive_initial_convection) then
             T_in = tempbar_init(j)
          else
             T_in = sold(i,j,temp_comp)
          endif

          ! Fortran doesn't guarantee short-circuit evaluation of logicals so
          ! we need to test the value of ispec_threshold before using it 
          ! as an index in x_in
          if (ispec_threshold > 0) then
             x_test = x_in(ispec_threshold)
          else
             x_test = ZERO
          endif

          ! if the threshold species is not in the network, then we burn
          ! normally.  if it is in the network, make sure the mass
          ! fraction is above the cutoff.
          if (do_burning .and.                                        &
              rho > burning_cutoff_density .and.                      &
              ( ispec_threshold < 0 .or.                              &
               (ispec_threshold > 0 .and.                             &
                x_test > burner_threshold_cutoff                      &
               )                                                      &
              )                                                       &
             ) then
             call burner(rho, T_in, x_in, dt, x_out, rhowdot, rhoH)
          else
             x_out = x_in
             rhowdot = 0.d0
             rhoH = 0.d0
          endif

          ! pass the density through
          snew(i,j,rho_comp) = sold(i,j,rho_comp)

          ! update the species
          snew(i,j,spec_comp:spec_comp+nspec-1) = x_out(1:nspec) * rho

          ! store the energy generation and species creation quantities
          rho_omegadot(i,j,1:nspec) = rhowdot(1:nspec)
          rho_Hnuc(i,j) = rhoH

          ! update the enthalpy -- include the change due to external heating
          snew(i,j,rhoh_comp) = sold(i,j,rhoh_comp) + dt*rho_Hnuc(i,j) + dt*rho_Hext(i,j)

          ! pass the tracers through
          snew(i,j,trac_comp:trac_comp+ntrac-1) = sold(i,j,trac_comp:trac_comp+ntrac-1)   
          
       enddo
    enddo

  end subroutine burner_loop_2d

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine burner_loop_3d(tempbar_init,sold,ng_si,snew,ng_so,rho_omegadot,ng_rw,rho_Hnuc,ng_hn, &
                            rho_Hext,ng_he,dt,lo,hi)

    use bl_constants_module
    use burner_module
    use variables, only: rho_comp, spec_comp, temp_comp, rhoh_comp, trac_comp, ntrac
    use network, only: nspec, network_species_index
    use probin_module, ONLY: do_burning, burning_cutoff_density, burner_threshold_species, &
         burner_threshold_cutoff, drive_initial_convection

    integer        , intent(in   ) :: lo(:),hi(:),ng_si,ng_so,ng_rw,ng_he,ng_hn
    real(kind=dp_t), intent(in   ) ::         sold(lo(1)-ng_si:,lo(2)-ng_si:,lo(3)-ng_si:,:)
    real(kind=dp_t), intent(  out) ::         snew(lo(1)-ng_so:,lo(2)-ng_so:,lo(3)-ng_so:,:)
    real(kind=dp_t), intent(  out) :: rho_omegadot(lo(1)-ng_rw:,lo(2)-ng_rw:,lo(3)-ng_rw:,:)
    real(kind=dp_t), intent(  out) ::     rho_Hnuc(lo(1)-ng_hn:,lo(2)-ng_hn:,lo(3)-ng_hn:)
    real(kind=dp_t), intent(in   ) ::     rho_Hext(lo(1)-ng_he:,lo(2)-ng_he:,lo(3)-ng_he:)
    real(kind=dp_t), intent(in   ) :: tempbar_init(0:)
    real(kind=dp_t), intent(in   ) :: dt

    !     Local variables
    integer            :: i, j, k
    real (kind = dp_t) :: rho,T_in,ldt

    real (kind = dp_t) :: x_in(nspec)
    real (kind = dp_t) :: x_out(nspec)
    real (kind = dp_t) :: rhowdot(nspec)
    real (kind = dp_t) :: rhoH
    real (kind = dp_t) :: x_test
    integer, save      :: ispec_threshold
    logical, save      :: firstCall = .true.

    if (firstCall) then
       ispec_threshold = network_species_index(burner_threshold_species)
       firstCall = .false.
    endif

    ldt = dt

    !$OMP PARALLEL DO PRIVATE(i,j,k,rho,x_in,T_in,x_test,x_out,rhowdot,rhoH) FIRSTPRIVATE(ldt)
    do k = lo(3), hi(3)
       do j = lo(2), hi(2)
          do i = lo(1), hi(1)

             rho = sold(i,j,k,rho_comp)
             x_in = sold(i,j,k,spec_comp:spec_comp+nspec-1) / rho

             if (drive_initial_convection) then
                T_in = tempbar_init(k)
             else
                T_in = sold(i,j,k,temp_comp)
             endif
             
             ! Fortran doesn't guarantee short-circuit evaluation of logicals 
             ! so we need to test the value of ispec_threshold before using it 
             ! as an index in x_in
             if (ispec_threshold > 0) then
                x_test = x_in(ispec_threshold)
             else
                x_test = ZERO
             endif

             ! if the threshold species is not in the network, then we burn
             ! normally.  if it is in the network, make sure the mass
             ! fraction is above the cutoff.
             if (do_burning .and.                                        &
                 rho > burning_cutoff_density .and.                      &
                 ( ispec_threshold < 0 .or.                              &
                  (ispec_threshold > 0 .and.                             &
                   x_test > burner_threshold_cutoff)                     &
                 )                                                       &
                 ) then
                call burner(rho, T_in, x_in, ldt, x_out, rhowdot, rhoH)
             else
                x_out = x_in
                rhowdot = 0.d0
                rhoH = 0.d0
             endif
             
             ! pass the density through
             snew(i,j,k,rho_comp) = sold(i,j,k,rho_comp)

             ! update the species
             snew(i,j,k,spec_comp:spec_comp+nspec-1) = x_out(1:nspec) * rho
             
             ! store the energy generation and species create quantities
             rho_omegadot(i,j,k,1:nspec) = rhowdot(1:nspec)
             rho_Hnuc(i,j,k) = rhoH

             ! update the enthalpy -- include the change due to external heating
             snew(i,j,k,rhoh_comp) = sold(i,j,k,rhoh_comp) &
                  + ldt*rho_Hnuc(i,j,k) + ldt*rho_Hext(i,j,k)

             ! pass the tracers through
             snew(i,j,k,trac_comp:trac_comp+ntrac-1) = &
                  sold(i,j,k,trac_comp:trac_comp+ntrac-1)
             
          enddo
       enddo
    enddo
    !$OMP END PARALLEL DO

  end subroutine burner_loop_3d

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine burner_loop_3d_sph(tempbar_init_cart,ng_tc, &
                                sold,ng_si,snew,ng_so, &
                                rho_omegadot,ng_rw, &
                                rho_Hnuc,ng_hn,rho_Hext,ng_he, &
                                dt,lo,hi)

    use bl_constants_module
    use burner_module
    use variables, only: rho_comp, spec_comp, temp_comp, rhoh_comp, trac_comp, ntrac
    use network, only: nspec, network_species_index
    use probin_module, ONLY: do_burning, burning_cutoff_density, burner_threshold_species, &
         burner_threshold_cutoff, drive_initial_convection

    integer        , intent(in   ) :: lo(:),hi(:),ng_si,ng_so,ng_rw,ng_he,ng_hn,ng_tc
    real(kind=dp_t), intent(in   ) ::         sold(lo(1)-ng_si:,lo(2)-ng_si:,lo(3)-ng_si:,:)
    real(kind=dp_t), intent(in   ) :: tempbar_init_cart(lo(1)-ng_tc:,lo(2)-ng_tc:,lo(3)-ng_tc:)
    real(kind=dp_t), intent(  out) ::         snew(lo(1)-ng_so:,lo(2)-ng_so:,lo(3)-ng_so:,:)
    real(kind=dp_t), intent(  out) :: rho_omegadot(lo(1)-ng_rw:,lo(2)-ng_rw:,lo(3)-ng_rw:,:)
    real(kind=dp_t), intent(  out) ::     rho_Hnuc(lo(1)-ng_hn:,lo(2)-ng_hn:,lo(3)-ng_hn:)
    real(kind=dp_t), intent(in   ) ::     rho_Hext(lo(1)-ng_he:,lo(2)-ng_he:,lo(3)-ng_he:)
    real(kind=dp_t), intent(in   ) :: dt

    !     Local variables
    integer            :: i, j, k
    real (kind = dp_t) :: rho,T_in,ldt

    real (kind = dp_t) :: x_in(nspec)
    real (kind = dp_t) :: x_out(nspec)
    real (kind = dp_t) :: rhowdot(nspec)
    real (kind = dp_t) :: rhoH
    real (kind = dp_t) :: x_test
    integer, save      :: ispec_threshold
    logical, save      :: firstCall = .true.

    if (firstCall) then
       ispec_threshold = network_species_index(burner_threshold_species)
       firstCall = .false.
    endif

    ldt = dt

    !$OMP PARALLEL DO PRIVATE(i,j,k,rho,x_in,T_in,x_test,x_out,rhowdot,rhoH) FIRSTPRIVATE(ldt)
    do k = lo(3), hi(3)
       do j = lo(2), hi(2)
          do i = lo(1), hi(1)

             rho = sold(i,j,k,rho_comp)
             x_in = sold(i,j,k,spec_comp:spec_comp+nspec-1) / rho

             if (drive_initial_convection) then
                T_in = tempbar_init_cart(i,j,k)
             else
                T_in = sold(i,j,k,temp_comp)
             endif
             
             ! Fortran doesn't guarantee short-circuit evaluation of logicals 
             ! so we need to test the value of ispec_threshold before using it 
             ! as an index in x_in
             if (ispec_threshold > 0) then
                x_test = x_in(ispec_threshold)
             else
                x_test = ZERO
             endif

             ! if the threshold species is not in the network, then we burn
             ! normally.  if it is in the network, make sure the mass
             ! fraction is above the cutoff.
             if (do_burning .and.                                        &
                 rho > burning_cutoff_density .and.                      &
                 ( ispec_threshold < 0 .or.                              &
                  (ispec_threshold > 0 .and.                             &
                   x_test > burner_threshold_cutoff)                     &
                 )                                                       &
                 ) then
                call burner(rho, T_in, x_in, ldt, x_out, rhowdot, rhoH)
             else
                x_out = x_in
                rhowdot = 0.d0
                rhoH = 0.d0
             endif
             
             ! pass the density through
             snew(i,j,k,rho_comp) = sold(i,j,k,rho_comp)

             ! update the species
             snew(i,j,k,spec_comp:spec_comp+nspec-1) = x_out(1:nspec) * rho
             
             ! store the energy generation and species create quantities
             rho_omegadot(i,j,k,1:nspec) = rhowdot(1:nspec)
             rho_Hnuc(i,j,k) = rhoH

             ! update the enthalpy -- include the change due to external heating
             snew(i,j,k,rhoh_comp) = sold(i,j,k,rhoh_comp) &
                  + ldt*rho_Hnuc(i,j,k) + ldt*rho_Hext(i,j,k)

             ! pass the tracers through
             snew(i,j,k,trac_comp:trac_comp+ntrac-1) = &
                  sold(i,j,k,trac_comp:trac_comp+ntrac-1)
             
          enddo
       enddo
    enddo
    !$OMP END PARALLEL DO

  end subroutine burner_loop_3d_sph

end module react_state_module