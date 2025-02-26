<?php
$log_file = "/var/log/mosdns.log"; // 日志文件路径

if (file_exists($log_file)) {
    readfile($log_file);
} else {
    echo "Log file not found.";
}
?>
