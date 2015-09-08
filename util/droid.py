# Droid
# Droid enumeration. The keys values equal the csv index up until FORMAT_VERSION.
# Other procedures add keys 'PID' and 'SEQ' columns.
#
# Note that a droid analysis may produce more than one FORMAT_* column with container files.
# These are not read in and ignored here.
class Droid:
    ID = 0
    PARENT_ID = 1
    URI = 2
    FILE_PATH = 3
    NAME = 4
    METHOD = 5
    STATUS = 6
    SIZE = 7
    TYPE = 8
    EXT = 9
    LAST_MODIFIED = 10
    EXTENSION_MISMATCH = 11
    HASH = 12
    FORMAT_COUNT = 13
    PUID = 14
    MIME_TYPE = 15
    FORMAT_NAME = 16
    FORMAT_VERSION = 17
    PID = 18
    SEQ = 19
