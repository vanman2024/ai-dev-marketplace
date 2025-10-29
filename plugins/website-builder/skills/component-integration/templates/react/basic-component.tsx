/**
 * Basic React Component Template
 *
 * A simple functional component with TypeScript props.
 * Use this as a starting point for static or simple components.
 */

interface ${COMPONENT_NAME}Props {
  /** Child elements to render inside the component */
  children?: React.ReactNode;
  /** Additional CSS classes to apply */
  className?: string;
  /** Optional title text */
  title?: string;
}

export default function ${COMPONENT_NAME}({
  children,
  className = '',
  title,
}: ${COMPONENT_NAME}Props) {
  return (
    <div className={`component-container ${className}`.trim()}>
      {title && <h2 className="text-2xl font-bold mb-4">{title}</h2>}
      {children}
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
 * <${COMPONENT_NAME} title="Hello World">
 *   <p>Content goes here</p>
 * </${COMPONENT_NAME}>
 *
 * Note: This component doesn't need hydration unless it has interactivity.
 * For static content, omit the client:* directive.
 */
