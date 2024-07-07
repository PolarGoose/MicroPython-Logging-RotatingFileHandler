# MicroPython-Logging-RotatingFileHandler
[RotatingFileHandler](https://docs.python.org/3/library/logging.handlers.html#logging.handlers.RotatingFileHandler) implementation for the [Micropython Logging library](https://github.com/micropython/micropython-lib/tree/master/python-stdlib/logging)

# Features
* Thread-safe
* Rotates files by adding an index to the old log files like `log.txt.1`, `log.txt.2`, etc.

# How to use

## Option 1: Manual installation
* Download the latest [release](https://github.com/PolarGoose/MicroPython-Logging-RotatingFileHandler/releases)
* Copy the file into the `/lib` directory on your device or to your source code folder

## Option 2: Using mpremote
* Use [mpremote](https://docs.micropython.org/en/latest/reference/mpremote.html) to install the library to the device:
```
mpremote mip install https://github.com/PolarGoose/MicroPython-Logging-RotatingFileHandler/releases/download/v1.0/rotating_file_handler.py
```

# Usage example
```
from rotating_file_handler import RotatingLogFileHandler
from logging import getLogger, DEBUG, Formatter

handler = RotatingLogFileHandler(log_file_name, 20, 2)
formatter = Formatter("%(message)s")
handler.setFormatter(formatter)
logger = getLogger("test_logger")
logger.addHandler(handler)
logger.setLevel(DEBUG)

logger.info("message")
```
