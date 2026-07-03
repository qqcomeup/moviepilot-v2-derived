"""Compatibility patches loaded automatically by Python at startup."""

import types

try:
    import bcrypt
except Exception:
    bcrypt = None

if bcrypt is not None and not hasattr(bcrypt, "__about__"):
    bcrypt.__about__ = types.SimpleNamespace(
        __version__=getattr(bcrypt, "__version__", "unknown")
    )
