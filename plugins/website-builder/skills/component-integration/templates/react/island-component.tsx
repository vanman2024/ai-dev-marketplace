/**
 * Astro Island Component Template
 *
 * Optimized React component for Astro's islands architecture.
 * Minimizes bundle size and handles SSR gracefully.
 */

import { useState, useEffect, useCallback } from 'react';

interface ${COMPONENT_NAME}Props {
  /** Component title */
  title?: string;
  /** Initial count value */
  initialCount?: number;
  /** Maximum count value */
  maxCount?: number;
}

/**
 * Performance-optimized island component
 * - Uses lazy state initialization
 * - Memoizes callbacks
 * - Handles SSR/CSR gracefully
 * - Minimal bundle size
 */
export default function ${COMPONENT_NAME}({
  title = 'Interactive Island',
  initialCount = 0,
  maxCount = 100,
}: ${COMPONENT_NAME}Props) {
  // Lazy state initialization
  const [count, setCount] = useState(() => initialCount);
  const [mounted, setMounted] = useState(false);

  // Handle client-side mount
  useEffect(() => {
    setMounted(true);
  }, []);

  // Memoized callbacks for performance
  const increment = useCallback(() => {
    setCount((prev) => Math.min(prev + 1, maxCount));
  }, [maxCount]);

  const decrement = useCallback(() => {
    setCount((prev) => Math.max(prev - 1, 0));
  }, []);

  const reset = useCallback(() => {
    setCount(initialCount);
  }, [initialCount]);

  // Show skeleton during SSR
  if (!mounted) {
    return (
      <div className="card animate-pulse">
        <div className="h-8 bg-gray-200 rounded mb-4 w-3/4" />
        <div className="h-12 bg-gray-200 rounded mb-4" />
        <div className="h-10 bg-gray-200 rounded" />
      </div>
    );
  }

  return (
    <div className="card max-w-md">
      <h3 className="text-xl font-bold mb-4">{title}</h3>

      <div className="text-center mb-6">
        <div className="text-5xl font-bold text-primary-600 mb-2">
          {count}
        </div>
        <div className="text-sm text-gray-600">
          of {maxCount}
        </div>
      </div>

      <div className="flex gap-2">
        <button
          onClick={decrement}
          disabled={count === 0}
          className="btn btn-secondary flex-1"
          aria-label="Decrement count"
        >
          -
        </button>

        <button
          onClick={reset}
          className="btn btn-secondary"
          aria-label="Reset count"
        >
          Reset
        </button>

        <button
          onClick={increment}
          disabled={count >= maxCount}
          className="btn btn-primary flex-1"
          aria-label="Increment count"
        >
          +
        </button>
      </div>

      <div className="mt-4 text-xs text-gray-500">
        This component only loads JavaScript when visible
      </div>
    </div>
  );
}

/**
 * Usage in Astro (Optimized):
 *
 * ---
 * import ${COMPONENT_NAME} from '@/components/react/${COMPONENT_NAME}';
 * ---
 *
 * <!-- Only hydrate when visible (best for below-fold content) -->
 * <${COMPONENT_NAME}
 *   client:visible
 *   title="Counter Island"
 *   initialCount={0}
 *   maxCount={50}
 * />
 *
 * Performance tips:
 * 1. Use client:visible for below-the-fold components
 * 2. Use client:idle for non-critical interactions
 * 3. Only use client:load for above-the-fold critical elements
 * 4. Consider client:media for responsive components
 */
