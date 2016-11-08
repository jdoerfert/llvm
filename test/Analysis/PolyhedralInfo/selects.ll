; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    int *select_affine0(int *A, int *B) {
;      return A ? A : B;
;    }
define i32* @select_affine0(i32* %A, i32* %B) {
entry:
  %tobool = icmp eq i32* %A, null
  %retval = select i1 %tobool, i32* %A, i32* %B
; CHECK:  [A, B] -> { [] -> [(0)] : A = 0; [] -> [(B)] : A < 0 or A > 0 } [retval]
  ret i32* %retval
}

;    int select_affine1(int a, int b) {
;      if (a > b)
;        return a;
;      return b;
;    }
define i32 @select_affine1(i32 %a, i32 %b) {
entry:
  %cmp = icmp sgt i32 %a, %b
  %retval = select i1 %cmp, i32 %a, i32 %b
; CHECK:  [b, a] -> { [] -> [(a)] : a > b; [] -> [(b)] : a <= b } [retval]
  ret i32 %retval
}

;    float select_affine2(float a, float b) {
;      if (a > b)
;        return a;
;      return b;
;    }
define float @select_affine2(float %a, float %b) {
entry:
  %cmp = fcmp ogt float %a, %b
  %retval = select i1 %cmp, float %a, float %b
; CHECK: [cmp, b, a] -> { [] -> [(a)] : cmp < 0 or cmp > 0; [] -> [(b)] : cmp = 0 } [retval]
  ret float %retval
}

;    int select_non_affine0(int *A, int *B) {
;      int x = 0;
;      for (int i = 0; i < 100; i++)
;        x += i * i > A[i] ? A[i] : B[i];
;      return x;
;    }
define i32 @select_non_affine0(i32* %A, i32* %B) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.body, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %entry ]
  %x.0 = phi i32 [ 0, %entry ], [ %add, %for.body ]
  %exitcond = icmp ne i64 %indvars.iv, 100
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %tmp = mul nsw i64 %indvars.iv, %indvars.iv
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx, align 4
  %tmp3 = sext i32 %tmp2 to i64
  %cmp1 = icmp sgt i64 %tmp, %tmp3
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %arrayidx5 = getelementptr inbounds i32, i32* %B, i64 %indvars.iv
  %cond.in = select i1 %cmp1, i32* %arrayidx3, i32* %arrayidx5
; CHECK:  [tmp2, tmp, B, A] -> { [i0] -> [(A + 4i0)] : tmp > tmp2; [i0] -> [(B + 4i0)] : tmp <= tmp2 } [cond.in]
  %cond = load i32, i32* %cond.in, align 4
  %add = add nsw i32 %x.0, %cond
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret i32 %x.0
}

;    int select_non_affine1(int *A) {
;      int x = 0;
;      for (int i = 0; i < 100; i++)
;        if (A[i] < i * i)
;          x += A[i];
;        else
;          x += i * i;
;      return x;
;    }
define i32 @select_non_affine1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.body, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %entry ]
  %x.0 = phi i32 [ 0, %entry ], [ %x.1, %for.body ]
  %exitcond = icmp ne i64 %indvars.iv, 100
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %tmp3 = mul nsw i64 %indvars.iv, %indvars.iv
  %tmp4 = sext i32 %tmp to i64
  %cmp1 = icmp slt i64 %tmp4, %tmp3
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp5 = load i32, i32* %arrayidx3, align 4
  %tmp6 = mul nsw i64 %indvars.iv, %indvars.iv
  %tmp7 = trunc i64 %tmp6 to i32
  %pn = select i1 %cmp1, i32 %tmp5, i32 %tmp7
; CHECK:  [tmp, tmp3, tmp6, tmp5] -> { [i0] -> [(tmp5)] : tmp3 > tmp; [i0] -> [(tmp6)] : tmp3 <= tmp } [pn]
  %x.1 = add nsw i32 %x.0, %pn
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret i32 %x.0
}
