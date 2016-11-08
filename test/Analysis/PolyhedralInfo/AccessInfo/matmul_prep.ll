; RUN: opt -polyhedral-access-function-info -analyze < %s | FileCheck %s
;
; void matMul(int rowsA, int colsA, int colsB, float *matrixA, float *matrixB,
;             float *matrixC) {
;
;   for (int row = 0; row < rowsA; ++row) {
;     for (int col = 0; col < colsB; ++col) {
;
;       double tmp = 0;
;       for (int i = 0; i < colsA; i++)
;         tmp += matrixA[row * colsA + i] * matrixB[i * colsB + col];
;
;       matrixC[row * colsB + col] = tmp;
;     }
;   }
; }
;
; CHECK:     PACC summary
; CHECK:       Unknown reads: None
; CHECK:       Unknown writes: None
; CHECK:     Array infos:
; CHECK-DAG:   Base pointer: float* %matrixC
; CHECK-DAG:     MustWrite: [rowsA, colsB] -> { [i0, i1] -> matrixC[i0, i1] : 0 <= i0 < rowsA and 0 <= i1 < colsB }
; CHECK-DAG:   Base pointer: float* %matrixB
; CHECK-DAG:      MustRead: [rowsA, colsB, colsA] -> { [i0, i1, i2] -> matrixB[i2, i1] : 0 <= i0 < rowsA and 0 <= i1 < colsB and 0 <= i2 < colsA }
; CHECK-DAG:   Base pointer: float* %matrixA
; CHECK-DAG:      MustRead: [rowsA, colsB, colsA] -> { [i0, i1, i2] -> matrixA[i0, i2] : 0 <= i0 < rowsA and 0 <= i1 < colsB and 0 <= i2 < colsA }

target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"

; Function Attrs: noinline nounwind ssp uwtable
define void @matMul(i32 %rowsA, i32 %colsA, i32 %colsB, float* %matrixA, float* %matrixB, float* %matrixC) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc22, %entry
  %row.0 = phi i32 [ 0, %entry ], [ %inc23, %for.inc22 ]
  %cmp = icmp slt i32 %row.0, %rowsA
  br i1 %cmp, label %for.body, label %for.end24

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc19, %for.body
  %col.0 = phi i32 [ 0, %for.body ], [ %inc20, %for.inc19 ]
  %cmp2 = icmp slt i32 %col.0, %colsB
  br i1 %cmp2, label %for.body3, label %for.end21

for.body3:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body3
  %tmp.0 = phi double [ 0.000000e+00, %for.body3 ], [ %add13, %for.inc ]
  %i.0 = phi i32 [ 0, %for.body3 ], [ %inc, %for.inc ]
  %cmp6 = icmp slt i32 %i.0, %colsA
  br i1 %cmp6, label %for.body7, label %for.end

for.body7:                                        ; preds = %for.cond5
  %mul = mul nsw i32 %row.0, %colsA
  %add = add nsw i32 %mul, %i.0
  %idxprom = sext i32 %add to i64
  %arrayidx = getelementptr inbounds float, float* %matrixA, i64 %idxprom
  %0 = load float, float* %arrayidx, align 4
  %mul8 = mul nsw i32 %i.0, %colsB
  %add9 = add nsw i32 %mul8, %col.0
  %idxprom10 = sext i32 %add9 to i64
  %arrayidx11 = getelementptr inbounds float, float* %matrixB, i64 %idxprom10
  %1 = load float, float* %arrayidx11, align 4
  %mul12 = fmul float %0, %1
  %conv = fpext float %mul12 to double
  %add13 = fadd double %tmp.0, %conv
  br label %for.inc

for.inc:                                          ; preds = %for.body7
  %inc = add nsw i32 %i.0, 1
  br label %for.cond5

for.end:                                          ; preds = %for.cond5
  %conv14 = fptrunc double %tmp.0 to float
  %mul15 = mul nsw i32 %row.0, %colsB
  %add16 = add nsw i32 %mul15, %col.0
  %idxprom17 = sext i32 %add16 to i64
  %arrayidx18 = getelementptr inbounds float, float* %matrixC, i64 %idxprom17
  store float %conv14, float* %arrayidx18, align 4
  br label %for.inc19

for.inc19:                                        ; preds = %for.end
  %inc20 = add nsw i32 %col.0, 1
  br label %for.cond1

for.end21:                                        ; preds = %for.cond1
  br label %for.inc22

for.inc22:                                        ; preds = %for.end21
  %inc23 = add nsw i32 %row.0, 1
  br label %for.cond

for.end24:                                        ; preds = %for.cond
  ret void
}
