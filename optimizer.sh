#!/bin/bash

# =============================================================================
# WebP Image Converter with Responsive Sizes
# =============================================================================
# Converts PNG, JPG, HEIC to WebP with multiple responsive widths
# Crops from center to match specified aspect ratio
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration (edit these defaults as needed)
# -----------------------------------------------------------------------------
DEFAULT_QUALITY=75
DEFAULT_WIDTHS="2560,1920,1440,1024,768,320"
DEFAULT_PRESET="photo"
OUTPUT_DIR="./output"

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") -i <input_file> -r <aspect_ratio> [options]

Required:
  -i, --input       Input image file (PNG, JPG, JPEG, HEIC)
  -r, --ratio       Aspect ratio: 16:9, 4:3, or 1:1

Options:
  -q, --quality     WebP quality (0-100, default: $DEFAULT_QUALITY)
  -w, --widths      Comma-separated widths (default: $DEFAULT_WIDTHS)
  -p, --preset      Image type preset (default: $DEFAULT_PRESET)
                    Options: photo, picture, drawing, icon, text
  -o, --output      Output directory (default: $OUTPUT_DIR)
  -h, --help        Show this help message

Presets optimize compression for different image types:
  photo    - Outdoor photographs, natural lighting (recommended for most)
  picture  - Digital pictures, portraits, indoor shots  
  drawing  - Line art, high-contrast illustrations
  icon     - Small colorful images, logos
  text     - Text-heavy images, screenshots

Examples:
  $(basename "$0") -i photo.jpg -r 16:9
  $(basename "$0") -i hero.png -r 4:3 -q 70 -p photo
  $(basename "$0") -i banner.heic -r 16:9 -w "1920,1440,1024,768" -p picture

EOF
    exit 1
}

# -----------------------------------------------------------------------------
# Check dependencies
# -----------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    
    if ! command -v magick &> /dev/null; then
        missing+=("ImageMagick v7 (magick)")
    fi
    
    if ! command -v cwebp &> /dev/null; then
        missing+=("cwebp")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Error: Missing required dependencies:"
        printf '  - %s\n' "${missing[@]}"
        echo ""
        echo "Install on macOS:  brew install imagemagick webp"
        echo "Install on Ubuntu: sudo apt install imagemagick webp"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Get cwebp arguments based on preset
# Based on compress-or-die.com techniques and ImageMagick recommendations
# -----------------------------------------------------------------------------
get_cwebp_preset_args() {
    local preset=$1
    local quality=$2
    
    # Common high-quality settings:
    # -m 6: Maximum compression effort
    # -sharp_yuv: Better RGB->YUV conversion (preserves edges/colors)
    # -pass 6: Multi-pass encoding for better compression
    # -af: Auto-filter optimization
    
    case $preset in
        "photo")
            # Outdoor photographs, natural lighting
            # -sns 80: Strong spatial noise shaping
            # -f 30: Moderate deblocking
            # -pre 2: Pseudo-random dithering (helps gradients)
            echo "-q $quality -m 6 -sharp_yuv -pass 6 -af -sns 80 -f 30 -sharpness 3 -pre 2"
            ;;
        "picture")
            # Digital pictures, portraits, indoor shots
            # -sns 80: Strong spatial noise shaping  
            # -f 35: Slightly stronger deblocking
            # -sharpness 4: Less sharp filtering
            echo "-q $quality -m 6 -sharp_yuv -pass 6 -af -sns 80 -f 35 -sharpness 4"
            ;;
        "drawing")
            # Line art, high-contrast illustrations
            # -sns 25: Low spatial noise shaping (preserve edges)
            # -f 10: Minimal deblocking (preserve sharp lines)
            # -sharpness 6: Preserve fine details
            echo "-q $quality -m 6 -sharp_yuv -pass 6 -sns 25 -f 10 -sharpness 6"
            ;;
        "icon")
            # Small colorful images, logos
            # Minimal processing to preserve sharp colors
            echo "-q $quality -m 6 -sharp_yuv -pass 6 -sns 0 -f 0"
            ;;
        "text")
            # Text-heavy images, screenshots
            # -segments 2: Better for uniform areas
            echo "-q $quality -m 6 -sharp_yuv -pass 6 -sns 0 -f 0 -segments 2"
            ;;
        *)
            echo "Error: Invalid preset '$preset'" >&2
            exit 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Calculate height from width and aspect ratio
# -----------------------------------------------------------------------------
calculate_height() {
    local width=$1
    local ratio=$2
    
    case $ratio in
        "16:9")
            echo $(( width * 9 / 16 ))
            ;;
        "4:3")
            echo $(( width * 3 / 4 ))
            ;;
        "1:1")
            echo $width
            ;;
        *)
            echo "Error: Invalid aspect ratio '$ratio'. Use 16:9, 4:3, or 1:1" >&2
            exit 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Main conversion function
# -----------------------------------------------------------------------------
convert_image() {
    local input_file="$1"
    local aspect_ratio="$2"
    local quality="$3"
    local widths_str="$4"
    local output_dir="$5"
    local preset="$6"
    
    # Validate input file
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found"
        exit 1
    fi
    
    # Get base filename without extension
    local basename=$(basename "$input_file")
    local name="${basename%.*}"
    
    # Get source image dimensions
    local source_width=$(magick identify -format "%w" "$input_file" 2>/dev/null)
    local source_height=$(magick identify -format "%h" "$input_file" 2>/dev/null)
    
    if [ -z "$source_width" ] || [ -z "$source_height" ]; then
        echo "Error: Could not read image dimensions from '$input_file'"
        exit 1
    fi
    
    # Get cwebp arguments for this preset
    local cwebp_args=$(get_cwebp_preset_args "$preset" "$quality")
    
    # Detect source type for logging
    local input_ext="${input_file##*.}"
    input_ext=$(echo "$input_ext" | tr '[:upper:]' '[:lower:]')
    local source_type="standard"
    if [[ "$input_ext" == "heic" || "$input_ext" == "heif" ]]; then
        source_type="HEIC (lossy source - denoise enabled)"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Source: $input_file (${source_width}x${source_height})"
    echo "Type: $source_type"
    echo "Aspect ratio: $aspect_ratio | Quality: $quality | Preset: $preset"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Parse widths into array and sort descending
    IFS=',' read -ra width_array <<< "$widths_str"
    IFS=$'\n' sorted_widths=($(sort -rn <<< "${width_array[*]}")); unset IFS
    
    local is_first=true
    local generated_count=0
    
    for width in "${sorted_widths[@]}"; do
        # Skip if width is larger than source
        if [ "$width" -gt "$source_width" ]; then
            echo "⏭  Skipping ${width}px (larger than source)"
            continue
        fi
        
        # Calculate target height
        local height=$(calculate_height "$width" "$aspect_ratio")
        
        # Determine output filename
        local output_file
        if [ "$is_first" = true ]; then
            output_file="${output_dir}/${name}.webp"
            is_first=false
        else
            output_file="${output_dir}/${name}-${width}x${height}.webp"
        fi
        
        # Create temporary resized file
        local temp_file=$(mktemp /tmp/webp_convert_XXXXXX.png)
        
        # Detect if source is HEIC (already lossy - needs different handling)
        local input_ext="${input_file##*.}"
        input_ext=$(echo "$input_ext" | tr '[:upper:]' '[:lower:]')
        
        if [[ "$input_ext" == "heic" || "$input_ext" == "heif" ]]; then
            # HEIC-specific pipeline:
            # 1. Convert to sRGB color space (HEIC often uses P3)
            # 2. Strip metadata to reduce processing overhead
            # 3. Apply subtle denoise to reduce HEIC compression artifacts
            # 4. Resize and crop
            # 5. Light unsharp to restore edges after denoise
            magick "$input_file" \
                -colorspace sRGB \
                -strip \
                -resize "${width}x${height}^" \
                -gravity center \
                -extent "${width}x${height}" \
                -enhance \
                -unsharp 0.5x0.5+0.6+0.008 \
                "$temp_file"
        else
            # PNG/JPG pipeline:
            # -resize: scales to fill target dimensions (minimum coverage)
            # -gravity center -extent: crops to exact dimensions from center
            # -unsharp: subtle edge sharpening to counteract chroma subsampling blur
            #           (compress-or-die technique: sharpen color edges)
            magick "$input_file" \
                -strip \
                -resize "${width}x${height}^" \
                -gravity center \
                -extent "${width}x${height}" \
                -unsharp 0.5x0.5+0.5+0.008 \
                "$temp_file"
        fi
        
        # Convert to WebP with preset-optimized compression
        # shellcheck disable=SC2086
        cwebp $cwebp_args "$temp_file" -o "$output_file" 2>/dev/null
        
        # Get file size
        local file_size=$(du -h "$output_file" | cut -f1)
        
        echo "✓  Created: $(basename "$output_file") (${width}x${height}) - ${file_size}"
        
        # Cleanup temp file
        rm -f "$temp_file"
        
        ((generated_count++))
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Generated $generated_count files in $output_dir/"
    echo ""
}

# -----------------------------------------------------------------------------
# Parse arguments
# -----------------------------------------------------------------------------
INPUT_FILE=""
ASPECT_RATIO=""
QUALITY="$DEFAULT_QUALITY"
WIDTHS="$DEFAULT_WIDTHS"
PRESET="$DEFAULT_PRESET"

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_FILE="$2"
            shift 2
            ;;
        -r|--ratio)
            ASPECT_RATIO="$2"
            shift 2
            ;;
        -q|--quality)
            QUALITY="$2"
            shift 2
            ;;
        -w|--widths)
            WIDTHS="$2"
            shift 2
            ;;
        -p|--preset)
            PRESET="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Input file is required (-i)"
    echo ""
    usage
fi

if [ -z "$ASPECT_RATIO" ]; then
    echo "Error: Aspect ratio is required (-r)"
    echo ""
    usage
fi

# Run
check_dependencies
convert_image "$INPUT_FILE" "$ASPECT_RATIO" "$QUALITY" "$WIDTHS" "$OUTPUT_DIR" "$PRESET"