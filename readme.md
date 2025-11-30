# WebP Multi-Size Script

## Output Naming Format

### For input: `eg-apartments-concierge.png`

The script generates:
```
eg-apartments-concierge.webp           ← Largest size (2560px), no dimensions in name
eg-apartments-concierge-1920x1080.webp ← Other sizes include WIDTHxHEIGHT
eg-apartments-concierge-1280x720.webp
eg-apartments-concierge-960x540.webp
eg-apartments-concierge-640x360.webp
```

## Key Features

✅ **Automatic dimension detection** - Script reads your original image dimensions
✅ **Maintains aspect ratio** - All resized images keep the same proportions
✅ **Clean naming** - Largest size has no dimension suffix
✅ **Accurate dimensions** - Other sizes show exact WIDTHxHEIGHT in filename

## Usage Examples

### Basic Usage
```bash
./webp-multi-size-advanced.sh eg-apartments-concierge.png
```
Output:
- eg-apartments-concierge.webp (2560px)
- eg-apartments-concierge-1920x1080.webp
- eg-apartments-concierge-1280x720.webp
- eg-apartments-concierge-960x540.webp
- eg-apartments-concierge-640x360.webp

### Custom Output Name
```bash
./webp-multi-size-advanced.sh photo.jpg -o hero-image
```
Output:
- hero-image.webp (2560px)
- hero-image-1920x1080.webp
- hero-image-1280x720.webp
- etc.

### Custom Widths
```bash
./webp-multi-size-advanced.sh photo.jpg -w 3840,2560,1920,1280,640
```
Output:
- photo.webp (3840px)
- photo-2560x1440.webp
- photo-1920x1080.webp
- photo-1280x720.webp
- photo-640x360.webp

### Custom Output Directory
```bash
./webp-multi-size-advanced.sh photo.jpg -d ./output/images
```
All files saved to `./output/images/`

### Different Quality for Thumbnails
```bash
./webp-multi-size-advanced.sh photo.jpg -q 85 --thumb-quality 75
```
- Larger images: quality 85
- Smallest image (640px): quality 75

### All Options Combined
```bash
./webp-multi-size-advanced.sh eg-apartments-concierge.png \
    -o apartments-hero \
    -w 2560,1920,1280,960,640 \
    -q 82 \
    -m 6 \
    --thumb-quality 75 \
    -d ./output/webp
```

## Batch Processing

### Process all PNGs in current directory
```bash
for img in *.png; do
    ./webp-multi-size-advanced.sh "$img"
done
```

### Process with custom output directory
```bash
mkdir -p ./webp-output
for img in *.png *.jpg; do
    ./webp-multi-size-advanced.sh "$img" -d ./webp-output
done
```

### Process with custom quality settings
```bash
for img in *.jpg; do
    ./webp-multi-size-advanced.sh "$img" -q 85 --thumb-quality 75
done
```

## HTML Implementation

With this naming convention, your HTML becomes:

```html
<picture>
  <source type="image/webp" 
          srcset="eg-apartments-concierge-640x360.webp 640w,
                  eg-apartments-concierge-960x540.webp 960w,
                  eg-apartments-concierge-1280x720.webp 1280w,
                  eg-apartments-concierge-1920x1080.webp 1920w,
                  eg-apartments-concierge.webp 2560w"
          sizes="(max-width: 640px) 640px,
                 (max-width: 960px) 960px,
                 (max-width: 1280px) 1280px,
                 (max-width: 1920px) 1920px,
                 2560px">
  <img src="eg-apartments-concierge.webp" 
       alt="Apartments Concierge" 
       width="2560" 
       height="1440"
       loading="lazy">
</picture>
```

## Advantages of This Naming Convention

1. **SEO-friendly** - Main image has clean name without dimensions
2. **Descriptive** - Responsive versions clearly show their dimensions
3. **Easy to organize** - All versions grouped by name prefix
4. **Developer-friendly** - Easy to programmatically generate srcset attributes
5. **Future-proof** - Can add more sizes without breaking existing references

## Script Options Reference

| Option | Description | Default |
|--------|-------------|---------|
| `-o, --output` | Output basename | Input filename |
| `-w, --widths` | Comma-separated widths | 2560,1920,1280,960,640 |
| `-q, --quality` | Quality (0-100) | 82 |
| `-m, --method` | Compression method (0-6) | 6 |
| `-d, --dir` | Output directory | Current directory |
| `--thumb-quality` | Quality for smallest size | Same as `-q` |
| `-h, --help` | Show help message | - |

## Aspect Ratio Calculations

For a 2560x1440 source (16:9 aspect ratio):

| Width | Height | Calculation |
|-------|--------|-------------|
| 2560px | 1440px | Original |
| 1920px | 1080px | 1920 × (1440/2560) = 1080 |
| 1280px | 720px | 1280 × (1440/2560) = 720 |
| 960px | 540px | 960 × (1440/2560) = 540 |
| 640px | 360px | 640 × (1440/2560) = 360 |

The script automatically calculates these proportions from your source image!

## Troubleshooting

**Dimension detection fails:**
- Install ImageMagick: `sudo apt install imagemagick`
- Script will fall back to 2560x1440 assumption if detection fails

**Wrong aspect ratio:**
- Check your source image dimensions
- Script calculates from actual source, not target dimensions

**Files in wrong location:**
- Use `-d` flag to specify output directory
- Check permissions on output directory