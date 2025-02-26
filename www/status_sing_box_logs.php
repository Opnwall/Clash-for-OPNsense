<?php
$log_file = "/var/log/sing-box.log";

// 获取日志文件内容（显示最近100条）
$logs = file_exists($log_file) ? file_get_contents($log_file) : "日志文件不可用。";
$log_lines = explode("\n", $logs);  // 将日志按行分割
$recent_logs = array_slice($log_lines, -100);  // 获取最近的15条日志
$logs = implode("\n", $recent_logs);  // 将日志重新组合为字符串

echo nl2br(htmlspecialchars($logs));  // 输出并转换特殊字符
?>
