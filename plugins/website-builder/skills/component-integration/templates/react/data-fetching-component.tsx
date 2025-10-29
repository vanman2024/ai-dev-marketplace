/**
 * Data Fetching Component Template
 *
 * Component that fetches and displays async data with
 * loading, error, and success states.
 */

import { useState, useEffect } from 'react';

interface DataItem {
  id: number | string;
  title: string;
  description?: string;
}

interface ${COMPONENT_NAME}Props {
  /** API endpoint URL */
  apiUrl: string;
  /** Optional custom headers */
  headers?: Record<string, string>;
  /** Refresh interval in milliseconds (0 = no auto-refresh) */
  refreshInterval?: number;
  /** Custom render function for each item */
  renderItem?: (item: DataItem) => React.ReactNode;
}

export default function ${COMPONENT_NAME}({
  apiUrl,
  headers = {},
  refreshInterval = 0,
  renderItem,
}: ${COMPONENT_NAME}Props) {
  const [data, setData] = useState<DataItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  /**
   * Fetch data from API
   */
  const fetchData = async () => {
    try {
      setError(null);

      const response = await fetch(apiUrl, {
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();

      // Handle both array responses and paginated responses
      const items = Array.isArray(result) ? result : result.data || result.items || [];
      setData(items);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch data';
      setError(errorMessage);
      console.error('Data fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  /**
   * Initial data fetch
   */
  useEffect(() => {
    fetchData();
  }, [apiUrl]);

  /**
   * Auto-refresh if interval is set
   */
  useEffect(() => {
    if (refreshInterval > 0) {
      const intervalId = setInterval(fetchData, refreshInterval);
      return () => clearInterval(intervalId);
    }
  }, [refreshInterval, apiUrl]);

  /**
   * Default item renderer
   */
  const defaultRenderItem = (item: DataItem) => (
    <div key={item.id} className="p-4 border border-gray-200 rounded-md hover:border-primary-300 transition-colors">
      <h3 className="text-lg font-semibold mb-2">{item.title}</h3>
      {item.description && (
        <p className="text-gray-600">{item.description}</p>
      )}
    </div>
  );

  // Loading State
  if (loading) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-center p-8">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600" />
          <span className="ml-4 text-gray-600">Loading data...</span>
        </div>
        {/* Skeleton loaders */}
        {[1, 2, 3].map((i) => (
          <div key={i} className="p-4 border border-gray-200 rounded-md animate-pulse">
            <div className="h-6 bg-gray-200 rounded w-3/4 mb-2" />
            <div className="h-4 bg-gray-200 rounded w-full" />
          </div>
        ))}
      </div>
    );
  }

  // Error State
  if (error) {
    return (
      <div className="p-6 bg-red-50 border border-red-200 rounded-md">
        <div className="flex items-start">
          <svg
            className="h-6 w-6 text-red-600 mt-0.5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div className="ml-3 flex-1">
            <h3 className="text-sm font-medium text-red-800">
              Error loading data
            </h3>
            <p className="mt-2 text-sm text-red-700">{error}</p>
            <button
              onClick={fetchData}
              className="mt-4 btn btn-secondary text-sm"
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Empty State
  if (data.length === 0) {
    return (
      <div className="p-8 text-center">
        <svg
          className="mx-auto h-12 w-12 text-gray-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
          />
        </svg>
        <h3 className="mt-2 text-sm font-medium text-gray-900">No data</h3>
        <p className="mt-1 text-sm text-gray-500">
          No items found at this endpoint.
        </p>
        <button onClick={fetchData} className="mt-4 btn btn-primary">
          Refresh
        </button>
      </div>
    );
  }

  // Success State with Data
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold">
          Data ({data.length} items)
        </h2>
        <button
          onClick={fetchData}
          className="btn btn-secondary text-sm"
          aria-label="Refresh data"
        >
          🔄 Refresh
        </button>
      </div>

      <div className="space-y-3">
        {data.map((item) =>
          renderItem ? renderItem(item) : defaultRenderItem(item)
        )}
      </div>
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
 *   apiUrl="/api/items"
 *   refreshInterval={30000}
 *   renderItem={(item) => (
 *     <div>
 *       <h3>{item.title}</h3>
 *       <p>{item.description}</p>
 *     </div>
 *   )}
 * />
 *
 * Tips:
 * - Use client:visible for data below the fold
 * - Use client:load for critical data
 * - Set refreshInterval to 0 to disable auto-refresh
 * - Provide custom renderItem for complex layouts
 */
