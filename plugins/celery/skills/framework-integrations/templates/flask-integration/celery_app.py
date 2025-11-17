"""
Flask + Celery integration with application context
Place in project root as celery_app.py
"""

from celery import Celery, Task
from flask import Flask


def create_app():
    """Flask application factory"""
    app = Flask(__name__)

    # Configuration
    app.config.update(
        SECRET_KEY='your_secret_key_here',
        SQLALCHEMY_DATABASE_URI='postgresql://your_database_url_here',
        CELERY_BROKER_URL='redis://your_redis_url_here',
        CELERY_RESULT_BACKEND='redis://your_redis_url_here',
    )

    return app


def make_celery(app):
    """
    Create Celery instance with Flask app context
    """

    class ContextTask(Task):
        """Custom task class that pushes Flask app context"""

        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery = Celery(
        app.import_name,
        task_cls=ContextTask,
    )

    celery.config_from_object(app.config, namespace='CELERY')
    celery.set_default()

    return celery


# Create instances
app = create_app()
celery = make_celery(app)
