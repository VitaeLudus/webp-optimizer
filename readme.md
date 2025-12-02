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