#!/usr/bin/env node
/**
 * ElevenLabs Streaming TTS Client Example
 *
 * Demonstrates real-time text-to-speech streaming with:
 * - WebSocket connection management
 * - Audio buffering and playback
 * - Error handling and reconnection
 * - Performance monitoring
 */

const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

// Configuration
const config = {
    voiceId: process.env.VOICE_ID || '',
    apiKey: process.env.ELEVENLABS_API_KEY || '',
    model: 'eleven_flash_v2_5',
    outputFormat: 'mp3_44100_128',
    optimizeLatency: 3,
    voiceSettings: {
        stability: 0.5,
        similarity_boost: 0.75,
        style: 0.0,
        use_speaker_boost: true
    },
    outputFile: 'streaming-output.mp3',
    enableMonitoring: true
};

// Metrics tracking
const metrics = {
    startTime: 0,
    firstChunkTime: 0,
    totalChunks: 0,
    totalBytes: 0,
    errors: 0
};

// Audio buffer
const audioChunks = [];
let outputStream = null;

/**
 * Create WebSocket connection
 */
function createConnection() {
    const url = `wss://api.elevenlabs.io/v1/text-to-speech/${config.voiceId}/stream-input?model_id=${config.model}&output_format=${config.outputFormat}`;

    console.log('Connecting to ElevenLabs streaming API...');
    const ws = new WebSocket(url, {
        headers: {
            'xi-api-key': config.apiKey
        }
    });

    return ws;
}

/**
 * Initialize streaming session
 */
function initializeStream(ws, text) {
    // BOS (Beginning of Stream) message
    const bosMessage = {
        text: ' ',
        voice_settings: config.voiceSettings,
        generation_config: {
            chunk_length_schedule: [120, 160, 250, 290]
        },
        xi_api_key: config.apiKey
    };

    ws.send(JSON.stringify(bosMessage));

    // Send actual text
    const textMessage = {
        text: text,
        try_trigger_generation: true
    };

    ws.send(JSON.stringify(textMessage));

    // EOS (End of Stream) message
    const eosMessage = {
        text: ''
    };

    ws.send(JSON.stringify(eosMessage));
}

/**
 * Handle incoming messages
 */
function handleMessage(data) {
    if (typeof data === 'string') {
        // JSON message (metadata or error)
        try {
            const message = JSON.parse(data);

            if (message.error) {
                console.error('❌ Generation error:', message.error);
                metrics.errors++;
                return;
            }

            if (message.audio) {
                console.log('✓ Audio generation complete');
                return;
            }

            if (message.isFinal) {
                console.log('✓ Stream finalized');
                return;
            }

            if (config.enableMonitoring) {
                console.log('📊 Message:', JSON.stringify(message).substring(0, 100));
            }
        } catch (e) {
            console.error('Failed to parse message:', e.message);
        }
    } else {
        // Binary audio chunk
        if (metrics.totalChunks === 0) {
            metrics.firstChunkTime = Date.now() - metrics.startTime;
            console.log(`⚡ First chunk received in ${metrics.firstChunkTime}ms`);
        }

        metrics.totalChunks++;
        metrics.totalBytes += data.length;

        // Save audio chunk
        audioChunks.push(data);

        if (outputStream) {
            outputStream.write(data);
        }

        if (config.enableMonitoring && metrics.totalChunks % 10 === 0) {
            console.log(`📦 Received ${metrics.totalChunks} chunks (${(metrics.totalBytes / 1024).toFixed(2)} KB)`);
        }
    }
}

/**
 * Save audio to file
 */
function saveAudio() {
    if (audioChunks.length === 0) {
        console.log('⚠️  No audio chunks received');
        return;
    }

    const totalLength = audioChunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const audioBuffer = Buffer.concat(audioChunks, totalLength);

    fs.writeFileSync(config.outputFile, audioBuffer);
    console.log(`💾 Saved audio to ${config.outputFile}`);
    console.log(`   Size: ${(totalLength / 1024).toFixed(2)} KB`);
}

/**
 * Print metrics summary
 */
function printMetrics() {
    if (!config.enableMonitoring) return;

    const duration = Date.now() - metrics.startTime;

    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('📊 Streaming Metrics');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log(`First chunk latency:  ${metrics.firstChunkTime}ms`);
    console.log(`Total duration:       ${duration}ms`);
    console.log(`Total chunks:         ${metrics.totalChunks}`);
    console.log(`Total data:           ${(metrics.totalBytes / 1024).toFixed(2)} KB`);
    console.log(`Average chunk size:   ${(metrics.totalBytes / metrics.totalChunks).toFixed(0)} bytes`);
    console.log(`Errors:              ${metrics.errors}`);
    console.log('═══════════════════════════════════════════════════════════════\n');
}

/**
 * Main streaming function
 */
async function streamTTS(text, options = {}) {
    // Merge options with config
    Object.assign(config, options);

    // Validate configuration
    if (!config.apiKey) {
        console.error('❌ Error: ELEVENLABS_API_KEY not set');
        console.log('Set it with: export ELEVENLABS_API_KEY="your-api-key"');
        process.exit(1);
    }

    if (!config.voiceId) {
        console.error('❌ Error: VOICE_ID not set');
        console.log('Use: --voice-id YOUR_VOICE_ID');
        process.exit(1);
    }

    if (!text || text.trim().length === 0) {
        console.error('❌ Error: No text provided');
        process.exit(1);
    }

    // Create output stream
    outputStream = fs.createWriteStream(config.outputFile);

    // Reset metrics
    metrics.startTime = Date.now();
    metrics.firstChunkTime = 0;
    metrics.totalChunks = 0;
    metrics.totalBytes = 0;
    metrics.errors = 0;

    console.log('\n🎙️  Starting ElevenLabs Streaming TTS');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log(`Text:         ${text.substring(0, 80)}${text.length > 80 ? '...' : ''}`);
    console.log(`Voice ID:     ${config.voiceId}`);
    console.log(`Model:        ${config.model}`);
    console.log(`Output:       ${config.outputFile}`);
    console.log('═══════════════════════════════════════════════════════════════\n');

    return new Promise((resolve, reject) => {
        const ws = createConnection();

        ws.on('open', () => {
            console.log('✓ WebSocket connection established');
            initializeStream(ws, text);
        });

        ws.on('message', (data) => {
            handleMessage(data);
        });

        ws.on('error', (error) => {
            console.error('❌ WebSocket error:', error.message);
            metrics.errors++;
            reject(error);
        });

        ws.on('close', (code, reason) => {
            console.log(`\n✓ Connection closed: ${code}${reason ? ' - ' + reason : ''}`);

            if (outputStream) {
                outputStream.end();
            }

            saveAudio();
            printMetrics();
            resolve();
        });
    });
}

/**
 * CLI interface
 */
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {};
    let text = '';

    for (let i = 0; i < args.length; i++) {
        switch (args[i]) {
            case '--voice-id':
                options.voiceId = args[++i];
                break;
            case '--text':
                text = args[++i];
                break;
            case '--model':
                options.model = args[++i];
                break;
            case '--output':
                options.outputFile = args[++i];
                break;
            case '--optimize-latency':
                options.optimizeLatency = parseInt(args[++i]);
                break;
            case '--stability':
                options.voiceSettings = options.voiceSettings || {};
                options.voiceSettings.stability = parseFloat(args[++i]);
                break;
            case '--similarity-boost':
                options.voiceSettings = options.voiceSettings || {};
                options.voiceSettings.similarity_boost = parseFloat(args[++i]);
                break;
            case '--no-monitoring':
                options.enableMonitoring = false;
                break;
            case '--help':
                showUsage();
                process.exit(0);
                break;
            default:
                if (!args[i].startsWith('--') && !text) {
                    text = args[i];
                }
                break;
        }
    }

    return { text, options };
}

function showUsage() {
    console.log(`
ElevenLabs Streaming TTS Client

Usage:
    node client-example.js --voice-id ID --text "TEXT" [OPTIONS]

Required:
    --voice-id ID          Voice ID to use
    --text TEXT           Text to convert to speech

Options:
    --model MODEL         Model (default: eleven_flash_v2_5)
    --output FILE         Output file (default: streaming-output.mp3)
    --optimize-latency N  Latency optimization 0-4 (default: 3)
    --stability VALUE     Stability 0.0-1.0 (default: 0.5)
    --similarity-boost N  Similarity boost 0.0-1.0 (default: 0.75)
    --no-monitoring      Disable verbose monitoring
    --help               Show this help

Environment Variables:
    ELEVENLABS_API_KEY    Your ElevenLabs API key (required)
    VOICE_ID             Default voice ID

Examples:
    # Basic streaming
    node client-example.js --voice-id abc123 --text "Hello world"

    # Maximum latency optimization
    node client-example.js --voice-id abc123 --text "Real-time chat" --optimize-latency 4

    # Custom settings
    node client-example.js --voice-id abc123 --text "Your text" --stability 0.7 --output custom.mp3
`);
}

// Run if called directly
if (require.main === module) {
    const { text, options } = parseArgs();

    if (!text) {
        console.error('❌ Error: No text provided');
        showUsage();
        process.exit(1);
    }

    streamTTS(text, options)
        .then(() => {
            console.log('✓ Streaming complete');
            process.exit(0);
        })
        .catch((error) => {
            console.error('❌ Streaming failed:', error.message);
            process.exit(1);
        });
}

// Export for use as module
module.exports = { streamTTS };
