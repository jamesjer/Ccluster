/* ************************************************************************** */
/*  Copyright (C) 2020 Remi Imbach                                            */
/*                                                                            */
/*  This file is part of Ccluster.                                            */
/*                                                                            */
/*  Ccluster is free software: you can redistribute it and/or modify it under */
/*  the terms of the GNU Lesser General Public License (LGPL) as published    */
/*  by the Free Software Foundation; either version 2.1 of the License, or    */
/*  (at your option) any later version.  See <http://www.gnu.org/licenses/>.  */
/* ************************************************************************** */

#include "tstar/tstar.h"
#include <time.h>

void tstar_real_getApproximation( realApp_poly_t res, cacheApp_t cache, slong prec, metadatas_t meta){
        clock_t start = clock();

        realApp_poly_set(res, cacheApp_getApproximation_real ( cache, prec ));

        if (metadatas_haveToCount(meta))
            metadatas_add_time_Approxi(meta, (double) (clock() - start) );
        
}

void tstar_real_taylor_shift_inplace( realApp_poly_t res, const compDsk_t d, slong prec, metadatas_t meta){
    
        clock_t start = clock();
        realApp_poly_taylorShift_in_place( res, 
                                           compRat_realref(compDsk_centerref(d)), 
                                           compDsk_radiusref(d), 
                                           prec );

        if (metadatas_haveToCount(meta))
            metadatas_add_time_Taylors(meta, (double) (clock() - start) );
}

void tstar_real_graeffe_iterations_inplace( realApp_poly_t res, int N, slong prec, metadatas_t meta){
    
        clock_t start = clock();
        for(int i = 0; i < N; i++)
            realApp_poly_oneGraeffeIteration_in_place( res, prec );
        
        if (metadatas_haveToCount(meta))
            metadatas_add_time_Graeffe(meta, (double) (clock() - start) );
}

void tstar_real_graeffe_iterations_abs_two_first_coeffs( realApp_t coeff0, realApp_t coeff1, const realApp_poly_t pApprox, int N, slong prec, metadatas_t meta){
    realApp_poly_t p1, p2;
    realApp_poly_init2(p1, realApp_poly_degree(pApprox)+1);
    realApp_poly_init2(p2, realApp_poly_degree(pApprox)+1);
    realApp_poly_set(p1, pApprox);
    slong bound = 0x1 << N; /* assume 2^N fits in an slong: N<32 for 32bits machine... */
    for( int i = 0; i < N; i++) {
        bound = bound >> 1;
//         printf("bound: %d\n", (int) bound);
        realApp_poly_oneGraeffeIteration_first_n_coeff( p2, p1, CCLUSTER_MIN(realApp_poly_degree(pApprox), bound), realApp_poly_degree(pApprox)+1, prec);
        realApp_poly_swap(p1,p2);
    }
    
    realApp_abs( coeff0, realApp_poly_getCoeff(p1, 0));
    realApp_abs( coeff1, realApp_poly_getCoeff(p1, 1));
    
    realApp_poly_clear(p1);
    realApp_poly_clear(p2);
}



tstar_res tstar_real_interface( cacheApp_t cache,
                           const compDsk_t d,
                           int max_nb_sols,    /*the maximum number of sols in the disk          */
                           int discard,        /*a flag saying if it is a discarding test or not */
                           int inNewton,      /*a flag saying if it is for newton refinement     */
                           slong prec,         /*the "default" arithmetic precision              */
                           int depth,          /*the depth for counter                           */
                           metadatas_t meta){
    slong nprec = CCLUSTER_DEFAULT_PREC;
    
    if (metadatas_usePredictPrec(meta))
        nprec = prec;
    
    if (metadatas_useTstarOptim(meta)) {
        if (discard&&CCLUSTER_V2(meta)){
            return tstar_real_optimized( cache, d, 0, discard, inNewton, nprec, depth, meta);
        }
        else {
            return tstar_real_optimized( cache, d, max_nb_sols, discard, inNewton, nprec, depth, meta);
        }
    }
    if (discard)
        return tstar_real_asInPaper( cache, d, 0, discard, inNewton, nprec, depth, meta);
    
    return tstar_real_asInPaper( cache, d, max_nb_sols, discard, inNewton, nprec, depth, meta);
    
}

tstar_res tstar_real_asInPaper( cacheApp_t cache,
                           const compDsk_t d,
                           int max_nb_sols,    /*the maximum number of sols in the disk,         */
                           int discard,        /*a flag saying if it is a discarding test or not */
                           int inNewton,      /*a flag saying if it is for newton refinement     */
                           slong prec,         /*the "default" arithmetic precision              */
                           int depth,          /*the depth for counter                           */
                           metadatas_t meta){
    
    clock_t start = clock();
    
    tstar_res res;
    res.nbOfSol = -1;
    res.appPrec = prec;
    int restemp = 0;
    int nbTaylorsRepeted = 0;
    int nbGraeffeRepeted = 0;
    int N = 0;
    slong deg = cacheApp_getDegree(cache);
    realApp_poly_t pApprox;
    realApp_poly_init2(pApprox, deg+1);
    realApp_t sum;
    realApp_init(sum);
    N = (int) 4+ceil(log2(1+log2(deg)));
    
    tstar_real_getApproximation( pApprox, cache, res.appPrec, meta);
    tstar_real_taylor_shift_inplace( pApprox, d, res.appPrec, meta);
    tstar_real_graeffe_iterations_inplace( pApprox, N, res.appPrec, meta);
    realApp_poly_sum_abs_coeffs( sum, pApprox, res.appPrec );
    
    while( (res.nbOfSol < max_nb_sols)&&(restemp==0) ){
        res.nbOfSol += 1;
        restemp = realApp_poly_TkGtilda_with_sum( pApprox, sum, res.nbOfSol, res.appPrec);
        
        while( restemp == -2 ){
            res.appPrec *=2;
            tstar_real_getApproximation( pApprox, cache, res.appPrec, meta);
            tstar_real_taylor_shift_inplace( pApprox, d, res.appPrec, meta);
            tstar_real_graeffe_iterations_inplace( pApprox, N, res.appPrec, meta);
            realApp_poly_sum_abs_coeffs( sum, pApprox, res.appPrec );
            restemp = realApp_poly_TkGtilda_with_sum( pApprox, sum, res.nbOfSol, res.appPrec);
            nbTaylorsRepeted +=1;
            nbGraeffeRepeted +=N;
        }
        if (restemp == -1)
            restemp = 0;
        
    }
        
    realApp_poly_clear(pApprox);
    realApp_clear(sum);
    
    if (restemp==0) res.nbOfSol = -1;

    if (metadatas_haveToCount(meta))
        metadatas_add_Test( meta, depth, (restemp==1), discard, inNewton, 1, nbTaylorsRepeted, N, 
                            nbGraeffeRepeted, (int) res.appPrec, (double) (clock() - start) );
    return res;
}

tstar_res tstar_real_optimized( cacheApp_t cache,
                           const compDsk_t d,
                           int max_nb_sols,   /*the maximum number of sols in the disk          */
                           int discard,       /*a flag saying if it is a discarding test or not */
                           int inNewton,      /*a flag saying if it is for newton refinement     */
                           slong prec,        /*the "default" arithmetic precision              */
                           int depth,         /*the depth for counter                           */
                           metadatas_t meta){
    
    clock_t start = clock();
    
    tstar_res res;
    res.nbOfSol = -1;
    res.appPrec = prec;
    int restemp = 0;
    int TS_has_been_computed=0;
    int nbTaylorsRepeted = 0;
    int nbGraeffeRepeted = 0;
    int nbGraeffe = 0;
    int iteration = 0;
    int N = 0;
    slong deg = cacheApp_getDegree(cache);
    realApp_poly_t pApprox;
    realApp_poly_init2(pApprox,deg+1);
    realApp_t sum;
    realApp_init(sum);
    
    realApp_t coeff0, coeff1, coeffn; /* for anticipate */
    int anticipate_already_applied = 0;
    N = (int) 4+ceil(log2(1+log2(deg)));

    if (TS_has_been_computed==0) {
        tstar_real_getApproximation( pApprox, cache, res.appPrec, meta);
        tstar_real_taylor_shift_inplace( pApprox, d, res.appPrec, meta);
    }
    
    
    if ( (discard)&&(metadatas_useAnticipate(meta)) ){
        realApp_init(coeff0);
        realApp_init(coeffn);
        
        realApp_abs( coeff0, realApp_poly_getCoeff(pApprox, 0));
        realApp_abs( coeffn, realApp_poly_getCoeff(pApprox, realApp_poly_degree(pApprox)));
        restemp = realApp_soft_compare( coeff0, coeffn, res.appPrec );
        while( restemp == -2 ){
            res.appPrec *=2;
            tstar_real_getApproximation( pApprox, cache, res.appPrec, meta);
            tstar_real_taylor_shift_inplace( pApprox, d, res.appPrec, meta);
            nbTaylorsRepeted +=1;
            realApp_abs( coeff0, realApp_poly_getCoeff(pApprox, 0) );
            realApp_abs( coeffn, realApp_poly_getCoeff(pApprox, realApp_poly_degree(pApprox)) );
            restemp = realApp_soft_compare( coeff0, coeffn, res.appPrec );
        }
            if (restemp==0)
                restemp = -1;
            else
                restemp = 0;
        
        realApp_clear(coeff0);
        realApp_clear(coeffn);
    }
    
    while( (iteration <= N)&&(restemp==0) ){
        
        if (iteration >= 1) {
            tstar_real_graeffe_iterations_inplace( pApprox, 1, res.appPrec, meta);
            nbGraeffe +=1;
        }
        
        realApp_poly_sum_abs_coeffs( sum, pApprox, res.appPrec );
        
        res.nbOfSol = -1;
        while( (res.nbOfSol < max_nb_sols)&&(restemp==0)&&(res.nbOfSol<deg) ){
            res.nbOfSol += 1;
            
            restemp = realApp_poly_TkGtilda_with_sum( pApprox, sum, res.nbOfSol, res.appPrec);
        
            while( restemp == -2 ){
                res.appPrec *=2;
                tstar_real_getApproximation( pApprox, cache, res.appPrec, meta);
                tstar_real_taylor_shift_inplace( pApprox, d, res.appPrec, meta);
                tstar_real_graeffe_iterations_inplace( pApprox, iteration, res.appPrec, meta);
                realApp_poly_sum_abs_coeffs( sum, pApprox, res.appPrec );
                restemp = realApp_poly_TkGtilda_with_sum( pApprox, sum, res.nbOfSol, res.appPrec);
                nbTaylorsRepeted +=1;
                nbGraeffeRepeted +=(iteration);
            }
        }
        
        if (restemp == -1)
            restemp = 0;
        
        if ( (discard) && (metadatas_useAnticipate(meta)) && (anticipate_already_applied==0) && (restemp == 0) ) {
           
            int test_anticipate = ((0x1 << (N-iteration)) <= (realApp_poly_degree(pApprox)/4));
            if (test_anticipate) {
                
                clock_t start2 = clock();
                
                anticipate_already_applied = 1;
                realApp_init(coeff0);
                realApp_init(coeff1);
                realApp_init(coeffn);
                
                tstar_real_graeffe_iterations_abs_two_first_coeffs( coeff0, coeff1, pApprox, N-iteration, res.appPrec, meta);
                realApp_abs( coeffn, realApp_poly_getCoeff(pApprox, realApp_poly_degree(pApprox)) );
                realApp_pow_ui( coeffn, coeffn, (ulong)(0x1 << (N-iteration)), res.appPrec);
                realApp_add(coeffn, coeffn, coeff1, res.appPrec);
                restemp = realApp_soft_compare( coeff0, coeffn, res.appPrec );
                
                if (restemp==0)
                    restemp = -1;
                else
                    restemp = 0;
        
                realApp_clear(coeff0);
                realApp_clear(coeff1);
                realApp_clear(coeffn);

                if (metadatas_haveToCount(meta)) 
                    metadatas_add_time_Anticip(meta, (double) (clock() - start2) );
           }
            
        }
        iteration +=1;
    }
    
    realApp_poly_clear(pApprox);
    realApp_clear(sum);
    
    if ((restemp==0)||(restemp==-1)) res.nbOfSol = -1;
    if (metadatas_haveToCount(meta))
        metadatas_add_Test( meta, depth, (restemp==1), discard, inNewton, 1, nbTaylorsRepeted, nbGraeffe, 
                            nbGraeffeRepeted, (int) res.appPrec, (double) (clock() - start) );
        
//     if (discard)
//         printf(" prec for discarding test: %d\n", (int) res.appPrec );
//     else
//         printf(" --- prec for validating test: %d\n", (int) res.appPrec );
    return res;
    
}

