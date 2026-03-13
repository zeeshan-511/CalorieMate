from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import ocr_service
import uvicorn
import cv2
import numpy as np
from typing import Optional

app = FastAPI(
    title="OCR Microservice",
    description="API to extract text and ingredients from product labels.",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "OCR Service is running", "status": "ok", "version": "2.0.0"}

@app.get("/test")
async def test():
    return {"message": "Connection successful!", "status": "ok"}

@app.post("/scan-label/")
async def scan_label(
    file: UploadFile = File(...),
    validate_allergens: Optional[bool] = False
):
    """
    Endpoint to upload an image and extract text/ingredients.
    Optional allergen validation.
    """
    try:
        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/jpg', 'image/gif', 'image/bmp']
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid file type. Allowed: {allowed_types}"
            )

        # Read file as bytes
        image_bytes = await file.read()
        print(f"📥 Received: {file.filename}, Size: {len(image_bytes)} bytes, Type: {file.content_type}")

        # Quick validation using OpenCV
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            raise HTTPException(
                status_code=400,
                detail="File could not be decoded as an image. Please send a valid image file."
            )

        # Get image properties
        height, width = img.shape[:2]
        print(f"📏 Image dimensions: {width}x{height}")

        # Call OCR service with enhanced extraction
        extracted_text = ocr_service.extract_text_from_image(image_bytes)
        print(f"📝 Extracted text: {extracted_text[:100]}...")  # Log first 100 chars

        # Extract structured ingredients
        ingredients_result = ocr_service.extract_ingredients(extracted_text)

        response = {
            "status": "success",
            "extracted_text": extracted_text,
            "ingredients": ingredients_result["ingredients"],
            "ingredients_section": ingredients_result["full_text"],
            "ingredient_count": ingredients_result["count"],
            "image_info": {
                "width": width,
                "height": height,
                "format": file.content_type
            }
        }

        # Optional allergen validation
        if validate_allergens and ingredients_result["ingredients"]:
            allergen_analysis = ocr_service.validate_ingredients(ingredients_result["ingredients"])
            response["allergen_analysis"] = allergen_analysis

        print(f"✅ Found {ingredients_result['count']} ingredients")
        return JSONResponse(status_code=200, content=response)

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@app.post("/scan-label/debug/")
async def scan_label_debug(file: UploadFile = File(...)):
    """
    Debug endpoint that returns preprocessing steps.
    """
    try:
        image_bytes = await file.read()
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Test different preprocessing methods
        results = []

        # Original image
        pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        text1 = pytesseract.image_to_string(pil_img, config='--oem 3 --psm 6')

        # Grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        pil_gray = Image.fromarray(gray)
        text2 = pytesseract.image_to_string(pil_gray, config='--oem 3 --psm 6')

        # Thresholded
        _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        pil_thresh = Image.fromarray(thresh)
        text3 = pytesseract.image_to_string(pil_thresh, config='--oem 3 --psm 6')

        results = {
            "original": text1.strip(),
            "grayscale": text2.strip(),
            "threshold": text3.strip()
        }

        # Find best result (longest text)
        best_method = max(results.items(), key=lambda x: len(x[1]))

        return JSONResponse(status_code=200, content={
            "status": "success",
            "debug_results": results,
            "best_method": best_method[0],
            "best_text": best_method[1],
            "image_dimensions": f"{img.shape[1]}x{img.shape[0]}"
        })

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)