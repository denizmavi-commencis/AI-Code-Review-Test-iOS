#!/bin/bash
#
#  runner.sh
#  YatirimFinansman
#
#  Created on 31/10/2023.
#  Copyright (c) 2023 Commencis. All rights reserved.
#
#  Save to the extent permitted by law, you may not use, copy, modify,
#  distribute or create derivative works of this material or any part
#  of it without the prior written consent of Commencis.
#  Any reproduction of this material must contain this notice.
#
#

set -e
cd .. && dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs