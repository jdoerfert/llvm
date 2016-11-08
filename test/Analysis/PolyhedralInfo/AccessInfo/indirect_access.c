int indirect(int *A, int i) {
  return A[A[i]];
}

void kernel(int lIdx, int* A, int* B, int ThreadIdx, int BlockIdx, int BlockDim) {
  int gIdx = ThreadIdx + BlockIdx * BlockDim;
  B[gIdx] = A[A[gIdx + lIdx]];
}

