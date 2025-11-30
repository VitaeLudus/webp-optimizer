#!/bin/bash

# webp-multi-size-advanced.sh
# Advanced multi-size WebP generator with custom widths and quality per size
# Naming convention: largest size = name.webp, others = name-WIDTHxHEIGHT.webp

show_usage() {
    echo "Usage: $0 input_image.jpg [options]"
    echo ""
    echo "Options:"
    echo "  -o, --output NAME     Output basename (default: input filename)"
    echo "  -w, --widths W1,W2... Comma-separated widths (default: 2560,1920,1280,960,640)"
    echo "  -q, --quality NUM     Quality 0-100 (default: 82)"
    echo "  -m, --method NUM      Compression method 0-6 (default: 6)"
    echo "  -d, --dir DIR         Output directory (default: current)"
    echo "  --thumb-quality NUM   Quality for smallest size (default: same as -q)"
    echo "  -h, --help            Show this help"
    echo ""
    echo "Naming convention:"
    echo "  Largest size:  name.webp"
    echo "  Other sizes:   name-WIDTHxHEIGHT.webp"
    echo ""
    echo "Examples:"
    echo "  $0 photo.jpg"
    echo "    → photo.webp, photo-1920x1080.webp, photo-1280x720.webp, etc."
    echo ""
    echo "  $0 eg-apartments-concierge.png"
    echo "    → eg-apartments-concierge.webp, eg-apartments-concierge-1920x1080.webp, etc."
    echo ""
    echo "  $0 photo.jpg -o hero -w 2560,1920,1280,960,640"
    echo "  $0 photo.jpg -q 85 -m 6 --thumb-quality 75"
    echo "  $0 photo.jpg -o product -d ./images/webp"
}

# Default values
INPUT=""
OUTPUT_BASENAME=""
WIDTHS="2560,1920,1440,1024,768,320"
QUALITY=70
METHOD=6
OUTPUT_DIR="./output/"
THUMB_QUALITY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_BASENAME="$2"
            shift 2
            ;;
        -w|--widths)
            WIDTHS="$2"
            shift 2
            ;;
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -d|--dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --thumb-quality)
            THUMB_QUALITY="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$INPUT" ]; then
                INPUT="$1"
            else
                echo "Error: Unknown option $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate input
if [ -z "$INPUT" ]; then
    echo "Error: No input file specified"
    show_usage
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: File '$INPUT' not found"
    exit 1
fi

# Set default output basename if not specified
if [ -z "$OUTPUT_BASENAME" ]; then
    OUTPUT_BASENAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')
fi

# Set thumb quality to main quality if not specified
if [ -z "$THUMB_QUALITY" ]; then
    THUMB_QUALITY=$QUALITY
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Convert comma-separated widths to array
IFS=',' read -ra WIDTH_ARRAY <<< "$WIDTHS"

# Get the largest width (first in array)
LARGEST_WIDTH=${WIDTH_ARRAY[0]}

# Function to get image dimensions
get_image_dimensions() {
    local file="$1"
    # Try to get dimensions using identify (ImageMagick) or file command
    if command -v identify &> /dev/null; then
        identify -format "%w %h" "$file" 2>/dev/null
    else
        # Fallback: try with file command (less reliable)
        file "$file" | grep -oP '\d+\s*x\s*\d+' | head -1 | tr 'x' ' ' | tr -d ' '
    fi
}

# Get original image dimensions
ORIG_DIMENSIONS=$(get_image_dimensions "$INPUT")
if [ -n "$ORIG_DIMENSIONS" ]; then
    ORIG_WIDTH=$(echo $ORIG_DIMENSIONS | awk '{print $1}')
    ORIG_HEIGHT=$(echo $ORIG_DIMENSIONS | awk '{print $2}')
    echo "Original dimensions: ${ORIG_WIDTH}x${ORIG_HEIGHT}"
else
    echo "Warning: Could not detect original dimensions. Dimension suffixes may be inaccurate."
    ORIG_WIDTH=2560
    ORIG_HEIGHT=1440
fi

# Function to calculate proportional height
calculate_height() {
    local width=$1
    local height=$(awk "BEGIN {printf \"%.0f\", $width * $ORIG_HEIGHT / $ORIG_WIDTH}")
    echo $height
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           WebP Multi-Size Generator                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Input:          $INPUT"
echo "Output prefix:  $OUTPUT_BASENAME"
echo "Output dir:     $OUTPUT_DIR"
echo "Widths:         ${WIDTH_ARRAY[@]}"
echo "Quality:        $QUALITY (main) / $THUMB_QUALITY (smallest)"
echo "Method:         $METHOD"
echo ""
echo "─────────────────────────────────────────────────────────────"
echo ""

# Get total number of widths
TOTAL=${#WIDTH_ARRAY[@]}
CURRENT=0

# Get the smallest width for special quality treatment
SMALLEST_WIDTH=${WIDTH_ARRAY[-1]}

for WIDTH in "${WIDTH_ARRAY[@]}"; do
    CURRENT=$((CURRENT + 1))
    
    # Calculate proportional height
    HEIGHT=$(calculate_height $WIDTH)
    
    # Determine output filename based on naming convention
    # Largest size: name.webp
    # All others: name-WIDTHxHEIGHT.webp
    if [ "$WIDTH" -eq "$LARGEST_WIDTH" ]; then
        OUTPUT="$OUTPUT_DIR/${OUTPUT_BASENAME}.webp"
        SIZE_LABEL="${WIDTH}px (original size)"
    else
        OUTPUT="$OUTPUT_DIR/${OUTPUT_BASENAME}-${WIDTH}x${HEIGHT}.webp"
        SIZE_LABEL="${WIDTH}x${HEIGHT}px"
    fi
    
    # Use thumb quality for smallest size, main quality for others
    if [ "$WIDTH" -eq "$SMALLEST_WIDTH" ]; then
        CURRENT_QUALITY=$THUMB_QUALITY
    else
        CURRENT_QUALITY=$QUALITY
    fi
    
    echo "[$CURRENT/$TOTAL] Generating $SIZE_LABEL (q=$CURRENT_QUALITY)"
    
    cwebp -q $CURRENT_QUALITY -m $METHOD -mt -resize $WIDTH 0 "$INPUT" -o "$OUTPUT" 2>&1 | grep -v "^Saving"
    
    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$OUTPUT" | cut -f1)
        echo "  ✓ $(basename "$OUTPUT")"
        echo "    Size: $SIZE"
    else
        echo "  ✗ Failed to create $OUTPUT"
    fi
    echo ""
done

echo "─────────────────────────────────────────────────────────────"
echo "Complete! Generated $TOTAL WebP files in $OUTPUT_DIR"
echo ""

# Summary table - show both the main file and dimensioned files
echo "Summary:"
if [ -f "$OUTPUT_DIR/${OUTPUT_BASENAME}.webp" ]; then
    ls -lh "$OUTPUT_DIR/${OUTPUT_BASENAME}.webp" 2>/dev/null | awk '{print "  " $9 " - " $5}'
fi
ls -lh "$OUTPUT_DIR/${OUTPUT_BASENAME}"-*.webp 2>/dev/null | awk '{print "  " $9 " - " $5}'