#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Bordes_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{    
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    // Sobel

    // Gx = [ -1   0  +1 
    // 	      -2   0  +2
    // 	      -1   0  +1 ] ∗ A 
    //
    // Gy = [ -1  -2  -1
    // 	       0   0   0
    //        +1  +2  +1 ] ∗ A
    //
    // G = sqrt( Gx^2 + Gy^2)

    for (int f = 1; f < height-1; f++) {
        for (int c = 1; c < (width-1); c++) {

            int m[3][3] = { { (int)src_matrix[f-1][c-1] , (int)src_matrix[f-1][c+0] , (int)src_matrix[f-1][c+1] },
                            { (int)src_matrix[f+0][c-1] , (int)src_matrix[f+0][c+0] , (int)src_matrix[f+0][c+1] },   
                            { (int)src_matrix[f+1][c-1] , (int)src_matrix[f+1][c+0] , (int)src_matrix[f+1][c+1] } };
                            
            int gx = (m[0][0]*-1) + (m[0][1]*+0) + (m[0][2]*+1) +
                     (m[1][0]*-2) + (m[1][1]*+0) + (m[1][2]*+2) +
                     (m[2][0]*-1) + (m[2][1]*+0) + (m[2][2]*+1);

            int gy = (m[0][0]*-1) + (m[0][1]*-2) + (m[0][2]*-1) +
                     (m[1][0]*+0) + (m[1][1]*+0) + (m[1][2]*+0) +
                     (m[2][0]*+1) + (m[2][1]*+2) + (m[2][2]*+1);

            gx = gx>0 ? gx : -gx;
            gy = gy>0 ? gy : -gy;

            int g = gx+gy;

            dst_matrix[f][c] = g>255? 255 : g;
        }
    }
    
    utils_paintBorders8(dst, width, height, src_row_size, 1, 0xff);
}
