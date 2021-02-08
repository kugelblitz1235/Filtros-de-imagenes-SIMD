import os
import subprocess
import argparse
import time

def list_img(d):
    return [os.path.join(d, f) for f in os.listdir(d) if os.path.isfile(os.path.join(d, f))]

def correr_filtro(filtro, img_path, n_iteraciones, n_nivel, cached, C, ASM, nombre_exp):
    comando = ["./experiments", filtro, img_path, str(n_iteraciones), str(n_nivel), str(cached), str(C), str(ASM), nombre_exp]
    subprocess.run(comando, check=True)

def primerExpCvsASM(iterations,n_nivel):
    print("Corriendo primer experimento: C vs ASM")
    dir_img = "./img/exp01"
    exp_name = "CvsASM"

    for img in list_img(dir_img):
        print(img)
        correr_filtro("Rombos", img, iterations, n_nivel, 1, 1, 1, exp_name)
        print("fin rombos")
        correr_filtro("Bordes", img, iterations, n_nivel, 1, 1, 1, exp_name)
        print("fin bordes")
        correr_filtro("Nivel", img, iterations, n_nivel, 1, 1, 1, exp_name)
        print("fin nivel")

def segundoExpASM_cachedImg(iterations,n_nivel):
    print("Corriendo segundo experimento: imagen en cache vs no en cache")
    dir_img = "./img/exp01"
    exp_name = "ASM_cachedImg"

    for img in list_img(dir_img):
        print(img)
        correr_filtro("Bordes", img, iterations, n_nivel, 1, 0, 1, exp_name)
        print("fin bordes img cached")


def tercerExpASM_differentImplementations(iterations,n_nivel):
    print("Corriendo tercer experimento: diferentes implementaciones de un filtro")
    dir_img = "./img/exp01"
    exp_name = "ASM_differentImplementations"

    for img in list_img(dir_img):
        print(img)
        correr_filtro("Rombos", img, iterations, n_nivel, 1, 0, 1, exp_name)
        print("fin rombos")
        correr_filtro("Bordes", img, iterations, n_nivel, 1, 0, 1, exp_name)
        print("fin bordes")
        correr_filtro("Nivel", img, iterations, n_nivel, 1, 0, 1, exp_name)
        print("fin nivel")
 

def main(args):
    for i in range(args.n_iterations):
        print("=================== Execution number " + str(i) + " has started ===================")
        primerExpCvsASM(args.exp01_its,args.exp01_niv)
        segundoExpASM_cachedImg(args.exp02_its,args.exp02_niv)
        tercerExpASM_differentImplementations(args.exp03_its,args.exp03_niv)
        print("=================== Execution ended ===================")
        time.sleep(args.time_delay)

if __name__== "__main__":
    description = 'Experiments tool'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('--time_delay',
                        type=int,
                        default=30,
                        help='Time span between 2 executions of all experiments')
    parser.add_argument('--n_iterations',
                        type=int,
                        default=100,
                        help='Number of iterations all experiments will be executed')
    parser.add_argument('--exp01_its',
                        type=int,
                        default=10,
                        help='Experiment 01 iterations per filter')
    parser.add_argument('--exp01_niv',
                        type=int,
                        default=1,
                        help='Experiment 01 n_nivel')
    parser.add_argument('--exp02_its',
                        type=int,
                        default=10,
                        help='Experiment 02 iterations per filter')
    parser.add_argument('--exp02_niv',
                        type=int,
                        default=1,
                        help='Experiment 02 n_nivel')
    parser.add_argument('--exp03_its',
                        type=int,
                        default=10,
                        help='Experiment 03 iterations per filter')
    parser.add_argument('--exp03_niv',
                        type=int,
                        default=1,
                        help='Experiment 03 n_nivel')
    args = parser.parse_args()

    main(args)