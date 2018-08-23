; RUN: opt -polyhedral-access-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

%struct.f2 = type { float, float }
%struct.m3 = type { i8, i32, double }

;    int basic_sum(int *arr, int n) {
;      int akk = 0;
;      for (int i = 0; i < n; ++i) {
;        akk += arr[i];
;      }
;      return akk;
;    }
; CHECK-LABEL: basic_sum
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0] -> arr[o0] : 0 <= i0 < n and 4i0 <= o0 <= 3 + 4i0 } 
define i32 @basic_sum(i32* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp6 = icmp sgt i32 %n, 0
  br i1 %cmp6, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext i32 %n to i64
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %entry
  %akk.0.lcssa = phi i32 [ 0, %entry ], [ %add, %for.body ]
  ret i32 %akk.0.lcssa

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next, %for.body ]
  %akk.07 = phi i32 [ 0, %for.body.lr.ph ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %arr, i64 %indvars.iv
  %0 = load i32, i32* %arrayidx, align 4, !tbaa !2
  %add = add nsw i32 %0, %akk.07
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

;    int basic_sum_strided(int *arr, int n) {
;      int akk = 0;
;      for (int i = 0; i < n; i += 2) {
;        akk += arr[i];
;      }
;      return akk;
;    }
; CHECK-LABEL: basic_sum_strided
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0] -> arr[o0] : i0 >= 0 and 2i0 < n and 8i0 <= o0 <= 3 + 8i0 }
define i32 @basic_sum_strided(i32* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp7 = icmp sgt i32 %n, 0
  br i1 %cmp7, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %0 = sext i32 %n to i64
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %entry
  %akk.0.lcssa = phi i32 [ 0, %entry ], [ %add, %for.body ]
  ret i32 %akk.0.lcssa

for.body:                                         ; preds = %for.body.lr.ph, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next, %for.body ]
  %akk.08 = phi i32 [ 0, %for.body.lr.ph ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %arr, i64 %indvars.iv
  %1 = load i32, i32* %arrayidx, align 4, !tbaa !2
  %add = add nsw i32 %1, %akk.08
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 2
  %cmp = icmp slt i64 %indvars.iv.next, %0
  br i1 %cmp, label %for.body, label %for.cond.cleanup
}

;    int fix_sum(int *arr) {
;      int akk = 0;
;      for (int i = 0; i < 10; ++i) {
;        akk += arr[i];
;      }
;      return akk;
;    }
; CHECK-LABEL: fix_sum
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0] -> arr[o0] : 0 <= i0 <= 9 and 4i0 <= o0 <= 3 + 4i0 }
define i32 @fix_sum(i32* nocapture readonly %arr) local_unnamed_addr #0 {
entry:
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body
  ret i32 %add

for.body:                                         ; preds = %for.body, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %akk.06 = phi i32 [ 0, %entry ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %arr, i64 %indvars.iv
  %0 = load i32, i32* %arrayidx, align 4, !tbaa !2
  %add = add nsw i32 %0, %akk.06
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, 10
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

;    int fix_sum_strided(int *arr) {
;      int akk = 0;
;      for (int i = 0; i < 10; i += 2) {
;        akk += arr[i];
;      }
;      return akk;
;    }
; CHECK-LABEL: fix_sum_strided
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0] -> arr[o0] : 0 <= i0 <= 4 and 8i0 <= o0 <= 3 + 8i0 }
define i32 @fix_sum_strided(i32* nocapture readonly %arr) local_unnamed_addr #0 {
entry:
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body
  ret i32 %add

for.body:                                         ; preds = %entry, %for.body
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %akk.07 = phi i32 [ 0, %entry ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %arr, i64 %indvars.iv
  %0 = load i32, i32* %arrayidx, align 4, !tbaa !2
  %add = add nsw i32 %0, %akk.07
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 2
  %cmp = icmp ult i64 %indvars.iv.next, 10
  br i1 %cmp, label %for.body, label %for.cond.cleanup
}

;    typedef struct f2 {
;      float x, y;
;    } f2;
;    
;    f2 sum_f2(f2 *arr, int n) {
;      f2 akk = (f2){0, 0};
;      for (int i = 0; i < n; ++i) {
;        akk.x += arr[i].x;
;        akk.y += arr[i].y;
;      }
;      return akk;
;    }
; CHECK-LABEL: sum_f2
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0] -> arr[o0] : 0 <= i0 < n and 8i0 <= o0 <= 7 + 8i0 }
define <2 x float> @sum_f2(%struct.f2* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp15 = icmp sgt i32 %n, 0
  br i1 %cmp15, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext i32 %n to i64
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %entry
  %akk.sroa.6.0.lcssa = phi float [ 0.000000e+00, %entry ], [ %add5, %for.body ]
  %akk.sroa.0.0.lcssa = phi float [ 0.000000e+00, %entry ], [ %add, %for.body ]
  %retval.sroa.0.0.vec.insert = insertelement <2 x float> undef, float %akk.sroa.0.0.lcssa, i32 0
  %retval.sroa.0.4.vec.insert = insertelement <2 x float> %retval.sroa.0.0.vec.insert, float %akk.sroa.6.0.lcssa, i32 1
  ret <2 x float> %retval.sroa.0.4.vec.insert

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next, %for.body ]
  %akk.sroa.0.017 = phi float [ 0.000000e+00, %for.body.lr.ph ], [ %add, %for.body ]
  %akk.sroa.6.016 = phi float [ 0.000000e+00, %for.body.lr.ph ], [ %add5, %for.body ]
  %x = getelementptr inbounds %struct.f2, %struct.f2* %arr, i64 %indvars.iv, i32 0
  %0 = load float, float* %x, align 4, !tbaa !6
  %add = fadd float %akk.sroa.0.017, %0
  %y = getelementptr inbounds %struct.f2, %struct.f2* %arr, i64 %indvars.iv, i32 1
  %1 = load float, float* %y, align 4, !tbaa !9
  %add5 = fadd float %akk.sroa.6.016, %1
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

;    f2 sum_f2_skip(f2 *arr, int n) {
;      f2 akk = (f2){0, 0};
;      for (int i = 0; i < n; ++i) {
;        akk.x += arr[i].x;
;      }
;      return akk;
;    }
; CHECK-LABEL: sum_f2_skip
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0] -> arr[o0] : 0 <= i0 < n and 8i0 <= o0 <= 3 + 8i0 }
define <2 x float> @sum_f2_skip(%struct.f2* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp9 = icmp sgt i32 %n, 0
  br i1 %cmp9, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext i32 %n to i64
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %entry
  %akk.sroa.0.0.lcssa = phi float [ 0.000000e+00, %entry ], [ %add, %for.body ]
  %retval.sroa.0.4.vec.insert = insertelement <2 x float> <float undef, float 0.000000e+00>, float %akk.sroa.0.0.lcssa, i32 0
  ret <2 x float> %retval.sroa.0.4.vec.insert

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next, %for.body ]
  %akk.sroa.0.010 = phi float [ 0.000000e+00, %for.body.lr.ph ], [ %add, %for.body ]
  %x = getelementptr inbounds %struct.f2, %struct.f2* %arr, i64 %indvars.iv, i32 0
  %0 = load float, float* %x, align 4, !tbaa !6
  %add = fadd float %akk.sroa.0.010, %0
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

;    typedef struct m3 {
;      char c;
;      int i;
;      double d;
;    } m3;
;    
;    m3 sum_m3_1d(m3 *arr, int n) {
;      m3 akk = (m3){0, 0, 0};
;      for (int i = 0; i < n; ++i) {
;        akk.c += arr[i].c;
;        akk.i += arr[i].i;
;        akk.d += arr[i].d;
;      }
;      return akk;
;    }
; CHECK-LABEL: sum_m3_1d
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0] -> arr[o0] : 0 <= i0 < n and 4 + 16i0 <= o0 <= 15 + 16i0; [i0] -> arr[16i0] : 0 <= i0 < n }
define { i64, double } @sum_m3_1d(%struct.m3* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp34 = icmp sgt i32 %n, 0
  br i1 %cmp34, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext i32 %n to i64
  br label %for.body

for.cond.cleanup.loopexit:                        ; preds = %for.body
  %phitmp = zext i8 %add to i64
  %phitmp41 = zext i32 %add8 to i64
  %phitmp42 = shl nuw i64 %phitmp41, 32
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  %akk.sroa.8.0.lcssa = phi double [ 0.000000e+00, %entry ], [ %add12, %for.cond.cleanup.loopexit ]
  %akk.sroa.621.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp42, %for.cond.cleanup.loopexit ]
  %akk.sroa.0.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp, %for.cond.cleanup.loopexit ]
  %retval.sroa.0.4.insert.insert = or i64 %akk.sroa.621.0.lcssa, %akk.sroa.0.0.lcssa
  %.fca.0.insert = insertvalue { i64, double } undef, i64 %retval.sroa.0.4.insert.insert, 0
  %.fca.1.insert = insertvalue { i64, double } %.fca.0.insert, double %akk.sroa.8.0.lcssa, 1
  ret { i64, double } %.fca.1.insert

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next, %for.body ]
  %akk.sroa.0.037 = phi i8 [ 0, %for.body.lr.ph ], [ %add, %for.body ]
  %akk.sroa.621.036 = phi i32 [ 0, %for.body.lr.ph ], [ %add8, %for.body ]
  %akk.sroa.8.035 = phi double [ 0.000000e+00, %for.body.lr.ph ], [ %add12, %for.body ]
  %c = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %indvars.iv, i32 0
  %0 = load i8, i8* %c, align 8, !tbaa !10
  %add = add i8 %0, %akk.sroa.0.037
  %i6 = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %indvars.iv, i32 1
  %1 = load i32, i32* %i6, align 4, !tbaa !13
  %add8 = add nsw i32 %1, %akk.sroa.621.036
  %d = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %indvars.iv, i32 2
  %2 = load double, double* %d, align 8, !tbaa !14
  %add12 = fadd double %akk.sroa.8.035, %2
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup.loopexit, label %for.body
}

;    m3 sum_m3_2d(m3 *arr, int n) {
;      m3 akk = (m3){0, 0, 0};
;      for (int i = 0; i < n; ++i) {
;        for (int j = 0; j < n; ++j) {
;          akk.c += arr[i*n + j].c;
;          akk.i += arr[i*n + j].i;
;          akk.d += arr[i*n + j].d;
;        }
;      }
;      return akk;
;    }
; CHECK-LABEL: sum_m3_2d
; CHECK: Dimension sizes (Bytes):
; CHECK-NEXT: { [] -> [(16n)] }
; CHECK: MustRead (Bytes)
; CHECK-SAME: { [i0, i1] -> arr[i0, o1] : i0 >= 0 and 0 <= i1 < n and 4 + 16i1 <= o1 <= 15 + 16i1; [i0, i1] -> arr[i0, 16i1] : i0 >= 0 and 0 <= i1 < n }
define { i64, double } @sum_m3_2d(%struct.m3* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp62 = icmp sgt i32 %n, 0
  br i1 %cmp62, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %0 = sext i32 %n to i64
  %wide.trip.count = zext i32 %n to i64
  %wide.trip.count74 = zext i32 %n to i64
  br label %for.body4.lr.ph

for.cond.cleanup.loopexit:                        ; preds = %for.cond.cleanup3
  %phitmp = zext i8 %add7 to i64
  %phitmp76 = zext i32 %add15 to i64
  %phitmp77 = shl nuw i64 %phitmp76, 32
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  %akk.sroa.8.0.lcssa = phi double [ 0.000000e+00, %entry ], [ %add21, %for.cond.cleanup.loopexit ]
  %akk.sroa.638.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp77, %for.cond.cleanup.loopexit ]
  %akk.sroa.0.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp, %for.cond.cleanup.loopexit ]
  %retval.sroa.0.4.insert.insert = or i64 %akk.sroa.638.0.lcssa, %akk.sroa.0.0.lcssa
  %.fca.0.insert = insertvalue { i64, double } undef, i64 %retval.sroa.0.4.insert.insert, 0
  %.fca.1.insert = insertvalue { i64, double } %.fca.0.insert, double %akk.sroa.8.0.lcssa, 1
  ret { i64, double } %.fca.1.insert

for.body4.lr.ph:                                  ; preds = %for.body.lr.ph, %for.cond.cleanup3
  %indvars.iv71 = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next72, %for.cond.cleanup3 ]
  %akk.sroa.0.065 = phi i8 [ 0, %for.body.lr.ph ], [ %add7, %for.cond.cleanup3 ]
  %akk.sroa.638.064 = phi i32 [ 0, %for.body.lr.ph ], [ %add15, %for.cond.cleanup3 ]
  %akk.sroa.8.063 = phi double [ 0.000000e+00, %for.body.lr.ph ], [ %add21, %for.cond.cleanup3 ]
  %1 = mul nsw i64 %indvars.iv71, %0
  br label %for.body4

for.cond.cleanup3:                                ; preds = %for.body4
  %indvars.iv.next72 = add nuw nsw i64 %indvars.iv71, 1
  %exitcond75 = icmp eq i64 %indvars.iv.next72, %wide.trip.count74
  br i1 %exitcond75, label %for.cond.cleanup.loopexit, label %for.body4.lr.ph

for.body4:                                        ; preds = %for.body4, %for.body4.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body4.lr.ph ], [ %indvars.iv.next, %for.body4 ]
  %akk.sroa.0.158 = phi i8 [ %akk.sroa.0.065, %for.body4.lr.ph ], [ %add7, %for.body4 ]
  %akk.sroa.638.157 = phi i32 [ %akk.sroa.638.064, %for.body4.lr.ph ], [ %add15, %for.body4 ]
  %akk.sroa.8.156 = phi double [ %akk.sroa.8.063, %for.body4.lr.ph ], [ %add21, %for.body4 ]
  %2 = add nsw i64 %indvars.iv, %1
  %c = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 0
  %3 = load i8, i8* %c, align 8, !tbaa !10
  %add7 = add i8 %3, %akk.sroa.0.158
  %i13 = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 1
  %4 = load i32, i32* %i13, align 4, !tbaa !13
  %add15 = add nsw i32 %4, %akk.sroa.638.157
  %d = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 2
  %5 = load double, double* %d, align 8, !tbaa !14
  %add21 = fadd double %akk.sroa.8.156, %5
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup3, label %for.body4
}

; Function Attrs: norecurse nounwind readonly uwtable
define { i64, double } @sum_m3_2d_c(%struct.m3* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp36 = icmp sgt i32 %n, 0
  br i1 %cmp36, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %0 = sext i32 %n to i64
  %wide.trip.count = zext i32 %n to i64
  %wide.trip.count44 = zext i32 %n to i64
  br label %for.body4.lr.ph

for.cond.cleanup.loopexit:                        ; preds = %for.cond.cleanup3
  %phitmp = zext i8 %add7 to i64
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  %akk.sroa.0.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp, %for.cond.cleanup.loopexit ]
  %.fca.0.insert = insertvalue { i64, double } undef, i64 %akk.sroa.0.0.lcssa, 0
  %.fca.1.insert = insertvalue { i64, double } %.fca.0.insert, double 0.000000e+00, 1
  ret { i64, double } %.fca.1.insert

for.body4.lr.ph:                                  ; preds = %for.body.lr.ph, %for.cond.cleanup3
  %indvars.iv41 = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next42, %for.cond.cleanup3 ]
  %akk.sroa.0.037 = phi i8 [ 0, %for.body.lr.ph ], [ %add7, %for.cond.cleanup3 ]
  %1 = mul nsw i64 %indvars.iv41, %0
  br label %for.body4

for.cond.cleanup3:                                ; preds = %for.body4
  %indvars.iv.next42 = add nuw nsw i64 %indvars.iv41, 1
  %exitcond45 = icmp eq i64 %indvars.iv.next42, %wide.trip.count44
  br i1 %exitcond45, label %for.cond.cleanup.loopexit, label %for.body4.lr.ph

for.body4:                                        ; preds = %for.body4, %for.body4.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body4.lr.ph ], [ %indvars.iv.next, %for.body4 ]
  %akk.sroa.0.134 = phi i8 [ %akk.sroa.0.037, %for.body4.lr.ph ], [ %add7, %for.body4 ]
  %2 = add nsw i64 %indvars.iv, %1
  %c = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 0
  %3 = load i8, i8* %c, align 8, !tbaa !10
  %add7 = add i8 %3, %akk.sroa.0.134
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup3, label %for.body4
}

; Function Attrs: norecurse nounwind readonly uwtable
define { i64, double } @sum_m3_2d_i(%struct.m3* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp28 = icmp sgt i32 %n, 0
  br i1 %cmp28, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %0 = sext i32 %n to i64
  %wide.trip.count = zext i32 %n to i64
  %wide.trip.count36 = zext i32 %n to i64
  br label %for.body4.lr.ph

for.cond.cleanup.loopexit:                        ; preds = %for.cond.cleanup3
  %phitmp = zext i32 %add7 to i64
  %phitmp38 = shl nuw i64 %phitmp, 32
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  %akk.sroa.4.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp38, %for.cond.cleanup.loopexit ]
  %.fca.0.insert = insertvalue { i64, double } undef, i64 %akk.sroa.4.0.lcssa, 0
  %.fca.1.insert = insertvalue { i64, double } %.fca.0.insert, double 0.000000e+00, 1
  ret { i64, double } %.fca.1.insert

for.body4.lr.ph:                                  ; preds = %for.body.lr.ph, %for.cond.cleanup3
  %indvars.iv33 = phi i64 [ 0, %for.body.lr.ph ], [ %indvars.iv.next34, %for.cond.cleanup3 ]
  %akk.sroa.4.029 = phi i32 [ 0, %for.body.lr.ph ], [ %add7, %for.cond.cleanup3 ]
  %1 = mul nsw i64 %indvars.iv33, %0
  br label %for.body4

for.cond.cleanup3:                                ; preds = %for.body4
  %indvars.iv.next34 = add nuw nsw i64 %indvars.iv33, 1
  %exitcond37 = icmp eq i64 %indvars.iv.next34, %wide.trip.count36
  br i1 %exitcond37, label %for.cond.cleanup.loopexit, label %for.body4.lr.ph

for.body4:                                        ; preds = %for.body4, %for.body4.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body4.lr.ph ], [ %indvars.iv.next, %for.body4 ]
  %akk.sroa.4.126 = phi i32 [ %akk.sroa.4.029, %for.body4.lr.ph ], [ %add7, %for.body4 ]
  %2 = add nsw i64 %indvars.iv, %1
  %i5 = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 1
  %3 = load i32, i32* %i5, align 4, !tbaa !13
  %add7 = add nsw i32 %3, %akk.sroa.4.126
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup3, label %for.body4
}

; Function Attrs: norecurse nounwind readonly uwtable
define { i64, double } @sum_m3_3d(%struct.m3* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
entry:
  %cmp99 = icmp sgt i32 %n, 0
  br i1 %cmp99, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext i32 %n to i64
  %wide.trip.count110 = zext i32 %n to i64
  br label %for.body4.lr.ph

for.cond.cleanup.loopexit:                        ; preds = %for.cond.cleanup3
  %phitmp = zext i8 %add14 to i64
  %phitmp113 = zext i32 %add25 to i64
  %phitmp114 = shl nuw i64 %phitmp113, 32
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  %akk.sroa.8.0.lcssa = phi double [ 0.000000e+00, %entry ], [ %add34, %for.cond.cleanup.loopexit ]
  %akk.sroa.659.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp114, %for.cond.cleanup.loopexit ]
  %akk.sroa.0.0.lcssa = phi i64 [ 0, %entry ], [ %phitmp, %for.cond.cleanup.loopexit ]
  %retval.sroa.0.4.insert.insert = or i64 %akk.sroa.659.0.lcssa, %akk.sroa.0.0.lcssa
  %.fca.0.insert = insertvalue { i64, double } undef, i64 %retval.sroa.0.4.insert.insert, 0
  %.fca.1.insert = insertvalue { i64, double } %.fca.0.insert, double %akk.sroa.8.0.lcssa, 1
  ret { i64, double } %.fca.1.insert

for.body4.lr.ph:                                  ; preds = %for.body.lr.ph, %for.cond.cleanup3
  %i.0103 = phi i32 [ 0, %for.body.lr.ph ], [ %inc39, %for.cond.cleanup3 ]
  %akk.sroa.0.0102 = phi i8 [ 0, %for.body.lr.ph ], [ %add14, %for.cond.cleanup3 ]
  %akk.sroa.659.0101 = phi i32 [ 0, %for.body.lr.ph ], [ %add25, %for.cond.cleanup3 ]
  %akk.sroa.8.0100 = phi double [ 0.000000e+00, %for.body.lr.ph ], [ %add34, %for.cond.cleanup3 ]
  %mul = mul nsw i32 %i.0103, %n
  br label %for.body8.lr.ph

for.cond.cleanup3:                                ; preds = %for.cond.cleanup7
  %inc39 = add nuw nsw i32 %i.0103, 1
  %exitcond112 = icmp eq i32 %inc39, %n
  br i1 %exitcond112, label %for.cond.cleanup.loopexit, label %for.body4.lr.ph

for.body8.lr.ph:                                  ; preds = %for.body4.lr.ph, %for.cond.cleanup7
  %indvars.iv108 = phi i64 [ 0, %for.body4.lr.ph ], [ %indvars.iv.next109, %for.cond.cleanup7 ]
  %akk.sroa.0.194 = phi i8 [ %akk.sroa.0.0102, %for.body4.lr.ph ], [ %add14, %for.cond.cleanup7 ]
  %akk.sroa.659.193 = phi i32 [ %akk.sroa.659.0101, %for.body4.lr.ph ], [ %add25, %for.cond.cleanup7 ]
  %akk.sroa.8.192 = phi double [ %akk.sroa.8.0100, %for.body4.lr.ph ], [ %add34, %for.cond.cleanup7 ]
  %0 = trunc i64 %indvars.iv108 to i32
  %mul981 = add i32 %mul, %0
  %add = mul i32 %mul981, %n
  %1 = sext i32 %add to i64
  br label %for.body8

for.cond.cleanup7:                                ; preds = %for.body8
  %indvars.iv.next109 = add nuw nsw i64 %indvars.iv108, 1
  %exitcond111 = icmp eq i64 %indvars.iv.next109, %wide.trip.count110
  br i1 %exitcond111, label %for.cond.cleanup3, label %for.body8.lr.ph

for.body8:                                        ; preds = %for.body8, %for.body8.lr.ph
  %indvars.iv = phi i64 [ 0, %for.body8.lr.ph ], [ %indvars.iv.next, %for.body8 ]
  %akk.sroa.0.287 = phi i8 [ %akk.sroa.0.194, %for.body8.lr.ph ], [ %add14, %for.body8 ]
  %akk.sroa.659.286 = phi i32 [ %akk.sroa.659.193, %for.body8.lr.ph ], [ %add25, %for.body8 ]
  %akk.sroa.8.285 = phi double [ %akk.sroa.8.192, %for.body8.lr.ph ], [ %add34, %for.body8 ]
  %2 = add nsw i64 %indvars.iv, %1
  %c = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 0
  %3 = load i8, i8* %c, align 8, !tbaa !10
  %add14 = add i8 %3, %akk.sroa.0.287
  %i23 = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 1
  %4 = load i32, i32* %i23, align 4, !tbaa !13
  %add25 = add nsw i32 %4, %akk.sroa.659.286
  %d = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %2, i32 2
  %5 = load double, double* %d, align 8, !tbaa !14
  %add34 = fadd double %akk.sroa.8.285, %5
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup7, label %for.body8
}

attributes #0 = { norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 6.0.0 (https://github.com/llvm-mirror/clang 2f27999df400d17b33cdd412fdd606a88208dfcc) (git@public.cdl.uni-saarland.de:optimization/LLVM.git 856c421528991550fe970350e918d15daad121a0)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"int", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}
!6 = !{!7, !8, i64 0}
!7 = !{!"f2", !8, i64 0, !8, i64 4}
!8 = !{!"float", !4, i64 0}
!9 = !{!7, !8, i64 4}
!10 = !{!11, !4, i64 0}
!11 = !{!"m3", !4, i64 0, !3, i64 4, !12, i64 8}
!12 = !{!"double", !4, i64 0}
!13 = !{!11, !3, i64 4}
!14 = !{!11, !12, i64 8}
