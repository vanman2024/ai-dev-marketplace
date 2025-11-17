"""
Celery Custom Serialization Patterns
=====================================

Implement custom serializers for complex data types, binary data,
or specialized encoding requirements.

Default serializers: json, pickle, yaml, msgpack

SECURITY: Avoid pickle serializer in production (code execution risk).
         JSON is recommended for security and cross-language compatibility.
"""

import os
import json
import base64
from datetime import datetime, date
from decimal import Decimal
from celery import Celery
from kombu.serialization import register

# Security: Load configuration from environment
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
result_backend = f'redis://:{REDIS_PASSWORD}@{REDIS_HOST}:6379/0'

app = Celery('myapp', backend=result_backend)

# ========================================
# Pattern 1: Extended JSON Serializer
# ========================================

class ExtendedJSONEncoder(json.JSONEncoder):
    """Handle datetime, Decimal, bytes, and other Python types"""

    def default(self, obj):
        # Datetime objects
        if isinstance(obj, (datetime, date)):
            return {
                '__type__': 'datetime',
                'value': obj.isoformat()
            }

        # Decimal numbers
        elif isinstance(obj, Decimal):
            return {
                '__type__': 'decimal',
                'value': str(obj)
            }

        # Binary data
        elif isinstance(obj, bytes):
            return {
                '__type__': 'bytes',
                'value': base64.b64encode(obj).decode('utf-8')
            }

        # Sets
        elif isinstance(obj, set):
            return {
                '__type__': 'set',
                'value': list(obj)
            }

        return super().default(obj)

def extended_json_decoder(obj):
    """Decode extended JSON objects"""
    if isinstance(obj, dict) and '__type__' in obj:
        type_name = obj['__type__']
        value = obj['value']

        if type_name == 'datetime':
            return datetime.fromisoformat(value)

        elif type_name == 'decimal':
            return Decimal(value)

        elif type_name == 'bytes':
            return base64.b64decode(value.encode('utf-8'))

        elif type_name == 'set':
            return set(value)

    return obj

def extended_json_encode(obj):
    """Encode with extended JSON encoder"""
    return json.dumps(obj, cls=ExtendedJSONEncoder).encode('utf-8')

def extended_json_decode(data):
    """Decode with extended JSON decoder"""
    return json.loads(data.decode('utf-8'), object_hook=extended_json_decoder)

# Register extended JSON serializer
register(
    'extended_json',
    extended_json_encode,
    extended_json_decode,
    content_type='application/x-extended-json',
    content_encoding='utf-8'
)

# Configure app to use extended JSON
app.conf.update(
    result_serializer='extended_json',
    task_serializer='extended_json',
    accept_content=['extended_json', 'json'],
)

# ========================================
# Pattern 2: MessagePack Serializer (Binary)
# ========================================

try:
    import msgpack

    def msgpack_encode(obj):
        """Encode using MessagePack (more efficient than JSON)"""
        return msgpack.packb(obj, use_bin_type=True)

    def msgpack_decode(data):
        """Decode MessagePack data"""
        return msgpack.unpackb(data, raw=False)

    register(
        'msgpack',
        msgpack_encode,
        msgpack_decode,
        content_type='application/x-msgpack',
        content_encoding='binary'
    )

except ImportError:
    print("msgpack not installed: pip install msgpack")

# ========================================
# Pattern 3: Compressed Serializer
# ========================================

import gzip

def compressed_json_encode(obj):
    """JSON encode and compress"""
    json_data = json.dumps(obj).encode('utf-8')
    return gzip.compress(json_data)

def compressed_json_decode(data):
    """Decompress and JSON decode"""
    json_data = gzip.decompress(data)
    return json.loads(json_data.decode('utf-8'))

register(
    'compressed_json',
    compressed_json_encode,
    compressed_json_decode,
    content_type='application/x-compressed-json',
    content_encoding='binary'
)

# ========================================
# Pattern 4: Domain-Specific Serializer
# ========================================

class User:
    """Example domain object"""
    def __init__(self, id, name, email):
        self.id = id
        self.name = name
        self.email = email

class Order:
    """Example domain object"""
    def __init__(self, id, user, items, total):
        self.id = id
        self.user = user
        self.items = items
        self.total = total

def domain_encoder(obj):
    """Encode domain objects"""
    if isinstance(obj, User):
        return {
            '__type__': 'User',
            'id': obj.id,
            'name': obj.name,
            'email': obj.email
        }
    elif isinstance(obj, Order):
        return {
            '__type__': 'Order',
            'id': obj.id,
            'user': domain_encoder(obj.user),
            'items': obj.items,
            'total': str(obj.total)
        }
    return obj

def domain_decoder(obj):
    """Decode domain objects"""
    if isinstance(obj, dict) and '__type__' in obj:
        if obj['__type__'] == 'User':
            return User(obj['id'], obj['name'], obj['email'])
        elif obj['__type__'] == 'Order':
            return Order(
                obj['id'],
                domain_decoder(obj['user']),
                obj['items'],
                Decimal(obj['total'])
            )
    return obj

def domain_serialize(obj):
    """Serialize domain objects"""
    return json.dumps(obj, default=domain_encoder).encode('utf-8')

def domain_deserialize(data):
    """Deserialize domain objects"""
    return json.loads(data.decode('utf-8'), object_hook=domain_decoder)

register(
    'domain',
    domain_serialize,
    domain_deserialize,
    content_type='application/x-domain',
    content_encoding='utf-8'
)

# ========================================
# Pattern 5: Per-Task Serializer
# ========================================

@app.task(serializer='json')
def json_task(data):
    """Task using standard JSON serializer"""
    return {'result': data}

@app.task(serializer='extended_json')
def datetime_task():
    """Task that returns datetime objects"""
    return {
        'timestamp': datetime.now(),
        'date': date.today(),
        'amount': Decimal('123.45')
    }

@app.task(serializer='msgpack')
def binary_task(data):
    """Task using efficient binary serialization"""
    return {'data': data, 'count': len(data)}

@app.task(serializer='compressed_json')
def large_result_task():
    """Task with large results that benefit from compression"""
    return {
        'data': ['item' * 100 for _ in range(1000)]
    }

@app.task(serializer='domain')
def order_processing_task(user_id, items):
    """Task that works with domain objects"""
    user = User(user_id, "John Doe", "john@example.com")
    order = Order(12345, user, items, Decimal('99.99'))
    return order

# ========================================
# Pattern 6: Hybrid Serializer Strategy
# ========================================

def smart_serializer(obj):
    """Choose serializer based on data type"""
    # Small simple data → JSON
    if isinstance(obj, (str, int, float, bool, type(None))):
        return json.dumps(obj).encode('utf-8')

    # Large data → Compressed JSON
    json_str = json.dumps(obj)
    if len(json_str) > 10000:  # > 10KB
        return gzip.compress(json_str.encode('utf-8'))

    # Complex objects → Extended JSON
    return extended_json_encode(obj)

# ========================================
# Pattern 7: Encryption for Sensitive Data
# ========================================

from cryptography.fernet import Fernet

# Security: Load encryption key from environment
ENCRYPTION_KEY = os.getenv('CELERY_ENCRYPTION_KEY', Fernet.generate_key())
cipher_suite = Fernet(ENCRYPTION_KEY)

def encrypted_encode(obj):
    """Encrypt serialized data"""
    json_data = json.dumps(obj).encode('utf-8')
    encrypted = cipher_suite.encrypt(json_data)
    return encrypted

def encrypted_decode(data):
    """Decrypt and deserialize data"""
    decrypted = cipher_suite.decrypt(data)
    return json.loads(decrypted.decode('utf-8'))

register(
    'encrypted',
    encrypted_encode,
    encrypted_decode,
    content_type='application/x-encrypted-json',
    content_encoding='binary'
)

@app.task(serializer='encrypted')
def sensitive_task(credit_card_info):
    """Task handling sensitive data with encryption"""
    return {'processed': True, 'last_four': credit_card_info[-4:]}

# ========================================
# Testing Serializers
# ========================================

def test_serializers():
    """Test all custom serializers"""

    # Test extended JSON
    print("=== Extended JSON ===")
    result = datetime_task.delay()
    data = result.get(timeout=10)
    print(f"Datetime result: {data}")
    print(f"Type: {type(data['timestamp'])}")

    # Test domain serializer
    print("\n=== Domain Serializer ===")
    result = order_processing_task.delay(123, ['item1', 'item2'])
    order = result.get(timeout=10)
    print(f"Order ID: {order.id}")
    print(f"User: {order.user.name}")
    print(f"Total: {order.total}")

    # Test compressed
    print("\n=== Compressed JSON ===")
    result = large_result_task.delay()
    data = result.get(timeout=10)
    print(f"Large result items: {len(data['data'])}")

    # Test encrypted
    print("\n=== Encrypted Serializer ===")
    result = sensitive_task.delay("4111111111111111")
    data = result.get(timeout=10)
    print(f"Processed: {data}")

# ========================================
# Serializer Comparison
# ========================================

"""
Serializer Comparison:
----------------------

JSON (default):
✅ Human-readable
✅ Cross-language compatible
✅ Secure (no code execution)
❌ Can't serialize datetime, Decimal, bytes
❌ Larger size than binary formats

Pickle:
✅ Serializes any Python object
❌ Security risk (code execution)
❌ Python-only
❌ Not recommended for production

Extended JSON:
✅ Handles datetime, Decimal, bytes
✅ Human-readable
✅ Secure
❌ Slightly more overhead than JSON

MessagePack:
✅ Efficient binary format
✅ Smaller than JSON
✅ Cross-language support
❌ Not human-readable
❌ Requires msgpack library

Compressed JSON:
✅ Reduced bandwidth
✅ Good for large results
❌ CPU overhead for compression
❌ Not human-readable in storage

Encrypted:
✅ Protects sensitive data
✅ Required for compliance (PCI, HIPAA)
❌ Performance overhead
❌ Key management complexity

Best Practices:
---------------
1. Use JSON by default for simplicity and security
2. Use Extended JSON when you need datetime/Decimal support
3. Use MessagePack for performance-critical binary data
4. Use Compressed JSON for large results
5. Use Encrypted serializer for sensitive data
6. NEVER use Pickle in production
7. Test serializer with actual data patterns
8. Document serializer choice in code
9. Consider cross-language compatibility
10. Monitor serialization performance impact
"""

if __name__ == '__main__':
    # Run tests
    test_serializers()

"""
Installation Requirements:
--------------------------
pip install msgpack  # For MessagePack serializer
pip install cryptography  # For encryption

Environment Variables (.env):
------------------------------
CELERY_ENCRYPTION_KEY=your_fernet_key_here  # Generate with Fernet.generate_key()
REDIS_HOST=localhost
REDIS_PASSWORD=your_redis_password_here

Generate Encryption Key:
------------------------
from cryptography.fernet import Fernet
key = Fernet.generate_key()
print(key.decode())  # Add to .env file
"""
