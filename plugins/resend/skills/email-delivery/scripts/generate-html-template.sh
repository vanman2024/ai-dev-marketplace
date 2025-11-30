#!/bin/bash

# Generate HTML email template with responsive design
# Usage: generate-html-template.sh <template_type> <output_file>

set -e

TEMPLATE_TYPE=${1:-basic}
OUTPUT_FILE=${2:-email-template.html}

# Function to generate basic template
generate_basic_template() {
    cat > "$1" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Template</title>
    <style>
        * { margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: #f5f5f5;
            line-height: 1.6;
            color: #333;
        }
        .container {
            background-color: #ffffff;
            max-width: 600px;
            margin: 20px auto;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 20px;
            text-align: center;
        }
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        .content {
            padding: 40px 20px;
        }
        .content h2 {
            font-size: 20px;
            color: #333;
            margin-bottom: 15px;
        }
        .content p {
            margin-bottom: 15px;
            font-size: 14px;
        }
        .button {
            display: inline-block;
            background-color: #667eea;
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 4px;
            margin: 20px 0;
            font-weight: bold;
        }
        .button:hover {
            background-color: #764ba2;
        }
        .footer {
            background-color: #f9f9f9;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #999;
            border-top: 1px solid #eee;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
        @media (max-width: 600px) {
            .container {
                margin: 0;
                border-radius: 0;
            }
            .header {
                padding: 30px 15px;
            }
            .header h1 {
                font-size: 22px;
            }
            .content {
                padding: 20px 15px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome!</h1>
            <p>Email Template</p>
        </div>
        <div class="content">
            <h2>Hello {{firstName}},</h2>
            <p>This is a responsive email template that works across all clients.</p>

            <p>Key features:</p>
            <ul>
                <li>Responsive design</li>
                <li>Mobile-friendly</li>
                <li>Cross-client compatible</li>
                <li>Easy to customize</li>
            </ul>

            <a href="{{actionUrl}}" class="button">Take Action</a>

            <p>If you have questions, feel free to reach out to our support team.</p>
        </div>
        <div class="footer">
            <p>&copy; 2024 Example Inc. All rights reserved.</p>
            <p>
                <a href="{{unsubscribeUrl}}">Unsubscribe</a> |
                <a href="{{preferencesUrl}}">Update Preferences</a>
            </p>
        </div>
    </div>
</body>
</html>
EOF
}

# Function to generate transactional template
generate_transactional_template() {
    cat > "$1" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{subject}}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: white;
        }
        .header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
        }
        .status {
            background-color: #27ae60;
            color: white;
            padding: 15px;
            text-align: center;
            font-weight: bold;
        }
        .details {
            padding: 20px;
            border-bottom: 1px solid #eee;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            font-size: 14px;
        }
        .detail-label {
            font-weight: bold;
            color: #2c3e50;
        }
        .detail-value {
            color: #555;
        }
        .actions {
            padding: 20px;
            text-align: center;
        }
        .action-button {
            display: inline-block;
            background-color: #2c3e50;
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 4px;
            margin: 10px 5px;
            font-weight: bold;
        }
        .action-button:hover {
            background-color: #34495e;
        }
        .footer {
            background-color: #f9f9f9;
            padding: 15px;
            text-align: center;
            font-size: 12px;
            color: #999;
        }
        .footer a {
            color: #2c3e50;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{subject}}</h1>
        </div>

        <div class="status">
            ✓ {{status}}
        </div>

        <div class="details">
            <div class="detail-row">
                <span class="detail-label">Reference:</span>
                <span class="detail-value">{{reference}}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Date:</span>
                <span class="detail-value">{{date}}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Amount:</span>
                <span class="detail-value">{{amount}}</span>
            </div>
        </div>

        <div class="actions">
            <a href="{{detailsUrl}}" class="action-button">View Details</a>
            <a href="{{supportUrl}}" class="action-button">Get Help</a>
        </div>

        <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
            <p>
                <a href="{{contactUrl}}">Contact Support</a> |
                <a href="{{privacyUrl}}">Privacy Policy</a>
            </p>
        </div>
    </div>
</body>
</html>
EOF
}

# Function to generate marketing template
generate_marketing_template() {
    cat > "$1" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{subject}}</title>
    <style>
        body {
            font-family: 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: white;
        }
        .hero {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 20px;
            text-align: center;
        }
        .hero h1 {
            font-size: 32px;
            margin: 0 0 10px 0;
        }
        .hero p {
            font-size: 16px;
            margin: 0;
        }
        .section {
            padding: 30px 20px;
            border-bottom: 1px solid #eee;
        }
        .section h2 {
            font-size: 20px;
            color: #333;
            margin: 0 0 15px 0;
        }
        .features {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        .feature {
            flex: 1;
            min-width: 200px;
        }
        .feature h3 {
            color: #667eea;
            margin: 0 0 10px 0;
        }
        .feature p {
            font-size: 14px;
            color: #555;
            margin: 0;
        }
        .cta {
            text-align: center;
            padding: 30px 20px;
            background-color: #f9f9f9;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 40px;
            text-decoration: none;
            border-radius: 4px;
            font-weight: bold;
            font-size: 16px;
        }
        .social {
            text-align: center;
            padding: 20px;
        }
        .social a {
            display: inline-block;
            width: 40px;
            height: 40px;
            background-color: #667eea;
            color: white;
            text-align: center;
            line-height: 40px;
            border-radius: 50%;
            margin: 0 5px;
            text-decoration: none;
        }
        .footer {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
            font-size: 12px;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="hero">
            <h1>{{headline}}</h1>
            <p>{{subheadline}}</p>
        </div>

        <div class="section">
            <h2>Featured</h2>
            <div class="features">
                <div class="feature">
                    <h3>Feature 1</h3>
                    <p>Description of first feature goes here.</p>
                </div>
                <div class="feature">
                    <h3>Feature 2</h3>
                    <p>Description of second feature goes here.</p>
                </div>
            </div>
        </div>

        <div class="cta">
            <a href="{{ctaUrl}}" class="cta-button">{{ctaText}}</a>
        </div>

        <div class="social">
            <a href="{{facebookUrl}}">f</a>
            <a href="{{twitterUrl}}">𝕏</a>
            <a href="{{linkedinUrl}}">in</a>
        </div>

        <div class="footer">
            <p>&copy; 2024 Example Inc. All rights reserved.</p>
            <p>
                <a href="{{unsubscribeUrl}}">Unsubscribe</a> |
                <a href="{{preferencesUrl}}">Preferences</a> |
                <a href="{{privacyUrl}}">Privacy</a>
            </p>
        </div>
    </div>
</body>
</html>
EOF
}

# Validate input
if [ -z "$TEMPLATE_TYPE" ]; then
    echo "Usage: generate-html-template.sh <template_type> [output_file]"
    echo ""
    echo "Template types:"
    echo "  basic           - Basic responsive template"
    echo "  transactional   - Transactional email (confirmation, receipt)"
    echo "  marketing       - Marketing/campaign email"
    echo ""
    echo "Output file: $OUTPUT_FILE (default: email-template.html)"
    exit 1
fi

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Generate template based on type
case "$TEMPLATE_TYPE" in
    basic)
        generate_basic_template "$OUTPUT_FILE"
        echo "Generated basic template: $OUTPUT_FILE"
        ;;
    transactional)
        generate_transactional_template "$OUTPUT_FILE"
        echo "Generated transactional template: $OUTPUT_FILE"
        ;;
    marketing)
        generate_marketing_template "$OUTPUT_FILE"
        echo "Generated marketing template: $OUTPUT_FILE"
        ;;
    *)
        echo "Unknown template type: $TEMPLATE_TYPE"
        echo "Valid types: basic, transactional, marketing"
        exit 1
        ;;
esac

echo "Template variables to replace:"
echo "  {{firstName}}     - Recipient first name"
echo "  {{subject}}       - Email subject"
echo "  {{status}}        - Operation status"
echo "  {{actionUrl}}     - Primary action URL"
echo "  {{date}}          - Date string"
echo "  {{amount}}        - Amount/price"
echo "  {{headline}}      - Campaign headline"
echo "  {{subheadline}}   - Campaign subheadline"
echo "  {{ctaText}}       - Call-to-action button text"
echo "  {{ctaUrl}}        - Call-to-action URL"
