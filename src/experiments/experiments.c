#include <stdio.h>
#include <libgen.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <time.h>
#include <stdbool.h>

#include "../helper/tiempo.h"
#include "../helper/libbmp.h"
#include "../helper/utils.h"

typedef struct {
    bool cached;
    bool C;
    bool ASM;
    char* experiment_name;
    char* filter_name;
    char* img_path;
    char* time;
    int n_iteraciones;
    int n_nivel;
    FILE* fp;
}Config;

typedef void (filter_fn_t) (uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
typedef void (filterNivel_fn_t) (uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size, int n);

// ~~~ seteo de los filtros de la entrega en C ~~~
extern void Bordes_c_O3(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Bordes_c_O2(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Bordes_c_O1(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Bordes_c_O0(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos_c_O3(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos_c_O2(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos_c_O1(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos_c_O0(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Nivel_c_O3(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size, int n);
extern void Nivel_c_O2(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size, int n);
extern void Nivel_c_O1(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size, int n);
extern void Nivel_c_O0(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size, int n);
// ~~~ seteo de los filtros de la entrega en ASM ~~~
extern void Bordes_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Nivel_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size, int n);
// ~~~ seteo de los filtros de los experimentos ~~~
extern void Bordes00_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos00_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos01_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos02_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos03_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos04_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos05_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Rombos06_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
extern void Nivel00_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size, int n);

void test_filter_img_not_cached(filter_fn_t *filter, char *filterName, int convert_to_8,Config config){
    unsigned long long start, end;
    unsigned long long int cant_ciclos;

    
    for (int i = 0; i < config.n_iteraciones; i++){
        BMP* src_img = bmp_read(config.img_path);
        bmp_convert_24_to_32_bpp(src_img);
        if (convert_to_8) {
            bmp_convert_32_to_8_bpp(src_img);
        }
        BMP* dst_img = bmp_copy(src_img, 0);

        int src_witdh = bmp_width(src_img);
        int src_height = bmp_height(src_img);
        int src_row_size = bmp_bytes_per_row(src_img);

        src_img->data = utils_verticalFlip(src_img->data, src_height, src_row_size);

        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);
        
        MEDIR_TIEMPO_START(start);
        // Aplicar filtro
        filter(src_img->data, dst_img->data, src_witdh, src_height, src_row_size, src_row_size);
        MEDIR_TIEMPO_STOP(end);

        cant_ciclos = end-start;

        // Salvo resultado
        fprintf(config.fp, "%s,%s,%s,%s,not_cached,%d,%d,%llu\n",config.experiment_name, filterName, config.time, basename(config.img_path),src_height,src_witdh, cant_ciclos);

        // Guardo imagen dst
        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);

        if (convert_to_8) {
            bmp_convert_8_to_32_bpp(dst_img);
        }
    
        bmp_delete(src_img);
        bmp_delete(dst_img);
    }
}

void test_filter_img_cached(filter_fn_t *filter, char *filterName, int convert_to_8,Config config){
    unsigned long long start, end;
    unsigned long long int cant_ciclos;

    BMP* src_img = bmp_read(config.img_path);
    bmp_convert_24_to_32_bpp(src_img);
    if (convert_to_8) {
        bmp_convert_32_to_8_bpp(src_img);
    }
    BMP* dst_img = bmp_copy(src_img, 1);

    int src_witdh = bmp_width(src_img);
    int src_height = bmp_height(src_img);
    int src_row_size = bmp_bytes_per_row(src_img);

    src_img->data = utils_verticalFlip(src_img->data, src_height, src_row_size);

    for (int i = 0; i < config.n_iteraciones; i++){
        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);
        
        MEDIR_TIEMPO_START(start);
        // Aplicar filtro
        filter(src_img->data, dst_img->data, src_witdh, src_height, src_row_size, src_row_size);
        MEDIR_TIEMPO_STOP(end);

        cant_ciclos = end-start;

        // Salvo resultado
        fprintf(config.fp, "%s,%s,%s,%s,cached,%d,%d,%llu\n",config.experiment_name, filterName, config.time, basename(config.img_path),src_height,src_witdh, cant_ciclos);
        // Guardo imagen dst
        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);
        if (convert_to_8) {
            bmp_convert_8_to_32_bpp(dst_img);
        }
    }
    
    bmp_delete(src_img);
    bmp_delete(dst_img);
}

void test_filter_nivel_cached(filterNivel_fn_t *filter, char *filterName,Config config){
    unsigned long long start, end;
    unsigned long long int cant_ciclos;

    BMP* src_img = bmp_read(config.img_path);
    bmp_convert_24_to_32_bpp(src_img);

    BMP* dst_img = bmp_copy(src_img, 1);

    int src_witdh = bmp_width(src_img);
    int src_height = bmp_height(src_img);
    int src_row_size = bmp_bytes_per_row(src_img);

    src_img->data = utils_verticalFlip(src_img->data, src_height, src_row_size);

    for (int i = 0; i < config.n_iteraciones; i++){
        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);

        MEDIR_TIEMPO_START(start);
        // Aplicar filtro
        filter(src_img->data, dst_img->data, src_witdh, src_height, src_row_size, src_row_size, config.n_nivel);
        MEDIR_TIEMPO_STOP(end);

        cant_ciclos = end-start;

        // Salvo resultado
        fprintf(config.fp, "%s,%s,%s,%s,cached,%d,%d,%llu\n",config.experiment_name, filterName, config.time, basename(config.img_path),src_height,src_witdh, cant_ciclos);
        // Guardo imagen dst
        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);
    }
    
    bmp_delete(src_img);
    bmp_delete(dst_img);
}


void test_filter_nivel_not_cached(filterNivel_fn_t *filter,char *filterName,Config config){
    unsigned long long start, end;
    unsigned long long int cant_ciclos;

    for (int i = 0; i < config.n_iteraciones; i++){
        BMP* src_img = bmp_read(config.img_path);
        bmp_convert_24_to_32_bpp(src_img);

        BMP* dst_img = bmp_copy(src_img, 0);

        int src_witdh = bmp_width(src_img);
        int src_height = bmp_height(src_img);
        int src_row_size = bmp_bytes_per_row(src_img);

        src_img->data = utils_verticalFlip(src_img->data, src_height, src_row_size); 

        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);

        MEDIR_TIEMPO_START(start);
        // Aplicar filtro
        filter(src_img->data, dst_img->data, src_witdh, src_height, src_row_size, src_row_size, config.n_nivel);
        MEDIR_TIEMPO_STOP(end);

        cant_ciclos = end-start;
        // Salvo resultado
        fprintf(config.fp, "%s,%s,%s,%s,not_cached,%d,%d,%llu\n",config.experiment_name, filterName, config.time, basename(config.img_path),src_height,src_witdh, cant_ciclos);

        // Guardo imagen dst
        dst_img->data = utils_verticalFlip(dst_img->data, src_height, src_row_size);

        bmp_delete(src_img);
        bmp_delete(dst_img);
    }
}

void apply_filter_nivel(Config config) {
    void (*fun_ptr)(filterNivel_fn_t*, char*,Config) = NULL;
    fun_ptr = config.cached ? &test_filter_nivel_cached : &test_filter_nivel_not_cached;
    
    if(config.C){
        (*fun_ptr)((filterNivel_fn_t*) &Nivel_c_O0, "Nivel C O0",config);
        (*fun_ptr)((filterNivel_fn_t*) &Nivel_c_O1, "Nivel C O1",config);
        (*fun_ptr)((filterNivel_fn_t*) &Nivel_c_O2,  "Nivel C O2",config);
        (*fun_ptr)((filterNivel_fn_t*) &Nivel_c_O3, "Nivel C O3",config);
    }
    if(config.ASM){
        (*fun_ptr)((filterNivel_fn_t*) &Nivel_asm, "Nivel ASM",config);
        (*fun_ptr)((filterNivel_fn_t*) &Nivel00_asm, "Nivel ASM 00",config);
    }
}

void apply_filter_bordes(Config config) {
    void (*fun_ptr)(filter_fn_t*, char*, int,Config) = NULL;
    fun_ptr = config.cached ? &test_filter_img_cached : &test_filter_img_not_cached;
    if(config.C){
        (*fun_ptr)((filter_fn_t*) &Bordes_c_O0, "Bordes C O0", 1,config);
        (*fun_ptr)((filter_fn_t*) &Bordes_c_O1, "Bordes C O1", 1,config);
        (*fun_ptr)((filter_fn_t*) &Bordes_c_O2, "Bordes C O2", 1,config);
        (*fun_ptr)((filter_fn_t*) &Bordes_c_O3, "Bordes C O3", 1,config);
    }
    if(config.ASM){
        (*fun_ptr)((filter_fn_t*) &Bordes_asm,"Bordes ASM", 1,config);
        (*fun_ptr)((filter_fn_t*) &Bordes00_asm,"Bordes ASM doble ciclo", 1,config);
    }
}

void apply_filter_rombos(Config config) {
    void (*fun_ptr)(filter_fn_t*, char*, int,Config) = NULL;
    fun_ptr = config.cached ? &test_filter_img_cached : &test_filter_img_not_cached;

    if(config.C){
        (*fun_ptr)((filter_fn_t*) &Rombos_c_O0, "Rombos C O0", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos_c_O1, "Rombos C O1", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos_c_O2, "Rombos C O2", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos_c_O3, "Rombos C O3", 0,config);
    }
    if(config.ASM){
        (*fun_ptr)((filter_fn_t*) &Rombos01_asm,"Rombos ASM 4px word", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos04_asm, "Rombos ASM 4px word mod64 shift", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos00_asm,"Rombos ASM 4px word mod64 cmp", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos06_asm, "Rombos ASM 4px word OOO", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos_asm, "Rombos ASM 8px word", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos02_asm,"Rombos ASM 8px byte", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos03_asm, "Rombos ASM 16px byte", 0,config);
        (*fun_ptr)((filter_fn_t*) &Rombos05_asm, "Rombos ASM 16px byte pblendvb", 0,config);
    }

}

void apply_filters(Config config) {
    if(strcmp(config.filter_name,"Bordes")==0)
        apply_filter_bordes(config);
    else if(strcmp(config.filter_name, "Nivel")==0)
        apply_filter_nivel(config);
    else if(strcmp(config.filter_name,"Rombos")==0)
        apply_filter_rombos(config);
}


int main( int argc, char *argv[] ) {
    // Parse arguments 
    if(argc == 9) {
        Config config;
        config.filter_name = argv[1];
        config.img_path = argv[2];
        config.n_iteraciones = atoi(argv[3]);
        config.n_nivel = atoi(argv[4]);
        config.cached = atoi(argv[5]);
        config.C = atoi(argv[6]);
        config.ASM = atoi(argv[7]);
        config.experiment_name = argv[8];
 

        time_t rawtime;
        struct tm * timeinfo;
        time ( &rawtime );
        timeinfo = localtime ( &rawtime );
        char* time = asctime (timeinfo);
        time[24] = '\0';
        config.time = time;
        
        // Create data output folder if it doesn't exist
        struct stat st = {0};
        
        if (stat("../../analysis", &st) == -1) {
            mkdir("../../analysis", 0700);
        }
       
        if(access( "../../analysis/data.csv", F_OK) != -1 ) {
            config.fp = fopen("../../analysis/data.csv", "a");
        } else {
            config.fp = fopen("../../analysis/data.csv", "a");
            fprintf(config.fp, "%s\n", "Experimento,Filtro,Corrida,Archivo,Cache,Alto,Ancho,Ciclos");
        }

        // Create image output folder if it doesn't exist
        if (stat("results", &st) == -1) {
            mkdir("results", 0700);
        }

        apply_filters(config);
        
    } else {
        printf("Uso:\n");
        printf("experiments filtro img_path n_iteraciones n_nivel cached nombre_exp\n");
        printf("filtro: filtro a usar.\n");
        printf("img_path: path de la imagen que va a ser filtrada.\n");
        printf("n_iteraciones: numero de veces que se aplicara cada filtro.\n");
        printf("n_nivel: bit a usar para el filtro de nivel.\n");
        printf("cached: si cachea primero la imagen.\n");
        printf("C: si corre filtros en C.\n");
        printf("ASM: si corre filtros en ASM.\n");
        printf("nombre_exp: nombre del experimento.\n");
    }

    return 0;
}