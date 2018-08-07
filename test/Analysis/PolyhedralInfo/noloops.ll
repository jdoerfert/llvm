; RUN: opt -polyhedral-value-info -analyze < %s | FileCheck %s
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

;    int *pass_through(int *A) {
;      return A;
;    }
define i32* @pass_through(i32* readnone returned) local_unnamed_addr #0 {
  ret i32* %0
}
