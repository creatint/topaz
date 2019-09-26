#!/usr/bin/env python
import os

if os.path.exists("../../third_party/dart/sdk/lib/_internal/vm/bin/builtin.dart"):
	print("True")
else:
	print("False")