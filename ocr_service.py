import cv2
import numpy as np
import pytesseract
from PIL import Image
import io
import os
import re

# For Windows - set Tesseract path
if os.name == 'nt':  # Windows
    possible_paths = [
        r'C:\Program Files\Tesseract-OCR\tesseract.exe',
        r'C:\Program Files (x86)\Tesseract-OCR\tesseract.exe',
    ]
    for path in possible_paths:
        if os.path.exists(path):
            pytesseract.pytesseract.tesseract_cmd = path
            print(f"Tesseract found at: {path}")
            break

def preprocess_image(image):
    """Advanced image preprocessing for better OCR accuracy"""
    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply bilateral filter to preserve edges while removing noise
    filtered = cv2.bilateralFilter(gray, 9, 75, 75)

    # Apply adaptive thresholding
    thresh = cv2.adaptiveThreshold(filtered, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                   cv2.THRESH_BINARY, 11, 2)

    # Denoise
    denoised = cv2.fastNlMeansDenoising(thresh, None, 30, 7, 21)

    # Enhance contrast
    enhanced = cv2.equalizeHist(denoised)

    return enhanced

def extract_text_from_image(image_bytes: bytes) -> str:
    """
    Extracts text from an image byte stream using advanced preprocessing.
    """
    try:
        # Convert image bytes to NumPy array
        nparr = np.frombuffer(image_bytes, np.uint8)

        # Decode image using OpenCV
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise ValueError("Could not decode image from bytes.")

        # Get image dimensions
        height, width = image.shape[:2]

        # Resize if too small
        if width < 800:
            scale = 800 / width
            new_width = int(width * scale)
            new_height = int(height * scale)
            image = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_CUBIC)

        # Preprocess the image
        processed = preprocess_image(image)

        # Convert to PIL Image for Tesseract
        pil_img = Image.fromarray(processed)

        # Multiple OCR attempts with different configurations
        configs = [
            '--oem 3 --psm 6',           # Assume uniform text block
            '--oem 3 --psm 3',           # Fully automatic
            '--oem 3 --psm 4',            # Single column
            '--oem 3 --psm 11'            # Sparse text
        ]

        texts = []
        for config in configs:
            try:
                text = pytesseract.image_to_string(pil_img, config=config)
                if text and text.strip():
                    texts.append(text.strip())
            except Exception as e:
                print(f"OCR config error: {e}")
                continue

        # Take the longest result (usually most complete)
        if texts:
            final_text = max(texts, key=len)
        else:
            # Fallback to default config
            final_text = pytesseract.image_to_string(pil_img)

        # Post-process the text
        final_text = post_process_text(final_text)

        return final_text.strip()

    except Exception as e:
        print(f"OCR Error: {e}")
        return ""

def post_process_text(text: str) -> str:
    """Clean up common OCR errors"""
    if not text:
        return ""

    # Fix common OCR mistakes
    replacements = {
        '|': 'I',
        '0': 'O',
        '1': 'I',
        '5': 'S',
        '8': 'B',
        '¢': 'c',
        '©': 'c',
        '®': 'r',
        '™': 'TM',
        'ﬁ': 'fi',
        'ﬂ': 'fl',
        '�': '',
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    # Remove excessive whitespace
    text = re.sub(r'\s+', ' ', text)

    # Fix line breaks
    text = re.sub(r'(\w)-\s+(\w)', r'\1\2', text)  # Fix hyphenated words

    return text

def extract_ingredients(text: str) -> dict:
    """
    Enhanced ingredient extraction with better pattern matching.
    Returns structured ingredient data.
    """
    if not text:
        return {"ingredients": [], "full_text": "No text extracted", "count": 0}

    # Common ingredient section headers in multiple languages
    ingredient_patterns = [
        r'(?i)(?:ingredients?|ingr[ée]dients?|contains?|contents?|composition|constituents?|beståraf)',
        r'(?i)(?:ingredientes|zutaten|ingrédients|ingredienti|原料|成分)',
    ]

    # Common ingredient separators
    separators = [',', ';', '•', '·', '●', '▪', '-']

    lines = text.split('\n')
    extracted_ingredients = []
    ingredient_section = []
    found_ingredients = False
    section_end_markers = ['nutrition', 'allergen', 'storage', 'best before',
                          'use by', 'manufactured', 'distributed', 'imported',
                          'serving size', 'servings per container']

    for i, line in enumerate(lines):
        clean_line = line.strip()
        if not clean_line:
            continue

        # Check for ingredient section start
        for pattern in ingredient_patterns:
            if re.search(pattern, clean_line):
                found_ingredients = True
                # Extract the line without the header
                header_match = re.search(pattern, clean_line)
                if header_match:
                    ingredient_text = clean_line[header_match.end():].strip()
                    # Remove leading colon or dash
                    ingredient_text = re.sub(r'^[:;\-]', '', ingredient_text).strip()
                    if ingredient_text:
                        # Split by common separators
                        for sep in separators:
                            if sep in ingredient_text:
                                parts = [p.strip() for p in ingredient_text.split(sep) if p.strip()]
                                extracted_ingredients.extend(parts)
                                break
                        else:
                            extracted_ingredients.append(ingredient_text)
                break

        # If in ingredient section, capture subsequent lines
        if found_ingredients:
            # Check if we've reached the end of ingredients section
            if any(marker in clean_line.lower() for marker in section_end_markers):
                break

            # Skip if line is too short or contains only numbers/special chars
            if len(clean_line) < 3 or re.match(r'^[\d\s.,%()\[\]]+$', clean_line):
                continue

            # Add to ingredient section
            ingredient_section.append(clean_line)

            # Parse the line for ingredients
            for sep in separators:
                if sep in clean_line:
                    parts = [p.strip() for p in clean_line.split(sep) if p.strip()]
                    # Filter out non-ingredient parts
                    for part in parts:
                        if len(part) > 1 and not re.match(r'^[\d\s.,%()\[\]]+$', part):
                            if part not in extracted_ingredients:
                                extracted_ingredients.append(part)
                    break
            else:
                # No separator found, treat as single ingredient if it looks valid
                if len(clean_line) > 2 and not re.match(r'^[\d\s.,%()\[\]]+$', clean_line):
                    if clean_line not in extracted_ingredients:
                        extracted_ingredients.append(clean_line)

    # If no ingredients found with keywords, try to find common ingredient patterns
    if not extracted_ingredients:
        # Look for common ingredient formats (e.g., "potatoes (62%)")
        ingredient_pattern = r'([A-Za-z\s]+)(?:\s*\([^)]*%\))?'
        for line in lines:
            matches = re.findall(ingredient_pattern, line)
            for match in matches:
                ingredient = match.strip()
                if ingredient and len(ingredient) > 2 and not re.match(r'^[\d\s.,%()\[\]]+$', ingredient):
                    if ingredient not in extracted_ingredients:
                        extracted_ingredients.append(ingredient)

    # Clean up ingredients
    cleaned_ingredients = []
    for ingredient in extracted_ingredients:
        # Remove percentages and parentheses content
        ingredient = re.sub(r'\([^)]*\)', '', ingredient)
        ingredient = re.sub(r'\d+%', '', ingredient)
        # Remove extra whitespace
        ingredient = re.sub(r'\s+', ' ', ingredient).strip()
        # Remove trailing punctuation
        ingredient = re.sub(r'[.,;:]$', '', ingredient)

        if ingredient and len(ingredient) > 1 and not ingredient.isdigit():
            cleaned_ingredients.append(ingredient)

    # Remove duplicates while preserving order
    seen = set()
    unique_ingredients = []
    for ingredient in cleaned_ingredients:
        ingredient_lower = ingredient.lower()
        if ingredient_lower not in seen:
            seen.add(ingredient_lower)
            unique_ingredients.append(ingredient)

    return {
        "ingredients": unique_ingredients,
        "full_text": " ".join(ingredient_section) if ingredient_section else "Ingredients not found",
        "count": len(unique_ingredients)
    }

def validate_ingredients(ingredients: list) -> dict:
    """
    Validate and analyze ingredients for potential allergens.
    """
    if not ingredients:
        return {"valid": False, "message": "No ingredients to validate", "allergens": []}

    # Common allergens to check
    common_allergens = {
        "gluten": ["wheat", "barley", "rye", "oat", "spelt", "gluten", "triticum", "hordeum", "secale", "avena"],
        "dairy": ["milk", "cream", "butter", "cheese", "yogurt", "whey", "casein", "lactose", "dairy", "ghee"],
        "eggs": ["egg", "albumin", "mayonnaise", "ovum", "lysozyme"],
        "soy": ["soy", "soya", "tofu", "tempeh", "lecithin", "edamame", "soybean"],
        "nuts": ["almond", "walnut", "pecan", "cashew", "hazelnut", "pistachio", "macadamia", "nut"],
        "peanuts": ["peanut", "groundnut", "arachis"],
        "fish": ["fish", "cod", "tuna", "salmon", "anchovy", "sardine", "mackerel"],
        "shellfish": ["shrimp", "prawn", "crab", "lobster", "crayfish", "mollusc", "clam", "oyster"],
        "sesame": ["sesame", "til", "gingelly"],
        "sulfites": ["sulfite", "sulphite", "sulfur dioxide", "e220", "e221", "e222", "e223", "e224", "e226", "e227", "e228"]
    }

    found_allergens = []
    ingredient_text = " ".join(ingredients).lower()

    for allergen, keywords in common_allergens.items():
        for keyword in keywords:
            if keyword.lower() in ingredient_text and allergen not in found_allergens:
                found_allergens.append(allergen)
                break

    return {
        "valid": True,
        "allergens": found_allergens,
        "ingredient_count": len(ingredients),
        "has_allergens": len(found_allergens) > 0
    }