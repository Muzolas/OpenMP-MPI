/*
 * MPI ve OpenMP ile Dağıtık Veri İşleme Programı
 * 
 * Bu program, büyük veri setlerini paralel olarak işlemek için
 * MPI (Message Passing Interface) ve OpenMP'yi birlikte kullanır.
 * 
 * Özellikler:
 * - MPI ile veriler farklı düğümlere dağıtılır
 * - Her düğümde OpenMP ile paralel işlem yapılır
 * - Sonuçlar tek bir düğümde toplanır
 * 
 * Kullanım:
 * mpirun -n 4 ./data_processor
 * 
 * Çıktı:
 * - Toplam veri boyutu
 * - Düğüm sayısı
 * - İşlem süresi
 * - Toplam sonuç
 */

#include <mpi.h>      
#include <omp.h>      
#include <stdio.h>   
#include <stdlib.h>   
#include <time.h>     

// Program sabitleri
#define DATA_SIZE 1000000   
#define NUM_THREADS 4        

/**
 * Rastgele veri üretme fonksiyonu
 * 
 * @param data: Verilerin saklanacağı dizi
 * @param size: Üretilecek veri sayısı
 */
void generate_data(double* data, int size) {
    for(int i = 0; i < size; i++) {
        // 0 ile 1 arasında rastgele sayılar üret
        data[i] = (double)rand() / RAND_MAX;
    }
}

/**
 * Veri parçası işleme fonksiyonu
 * OpenMP ile paralel işlem yapar
 * 
 * @param chunk: İşlenecek veri parçası
 * @param chunk_size: Parça boyutu
 * @return: İşlenmiş verilerin toplamı
 */
double process_chunk(double* chunk, int chunk_size) {
    double sum = 0.0;
    // OpenMP ile paralel işlem
    #pragma omp parallel for reduction(+:sum) num_threads(NUM_THREADS)
    for(int i = 0; i < chunk_size; i++) {
        // Her veri noktası için 100 kez kare alma işlemi
        for(int j = 0; j < 100; j++) {
            sum += chunk[i] * chunk[i];
        }
    }
    return sum;
}

/**
 * Ana program
 * MPI ve OpenMP entegrasyonunu sağlar
 */
int main(int argc, char** argv) {
    int world_size, world_rank;  // MPI düğüm bilgileri
    double start_time, end_time; // Performans ölçümü için zaman değişkenleri
    
    // MPI başlatma
    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    
    // Her düğüm için veri boyutu hesaplama
    int chunk_size = DATA_SIZE / world_size;
    double* local_data = (double*)malloc(chunk_size * sizeof(double));
    
    // Master düğümde veri oluşturma ve dağıtma
    if(world_rank == 0) {
        printf("Veri işleme başlıyor...\n");
        printf("Toplam veri boyutu: %d\n", DATA_SIZE);
        printf("Düğüm sayısı: %d\n", world_size);
        printf("Her düğümdeki OpenMP iş parçacığı sayısı: %d\n", NUM_THREADS);
        
        // Tüm veriyi oluştur
        double* full_data = (double*)malloc(DATA_SIZE * sizeof(double));
        generate_data(full_data, DATA_SIZE);
        
        // Veriyi düğümlere dağıt
        MPI_Scatter(full_data, chunk_size, MPI_DOUBLE, local_data, chunk_size, MPI_DOUBLE, 0, MPI_COMM_WORLD);
        free(full_data);
    } else {
        // Worker düğümlerde veri al
        MPI_Scatter(NULL, chunk_size, MPI_DOUBLE, local_data, chunk_size, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    }
    
    // OpenMP ile paralel işlem
    start_time = MPI_Wtime();
    double local_sum = process_chunk(local_data, chunk_size);
    end_time = MPI_Wtime();
    
    // Sonuçları topla
    double global_sum;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    
    // Master düğümde sonuçları göster
    if(world_rank == 0) {
        printf("\nSonuçlar:\n");
        printf("Toplam işlem süresi: %f saniye\n", end_time - start_time);
        printf("Toplam sonuç: %f\n", global_sum);
        printf("İşlem tamamlandı!\n");
    }
    
    // Belleği temizle
    free(local_data);
    MPI_Finalize();
    return 0;
} 