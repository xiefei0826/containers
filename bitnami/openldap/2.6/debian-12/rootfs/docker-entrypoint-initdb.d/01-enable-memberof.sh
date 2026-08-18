#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# Script to enable memberOf overlay in OpenLDAP
# This script runs BEFORE slapd starts, so we must use slapadd
set -e

echo "=== Starting MemberOf Overlay Configuration (Pre-Start) ==="

# 检查是否已配置memberof
if slapcat -F /opt/bitnami/openldap/etc/slapd.d -b cn=config | grep -q "olcOverlay.*memberof"; then
    echo "✓ MemberOf overlay is already configured."
    exit 0
fi

# 配置MemberOf Overlay
echo "=== Configuring MemberOf Overlay ==="

# 创建LDIF文件
cat > /tmp/memberof-overlay.ldif << 'EOF'
dn: cn=module{1},cn=config
objectClass: olcModuleList
cn: module{1}
olcModulePath: /opt/bitnami/openldap/libexec/openldap
olcModuleLoad: memberof.so

dn: olcOverlay=memberof,olcDatabase={2}mdb,cn=config
objectClass: olcOverlayConfig
objectClass: olcMemberOf
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfNames
olcMemberOfMemberAD: member
olcMemberOfMemberOfAD: memberOf
EOF

# 应用配置（使用slapadd，因为slapd尚未启动）
echo "Enabling memberOf overlay using slapadd..."
if slapadd -F /opt/bitnami/openldap/etc/slapd.d -b cn=config -l /tmp/memberof-overlay.ldif; then
    echo "✓ MemberOf overlay configured successfully"
else
    echo "⚠ MemberOf overlay configuration may have failed or already exists"
fi

echo "=== Configuration completed ==="

# 验证配置
echo "=== Verification ==="
if slapcat -F /opt/bitnami/openldap/etc/slapd.d -b cn=config | grep -q "olcOverlay.*memberof"; then
    echo "✅ MemberOf overlay configuration successful"
else
    echo "❌ MemberOf overlay configuration failed"
fi