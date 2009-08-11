module thermal_conduct_module

  use bl_types
  use multifab_module
  use bl_constants_module
  use define_bc_module
  use ml_layout_module
  use bndry_reg_module
  use fill_3d_module

  implicit none

  private

  public :: thermal_conduct

contains 

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ! Crank-Nicholson solve for enthalpy, taking into account only the
  ! enthalpy-diffusion terms in the temperature conduction term.
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  subroutine thermal_conduct(mla,dx,dt,s1,hcoeff1,Xkcoeff1,pcoeff1, &
                             hcoeff2,Xkcoeff2,pcoeff2,s2,p0_old,p0_new,the_bc_tower)

    use variables, only: foextrap_comp, rho_comp, spec_comp, rhoh_comp, temp_comp
    use macproject_module
    use network, only: nspec
    use rhoh_vs_t_module
    use probin_module, ONLY: thermal_diffusion_type, use_tfromp
    use bl_prof_module
    use multifab_physbc_module
    use multifab_fill_ghost_module
    use ml_restriction_module, only: ml_cc_restriction_c
    use geometry, only: dm, nlevs
    use make_explicit_thermal_module

    type(ml_layout), intent(inout) :: mla
    real(dp_t)     , intent(in   ) :: dx(:,:),dt
    type(multifab) , intent(in   ) :: s1(:)
    type(multifab) , intent(in   ) :: hcoeff1(:)
    type(multifab) , intent(in   ) :: Xkcoeff1(:)
    type(multifab) , intent(in   ) :: pcoeff1(:)
    type(multifab) , intent(in   ) :: hcoeff2(:)
    type(multifab) , intent(in   ) :: Xkcoeff2(:)
    type(multifab) , intent(in   ) :: pcoeff2(:)
    type(multifab) , intent(inout) :: s2(:)
    real(kind=dp_t), intent(in   ) :: p0_old(:,0:),p0_new(:,0:)
    type(bc_tower) , intent(in   ) :: the_bc_tower

    ! Local
    type(multifab) :: rhsalpha(mla%nlevel),lhsalpha(mla%nlevel)
    type(multifab) :: rhsbeta(mla%nlevel),lhsbeta(mla%nlevel)
    type(multifab) :: phi(mla%nlevel),Lphi(mla%nlevel),rhs(mla%nlevel)

    integer                     :: stencil_order
    integer                     :: n,comp
    type(bndry_reg)             :: fine_flx(2:mla%nlevel)

    type(bl_prof_timer), save :: bpt

    call build(bpt, "therm_cond_full_alg")

    stencil_order = 2

    do n = 2,nlevs
       call bndry_reg_build(fine_flx(n),mla%la(n),ml_layout_get_pd(mla,n))
    end do


    ! here we will solve:
    !
    ! (rho^2 - dt/2 div . hcoeff2 grad ) h^2 = (rho h)^1  + 
    !           dt/2 div . ( hcoeff1 grad h^1) -
    !           dt/2 sum_k div . (Xkcoeff2 grad X_k^2 + Xkcoeff1 grad X_k^1) -
    !           dt/2 div . ( pcoeff2 grad p_0^new + pcoeff1 grad p_0^old)
    !
    ! or 
    ! (lhsalpha - div . lhsbeta grad) h^2 = RHS
    !
    ! First we will construct the RHS by adding each of the terms in
    ! turn.  
    !
    ! To actually construct each div . (c grad q) term for the RHS, we will 
    ! make use of the mac_applyop routine, which constructs the quantity
    !
    !     (rhsalpha - div . rhsbeta grad) phi = Lphi
    !
    ! For all RHS terms, we set rhsalpha = 0, rhsbeta = the appropriate 
    ! coefficient, and phi = the quantity being diffused.


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! add enthalpy diffusion to rhs
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    do n=1,nlevs
       call multifab_build(rhsbeta(n), mla%la(n), dm, 1)
    end do

    ! put beta on faces
    call put_data_on_faces(hcoeff1,1,rhsbeta,.true.)

    ! scale by dt/2
    if (thermal_diffusion_type .eq. 1) then
       do n=1,nlevs
          call multifab_mult_mult_s_c(rhsbeta(n),1,dt/2.d0,dm,1)
       enddo
    else
       do n=1,nlevs
          call multifab_mult_mult_s_c(rhsbeta(n),1,dt,dm,1)
       enddo
    end if

    ! set rhsalpha = 0
    ! set phi = h^{(1)}
    do n=1,nlevs
       call multifab_build(phi(n), mla%la(n),  1, 1)
       call multifab_build(rhsalpha(n), mla%la(n),  1, 1)
       call multifab_build(Lphi(n), mla%la(n),  1, 0)
       call setval(rhsalpha(n), ZERO, all=.true.)
       call multifab_copy_c(phi(n),1,s1(n),rhoh_comp,1,1)
       call multifab_div_div_c(phi(n),1,s1(n),rho_comp,1,1)
    end do

    ! apply the operator
    call mac_applyop(mla,Lphi,phi,rhsalpha,rhsbeta,dx,the_bc_tower, &
                     dm+rhoh_comp,stencil_order,mla%mba%rr)

    ! begin construction of rhs by setting rhs = \rho^{(2)}h^{(2')}
    do n=1,nlevs
       call multifab_build(rhs(n), mla%la(n),  1, 0)
       call multifab_copy_c(rhs(n),1,s2(n),rhoh_comp,1)
    enddo

    if(thermal_diffusion_type .eq. 1) then
       ! add Lphi to rhs
       do n=1,nlevs
          call multifab_plus_plus_c(rhs(n),1,Lphi(n),1,1)
       enddo
    end if

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! add species diffusion to rhs
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! loop over species
    do comp=1,nspec

       ! do X_k^{(1)} term first
       ! put beta on faces
       call put_data_on_faces(Xkcoeff1,comp,rhsbeta,.true.)

       ! scale by dt/2
       if (thermal_diffusion_type .eq. 1) then
          do n=1,nlevs
             call multifab_mult_mult_s_c(rhsbeta(n),1,dt/2.d0,dm,1)
          enddo
       else
          do n=1,nlevs
             call multifab_mult_mult_s_c(rhsbeta(n),1,dt,dm,1)
          enddo
       end if

       ! load phi = X_k^{(1)}
       do n=1,nlevs
          call multifab_copy_c(phi(n),1,s1(n),spec_comp+comp-1,1,1)
          call multifab_div_div_c(phi(n),1,s1(n),rho_comp,1,1)
       enddo

       ! apply the operator
       call mac_applyop(mla,Lphi,phi,rhsalpha,rhsbeta,dx,the_bc_tower, &
                        dm+spec_comp+comp-1,stencil_order,mla%mba%rr)

       if(thermal_diffusion_type .eq. 1) then
          ! add lphi to rhs
          do n=1,nlevs
             call multifab_plus_plus_c(rhs(n),1,Lphi(n),1,1)
          enddo
       end if

       ! now do X_k^{(2)} term
       ! put beta on faces
       call put_data_on_faces(Xkcoeff2,comp,rhsbeta,.true.)

       ! scale by dt/2
       if (thermal_diffusion_type .eq. 1) then
          do n=1,nlevs
             call multifab_mult_mult_s_c(rhsbeta(n),1,dt/2.d0,dm,1)
          enddo
       else
          do n=1,nlevs
             call multifab_mult_mult_s_c(rhsbeta(n),1,dt,dm,1)
          enddo
       end if

       ! load phi = X_k^{(2)}
       do n=1,nlevs
          call multifab_copy_c(phi(n),1,s2(n),spec_comp+comp-1,1,1)
          call multifab_div_div_c(phi(n),1,s2(n),rho_comp,1,1)
       enddo

       ! apply the operator
       call mac_applyop(mla,Lphi,phi,rhsalpha,rhsbeta,dx,the_bc_tower, &
                        dm+spec_comp+comp-1,stencil_order,mla%mba%rr)

       ! add lphi to rhs
       do n=1,nlevs
          call multifab_plus_plus_c(rhs(n),1,Lphi(n),1,1)
       enddo
    enddo

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! add pressure diffusion to rhs
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! do p0_old term first
    ! put beta on faces
    call put_data_on_faces(pcoeff1,1,rhsbeta,.true.)

    ! scale by dt/2
    if (thermal_diffusion_type .eq. 1) then
       do n=1,nlevs
          call multifab_mult_mult_s_c(rhsbeta(n),1,dt/2.d0,dm,1)
       enddo
    else
       do n=1,nlevs
          call multifab_mult_mult_s_c(rhsbeta(n),1,dt,dm,1)
       enddo
    end if

    call put_1d_array_on_cart(p0_old,phi,foextrap_comp,.false.,.false., &
                              dx,the_bc_tower%bc_tower_array,mla)
    ! apply the operator
    call mac_applyop(mla,Lphi,phi,rhsalpha,rhsbeta,dx,the_bc_tower, &
                     foextrap_comp,stencil_order,mla%mba%rr)

    if(thermal_diffusion_type .eq. 1) then
       ! add lphi to rhs
       do n=1,nlevs
          call multifab_plus_plus_c(rhs(n),1,Lphi(n),1,1)
       enddo
    end if

    ! now do p0_new term
    ! put beta on faces
    call put_data_on_faces(pcoeff2,1,rhsbeta,.true.)

    ! scale by dt/2
    if (thermal_diffusion_type .eq. 1) then
       do n=1,nlevs
          call multifab_mult_mult_s_c(rhsbeta(n),1,dt/2.d0,dm,1)
       enddo
    else
       do n=1,nlevs
          call multifab_mult_mult_s_c(rhsbeta(n),1,dt,dm,1)
       enddo
    end if

    call put_1d_array_on_cart(p0_new,phi,foextrap_comp,.false.,.false., &
                              dx,the_bc_tower%bc_tower_array,mla)

    ! apply the operator
    call mac_applyop(mla,Lphi,phi,rhsalpha,rhsbeta,dx,the_bc_tower, &
                     foextrap_comp,stencil_order,mla%mba%rr)

    do n=1,nlevs
       call destroy(rhsalpha(n))
       call destroy(rhsbeta(n))
    end do

    ! add lphi to rhs
    do n=1,nlevs
       call multifab_plus_plus_c(rhs(n),1,Lphi(n),1,1)
    enddo

    do n=1,nlevs
       call destroy(Lphi(n))
    end do

    !!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Setup LHS coefficients
    !!!!!!!!!!!!!!!!!!!!!!!!!!!

    do n=1,nlevs
       call multifab_build(lhsbeta(n), mla%la(n), dm, 1)
    end do

    ! create lhsbeta = -hcoeff2 = (dt/2)k_{th}^{(2'')}/c_p^{(2'')}
    ! put beta on faces (remember to scale by -dt/2 afterwards)
    call put_data_on_faces(hcoeff2,1,lhsbeta,.true.)

    ! scale by -dt/2
    if (thermal_diffusion_type .eq. 1) then
       do n=1,nlevs
          call multifab_mult_mult_s_c(lhsbeta(n),1,-dt/2.d0,dm,1)
       enddo
    else
       do n=1,nlevs
          call multifab_mult_mult_s_c(lhsbeta(n),1,-dt,dm,1)
       enddo
    end if

    !!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Now do the implicit solve
    !!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! initialize phi to h^{(2'')} as a guess; also sets the ghost cells at inflow/outflow
    ! to a reasonable value
    do n=1,nlevs
       call multifab_copy_c(phi(n),1,s2(n),rhoh_comp,1,1)
       call multifab_div_div_c(phi(n),1,s2(n),rho_comp,1,1)
    enddo

    ! lhsalpha = \rho^{(2),*} or \rho^{(2)}
    do n=1,nlevs
       call multifab_build(lhsalpha(n), mla%la(n), 1, 1)
       call multifab_copy_c(lhsalpha(n),1,s2(n),rho_comp,1,1)
    enddo

    ! Call the solver to obtain h^(2) (it will be stored in phi)
    ! solves (alpha - nabla dot beta nabla)phi = rhs
    call mac_multigrid(mla,rhs,phi,fine_flx,lhsalpha,lhsbeta,dx,the_bc_tower, &
                       dm+rhoh_comp,stencil_order,mla%mba%rr)

    do n=2,nlevs
       call destroy(fine_flx(n))
    end do

    do n=1,nlevs
       call destroy(lhsalpha(n))
       call destroy(lhsbeta(n))
       call destroy(rhs(n))
    end do

    ! load new rho*h into s2
    do n=1,nlevs
       call multifab_copy_c(s2(n),rhoh_comp,phi(n),1,1)
       call multifab_mult_mult_c(s2(n),rhoh_comp,s2(n),rho_comp,1)
       call enforce_transverse(n,s2(n),rhoh_comp)
    enddo



    do n=1,nlevs
       call destroy(phi(n))
    end do

    if (nlevs .eq. 1) then

       ! fill ghost cells for two adjacent grids at the same level
       ! this includes periodic domain boundary ghost cells
       call multifab_fill_boundary_c(s2(nlevs),rhoh_comp,1)

       ! fill non-periodic domain boundary ghost cells
       call multifab_physbc(s2(nlevs),rhoh_comp,dm+rhoh_comp,1, &
                            the_bc_tower%bc_tower_array(nlevs))

    else

       ! the loop over nlevs must count backwards to make sure the finer grids are done first
       do n=nlevs,2,-1

          ! set level n-1 data to be the average of the level n data covering it
          call ml_cc_restriction_c(s2(n-1),rhoh_comp,s2(n),rhoh_comp,mla%mba%rr(n-1,:),1)

          ! fill level n ghost cells using interpolation from level n-1 data
          ! note that multifab_fill_boundary and multifab_physbc are called for
          ! both levels n-1 and n
          call multifab_fill_ghost_cells(s2(n),s2(n-1),s2(1)%ng,mla%mba%rr(n-1,:), &
                                         the_bc_tower%bc_tower_array(n-1), &
                                         the_bc_tower%bc_tower_array(n  ), &
                                         rhoh_comp,dm+rhoh_comp,1,fill_crse_input=.false.)
       enddo

    end if

    call destroy(bpt)

  end subroutine thermal_conduct

  subroutine enforce_transverse(n,s,comp)

    use multifab_module
    use geometry, only : dm

    integer, intent(in) :: n, comp
    type(multifab), intent(inout) :: s

    real(kind=dp_t), pointer :: sp(:,:,:,:)
    integer :: i, ng_s
    integer :: lo(dm), hi(dm)

    do i = 1, s%nboxes
       if (multifab_remote(s, i) ) cycle

       lo = lwb(get_box(s, i))
       hi = upb(get_box(s, i))
       ng_s = s%ng

       sp => dataptr(s, i)

       call enforce_transverse_2d(sp(:,:,1,comp),ng_s,lo,hi)

    enddo

  end subroutine enforce_transverse

  subroutine enforce_transverse_2d(rhoh,ng_s,lo,hi)

    integer, intent(in) :: lo(:), hi(:), ng_s
    real(kind=dp_t) :: rhoh(lo(1)-ng_s:,lo(2)-ng_s:)

    integer :: i, j

    do j = lo(2), hi(2)
       do i = lo(1), hi(1)
          rhoh(i,j) = rhoh(lo(1),j)
       enddo
    enddo
    
  end subroutine enforce_transverse_2d

end module thermal_conduct_module