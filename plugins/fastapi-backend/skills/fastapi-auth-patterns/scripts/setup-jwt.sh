#!/bin/bash

# setup-jwt.sh
# Initialize JWT authentication system for FastAPI
# Usage: ./setup-jwt.sh [project_dir]

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "🔐 Setting up JWT Authentication for FastAPI..."

# Check if Python virtual environment exists
if [ ! -d "venv" ] && [ ! -d ".venv" ]; then
    echo "⚠️  No virtual environment found. Create one with: python -m venv venv"
fi

# Install required packages
echo ""
echo "📦 Installing required packages..."
pip install fastapi python-jose[cryptography] pwdlib[argon2] python-multipart

# Generate SECRET_KEY
echo ""
echo "🔑 Generating SECRET_KEY..."
SECRET_KEY=$(openssl rand -hex 32)

# Create or update .env file
if [ -f ".env" ]; then
    echo "📝 Updating existing .env file..."
    # Check if SECRET_KEY exists
    if grep -q "^SECRET_KEY=" .env; then
        echo "⚠️  SECRET_KEY already exists in .env. Skipping..."
    else
        echo "SECRET_KEY=$SECRET_KEY" >> .env
        echo "✅ SECRET_KEY added to .env"
    fi

    # Add other variables if missing
    grep -q "^ALGORITHM=" .env || echo "ALGORITHM=HS256" >> .env
    grep -q "^ACCESS_TOKEN_EXPIRE_MINUTES=" .env || echo "ACCESS_TOKEN_EXPIRE_MINUTES=30" >> .env
else
    echo "📝 Creating .env file..."
    cat > .env << EOF
# JWT Authentication Configuration
SECRET_KEY=$SECRET_KEY
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF
    echo "✅ .env file created"
fi

# Ensure .env is in .gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo ".env" >> .gitignore
        echo "✅ Added .env to .gitignore"
    fi
else
    echo ".env" > .gitignore
    echo "✅ Created .gitignore with .env"
fi

# Create auth directory structure
echo ""
echo "📁 Creating authentication directory structure..."
mkdir -p app/auth
touch app/__init__.py
touch app/auth/__init__.py

# Create models file
if [ ! -f "app/auth/models.py" ]; then
    cat > app/auth/models.py << 'EOF'
from pydantic import BaseModel

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: str | None = None
    scopes: list[str] = []

class User(BaseModel):
    username: str
    email: str | None = None
    full_name: str | None = None
    disabled: bool | None = None

class UserInDB(User):
    hashed_password: str
EOF
    echo "✅ Created app/auth/models.py"
fi

# Create dependencies file
if [ ! -f "app/auth/dependencies.py" ]; then
    cat > app/auth/dependencies.py << 'EOF'
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from datetime import datetime, timezone
import os

from .models import TokenData, User, UserInDB

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")

# Mock database - replace with real database
fake_users_db = {
    "johndoe": {
        "username": "johndoe",
        "full_name": "John Doe",
        "email": "johndoe@example.com",
        "hashed_password": "$argon2id$v=19$m=65536,t=3,p=4$...",  # Replace with real hash
        "disabled": False,
    }
}

def get_user(db, username: str):
    if username in db:
        user_dict = db[username]
        return UserInDB(**user_dict)

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception

    user = get_user(fake_users_db, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user
EOF
    echo "✅ Created app/auth/dependencies.py"
fi

# Create utils file
if [ ! -f "app/auth/utils.py" ]; then
    cat > app/auth/utils.py << 'EOF'
from datetime import datetime, timedelta, timezone
from jose import jwt
from pwdlib import PasswordHash
import os

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))

password_hash = PasswordHash.recommended()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return password_hash.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password using Argon2."""
    return password_hash.hash(password)

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """Create a JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
EOF
    echo "✅ Created app/auth/utils.py"
fi

echo ""
echo "✅ JWT Authentication setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Replace fake_users_db in app/auth/dependencies.py with real database"
echo "2. Update hashed passwords using: from app.auth.utils import get_password_hash"
echo "3. Create login endpoint in your main.py (see templates/jwt_auth.py)"
echo "4. Protect routes with: current_user: User = Depends(get_current_active_user)"
echo ""
echo "🔒 Your SECRET_KEY has been saved to .env (keep it secret!)"
