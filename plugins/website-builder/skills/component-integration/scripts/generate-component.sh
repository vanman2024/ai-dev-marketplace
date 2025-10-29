#!/bin/bash
# generate-component.sh - Scaffold new React components

set -e

# Parse arguments
COMPONENT_NAME="$1"
COMPONENT_TYPE="${2:-basic}"

if [ -z "$COMPONENT_NAME" ]; then
  echo "Usage: bash generate-component.sh <ComponentName> [type]"
  echo ""
  echo "Types:"
  echo "  basic       - Simple functional component (default)"
  echo "  interactive - Component with state and event handlers"
  echo "  form        - Form component with validation"
  echo "  island      - Component optimized for Astro islands"
  echo "  data        - Component with data fetching"
  echo ""
  echo "Example:"
  echo "  bash generate-component.sh Button interactive"
  exit 1
fi

# Remove --type= prefix if present
COMPONENT_TYPE="${COMPONENT_TYPE#--type=}"

echo "🚀 Generating $COMPONENT_TYPE component: $COMPONENT_NAME"

# Create components directory if it doesn't exist
COMPONENTS_DIR="src/components/react"
mkdir -p "$COMPONENTS_DIR"

# Component file path
COMPONENT_FILE="$COMPONENTS_DIR/$COMPONENT_NAME.tsx"

# Check if component already exists
if [ -f "$COMPONENT_FILE" ]; then
  echo "❌ Error: Component $COMPONENT_NAME already exists"
  echo "   Location: $COMPONENT_FILE"
  exit 1
fi

# Generate component based on type
case "$COMPONENT_TYPE" in
  basic)
    cat > "$COMPONENT_FILE" << 'EOF'
interface Props {
  children?: React.ReactNode;
  className?: string;
}

export default function COMPONENT_NAME({ children, className = '' }: Props) {
  return (
    <div className={className}>
      {children}
    </div>
  );
}
EOF
    ;;

  interactive)
    cat > "$COMPONENT_FILE" << 'EOF'
import { useState } from 'react';

interface Props {
  initialValue?: string;
  onValueChange?: (value: string) => void;
}

export default function COMPONENT_NAME({
  initialValue = '',
  onValueChange
}: Props) {
  const [value, setValue] = useState(initialValue);

  const handleChange = (newValue: string) => {
    setValue(newValue);
    onValueChange?.(newValue);
  };

  return (
    <div className="interactive-component">
      <p>Current value: {value}</p>
      <button
        onClick={() => handleChange('Updated!')}
        className="btn btn-primary"
      >
        Update Value
      </button>
    </div>
  );
}
EOF
    ;;

  form)
    cat > "$COMPONENT_FILE" << 'EOF'
import { useState, type FormEvent } from 'react';

interface FormData {
  name: string;
  email: string;
}

interface Props {
  onSubmit?: (data: FormData) => void;
}

export default function COMPONENT_NAME({ onSubmit }: Props) {
  const [formData, setFormData] = useState<FormData>({
    name: '',
    email: '',
  });
  const [errors, setErrors] = useState<Partial<FormData>>({});

  const validate = (): boolean => {
    const newErrors: Partial<FormData> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();

    if (validate()) {
      onSubmit?.(formData);
      // Reset form
      setFormData({ name: '', email: '' });
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="name" className="block text-sm font-medium">
          Name
        </label>
        <input
          type="text"
          id="name"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          className="mt-1 block w-full rounded-md border-gray-300"
        />
        {errors.name && (
          <p className="mt-1 text-sm text-red-600">{errors.name}</p>
        )}
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium">
          Email
        </label>
        <input
          type="email"
          id="email"
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          className="mt-1 block w-full rounded-md border-gray-300"
        />
        {errors.email && (
          <p className="mt-1 text-sm text-red-600">{errors.email}</p>
        )}
      </div>

      <button type="submit" className="btn btn-primary">
        Submit
      </button>
    </form>
  );
}
EOF
    ;;

  island)
    cat > "$COMPONENT_FILE" << 'EOF'
import { useState, useEffect } from 'react';

interface Props {
  title?: string;
}

/**
 * Optimized for Astro islands architecture
 * Use with client:visible or client:idle for best performance
 */
export default function COMPONENT_NAME({ title = 'Interactive Island' }: Props) {
  const [isClient, setIsClient] = useState(false);
  const [count, setCount] = useState(0);

  useEffect(() => {
    setIsClient(true);
  }, []);

  if (!isClient) {
    return (
      <div className="island-skeleton">
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="card">
      <h3 className="text-xl font-bold">{title}</h3>
      <p className="mt-2">Count: {count}</p>
      <button
        onClick={() => setCount(count + 1)}
        className="mt-4 btn btn-primary"
      >
        Increment
      </button>
    </div>
  );
}
EOF
    ;;

  data)
    cat > "$COMPONENT_FILE" << 'EOF'
import { useState, useEffect } from 'react';

interface DataItem {
  id: number;
  name: string;
}

interface Props {
  apiUrl?: string;
}

export default function COMPONENT_NAME({ apiUrl = '/api/data' }: Props) {
  const [data, setData] = useState<DataItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchData();
  }, [apiUrl]);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(apiUrl);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch data');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-center p-4">Loading...</div>;
  }

  if (error) {
    return (
      <div className="text-red-600 p-4">
        <p>Error: {error}</p>
        <button onClick={fetchData} className="mt-2 btn btn-secondary">
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <h3 className="text-xl font-bold">Data List</h3>
      <ul className="divide-y">
        {data.map((item) => (
          <li key={item.id} className="py-2">
            {item.name}
          </li>
        ))}
      </ul>
      <button onClick={fetchData} className="btn btn-primary">
        Refresh
      </button>
    </div>
  );
}
EOF
    ;;

  *)
    echo "❌ Error: Unknown component type: $COMPONENT_TYPE"
    echo "   Valid types: basic, interactive, form, island, data"
    exit 1
    ;;
esac

# Replace COMPONENT_NAME placeholder
sed -i "s/COMPONENT_NAME/$COMPONENT_NAME/g" "$COMPONENT_FILE"

echo "✅ Component created: $COMPONENT_FILE"
echo ""
echo "📝 Usage in Astro file:"
echo ""
echo "---"
echo "import $COMPONENT_NAME from '@/components/react/$COMPONENT_NAME';"
echo "---"
echo ""
echo "<$COMPONENT_NAME client:visible />"
echo ""
echo "💡 Client directives:"
echo "   - client:load     = Hydrate on page load (use sparingly)"
echo "   - client:visible  = Hydrate when visible in viewport"
echo "   - client:idle     = Hydrate when browser is idle"
echo "   - client:media    = Hydrate based on media query"
