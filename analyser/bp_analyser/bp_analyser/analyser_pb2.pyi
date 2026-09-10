from google.protobuf.internal import enum_type_wrapper as _enum_type_wrapper
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class AnalyseStatus(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    ANALYSE_STATUS_UNSPECIFIED: _ClassVar[AnalyseStatus]
    ANALYSE_STATUS_COMPLETED: _ClassVar[AnalyseStatus]
    ANALYSE_STATUS_CANCELLED: _ClassVar[AnalyseStatus]
    ANALYSE_STATUS_NO_DATA: _ClassVar[AnalyseStatus]
    ANALYSE_STATUS_FAILED: _ClassVar[AnalyseStatus]

class CancelStatus(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    CANCEL_STATUS_UNSPECIFIED: _ClassVar[CancelStatus]
    CANCEL_STATUS_STOPPED: _ClassVar[CancelStatus]
    CANCEL_STATUS_NOTHING_RUNNING: _ClassVar[CancelStatus]
    CANCEL_STATUS_REFUSED: _ClassVar[CancelStatus]
ANALYSE_STATUS_UNSPECIFIED: AnalyseStatus
ANALYSE_STATUS_COMPLETED: AnalyseStatus
ANALYSE_STATUS_CANCELLED: AnalyseStatus
ANALYSE_STATUS_NO_DATA: AnalyseStatus
ANALYSE_STATUS_FAILED: AnalyseStatus
CANCEL_STATUS_UNSPECIFIED: CancelStatus
CANCEL_STATUS_STOPPED: CancelStatus
CANCEL_STATUS_NOTHING_RUNNING: CancelStatus
CANCEL_STATUS_REFUSED: CancelStatus

class AnalyseRequest(_message.Message):
    __slots__ = ("web_id", "shared_file_count", "requested_at")
    WEB_ID_FIELD_NUMBER: _ClassVar[int]
    SHARED_FILE_COUNT_FIELD_NUMBER: _ClassVar[int]
    REQUESTED_AT_FIELD_NUMBER: _ClassVar[int]
    web_id: str
    shared_file_count: int
    requested_at: str
    def __init__(self, web_id: _Optional[str] = ..., shared_file_count: _Optional[int] = ..., requested_at: _Optional[str] = ...) -> None: ...

class AnalyseReply(_message.Message):
    __slots__ = ("status", "run_id", "message", "result_url", "generated_at", "pod_count", "observation_count", "files_read", "files_skipped", "published")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    RUN_ID_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    RESULT_URL_FIELD_NUMBER: _ClassVar[int]
    GENERATED_AT_FIELD_NUMBER: _ClassVar[int]
    POD_COUNT_FIELD_NUMBER: _ClassVar[int]
    OBSERVATION_COUNT_FIELD_NUMBER: _ClassVar[int]
    FILES_READ_FIELD_NUMBER: _ClassVar[int]
    FILES_SKIPPED_FIELD_NUMBER: _ClassVar[int]
    PUBLISHED_FIELD_NUMBER: _ClassVar[int]
    status: AnalyseStatus
    run_id: str
    message: str
    result_url: str
    generated_at: str
    pod_count: int
    observation_count: int
    files_read: int
    files_skipped: int
    published: bool
    def __init__(self, status: _Optional[_Union[AnalyseStatus, str]] = ..., run_id: _Optional[str] = ..., message: _Optional[str] = ..., result_url: _Optional[str] = ..., generated_at: _Optional[str] = ..., pod_count: _Optional[int] = ..., observation_count: _Optional[int] = ..., files_read: _Optional[int] = ..., files_skipped: _Optional[int] = ..., published: bool = ...) -> None: ...

class CancelRequest(_message.Message):
    __slots__ = ("web_id", "requested_at")
    WEB_ID_FIELD_NUMBER: _ClassVar[int]
    REQUESTED_AT_FIELD_NUMBER: _ClassVar[int]
    web_id: str
    requested_at: str
    def __init__(self, web_id: _Optional[str] = ..., requested_at: _Optional[str] = ...) -> None: ...

class CancelReply(_message.Message):
    __slots__ = ("status", "message", "run_id")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    RUN_ID_FIELD_NUMBER: _ClassVar[int]
    status: CancelStatus
    message: str
    run_id: str
    def __init__(self, status: _Optional[_Union[CancelStatus, str]] = ..., message: _Optional[str] = ..., run_id: _Optional[str] = ...) -> None: ...

class StatusRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class StatusReply(_message.Message):
    __slots__ = ("ready", "analyser_web_id", "active_runs", "last_run_id", "last_run_at", "message")
    READY_FIELD_NUMBER: _ClassVar[int]
    ANALYSER_WEB_ID_FIELD_NUMBER: _ClassVar[int]
    ACTIVE_RUNS_FIELD_NUMBER: _ClassVar[int]
    LAST_RUN_ID_FIELD_NUMBER: _ClassVar[int]
    LAST_RUN_AT_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    ready: bool
    analyser_web_id: str
    active_runs: int
    last_run_id: str
    last_run_at: str
    message: str
    def __init__(self, ready: bool = ..., analyser_web_id: _Optional[str] = ..., active_runs: _Optional[int] = ..., last_run_id: _Optional[str] = ..., last_run_at: _Optional[str] = ..., message: _Optional[str] = ...) -> None: ...
