#!/usr/bin/env bash

# Create Next.js API route for ElevenLabs transcription
# Supports both App Router (app/) and Pages Router (pages/)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Create Next.js API route for ElevenLabs transcription

OPTIONS:
    -h, --help              Show this help message
    --app-router            Create App Router route (default if app/ exists)
    --pages-router          Create Pages Router route
    --route-name NAME       Route name (default: transcribe)
    --force                 Overwrite existing route

EXAMPLES:
    $0                                    # Auto-detect router
    $0 --app-router                       # Force App Router
    $0 --pages-router --route-name audio  # Pages Router with custom name

EOF
    exit 1
}

detect_router() {
    if [ -d "app" ]; then
        echo "app"
    elif [ -d "pages" ]; then
        echo "pages"
    else
        log_error "Neither app/ nor pages/ directory found"
        log_info "This script must be run from a Next.js project root"
        exit 1
    fi
}

create_app_router_route() {
    local route_name="$1"
    local force="$2"
    local route_dir="app/api/$route_name"
    local route_file="$route_dir/route.ts"

    log_info "Creating App Router route: $route_file"

    if [ -f "$route_file" ] && [ "$force" != "true" ]; then
        log_error "Route already exists: $route_file"
        log_info "Use --force to overwrite"
        return 1
    fi

    mkdir -p "$route_dir"

    cat > "$route_file" << 'EOF'
import { experimental_transcribe as transcribe } from 'ai';
import { elevenlabs } from '@ai-sdk/elevenlabs';
import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs'; // or 'edge' for edge runtime

export async function POST(request: NextRequest) {
  try {
    // Parse form data
    const formData = await request.formData();
    const audioFile = formData.get('audio') as File | null;

    if (!audioFile) {
      return NextResponse.json(
        { error: 'No audio file provided' },
        { status: 400 }
      );
    }

    // Validate file type
    const validTypes = [
      'audio/mpeg',
      'audio/wav',
      'audio/flac',
      'audio/m4a',
      'audio/ogg',
    ];

    if (!validTypes.includes(audioFile.type)) {
      return NextResponse.json(
        {
          error: `Invalid file type: ${audioFile.type}`,
          validTypes,
        },
        { status: 400 }
      );
    }

    // Validate file size (max 100MB)
    const maxSize = 100 * 1024 * 1024; // 100MB
    if (audioFile.size > maxSize) {
      return NextResponse.json(
        {
          error: `File too large: ${audioFile.size} bytes (max ${maxSize} bytes)`,
        },
        { status: 400 }
      );
    }

    // Convert File to Buffer
    const arrayBuffer = await audioFile.arrayBuffer();
    const audioBuffer = Buffer.from(arrayBuffer);

    // Optional: Get configuration from query params or form data
    const language = formData.get('language') as string | null;
    const speakers = formData.get('speakers') as string | null;
    const timestamps = formData.get('timestamps') === 'true';

    // Build transcription options
    const providerOptions: any = {};

    if (language) {
      providerOptions.languageCode = language;
    }

    if (speakers) {
      providerOptions.numSpeakers = parseInt(speakers, 10);
      providerOptions.diarize = true;
    }

    if (timestamps) {
      providerOptions.timestampsGranularity = 'word';
    }

    const startTime = Date.now();

    // Transcribe audio
    const result = await transcribe({
      model: elevenlabs.transcription('scribe_v1'),
      audio: audioBuffer,
      ...(Object.keys(providerOptions).length > 0 && {
        providerOptions: { elevenlabs: providerOptions },
      }),
    });

    const processingTime = Date.now() - startTime;

    // Return transcription result
    return NextResponse.json({
      success: true,
      text: result.text,
      language: result.language,
      durationInSeconds: result.durationInSeconds,
      segments: result.segments,
      metadata: {
        fileName: audioFile.name,
        fileSize: audioFile.size,
        fileType: audioFile.type,
        processingTimeMs: processingTime,
      },
    });
  } catch (error) {
    console.error('Transcription error:', error);

    if (error instanceof Error) {
      return NextResponse.json(
        {
          success: false,
          error: error.message,
          type: error.name,
        },
        { status: 500 }
      );
    }

    return NextResponse.json(
      {
        success: false,
        error: 'Unknown error occurred',
      },
      { status: 500 }
    );
  }
}

// Optional: GET endpoint for health check
export async function GET() {
  return NextResponse.json({
    status: 'ok',
    provider: 'elevenlabs',
    model: 'scribe_v1',
  });
}
EOF

    log_success "Created App Router route: $route_file"
    return 0
}

create_pages_router_route() {
    local route_name="$1"
    local force="$2"
    local route_dir="pages/api"
    local route_file="$route_dir/$route_name.ts"

    log_info "Creating Pages Router route: $route_file"

    if [ -f "$route_file" ] && [ "$force" != "true" ]; then
        log_error "Route already exists: $route_file"
        log_info "Use --force to overwrite"
        return 1
    fi

    mkdir -p "$route_dir"

    cat > "$route_file" << 'EOF'
import { experimental_transcribe as transcribe } from 'ai';
import { elevenlabs } from '@ai-sdk/elevenlabs';
import type { NextApiRequest, NextApiResponse } from 'next';
import formidable from 'formidable';
import fs from 'fs/promises';

// Disable body parser to handle multipart/form-data
export const config = {
  api: {
    bodyParser: false,
  },
};

type TranscriptionResponse = {
  success: boolean;
  text?: string;
  language?: string;
  durationInSeconds?: number;
  segments?: any[];
  metadata?: {
    fileName: string;
    fileSize: number;
    fileType: string;
    processingTimeMs: number;
  };
  error?: string;
  type?: string;
};

async function parseForm(req: NextApiRequest): Promise<{
  fields: formidable.Fields;
  files: formidable.Files;
}> {
  const form = formidable({
    maxFileSize: 100 * 1024 * 1024, // 100MB
    keepExtensions: true,
  });

  return new Promise((resolve, reject) => {
    form.parse(req, (err, fields, files) => {
      if (err) reject(err);
      else resolve({ fields, files });
    });
  });
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<TranscriptionResponse>
) {
  if (req.method !== 'POST') {
    return res.status(405).json({
      success: false,
      error: 'Method not allowed',
    });
  }

  try {
    // Parse form data
    const { fields, files } = await parseForm(req);

    const audioFile = Array.isArray(files.audio) ? files.audio[0] : files.audio;

    if (!audioFile) {
      return res.status(400).json({
        success: false,
        error: 'No audio file provided',
      });
    }

    // Read file
    const audioBuffer = await fs.readFile(audioFile.filepath);

    // Optional: Get configuration from fields
    const language = Array.isArray(fields.language)
      ? fields.language[0]
      : fields.language;

    const speakersStr = Array.isArray(fields.speakers)
      ? fields.speakers[0]
      : fields.speakers;

    const timestampsStr = Array.isArray(fields.timestamps)
      ? fields.timestamps[0]
      : fields.timestamps;

    // Build transcription options
    const providerOptions: any = {};

    if (language) {
      providerOptions.languageCode = language;
    }

    if (speakersStr) {
      providerOptions.numSpeakers = parseInt(speakersStr, 10);
      providerOptions.diarize = true;
    }

    if (timestampsStr === 'true') {
      providerOptions.timestampsGranularity = 'word';
    }

    const startTime = Date.now();

    // Transcribe audio
    const result = await transcribe({
      model: elevenlabs.transcription('scribe_v1'),
      audio: audioBuffer,
      ...(Object.keys(providerOptions).length > 0 && {
        providerOptions: { elevenlabs: providerOptions },
      }),
    });

    const processingTime = Date.now() - startTime;

    // Clean up temp file
    await fs.unlink(audioFile.filepath);

    // Return transcription result
    return res.status(200).json({
      success: true,
      text: result.text,
      language: result.language,
      durationInSeconds: result.durationInSeconds,
      segments: result.segments,
      metadata: {
        fileName: audioFile.originalFilename || 'unknown',
        fileSize: audioFile.size,
        fileType: audioFile.mimetype || 'unknown',
        processingTimeMs: processingTime,
      },
    });
  } catch (error) {
    console.error('Transcription error:', error);

    if (error instanceof Error) {
      return res.status(500).json({
        success: false,
        error: error.message,
        type: error.name,
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Unknown error occurred',
    });
  }
}
EOF

    log_success "Created Pages Router route: $route_file"
    log_info "Note: Pages Router requires 'formidable' package"
    log_info "Install it with: npm install formidable @types/formidable"
    return 0
}

create_config_file() {
    local config_file="next.config.js"

    if [ -f "$config_file" ]; then
        log_info "next.config.js already exists"
        log_warning "Please ensure API body size limits are configured:"
        echo "  api: {"
        echo "    bodyParser: {"
        echo "      sizeLimit: '100mb',"
        echo "    },"
        echo "  },"
        return 0
    fi

    log_info "Creating next.config.js with API configuration..."

    cat > "$config_file" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  api: {
    bodyParser: {
      sizeLimit: '100mb',
    },
  },
};

module.exports = nextConfig;
EOF

    log_success "Created next.config.js"
}

main() {
    local router=""
    local route_name="transcribe"
    local force=false

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            --app-router)
                router="app"
                shift
                ;;
            --pages-router)
                router="pages"
                shift
                ;;
            --route-name)
                route_name="$2"
                shift 2
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                ;;
        esac
    done

    log_info "Creating Next.js API route for ElevenLabs transcription"
    echo

    # Auto-detect router if not specified
    if [ -z "$router" ]; then
        router=$(detect_router)
        log_info "Detected router: $router"
    fi

    echo

    # Create route based on router type
    case "$router" in
        app)
            create_app_router_route "$route_name" "$force"
            ;;
        pages)
            create_pages_router_route "$route_name" "$force"
            ;;
        *)
            log_error "Invalid router type: $router"
            exit 1
            ;;
    esac

    echo

    # Create config file
    create_config_file

    echo

    # Success message
    log_success "API route created successfully!"
    echo
    log_info "Next steps:"
    echo "  1. Ensure ELEVENLABS_API_KEY is set in .env.local"
    echo "  2. Start your Next.js dev server: npm run dev"
    echo "  3. Test the endpoint:"

    if [ "$router" = "app" ]; then
        echo "     curl -X POST http://localhost:3000/api/$route_name \\"
        echo "          -F 'audio=@/path/to/audio.mp3'"
    else
        echo "     curl -X POST http://localhost:3000/api/$route_name \\"
        echo "          -F 'audio=@/path/to/audio.mp3'"
        echo
        log_info "Don't forget to install formidable:"
        echo "     npm install formidable @types/formidable"
    fi

    echo
}

# Run main function
main "$@"
