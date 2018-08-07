; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    void d1_c_slt_0(int *A) {
;      for (int i = 0; i < 1000; i += 2)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_slt_0
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond]
; CHECK: { [i0] -> [(2i0)] } [indvars.iv]
; CHECK: { [] -> [(1)] } [for.cond.cleanup]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 499 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 499 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_slt_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 2
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_slt_1(int *A) {
;      for (int i = 500; i < 1000; i += 3)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_slt_1
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 167 } [for.cond]
; CHECK: { [i0] -> [(500 + 3i0)] } [indvars.iv]
; CHECK: { [] -> [(1)] } [for.cond.cleanup]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 166 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 166 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_slt_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 500, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 3
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_slt_2(int *A) {
;      for (int i = -500; i < 1000; i += 4)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_slt_2
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 375 } [for.cond]
; CHECK: { [i0] -> [(-500 + 4i0)] } [indvars.iv]
; CHECK: { [] -> [(1)] } [for.cond.cleanup]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 374 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 374 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_slt_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ -500, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, 4
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_slt_3(int *A) {
;      for (int i = 1000; i < 1000; i += 5)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_slt_3
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 + 5i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_slt_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp slt i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 5
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_0(int *A) {
;      for (int i = 0; i != 1000; i += 6)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_0
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(6i0)] } [indvars.iv]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_sne_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp ne i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 6
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_1(int *A) {
;      for (int i = 500; i != 1000; i += 7)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_1
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(500 + 7i0)] } [indvars.iv]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_sne_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 500, %entry ]
  %cmp = icmp ne i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 7
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_2(int *A) {
;      for (int i = -500; i != 1000; i += 8)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_2
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(-500 + 8i0)] } [indvars.iv]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_sne_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ -500, %entry ]
  %cmp = icmp ne i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, 8
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_3(int *A) {
;      for (int i = 1000; i != 1000; i += 9)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_3
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 + 9i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_sne_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 9
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_0_r(int *A) {
;      for (int i = 0; i < 1000; i += 10)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sgt_0_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 100 } [for.cond]
; CHECK: { [i0] -> [(10i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 99 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 99 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_sgt_0_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 10
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_1_r(int *A) {
;      for (int i = 1000; i > 500; i -= 2)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sgt_1_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 250 } [for.cond]
; CHECK: { [i0] -> [(1000 - 2i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 249 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 249 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_sgt_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i64 %indvars.iv, 500
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -2
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_2_r(int *A) {
;      for (int i = 1000; i > -500; i -= 3)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sgt_2_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond]
; CHECK: { [i0] -> [(1000 - 3i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 499 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 499 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_sgt_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp sgt i64 %indvars.iv, -500
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -3
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_3_r(int *A) {
;      for (int i = 1000; i > 1000; i -= 4)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sgt_3_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 - 4i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_sgt_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp sgt i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -4
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_0_r(int *A) {
;      for (int i = 1000; i != 0; i -= 5)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_0_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 200 } [for.cond]
; CHECK: { [i0] -> [(1000 - 5i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 199 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 199 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_sne_0_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 0
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -5
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_1_r(int *A) {
;      for (int i = 1000; i != 500; i -= 6)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_1_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(1000 - 6i0)] } [indvars.iv]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_sne_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ne i64 %indvars.iv, 500
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -6
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_2_r(int *A) {
;      for (int i = 1000; i != -500; i -= 7)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_2_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(1000 - 7i0)] } [indvars.iv]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_sne_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ne i64 %indvars.iv, -500
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -7
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_3_r(int *A) {
;      for (int i = 1000; i != 1000; i -= 8)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_sne_3_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 - 8i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_sne_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -8
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_0(unsigned *A) {
;      for (unsigned i = 0; i < 1000; i += 2)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ult_0
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond]
; CHECK: { [i0] -> [(2i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 499 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 499 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_ult_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 2
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_1(unsigned *A) {
;      for (unsigned i = 500; i < 1000; i += 3)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ult_1
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 167 } [for.cond]
; CHECK: { [i0] -> [(500 + 3i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 166 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 166 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_ult_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 500, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 3
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_2(unsigned *A) {
;      for (unsigned i = -500; i < 1000; i += 4)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ult_2
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(4294966796 + 4i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_ult_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 4294966796, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 4
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_3(unsigned *A) {
;      for (unsigned i = 1000; i < 1000; i += 5)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ult_3
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 + 5i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_ult_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 5
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_0(unsigned *A) {
;      for (unsigned i = 0; i != 1000; i += 6)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_0
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(6i0)] } [i.0]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_une_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %add, %for.inc ]
  %cmp = icmp eq i32 %i.0, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = zext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %idxprom
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %add = add i32 %i.0, 6
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_1(unsigned *A) {
;      for (unsigned i = 500; i != 1000; i += 7)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_1
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(500 + 7i0)] } [i.0]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_une_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 500, %entry ], [ %add, %for.inc ]
  %cmp = icmp eq i32 %i.0, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = zext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %idxprom
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %add = add i32 %i.0, 7
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_2(unsigned *A) {
;      for (unsigned i = -500; i != 1000; i += 8)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_2
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(-500 + 8i0)] } [i.0]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_une_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ -500, %entry ], [ %add, %for.inc ]
  %cmp = icmp eq i32 %i.0, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = zext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %idxprom
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %add = add i32 %i.0, 8
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_3(unsigned *A) {
;      for (unsigned i = 1000; i != 1000; i += 9)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_3
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 + 9i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_une_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 9
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_0(unsigned *A) {
;      for (unsigned i = 0; i < 1000; i += 10)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ugt_0
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 100 } [for.cond]
; CHECK: { [i0] -> [(10i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 99 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 99 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_ugt_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 10
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_1_r(unsigned *A) {
;      for (unsigned i = 1000; i > 500; i -= 2)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ugt_1_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 250 } [for.cond]
; CHECK: { [i0] -> [(1000 - 2i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 249 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 249 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_ugt_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i64 %indvars.iv, 500
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -2
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_2_r(unsigned *A) {
;      for (unsigned i = 1000; i > -500; i -= 3)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ugt_2_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(1000 + 4294967293i0)] } [indvars.iv]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_ugt_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i64 %indvars.iv, -500
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 4294967293
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_3_r(unsigned *A) {
;      for (unsigned i = 1000; i > 1000; i -= 4)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_ugt_3_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 + 4294967292i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_ugt_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 4294967292
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_0_r(unsigned *A) {
;      for (unsigned i = 1000; i != 0; i -= 5)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_0_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 200 } [for.cond]
; CHECK: { [i0] -> [(1000 - 5i0)] } [indvars.iv]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 199 } [for.body]
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 199 } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_une_0_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 0
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -5
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_1_r(unsigned *A) {
;      for (unsigned i = 1000; i != 500; i -= 6)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_1_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(1000 - 6i0)] } [i.0]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_une_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 1000, %entry ], [ %sub, %for.inc ]
  %cmp = icmp eq i32 %i.0, 500
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = zext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %idxprom
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %sub = add i32 %i.0, -6
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_2_r(unsigned *A) {
;      for (unsigned i = 1000; i != -500; i -= 7)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_2_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: null [for.cond]
; CHECK: { [i0] -> [(1000 - 7i0)] } [i.0]
; CHECK: null [for.cond.cleanup]
; CHECK: null [for.body]
; CHECK: null [for.inc]
; CHECK: null [for.end]
define void @d1_c_une_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 1000, %entry ], [ %sub, %for.inc ]
  %cmp = icmp eq i32 %i.0, -500
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = zext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %idxprom
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %sub = add i32 %i.0, -7
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_3_r(unsigned *A) {
;      for (unsigned i = 1000; i != 1000; i -= 8)
;        A[i]++;
;   }
;
; CHECK-LABEL: d1_c_une_3_r
; CHECK: { [] -> [(1)] } [entry]
; CHECK: { [i0] -> [(1)] : i0 = 0 } [for.cond]
; CHECK: { [i0] -> [(1000 + 4294967288i0)] } [indvars.iv]
; CHECK: {  } [for.body]
; CHECK: {  } [for.inc]
; CHECK: { [] -> [(1)] } [for.end]
define void @d1_c_une_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 4294967288
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}
