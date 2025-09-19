from fastapi import FastAPI, File, UploadFile, Request
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import tensorflow as tf
import numpy as np
import cv2
import pickle
import uuid
import os
import google.generativeai as genai
from dotenv import load_dotenv

app = FastAPI(title="Pneumonia Detection API + Report Service")

# Allow requests from Flutter web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all during dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

load_dotenv()


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

# --- Gemini config ---
genai.configure(api_key=os.getenv("GEMINI_KEY"))
gemini_model = genai.GenerativeModel("gemini-2.0-flash")

# Serve static diagnosed images.
app.mount("/outputs", StaticFiles(directory=OUTPUT_DIR), name="outputs")


# ---------------------------
#   ROUTE 1: PREDICT
# ---------------------------
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    try:
        # Save uploaded file temporarily
        filename = f"{uuid.uuid4()}_{file.filename}"
        temp_path = os.path.join(OUTPUT_DIR, filename)
        with open(temp_path, "wb") as f_out:
            f_out.write(await file.read())

        # --- Preprocess image ---
        img = cv2.imread(temp_path)
        if img is None:
            return JSONResponse(status_code=400, content={"error": "Invalid image"})

        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img_resized = cv2.resize(img_rgb, IMG_SIZE)
        img_array = np.expand_dims(img_resized / 255.0, axis=0)

        # --- Prediction ---
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

        diagnosed_url = f"/outputs/{diagnosed_filename}"

        # --- Base result ---
        result = {
            "prediction": prediction,
            "probability": prob,
            "threshold_used": float(best_thresh),
            "confidence": confidence,
            "diagnosed_image_url": diagnosed_url
        }

        # --- ALSO generate report automatically ---
        try:
            report = await generate_report_internal(result)
            result["report"] = report
        except Exception as e:
            result["report"] = {"error": str(e)}

        return result

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


# ---------------------------
#   ROUTE 2: REPORT
# ---------------------------
@app.post("/generate_report")
async def generate_report(request: Request):
    """
    Exposed route if you want to call it separately.
    """
    try:
        data = await request.json()
        return {"report": await generate_report_internal(data)}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


# ---------------------------
#   HELPER: GEMINI REPORT
# ---------------------------
async def generate_report_internal(data: dict):
    prediction = data.get("prediction")
    probability = data.get("probability")
    confidence = data.get("confidence")
    threshold = data.get("threshold_used")

    prompt = f"""
    Write a **professional medical-style report** for a patient based on these chest X-ray results:

    - Diagnosis: {prediction}
    - Probability Score: {probability:.2f}
    - Confidence Levels: {confidence}
    - Threshold Used: {threshold}

    The report should:
    - Avoid phrases like "here’s a summary" or "the computer thinks".
    - Be written as if it’s a medical assistant summarizing results for a patient.
    - Have clear sections with headings:
        1. Diagnosis
        2. Confidence in Result
        3. General Health Guidance
        4. Recommended Next Steps
    - Use plain, supportive language (easy to understand, but professional).
    - Keep it concise and structured like a real medical note.
    """

    response = gemini_model.generate_content(prompt)
    return response.text
