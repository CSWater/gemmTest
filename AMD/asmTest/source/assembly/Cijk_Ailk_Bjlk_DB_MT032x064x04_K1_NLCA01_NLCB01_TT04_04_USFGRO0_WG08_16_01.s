
/******************************************/
/* Function Prefix                        */
/******************************************/

/******************************************/
/* Begin Kernel                           */
/******************************************/
.hsa_code_object_version 2,0
.hsa_code_object_isa 9, 0, 6, "AMD", "AMDGPU" 
.text
.p2align 8
.amdgpu_hsa_kernel Cijk_Ailk_Bjlk_DB_MT032x064x04_K1_NLCA01_NLCB01_TT04_04_USFGRO0_WG08_16_01
Cijk_Ailk_Bjlk_DB_MT032x064x04_K1_NLCA01_NLCB01_TT04_04_USFGRO0_WG08_16_01:
.amd_kernel_code_t
  is_ptr64 = 1
  enable_sgpr_kernarg_segment_ptr = 1
  kernarg_segment_byte_size = 92 // bytes of kern args
  workitem_vgpr_count = 77 // vgprs
  wavefront_sgpr_count = 78 // sgprs
  compute_pgm_rsrc1_vgprs = 19 // floor((77-1)/4)
  compute_pgm_rsrc1_sgprs = 10 // floor((78-1)/8)
  compute_pgm_rsrc2_tidig_comp_cnt = 0 // 1D wg
  compute_pgm_rsrc2_tgid_x_en = 1 // wg.x
  compute_pgm_rsrc2_tgid_y_en = 1 // wg.y
  compute_pgm_rsrc2_tgid_z_en = 1 // wg.z
  workgroup_group_segment_byte_size = 7168 // lds bytes
  compute_pgm_rsrc2_user_sgpr = 2 // vcc
  kernarg_segment_alignment = 4
  group_segment_alignment = 4
  private_segment_alignment = 4
.end_amd_kernel_code_t

/******************************************/
/* Optimizations and Config:              */
/******************************************/
/* ThreadTile=4 x 4 */
/* VectorWidth=2 */
/* GlobalLoadVectorWidthA=1, GlobalLoadVectorWidthB=2 */
/* DirectToLdsA=False */
/* DirectToLdsB=False */
/* UseSgprForGRO=False */

/******************************************/
/* ASM syntax bug workarounds             */
/******************************************/
.macro _v_add_co_u32 dst, cc, src0, src1, dpp=
   v_add_co_u32 \dst, \cc, \src0, \src1 \dpp
.endm
.macro _v_sub_co_u32 dst, cc, src0, src1, dpp=
   v_sub_co_u32 \dst, \cc, \src0, \src1 \dpp
.endm
.macro _v_addc_co_u32 dst, ccOut, src0, ccIn, src1, dpp=
   v_addc_co_u32 \dst, \ccOut, \src0, \ccIn, \src1 \dpp
.endm
.macro _v_add_lshl_u32 dst, src0, src1, shiftCnt
    v_add_lshl_u32 \dst, \src0, \src1, \shiftCnt
.endm
.macro _v_lshl_add_u32 dst, src0, src1, shiftCnt
    v_lshl_add_u32 \dst, \src0, \src1, \shiftCnt
.endm

/******************************************/
/* VGPR Assignments                       */
/******************************************/
.set vgprValuC, 0
/* ValuA/B   Xn=PLR buffer idx,  In=InnerUnroll idx */
.set vgprValuA_X0_I0, 32
.set vgprValuA_X1_I0, 40
.set vgprG2LA, 48
.set vgprValuB_X0_I0, 50
.set vgprValuB_X1_I0, 58
.set vgprG2LB, 66
.set vgprLocalReadAddrA, 70
.set vgprLocalReadAddrB, 71
.set vgprLocalWriteAddrA, 72
.set vgprLocalWriteAddrB, 73
.set vgprGlobalReadOffsetA, 74
.set vgprGlobalReadOffsetB, 75
.set vgprSerial, 76
/* max VGPR=77 */

/******************************************/
/* SGPR Assignments                       */
/******************************************/
.set sgprKernArgAddress, 0
.set sgprWorkGroup0, 2
.set sgprWorkGroup1, 3
.set sgprWorkGroup2, 4
.set sgprNumWorkGroups0, 5
.set sgprNumWorkGroups1, 6
.set sgprSrdA, 8
.set sgprSrdB, 12
.set sgprSrdC, 16
.set sgprTensor2dSizeC, 20
.set sgprTensor2dSizeA, 22
.set sgprTensor2dSizeB, 24
.set sgprSaveExecMask, 26
.set sgprAddressC, 28
.set sgprStridesC, 30
.set sgprAlpha, 32
.set sgprBeta, 34
.set sgprSizesFree, 36
.set sgprSizesSum, 39
.set sgprLoopCounters, 40
.set sgprStridesA, 41
.set sgprStridesB, 43
.set sgprAddressA, 45
.set sgprAddressB, 47
.set sgprSrdShadowLimitA, 50
.set sgprSrdShadowLimitB, 52
.set sgprOffsetC, 54
.set sgprOffsetA, 55
.set sgprOffsetB, 56
.set sgprGlobalReadIncsA, 57
.set sgprGlobalReadIncsB, 58
/* max SGPR=78 */

/******************************************/
/* 2GB limit - set offsets to -1 to exceed this and clamp */
/******************************************/
.set BufferLimit, 0x80000000

/******************************************/
/* Bits 127:96 of SRD.  Set DataFormat = 32 bit */
/******************************************/
.set Srd127_96, 0x0020000
.set BufferOOB, 0x80000000

/* Global Offset A */
.macro GLOBAL_OFFSET_A vgprAddr vgprOffset0I vgprOffsetL vgprTmp
v_mul_lo_u32 v[\vgprTmp+0], s[sgprStridesA+0], v[\vgprOffsetL] // mul d1 lower
_v_add_co_u32 v[\vgprAddr+0], vcc, v[\vgprTmp+0], v[\vgprOffset0I] // accumulate d1 lower
_v_add_co_u32 v[\vgprAddr+0], vcc, 0x1, v[\vgprAddr+0] // add prepad
v_lshlrev_b32 v[\vgprAddr+0], 0x3, v[\vgprAddr+0]  // offset *= bytes/element
.endm

/* Global Offset B */
.macro GLOBAL_OFFSET_B vgprAddr vgprOffset1J vgprOffsetL vgprTmp
v_mul_lo_u32 v[\vgprTmp+0], s[sgprStridesB+0], v[\vgprOffsetL] // mul d1 lower
_v_add_co_u32 v[\vgprAddr+0], vcc, v[\vgprTmp+0], v[\vgprOffset1J] // accumulate d1 lower
_v_add_co_u32 v[\vgprAddr+0], vcc, 0x2, v[\vgprAddr+0] // add prepad
v_lshlrev_b32 v[\vgprAddr+0], 0x3, v[\vgprAddr+0]  // offset *= bytes/element
.endm

/******************************************/
/* Dynamic Scalar Divide: vQuotient=vDividend/vDivisor; vRemainder=vDividend%vDivisor; */
/******************************************/
.macro DYNAMIC_VECTOR_DIVIDE vQuotient vRemainder vDividend vDivisor vTmp0 vTmp1 sTmp
v_cvt_f32_u32 v[\vQuotient], v[\vDivisor]          // 
v_rcp_f32 v[\vQuotient], v[\vQuotient]             // 
v_mul_f32 v[\vQuotient], 0x4f800000, v[\vQuotient] // 
v_cvt_u32_f32 v[\vQuotient], v[\vQuotient]         // 
v_mul_lo_u32 v[\vRemainder], v[\vDivisor], v[\vQuotient] // 
v_mul_hi_u32 v[\vTmp0], v[\vDivisor], v[\vQuotient] // 
_v_sub_co_u32 v[\vTmp1], vcc, 0x0, v[\vRemainder]  // 
v_cmp_ne_i32 s[\sTmp:\sTmp+1], 0x0, v[\vTmp0]      // 
v_cndmask_b32 v[\vRemainder], v[\vTmp1], v[\vRemainder], s[\sTmp:\sTmp+1] // 
v_mul_hi_u32 v[\vRemainder], v[\vRemainder], v[\vQuotient] // 
_v_sub_co_u32 v[\vTmp0], vcc, v[\vQuotient], v[\vRemainder] // 
_v_add_co_u32 v[\vQuotient], vcc, v[\vQuotient], v[\vRemainder] // 
v_cndmask_b32 v[\vQuotient], v[\vQuotient], v[\vTmp0], s[\sTmp:\sTmp+1] // 
v_mul_hi_u32 v[\vQuotient], v[\vQuotient], v[\vDividend] // 
v_mul_lo_u32 v[\vRemainder], v[\vQuotient], v[\vDivisor] // 
_v_sub_co_u32 v[\vTmp0], vcc, v[\vDividend], v[\vRemainder] // 
v_cmp_ge_u32 s[\sTmp:\sTmp+1], v[\vDividend], v[\vRemainder] // 
_v_add_co_u32 v[\vRemainder], vcc, 0x1, v[\vQuotient] // 
_v_add_co_u32 v[\vTmp1], vcc, -1, v[\vQuotient]    // 
v_cmp_le_u32 vcc, v[\vDivisor], v[\vTmp0]          // 
s_and_b64 vcc, s[\sTmp:\sTmp+1], vcc               // 
v_cndmask_b32 v[\vQuotient], v[\vQuotient], v[\vRemainder], vcc // 
v_cndmask_b32 v[\vQuotient], v[\vTmp1], v[\vQuotient], s[\sTmp:\sTmp+1] // 
v_cmp_ne_i32 vcc, 0x0, v[\vDivisor]                // 
v_cndmask_b32 v[\vQuotient], -1, v[\vQuotient], vcc // final result
v_mul_lo_u32 v[\vRemainder], v[\vQuotient], v[\vDivisor] // 
_v_sub_co_u32 v[\vRemainder], vcc, v[\vDividend], v[\vRemainder] // final result
.endm

/******************************************/
/* 4x4 thread-tile                        */
/******************************************/
.macro MAC_4x4_X0
v_fma_f64 v[vgprValuC+(0+0*4)*2:(vgprValuC+0+0*4)*2+1], v[vgprValuA_X0_I0+0*2:vgprValuA_X0_I0+0*2+1], v[vgprValuB_X0_I0+0*2:vgprValuB_X0_I0+0*2+1], v[vgprValuC+(0+0*4)*2:(vgprValuC+0+0*4)*2+1]
s_setprio 1 // Raise priority while processing macs 
v_fma_f64 v[vgprValuC+(1+0*4)*2:(vgprValuC+1+0*4)*2+1], v[vgprValuA_X0_I0+1*2:vgprValuA_X0_I0+1*2+1], v[vgprValuB_X0_I0+0*2:vgprValuB_X0_I0+0*2+1], v[vgprValuC+(1+0*4)*2:(vgprValuC+1+0*4)*2+1]
v_fma_f64 v[vgprValuC+(2+0*4)*2:(vgprValuC+2+0*4)*2+1], v[vgprValuA_X0_I0+2*2:vgprValuA_X0_I0+2*2+1], v[vgprValuB_X0_I0+0*2:vgprValuB_X0_I0+0*2+1], v[vgprValuC+(2+0*4)*2:(vgprValuC+2+0*4)*2+1]
v_fma_f64 v[vgprValuC+(3+0*4)*2:(vgprValuC+3+0*4)*2+1], v[vgprValuA_X0_I0+3*2:vgprValuA_X0_I0+3*2+1], v[vgprValuB_X0_I0+0*2:vgprValuB_X0_I0+0*2+1], v[vgprValuC+(3+0*4)*2:(vgprValuC+3+0*4)*2+1]
v_fma_f64 v[vgprValuC+(0+1*4)*2:(vgprValuC+0+1*4)*2+1], v[vgprValuA_X0_I0+0*2:vgprValuA_X0_I0+0*2+1], v[vgprValuB_X0_I0+1*2:vgprValuB_X0_I0+1*2+1], v[vgprValuC+(0+1*4)*2:(vgprValuC+0+1*4)*2+1]
v_fma_f64 v[vgprValuC+(1+1*4)*2:(vgprValuC+1+1*4)*2+1], v[vgprValuA_X0_I0+1*2:vgprValuA_X0_I0+1*2+1], v[vgprValuB_X0_I0+1*2:vgprValuB_X0_I0+1*2+1], v[vgprValuC+(1+1*4)*2:(vgprValuC+1+1*4)*2+1]
v_fma_f64 v[vgprValuC+(2+1*4)*2:(vgprValuC+2+1*4)*2+1], v[vgprValuA_X0_I0+2*2:vgprValuA_X0_I0+2*2+1], v[vgprValuB_X0_I0+1*2:vgprValuB_X0_I0+1*2+1], v[vgprValuC+(2+1*4)*2:(vgprValuC+2+1*4)*2+1]
v_fma_f64 v[vgprValuC+(3+1*4)*2:(vgprValuC+3+1*4)*2+1], v[vgprValuA_X0_I0+3*2:vgprValuA_X0_I0+3*2+1], v[vgprValuB_X0_I0+1*2:vgprValuB_X0_I0+1*2+1], v[vgprValuC+(3+1*4)*2:(vgprValuC+3+1*4)*2+1]
v_fma_f64 v[vgprValuC+(0+2*4)*2:(vgprValuC+0+2*4)*2+1], v[vgprValuA_X0_I0+0*2:vgprValuA_X0_I0+0*2+1], v[vgprValuB_X0_I0+2*2:vgprValuB_X0_I0+2*2+1], v[vgprValuC+(0+2*4)*2:(vgprValuC+0+2*4)*2+1]
v_fma_f64 v[vgprValuC+(1+2*4)*2:(vgprValuC+1+2*4)*2+1], v[vgprValuA_X0_I0+1*2:vgprValuA_X0_I0+1*2+1], v[vgprValuB_X0_I0+2*2:vgprValuB_X0_I0+2*2+1], v[vgprValuC+(1+2*4)*2:(vgprValuC+1+2*4)*2+1]
v_fma_f64 v[vgprValuC+(2+2*4)*2:(vgprValuC+2+2*4)*2+1], v[vgprValuA_X0_I0+2*2:vgprValuA_X0_I0+2*2+1], v[vgprValuB_X0_I0+2*2:vgprValuB_X0_I0+2*2+1], v[vgprValuC+(2+2*4)*2:(vgprValuC+2+2*4)*2+1]
v_fma_f64 v[vgprValuC+(3+2*4)*2:(vgprValuC+3+2*4)*2+1], v[vgprValuA_X0_I0+3*2:vgprValuA_X0_I0+3*2+1], v[vgprValuB_X0_I0+2*2:vgprValuB_X0_I0+2*2+1], v[vgprValuC+(3+2*4)*2:(vgprValuC+3+2*4)*2+1]
v_fma_f64 v[vgprValuC+(0+3*4)*2:(vgprValuC+0+3*4)*2+1], v[vgprValuA_X0_I0+0*2:vgprValuA_X0_I0+0*2+1], v[vgprValuB_X0_I0+3*2:vgprValuB_X0_I0+3*2+1], v[vgprValuC+(0+3*4)*2:(vgprValuC+0+3*4)*2+1]
v_fma_f64 v[vgprValuC+(1+3*4)*2:(vgprValuC+1+3*4)*2+1], v[vgprValuA_X0_I0+1*2:vgprValuA_X0_I0+1*2+1], v[vgprValuB_X0_I0+3*2:vgprValuB_X0_I0+3*2+1], v[vgprValuC+(1+3*4)*2:(vgprValuC+1+3*4)*2+1]
v_fma_f64 v[vgprValuC+(2+3*4)*2:(vgprValuC+2+3*4)*2+1], v[vgprValuA_X0_I0+2*2:vgprValuA_X0_I0+2*2+1], v[vgprValuB_X0_I0+3*2:vgprValuB_X0_I0+3*2+1], v[vgprValuC+(2+3*4)*2:(vgprValuC+2+3*4)*2+1]
v_fma_f64 v[vgprValuC+(3+3*4)*2:(vgprValuC+3+3*4)*2+1], v[vgprValuA_X0_I0+3*2:vgprValuA_X0_I0+3*2+1], v[vgprValuB_X0_I0+3*2:vgprValuB_X0_I0+3*2+1], v[vgprValuC+(3+3*4)*2:(vgprValuC+3+3*4)*2+1]
s_setprio 0 // Reset priority after macs 
.endm
.macro MAC_4x4_X1
v_fma_f64 v[vgprValuC+(0+0*4)*2:(vgprValuC+0+0*4)*2+1], v[vgprValuA_X1_I0+0*2:vgprValuA_X1_I0+0*2+1], v[vgprValuB_X1_I0+0*2:vgprValuB_X1_I0+0*2+1], v[vgprValuC+(0+0*4)*2:(vgprValuC+0+0*4)*2+1]
s_setprio 1 // Raise priority while processing macs 
v_fma_f64 v[vgprValuC+(1+0*4)*2:(vgprValuC+1+0*4)*2+1], v[vgprValuA_X1_I0+1*2:vgprValuA_X1_I0+1*2+1], v[vgprValuB_X1_I0+0*2:vgprValuB_X1_I0+0*2+1], v[vgprValuC+(1+0*4)*2:(vgprValuC+1+0*4)*2+1]
v_fma_f64 v[vgprValuC+(2+0*4)*2:(vgprValuC+2+0*4)*2+1], v[vgprValuA_X1_I0+2*2:vgprValuA_X1_I0+2*2+1], v[vgprValuB_X1_I0+0*2:vgprValuB_X1_I0+0*2+1], v[vgprValuC+(2+0*4)*2:(vgprValuC+2+0*4)*2+1]
v_fma_f64 v[vgprValuC+(3+0*4)*2:(vgprValuC+3+0*4)*2+1], v[vgprValuA_X1_I0+3*2:vgprValuA_X1_I0+3*2+1], v[vgprValuB_X1_I0+0*2:vgprValuB_X1_I0+0*2+1], v[vgprValuC+(3+0*4)*2:(vgprValuC+3+0*4)*2+1]
v_fma_f64 v[vgprValuC+(0+1*4)*2:(vgprValuC+0+1*4)*2+1], v[vgprValuA_X1_I0+0*2:vgprValuA_X1_I0+0*2+1], v[vgprValuB_X1_I0+1*2:vgprValuB_X1_I0+1*2+1], v[vgprValuC+(0+1*4)*2:(vgprValuC+0+1*4)*2+1]
v_fma_f64 v[vgprValuC+(1+1*4)*2:(vgprValuC+1+1*4)*2+1], v[vgprValuA_X1_I0+1*2:vgprValuA_X1_I0+1*2+1], v[vgprValuB_X1_I0+1*2:vgprValuB_X1_I0+1*2+1], v[vgprValuC+(1+1*4)*2:(vgprValuC+1+1*4)*2+1]
v_fma_f64 v[vgprValuC+(2+1*4)*2:(vgprValuC+2+1*4)*2+1], v[vgprValuA_X1_I0+2*2:vgprValuA_X1_I0+2*2+1], v[vgprValuB_X1_I0+1*2:vgprValuB_X1_I0+1*2+1], v[vgprValuC+(2+1*4)*2:(vgprValuC+2+1*4)*2+1]
v_fma_f64 v[vgprValuC+(3+1*4)*2:(vgprValuC+3+1*4)*2+1], v[vgprValuA_X1_I0+3*2:vgprValuA_X1_I0+3*2+1], v[vgprValuB_X1_I0+1*2:vgprValuB_X1_I0+1*2+1], v[vgprValuC+(3+1*4)*2:(vgprValuC+3+1*4)*2+1]
v_fma_f64 v[vgprValuC+(0+2*4)*2:(vgprValuC+0+2*4)*2+1], v[vgprValuA_X1_I0+0*2:vgprValuA_X1_I0+0*2+1], v[vgprValuB_X1_I0+2*2:vgprValuB_X1_I0+2*2+1], v[vgprValuC+(0+2*4)*2:(vgprValuC+0+2*4)*2+1]
v_fma_f64 v[vgprValuC+(1+2*4)*2:(vgprValuC+1+2*4)*2+1], v[vgprValuA_X1_I0+1*2:vgprValuA_X1_I0+1*2+1], v[vgprValuB_X1_I0+2*2:vgprValuB_X1_I0+2*2+1], v[vgprValuC+(1+2*4)*2:(vgprValuC+1+2*4)*2+1]
v_fma_f64 v[vgprValuC+(2+2*4)*2:(vgprValuC+2+2*4)*2+1], v[vgprValuA_X1_I0+2*2:vgprValuA_X1_I0+2*2+1], v[vgprValuB_X1_I0+2*2:vgprValuB_X1_I0+2*2+1], v[vgprValuC+(2+2*4)*2:(vgprValuC+2+2*4)*2+1]
v_fma_f64 v[vgprValuC+(3+2*4)*2:(vgprValuC+3+2*4)*2+1], v[vgprValuA_X1_I0+3*2:vgprValuA_X1_I0+3*2+1], v[vgprValuB_X1_I0+2*2:vgprValuB_X1_I0+2*2+1], v[vgprValuC+(3+2*4)*2:(vgprValuC+3+2*4)*2+1]
v_fma_f64 v[vgprValuC+(0+3*4)*2:(vgprValuC+0+3*4)*2+1], v[vgprValuA_X1_I0+0*2:vgprValuA_X1_I0+0*2+1], v[vgprValuB_X1_I0+3*2:vgprValuB_X1_I0+3*2+1], v[vgprValuC+(0+3*4)*2:(vgprValuC+0+3*4)*2+1]
v_fma_f64 v[vgprValuC+(1+3*4)*2:(vgprValuC+1+3*4)*2+1], v[vgprValuA_X1_I0+1*2:vgprValuA_X1_I0+1*2+1], v[vgprValuB_X1_I0+3*2:vgprValuB_X1_I0+3*2+1], v[vgprValuC+(1+3*4)*2:(vgprValuC+1+3*4)*2+1]
v_fma_f64 v[vgprValuC+(2+3*4)*2:(vgprValuC+2+3*4)*2+1], v[vgprValuA_X1_I0+2*2:vgprValuA_X1_I0+2*2+1], v[vgprValuB_X1_I0+3*2:vgprValuB_X1_I0+3*2+1], v[vgprValuC+(2+3*4)*2:(vgprValuC+2+3*4)*2+1]
v_fma_f64 v[vgprValuC+(3+3*4)*2:(vgprValuC+3+3*4)*2+1], v[vgprValuA_X1_I0+3*2:vgprValuA_X1_I0+3*2+1], v[vgprValuB_X1_I0+3*2:vgprValuB_X1_I0+3*2+1], v[vgprValuC+(3+3*4)*2:(vgprValuC+3+3*4)*2+1]
s_setprio 0 // Reset priority after macs 
.endm

/******************************************/
/* Allocate Resources                     */
/******************************************/
s_mov_b32 m0, 0x1c00                               // LDS clamp at 7168 bytes
v_mov_b32 v[vgprSerial], v0                        // thread serial id

/* Load Kernel Args */
s_load_dword s[sgprTensor2dSizeC+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x0 // load tensor size
s_load_dword s[sgprTensor2dSizeC+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x4 // load tensor size
s_load_dword s[sgprTensor2dSizeA+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x8 // load tensor size
s_load_dword s[sgprTensor2dSizeA+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0xc // load tensor size
s_load_dword s[sgprTensor2dSizeB+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x10 // load tensor size
s_load_dword s[sgprTensor2dSizeB+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x14 // load tensor size
s_load_dword s[sgprAddressC], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x18 // load addr c
s_load_dword s[sgprAddressC+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x1c // load addr c
s_load_dword s[sgprAddressA], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x20 // load addr a
s_load_dword s[sgprAddressA+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x24 // load addr a
s_load_dword s[sgprAddressB], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x28 // load addr b
s_load_dword s[sgprAddressB+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x2c // load addr b
s_load_dword s[sgprAlpha+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x30 // load alpha
s_load_dword s[sgprAlpha+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x34 // load alpha
s_load_dword s[sgprBeta+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x38 // load beta
s_load_dword s[sgprBeta+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x3c // load beta
s_load_dword s[sgprOffsetC], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x40 // load offset c
s_load_dword s[sgprOffsetA], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x44 // load offset a
s_load_dword s[sgprOffsetB], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x48 // load offset b
s_load_dword s[sgprStridesC+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x4c // load stride c 0
s_load_dword s[sgprStridesC+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x50 // load stride c 1
s_load_dword s[sgprStridesA+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x54 // load stride a 0
s_load_dword s[sgprStridesA+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x58 // load stride a 1
s_load_dword s[sgprStridesB+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x5c // load stride b 0
s_load_dword s[sgprStridesB+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x60 // load stride b 1
s_load_dword s[sgprSizesFree+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x64 // load size free 0
s_load_dword s[sgprSizesFree+1], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x68 // load size free 1
s_load_dword s[sgprSizesFree+2], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x6c // load size free 2
s_load_dword s[sgprSizesSum+0], s[sgprKernArgAddress:sgprKernArgAddress+1], 0x70 // load size sum 0
s_waitcnt lgkmcnt(0)                               // wait for 116 bytes of kern args

/* User Offsets */
s_add_u32 s[sgprAddressC], s[sgprOffsetC], s[sgprAddressC] // addrC += offsetC
s_mov_b32 s[sgprOffsetC], 0                        // 
s_addc_u32 s[sgprAddressC], s[sgprOffsetC], s[sgprAddressC] // addrC += offsetC carry
s_add_u32 s[sgprAddressA], s[sgprOffsetA], s[sgprAddressA] // addrA += offsetA
s_mov_b32 s[sgprOffsetA], 0                        // 
s_addc_u32 s[sgprAddressA], s[sgprOffsetA], s[sgprAddressA] // addrA += offsetA carry
s_add_u32 s[sgprAddressB], s[sgprOffsetB], s[sgprAddressB] // addrB += offsetB
s_mov_b32 s[sgprOffsetB], 0                        // 
s_addc_u32 s[sgprAddressB], s[sgprOffsetB], s[sgprAddressB] // addrB += offsetB carry
// size0 = (size0I + MT0I - 1) / MT0I;
v_mov_b32 v0, s[sgprSizesFree+0]                   // 
s_mov_b32 s59, 0x1f                                // 
_v_add_co_u32 v0, vcc, s59, v0                     // v0 = size0+MT0-1
v_lshrrev_b32 v3, 5, v0                            // vectorStaticDiv: v3 = v0 / 32
v_readfirstlane_b32 s[sgprNumWorkGroups0], v3      // 
// size1 = (size1J + MT1J - 1) / MT1J;
v_mov_b32 v0, s[sgprSizesFree+1]                   // 
s_mov_b32 s59, 0x3f                                // 
_v_add_co_u32 v0, vcc, s59, v0                     // v0 = size1+MT1-1
v_lshrrev_b32 v3, 6, v0                            // vectorStaticDiv: v3 = v0 / 64
v_readfirstlane_b32 s[sgprNumWorkGroups1], v3      // 

/******************************************/
/* Global Read Addresses                  */
/******************************************/

/* global read addresses: subgroup */
/*   not needed until local read addresses */

/* global read addresses: work-group */
// nwg0 = (size0I + MT0I - 1) / MT0I;
v_mov_b32 v2, s[sgprSizesFree+0]                   // 
s_mov_b32 s60, 0x1f                                // 
_v_add_co_u32 v2, vcc, s60, v2                     // v2 = size0+MT0-1
v_lshrrev_b32 v2, 5, v2                            // vectorStaticDiv: v2 = v2 / 32
// nwg1 = (size1J + MT1J - 1) / MT1J;
v_mov_b32 v3, s[sgprSizesFree+1]                   // 
s_mov_b32 s60, 0x3f                                // 
_v_add_co_u32 v3, vcc, s60, v3                     // v3 = size1+MT1-1
v_lshrrev_b32 v3, 6, v3                            // vectorStaticDiv: v3 = v3 / 64
v_mov_b32 v6, s[sgprWorkGroup1]                    // wg1
v_lshrrev_b32 v4, 3, v6                            // vectorStaticDiv: v4 = v6 / 8
v_and_b32 v5, 7, v6                                // vectorStaticDiv: v5 = v6 % 8
v_mul_lo_u32 v5, v5, v2                            // (wg1 % WGM)*nwg0
_v_add_co_u32 v5, vcc, s[sgprWorkGroup0], v5       // wgSerial = wg0 + (wg1 % WGM)*nwg0
// numFullBlocks = (nwg1) / WGM
v_lshrrev_b32 v2, 3, v3                            // vectorStaticDiv: v2 = v3 / 8
v_and_b32 v7, 7, v3                                // vectorStaticDiv: v7 = v3 % 8
v_cmp_lt_u32 s[60:61], v4, v2                      // blockId < numFullBlocks
v_cndmask_b32 v2, v7, 0x8, s[60:61]                // blockWidth = (blockId < numFullBlocks) ? WGM : remainder
DYNAMIC_VECTOR_DIVIDE 3 6 5 2 0 1 60
v_mul_lo_u32 v4, v4, 8                             // blockId * WGM
_v_add_co_u32 v6, vcc, v6, v4                      // wg1 += blockId * WGM
v_readfirstlane_b32 s[sgprWorkGroup0], v3          // 
v_readfirstlane_b32 s[sgprWorkGroup1], v6          // 

/* global read addresses: tile offset assignment a */
/* LVCA = 32 */
/* v0 = (local)groA-tile = serial%LVCA (note (wgA*MTA) will be added to SRD) */
/* v1 = groA-unroll = serial/LVCA */
v_lshrrev_b32 v1, 5, v[vgprSerial]                 // vectorStaticDiv: v1 = v[vgprSerial] / 32
v_and_b32 v0, 31, v[vgprSerial]                    // vectorStaticDiv: v0 = v[vgprSerial] % 32

/* global read addresses: tile offset assignment b */
/* LVCB = 32 */
/* v2 = (local)groB-tile = serial%LVCB (note (wgB*MTB) will be added to SRD) */
/* v3 = groB-unroll = serial/LVCB */
v_lshrrev_b32 v3, 5, v[vgprSerial]                 // vectorStaticDiv: v3 = v[vgprSerial] / 32
v_and_b32 v2, 31, v[vgprSerial]                    // vectorStaticDiv: v2 = v[vgprSerial] % 32
/* gro-tile *= glvw */
v_lshlrev_b32 v2, 1, v2                            // staticMultiply: v2 = v2 * 2

/* global read addresses: unroll assignment a */
/* v1 */

/* global read addresses: unroll assignment b */
/* v3 */

/* global read addresses: other free assignments */
/* s[sgprWorkGroup2] */

/* global read addresses: tile offsets a */
v_mov_b32 v4, v0                                   // groA0I_0

/* global read addresses: tile offsets b */
v_mov_b32 v5, v2                                   // groB1J_0

/* global read addresses: unroll offsets a */
v_mov_b32 v6, v1                                   // groAL_0

/* global read addresses: unroll offsets b */
v_mov_b32 v7, v3                                   // groBL_0

/* global read addresses: shift b */
s_mul_i32 s59, s[sgprWorkGroup1], 64               // WorkGroup[01] * MT
s_sub_u32 s59, s[sgprSizesFree+1], s59             // edge = Size1J - WG*MT
s_sub_u32 s59, s59, 2                              // edge -= margin
v_mov_b32 v8, s59                                  // edge vgpr = Size1J-2
_v_add_co_u32 v9, vcc, v8, 2                       // add srdShiftLift
_v_add_co_u32 v10, vcc, v5, 2                      // 
v_cmp_lt_u32 s[60:61], v10, v9                     // offset < edge
v_cndmask_b32 v5, v8, v5, s[60:61]                 // offset = (offset < edge) ? offset : edge

/* global read addresses: final offsets a */
GLOBAL_OFFSET_A vgprGlobalReadOffsetA+0,  4,  6, 8 // gROA_0_0_0_0

/* global read addresses: final offsets b */
GLOBAL_OFFSET_B vgprGlobalReadOffsetB+0,  5,  7, 8 // gROB_0_0_0_0

/* global read addresses: apply user offsets */
/* moved earlier */

/* global read addresses: addresses a */
/* max read offset = size[n] * stride[n-1] */
s_mul_hi_u32 s65, s[sgprWorkGroup0], 32            // WorkGroup[01] * MT
s_mul_i32 s64, s[sgprWorkGroup0], 32               // WorkGroup[01] * MT
s_sub_u32 s[sgprSrdShadowLimitA+0], s[sgprTensor2dSizeA], s64 // sub tileStart
s_subb_u32 s[sgprSrdShadowLimitA+1], s[sgprTensor2dSizeA+1], s65 // sub tileStart
s_lshl_b64 s[sgprSrdShadowLimitA:sgprSrdShadowLimitA+1], s[sgprSrdShadowLimitA:sgprSrdShadowLimitA+1], 0x3 // Set limit to use bytes
s_add_u32 s[sgprSrdShadowLimitA+0], s[sgprSrdShadowLimitA+0], 8 // extend limit for pre-pad
s_addc_u32 s[sgprSrdShadowLimitA+1], s[sgprSrdShadowLimitA+1], 0 // extend limit for pre-pad
s_cmp_eq_u32 s[sgprSrdShadowLimitA+1], 0           // are we within 2^32?
s_cselect_b32 s[sgprSrdA+2], s[sgprSrdShadowLimitA+0], BufferLimit // Move shadow to real if we are within 2^32
s_mul_hi_u32 s61, s[sgprStridesA+1], s[sgprWorkGroup2] // Stride*WG
s_mul_i32 s60, s[sgprStridesA+1], s[sgprWorkGroup2] // Stride*WG
s_add_u32 s64, s64, s60                            // accum wg term to tilestart
s_addc_u32 s65, s65, s61                           // accum wg term to tilestart
s_lshl_b64 s[64:65], s[64:65], 3                   // tileStart *= BPE
s_add_u32 s[sgprSrdA+0], s[sgprAddressA+0], s64    // SRD_base = Address+ tileStart0
s_addc_u32 s[sgprSrdA+1], s[sgprAddressA+1], s65   // SRD_base = Address+ tileStart1
s_sub_u32 s[sgprSrdA+0], s[sgprSrdA+0], 8          // pre-pad to make room for possible pointer shift
s_subb_u32 s[sgprSrdA+1], s[sgprSrdA+1], 0         // pre-pad to make room for possible pointer shift
s_mov_b32 s[sgprSrdA+3], Srd127_96                 // Set bits 127_96 in SRD

/* global read addresses: addresses b */
/* max read offset = size[n] * stride[n-1] */
s_mul_hi_u32 s65, s[sgprWorkGroup1], 64            // WorkGroup[01] * MT
s_mul_i32 s64, s[sgprWorkGroup1], 64               // WorkGroup[01] * MT
s_sub_u32 s[sgprSrdShadowLimitB+0], s[sgprTensor2dSizeB], s64 // sub tileStart
s_subb_u32 s[sgprSrdShadowLimitB+1], s[sgprTensor2dSizeB+1], s65 // sub tileStart
s_lshl_b64 s[sgprSrdShadowLimitB:sgprSrdShadowLimitB+1], s[sgprSrdShadowLimitB:sgprSrdShadowLimitB+1], 0x3 // Set limit to use bytes
s_add_u32 s[sgprSrdShadowLimitB+0], s[sgprSrdShadowLimitB+0], 16 // extend limit for pre-pad
s_addc_u32 s[sgprSrdShadowLimitB+1], s[sgprSrdShadowLimitB+1], 0 // extend limit for pre-pad
s_cmp_eq_u32 s[sgprSrdShadowLimitB+1], 0           // are we within 2^32?
s_cselect_b32 s[sgprSrdB+2], s[sgprSrdShadowLimitB+0], BufferLimit // Move shadow to real if we are within 2^32
s_mul_hi_u32 s61, s[sgprStridesB+1], s[sgprWorkGroup2] // Stride*WG
s_mul_i32 s60, s[sgprStridesB+1], s[sgprWorkGroup2] // Stride*WG
s_add_u32 s64, s64, s60                            // accum wg term to tilestart
s_addc_u32 s65, s65, s61                           // accum wg term to tilestart
s_lshl_b64 s[64:65], s[64:65], 3                   // tileStart *= BPE
s_add_u32 s[sgprSrdB+0], s[sgprAddressB+0], s64    // SRD_base = Address+ tileStart0
s_addc_u32 s[sgprSrdB+1], s[sgprAddressB+1], s65   // SRD_base = Address+ tileStart1
s_sub_u32 s[sgprSrdB+0], s[sgprSrdB+0], 16         // pre-pad to make room for possible pointer shift
s_subb_u32 s[sgprSrdB+1], s[sgprSrdB+1], 0         // pre-pad to make room for possible pointer shift
s_mov_b32 s[sgprSrdB+3], Srd127_96                 // Set bits 127_96 in SRD

/* global read addresses: increments a */
s_mul_i32 s[sgprGlobalReadIncsA+0], 0x20, s[sgprStridesA] // incr = stride*4*bytes

/* global read addresses: increments b */
s_mul_i32 s[sgprGlobalReadIncsB+0], 0x20, s[sgprStridesB] // incr = stride*4*bytes

/******************************************/
/* Local Write Addresses                  */
/******************************************/

/* local write addresses: tile assignment a */
/* lwaTileA = v0 */

/* local write addresses: tile assignment b */
/* lwaTileB = v2 */

/* local write addresses: unroll assignment a */
/* lwaUnrollA = v1 */

/* local write addresses: unroll assignment b */
/* lwaUnrollB = v3 */

/* local write addresses: first offset a */
v_mul_u32_u24 v[vgprLocalWriteAddrA], 0x20, v1     // lwAL**(MTA + PAD)
_v_add_lshl_u32 v[vgprLocalWriteAddrA], v0, v[vgprLocalWriteAddrA], 0x3 // lwFOA = (lwAA + lwAL*(MT0I+PAD))*bpe

/* local write addresses: first offset b */
v_mul_u32_u24 v[vgprLocalWriteAddrB], 0x40, v3     // lwBL**(MTB + PAD)
_v_add_lshl_u32 v[vgprLocalWriteAddrB], v2, v[vgprLocalWriteAddrB], 0x3 // lwFOB = (lwBB + lwBL*(MT1J+PAD))*bpe
_v_add_co_u32 v[vgprLocalWriteAddrB], vcc, 0x400, v[vgprLocalWriteAddrB] // lwFOB = lwB1J + lwBL*MT1J + LDS_OFFSET_B=128*8

/* local write addresses: final offsets a */

/* N/A */

/* local write addresses: final offsets b */

/* N/A */

/* local write addresses: declare addresses a */
/* N/A */

/* local write addresses: declare addresses b */
/* N/A */

/* local write addresses: init pointers a */
/* N/A */

/* local write addresses: init pointers b */
/* N/A */

/******************************************/
/* Local Read Addresses                   */
/******************************************/

/* local read addresses: tile assignments a */
/*lr0I = serial % SG0I*/
v_lshrrev_b32 v0, 3, v[vgprSerial]                 // vectorStaticDiv: v0 = v[vgprSerial] / 8
v_and_b32 v1, 7, v[vgprSerial]                     // vectorStaticDiv: v1 = v[vgprSerial] % 8

/* local read addresses: tile assignments b */
/*lr1J = (serial / SG1J) % SG1J*/
v_lshrrev_b32 v2, 4, v0                            // vectorStaticDiv: v2 = v0 / 16
v_and_b32 v3, 15, v0                               // vectorStaticDiv: v3 = v0 % 16

/* local read addresses: final offsets a */
v_lshrrev_b32 v0, 7, v[vgprSerial]                 // vectorStaticDiv: v0 = v[vgprSerial] / 128
v_and_b32 v2, 127, v[vgprSerial]                   // vectorStaticDiv: v2 = v[vgprSerial] % 128
s_mov_b32 s59, 0x20                                // MT0+PAD
v_mul_lo_u32 v0, s59, v0                           // sgid=sgid*(MT0+PAD)
v_lshlrev_b32 v1, 1, v1                            // staticMultiply: v1 = v1 * 2
_v_add_lshl_u32 v[vgprLocalReadAddrA], v0, v1, 0x3 // o = (lroA*VW+sgid*MT0)*bpe

/* local read addresses: final offsets b */
v_lshrrev_b32 v0, 7, v[vgprSerial]                 // vectorStaticDiv: v0 = v[vgprSerial] / 128
v_and_b32 v1, 127, v[vgprSerial]                   // vectorStaticDiv: v1 = v[vgprSerial] % 128
s_mov_b32 s59, 0x40                                // MT1+PAD
v_mul_lo_u32 v0, s59, v0                           // sgid=sgid*(MT1+PAD)
v_lshlrev_b32 v3, 1, v3                            // staticMultiply: v3 = v3 * 2
_v_add_lshl_u32 v[vgprLocalReadAddrB], v0, v3, 0x3 // o = (lroB*VW+sgid*MT1)*bpe

/* local read addresses: declare addresses a */
/* N/A */

/* local read addresses: declare addresses b */
_v_add_co_u32 v[vgprLocalReadAddrB+0], vcc, 0x400, v[vgprLocalReadAddrB+0] //  += LdsOffsetB (lower)

/* declare loop num iterations */
v_mov_b32 v[vgprValuC+0], 0x0                      // initC
v_mov_b32 v[vgprValuC+1], 0x0                      // initC
v_mov_b32 v[vgprValuC+2], 0x0                      // initC
v_mov_b32 v[vgprValuC+3], 0x0                      // initC
v_mov_b32 v[vgprValuC+4], 0x0                      // initC
v_mov_b32 v[vgprValuC+5], 0x0                      // initC
v_mov_b32 v[vgprValuC+6], 0x0                      // initC
v_mov_b32 v[vgprValuC+7], 0x0                      // initC
v_mov_b32 v[vgprValuC+8], 0x0                      // initC
v_mov_b32 v[vgprValuC+9], 0x0                      // initC
v_mov_b32 v[vgprValuC+10], 0x0                     // initC
v_mov_b32 v[vgprValuC+11], 0x0                     // initC
v_mov_b32 v[vgprValuC+12], 0x0                     // initC
v_mov_b32 v[vgprValuC+13], 0x0                     // initC
v_mov_b32 v[vgprValuC+14], 0x0                     // initC
v_mov_b32 v[vgprValuC+15], 0x0                     // initC
v_mov_b32 v[vgprValuC+16], 0x0                     // initC
v_mov_b32 v[vgprValuC+17], 0x0                     // initC
v_mov_b32 v[vgprValuC+18], 0x0                     // initC
v_mov_b32 v[vgprValuC+19], 0x0                     // initC
v_mov_b32 v[vgprValuC+20], 0x0                     // initC
v_mov_b32 v[vgprValuC+21], 0x0                     // initC
v_mov_b32 v[vgprValuC+22], 0x0                     // initC
v_mov_b32 v[vgprValuC+23], 0x0                     // initC
v_mov_b32 v[vgprValuC+24], 0x0                     // initC
v_mov_b32 v[vgprValuC+25], 0x0                     // initC
v_mov_b32 v[vgprValuC+26], 0x0                     // initC
v_mov_b32 v[vgprValuC+27], 0x0                     // initC
v_mov_b32 v[vgprValuC+28], 0x0                     // initC
v_mov_b32 v[vgprValuC+29], 0x0                     // initC
v_mov_b32 v[vgprValuC+30], 0x0                     // initC
v_mov_b32 v[vgprValuC+31], 0x0                     // initC
s_lshr_b32 s[sgprLoopCounters+0], s[sgprSizesSum+0], 2 // s[sgprLoopCounters+0] = s[sgprSizesSum+0] / 4
s_sub_u32 s[sgprLoopCounters+0], 0x0, s[sgprLoopCounters+0] // counterL = -sizeL

/* local read addresses: init pointers a */

/* local read addresses: init pointers b */

/* prefetch: global -> local */
s_cmp_eq_u32 s[sgprLoopCounters+0], 0x0            // numIter0I == 0
s_cbranch_scc1 label_0002                          // skip to end of prefetch last iter b/c numIter==0

/* global read a */
buffer_load_dwordx2 v[vgprG2LA+0:vgprG2LA+0+1], v[vgprGlobalReadOffsetA+0], s[sgprSrdA:sgprSrdA+3], 0, offen offset:0 // G -> Reg 0_0_0_0

/* global read b */
buffer_load_dwordx4 v[vgprG2LB+0:vgprG2LB+0+3], v[vgprGlobalReadOffsetB+0], s[sgprSrdB:sgprSrdB+3], 0, offen offset:0 // G -> Reg 0_0_0_0

/* global read inc a */
s_add_u32  s[sgprSrdA+0], s[sgprSrdA+0], s[sgprGlobalReadIncsA+0] // gra SRD += inc(lower)
s_addc_u32  s[sgprSrdA+1], s[sgprSrdA+1], 0        // gra SRD += inc(upper)
s_sub_u32 s[sgprSrdShadowLimitA+0], s[sgprSrdShadowLimitA+0], s[sgprGlobalReadIncsA+0] // limit -= inc)
s_subb_u32 s[sgprSrdShadowLimitA+1], s[sgprSrdShadowLimitA+1], 0 // limit -= inc)
s_cmp_eq_u32 s[sgprSrdShadowLimitA+1], 0           // are we within 2^32?
s_cmov_b32 s[sgprSrdA+2], s[sgprSrdShadowLimitA+0] // Move shadow to real if we are within 2^32

/* global read inc b */
s_add_u32  s[sgprSrdB+0], s[sgprSrdB+0], s[sgprGlobalReadIncsB+0] // gra SRD += inc(lower)
s_addc_u32  s[sgprSrdB+1], s[sgprSrdB+1], 0        // gra SRD += inc(upper)
s_sub_u32 s[sgprSrdShadowLimitB+0], s[sgprSrdShadowLimitB+0], s[sgprGlobalReadIncsB+0] // limit -= inc)
s_subb_u32 s[sgprSrdShadowLimitB+1], s[sgprSrdShadowLimitB+1], 0 // limit -= inc)
s_cmp_eq_u32 s[sgprSrdShadowLimitB+1], 0           // are we within 2^32?
s_cmov_b32 s[sgprSrdB+2], s[sgprSrdShadowLimitB+0] // Move shadow to real if we are within 2^32
s_waitcnt vmcnt(0) // 3wait for global read

/* local write a */
ds_write_b64 v[vgprLocalWriteAddrA], v[vgprG2LA+0:vgprG2LA+0+1] offset:0 // lwoA_0_0_0_0 = (0*LSCA) + (0*LSPA)(*MT0I+PAD) = 0 #9

/* local write b */
ds_write_b128 v[vgprLocalWriteAddrB], v[vgprG2LB+0:vgprG2LB+0+3] offset:0 // lwoB_0_0_0_0 = (0*LSCB) + (0*LSPB)(*MT1J+PAD) = 0 #10

/* local write swap a */

/* local write swap b */

/* local write init pointers a */
/* N/A */

/* local write init pointers b */
/* N/A */
s_waitcnt lgkmcnt(0) // 0wait for local write
s_barrier //

/* local read prefetch a */
ds_read_b128 v[vgprValuA_X0_I0+0:vgprValuA_X0_I0+0+3], v[vgprLocalReadAddrA] offset:0 // L -> Reg lro=0 swapByteOffset=0 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuA_X0_I0+4:vgprValuA_X0_I0+4+3], v[vgprLocalReadAddrA] offset:128 // L -> Reg lro=0 swapByteOffset=0 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read prefetch b */
ds_read_b128 v[vgprValuB_X0_I0+0:vgprValuB_X0_I0+0+3], v[vgprLocalReadAddrB] offset:0 // L -> Reg lro=0 swapByteOffset=0 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuB_X0_I0+4:vgprValuB_X0_I0+4+3], v[vgprLocalReadAddrB] offset:256 // L -> Reg lro=0 swapByteOffset=0 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read inc a */
/* N/A, lro->32 */

/* local read inc b */
/* N/A, lro->64 */

/******************************************/
/* Unrolled Loop(s) - Begin               */
/******************************************/
s_cmp_ge_i32 s[sgprLoopCounters+0], 0x0            // LoopCounterL < EndCounter
s_cbranch_scc1 label_0002                          // don't enter LoopL
label_0001:

/******************************************/
/* Unroll Loop 1/2 - Begin                */
/******************************************/

/* global read a */
s_cmp_eq_i32 s[sgprLoopCounters+0], -1             // is this the last iteration
s_cmov_b32 s[sgprGlobalReadIncsA], 0               // Set inc to 0 for last iteration
s_cmov_b32 s[sgprSrdA+2], 0                        // Set limit to 0 for last iteration
s_cmov_b32 s[sgprGlobalReadIncsB], 0               // Set inc to 0 for last iteration
s_cmov_b32 s[sgprSrdB+2], 0                        // Set limit to 0 for last iteration
buffer_load_dwordx2 v[vgprG2LA+0:vgprG2LA+0+1], v[vgprGlobalReadOffsetA+0], s[sgprSrdA:sgprSrdA+3], 0, offen offset:0 // G -> Reg 0_0_0_0

/* global read b */
buffer_load_dwordx4 v[vgprG2LB+0:vgprG2LB+0+3], v[vgprGlobalReadOffsetB+0], s[sgprSrdB:sgprSrdB+3], 0, offen offset:0 // G -> Reg 0_0_0_0

/* global read inc a */
s_add_u32  s[sgprSrdA+0], s[sgprSrdA+0], s[sgprGlobalReadIncsA+0] // gra SRD += inc(lower)
s_addc_u32  s[sgprSrdA+1], s[sgprSrdA+1], 0        // gra SRD += inc(upper)
s_sub_u32 s[sgprSrdShadowLimitA+0], s[sgprSrdShadowLimitA+0], s[sgprGlobalReadIncsA+0] // limit -= inc)
s_subb_u32 s[sgprSrdShadowLimitA+1], s[sgprSrdShadowLimitA+1], 0 // limit -= inc)
s_cmp_eq_u32 s[sgprSrdShadowLimitA+1], 0           // are we within 2^32?
s_cmov_b32 s[sgprSrdA+2], s[sgprSrdShadowLimitA+0] // Move shadow to real if we are within 2^32

/* global read inc b */
s_add_u32  s[sgprSrdB+0], s[sgprSrdB+0], s[sgprGlobalReadIncsB+0] // gra SRD += inc(lower)
s_addc_u32  s[sgprSrdB+1], s[sgprSrdB+1], 0        // gra SRD += inc(upper)
s_sub_u32 s[sgprSrdShadowLimitB+0], s[sgprSrdShadowLimitB+0], s[sgprGlobalReadIncsB+0] // limit -= inc)
s_subb_u32 s[sgprSrdShadowLimitB+1], s[sgprSrdShadowLimitB+1], 0 // limit -= inc)
s_cmp_eq_u32 s[sgprSrdShadowLimitB+1], 0           // are we within 2^32?
s_cmov_b32 s[sgprSrdB+2], s[sgprSrdShadowLimitB+0] // Move shadow to real if we are within 2^32

/* iter 0 */

/* local read a */
ds_read_b128 v[vgprValuA_X1_I0+0:vgprValuA_X1_I0+0+3], v[vgprLocalReadAddrA] offset:256 // L -> Reg lro=32 swapByteOffset=0 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuA_X1_I0+4:vgprValuA_X1_I0+4+3], v[vgprLocalReadAddrA] offset:384 // L -> Reg lro=32 swapByteOffset=0 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X1_I0+0:vgprValuB_X1_I0+0+3], v[vgprLocalReadAddrB] offset:512 // L -> Reg lro=64 swapByteOffset=0 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuB_X1_I0+4:vgprValuB_X1_I0+4+3], v[vgprLocalReadAddrB] offset:768 // L -> Reg lro=64 swapByteOffset=0 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0

/* local read increment a */
/* N/A, lro->64 */

/* local read increment b */
/* N/A, lro->128 */
s_waitcnt lgkmcnt(4) // wait for prior local read
MAC_4x4_X0

/* iter 1 */

/* local read a */
ds_read_b128 v[vgprValuA_X0_I0+0:vgprValuA_X0_I0+0+3], v[vgprLocalReadAddrA] offset:512 // L -> Reg lro=64 swapByteOffset=0 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuA_X0_I0+4:vgprValuA_X0_I0+4+3], v[vgprLocalReadAddrA] offset:640 // L -> Reg lro=64 swapByteOffset=0 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X0_I0+0:vgprValuB_X0_I0+0+3], v[vgprLocalReadAddrB] offset:1024 // L -> Reg lro=128 swapByteOffset=0 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuB_X0_I0+4:vgprValuB_X0_I0+4+3], v[vgprLocalReadAddrB] offset:1280 // L -> Reg lro=128 swapByteOffset=0 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read increment a */
/* N/A, lro->96 */

/* local read increment b */
/* N/A, lro->192 */
s_waitcnt lgkmcnt(4) // wait for prior local read
MAC_4x4_X1

/* iter 2 (swap local pointers iteration) */

/* local read a */
ds_read_b128 v[vgprValuA_X1_I0+0:vgprValuA_X1_I0+0+3], v[vgprLocalReadAddrA] offset:768 // L -> Reg lro=96 swapByteOffset=0 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuA_X1_I0+4:vgprValuA_X1_I0+4+3], v[vgprLocalReadAddrA] offset:896 // L -> Reg lro=96 swapByteOffset=0 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X1_I0+0:vgprValuB_X1_I0+0+3], v[vgprLocalReadAddrB] offset:1536 // L -> Reg lro=192 swapByteOffset=0 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuB_X1_I0+4:vgprValuB_X1_I0+4+3], v[vgprLocalReadAddrB] offset:1792 // L -> Reg lro=192 swapByteOffset=0 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0
s_waitcnt vmcnt(0) // 4wait for global read

/* local write a */
ds_write_b64 v[vgprLocalWriteAddrA], v[vgprG2LA+0:vgprG2LA+0+1] offset:4096 // lwoA_0_0_0_0 = (0*LSCA) + (0*LSPA)(*MT0I+PAD) = 4096 #11

/* local write b */
ds_write_b128 v[vgprLocalWriteAddrB], v[vgprG2LB+0:vgprG2LB+0+3] offset:4096 // lwoB_0_0_0_0 = (0*LSCB) + (0*LSPB)(*MT1J+PAD) = 4096 #12

/* local write swap offsets a */

/* local write swap offsets b */

/* local write init pointers a */
/* N/A */

/* local write init pointers b */
/* N/A */

/* local read swap offsets a */

/* local read swap internal offset -> 4096 */

/* local read swap offsets b */

/* local read swap internal offset -> 4096 */

/* local read init pointers a */

/* local read init pointers b */
s_waitcnt lgkmcnt(6) // wait for prior local read
MAC_4x4_X0

/* iter 3 (last) */
s_waitcnt lgkmcnt(0) // 3wait for local write
s_barrier //

/* local read a */
ds_read_b128 v[vgprValuA_X0_I0+0:vgprValuA_X0_I0+0+3], v[vgprLocalReadAddrA] offset:4096 // L -> Reg lro=0 swapByteOffset=4096 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuA_X0_I0+4:vgprValuA_X0_I0+4+3], v[vgprLocalReadAddrA] offset:4224 // L -> Reg lro=0 swapByteOffset=4096 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X0_I0+0:vgprValuB_X0_I0+0+3], v[vgprLocalReadAddrB] offset:4096 // L -> Reg lro=0 swapByteOffset=4096 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuB_X0_I0+4:vgprValuB_X0_I0+4+3], v[vgprLocalReadAddrB] offset:4352 // L -> Reg lro=0 swapByteOffset=4096 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read inc a */
/* N/A, lro->32 */

/* local read inc b */
/* N/A, lro->64 */
MAC_4x4_X1

/******************************************/
/* Unrolled Loop - End 1/2                */
/******************************************/
s_add_u32 s[sgprLoopCounters+0], s[sgprLoopCounters+0], 0x1 // inc counterL
s_cmp_eq_i32 s[sgprLoopCounters+0], 0x0            // counterL==0
s_cbranch_scc1 label_0003                          // exit LoopL

/******************************************/
/* Unroll Loop 2/2 - Begin                */
/******************************************/

/* global read a */
s_cmp_eq_i32 s[sgprLoopCounters+0], -1             // is this the last iteration
s_cmov_b32 s[sgprGlobalReadIncsA], 0               // Set inc to 0 for last iteration
s_cmov_b32 s[sgprSrdA+2], 0                        // Set limit to 0 for last iteration
s_cmov_b32 s[sgprGlobalReadIncsB], 0               // Set inc to 0 for last iteration
s_cmov_b32 s[sgprSrdB+2], 0                        // Set limit to 0 for last iteration
buffer_load_dwordx2 v[vgprG2LA+0:vgprG2LA+0+1], v[vgprGlobalReadOffsetA+0], s[sgprSrdA:sgprSrdA+3], 0, offen offset:0 // G -> Reg 0_0_0_0

/* global read b */
buffer_load_dwordx4 v[vgprG2LB+0:vgprG2LB+0+3], v[vgprGlobalReadOffsetB+0], s[sgprSrdB:sgprSrdB+3], 0, offen offset:0 // G -> Reg 0_0_0_0

/* global read inc a */
s_add_u32  s[sgprSrdA+0], s[sgprSrdA+0], s[sgprGlobalReadIncsA+0] // gra SRD += inc(lower)
s_addc_u32  s[sgprSrdA+1], s[sgprSrdA+1], 0        // gra SRD += inc(upper)
s_sub_u32 s[sgprSrdShadowLimitA+0], s[sgprSrdShadowLimitA+0], s[sgprGlobalReadIncsA+0] // limit -= inc)
s_subb_u32 s[sgprSrdShadowLimitA+1], s[sgprSrdShadowLimitA+1], 0 // limit -= inc)
s_cmp_eq_u32 s[sgprSrdShadowLimitA+1], 0           // are we within 2^32?
s_cmov_b32 s[sgprSrdA+2], s[sgprSrdShadowLimitA+0] // Move shadow to real if we are within 2^32

/* global read inc b */
s_add_u32  s[sgprSrdB+0], s[sgprSrdB+0], s[sgprGlobalReadIncsB+0] // gra SRD += inc(lower)
s_addc_u32  s[sgprSrdB+1], s[sgprSrdB+1], 0        // gra SRD += inc(upper)
s_sub_u32 s[sgprSrdShadowLimitB+0], s[sgprSrdShadowLimitB+0], s[sgprGlobalReadIncsB+0] // limit -= inc)
s_subb_u32 s[sgprSrdShadowLimitB+1], s[sgprSrdShadowLimitB+1], 0 // limit -= inc)
s_cmp_eq_u32 s[sgprSrdShadowLimitB+1], 0           // are we within 2^32?
s_cmov_b32 s[sgprSrdB+2], s[sgprSrdShadowLimitB+0] // Move shadow to real if we are within 2^32

/* iter 0 */

/* local read a */
ds_read_b128 v[vgprValuA_X1_I0+0:vgprValuA_X1_I0+0+3], v[vgprLocalReadAddrA] offset:4352 // L -> Reg lro=32 swapByteOffset=4096 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuA_X1_I0+4:vgprValuA_X1_I0+4+3], v[vgprLocalReadAddrA] offset:4480 // L -> Reg lro=32 swapByteOffset=4096 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X1_I0+0:vgprValuB_X1_I0+0+3], v[vgprLocalReadAddrB] offset:4608 // L -> Reg lro=64 swapByteOffset=4096 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuB_X1_I0+4:vgprValuB_X1_I0+4+3], v[vgprLocalReadAddrB] offset:4864 // L -> Reg lro=64 swapByteOffset=4096 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0

/* local read increment a */
/* N/A, lro->64 */

/* local read increment b */
/* N/A, lro->128 */
s_waitcnt lgkmcnt(4) // wait for prior local read
MAC_4x4_X0

/* iter 1 */

/* local read a */
ds_read_b128 v[vgprValuA_X0_I0+0:vgprValuA_X0_I0+0+3], v[vgprLocalReadAddrA] offset:4608 // L -> Reg lro=64 swapByteOffset=4096 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuA_X0_I0+4:vgprValuA_X0_I0+4+3], v[vgprLocalReadAddrA] offset:4736 // L -> Reg lro=64 swapByteOffset=4096 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X0_I0+0:vgprValuB_X0_I0+0+3], v[vgprLocalReadAddrB] offset:5120 // L -> Reg lro=128 swapByteOffset=4096 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuB_X0_I0+4:vgprValuB_X0_I0+4+3], v[vgprLocalReadAddrB] offset:5376 // L -> Reg lro=128 swapByteOffset=4096 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read increment a */
/* N/A, lro->96 */

/* local read increment b */
/* N/A, lro->192 */
s_waitcnt lgkmcnt(4) // wait for prior local read
MAC_4x4_X1

/* iter 2 (swap local pointers iteration) */

/* local read a */
ds_read_b128 v[vgprValuA_X1_I0+0:vgprValuA_X1_I0+0+3], v[vgprLocalReadAddrA] offset:4864 // L -> Reg lro=96 swapByteOffset=4096 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuA_X1_I0+4:vgprValuA_X1_I0+4+3], v[vgprLocalReadAddrA] offset:4992 // L -> Reg lro=96 swapByteOffset=4096 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X1_I0+0:vgprValuB_X1_I0+0+3], v[vgprLocalReadAddrB] offset:5632 // L -> Reg lro=192 swapByteOffset=4096 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=1 iui=0
ds_read_b128 v[vgprValuB_X1_I0+4:vgprValuB_X1_I0+4+3], v[vgprLocalReadAddrB] offset:5888 // L -> Reg lro=192 swapByteOffset=4096 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=1 iui=0
s_waitcnt vmcnt(0) // 4wait for global read

/* local write a */
ds_write_b64 v[vgprLocalWriteAddrA], v[vgprG2LA+0:vgprG2LA+0+1] offset:0 // lwoA_0_0_0_0 = (0*LSCA) + (0*LSPA)(*MT0I+PAD) = 0 #13

/* local write b */
ds_write_b128 v[vgprLocalWriteAddrB], v[vgprG2LB+0:vgprG2LB+0+3] offset:0 // lwoB_0_0_0_0 = (0*LSCB) + (0*LSPB)(*MT1J+PAD) = 0 #14

/* local write swap offsets a */

/* local write swap offsets b */

/* local write init pointers a */
/* N/A */

/* local write init pointers b */
/* N/A */

/* local read swap offsets a */

/* local read swap internal offset -> 0 */

/* local read swap offsets b */

/* local read swap internal offset -> 0 */

/* local read init pointers a */

/* local read init pointers b */
s_waitcnt lgkmcnt(6) // wait for prior local read
MAC_4x4_X0

/* iter 3 (last) */
s_waitcnt lgkmcnt(0) // 3wait for local write
s_barrier //

/* local read a */
ds_read_b128 v[vgprValuA_X0_I0+0:vgprValuA_X0_I0+0+3], v[vgprLocalReadAddrA] offset:0 // L -> Reg lro=0 swapByteOffset=0 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuA_X0_I0+4:vgprValuA_X0_I0+4+3], v[vgprLocalReadAddrA] offset:128 // L -> Reg lro=0 swapByteOffset=0 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X0_I0+0:vgprValuB_X0_I0+0+3], v[vgprLocalReadAddrB] offset:0 // L -> Reg lro=0 swapByteOffset=0 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuB_X0_I0+4:vgprValuB_X0_I0+4+3], v[vgprLocalReadAddrB] offset:256 // L -> Reg lro=0 swapByteOffset=0 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read inc a */
/* N/A, lro->32 */

/* local read inc b */
/* N/A, lro->64 */
MAC_4x4_X1

/******************************************/
/* Unrolled Loop - End 2/2 (final)        */
/******************************************/
s_add_u32 s[sgprLoopCounters+0], s[sgprLoopCounters+0], 0x1 // inc counterL
s_cmp_eq_i32 s[sgprLoopCounters+0], 0x0            // counterL==0
s_cbranch_scc1 label_0002                          // exit LoopL
s_branch label_0001                                // restart unrolled loop LoopL
label_0003: // unroll loop odditer exit
label_0002:

/******************************************/
/* Tail Loop                              */
/******************************************/

/* local write reset offsets a */

/* local write reset offsets b */
//numIterL = (((sizeL % LOCAL_DEPTHU) + LOCAL_SPLITU - 1) / LOCAL_SPLITU)
s_lshr_b32 s60, s[sgprSizesSum+0], 2               // s60 = s[sgprSizesSum+0] / 4
s_and_b32 s[sgprLoopCounters+0], 3, s[sgprSizesSum+0] // s[sgprLoopCounters+0] = s[sgprSizesSum+0] % 4
s_cmp_eq_u32 s[sgprLoopCounters+0], 0x0            // numIterL == 0
s_cbranch_scc1 label_0006                          // skip to end of tail loop b/c numIter==0
s_sub_u32 s[sgprLoopCounters+0], 0x0, s[sgprLoopCounters+0] // counterL = -sizeL

/* global read a */
/* g2l=0, load component 0 */
buffer_load_dwordx2 v[vgprG2LA+0+0:vgprG2LA+0+0+1], v[vgprGlobalReadOffsetA+0], s[sgprSrdA:sgprSrdA+3], 0, offen offset:0 // load one buffer value
_v_add_co_u32 v[vgprGlobalReadOffsetA+0], vcc, v[vgprGlobalReadOffsetA+0], 8 // graOffset += 1 * bpe

/* global read b */
/* g2l=0, load component 0 */
buffer_load_dwordx2 v[vgprG2LB+0+0:vgprG2LB+0+0+1], v[vgprGlobalReadOffsetB+0], s[sgprSrdB:sgprSrdB+3], 0, offen offset:0 // load one buffer value
/* g2l=0, load component 1 */
buffer_load_dwordx2 v[vgprG2LB+0+2:vgprG2LB+0+2+1], v[vgprGlobalReadOffsetB+0], s[sgprSrdB:sgprSrdB+3], 0, offen offset:8 // load one buffer value
_v_add_co_u32 v[vgprGlobalReadOffsetB+0], vcc, v[vgprGlobalReadOffsetB+0], 8 // graOffset += 1 * bpe
s_waitcnt vmcnt(0) // 2wait for global read
s_barrier //

/* local write init pointers a */
/* N/A */

/* local write init pointers b */
/* N/A */

/* local write a */
ds_write_b64 v[vgprLocalWriteAddrA], v[vgprG2LA+0:vgprG2LA+0+1] offset:0 // lwoA_0_0_0_0 = (0*LSCA) + (0*LSPA)(*MT0I+PAD) = 0 #15

/* local write b */
ds_write_b128 v[vgprLocalWriteAddrB], v[vgprG2LB+0:vgprG2LB+0+3] offset:0 // lwoB_0_0_0_0 = (0*LSCB) + (0*LSPB)(*MT1J+PAD) = 0 #16
s_waitcnt lgkmcnt(0) // 5wait for local write
s_barrier //

/* local read reset offsets a */
/* handled internally */
v_and_b32 v[vgprLocalReadAddrA], 0xfff, v[vgprLocalReadAddrA] // reset Red,Blk -> Red

/* local read reset offsets b */
/* handled internally */
v_and_b32 v[vgprLocalReadAddrB], 0xfff, v[vgprLocalReadAddrB] // reset Red,Blk -> Red

/* local read init pointers a */

/* local read init pointers b */

/* tail loop: macs */
s_cmp_ge_i32 s[sgprLoopCounters+0], 0x0            // LoopCounterL < EndCounter
s_cbranch_scc1 label_0006                          // don't enter LoopL
label_0005:

/* local read a */
ds_read_b128 v[vgprValuA_X0_I0+0:vgprValuA_X0_I0+0+3], v[vgprLocalReadAddrA] offset:0 // L -> Reg lro=0 swapByteOffset=0 ti=8 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuA_X0_I0+4:vgprValuA_X0_I0+4+3], v[vgprLocalReadAddrA] offset:128 // L -> Reg lro=0 swapByteOffset=0 ti=8 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read b */
ds_read_b128 v[vgprValuB_X0_I0+0:vgprValuB_X0_I0+0+3], v[vgprLocalReadAddrB] offset:0 // L -> Reg lro=0 swapByteOffset=0 ti=16 vIdx=0 rIdx=0 oIdx=0 buffer=0 iui=0
ds_read_b128 v[vgprValuB_X0_I0+4:vgprValuB_X0_I0+4+3], v[vgprLocalReadAddrB] offset:256 // L -> Reg lro=0 swapByteOffset=0 ti=16 vIdx=1 rIdx=0 oIdx=0 buffer=0 iui=0

/* local read inc a */
s_mov_b32 s59, 0x100                               // inc
_v_add_co_u32 v[vgprLocalReadAddrA], vcc, s59, v[vgprLocalReadAddrA] // lrA += 256 (LSU*(MT+PAD)*bpe)

/* local read inc b */
s_mov_b32 s59, 0x200                               // inc
_v_add_co_u32 v[vgprLocalReadAddrB], vcc, s59, v[vgprLocalReadAddrB] // lrB += 512 (LSU*(MT+PAD)*bpe)
s_waitcnt lgkmcnt(0) // 4wait for local read
MAC_4x4_X0
s_add_u32 s[sgprLoopCounters+0], s[sgprLoopCounters+0], 0x1 // inc counterL
s_cmp_eq_i32 s[sgprLoopCounters+0], 0x0            // counterL==0
s_cbranch_scc1 label_0006                          // exit LoopL
s_branch label_0005                                // restart tailLoop LoopL
label_0007: // unroll loop odditer exit
label_0006:
s_waitcnt lgkmcnt(0) & vmcnt(0)                    // wait for all summation activity

/* shift vector components d1 */
v_mov_b32 v34, s[sgprWorkGroup1]                   // 
v_mul_i32_i24 v34, -0x40, v34                      // wg*MT
_v_add_co_u32 v34, vcc, s[sgprSizesFree+1], v34    // wgMT = Size - wg*MT
v_mov_b32 v32, 0x40                                // MT
v_cmp_lt_u32 s[54:55], v34, v32                    // wgMT < MT
v_cndmask_b32 v34, v32, v34, s[54:55]              // wgMT = (wgMT < MT) ? wgMT : MT
v_lshrrev_b32 v36, 1, v34                          // vectorStaticDiv: v36 = v34 / 2
v_and_b32 v37, 1, v34                              // vectorStaticDiv: v37 = v34 % 2
v_lshrrev_b32 v38, 4, v36                          // vectorStaticDiv: v38 = v36 / 16
v_and_b32 v39, 15, v36                             // vectorStaticDiv: v39 = v36 % 16
v_lshrrev_b32 v40, 3, v[vgprSerial]                // vectorStaticDiv: v40 = v[vgprSerial] / 8
v_and_b32 v41, 15, v40                             // vectorStaticDiv: v41 = v40 % 16
v_lshrrev_b32 v40, 5, v34                          // vectorStaticDiv: v40 = v34 / 32
v_and_b32 v42, 1, v34                              // vectorStaticDiv: v42 = v34 % 2
v_mov_b32 v43, v42                                 // duplicate
v_lshrrev_b32 v42, 1, v43                          // vectorStaticDiv: v42 = v43 / 2
_v_add_co_u32 v42, vcc, v40, v42                   // vId = 2 components
v_cmp_eq_u32 s[54:55], v41, v39                    // mask
v_mov_b32 v32, s54                                 // 
v_mov_b32 v33, s55                                 // 
v_cmp_eq_u32 vcc, v37, 0x1                         // wgMT%VW == 1
s_cbranch_vccnz label_0008                         // shift d1 r=1
s_branch label_0011                                // no shifting

/******************************************/
/* shift d1 r=1                           */
/******************************************/
label_0008:
v_cmp_eq_u32 vcc, v42, 0x0                         // wgMT/(SG*VW) == 0
s_cbranch_vccnz label_0009                         // shift d1, r=1, v=0
v_cmp_eq_u32 vcc, v42, 0x1                         // wgMT/(SG*VW) == 1
s_cbranch_vccnz label_0010                         // shift d1, r=1, v=1

/* shift d1 r=1 v=0 */
label_0009:
v_cmpx_eq_u32 s[54:55], v41, v39                   // serial % SG == (wgMT/VECTOR_WIDTH)%SG
// src=4, dst=0
v_mov_b32 v0, v8                                   // rC[0+0*TT0I*VW+0*TT0I] = rC[0+0*TT0I*VW+1*TT0I]
v_mov_b32 v1, v9                                   // rC[0+0*TT0I*VW+0*TT0I] = rC[0+0*TT0I*VW+1*TT0I]
// src=5, dst=1
v_mov_b32 v2, v10                                  // rC[1+0*TT0I*VW+0*TT0I] = rC[1+0*TT0I*VW+1*TT0I]
v_mov_b32 v3, v11                                  // rC[1+0*TT0I*VW+0*TT0I] = rC[1+0*TT0I*VW+1*TT0I]
// src=6, dst=2
v_mov_b32 v4, v12                                  // rC[2+0*TT0I*VW+0*TT0I] = rC[2+0*TT0I*VW+1*TT0I]
v_mov_b32 v5, v13                                  // rC[2+0*TT0I*VW+0*TT0I] = rC[2+0*TT0I*VW+1*TT0I]
// src=7, dst=3
v_mov_b32 v6, v14                                  // rC[3+0*TT0I*VW+0*TT0I] = rC[3+0*TT0I*VW+1*TT0I]
v_mov_b32 v7, v15                                  // rC[3+0*TT0I*VW+0*TT0I] = rC[3+0*TT0I*VW+1*TT0I]
s_mov_b64 s[54:55], 0xFFFFFFFFFFFFFFFF             // to restore all threads active
s_or_saveexec_b64 vcc, s[54:55]                    // all threads active
s_branch label_0011                                // done shifting

/* shift d1 r=1 v=1 */
label_0010:
v_cmpx_eq_u32 s[54:55], v41, v39                   // serial % SG == (wgMT/VECTOR_WIDTH)%SG
// src=12, dst=8
v_mov_b32 v16, v24                                 // rC[0+1*TT0I*VW+0*TT0I] = rC[0+1*TT0I*VW+1*TT0I]
v_mov_b32 v17, v25                                 // rC[0+1*TT0I*VW+0*TT0I] = rC[0+1*TT0I*VW+1*TT0I]
// src=13, dst=9
v_mov_b32 v18, v26                                 // rC[1+1*TT0I*VW+0*TT0I] = rC[1+1*TT0I*VW+1*TT0I]
v_mov_b32 v19, v27                                 // rC[1+1*TT0I*VW+0*TT0I] = rC[1+1*TT0I*VW+1*TT0I]
// src=14, dst=10
v_mov_b32 v20, v28                                 // rC[2+1*TT0I*VW+0*TT0I] = rC[2+1*TT0I*VW+1*TT0I]
v_mov_b32 v21, v29                                 // rC[2+1*TT0I*VW+0*TT0I] = rC[2+1*TT0I*VW+1*TT0I]
// src=15, dst=11
v_mov_b32 v22, v30                                 // rC[3+1*TT0I*VW+0*TT0I] = rC[3+1*TT0I*VW+1*TT0I]
v_mov_b32 v23, v31                                 // rC[3+1*TT0I*VW+0*TT0I] = rC[3+1*TT0I*VW+1*TT0I]
s_mov_b64 s[54:55], 0xFFFFFFFFFFFFFFFF             // to restore all threads active
s_or_saveexec_b64 vcc, s[54:55]                    // all threads active
s_branch label_0011                                // done shifting
label_0011: // end shift0

/* not-LocalSplitU: global write indices */
s_mov_b32 s[sgprSrdC+0], s[sgprAddressC+0]         // init SRD base address (lower)
s_mov_b32 s[sgprSrdC+1], s[sgprAddressC+1]         // init SRD base address (upper) + other fields
s_mov_b32 s[sgprSrdC+2], 0x80000000                // 
s_mov_b32 s[sgprSrdC+3], Srd127_96                 // Set bits 127_96 in SRD
v_lshrrev_b32 v33, 3, v[vgprSerial]                // vectorStaticDiv: v33 = v[vgprSerial] / 8
v_and_b32 v32, 7, v[vgprSerial]                    // vectorStaticDiv: v32 = v[vgprSerial] % 8
v_lshlrev_b32 v32, 1, v32                          // staticMultiply: v32 = v32 * 2
v_lshlrev_b32 v33, 1, v33                          // staticMultiply: v33 = v33 * 2

s_mul_i32 s56, 0x40, s[sgprWorkGroup1]             // <- wg1*MT1
s_mul_hi_u32 s55, s56, s[sgprStridesC+0]           // Scale s56 by Stride
s_mul_i32 s54, s56, s[sgprStridesC+0]              // Scale s56 by Stride
s_lshl_b64 s[54:55], s[54:55], 3                   // scale by bpe
s_add_u32 s[sgprSrdC+0], s[sgprSrdC+0], s54        // add lo to SRD
s_addc_u32 s[sgprSrdC+1], s[sgprSrdC+1], s55       // add hi to SRD

s_mul_hi_u32 s55, s[sgprWorkGroup2], s[sgprStridesC+1] // Scale s[sgprWorkGroup2] by Stride
s_mul_i32 s54, s[sgprWorkGroup2], s[sgprStridesC+1] // Scale s[sgprWorkGroup2] by Stride
s_lshl_b64 s[54:55], s[54:55], 3                   // scale by bpe
s_add_u32 s[sgprSrdC+0], s[sgprSrdC+0], s54        // add lo to SRD
s_addc_u32 s[sgprSrdC+1], s[sgprSrdC+1], s55       // add hi to SRD

v_mul_lo_u32 v34, v33, s[sgprStridesC+0]           // rowStart vgpr

s_mul_i32 s54, 0x20, s[sgprWorkGroup0]             // s54 = wg0*MT0
_v_add_co_u32 v32, vcc, s54, v32                   // coord0 = tid0*VW + wg0*MT0
_v_add_co_u32 v33, vcc, s56, v33                   // coord1 = tid1*VW + wg1*MT1

/* not-LocalSplitU: global write */
s_mov_b32 s54, s[sgprBeta+0]                       // tmp = Beta[0]
s_or_b32 s54, s[sgprBeta+1], s54                   // tmp |= Beta[1] 
s_cmpk_eq_u32 s54, 0x0                             // Beta == 0
s_cbranch_scc0 label_0020                          // Beta not not zero; so jump to B nonzero
s_mov_b32 s54, 0x0                                 // rMT0=0
s_add_u32 s56, -0x1, s[sgprNumWorkGroups0]         // 
s_cmp_lt_u32 s[sgprWorkGroup0], s56                // wg0 < nwg0-1
s_cbranch_scc1 label_0017                          // wg0 < nwg0-1 so skip rMT0 = Size0 % MT0
s_lshr_b32 s56, s[sgprSizesFree+0], 5              // s56 = s[sgprSizesFree+0] / 32
s_and_b32 s54, 31, s[sgprSizesFree+0]              // s54 = s[sgprSizesFree+0] % 32
label_0017:
s_cmpk_gt_u32 s54, 0x0                             // rMT0 > 0
s_cbranch_scc1 label_0019                          // edges required so jump to E1
s_mov_b32 s54, 0x0                                 // rMT1=0
s_add_u32 s56, -0x1, s[sgprNumWorkGroups1]         // 
s_cmp_lt_u32 s[sgprWorkGroup1], s56                // wg1 < nwg1-1
s_cbranch_scc1 label_0018                          // wg1 < nwg1-1 so skip rMT1 = Size1 % MT1
s_lshr_b32 s56, s[sgprSizesFree+1], 6              // s56 = s[sgprSizesFree+1] / 64
s_and_b32 s54, 63, s[sgprSizesFree+1]              // s54 = s[sgprSizesFree+1] % 64
label_0018:
s_cmpk_gt_u32 s54, 0x0                             // rMT1 > 0
s_cbranch_scc1 label_0019                          // edges required so jump to E1
label_0016:

/******************************************/
/* Global Write Batch:(0,0,0,0:vw2); (0,0,1,0:vw2); (0,1,0,0:vw2); (0,1,1,0:vw2); (1,0,0,0:vw2); (1,0,1,0:vw2); (1,1,0,0:vw2); (1,1,1,0:vw2) */
/******************************************/

/* calc coords, apply mask, and issue loads (if necessary) */
/* (d1,vc1,d0,vc0)=(0,0,0,0) coordOffset1=0 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=0: d1=0 vc1=0 */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v38, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
/* (d1,vc1,d0,vc0)=(0,1,0,0) coordOffset1=1 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v39, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
/* (d1,vc1,d0,vc0)=(0,0,1,0) coordOffset1=0 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=0: d1=0 vc1=0 */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v40, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
/* (d1,vc1,d0,vc0)=(0,1,1,0) coordOffset1=1 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v41, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
/* (d1,vc1,d0,vc0)=(1,0,0,0) coordOffset1=32 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=32: d1=1 vc1=0 */
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v42, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
/* (d1,vc1,d0,vc0)=(1,1,0,0) coordOffset1=33 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v43, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
/* (d1,vc1,d0,vc0)=(1,0,1,0) coordOffset1=32 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=32: d1=1 vc1=0 */
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v44, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
/* (d1,vc1,d0,vc0)=(1,1,1,0) coordOffset1=33 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v45, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr

/* rC *= alpha batchEements=[(0, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 1, 1, 0), (1, 0, 0, 0), (1, 0, 1, 0), (1, 1, 0, 0), (1, 1, 1, 0)] */
v_mul_f64 v[vgprValuC+0:vgprValuC+0+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+0:vgprValuC+0+1] // *= alpha
v_mul_f64 v[vgprValuC+2:vgprValuC+2+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+2:vgprValuC+2+1] // *= alpha
v_mul_f64 v[vgprValuC+8:vgprValuC+8+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+8:vgprValuC+8+1] // *= alpha
v_mul_f64 v[vgprValuC+10:vgprValuC+10+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+10:vgprValuC+10+1] // *= alpha
v_mul_f64 v[vgprValuC+4:vgprValuC+4+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+4:vgprValuC+4+1] // *= alpha
v_mul_f64 v[vgprValuC+6:vgprValuC+6+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+6:vgprValuC+6+1] // *= alpha
v_mul_f64 v[vgprValuC+12:vgprValuC+12+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+12:vgprValuC+12+1] // *= alpha
v_mul_f64 v[vgprValuC+14:vgprValuC+14+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+14:vgprValuC+14+1] // *= alpha
v_mul_f64 v[vgprValuC+16:vgprValuC+16+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+16:vgprValuC+16+1] // *= alpha
v_mul_f64 v[vgprValuC+18:vgprValuC+18+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+18:vgprValuC+18+1] // *= alpha
v_mul_f64 v[vgprValuC+24:vgprValuC+24+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+24:vgprValuC+24+1] // *= alpha
v_mul_f64 v[vgprValuC+26:vgprValuC+26+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+26:vgprValuC+26+1] // *= alpha
v_mul_f64 v[vgprValuC+20:vgprValuC+20+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+20:vgprValuC+20+1] // *= alpha
v_mul_f64 v[vgprValuC+22:vgprValuC+22+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+22:vgprValuC+22+1] // *= alpha
v_mul_f64 v[vgprValuC+28:vgprValuC+28+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+28:vgprValuC+28+1] // *= alpha
v_mul_f64 v[vgprValuC+30:vgprValuC+30+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+30:vgprValuC+30+1] // *= alpha

/* apply mask, calc new C and issue write */
buffer_store_dwordx4 v[0:3], v38, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx4 v[8:11], v39, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx4 v[4:7], v40, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx4 v[12:15], v41, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx4 v[16:19], v42, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx4 v[24:27], v43, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx4 v[20:23], v44, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx4 v[28:31], v45, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
s_branch label_0027                                // jump to end
label_0019:

/******************************************/
/* Global Write Edge Batch:(0,0,0,0:vw1); (0,0,0,1:vw1); (0,0,1,0:vw1); (0,0,1,1:vw1); (0,1,0,0:vw1); (0,1,0,1:vw1); (0,1,1,0:vw1); (0,1,1,1:vw1) */
/******************************************/

/* calc coords, apply mask, and issue loads (if necessary) */
/* (d1,vc1,d0,vc0)=(0,0,0,0) coordOffset1=0 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=0: d1=0 vc1=0 */
/* coordOffset1=0, use coordVgpr1=v33 directly */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v38, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[60:61], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v38, -1, v38, s[60:61]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(0,0,0,1) coordOffset1=0 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v39, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[62:63], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v39, -1, v39, s[62:63]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(0,1,0,0) coordOffset1=1 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 1                     // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v40, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[64:65], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v40, -1, v40, s[64:65]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(0,1,0,1) coordOffset1=1 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v41, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[66:67], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v41, -1, v41, s[66:67]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(0,0,1,0) coordOffset1=0 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=0: d1=0 vc1=0 */
/* coordOffset1=0, use coordVgpr1=v33 directly */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v42, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[68:69], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v42, -1, v42, s[68:69]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(0,0,1,1) coordOffset1=0 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v43, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[70:71], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v43, -1, v43, s[70:71]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(0,1,1,0) coordOffset1=1 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 1                     // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v44, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[72:73], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v44, -1, v44, s[72:73]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(0,1,1,1) coordOffset1=1 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v45, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[74:75], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v45, -1, v45, s[74:75]               // clip if OOB. offset

/* rC *= alpha batchEements=[(0, 0, 0, 0), (0, 0, 0, 1), (0, 0, 1, 0), (0, 0, 1, 1), (0, 1, 0, 0), (0, 1, 0, 1), (0, 1, 1, 0), (0, 1, 1, 1)] */
v_mul_f64 v[vgprValuC+0:vgprValuC+0+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+0:vgprValuC+0+1] // *= alpha
v_mul_f64 v[vgprValuC+2:vgprValuC+2+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+2:vgprValuC+2+1] // *= alpha
v_mul_f64 v[vgprValuC+8:vgprValuC+8+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+8:vgprValuC+8+1] // *= alpha
v_mul_f64 v[vgprValuC+10:vgprValuC+10+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+10:vgprValuC+10+1] // *= alpha
v_mul_f64 v[vgprValuC+4:vgprValuC+4+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+4:vgprValuC+4+1] // *= alpha
v_mul_f64 v[vgprValuC+6:vgprValuC+6+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+6:vgprValuC+6+1] // *= alpha
v_mul_f64 v[vgprValuC+12:vgprValuC+12+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+12:vgprValuC+12+1] // *= alpha
v_mul_f64 v[vgprValuC+14:vgprValuC+14+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+14:vgprValuC+14+1] // *= alpha

/* apply mask, calc new C and issue write */
buffer_store_dwordx2 v[0:1], v38, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[2:3], v39, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[8:9], v40, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[10:11], v41, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[4:5], v42, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[6:7], v43, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[12:13], v44, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[14:15], v45, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C

/******************************************/
/* Global Write Edge Batch:(1,0,0,0:vw1); (1,0,0,1:vw1); (1,0,1,0:vw1); (1,0,1,1:vw1); (1,1,0,0:vw1); (1,1,0,1:vw1); (1,1,1,0:vw1); (1,1,1,1:vw1) */
/******************************************/

/* calc coords, apply mask, and issue loads (if necessary) */
/* (d1,vc1,d0,vc0)=(1,0,0,0) coordOffset1=32 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=32: d1=1 vc1=0 */
_v_add_co_u32 v37, vcc, v33, 32                    // coord1 += d1*sg1*VW + vc1
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v38, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[60:61], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v38, -1, v38, s[60:61]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(1,0,0,1) coordOffset1=32 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v39, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[62:63], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v39, -1, v39, s[62:63]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(1,1,0,0) coordOffset1=33 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 33                    // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v40, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[64:65], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v40, -1, v40, s[64:65]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(1,1,0,1) coordOffset1=33 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v41, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[66:67], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v41, -1, v41, s[66:67]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(1,0,1,0) coordOffset1=32 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=32: d1=1 vc1=0 */
_v_add_co_u32 v37, vcc, v33, 32                    // coord1 += d1*sg1*VW + vc1
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v42, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[68:69], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v42, -1, v42, s[68:69]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(1,0,1,1) coordOffset1=32 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v43, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[70:71], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v43, -1, v43, s[70:71]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(1,1,1,0) coordOffset1=33 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 33                    // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v44, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[72:73], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v44, -1, v44, s[72:73]               // clip if OOB. offset
/* (d1,vc1,d0,vc0)=(1,1,1,1) coordOffset1=33 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v45, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[74:75], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v45, -1, v45, s[74:75]               // clip if OOB. offset

/* rC *= alpha batchEements=[(1, 0, 0, 0), (1, 0, 0, 1), (1, 0, 1, 0), (1, 0, 1, 1), (1, 1, 0, 0), (1, 1, 0, 1), (1, 1, 1, 0), (1, 1, 1, 1)] */
v_mul_f64 v[vgprValuC+16:vgprValuC+16+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+16:vgprValuC+16+1] // *= alpha
v_mul_f64 v[vgprValuC+18:vgprValuC+18+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+18:vgprValuC+18+1] // *= alpha
v_mul_f64 v[vgprValuC+24:vgprValuC+24+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+24:vgprValuC+24+1] // *= alpha
v_mul_f64 v[vgprValuC+26:vgprValuC+26+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+26:vgprValuC+26+1] // *= alpha
v_mul_f64 v[vgprValuC+20:vgprValuC+20+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+20:vgprValuC+20+1] // *= alpha
v_mul_f64 v[vgprValuC+22:vgprValuC+22+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+22:vgprValuC+22+1] // *= alpha
v_mul_f64 v[vgprValuC+28:vgprValuC+28+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+28:vgprValuC+28+1] // *= alpha
v_mul_f64 v[vgprValuC+30:vgprValuC+30+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+30:vgprValuC+30+1] // *= alpha

/* apply mask, calc new C and issue write */
buffer_store_dwordx2 v[16:17], v38, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[18:19], v39, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[24:25], v40, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[26:27], v41, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[20:21], v42, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[22:23], v43, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[28:29], v44, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
buffer_store_dwordx2 v[30:31], v45, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
s_branch label_0027                                // jump to end
label_0020:
s_mov_b32 s54, 0x0                                 // rMT0=0
s_add_u32 s56, -0x1, s[sgprNumWorkGroups0]         // 
s_cmp_lt_u32 s[sgprWorkGroup0], s56                // wg0 < nwg0-1
s_cbranch_scc1 label_0024                          // wg0 < nwg0-1 so skip rMT0 = Size0 % MT0
s_lshr_b32 s56, s[sgprSizesFree+0], 5              // s56 = s[sgprSizesFree+0] / 32
s_and_b32 s54, 31, s[sgprSizesFree+0]              // s54 = s[sgprSizesFree+0] % 32
label_0024:
s_cmpk_gt_u32 s54, 0x0                             // rMT0 > 0
s_cbranch_scc1 label_0026                          // edges required so jump to E1
s_mov_b32 s54, 0x0                                 // rMT1=0
s_add_u32 s56, -0x1, s[sgprNumWorkGroups1]         // 
s_cmp_lt_u32 s[sgprWorkGroup1], s56                // wg1 < nwg1-1
s_cbranch_scc1 label_0025                          // wg1 < nwg1-1 so skip rMT1 = Size1 % MT1
s_lshr_b32 s56, s[sgprSizesFree+1], 6              // s56 = s[sgprSizesFree+1] / 64
s_and_b32 s54, 63, s[sgprSizesFree+1]              // s54 = s[sgprSizesFree+1] % 64
label_0025:
s_cmpk_gt_u32 s54, 0x0                             // rMT1 > 0
s_cbranch_scc1 label_0026                          // edges required so jump to E1
label_0023:

/******************************************/
/* Global Write Beta Batch:(0,0,0,0:vw2); (0,0,1,0:vw2); (0,1,0,0:vw2); (0,1,1,0:vw2); (1,0,0,0:vw2); (1,0,1,0:vw2); (1,1,0,0:vw2) */
/******************************************/

/* calc coords, apply mask, and issue loads (if necessary) */
/* (d1,vc1,d0,vc0)=(0,0,0,0) coordOffset1=0 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=0: d1=0 vc1=0 */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v38, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[39:42], v38, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,1,0,0) coordOffset1=1 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v43, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[44:47], v43, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,0,1,0) coordOffset1=0 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=0: d1=0 vc1=0 */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v48, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[49:52], v48, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,1,1,0) coordOffset1=1 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v53, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[54:57], v53, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,0,0,0) coordOffset1=32 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=32: d1=1 vc1=0 */
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v58, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[59:62], v58, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,1,0,0) coordOffset1=33 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v63, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[64:67], v63, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,0,1,0) coordOffset1=32 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=32: d1=1 vc1=0 */
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v68, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[69:72], v68, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc

/* rC *= alpha batchEements=[(0, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 1, 1, 0), (1, 0, 0, 0), (1, 0, 1, 0), (1, 1, 0, 0)] */
v_mul_f64 v[vgprValuC+0:vgprValuC+0+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+0:vgprValuC+0+1] // *= alpha
v_mul_f64 v[vgprValuC+2:vgprValuC+2+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+2:vgprValuC+2+1] // *= alpha
v_mul_f64 v[vgprValuC+8:vgprValuC+8+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+8:vgprValuC+8+1] // *= alpha
v_mul_f64 v[vgprValuC+10:vgprValuC+10+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+10:vgprValuC+10+1] // *= alpha
v_mul_f64 v[vgprValuC+4:vgprValuC+4+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+4:vgprValuC+4+1] // *= alpha
v_mul_f64 v[vgprValuC+6:vgprValuC+6+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+6:vgprValuC+6+1] // *= alpha
v_mul_f64 v[vgprValuC+12:vgprValuC+12+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+12:vgprValuC+12+1] // *= alpha
v_mul_f64 v[vgprValuC+14:vgprValuC+14+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+14:vgprValuC+14+1] // *= alpha
v_mul_f64 v[vgprValuC+16:vgprValuC+16+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+16:vgprValuC+16+1] // *= alpha
v_mul_f64 v[vgprValuC+18:vgprValuC+18+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+18:vgprValuC+18+1] // *= alpha
v_mul_f64 v[vgprValuC+24:vgprValuC+24+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+24:vgprValuC+24+1] // *= alpha
v_mul_f64 v[vgprValuC+26:vgprValuC+26+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+26:vgprValuC+26+1] // *= alpha
v_mul_f64 v[vgprValuC+20:vgprValuC+20+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+20:vgprValuC+20+1] // *= alpha
v_mul_f64 v[vgprValuC+22:vgprValuC+22+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+22:vgprValuC+22+1] // *= alpha
s_waitcnt vmcnt(0)                                 // wait C

/* apply mask, calc new C and issue write */
v_fma_f64 v[vgprValuC+0:vgprValuC+0+1], v[39:40], s[sgprBeta:sgprBeta+1], v[vgprValuC+0:vgprValuC+0+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+2:vgprValuC+2+1], v[41:42], s[sgprBeta:sgprBeta+1], v[vgprValuC+2:vgprValuC+2+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[0:3], v38, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+8:vgprValuC+8+1], v[44:45], s[sgprBeta:sgprBeta+1], v[vgprValuC+8:vgprValuC+8+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+10:vgprValuC+10+1], v[46:47], s[sgprBeta:sgprBeta+1], v[vgprValuC+10:vgprValuC+10+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[8:11], v43, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+4:vgprValuC+4+1], v[49:50], s[sgprBeta:sgprBeta+1], v[vgprValuC+4:vgprValuC+4+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+6:vgprValuC+6+1], v[51:52], s[sgprBeta:sgprBeta+1], v[vgprValuC+6:vgprValuC+6+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[4:7], v48, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+12:vgprValuC+12+1], v[54:55], s[sgprBeta:sgprBeta+1], v[vgprValuC+12:vgprValuC+12+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+14:vgprValuC+14+1], v[56:57], s[sgprBeta:sgprBeta+1], v[vgprValuC+14:vgprValuC+14+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[12:15], v53, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+16:vgprValuC+16+1], v[59:60], s[sgprBeta:sgprBeta+1], v[vgprValuC+16:vgprValuC+16+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+18:vgprValuC+18+1], v[61:62], s[sgprBeta:sgprBeta+1], v[vgprValuC+18:vgprValuC+18+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[16:19], v58, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+24:vgprValuC+24+1], v[64:65], s[sgprBeta:sgprBeta+1], v[vgprValuC+24:vgprValuC+24+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+26:vgprValuC+26+1], v[66:67], s[sgprBeta:sgprBeta+1], v[vgprValuC+26:vgprValuC+26+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[24:27], v63, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+20:vgprValuC+20+1], v[69:70], s[sgprBeta:sgprBeta+1], v[vgprValuC+20:vgprValuC+20+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+22:vgprValuC+22+1], v[71:72], s[sgprBeta:sgprBeta+1], v[vgprValuC+22:vgprValuC+22+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[20:23], v68, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C

/******************************************/
/* Global Write Beta Batch:(1,1,1,0:vw2)  */
/******************************************/

/* calc coords, apply mask, and issue loads (if necessary) */
/* (d1,vc1,d0,vc0)=(1,1,1,0) coordOffset1=33 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v38, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
buffer_load_dwordx4 v[39:42], v38, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc

/* rC *= alpha batchEements=[(1, 1, 1, 0)] */
v_mul_f64 v[vgprValuC+28:vgprValuC+28+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+28:vgprValuC+28+1] // *= alpha
v_mul_f64 v[vgprValuC+30:vgprValuC+30+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+30:vgprValuC+30+1] // *= alpha
s_waitcnt vmcnt(0)                                 // wait C

/* apply mask, calc new C and issue write */
v_fma_f64 v[vgprValuC+28:vgprValuC+28+1], v[39:40], s[sgprBeta:sgprBeta+1], v[vgprValuC+28:vgprValuC+28+1] // finalSum = sum*alpha + C*beta
v_fma_f64 v[vgprValuC+30:vgprValuC+30+1], v[41:42], s[sgprBeta:sgprBeta+1], v[vgprValuC+30:vgprValuC+30+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx4 v[28:31], v38, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
s_branch label_0027                                // jump to end
label_0026:

/******************************************/
/* Global Write Beta Edge Batch:(0,0,0,0:vw1); (0,0,0,1:vw1); (0,0,1,0:vw1); (0,0,1,1:vw1); (0,1,0,0:vw1); (0,1,0,1:vw1); (0,1,1,0:vw1); (0,1,1,1:vw1) */
/******************************************/

/* calc coords, apply mask, and issue loads (if necessary) */
/* (d1,vc1,d0,vc0)=(0,0,0,0) coordOffset1=0 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=0: d1=0 vc1=0 */
/* coordOffset1=0, use coordVgpr1=v33 directly */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v38, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[60:61], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v38, -1, v38, s[60:61]               // clip if OOB. offset
buffer_load_dwordx2 v[39:40], v38, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,0,0,1) coordOffset1=0 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v41, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[62:63], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v41, -1, v41, s[62:63]               // clip if OOB. offset
buffer_load_dwordx2 v[42:43], v41, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,1,0,0) coordOffset1=1 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 1                     // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v44, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[64:65], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v44, -1, v44, s[64:65]               // clip if OOB. offset
buffer_load_dwordx2 v[45:46], v44, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,1,0,1) coordOffset1=1 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v47, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[66:67], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v47, -1, v47, s[66:67]               // clip if OOB. offset
buffer_load_dwordx2 v[48:49], v47, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,0,1,0) coordOffset1=0 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=0: d1=0 vc1=0 */
/* coordOffset1=0, use coordVgpr1=v33 directly */
v_mov_b32 v35, v34                                 // rowPtr <- rowStart (first row)
_v_add_lshl_u32 v50, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[68:69], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v50, -1, v50, s[68:69]               // clip if OOB. offset
buffer_load_dwordx2 v[51:52], v50, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,0,1,1) coordOffset1=0 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v53, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v33, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[70:71], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v53, -1, v53, s[70:71]               // clip if OOB. offset
buffer_load_dwordx2 v[54:55], v53, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,1,1,0) coordOffset1=1 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=1: d1=0 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 1                     // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v56, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[72:73], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v56, -1, v56, s[72:73]               // clip if OOB. offset
buffer_load_dwordx2 v[57:58], v56, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(0,1,1,1) coordOffset1=1 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v59, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[74:75], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v59, -1, v59, s[74:75]               // clip if OOB. offset
buffer_load_dwordx2 v[60:61], v59, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc

/* rC *= alpha batchEements=[(0, 0, 0, 0), (0, 0, 0, 1), (0, 0, 1, 0), (0, 0, 1, 1), (0, 1, 0, 0), (0, 1, 0, 1), (0, 1, 1, 0), (0, 1, 1, 1)] */
v_mul_f64 v[vgprValuC+0:vgprValuC+0+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+0:vgprValuC+0+1] // *= alpha
v_mul_f64 v[vgprValuC+2:vgprValuC+2+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+2:vgprValuC+2+1] // *= alpha
v_mul_f64 v[vgprValuC+8:vgprValuC+8+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+8:vgprValuC+8+1] // *= alpha
v_mul_f64 v[vgprValuC+10:vgprValuC+10+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+10:vgprValuC+10+1] // *= alpha
v_mul_f64 v[vgprValuC+4:vgprValuC+4+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+4:vgprValuC+4+1] // *= alpha
v_mul_f64 v[vgprValuC+6:vgprValuC+6+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+6:vgprValuC+6+1] // *= alpha
v_mul_f64 v[vgprValuC+12:vgprValuC+12+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+12:vgprValuC+12+1] // *= alpha
v_mul_f64 v[vgprValuC+14:vgprValuC+14+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+14:vgprValuC+14+1] // *= alpha
s_waitcnt vmcnt(0)                                 // wait C

/* apply mask, calc new C and issue write */
v_fma_f64 v[vgprValuC+0:vgprValuC+0+1], v[39:40], s[sgprBeta:sgprBeta+1], v[vgprValuC+0:vgprValuC+0+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[0:1], v38, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+2:vgprValuC+2+1], v[42:43], s[sgprBeta:sgprBeta+1], v[vgprValuC+2:vgprValuC+2+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[2:3], v41, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+8:vgprValuC+8+1], v[45:46], s[sgprBeta:sgprBeta+1], v[vgprValuC+8:vgprValuC+8+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[8:9], v44, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+10:vgprValuC+10+1], v[48:49], s[sgprBeta:sgprBeta+1], v[vgprValuC+10:vgprValuC+10+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[10:11], v47, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+4:vgprValuC+4+1], v[51:52], s[sgprBeta:sgprBeta+1], v[vgprValuC+4:vgprValuC+4+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[4:5], v50, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+6:vgprValuC+6+1], v[54:55], s[sgprBeta:sgprBeta+1], v[vgprValuC+6:vgprValuC+6+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[6:7], v53, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+12:vgprValuC+12+1], v[57:58], s[sgprBeta:sgprBeta+1], v[vgprValuC+12:vgprValuC+12+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[12:13], v56, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+14:vgprValuC+14+1], v[60:61], s[sgprBeta:sgprBeta+1], v[vgprValuC+14:vgprValuC+14+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[14:15], v59, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C

/******************************************/
/* Global Write Beta Edge Batch:(1,0,0,0:vw1); (1,0,0,1:vw1); (1,0,1,0:vw1); (1,0,1,1:vw1); (1,1,0,0:vw1); (1,1,0,1:vw1); (1,1,1,0:vw1); (1,1,1,1:vw1) */
/******************************************/

/* calc coords, apply mask, and issue loads (if necessary) */
/* (d1,vc1,d0,vc0)=(1,0,0,0) coordOffset1=32 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=32: d1=1 vc1=0 */
_v_add_co_u32 v37, vcc, v33, 32                    // coord1 += d1*sg1*VW + vc1
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v38, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[60:61], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v38, -1, v38, s[60:61]               // clip if OOB. offset
buffer_load_dwordx2 v[39:40], v38, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,0,0,1) coordOffset1=32 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v41, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[62:63], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v41, -1, v41, s[62:63]               // clip if OOB. offset
buffer_load_dwordx2 v[42:43], v41, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,1,0,0) coordOffset1=33 coordOffset0=0 */
/*   coordOffset=0, use coord0=v32 directly */
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 33                    // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v44, v35, v32, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v32, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[64:65], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v44, -1, v44, s[64:65]               // clip if OOB. offset
buffer_load_dwordx2 v[45:46], v44, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,1,0,1) coordOffset1=33 coordOffset0=1 */
_v_add_co_u32 v36, vcc, v32, 1                     // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v47, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[66:67], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v47, -1, v47, s[66:67]               // clip if OOB. offset
buffer_load_dwordx2 v[48:49], v47, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,0,1,0) coordOffset1=32 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=32: d1=1 vc1=0 */
_v_add_co_u32 v37, vcc, v33, 32                    // coord1 += d1*sg1*VW + vc1
s_mul_i32 s54, s[sgprStridesC+0], 32               // scale StrideC *= coordOffset1(32)
_v_add_co_u32 v35, vcc, v34, s54                   // rowPtr <- inc for non-0 (tt1+vc1))
_v_add_lshl_u32 v50, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[68:69], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v50, -1, v50, s[68:69]               // clip if OOB. offset
buffer_load_dwordx2 v[51:52], v50, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,0,1,1) coordOffset1=32 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v53, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[70:71], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v53, -1, v53, s[70:71]               // clip if OOB. offset
buffer_load_dwordx2 v[54:55], v53, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,1,1,0) coordOffset1=33 coordOffset0=16 */
_v_add_co_u32 v36, vcc, v32, 16                    // coord0 += d0*sg0*VW + vc0
/*   new coordOffset1=33: d1=1 vc1=1 */
_v_add_co_u32 v37, vcc, v33, 33                    // coord1 += d1*sg1*VW + vc1
_v_add_co_u32 v35, vcc, v35, s[sgprStridesC+0]     // rowPtr <- move to start of new row
_v_add_lshl_u32 v56, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[72:73], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v56, -1, v56, s[72:73]               // clip if OOB. offset
buffer_load_dwordx2 v[57:58], v56, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc
/* (d1,vc1,d0,vc0)=(1,1,1,1) coordOffset1=33 coordOffset0=17 */
_v_add_co_u32 v36, vcc, v32, 17                    // coord0 += d0*sg0*VW + vc0
_v_add_lshl_u32 v59, v35, v36, 0x3                 // accumulate d0 lower and *= bpe into addr
v_cmp_lt_u32 s[54:55], v36, s[sgprSizesFree+0]     // coord0 < size0
v_cmp_lt_u32 s[56:57], v37, s[sgprSizesFree+1]     // coord1 < size1
s_and_b64 s[74:75], s[54:55], s[56:57]             // in0 && in1
v_cndmask_b32 v59, -1, v59, s[74:75]               // clip if OOB. offset
buffer_load_dwordx2 v[60:61], v59, s[sgprSrdC:sgprSrdC+3], 0, offen offset:0 // load C for beta calc

/* rC *= alpha batchEements=[(1, 0, 0, 0), (1, 0, 0, 1), (1, 0, 1, 0), (1, 0, 1, 1), (1, 1, 0, 0), (1, 1, 0, 1), (1, 1, 1, 0), (1, 1, 1, 1)] */
v_mul_f64 v[vgprValuC+16:vgprValuC+16+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+16:vgprValuC+16+1] // *= alpha
v_mul_f64 v[vgprValuC+18:vgprValuC+18+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+18:vgprValuC+18+1] // *= alpha
v_mul_f64 v[vgprValuC+24:vgprValuC+24+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+24:vgprValuC+24+1] // *= alpha
v_mul_f64 v[vgprValuC+26:vgprValuC+26+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+26:vgprValuC+26+1] // *= alpha
v_mul_f64 v[vgprValuC+20:vgprValuC+20+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+20:vgprValuC+20+1] // *= alpha
v_mul_f64 v[vgprValuC+22:vgprValuC+22+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+22:vgprValuC+22+1] // *= alpha
v_mul_f64 v[vgprValuC+28:vgprValuC+28+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+28:vgprValuC+28+1] // *= alpha
v_mul_f64 v[vgprValuC+30:vgprValuC+30+1], s[sgprAlpha:sgprAlpha+1], v[vgprValuC+30:vgprValuC+30+1] // *= alpha
s_waitcnt vmcnt(0)                                 // wait C

/* apply mask, calc new C and issue write */
v_fma_f64 v[vgprValuC+16:vgprValuC+16+1], v[39:40], s[sgprBeta:sgprBeta+1], v[vgprValuC+16:vgprValuC+16+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[16:17], v38, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+18:vgprValuC+18+1], v[42:43], s[sgprBeta:sgprBeta+1], v[vgprValuC+18:vgprValuC+18+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[18:19], v41, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+24:vgprValuC+24+1], v[45:46], s[sgprBeta:sgprBeta+1], v[vgprValuC+24:vgprValuC+24+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[24:25], v44, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+26:vgprValuC+26+1], v[48:49], s[sgprBeta:sgprBeta+1], v[vgprValuC+26:vgprValuC+26+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[26:27], v47, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+20:vgprValuC+20+1], v[51:52], s[sgprBeta:sgprBeta+1], v[vgprValuC+20:vgprValuC+20+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[20:21], v50, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+22:vgprValuC+22+1], v[54:55], s[sgprBeta:sgprBeta+1], v[vgprValuC+22:vgprValuC+22+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[22:23], v53, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+28:vgprValuC+28+1], v[57:58], s[sgprBeta:sgprBeta+1], v[vgprValuC+28:vgprValuC+28+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[28:29], v56, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
v_fma_f64 v[vgprValuC+30:vgprValuC+30+1], v[60:61], s[sgprBeta:sgprBeta+1], v[vgprValuC+30:vgprValuC+30+1] // finalSum = sum*alpha + C*beta
buffer_store_dwordx2 v[30:31], v59, s[sgprSrdC:sgprSrdC+3], 0, offen, offset:0,  // store C
s_branch label_0027                                // jump to end
label_0027:
s_endpgm                                           // End Kernel
