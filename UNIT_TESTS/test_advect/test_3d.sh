#!/bin/sh

MAESTRO_EXE=./main.Linux.Intel.debug.exe
COMPARE_EXE=fcompare.Linux.Intel.exe

echo "3-d advection tests" > advect_3d_report.out

# PPM 0

${MAESTRO_EXE} inputs_3d_xm --ppm_type 0 &> advect_3d_xm_ppm0.out
${MAESTRO_EXE} inputs_3d_xp --ppm_type 0 &> advect_3d_xp_ppm0.out
${MAESTRO_EXE} inputs_3d_ym --ppm_type 0 &> advect_3d_ym_ppm0.out
${MAESTRO_EXE} inputs_3d_yp --ppm_type 0 &> advect_3d_yp_ppm0.out
${MAESTRO_EXE} inputs_3d_zm --ppm_type 0 &> advect_3d_zm_ppm0.out
${MAESTRO_EXE} inputs_3d_zp --ppm_type 0 &> advect_3d_zp_ppm0.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 0, -X direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm0_xm_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 0, +X direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm0_xp_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 0, -Y direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm0_ym_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 0, +Y direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm0_yp_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 0, -Z direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm0_zm_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 0, +Z direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm0_zp_final >> advect_3d_report.out


# PPM 1

${MAESTRO_EXE} inputs_3d_xm --ppm_type 1 &> advect_3d_xm_ppm1.out
${MAESTRO_EXE} inputs_3d_xp --ppm_type 1 &> advect_3d_xp_ppm1.out
${MAESTRO_EXE} inputs_3d_ym --ppm_type 1 &> advect_3d_ym_ppm1.out
${MAESTRO_EXE} inputs_3d_yp --ppm_type 1 &> advect_3d_yp_ppm1.out
${MAESTRO_EXE} inputs_3d_zm --ppm_type 1 &> advect_3d_zm_ppm1.out
${MAESTRO_EXE} inputs_3d_zp --ppm_type 1 &> advect_3d_zp_ppm1.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 1, -X direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm1_xm_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 1, +X direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm1_xp_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 1, -Y direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm1_ym_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 1, +Y direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm1_yp_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 1, -Z direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm1_zm_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 1, +Z direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm1_zp_final >> advect_3d_report.out



# PPM 2

${MAESTRO_EXE} inputs_3d_xm --ppm_type 2 &> advect_3d_xm_ppm2.out
${MAESTRO_EXE} inputs_3d_xp --ppm_type 2 &> advect_3d_xp_ppm2.out
${MAESTRO_EXE} inputs_3d_ym --ppm_type 2 &> advect_3d_ym_ppm2.out
${MAESTRO_EXE} inputs_3d_yp --ppm_type 2 &> advect_3d_yp_ppm2.out
${MAESTRO_EXE} inputs_3d_zm --ppm_type 2 &> advect_3d_zm_ppm2.out
${MAESTRO_EXE} inputs_3d_zp --ppm_type 2 &> advect_3d_zp_ppm2.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 2, -X direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm2_xm_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 2, +X direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm2_xp_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 2, -Y direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm2_ym_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 2, +Y direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm2_yp_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 2, -Z direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm2_zm_final >> advect_3d_report.out

echo " " >> advect_3d_report.out
echo "3-d advection PPM 2, +Z direction error" >> advect_3d_report.out
${COMPARE_EXE} --infile1 dens_3d_orig --infile2 dens_3d_ppm2_zp_final >> advect_3d_report.out


