/**
 * Form Component Template with Validation
 *
 * Complete form component with validation, error handling,
 * and TypeScript type safety.
 */

import { useState, type FormEvent, type ChangeEvent } from 'react';

interface ${COMPONENT_NAME}FormData {
  name: string;
  email: string;
  message: string;
}

interface ${COMPONENT_NAME}Props {
  /** Callback when form is successfully submitted */
  onSubmit?: (data: ${COMPONENT_NAME}FormData) => void | Promise<void>;
  /** Submit button text */
  submitText?: string;
  /** Show success message after submission */
  showSuccessMessage?: boolean;
}

type ValidationErrors = Partial<Record<keyof ${COMPONENT_NAME}FormData, string>>;

export default function ${COMPONENT_NAME}({
  onSubmit,
  submitText = 'Submit',
  showSuccessMessage = true,
}: ${COMPONENT_NAME}Props) {
  const [formData, setFormData] = useState<${COMPONENT_NAME}FormData>({
    name: '',
    email: '',
    message: '',
  });

  const [errors, setErrors] = useState<ValidationErrors>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  /**
   * Validate form data
   */
  const validate = (): boolean => {
    const newErrors: ValidationErrors = {};

    // Name validation
    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    } else if (formData.name.trim().length < 2) {
      newErrors.name = 'Name must be at least 2 characters';
    }

    // Email validation
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    // Message validation
    if (!formData.message.trim()) {
      newErrors.message = 'Message is required';
    } else if (formData.message.trim().length < 10) {
      newErrors.message = 'Message must be at least 10 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  /**
   * Handle input change
   */
  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));

    // Clear error for this field when user types
    if (errors[name as keyof ${COMPONENT_NAME}FormData]) {
      setErrors((prev) => ({ ...prev, [name]: undefined }));
    }
  };

  /**
   * Handle form submission
   */
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSubmitSuccess(false);

    // Validate form
    if (!validate()) {
      return;
    }

    // Submit form
    setIsSubmitting(true);
    try {
      await onSubmit?.(formData);

      // Reset form on success
      setFormData({ name: '', email: '', message: '' });
      if (showSuccessMessage) {
        setSubmitSuccess(true);
        setTimeout(() => setSubmitSuccess(false), 5000);
      }
    } catch (error) {
      setErrors({
        message: error instanceof Error ? error.message : 'Submission failed',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-md">
      {/* Success Message */}
      {submitSuccess && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-md text-green-800">
          Form submitted successfully!
        </div>
      )}

      {/* Name Field */}
      <div>
        <label htmlFor="name" className="block text-sm font-medium mb-2">
          Name <span className="text-red-500">*</span>
        </label>
        <input
          type="text"
          id="name"
          name="name"
          value={formData.name}
          onChange={handleChange}
          className={`w-full px-4 py-2 border rounded-md focus:ring-2 focus:ring-primary-500 ${
            errors.name ? 'border-red-500' : 'border-gray-300'
          }`}
          aria-invalid={!!errors.name}
          aria-describedby={errors.name ? 'name-error' : undefined}
        />
        {errors.name && (
          <p id="name-error" className="mt-1 text-sm text-red-600">
            {errors.name}
          </p>
        )}
      </div>

      {/* Email Field */}
      <div>
        <label htmlFor="email" className="block text-sm font-medium mb-2">
          Email <span className="text-red-500">*</span>
        </label>
        <input
          type="email"
          id="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          className={`w-full px-4 py-2 border rounded-md focus:ring-2 focus:ring-primary-500 ${
            errors.email ? 'border-red-500' : 'border-gray-300'
          }`}
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? 'email-error' : undefined}
        />
        {errors.email && (
          <p id="email-error" className="mt-1 text-sm text-red-600">
            {errors.email}
          </p>
        )}
      </div>

      {/* Message Field */}
      <div>
        <label htmlFor="message" className="block text-sm font-medium mb-2">
          Message <span className="text-red-500">*</span>
        </label>
        <textarea
          id="message"
          name="message"
          value={formData.message}
          onChange={handleChange}
          rows={4}
          className={`w-full px-4 py-2 border rounded-md focus:ring-2 focus:ring-primary-500 ${
            errors.message ? 'border-red-500' : 'border-gray-300'
          }`}
          aria-invalid={!!errors.message}
          aria-describedby={errors.message ? 'message-error' : undefined}
        />
        {errors.message && (
          <p id="message-error" className="mt-1 text-sm text-red-600">
            {errors.message}
          </p>
        )}
      </div>

      {/* Submit Button */}
      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full btn btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isSubmitting ? 'Submitting...' : submitText}
      </button>
    </form>
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
 *   client:load
 *   onSubmit={(data) => {
 *     console.log('Form submitted:', data);
 *     // Handle form submission (e.g., API call)
 *   }}
 *   submitText="Send Message"
 * />
 */
