"""
FastAPI Application Entry Point

Main application initialization with middleware, routers, and configuration.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware

from app.core.config import settings
from app.api.routes import health

# Optional: MCP server integration
# from app.mcp.server import mcp_server, run_mcp_server


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""

    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        debug=settings.DEBUG,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
    )

    # Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.add_middleware(GZipMiddleware, minimum_size=1000)

    if not settings.DEBUG:
        app.add_middleware(
            TrustedHostMiddleware,
            allowed_hosts=["*"],  # Configure for production
        )

    # Include routers
    app.include_router(health.router, prefix="/health", tags=["health"])
    # app.include_router(users.router, prefix="/api/v1/users", tags=["users"])

    @app.get("/")
    async def root():
        """Root endpoint."""
        return {
            "message": f"Welcome to {settings.PROJECT_NAME}",
            "version": settings.VERSION,
            "environment": settings.ENVIRONMENT,
        }

    return app


app = create_app()


# Optional: MCP server mode
# if __name__ == "__main__":
#     import sys
#     import asyncio
#
#     if "--mcp" in sys.argv:
#         # Run as MCP server (STDIO mode)
#         asyncio.run(run_mcp_server())
#     else:
#         # Run as HTTP server
#         import uvicorn
#         uvicorn.run(
#             "app.main:app",
#             host=settings.HOST,
#             port=settings.PORT,
#             reload=settings.DEBUG,
#         )
