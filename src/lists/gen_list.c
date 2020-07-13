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

#include "lists/gen_list.h"

void gen_list_init(gen_list_t l, clear_func clear) {
    l->_begin = l->_end = NULL;
    l->_size  = 0;
    l->_clear = clear;
}

void gen_list_swap(gen_list_t l1, gen_list_t l2){
    struct gen_elmt *begin = l1->_begin;
    struct gen_elmt *end   = l1->_end  ;
    int              size  = l1->_size ;
    clear_func       clear = l1->_clear;
    l1->_begin = l2->_begin;
    l1->_end   = l2->_end;
    l1->_size  = l2->_size;
    l1->_clear = l2->_clear;
    l2->_begin = begin;
    l2->_end   = end;
    l2->_size  = size;
    l2->_clear = clear;
}

void gen_list_clear(gen_list_t l){
    struct gen_elmt * voyager = l->_begin;
    
    while (l->_begin!=l->_end) {
        voyager = l->_begin;
        l->_begin = l->_begin->_next;
        l->_clear(voyager->_elmt);
        ccluster_free(voyager->_elmt);
        ccluster_free(voyager);
    }
    
    if (l->_begin!=NULL){
        l->_clear(l->_begin->_elmt);
        ccluster_free(l->_begin->_elmt);
        ccluster_free(l->_begin);
        l->_begin = l->_end = NULL;
    }

}

void gen_list_clear_for_tables(gen_list_t l){
    struct gen_elmt * voyager = l->_begin;
    
    while (l->_begin!=l->_end) {
        voyager = l->_begin;
        l->_begin = l->_begin->_next;
        l->_clear(voyager->_elmt);
        ccluster_free(voyager);
    }
    
    if (l->_begin!=NULL){
        l->_clear(l->_begin->_elmt);
        ccluster_free(l->_begin);
        l->_begin = l->_end = NULL;
    }

}

void gen_list_push(gen_list_t l, void * data){
    struct gen_elmt * nelmt = (struct gen_elmt *) ccluster_malloc (sizeof(struct gen_elmt));
    nelmt->_elmt = data;
    nelmt->_next = NULL;
    
    if (l->_begin == NULL) {
        l->_begin = l->_end = nelmt;
    }
    else {
        l->_end->_next = nelmt;
        l->_end = nelmt;
    }
    l->_size +=1;
}

void * gen_list_pop(gen_list_t l){
    void * res;
    struct gen_elmt * temp = l->_begin;
    
    if (l->_begin == NULL) {
//         printf("ici!!!!\n");
        res = NULL;
    }
    else {
        res = l->_begin->_elmt;
        if (l->_begin == l->_end)
            l->_begin = l->_end = NULL;
        else
            l->_begin = l->_begin->_next;
        ccluster_free(temp);
        l->_size -=1;
    }
    return res;
}

void * gen_list_first(gen_list_t l){
    if (l->_begin == NULL)
        return NULL;
    else
        return (l->_begin)->_elmt;
}

void * gen_list_data_at_index(const gen_list_t l, int index){
    struct gen_elmt * voyager = l->_begin;
    for (int i=0;i<index; i++)
        voyager = voyager->_next;
    return voyager->_elmt;
}

void gen_list_insert_sorted(gen_list_t l, void * data, int (isless_func)(const void * d1, const void * d2)){
    
    struct gen_elmt * voyager = l->_begin;
    struct gen_elmt * nelmt = (struct gen_elmt *) ccluster_malloc (sizeof(struct gen_elmt));
    nelmt->_elmt = data;
    nelmt->_next = NULL;
    
    /* empty list */
    if (voyager == NULL) {
        l->_begin = l->_end = nelmt;
    }
    else{
        if ( isless_func( data, voyager->_elmt ) ){ /* insert at the beginning */
            nelmt->_next = l->_begin;
            l->_begin = nelmt;
        }
        else {
                while (voyager->_next!=NULL && isless_func( (voyager->_next->_elmt), data ))
                    voyager = voyager->_next;
            
            if (voyager->_next==NULL) { /* insert at the end */
                voyager->_next = nelmt;
                l->_end = nelmt;
            }
            else {
                nelmt->_next = voyager->_next;
                voyager->_next = nelmt;
            }
        }
    }
    l->_size +=1;
}


void gen_list_fprint(FILE * file, const gen_list_t l, void (* print_func)(FILE *, const void *) ){
    fprintf(file, "length: %d, elements: [", l->_size);
    
    struct gen_elmt * voyager = l->_begin;
    while (voyager != NULL) {
        print_func(file, voyager->_elmt);
        if (voyager->_next != NULL)
            fprintf(file, ", ");
        voyager = voyager->_next;
    }
    fprintf(file, "]");
}

int gen_list_is_empty(const gen_list_t l){
    return (l->_size==0);
}
int gen_list_get_size(const gen_list_t l){
    return l->_size;
}
