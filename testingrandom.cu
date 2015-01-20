#include <iostream>
#include <math.h>
#include <iomanip>
#include <vector>
#include <random>
#include <sstream>

using namespace std;

__global__ void add(int *a, int *b, int *c, int n){
	int index = threadIdx.x + blockIdx.x*blockDim.x;

	c[index] = a[index] + b[index];
}

__global__ void print(int *a){
 	printf("%d \n", blockIdx.x);
}

//host ptr, device ptr
template<typename T>
void init_host_device( T* &host_ptr, T* &device_ptr, int size ){
	host_ptr = (T*) malloc( size );
	cudaMalloc( (void**)& device_ptr, size );
}

//print vector 
template<typename T>
void print( vector<T>& vec ){
	for (int i = 0; i < vec.size(); ++i){
		cout << vec[i];
	}
	cout << endl;
}

//print vector 
template<typename T>
void print( T*& vec, int size ){
	for (int i = 0; i < size; ++i){
		cout << setw(6) << vec[i];
	}
	cout << endl;
}

//host ptr, device ptr
template<typename T>
void clean_host_device( T* &host_ptr, T* &device_ptr ){
	free( host_ptr );
	cudaFree( device_ptr );
}

/*double Random( int High, int Low )
{
    //se usa la funcion time(NULL) para no tener siempre la misma secuencia de aleatorios
    srand( ( unsigned int )time( NULL ) );
    //retorna el numero aleatorio
    return ( (double)rand()/RAND_MAX) * (High - Low) + Low;
}
*/

//print vector 
template<typename T>
void init_rand( T*& vec, int size, int low, int high, int type ){
	//srand
	if( type == 0 ){
		srand( time( NULL ) ); 
		
		for (int i = 0; i < size; ++i){
			vec[i] = rand()%(high-low) + low ;
		}
	}
	//uniform
	else if( type == 1 ){		
		default_random_engine rng(random_device{}()); 		
		uniform_int_distribution<T> dist( low, high );

		for (int i = 0; i < size; ++i){
			vec[i] = dist(rng) ;
		}	
	}
}

template <typename T>
inline void str2num(string str, T& num){
	if ( ! (istringstream(str) >> num) ) num = 0;
}

void test( int N, int M, int type ){
	
	int *a,*b,*c;					// host copies of a,b,c
	int *d_a, *d_b, *d_c;		// device copies of a,b,c
	int size = N * sizeof(int);

	// Allocate space for device copies of a,b,c
	// Alloc space for host copies of a,b,c and setup input
	init_host_device( a, d_a, size);
	init_host_device( b, d_b, size);
	init_host_device( c, d_c, size);

	init_rand( a, N, 0, N, type );
	init_rand( b, N, 0, N*N, type );

	// Copy inputs to device
	cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);  // Args: Dir. destino, Dir. origen, tamano de dato, sentido del envio
	cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);

	// Launch add() kernel on GPU
	add<<<(N+M-1)/M,M>>> (d_a, d_b, d_c, N);

	// Copy result back to host
	cudaMemcpy(c, d_c, size, cudaMemcpyDeviceToHost);

	// print( a, N );
	// print( b, N );
	// print( c, N );

	// Cleanup
	clean_host_device( a, d_a );
	clean_host_device( b, d_b );
	clean_host_device( c, d_c );

}

int main( int argc, char** argv ){

	int N , M ;

	string par = argv[1]; str2num( par, N); 
	par = argv[2]; str2num( par, M);

	time_t timer = time(0);	

	test( N, M, 0 );

	time_t timer2 = time(0);
	cout <<"Tiempo total: " << difftime(timer2, timer) << endl;
	
	timer = time(0);	
	
	test( N, M, 1 );
	
	timer2 = time(0);
	
	cout <<"Tiempo total: " << difftime(timer2, timer) << endl;

	return 0;
}