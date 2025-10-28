'use client'

import { useState } from 'react'
import { generateUI, type Message } from './server-action-pattern'

/**
 * Client Wrapper Pattern for Generative UI
 *
 * This template demonstrates how to create client-side interactive
 * components that call server actions for UI generation.
 *
 * Usage:
 * 1. Import in Next.js App Router page
 * 2. Use as: <GenerativeUIClient />
 * 3. Customize for your use case
 */

interface GenerativeUIClientProps {
  initialMessages?: Message[]
  placeholder?: string
  context?: Record<string, any>
}

export default function GenerativeUIClient({
  initialMessages = [],
  placeholder = 'Ask AI to generate UI...',
  context
}: GenerativeUIClientProps) {
  const [messages, setMessages] = useState<Message[]>(initialMessages)
  const [input, setInput] = useState('')
  const [isGenerating, setIsGenerating] = useState(false)
  const [generatedUI, setGeneratedUI] = useState<React.ReactNode>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!input.trim() || isGenerating) return

    const userMessage: Message = {
      role: 'user',
      content: input
    }

    const newMessages = [...messages, userMessage]
    setMessages(newMessages)
    setInput('')
    setIsGenerating(true)

    try {
      // Call server action for UI generation
      const ui = await generateUI(newMessages, context)
      setGeneratedUI(ui)

      // Optionally add assistant response to message history
      setMessages([...newMessages, {
        role: 'assistant',
        content: '[UI Generated]'
      }])
    } catch (error) {
      console.error('Failed to generate UI:', error)
      setGeneratedUI(
        <div className="error">
          <p>Failed to generate UI. Please try again.</p>
        </div>
      )
    } finally {
      setIsGenerating(false)
    }
  }

  const handleClear = () => {
    setMessages([])
    setGeneratedUI(null)
    setInput('')
  }

  return (
    <div className="generative-ui-container">
      {/* Message History (optional) */}
      <div className="messages">
        {messages.map((msg, i) => (
          <div key={i} className={`message message-${msg.role}`}>
            <strong>{msg.role === 'user' ? 'You' : 'AI'}:</strong>
            <span>{msg.content}</span>
          </div>
        ))}
      </div>

      {/* Generated UI Display */}
      <div className="generated-ui">
        {isGenerating ? (
          <div className="loading">
            <div className="spinner" />
            <p>Generating UI...</p>
          </div>
        ) : generatedUI ? (
          <div className="ui-result">
            {generatedUI}
          </div>
        ) : (
          <div className="empty-state">
            <p>No UI generated yet. Enter a prompt to get started.</p>
          </div>
        )}
      </div>

      {/* Input Form */}
      <form onSubmit={handleSubmit} className="input-form">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder={placeholder}
          disabled={isGenerating}
          className="input"
        />
        <div className="button-group">
          <button
            type="submit"
            disabled={!input.trim() || isGenerating}
            className="button-primary"
          >
            {isGenerating ? 'Generating...' : 'Generate UI'}
          </button>
          <button
            type="button"
            onClick={handleClear}
            disabled={isGenerating || messages.length === 0}
            className="button-secondary"
          >
            Clear
          </button>
        </div>
      </form>

      <style jsx>{`
        .generative-ui-container {
          display: flex;
          flex-direction: column;
          gap: 1rem;
          max-width: 800px;
          margin: 0 auto;
          padding: 1rem;
        }

        .messages {
          display: flex;
          flex-direction: column;
          gap: 0.5rem;
          max-height: 200px;
          overflow-y: auto;
        }

        .message {
          padding: 0.5rem;
          border-radius: 0.25rem;
          background: #f5f5f5;
        }

        .message-user {
          background: #e3f2fd;
        }

        .message-assistant {
          background: #f1f8e9;
        }

        .generated-ui {
          min-height: 200px;
          padding: 1rem;
          border: 1px solid #e0e0e0;
          border-radius: 0.5rem;
          background: white;
        }

        .loading {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 1rem;
        }

        .spinner {
          width: 40px;
          height: 40px;
          border: 4px solid #f3f3f3;
          border-top: 4px solid #3498db;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }

        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }

        .empty-state {
          text-align: center;
          color: #999;
          padding: 2rem;
        }

        .input-form {
          display: flex;
          gap: 0.5rem;
          flex-direction: column;
        }

        .input {
          padding: 0.75rem;
          border: 1px solid #ddd;
          border-radius: 0.25rem;
          font-size: 1rem;
        }

        .button-group {
          display: flex;
          gap: 0.5rem;
        }

        .button-primary,
        .button-secondary {
          padding: 0.75rem 1.5rem;
          border: none;
          border-radius: 0.25rem;
          font-size: 1rem;
          cursor: pointer;
          transition: opacity 0.2s;
        }

        .button-primary {
          background: #3498db;
          color: white;
          flex: 1;
        }

        .button-secondary {
          background: #e0e0e0;
          color: #333;
        }

        .button-primary:disabled,
        .button-secondary:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        .button-primary:hover:not(:disabled) {
          opacity: 0.9;
        }

        .error {
          padding: 1rem;
          background: #ffebee;
          border-left: 4px solid #f44336;
          border-radius: 0.25rem;
          color: #c62828;
        }
      `}</style>
    </div>
  )
}
