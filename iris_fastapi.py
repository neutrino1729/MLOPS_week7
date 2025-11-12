from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd

app = FastAPI(title="🌸 Iris Classifier API")

# Load model
try:
    model = joblib.load("model.joblib")
    print("✅ Model loaded successfully")
except Exception as e:
    print(f"❌ Error loading model: {e}")
    model = None

class IrisInput(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float

@app.get("/")
def read_root():
    return {"message": "Welcome to the Iris Classifier API!"}

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": model is not None
    }

@app.post("/predict/")
def predict_species(data: IrisInput):
    """Predict iris species"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Create DataFrame from input
        input_df = pd.DataFrame([{
            'sepal_length': data.sepal_length,
            'sepal_width': data.sepal_width,
            'petal_length': data.petal_length,
            'petal_width': data.petal_width
        }])
        
        # Make prediction
        prediction = model.predict(input_df)[0]
        
        return {
            "predicted_class": int(prediction)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")
