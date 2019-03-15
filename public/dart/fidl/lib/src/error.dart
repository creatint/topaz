// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

class FidlError implements Exception {
  FidlError(this.message);

  final String message;

  @override
  String toString() => 'FidlError: $message';
}

class MethodError<T> implements Exception {
  MethodError(this.value);

  final T value;

  @override
  String toString() => 'MethodError: $value';
}
