#!/bin/bash
#
#  proto.sh
#  YatirimFinansman
#
#  Created on 30/10/2023.
#  Copyright (c) 2023 Commencis. All rights reserved.
#
#  Save to the extent permitted by law, you may not use, copy, modify,
#  distribute or create derivative works of this material or any part
#  of it without the prior written consent of Commencis.
#  Any reproduction of this material must contain this notice.
#
#

set -e
cd ../lib/common/mqtt/models/proto && dart pub global activate protoc_plugin && protoc --dart_out=. Symbol.proto && protoc --dart_out=. Derivative.proto && protoc --dart_out=. Messenger.proto