# Common SDK Configuration Issues and Fixes

## Issue 1: SDK Dependency Not Found

### Symptoms
```
❌ ERROR: @claude-ai/sdk not found in dependencies
```

### Fix (TypeScript)
```bash
npm install @claude-ai/sdk --save
```

### Fix (Python)
```bash
pip install claude-ai-sdk
# or add to requirements.txt:
echo "claude-ai-sdk>=1.0.0" >> requirements.txt
pip install -r requirements.txt
```

---

## Issue 2: Missing ANTHROPIC_API_KEY

### Symptoms
```
❌ ERROR: ANTHROPIC_API_KEY not found in .env
Error: API key not configured
```

### Fix
1. Get your API key from https://console.anthropic.com/settings/keys
2. Create/update .env file:
```bash
echo "ANTHROPIC_API_KEY=sk-ant-api03-..." > .env
```
3. Add .env to .gitignore:
```bash
echo ".env" >> .gitignore
```

---

## Issue 3: TypeScript Module Resolution Issues

### Symptoms
```
Error: Cannot find module '@claude-ai/sdk'
Module not found: Can't resolve '@claude-ai/sdk'
```

### Fix
Update tsconfig.json:
```json
{
  "compilerOptions": {
    "moduleResolution": "node",
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true
  }
}
```

Then rebuild:
```bash
npm run build
```

---

## Issue 4: Python Import Errors

### Symptoms
```
ModuleNotFoundError: No module named 'claude_sdk'
ImportError: cannot import name 'ClaudeAgent'
```

### Fix
1. Verify virtual environment is activated:
```bash
source venv/bin/activate  # Linux/Mac
# or
.\venv\Scripts\activate  # Windows
```

2. Reinstall SDK:
```bash
pip install --upgrade claude-ai-sdk
```

3. Check Python path:
```bash
python -c "import sys; print('\n'.join(sys.path))"
```

---

## Issue 5: Node Version Incompatibility

### Symptoms
```
❌ ERROR: Node.js 18+ required, found v16.14.0
```

### Fix
1. Using nvm (recommended):
```bash
nvm install 20
nvm use 20
```

2. Or download from https://nodejs.org/

3. Verify:
```bash
node --version  # Should show v18.0.0 or higher
```

---

## Issue 6: .env File Security

### Symptoms
```
❌ ERROR: .env not in .gitignore - SECURITY RISK!
```

### Fix
```bash
echo ".env" >> .gitignore
git rm --cached .env  # If already committed
git commit -m "Remove .env from version control"
```

---

## Issue 7: SDK Version Mismatch

### Symptoms
```
⚠️  WARNING: SDK version may be outdated
TypeError: agent.initialize is not a function
```

### Fix (TypeScript)
```bash
npm install @claude-ai/sdk@latest
npm update
```

### Fix (Python)
```bash
pip install --upgrade claude-ai-sdk
```

---

## Issue 8: Missing Environment Template

### Symptoms
```
⚠️  WARNING: .env.example not found
```

### Fix
```bash
cp templates/.env.example.template .env.example
git add .env.example
```

---

## Validation Workflow

After applying any fix:

1. **Re-run validation**:
```bash
bash scripts/validate-typescript.sh .
# or
bash scripts/validate-python.sh .
```

2. **Test SDK initialization**:
```typescript
// TypeScript
import { ClaudeAgent } from '@claude-ai/sdk';
const agent = new ClaudeAgent();
console.log('SDK initialized successfully!');
```

```python
# Python
from claude_sdk import ClaudeAgent
agent = ClaudeAgent()
print("SDK initialized successfully!")
```

3. **Run project tests**:
```bash
npm test  # TypeScript
# or
pytest    # Python
```

---

## Prevention Checklist

Before starting a new SDK project:

- [ ] Copy .env.example.template to .env
- [ ] Set ANTHROPIC_API_KEY in .env
- [ ] Add .env to .gitignore
- [ ] Copy appropriate config (tsconfig-sdk.json or pyproject-sdk.toml)
- [ ] Install SDK dependency
- [ ] Run validation scripts
- [ ] Test with simple initialization code

---

## Getting Help

If validation issues persist:

1. Check SDK documentation: https://docs.anthropic.com/claude/docs
2. Review API status: https://status.anthropic.com/
3. Verify API key permissions in console: https://console.anthropic.com/
4. Check Node/Python versions match requirements
5. Review validation script output for specific error messages
