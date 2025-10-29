/**
 * Interactive React Component Template
 *
 * Component with state management and event handlers.
 * Requires hydration in Astro (use client:* directive).
 */

import { useState, useEffect } from 'react';

interface ${COMPONENT_NAME}Props {
  /** Initial value for the component state */
  initialValue?: string;
  /** Callback when value changes */
  onValueChange?: (value: string) => void;
  /** Optional label text */
  label?: string;
}

export default function ${COMPONENT_NAME}({
  initialValue = '',
  onValueChange,
  label = 'Value',
}: ${COMPONENT_NAME}Props) {
  const [value, setValue] = useState(initialValue);
  const [isClient, setIsClient] = useState(false);

  // Set isClient flag after mount (handles SSR)
  useEffect(() => {
    setIsClient(true);
  }, []);

  const handleChange = (newValue: string) => {
    setValue(newValue);
    onValueChange?.(newValue);
  };

  const handleClick = () => {
    handleChange(value === 'active' ? 'inactive' : 'active');
  };

  // Optional: Show loading state during hydration
  if (!isClient) {
    return (
      <div className="animate-pulse bg-gray-200 h-20 rounded-md" />
    );
  }

  return (
    <div className="space-y-4 p-4 border rounded-lg">
      <div className="flex items-center justify-between">
        <span className="font-medium">{label}:</span>
        <span className="text-primary-600">{value}</span>
      </div>

      <button
        onClick={handleClick}
        className="btn btn-primary w-full"
      >
        Toggle State
      </button>

      <input
        type="text"
        value={value}
        onChange={(e) => handleChange(e.target.value)}
        className="w-full px-3 py-2 border rounded-md"
        placeholder="Enter value..."
      />
    </div>
  );
}

/**
 * Usage in Astro:
 *
 * ---
 * import ${COMPONENT_NAME} from '@/components/react/${COMPONENT_NAME}';
 * ---
 *
 * <${COMPONENT_NAME}
 *   client:visible
 *   initialValue="inactive"
 *   onValueChange={(val) => console.log(val)}
 *   label="Status"
 * />
 *
 * Client directives:
 * - client:load = Hydrate immediately on page load
 * - client:visible = Hydrate when component becomes visible
 * - client:idle = Hydrate when browser is idle
 */
