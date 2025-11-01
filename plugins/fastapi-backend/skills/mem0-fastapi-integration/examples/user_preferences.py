"""
User Preference Management Example
Demonstrates user preference tracking and personalization with Mem0
"""

from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from enum import Enum
from contextlib import asynccontextmanager
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Enums
class PreferenceCategory(str, Enum):
    """Preference categories"""

    COMMUNICATION = "communication"
    UI = "ui"
    CONTENT = "content"
    BEHAVIOR = "behavior"
    PRIVACY = "privacy"


class ResponseStyle(str, Enum):
    """Response style preferences"""

    CONCISE = "concise"
    DETAILED = "detailed"
    TECHNICAL = "technical"
    CASUAL = "casual"


# Models
class PreferenceCreate(BaseModel):
    """Create preference request"""

    preference: str = Field(..., description="Preference description")
    category: PreferenceCategory = Field(..., description="Preference category")
    value: Optional[str] = Field(None, description="Preference value")


class PreferenceResponse(BaseModel):
    """Preference response"""

    preference: str
    category: str
    value: Optional[str] = None
    timestamp: str


class UserProfile(BaseModel):
    """User profile with preferences"""

    user_id: str
    preferences: List[PreferenceResponse]
    response_style: Optional[ResponseStyle] = None
    total_interactions: int = 0
    memory_summary: Dict[str, Any] = {}


# Application setup
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager"""
    logger.info("Initializing preference management service...")
    yield
    logger.info("Shutting down...")


app = FastAPI(
    title="User Preference Management API",
    description="User preference tracking with Mem0",
    version="1.0.0",
    lifespan=lifespan,
)


# Preference endpoints
@app.post("/preferences", response_model=PreferenceResponse)
async def add_preference(
    request: PreferenceCreate,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Add a user preference to memory.

    The preference will be stored in Mem0 and used to personalize future interactions.
    """
    user_id = "demo_user"

    try:
        # Build preference text
        preference_text = request.preference
        if request.value:
            preference_text += f": {request.value}"

        # Add to memory
        # success = await memory_service.add_user_preference(
        #     user_id=user_id,
        #     preference=preference_text,
        #     category=request.category.value
        # )
        success = True

        if not success:
            raise HTTPException(status_code=500, detail="Failed to add preference")

        logger.info(f"Added preference for user {user_id}: {preference_text}")

        return PreferenceResponse(
            preference=request.preference,
            category=request.category.value,
            value=request.value,
            timestamp="2025-10-31T00:00:00Z",
        )

    except Exception as e:
        logger.error(f"Error adding preference: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/preferences")
async def get_preferences(
    category: Optional[PreferenceCategory] = None,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Get all user preferences.

    Optionally filter by category.
    """
    user_id = "demo_user"

    try:
        # Get user summary
        # summary = await memory_service.get_user_summary(user_id)
        summary = {"user_preferences": []}  # Placeholder

        preferences = summary.get("user_preferences", [])

        # Filter by category if specified
        if category:
            preferences = [
                p for p in preferences if p.get("category") == category.value
            ]

        return {"user_id": user_id, "preferences": preferences, "count": len(preferences)}

    except Exception as e:
        logger.error(f"Error getting preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/profile", response_model=UserProfile)
async def get_user_profile(
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Get complete user profile including preferences and memory summary.
    """
    user_id = "demo_user"

    try:
        # Get comprehensive summary
        # summary = await memory_service.get_user_summary(user_id)
        summary = {
            "total_memories": 0,
            "user_preferences": [],
            "memory_categories": {},
        }

        # Extract response style if set
        response_style = None
        for pref in summary.get("user_preferences", []):
            if pref.get("category") == "communication":
                content = pref.get("preference", "").lower()
                if "concise" in content:
                    response_style = ResponseStyle.CONCISE
                elif "detailed" in content:
                    response_style = ResponseStyle.DETAILED
                elif "technical" in content:
                    response_style = ResponseStyle.TECHNICAL

        return UserProfile(
            user_id=user_id,
            preferences=[
                PreferenceResponse(
                    preference=p.get("preference", ""),
                    category=p.get("category", "general"),
                    timestamp="2025-10-31T00:00:00Z",
                )
                for p in summary.get("user_preferences", [])
            ],
            response_style=response_style,
            total_interactions=summary.get("total_memories", 0),
            memory_summary=summary.get("memory_categories", {}),
        )

    except Exception as e:
        logger.error(f"Error getting profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/preferences/quick")
async def set_quick_preference(
    response_style: ResponseStyle,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Quick set common preferences.

    Sets a predefined preference based on response style.
    """
    user_id = "demo_user"

    # Map response style to preference text
    style_preferences = {
        ResponseStyle.CONCISE: "I prefer concise, brief responses",
        ResponseStyle.DETAILED: "I prefer detailed, comprehensive explanations",
        ResponseStyle.TECHNICAL: "I prefer technical language with examples",
        ResponseStyle.CASUAL: "I prefer casual, friendly conversation",
    }

    preference_text = style_preferences.get(response_style)

    if not preference_text:
        raise HTTPException(status_code=400, detail="Invalid response style")

    try:
        # Add preference
        # success = await memory_service.add_user_preference(
        #     user_id=user_id,
        #     preference=preference_text,
        #     category="communication"
        # )
        success = True

        if not success:
            raise HTTPException(status_code=500, detail="Failed to set preference")

        return {
            "message": "Preference set successfully",
            "response_style": response_style.value,
            "preference": preference_text,
        }

    except Exception as e:
        logger.error(f"Error setting quick preference: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/preferences/learn")
async def learn_from_interaction(
    interaction_type: str,
    user_feedback: str,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Learn user preferences from interactions.

    Automatically extracts preferences from user feedback.
    """
    user_id = "demo_user"

    try:
        # Analyze feedback for preferences (simple keyword extraction)
        learned_preferences = []

        feedback_lower = user_feedback.lower()

        # Check for style preferences
        if "too long" in feedback_lower or "too detailed" in feedback_lower:
            learned_preferences.append(
                ("I prefer shorter responses", PreferenceCategory.COMMUNICATION)
            )
        elif "more detail" in feedback_lower or "elaborate" in feedback_lower:
            learned_preferences.append(
                ("I prefer detailed explanations", PreferenceCategory.COMMUNICATION)
            )

        # Check for content preferences
        if "example" in feedback_lower:
            learned_preferences.append(
                ("I like examples in responses", PreferenceCategory.CONTENT)
            )
        if "code" in feedback_lower:
            learned_preferences.append(
                ("I want code examples", PreferenceCategory.CONTENT)
            )

        # Add learned preferences
        for pref_text, category in learned_preferences:
            # await memory_service.add_user_preference(
            #     user_id=user_id,
            #     preference=pref_text,
            #     category=category.value
            # )
            logger.info(f"Learned preference: {pref_text}")

        return {
            "message": "Learned from interaction",
            "learned_preferences": [p[0] for p in learned_preferences],
            "count": len(learned_preferences),
        }

    except Exception as e:
        logger.error(f"Error learning from interaction: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/preferences")
async def clear_preferences(
    category: Optional[PreferenceCategory] = None,
    # user_id: str = Depends(get_current_user),
    # memory_service = Depends(get_memory_service)
):
    """
    Clear user preferences.

    Optionally clear only specific category.
    """
    user_id = "demo_user"

    try:
        if category:
            # Clear specific category (would need custom implementation)
            return {
                "message": f"Cleared {category.value} preferences",
                "category": category.value,
            }
        else:
            # Clear all preferences (delete all memories)
            # success = await memory_service.delete_all_memories(user_id)
            success = True

            if success:
                return {"message": "All preferences cleared"}
            else:
                raise HTTPException(status_code=500, detail="Failed to clear preferences")

    except Exception as e:
        logger.error(f"Error clearing preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Health check
@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "service": "user-preferences"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
