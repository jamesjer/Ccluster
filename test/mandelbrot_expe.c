/* ************************************************************************** */
/*  Copyright (C) 2018 Remi Imbach                                            */
/*                                                                            */
/*  This file is part of Ccluster.                                            */
/*                                                                            */
/*  Ccluster is free software: you can redistribute it and/or modify it under */
/*  the terms of the GNU Lesser General Public License (LGPL) as published    */
/*  by the Free Software Foundation; either version 2.1 of the License, or    */
/*  (at your option) any later version.  See <http://www.gnu.org/licenses/>.  */
/* ************************************************************************** */

#include <string.h>
#include <stdio.h>
#include "polynomials/compRat_poly.h"
#include "polynomials/compApp_poly.h"
#include "polynomials/app_rat_poly.h"
#include "ccluster/ccluster.h"

#include "./parseArgs.h"

compRat_poly_t p_global;
int d_global;

void getApprox(compApp_poly_t dest, slong prec){
    compApp_poly_set_compRat_poly(dest, p_global, prec);
}

void evaluateMandelbrotFast( compApp_t dest, compApp_t dest2, const compApp_t point, slong prec ){
    compApp_one(dest);
    compApp_zero(dest2);
    
    compApp_t temp;
    compApp_init(temp);
    compApp_set(temp, dest);
    
    for (int i = 1; i <= d_global; i++){
        
        compApp_pow_si(dest, dest, 2, prec); /* Pk-1(z)*Pk-1(z)*/
        
        /*compute value of derivative*/
        compApp_mul(dest2, temp, dest2, prec); /* P'k-1(z)*Pk-1(z) */
        compApp_mul(dest2, dest2, point, prec); /* z*P'k-1(z)*Pk-1(z) */
        compApp_mul_si( dest2, dest2, 2, prec); /* 2*z*P'k-1(z)*Pk-1(z) */
        compApp_add(dest2, dest2, dest, prec); /* 2*z*P'k-1(z)*Pk-1(z) + Pk-1(z)*Pk-1(z) */
        
        /*compute value of poly*/
//         compApp_pow_si(dest, dest, 2, prec);
        compApp_mul(dest, dest, point, prec);
        compApp_add_ui(dest, dest, 1, prec);
        
        compApp_set(temp, dest);
    }
    compApp_clear(temp);
    
    return;
}

int main(int argc, char **argv){
    
    if (argc<=2){
        printf("usage: %s degree [OPTIONS] ", argv[0]);
        printf("                                 \n");
        printf("      -d , --domain: the initial region of interest\n");
        printf("                     global [default] finds all the roots\n");
        printf("                     a box, for instance 0,1,1,2,100,1 i.e. the square centered in 0/1 +i*(1/2) of width 100/1\n");
        printf("                     if a bounded box B is given, ccluster finds all natural clusters in B, and possibly some in (5/4)B \n");
        printf("      -e , --epsilon: the size of output clusters\n");
        printf("                     +inf [default] output natural clusters wits less roots than degree of input polynomial\n");
        printf("                     a positive number as 1,100 (1/100) or -53 (1/2^(-53))\n");
        printf("      -m, --mode: the version of the algorithm\n");
        printf("                     default value is \"default\"  \n");
        printf("      -v, --verbose: an integer for verbosity\n");
        printf("                     0: nothing\n");
        printf("                     1 [default]: abstract of input and output\n");
        printf("                     2: detailed reports concerning algorithm\n");
        printf("                     3: same as 2 + prints the clusters to stdout\n");
        printf("TODO: nbthreads, display precision of outout\n");
        if (argc<2)
            return -1;
    }
    
    int parse = 1;
    int degree;
    char * st;
    int verbosity = 1;
    int nbthreads = 1;
    int global = 2; /* by default, search all the roots */
    int infinity = 2;
    
    compBox_t bInit;
    realRat_t eps;
    
    char stDefault[] = "default"; 
    st = stDefault;
    
    compBox_init(bInit);
    realRat_init(eps);
    scan_epsilon( "+inf", eps );
    global = scan_initialBox( "global", bInit );
    
    parse = parse*scan_degree( argv[1], &degree);
    
    /* loop on arguments to figure out options */
    for (int arg = 2; arg< argc; arg++) {
        
        if ( (strcmp( argv[arg], "-v" ) == 0) || (strcmp( argv[arg], "--verbose" ) == 0) ) {
            if (argc>arg+1) {
                parse = parse*scan_verbosity(argv[arg+1], &verbosity );
                arg++;
            }
        }
        
        if ( (strcmp( argv[arg], "-d" ) == 0) || (strcmp( argv[arg], "--domain" ) == 0) ) {
            if (argc>arg+1) {
                global = scan_initialBox( argv[arg+1], bInit );
                if (global==1) {
                    printf("option --domain %s is not valid; doing global\n", argv[arg+1]);
                    global =2;
                }
                parse = parse*global;
                arg++;
            }
        }
        
        if ( (strcmp( argv[arg], "-e" ) == 0) || (strcmp( argv[arg], "--epsilon" ) == 0) ) {
            if (argc>arg+1) {
                infinity = scan_epsilon( argv[arg+1], eps );
                parse = parse*infinity;
                arg++;
            }
        }
        
        if ( (strcmp( argv[arg], "-m" ) == 0) || (strcmp( argv[arg], "--mode" ) == 0) ) {
            if (argc>arg+1) {
//                 parse = parse*scan_strategy( argv[arg+1], st );
                st = argv[arg+1];
                arg++;
            }
        }
        
    }
    
    realRat_poly_t pmand, pone, px;
    realRat_poly_init(pmand);
    realRat_poly_init(pone);
    realRat_poly_init(px);
    
    compRat_poly_init(p_global);
    d_global = degree;
    
    if (parse==1) {
        
        realRat_poly_one(pmand);
        realRat_poly_one(pone);
        realRat_poly_zero(px);
        realRat_poly_set_coeff_si_ui(px, 1, 1, 1);
        
        for (int i = 1; i<=degree; i++) {
            realRat_poly_pow(pmand, pmand, 2);
            realRat_poly_mul(pmand, pmand, px);
            realRat_poly_add(pmand, pmand, pone);
        }
        
        compRat_poly_set_realRat_poly(p_global,pmand);
//         printf("poly: "); compRat_poly_print(p_global); printf("\n");
        
//         ccluster_interface_func( getApprox, bInit, eps, st, verbosity);
//         ccluster_interface_func( getApprox, bInit, eps, st, nbthreads, verbosity);
        ccluster_expe_global_interface_func_eval( getApprox, evaluateMandelbrotFast, eps, st, nbthreads, verbosity);
    }
    
    realRat_poly_clear(pmand);
    realRat_poly_clear(pone);
    realRat_poly_clear(px);
    compRat_poly_clear(p_global);
    realRat_clear(eps);
    compBox_clear(bInit);
    
    flint_cleanup();
    
    return 0;
}
