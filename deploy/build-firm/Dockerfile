# 3DS Presence — Discord Rich Presence for Nintendo 3DS
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

FROM docker.io/devkitpro/devkitarm:20260610

RUN apt update && apt install -y python3-pip git
RUN pip install -U git+https://github.com/TuxSH/firmtool.git --break-system-packages
RUN git clone https://github.com/3DSGuy/Project_CTR.git && cd Project_CTR/makerom && make deps && make && cp bin/makerom /bin/makerom

WORKDIR /app
COPY --chown=root:root build.sh build.sh
RUN chmod o+rx build.sh && mkdir -p info

CMD ["/app/build.sh"]
