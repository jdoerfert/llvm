; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    void d1_c_slt_0(int *A) {
;      for (int i = 0; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_slt_0(i32* %A) {
entry:
  br label %for.cond
; CHECK:  { [] -> [(1)] } [entry] [DOMAIN] [Scope: <max>]

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end
; CHECK: { [] -> [(1)] } [for.cond.cleanup] [DOMAIN] [Scope: <max>]

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.body] [DOMAIN] [Scope: <max>]

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond
; CHECK: { [i0] -> [(1)] : 0 <= i0 <= 999 } [for.inc] [DOMAIN] [Scope: <max>]

for.end:                                          ; preds = %for.cond.cleanup
  ret void
; CHECK: { [] -> [(1)] } [for.end] [DOMAIN] [Scope: <max>]
}


;    void d1_c_slt_1(int *A) {
;      for (int i = 500; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_slt_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 500, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(500 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_slt_2(int *A) {
;      for (int i = -500; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_slt_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ -500, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(-500 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_slt_3(int *A) {
;      for (int i = 1000; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_slt_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  br i1 false, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc
; CHECK:  {  } [for.body] [DOMAIN] [Scope: <max>]

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_0(int *A) {
;      for (int i = 0; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_sne_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_1(int *A) {
;      for (int i = 500; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_sne_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 500, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(500 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_2(int *A) {
;      for (int i = -500; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_sne_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ -500, %entry ]
  %exitcond = icmp eq i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(-500 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_3(int *A) {
;      for (int i = 1000; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_sne_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_0_r(int *A) {
;      for (int i = 0; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_sgt_0_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp slt i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_1_r(int *A) {
;      for (int i = 1000; i > 500; i--)
;        A[i]++;
;    }
define void @d1_c_sgt_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i64 %indvars.iv, 500
  br i1 %cmp, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_2_r(int *A) {
;      for (int i = 1000; i > -500; i--)
;        A[i]++;
;    }
define void @d1_c_sgt_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp sgt i64 %indvars.iv, -500
  br i1 %cmp, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sgt_3_r(int *A) {
;      for (int i = 1000; i > 1000; i--)
;        A[i]++;
;    }
define void @d1_c_sgt_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  br i1 false, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_0_r(int *A) {
;      for (int i = 1000; i != 0; i--)
;        A[i]++;
;    }
define void @d1_c_sne_0_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 0
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_1_r(int *A) {
;      for (int i = 1000; i != 500; i--)
;        A[i]++;
;    }
define void @d1_c_sne_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 500
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_2_r(int *A) {
;      for (int i = 1000; i != -500; i--)
;        A[i]++;
;    }
define void @d1_c_sne_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %tmp = trunc i64 %indvars.iv to i32
  %cmp = icmp eq i32 %tmp, -500
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_sne_3_r(int *A) {
;      for (int i = 1000; i != 1000; i--)
;        A[i]++;
;    }
define void @d1_c_sne_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_0(unsigned *A) {
;      for (unsigned i = 0; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_ult_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ult i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_1(unsigned *A) {
;      for (unsigned i = 500; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_ult_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 500, %entry ]
  %exitcond = icmp ult i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(500 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_2(unsigned *A) {
;      for (unsigned i = -500; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_ult_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 4294966796, %entry ]
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(4294966796 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]
  br i1 false, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ult_3(unsigned *A) {
;      for (unsigned i = 1000; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_ult_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  br i1 false, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_0(unsigned *A) {
;      for (unsigned i = 0; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_une_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_1(unsigned *A) {
;      for (unsigned i = 500; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_une_1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 500, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(500 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_2(unsigned *A) {
;      for (unsigned i = -500; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_une_2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ -500, %entry ], [ %inc1, %for.inc ]
  %cmp = icmp eq i32 %i.0, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(-500 + i0)] } [i.0] [UNKNOWN] [Scope: <max>]

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
  %inc1 = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_3(unsigned *A) {
;      for (unsigned i = 1000; i != 1000; i++)
;        A[i]++;
;    }
define void @d1_c_une_3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 + i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_0(unsigned *A) {
;      for (unsigned i = 0; i < 1000; i++)
;        A[i]++;
;    }
define void @d1_c_ugt_0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ult i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_1_r(unsigned *A) {
;      for (unsigned i = 1000; i > 500; i--)
;        A[i]++;
;    }
define void @d1_c_ugt_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i64 %indvars.iv, 500
  br i1 %cmp, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_2_r(unsigned *A) {
;      for (unsigned i = 1000; i > -500; i--)
;        A[i]++;
;    }
define void @d1_c_ugt_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i32 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i32 %indvars.iv, -500
  br i1 %cmp, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i32 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add i32 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_ugt_3_r(unsigned *A) {
;      for (unsigned i = 1000; i > 1000; i--)
;        A[i]++;
;    }
define void @d1_c_ugt_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp ugt i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 + 4294967295i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 4294967295
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_0_r(unsigned *A) {
;      for (unsigned i = 1000; i != 0; i--)
;        A[i]++;
;    }
define void @d1_c_une_0_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 0
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1000 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_1_r(unsigned *A) {
;      for (unsigned i = 1000; i != 500; i--)
;        A[i]++;
;    }
define void @d1_c_une_1_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 500
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_2_r(unsigned *A) {
;      for (unsigned i = 1000; i != -500; i--)
;        A[i]++;
;    }
define void @d1_c_une_2_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 1000, %entry ], [ %dec, %for.inc ]
  %cmp = icmp eq i32 %i.0, -500
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : 0 <= i0 <= 1500 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [i.0] [UNKNOWN] [Scope: <max>]

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
  %dec = add nsw i32 %i.0, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

;    void d1_c_une_3_r(unsigned *A) {
;      for (unsigned i = 1000; i != 1000; i--)
;        A[i]++;
;    }
define void @d1_c_une_3_r(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 1000, %entry ]
  %cmp = icmp eq i64 %indvars.iv, 1000
  br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK:  { [i0] -> [(1)] : i0 = 0 } [for.cond] [DOMAIN] [Scope: <max>]
; CHECK:  { [i0] -> [(1000 - i0)] } [indvars.iv] [UNKNOWN] [Scope: <max>]

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nsw i64 %indvars.iv, -1
  br label %for.cond

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}
