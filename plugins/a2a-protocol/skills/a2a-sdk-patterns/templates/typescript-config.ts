// A2A Protocol TypeScript Configuration Example
// IMPORTANT: Never hardcode API keys - always use environment variables

import { A2AClient } from '@a2a/protocol';

// Load environment variables
const API_KEY = process.env.A2A_API_KEY;
const BASE_URL = process.env.A2A_BASE_URL || 'https://api.a2a.example.com';
const TIMEOUT = parseInt(process.env.A2A_TIMEOUT || '30000');
const RETRY_ATTEMPTS = parseInt(process.env.A2A_RETRY_ATTEMPTS || '3');
const LOG_LEVEL = process.env.A2A_LOG_LEVEL || 'info';

// Validate required environment variables
if (!API_KEY) {
    throw new Error('A2A_API_KEY environment variable is required');
}

// Initialize client
const client = new A2AClient({
    apiKey: API_KEY,
    baseUrl: BASE_URL,
    timeout: TIMEOUT,
    retryAttempts: RETRY_ATTEMPTS,
    logLevel: LOG_LEVEL as 'debug' | 'info' | 'warn' | 'error',
});

// Example: Multi-environment configuration
interface EnvironmentConfig {
    apiKey: string;
    baseUrl: string;
    timeout?: number;
    retryAttempts?: number;
}

class Config {
    private env: string;
    private config: EnvironmentConfig;

    constructor(env: 'development' | 'staging' | 'production' = 'production') {
        this.env = env;
        this.config = this.loadConfig();
    }

    private loadConfig(): EnvironmentConfig {
        let apiKey: string | undefined;
        let baseUrl: string | undefined;

        switch (this.env) {
            case 'development':
                apiKey = process.env.A2A_DEV_API_KEY;
                baseUrl = process.env.A2A_DEV_BASE_URL;
                break;
            case 'staging':
                apiKey = process.env.A2A_STAGING_API_KEY;
                baseUrl = process.env.A2A_STAGING_BASE_URL;
                break;
            default: // production
                apiKey = process.env.A2A_PROD_API_KEY;
                baseUrl = process.env.A2A_PROD_BASE_URL;
        }

        if (!apiKey) {
            throw new Error(`API key not set for ${this.env} environment`);
        }

        if (!baseUrl) {
            throw new Error(`Base URL not set for ${this.env} environment`);
        }

        return {
            apiKey,
            baseUrl,
            timeout: TIMEOUT,
            retryAttempts: RETRY_ATTEMPTS,
        };
    }

    createClient(): A2AClient {
        return new A2AClient(this.config);
    }
}

// Usage:
// const config = new Config('development');
// const client = config.createClient();

export { client, Config };
