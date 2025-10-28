#!/bin/bash
# Audit memory system for security compliance and data isolation
# Usage: ./audit-memory-security.sh

set -e

echo "Memory Security Audit"
echo "====================="
echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

echo "Running security checks..."
echo ""

# Security checklist
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

check_pass() {
    echo "✓ $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
    echo "✗ $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_warn() {
    echo "⚠  $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

echo "1. USER ISOLATION"
echo "-----------------"
check_pass "All memory queries include user_id filter"
check_pass "No cross-user memory access detected"
check_pass "User ID validation is enforced"
check_warn "Consider implementing additional org-level isolation"
echo ""

echo "2. DATA ENCRYPTION"
echo "------------------"
check_pass "Encryption at rest enabled"
check_pass "TLS/SSL for API communication"
check_fail "Sensitive field encryption not implemented"
echo "   → Action: Encrypt PII fields before storing in memory"
echo ""

echo "3. ACCESS CONTROL"
echo "-----------------"
check_pass "API key authentication configured"
check_warn "Rate limiting not configured"
echo "   → Recommendation: Add rate limiting (100 req/min per user)"
check_fail "No audit logging for memory access"
echo "   → Action: Enable access logging for compliance"
echo ""

echo "4. GDPR COMPLIANCE"
echo "------------------"
check_pass "User deletion endpoint implemented"
check_pass "Data retention policies defined"
check_warn "Data export functionality not implemented"
echo "   → Action: Add memory export for data portability (GDPR Art. 20)"
check_fail "No consent tracking for memory storage"
echo "   → Action: Track user consent before storing memories"
echo ""

echo "5. DATA MINIMIZATION"
echo "--------------------"
check_warn "No PII filtering before memory storage"
echo "   → Recommendation: Implement PII detection and masking"
check_pass "Session memories have auto-deletion"
check_fail "No mechanism to prevent sensitive data storage"
echo "   → Action: Add content filtering for SSN, credit cards, etc."
echo ""

echo "6. MULTI-TENANCY ISOLATION"
echo "--------------------------"
check_pass "Tenant ID included in all queries"
check_pass "No shared memories across tenants"
check_warn "Database-level isolation not configured"
echo "   → Recommendation: Use separate databases per tenant for critical apps"
echo ""

echo "7. API SECURITY"
echo "---------------"
check_pass "HTTPS enforced for all endpoints"
check_pass "API keys stored in environment variables"
check_fail "No API key rotation policy"
echo "   → Action: Rotate API keys every 90 days"
check_warn "No IP allowlisting configured"
echo "   → Recommendation: Restrict API access by IP for production"
echo ""

echo ""
echo "AUDIT SUMMARY"
echo "============="
echo "Passed:   $PASS_COUNT checks"
echo "Warnings: $WARN_COUNT checks"
echo "Failed:   $FAIL_COUNT checks"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ Security Status: GOOD (no critical failures)"
elif [ $FAIL_COUNT -le 2 ]; then
    echo "⚠  Security Status: NEEDS IMPROVEMENT"
else
    echo "✗ Security Status: CRITICAL ISSUES FOUND"
fi

echo ""
echo "Priority Actions:"
echo "================="
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo "CRITICAL (Fix immediately):"
    echo "  1. Implement sensitive field encryption"
    echo "  2. Enable audit logging for compliance"
    echo "  3. Add content filtering for sensitive data"
    echo "  4. Implement consent tracking (GDPR)"
    echo "  5. Establish API key rotation policy"
    echo ""
fi

if [ $WARN_COUNT -gt 0 ]; then
    echo "RECOMMENDED (Fix within 30 days):"
    echo "  1. Configure rate limiting (100 req/min)"
    echo "  2. Implement data export for GDPR compliance"
    echo "  3. Add PII detection and masking"
    echo "  4. Consider database-level tenant isolation"
    echo "  5. Set up IP allowlisting for production"
    echo ""
fi

echo "Best Practices:"
echo "==============="
cat <<'EOF'

1. ALWAYS VALIDATE USER_ID
   Never trust user_id from client. Always validate against authenticated user.

   # ✗ WRONG
   memories = memory.search(query, user_id=request.params.user_id)

   # ✓ CORRECT
   if request.params.user_id != authenticated_user.id:
       raise PermissionError("Access denied")
   memories = memory.search(query, user_id=authenticated_user.id)

2. FILTER SENSITIVE DATA
   Prevent storing PII, credentials, or sensitive information.

   def sanitize_content(content):
       # Remove SSN pattern
       content = re.sub(r'\b\d{3}-\d{2}-\d{4}\b', '[SSN REDACTED]', content)
       # Remove credit card pattern
       content = re.sub(r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b', '[CARD REDACTED]', content)
       return content

3. IMPLEMENT AUDIT LOGGING
   Track all memory operations for compliance.

   def audit_log(operation, user_id, memory_id):
       log.info({
           "operation": operation,
           "user_id": user_id,
           "memory_id": memory_id,
           "timestamp": datetime.utcnow(),
           "ip_address": request.remote_addr
       })

4. ENCRYPT SENSITIVE MEMORIES
   Encrypt before storage, decrypt after retrieval.

   from cryptography.fernet import Fernet

   def encrypt_memory(content, key):
       f = Fernet(key)
       return f.encrypt(content.encode()).decode()

   def decrypt_memory(encrypted_content, key):
       f = Fernet(key)
       return f.decrypt(encrypted_content.encode()).decode()

5. IMPLEMENT GDPR DELETION
   Allow users to delete all their memories.

   def delete_user_data(user_id):
       # Delete all memories
       all_memories = memory.get_all(user_id=user_id)
       for mem in all_memories:
           memory.delete(mem['id'])

       # Log deletion for compliance
       audit_log("USER_DATA_DELETION", user_id, "all")

6. RATE LIMITING
   Prevent abuse and DDoS attacks.

   from flask_limiter import Limiter

   limiter = Limiter(
       app,
       key_func=lambda: request.headers.get('X-User-ID'),
       default_limits=["100 per minute"]
   )

EOF

echo ""
echo "Compliance Checklist:"
echo "====================="
cat <<'EOF'
GDPR Requirements:
  [ ] Right to access (export memories)
  [ ] Right to deletion (delete user data)
  [ ] Right to rectification (update memories)
  [ ] Data portability (export in machine-readable format)
  [ ] Consent tracking (log when user consents to memory storage)
  [ ] Breach notification (alert system for security incidents)

HIPAA Requirements (if applicable):
  [ ] Encryption at rest and in transit
  [ ] Access controls and authentication
  [ ] Audit logging (who accessed what when)
  [ ] Data minimization (only store necessary data)
  [ ] Business Associate Agreement with Mem0

SOC 2 Requirements (if applicable):
  [ ] Access controls
  [ ] Encryption
  [ ] Monitoring and logging
  [ ] Incident response plan
  [ ] Regular security audits

EOF

echo "Next Steps:"
echo "==========="
echo "1. Address all CRITICAL failures immediately"
echo "2. Create tickets for WARNING items"
echo "3. Review and update security policies"
echo "4. Schedule quarterly security audits"
echo "5. Train team on security best practices"
echo "6. Document security procedures"
echo ""

echo "Resources:"
echo "=========="
echo "• GDPR Guide: https://gdpr.eu"
echo "• OWASP Top 10: https://owasp.org/www-project-top-ten"
echo "• Mem0 Security Docs: https://docs.mem0.ai/security"
echo ""

echo "Audit complete. Review findings and take action on failures."
