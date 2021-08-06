#include "mex.h"
#include <iostream>
#include <numeric>
#include <vector>
#include <algorithm>
#include <iterator>
#include <unordered_set>

extern "C"{
    #include "matrix.h"
    #include "math.h"
    #include <omp.h>
}

using namespace std;

#define MAX_ELEMENTS 100000
#define SMALLER_MAX 1000

static vector<int> *neighborsRegion_1 = NULL;
static vector<int> *neighborsRegion_2 = NULL;
static vector<int> *neighborsRegion_3 = NULL;

static vector<int> *faceIndex = NULL;
static vector<int> *edgeList_1 = NULL;

static vector<bool> *watersheds_equals_wLabel = NULL;

static int * facesInRegion = NULL;

static int * neighbors_ptr_int = NULL;

static vector<int> * facesAllNeighbors = NULL;

static bool * boundaryEdgesMask = NULL;

static vector<int> * boundaryEdgeList_1 = NULL;
static vector<int> * boundaryEdgeList_2 = NULL;

static int * vertexPairs_1 = NULL;
static int * vertexPairs_2 = NULL;

static int * faces_ptr_int = NULL;

static vector<double> * centered_v1 = NULL;
static vector<double> * centered_v2 = NULL;
static vector<double> * centered_v3 = NULL;

static vector<double> * centered_sum = NULL;

static vector<int> * cm_faces_1 = NULL;
static vector<int> * cm_faces_2 = NULL;
static vector<int> * cm_faces_3 = NULL;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    
    omp_set_num_threads(omp_get_max_threads());
    
    //ALLOCATE MEMORY FIRST:
    if(!neighborsRegion_1){
        cout << "allocating" << endl;
        //length facesInRegion_len
        neighborsRegion_1 = new vector<int>(MAX_ELEMENTS);
        neighborsRegion_2 = new vector<int>(MAX_ELEMENTS);        
        neighborsRegion_3 = new vector<int>(MAX_ELEMENTS);

        //length watersheds_size:
        faceIndex = new vector<int>(MAX_ELEMENTS);
        
        //length watersheds_size
        watersheds_equals_wLabel = new vector<bool>(MAX_ELEMENTS);
        
        //length facesInRegion_len
        facesInRegion = (int *) malloc(MAX_ELEMENTS * sizeof(int));
        
        //length 3*neighbors_M
        neighbors_ptr_int = (int*) malloc(3*MAX_ELEMENTS*sizeof(int));
        
        //length 3*facesInRegion_len
        edgeList_1 = new vector<int>(3*MAX_ELEMENTS) ;
        
        //length 0
        facesAllNeighbors = new vector<int>();
        
        //length N
        boundaryEdgesMask = (bool*) malloc(MAX_ELEMENTS * sizeof(bool));        
        
        //length BEM_greaterthan_zero_length
        boundaryEdgeList_1 = new vector<int>(SMALLER_MAX);
        boundaryEdgeList_2 = new vector<int>(SMALLER_MAX);
        
        //length BEM_greaterthan_zero_length
        vertexPairs_1 = (int *) malloc(SMALLER_MAX * sizeof(int));
        vertexPairs_2 = (int *) malloc(SMALLER_MAX * sizeof(int));
        
        //length 3*faces_M
        faces_ptr_int = (int*) malloc(3*MAX_ELEMENTS*sizeof(int));
        
        //length BEM_greaterthan_zero_length
        centered_v1 = new vector<double>(SMALLER_MAX); 
        centered_v2 = new vector<double>(SMALLER_MAX); 
        centered_v3 = new vector<double>(SMALLER_MAX);
        
        //length BEM_greaterthan_zero_length
        centered_sum = new vector<double>(SMALLER_MAX);
        
        //length facesInRegion_len
        cm_faces_1 = new vector<int>(MAX_ELEMENTS);
        cm_faces_2 = new vector<int>(MAX_ELEMENTS);
        cm_faces_3 = new vector<int>(MAX_ELEMENTS);
    }
    
    // Inputs:
    const double wLabel = (mxGetPr(prhs[0]))[0];   //Integer
    const mxArray * mx_faces = prhs[1];
    const mxArray * mx_vertices = prhs[2];
    const mxArray * watersheds = prhs[3];   //Vector
    const mxArray * neighbors = prhs[4];
    
    /* Find the labels of the faces in the region:
     * faceIndex = 1:length(watersheds);
     */
    size_t watersheds_size = mxGetNumberOfElements(watersheds);
    iota(begin(*faceIndex), begin(*faceIndex) + watersheds_size, 1);
        
    /*
     * facesInRegion = faceIndex'.*(wLabel==watersheds);
     * facesInRegion = facesInRegion(facesInRegion>0);
     */
    double * watersheds_ptr = mxGetPr(watersheds);
        
    //replace_copy_if(std::execution::parallel_policy, watersheds_ptr, watersheds_ptr+watersheds_size,watersheds_equals_wLabel->begin(), [&](auto i){ return i == wLabel;}, 0);
    
    // Convert watersheds to a vector:
    int facesInRegion_len = 0;
    
    for(int i = 0; i < watersheds_size; i++){
        watersheds_equals_wLabel->at(i) = watersheds_ptr[i] == wLabel;
        if(watersheds_equals_wLabel->at(i)){
            ++facesInRegion_len;
        }
    }
    
    int k = 0;
    for(int i = 0; i < watersheds_size; ++i)
        if(watersheds_equals_wLabel->at(i)){
            facesInRegion[k] = faceIndex->at(i);
            ++k;
        }


    /*
     * Make an edge list of edges associated with the region
     * neighborsRegion = neighbors.*repmat(wLabel==watersheds,1,3);
     * edgeList = [facesInRegion, neighborsRegion(neighborsRegion(:,1)>0,1); 
     *              facesInRegion, neighborsRegion(neighborsRegion(:,2)>0,2);
     *              facesInRegion, neighborsRegion(neighborsRegion(:,3)>0,3)];
     */

    double * neighbors_ptr = mxGetPr(neighbors);
    size_t neighbors_M = mxGetM(neighbors);
    
    for (int i = 0; i < 3 * neighbors_M; ++i) {
        neighbors_ptr_int[i] = (int)neighbors_ptr[i];
    }

    //vector<int> *neighbors_1 = new vector<int>(neighbors_ptr_int, neighbors_ptr_int + neighbors_M);
    //vector<int> *neighbors_2 = new vector<int>(neighbors_ptr_int + neighbors_M, neighbors_ptr_int + 2*neighbors_M);
    //vector<int> *neighbors_3 = new vector<int>(neighbors_ptr_int + 2*neighbors_M, neighbors_ptr_int + 3*neighbors_M);

    int * neighbors_1 = neighbors_ptr_int;
    int * neighbors_2 = neighbors_ptr_int + neighbors_M;
    int * neighbors_3 = neighbors_ptr_int + 2*neighbors_M;
        
    //vector<int> *neighborsRegion_1 = new vector<int>(facesInRegion_len);
    //vector<int> *neighborsRegion_2 = new vector<int>(facesInRegion_len);
    //vector<int> *neighborsRegion_3 = new vector<int>(facesInRegion_len);
        
    k = 0;
    for(int i = 0; i < watersheds_size; ++i)
        if(watersheds_equals_wLabel->at(i)){
            //length: facesInRegion_len
            neighborsRegion_1->at(k) = neighbors_1[i];
            neighborsRegion_2->at(k) = neighbors_2[i];
            neighborsRegion_3->at(k) = neighbors_3[i];
            ++k;
        }
    
    memcpy(edgeList_1->data()                       , facesInRegion, facesInRegion_len*sizeof(int));
    memcpy(edgeList_1->data() + facesInRegion_len   , facesInRegion, facesInRegion_len*sizeof(int));
    memcpy(edgeList_1->data() + 2*facesInRegion_len , facesInRegion, facesInRegion_len*sizeof(int));
        
    vector<int> * edgeList_2 = new vector<int>(*neighborsRegion_1);
    edgeList_2->insert(edgeList_2->begin() + facesInRegion_len, neighborsRegion_2->begin(), neighborsRegion_2->begin()+facesInRegion_len);
    edgeList_2->insert(edgeList_2->begin() + 2*facesInRegion_len, neighborsRegion_3->begin(), neighborsRegion_3->begin()+facesInRegion_len);
    
    /*
     * Find a list of the neighboring faces
     * facesAllNeighbors = setdiff(edgeList(:,2), facesInRegion);
     */

    
    vector<int> * facesInRegion_vect = new vector<int>(facesInRegion, facesInRegion + facesInRegion_len);
    vector<int> * edgeList_2_sorted = new vector<int>(*edgeList_2);
    
    // Need to sort input vectors and delete duplicates for this to work:
        
    sort(edgeList_2_sorted->begin(), edgeList_2_sorted->begin()+3*facesInRegion_len);
    edgeList_2_sorted->erase( 
            unique( edgeList_2_sorted->begin(), edgeList_2_sorted->begin()+3*facesInRegion_len ), edgeList_2_sorted->begin()+3*facesInRegion_len
            );
     
    sort(facesInRegion_vect->begin(), facesInRegion_vect->begin()+facesInRegion_len);
    facesInRegion_vect->erase( 
            unique( facesInRegion_vect->begin(), facesInRegion_vect->begin()+facesInRegion_len), facesInRegion_vect->begin()+facesInRegion_len 
            );
    
    facesAllNeighbors->clear();
    // These "end's" are okay
    set_difference(edgeList_2_sorted->begin(), edgeList_2_sorted->end(),
                    facesInRegion_vect->begin(), facesInRegion_vect->end(),
                    std::inserter(*facesAllNeighbors, facesAllNeighbors->begin()));
    /*
     * boundaryEdgesMask = ismembc(edgeList(:,2),facesAllNeighbors);
     */
        
    int * in1 = edgeList_2->data();
    int * in2 = facesAllNeighbors->data();
    
    size_t N = 3*facesInRegion_len;
            
    for(int i = 0; i < N; ++i){
        boundaryEdgesMask[i] = find(facesAllNeighbors->begin(), facesAllNeighbors->end(), edgeList_2->at(i)) != facesAllNeighbors->end();
    }
    
    /*
     * Find the edges that connect the regions to its neighors
     * boundaryEdgeList = [edgeList(boundaryEdgesMask>0,1), edgeList(boundaryEdgesMask>0,2)];
     */
    
    size_t BEM_greaterthan_zero_length = 0;
    
    for(int i = 0; i < N; ++i)
        if(boundaryEdgesMask[i]) 
            ++BEM_greaterthan_zero_length;
        
    k = 0;
    for(int i = 0; i < 3*facesInRegion_len; ++i){
        if(boundaryEdgesMask[i]){
            boundaryEdgeList_1->at(k) = edgeList_1->at(i);
            boundaryEdgeList_2->at(k) = edgeList_2->at(i);
            ++k;
        }
    }
          
    /*
     * vertexPairs = zeros(size(boundaryEdgeList,1),2);
     */
            
    /*
    % find the vertices that correspond to each boundary edge
    for b = 1:size(boundaryEdgeList,1)
        vertexPairs(b,:) = intersect(smoothedSurface.faces(boundaryEdgeList(b,1),:), smoothedSurface.faces(boundaryEdgeList(b,2),:), 'stable'); 

        % maintain the order of the vertices in the pair so that the vertex directionality convention for normality will be preserved during closure
        if vertexPairs(b,1) == smoothedSurface.faces(boundaryEdgeList(b,1),1) && vertexPairs(b,2) == smoothedSurface.faces(boundaryEdgeList(b,1),3)
            vertexPairs(b,:) = fliplr(vertexPairs(b,:));
        end
    end
    */
    
    double * faces_ptr = mxGetPr(mx_faces);
    size_t faces_M = mxGetM(mx_faces);
    
    for (int i = 0; i < 3 * faces_M; ++i) {
        faces_ptr_int[i] = (int)faces_ptr[i];
    }
    
    //vector<int> * faces_1 = new vector<int>(faces_ptr_int, faces_ptr_int + faces_M);
    int * faces_1 = faces_ptr_int;
    int * faces_2 = faces_ptr_int + faces_M;
    int * faces_3 = faces_ptr_int + 2*faces_M;
                    
    for(int b = 0; b < BEM_greaterthan_zero_length; ++b){                
        unordered_set<int> f1, f2, vertexPairs_set;
        f1.insert(faces_1[boundaryEdgeList_1->at(b)-1]);
        f2.insert(faces_1[boundaryEdgeList_2->at(b)-1]);
        f1.insert(faces_2[boundaryEdgeList_1->at(b)-1]);
        f2.insert(faces_2[boundaryEdgeList_2->at(b)-1]);
        f1.insert(faces_3[boundaryEdgeList_1->at(b)-1]);
        f2.insert(faces_3[boundaryEdgeList_2->at(b)-1]);
        
        copy_if(f1.begin(), f1.end(), inserter(vertexPairs_set, vertexPairs_set.begin()), [f2](const int element){return f2.count(element) > 0;} );
        
        vertexPairs_1[b] = *(vertexPairs_set.begin());
        vertexPairs_2[b] = *next(vertexPairs_set.begin(), 1);
        
        if(vertexPairs_2[b] < vertexPairs_1[b]){
            int tmp = vertexPairs_1[b];
            vertexPairs_1[b] = vertexPairs_2[b];
            vertexPairs_2[b] = tmp;
        }
        
        if ((vertexPairs_1[b] == faces_1[boundaryEdgeList_1->at(b)-1] && 
                vertexPairs_2[b] == faces_3[boundaryEdgeList_1->at(b)-1])){
            int tmp = vertexPairs_1[b];
            vertexPairs_1[b] = vertexPairs_2[b];
            vertexPairs_2[b] = tmp;
        }
    }
        
    /*
     * Find the center of mass of the vertices
     * nVertices = vertexPairs(:,1);
     * closeCenter = mean([smoothedSurface.vertices(nVertices,1), smoothedSurface.vertices(nVertices,2), smoothedSurface.vertices(nVertices,3)], 1);
     *
     * find the average distance from each edge vertex to the closeCenter
     * closeRadius = mean(sqrt(sum((smoothedSurface.vertices(nVertices,:) - repmat(closeCenter, size(smoothedSurface.vertices(nVertices,:),1), 1)).^2, 2)));
     *
     */

    double * vertices_ptr = mxGetPr(mx_vertices);
    size_t vertices_M = mxGetM(mx_vertices);
    
    double * vertices_1 = vertices_ptr;
    double * vertices_2 = vertices_ptr + vertices_M;
    double * vertices_3 = vertices_ptr + 2*vertices_M;
    
    double closeCenter_1 = 0, closeCenter_2 = 0, closeCenter_3 = 0;
    
    for(int b = 0; b < BEM_greaterthan_zero_length; ++b){
        centered_v1->at(b) = (double) vertices_1[vertexPairs_1[b]-1];
        centered_v2->at(b) = (double) vertices_2[vertexPairs_1[b]-1];
        centered_v3->at(b) = (double) vertices_3[vertexPairs_1[b]-1];
        
        closeCenter_1 += (double) vertices_1[vertexPairs_1[b]-1];
        closeCenter_2 += (double) vertices_2[vertexPairs_1[b]-1];
        closeCenter_3 += (double) vertices_3[vertexPairs_1[b]-1];
    }
        
    closeCenter_1 /= (double) BEM_greaterthan_zero_length;
    closeCenter_2 /= (double) BEM_greaterthan_zero_length;
    closeCenter_3 /= (double) BEM_greaterthan_zero_length;
    for (int i = 0; i < BEM_greaterthan_zero_length; ++i) {
        centered_v1->at(i) = pow(centered_v1->at(i) - closeCenter_1, 2);
        centered_v2->at(i) = pow(centered_v2->at(i) - closeCenter_2, 2);
        centered_v3->at(i) = pow(centered_v3->at(i) - closeCenter_3, 2);
    }
    
    // Subtract means:
    //for(auto & element : *centered_v1) element -= closeCenter_1;
    //for(auto & element : *centered_v2) element -= closeCenter_2;
    //for(auto & element : *centered_v3) element -= closeCenter_3;    
    
    // Square each element:
    //for(auto & element : *centered_v1) element *= element;
    //for(auto & element : *centered_v2) element *= element;
    //for(auto & element : *centered_v3) element *= element;
    
    for (int i = 0; i < BEM_greaterthan_zero_length; ++i) {
        centered_sum->at(i) = sqrt(centered_v1->at(i) + centered_v2->at(i) + centered_v3->at(i));
    }
        
    //for(auto & element : *centered_sum) element = sqrt(element);
    
    // Finally, get the mean:
    double closeRadius_ = accumulate(centered_sum->begin(), centered_sum->begin()+BEM_greaterthan_zero_length, 0) / (double) BEM_greaterthan_zero_length;
    
    /*
     * Make a fv (faces-vertices) structure for the region  (note that the vertices are not relabeled and so the structure is large)
     * closedMesh.faces = [smoothedSurface.faces(facesInRegion,1), smoothedSurface.faces(facesInRegion,2), smoothedSurface.faces(facesInRegion,3)];
     */
    
    for(int i = 0; i < facesInRegion_len; ++i){
        cm_faces_1->at(i) = faces_1[facesInRegion[i]-1];
        cm_faces_2->at(i) = faces_2[facesInRegion[i]-1];
        cm_faces_3->at(i) = faces_3[facesInRegion[i]-1];
    }
    
    /*
     *  closedMesh.vertices = smoothedSurface.vertices;
     *
     *  find a unique label for the new vertex:
     *  closeCenterLabel = size(closedMesh.vertices,1)+1;
     *
     *  append the new vertex to the list of vertices
     *  closedMesh.vertices(closeCenterLabel,:) = closeCenter;
     *
     */
    
    //HEREEEE
            

    /*
     *  swap the order of the vertices in the pairs to maintain the directionality of the surface normal
     *  vertexPairs = fliplr(vertexPairs);
     */

    int * tmp = vertexPairs_1;
    vertexPairs_1 = vertexPairs_2;
    vertexPairs_2 = tmp;    
    
    /*
     * append the new faces to the list of faces 
     * newFaces = [vertexPairs, closeCenterLabel.*ones(size(vertexPairs,1),1)];         // Add a third column of all value closeCenterLabel
     * closedMesh.faces = [closedMesh.faces; newFaces];     // Add the new faces to the bottom of this matrix:
     * closureMesh.faces = newFaces;
     *
     * closureMesh.vertices = closedMesh.vertices;
     * [closeCenter, closureSurfaceArea, closedMesh, closeRadius]
     */

    size_t fsize = facesInRegion_len + BEM_greaterthan_zero_length;
                
    mxArray * closeCenter           = mxCreateDoubleMatrix(1, 3, mxREAL);
    mxArray * closureSurfaceArea    = mxCreateDoubleMatrix(1, 1, mxREAL);
    mxArray * cmFaces               = mxCreateDoubleMatrix(fsize, 3, mxREAL);
    mxArray * cmVertices            = mxCreateDoubleMatrix(vertices_M + 1, 3, mxREAL);
    mxArray * closeRadius           = mxCreateDoubleMatrix(1, 1, mxREAL);    
    
    double * cmVertices_pr = mxGetPr(cmVertices);
    memcpy(cmVertices_pr                   , vertices_1, vertices_M*sizeof(double));
    memcpy(cmVertices_pr + 1 + vertices_M  , vertices_2, vertices_M*sizeof(double));
    memcpy(cmVertices_pr + 2 + 2*vertices_M, vertices_3, vertices_M*sizeof(double));    

    cmVertices_pr[vertices_M] = closeCenter_1;
    cmVertices_pr[2*vertices_M + 1] = closeCenter_2;
    cmVertices_pr[3*vertices_M + 2] = closeCenter_3;

    double * closeCenter_pr = mxGetPr(closeCenter);
        
    closeCenter_pr[0] = closeCenter_1;
    closeCenter_pr[1] = closeCenter_2;
    closeCenter_pr[2] = closeCenter_3;
    
    double * cmFaces_pr = mxGetPr(cmFaces);
    
    for(int i = 0; i < facesInRegion_len; ++i){
        cmFaces_pr[i] = (double)cm_faces_1->at(i);
        cmFaces_pr[i + fsize] = (double)cm_faces_2->at(i);
        cmFaces_pr[i + 2*fsize] = (double)cm_faces_3->at(i);
    }
    
    for(int i = facesInRegion_len; i < fsize; ++i){
        cmFaces_pr[i] = vertexPairs_1[i - facesInRegion_len];
        cmFaces_pr[i + fsize] = vertexPairs_2[i - facesInRegion_len];
        cmFaces_pr[i + 2*fsize] = (double)vertices_M + 1;
        
        //cout << vertexPairs_1[i - facesInRegion_len] << endl;
    }
    
    /*
     * closureSurfaceArea = sum(measureAllFaceAreas(closureMesh));     
     */
    
    *(mxGetPr(closeRadius)) = closeRadius_;
    
    /*
    unordered_set<double> x, y, z;
    x.insert(1126);
    x.insert(1151);
    x.insert(1127);
    y.insert(1127);
    y.insert(1151);
    y.insert(1152);
    
    copy_if(x.begin(), x.end(), inserter(z, z.begin()), [y](const int element){return y.count(element) > 0;} );
    
    for(auto & v : z) cout << v << endl;
    */
    
    plhs[0] = closeCenter;
    plhs[1] = closureSurfaceArea;
    plhs[2] = cmFaces;
    plhs[3] = cmVertices;
    plhs[4] = closeRadius;
    
    /*
    delete faceIndex;    
    delete neighbors_1;
    delete neighbors_2;
    delete neighbors_3;
    delete edgeList_2;
    delete facesInRegion_vect;
    delete facesAllNeighbors;
    delete edgeList_2_sorted;
    delete boundaryEdgeList_1;
    delete boundaryEdgeList_2;
    delete faces_1;
    delete faces_2;
    delete faces_3;
    delete vertices_1;
    delete vertices_2;
    delete vertices_3;
    delete centered_v1; 
    delete centered_v2;
    delete centered_v3;
    delete centered_sum;
    delete cm_faces_1;
    delete cm_faces_2;
    delete cm_faces_3;
    delete cm_vertices_1;
    delete cm_vertices_2;
    delete cm_vertices_3;
    
    free(facesInRegion);
    free(boundaryEdgesMask);
    free(vertexPairs_1);
    free(vertexPairs_2);
    free(neighbors_ptr_int);
    free(watersheds_equals_wLabel);
    */
                
    return;
}