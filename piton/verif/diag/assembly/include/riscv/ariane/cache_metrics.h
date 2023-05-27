/* -----------------------------------------------
 * File           : cache_metrics.h
 * Organization   : Barcelona Supercomputing Center
 * Author(s)      : Noelia Oliete Escuin
 * Email(s)       : noelia.oliete@bsc.es
 * -----------------------------------------------*/
#ifndef __CACHE_METRICS_H
#define __CACHE_METRICS_H

#include <stdint.h>
#include <stdio.h>

#define L2_CR 0xA900000000
#define L2_ACR 0xAA00000000
#define L2_MCR 0xAB00000000
#define enable_L2_CR 0x0C00000000000000
#define zero 0x0


void reset_L2_metrics(uint8_t coreid){

    asm volatile ("sd %0,0(%1)"::"r" (zero), "r" (L2_ACR | coreid << 24));             //Reset Counter Access
    asm volatile ("sd %0,0(%1)"::"r" (zero), "r" (L2_MCR | coreid << 24));             //Reset Counter Miss
}
void init_L2_metrics(uint8_t coreid){
    asm volatile ("sd %0,0(%1)"::"r" (enable_L2_CR), "r" (L2_CR | coreid << 24));      //Init count
}
void stop_L2_metrics(uint8_t coreid){
    asm volatile ("sd %0,0(%1)"::"r" (zero), "r" (L2_CR | coreid << 24));              //Stop count
}
uint64_t read_L2_access(uint8_t coreid){
    uint64_t L2_access = zero;
    asm volatile ("ld %0,0(%1)":"=r" (L2_access):"r" (L2_ACR | coreid << 24));         //Read Counter Access
    return ((((L2_access) & 0xff00000000000000ull) >> 56)      
             | (((L2_access) & 0x00ff000000000000ull) >> 40)   
             | (((L2_access) & 0x0000ff0000000000ull) >> 24)      
             | (((L2_access) & 0x000000ff00000000ull) >> 8)      
             | (((L2_access) & 0x00000000ff000000ull) << 8)      
             | (((L2_access) & 0x0000000000ff0000ull) << 24)      
             | (((L2_access) & 0x000000000000ff00ull) << 40)      
             | (((L2_access) & 0x00000000000000ffull) << 56));
}
uint64_t read_L2_misses(uint8_t coreid){
    uint64_t L2_miss = zero;
    asm volatile ("ld %0,0(%1)":"=r" (L2_miss):"r" (L2_MCR | coreid << 24));           //Read Counter Miss
    return ((((L2_miss) & 0xff00000000000000ull) >> 56)      
             | (((L2_miss) & 0x00ff000000000000ull) >> 40)      
             | (((L2_miss) & 0x0000ff0000000000ull) >> 24)      
             | (((L2_miss) & 0x000000ff00000000ull) >> 8)      
             | (((L2_miss) & 0x00000000ff000000ull) << 8)      
             | (((L2_miss) & 0x0000000000ff0000ull) << 24)    
             | (((L2_miss) & 0x000000000000ff00ull) << 40)    
             | (((L2_miss) & 0x00000000000000ffull) << 56));
}
void print_L2_metrics(uint8_t coreid){
    
    uint64_t L2_access = read_L2_access(coreid);
    uint64_t L2_miss = read_L2_access(coreid);
    printf("L2 access: %ld\n",L2_access);
    printf("L2 miss: %ld\n",L2_miss);
}
#endif //__CACHE_METRICS_H
