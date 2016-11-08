; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

; This file checks the back edge taken count computation of the polyhedral value
; info for two dimensional loops.

;    void c0(int *A) {
;      for (int i = 0; i < 1000; i++)
;        for (int j = 0; j < 500; j++)
;          A[i]++;
;    }
;
; CHECK: back edge taken count of for.cond
; CHECK-NEXT: { [] -> [(1000)] } [for.cond] [INTEGER] [Scope: <max>]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: [indvars_iv] -> { [] -> [(500)] : indvars_iv >= 1001 or indvars_iv <= 999 } [for.cond1] [INTEGER] [Scope: for.cond]
;  { [] -> [(500)] } [for.cond1] [INTEGER] [Scope: for.cond]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: { [i0] -> [(500)] : 0 <= i0 <= 999 } [for.cond1] [INTEGER] [Scope: <max>]
;
define void @c0(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc6, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc6 ], [ 0, %entry ]
  %exitcond1 = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond1, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end8

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc5, %for.inc ]
  %exitcond = icmp ne i32 %j.0, 500
  br i1 %exitcond, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end

for.body4:                                        ; preds = %for.cond1
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body4
  %inc5 = add nuw nsw i32 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond.cleanup3
  br label %for.inc6

for.inc6:                                         ; preds = %for.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end8:                                         ; preds = %for.cond.cleanup
  ret void
}

;    void c1(int *A) {
;      for (int i = 0; i < 1000; i++)
;        for (int j = i; j < 500; j++)
;          A[i]++;
;    }
;
; CHECK: back edge taken count of for.cond
; CHECK-NEXT: { [] -> [(1000)] } [for.cond] [INTEGER] [Scope: <max>]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: [indvars_iv] -> { [] -> [(0)] : indvars_iv >= 500 and (indvars_iv >= 1001 or indvars_iv <= 999); [] -> [(500 - indvars_iv)] : indvars_iv <= 499 } [for.cond1] [UNKNOWN] [Scope: for.cond]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: { [i0] -> [(0)] : 500 <= i0 <= 999; [i0] -> [(500 - i0)] : 0 <= i0 <= 499 } [for.cond1] [UNKNOWN] [Scope: <max>]
;
define void @c1(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc6, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc6 ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end8

for.body:                                         ; preds = %for.cond
  %tmp = trunc i64 %indvars.iv to i32
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i32 [ %tmp, %for.body ], [ %inc5, %for.inc ]
  %cmp2 = icmp ult i32 %j.0, 500
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end

for.body4:                                        ; preds = %for.cond1
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body4
  %inc5 = add nuw nsw i32 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond.cleanup3
  br label %for.inc6

for.inc6:                                         ; preds = %for.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end8:                                         ; preds = %for.cond.cleanup
  ret void
}

;    void c2(int *A) {
;      for (int i = 0; i < 1000; i++)
;        for (int j = -i; j < i; j++)
;          A[i]++;
;    }
;
; CHECK: back edge taken count of for.cond
; CHECK-NEXT: { [] -> [(1000)] } [for.cond] [INTEGER] [Scope: <max>]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: [indvars_iv1, indvars_iv] -> { [] -> [(0)] : indvars_iv <= -indvars_iv1 and (indvars_iv1 >= 1001 or indvars_iv1 <= 999); [] -> [(indvars_iv1 + indvars_iv)] : indvars_iv > -indvars_iv1 and (indvars_iv1 >= 1001 or indvars_iv1 <= 999) } [for.cond1] [UNKNOWN] [Scope: for.cond] 
; CHECK-SAME: [ID: [indvars_iv1, indvars_iv] -> { [i0] : indvars_iv1 >= 2147483649 or indvars_iv1 <= -2147483648 or (indvars_iv1 >= 1001 and indvars_iv < -indvars_iv1 and i0 > 0) or (indvars_iv1 <= 999 and indvars_iv < -indvars_iv1 and i0 > 0) }] 
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: { [i0] -> [(2i0)] : 0 <= i0 <= 999 } [for.cond1] [UNKNOWN] [Scope: <max>]
;
define void @c2(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc6, %entry
  %indvars.iv1 = phi i64 [ %indvars.iv.next2, %for.inc6 ], [ 0, %entry ]
  %indvars.iv = phi i32 [ %indvars.iv.next, %for.inc6 ], [ 0, %entry ]
  %exitcond4 = icmp ne i64 %indvars.iv1, 1000
  br i1 %exitcond4, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end8

for.body:                                         ; preds = %for.cond
  %tmp = sub nsw i64 0, %indvars.iv1
  %tmp5 = trunc i64 %tmp to i32
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i32 [ %tmp5, %for.body ], [ %inc5, %for.inc ]
  %exitcond = icmp ne i32 %j.0, %indvars.iv
  br i1 %exitcond, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end

for.body4:                                        ; preds = %for.cond1
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv1
  %tmp6 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp6, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body4
  %inc5 = add nsw i32 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond.cleanup3
  br label %for.inc6

for.inc6:                                         ; preds = %for.end
  %indvars.iv.next2 = add nuw nsw i64 %indvars.iv1, 1
  %indvars.iv.next = add nuw nsw i32 %indvars.iv, 1
  br label %for.cond

for.end8:                                         ; preds = %for.cond.cleanup
  ret void
}

;    void c3(int *A) {
;      for (int i = 11; i < 1000; i += 2)
;        for (int j = 13; j < i; j += 3)
;          A[i]++;
;    }
;
; CHECK: back edge taken count of for.cond
; CHECK-NEXT: { [] -> [(495)] } [for.cond] [INTEGER] [Scope: <max>]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: [indvars_iv] -> { [] -> [(0)] : indvars_iv <= 13; [] -> [(-4 + floor((1 + indvars_iv)/3))] : 14 <= indvars_iv <= 999 } [for.cond1] [UNKNOWN] [Scope: for.cond]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: { [i0] -> [(floor((2i0)/3))] : 0 <= i0 <= 494 } [for.cond1] [UNKNOWN] [Scope: <max>]
;
define void @c3(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc5, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc5 ], [ 11, %entry ]
  %cmp = icmp ult i64 %indvars.iv, 1000
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end7

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i32 [ 13, %for.body ], [ %add, %for.inc ]
  %tmp = zext i32 %j.0 to i64
  %cmp2 = icmp ult i64 %tmp, %indvars.iv
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end

for.body4:                                        ; preds = %for.cond1
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp1 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp1, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body4
  %add = add nuw nsw i32 %j.0, 3
  br label %for.cond1

for.end:                                          ; preds = %for.cond.cleanup3
  br label %for.inc5

for.inc5:                                         ; preds = %for.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 2
  br label %for.cond

for.end7:                                         ; preds = %for.cond.cleanup
  ret void
}

;    void c4(int *A) {
;      for (int i = 0; i < 1000; i++)
;        for (int j = -i; j < i * i; j++)
;          A[i]++;
;    }
;
; CHECK: back edge taken count of for.cond
; CHECK-NEXT: { [] -> [(1000)] } [for.cond] [INTEGER] [Scope: <max>]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: [indvars_iv, tmp4] -> { [] -> [(0)] : tmp4 <= -indvars_iv and (indvars_iv >= 1001 or indvars_iv <= 999); [] -> [(indvars_iv + tmp4)] : tmp4 > -indvars_iv and (indvars_iv >= 1001 or indvars_iv <= 999) } [for.cond1] [UNKNOWN] [Scope: for.cond]
; CHECK: back edge taken count of for.cond1
; CHECK-NEXT: null [for.cond1] [NON AFFINE] [Scope: <max>]
;
define void @c4(i32* %A) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc6, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc6 ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1000
  br i1 %exitcond, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end8

for.body:                                         ; preds = %for.cond
  %tmp = sub nsw i64 0, %indvars.iv
  %tmp3 = trunc i64 %tmp to i32
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i32 [ %tmp3, %for.body ], [ %inc5, %for.inc ]
  %tmp4 = mul nsw i64 %indvars.iv, %indvars.iv
  %tmp5 = sext i32 %j.0 to i64
  %cmp2 = icmp slt i64 %tmp5, %tmp4
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end

for.body4:                                        ; preds = %for.cond1
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp6 = load i32, i32* %arrayidx, align 4
  %inc = add nsw i32 %tmp6, 1
  store i32 %inc, i32* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body4
  %inc5 = add nsw i32 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond.cleanup3
  br label %for.inc6

for.inc6:                                         ; preds = %for.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end8:                                         ; preds = %for.cond.cleanup
  ret void
}
