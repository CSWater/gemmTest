#include<stdio.h>

#define STR(...) #__VA_ARGS__
#define SHOW_DEFINE(x) printf("%s\n", STR(x))

#define V_FMA_F64(i, j) v_fma_f64 v[vgprValuC+(i+j*6)*2:(vgprValuC+i+j*6)*2+1], v[vgprValuA_X0_I0+i*2:vgprValuA_X0_I0+i*2+1], v[vgprValuB_X0_I0+j*2:vgprValuB_X0_I0+j*2+1], v[vgprValuC+(i+j*6)*2:(vgprValuC+i+j*6)*2+1]

int main() {
  //SHOW_DEFINE(HH);
  SHOW_DEFINE(V_FMA_F64(0, 0));
  SHOW_DEFINE(V_FMA_F64(1, 0));
  SHOW_DEFINE(V_FMA_F64(2, 0));
  SHOW_DEFINE(V_FMA_F64(3, 0));
  SHOW_DEFINE(V_FMA_F64(4, 0));
  SHOW_DEFINE(V_FMA_F64(5, 0));
  SHOW_DEFINE(V_FMA_F64(0, 1));
  SHOW_DEFINE(V_FMA_F64(1, 1));
  SHOW_DEFINE(V_FMA_F64(2, 1));
  SHOW_DEFINE(V_FMA_F64(3, 1));
  SHOW_DEFINE(V_FMA_F64(4, 1));
  SHOW_DEFINE(V_FMA_F64(5, 1));
  SHOW_DEFINE(V_FMA_F64(0, 2));
  SHOW_DEFINE(V_FMA_F64(1, 2));
  SHOW_DEFINE(V_FMA_F64(2, 2));
  SHOW_DEFINE(V_FMA_F64(3, 2));
  SHOW_DEFINE(V_FMA_F64(4, 2));
  SHOW_DEFINE(V_FMA_F64(5, 2));
  SHOW_DEFINE(V_FMA_F64(0, 3));
  SHOW_DEFINE(V_FMA_F64(1, 3));
  SHOW_DEFINE(V_FMA_F64(2, 3));
  SHOW_DEFINE(V_FMA_F64(3, 3));
  SHOW_DEFINE(V_FMA_F64(4, 3));
  SHOW_DEFINE(V_FMA_F64(5, 3));
  return 0;
}



