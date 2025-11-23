from django.apps import AppConfig


class SchedulingConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "scheduling"

    def ready(self) -> None:
        from . import signals  # noqa: F401
        return super().ready()
