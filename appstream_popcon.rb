#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Copyright (C) 2016 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) version 3, or any
# later version accepted by the membership of KDE e.V. (or its
# successor approved by the membership of KDE e.V.), which shall
# act as a proxy defined in Section 6 of version 3 of the license.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

load_path = '/var/lib/jenkins/ci-tooling'
require "#{load_path}/lib/apt"
require "#{load_path}/lib/retry"

# Simple builder building https://github.com/aleixpol/AppstreamPopcon

Retry.retry_it do
  Apt.install(%w(cmake libkf5archive-dev libappstreamqt-dev appstream))
end
# appstream data for some reason requires an apt update.
Retry.retry_it(times: 2, sleep: 16) { Apt.update }

abort unless system('appstreamcli refresh')

Dir.mkdir('build') unless Dir.exist?('build')
Dir.chdir('build') do
  abort unless system('cmake ..')
  abort unless system("make -j#{`nproc`.strip}")
end

all_popcon_url = 'http://popcon.debian.org/all-popcon-results.gz'
output = 'appstream-popcon.gz'
cmd = format('build/appstreampopcon %s | gzip -c > %s', all_popcon_url, output)
abort unless system(cmd)
