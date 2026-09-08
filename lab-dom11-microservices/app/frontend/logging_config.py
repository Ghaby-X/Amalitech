"""
Structured JSON logging
"""
import json
import logging
import os

SERVICE_NAME = os.environ.get('SERVICE_NAME', 'frontend')

# Attributes every LogRecord carries regardless of what was logged -
# anything else on the record came from a caller's extra={...} and
# should be merged into the JSON output.
_STANDARD_ATTRS = set(logging.LogRecord('', 0, '', 0, '', (), None).__dict__) | {'message', 'asctime'}


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            'time': self.formatTime(record, '%Y-%m-%dT%H:%M:%S%z'),
            'level': record.levelname.lower(),
            'service': SERVICE_NAME,
            'module': record.module,
            'function': record.funcName,
            'message': record.getMessage(),
        }
        if record.exc_info:
            payload['exception'] = self.formatException(record.exc_info)

        for key, value in record.__dict__.items():
            if key not in _STANDARD_ATTRS and key not in payload:
                payload[key] = value

        return json.dumps(payload, default=str)


def configure_logging():
    level = os.environ.get('LOG_LEVEL', 'INFO').upper()

    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)
