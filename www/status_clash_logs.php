<?php
$log_file = "/var/log/clash.log";

if (file_exists($log_file)) {
    // 输出日志内容（最多返回 200 行，避免过大）
    $lines = array_slice(file($log_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES), -200);
    echo implode("\n", $lines);
} else {
    echo "日志文件未找到！";
}