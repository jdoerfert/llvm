; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

%struct.f2 = type { float, float }
%struct.m3 = type { i8, i32, double }

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
; CHECK: { [i0] -> [(1)] : 0 <= i0 < n } [for.body]
; CHECK: %x = getelementptr inbounds %struct.f2
; CHECK: { [i0] -> [(arr + 8i0)] } [x]
; CHECK: %y = getelementptr inbounds %struct.f2
; CHECK: { [i0] -> [(4 + arr + 8i0)] } [y]
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
  %0 = load float, float* %x, align 4
  %add = fadd float %akk.sroa.0.017, %0
  %y = getelementptr inbounds %struct.f2, %struct.f2* %arr, i64 %indvars.iv, i32 1
  %1 = load float, float* %y, align 4
  %add5 = fadd float %akk.sroa.6.016, %1
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
;    m3 sum_m3(m3 *arr, int n) {
;      m3 akk = (m3){0, 0, 0};
;      for (int i = 0; i < n; ++i) {
;        akk.c += arr[i].c;
;        akk.i += arr[i].i;
;        akk.d += arr[i].d;
;      }
;      return akk;
;    }
; CHECK-LABEL: sum_m3
; CHECK: { [i0] -> [(1)] : 0 <= i0 < n } [for.body]
; CHECK: { [i0] -> [(arr + 16i0)] } [c]
; CHECK: { [i0] -> [(4 + arr + 16i0)] } [i6]
; CHECK: { [i0] -> [(8 + arr + 16i0)] } [d]
define { i64, double } @sum_m3(%struct.m3* nocapture readonly %arr, i32 %n) local_unnamed_addr #0 {
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
  %0 = load i8, i8* %c, align 8
  %add = add i8 %0, %akk.sroa.0.037
  %i6 = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %indvars.iv, i32 1
  %1 = load i32, i32* %i6, align 4
  %add8 = add nsw i32 %1, %akk.sroa.621.036
  %d = getelementptr inbounds %struct.m3, %struct.m3* %arr, i64 %indvars.iv, i32 2
  %2 = load double, double* %d, align 8
  %add12 = fadd double %akk.sroa.8.035, %2
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup.loopexit, label %for.body
}
