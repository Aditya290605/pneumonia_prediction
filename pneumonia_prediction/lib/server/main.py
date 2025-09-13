from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import tensorflow as tf
import numpy as np
import cv2
import pickle
import uuid
import os

# --- Config ---
MODEL_PATH = "attention_model.keras"   # change path
THRESHOLD_PATH = "attention_model_threshold.pkl"   # change path
IMG_SIZE = (224, 224)
OUTPUT_DIR = "outputs"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Load model and threshold once ---
with open(THRESHOLD_PATH, "rb") as f:
    best_thresh = pickle.load(f)

model = tf.keras.models.load_model(MODEL_PATH, compile=False)

# --- Create FastAPI app ---
app = FastAPI(title="Pneumonia Detection API")

# Serve the outputs directory as static files
app.mount("/outputs", StaticFiles(directory=OUTPUT_DIR), name="outputs")


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        # Save uploaded file temporarily
        filename = f"{uuid.uuid4()}_{file.filename}"
        temp_path = os.path.join(OUTPUT_DIR, filename)
        with open(temp_path, "wb") as f_out:
            f_out.write(await file.read())

        # --- Read + preprocess image ---
        img = cv2.imread(temp_path)
        if img is None:
            return JSONResponse(status_code=400, content={"error": "Invalid image"})

        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img_resized = cv2.resize(img_rgb, IMG_SIZE)
        img_array = np.expand_dims(img_resized / 255.0, axis=0)

        # --- Predict ---
        prob = float(model.predict(img_array, verbose=0).ravel()[0])
        prediction = "PNEUMONIA" if prob > best_thresh else "NORMAL"

        confidence = {
            "PNEUMONIA": round(prob * 100, 2),
            "NORMAL": round((1 - prob) * 100, 2)
        }

        # --- Create diagnosed image ---
        diagnosed_filename = filename.rsplit(".", 1)[0] + "_diagnosed.jpg"
        diagnosed_path = os.path.join(OUTPUT_DIR, diagnosed_filename)

        output_img = img_rgb.copy()
        color = (255, 0, 0) if prediction == "PNEUMONIA" else (0, 200, 0)
        cv2.putText(output_img, f"{prediction} ({prob:.2f})", (20, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2, cv2.LINE_AA)
        cv2.imwrite(diagnosed_path, cv2.cvtColor(output_img, cv2.COLOR_RGB2BGR))

        # --- Build public URL for diagnosed image ---
        diagnosed_url = f"/outputs/{diagnosed_filename}"

        return {
            "prediction": prediction,
            "probability": prob,
            "threshold_used": float(best_thresh),
            "confidence": confidence,
            "diagnosed_image_url": diagnosed_url
        }

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
