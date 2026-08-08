# 3DS Presence — service-logs sidecar image
# Copyright (C) 2026 3DS Presence - LeonLeBreton
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

FROM alpine:3.22

# coreutils : GNU date (handles yesterday, timezones, DST correctly)
# jq         : read config.v2.json (compose labels)
# xz         : compression (busybox applet cannot compress)
# tzdata     : named timezones (TZ)
RUN apk add --no-cache coreutils jq xz tzdata

COPY rotate.sh /rotate.sh
RUN chmod +x /rotate.sh

CMD ["sh", "/rotate.sh"]